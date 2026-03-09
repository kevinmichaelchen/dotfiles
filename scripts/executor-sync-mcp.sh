#!/usr/bin/env bash
# Sync local MCP inventory into executor, bridging stdio MCP servers to local HTTP.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
  echo -e "${GREEN}==>${NC} $*"
}

warn() {
  echo -e "${YELLOW}warn${NC} $*" >&2
}

error() {
  echo -e "${RED}err${NC} $*" >&2
}

resolve_bin() {
  local name="$1"
  local fallback="${2:-}"

  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi

  if [[ -n "$fallback" && -x "$fallback" ]]; then
    printf '%s\n' "$fallback"
    return 0
  fi

  return 1
}

require_bin() {
  local name="$1"
  local fallback="${2:-}"
  local resolved

  if ! resolved="$(resolve_bin "$name" "$fallback")"; then
    error "Required command not found: $name"
    exit 1
  fi

  printf '%s\n' "$resolved"
}

have_env() {
  local key
  for key in "$@"; do
    if [[ -z "${!key:-}" ]]; then
      return 1
    fi
  done
  return 0
}

health_url() {
  local port="$1"
  printf 'http://127.0.0.1:%s/healthz\n' "$port"
}

bridge_url() {
  local port="$1"
  printf 'http://127.0.0.1:%s/mcp\n' "$port"
}

wait_for_health() {
  local name="$1"
  local port="$2"
  local attempts=0

  while (( attempts < 30 )); do
    if "$CURL_BIN" -fsS "$(health_url "$port")" >/dev/null 2>&1; then
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 1
  done

  warn "Bridge $name did not become healthy on port $port"
  return 1
}

start_managed_process() {
  local name="$1"
  local port="$2"
  shift 2

  local log_file="$LOG_DIR/${name}.log"
  local command_file="$COMMAND_DIR/${name}.sh"
  local session_name="executor-mcp-${name}"

  if "$CURL_BIN" -fsS "$(health_url "$port")" >/dev/null 2>&1; then
    info "Bridge $name already healthy on $port"
    return 0
  fi

  if "$TMUX_BIN" has-session -t "$session_name" >/dev/null 2>&1; then
    warn "Stopping stale tmux session $session_name"
    "$TMUX_BIN" kill-session -t "$session_name" >/dev/null 2>&1 || true
  fi

  {
    printf '#!/usr/bin/env bash\n'
    printf 'exec </dev/null >%q 2>&1\n' "$log_file"
    printf 'exec'
    local arg
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
  } >"$command_file"
  chmod 700 "$command_file"

  info "Starting bridge $name on $port"
  "$TMUX_BIN" new-session -d -s "$session_name" "$command_file"

  if ! wait_for_health "$name" "$port"; then
    warn "Recent log output for $name:"
    tail -n 40 "$log_file" >&2 || true
    return 1
  fi

  return 0
}

start_stdio_bridge() {
  local name="$1"
  local port="$2"
  local command_string="$3"

  start_managed_process \
    "$name" \
    "$port" \
    "$SUPERGATEWAY_BIN" \
    --stdio "$command_string" \
    --outputTransport streamableHttp \
    --port "$port" \
    --streamableHttpPath /mcp \
    --stateful \
    --healthEndpoint /healthz \
    --logLevel info
}

stop_managed_process() {
  local name="$1"
  local session_name="executor-mcp-${name}"

  if "$TMUX_BIN" has-session -t "$session_name" >/dev/null 2>&1; then
    warn "Stopping tmux session $session_name"
    "$TMUX_BIN" kill-session -t "$session_name" >/dev/null 2>&1 || true
  fi

  rm -f "$COMMAND_DIR/${name}.sh"
}

api_sources() {
  "$CURL_BIN" -fsS \
    -H "x-executor-account-id: $ACCOUNT_ID" \
    "$BASE_URL/v1/workspaces/$WORKSPACE_ID/sources"
}

delete_source() {
  local source_id="$1"
  "$CURL_BIN" -fsS \
    -X DELETE \
    -H "x-executor-account-id: $ACCOUNT_ID" \
    "$BASE_URL/v1/workspaces/$WORKSPACE_ID/sources/$source_id" >/dev/null
}

remove_matching_sources() {
  local name="$1"
  local namespace="$2"

  while IFS=$'\t' read -r source_id source_name source_endpoint source_status; do
    [[ -z "$source_id" ]] && continue
    warn "Removing source $source_name ($source_status) at $source_endpoint"
    delete_source "$source_id"
  done < <(
    api_sources | "$JQ_BIN" -r --arg namespace "$namespace" --arg name "$name" '
      .[] | select(.namespace == $namespace or .name == $name) |
      [.id, .name, .endpoint, .status] | @tsv
    '
  )

  return 0
}

ensure_executor() {
  local doctor_json reachable

  doctor_json="$("$EXECUTOR_BIN" doctor --json 2>/dev/null || true)"
  reachable="$(printf '%s' "$doctor_json" | "$JQ_BIN" -r '.status.reachable // false' 2>/dev/null || echo false)"

  if [[ "$reachable" != "true" ]]; then
    info "Starting executor daemon"
    "$EXECUTOR_BIN" up >/dev/null
    doctor_json="$("$EXECUTOR_BIN" doctor --json)"
  fi

  ACCOUNT_ID="$(printf '%s' "$doctor_json" | "$JQ_BIN" -r '.status.installation.accountId // empty')"
  WORKSPACE_ID="$(printf '%s' "$doctor_json" | "$JQ_BIN" -r '.status.installation.workspaceId // empty')"

  if [[ -z "$ACCOUNT_ID" || -z "$WORKSPACE_ID" ]]; then
    error "Executor did not report a local account/workspace"
    exit 1
  fi
}

ensure_source() {
  local name="$1"
  local namespace="$2"
  local endpoint="$3"
  local sources connected_count

  sources="$(api_sources)"
  connected_count="$(printf '%s' "$sources" | "$JQ_BIN" -r --arg namespace "$namespace" --arg endpoint "$endpoint" '
    map(select(.namespace == $namespace and .endpoint == $endpoint and .status == "connected")) | length
  ')"

  if [[ "$connected_count" != "0" ]]; then
    info "Source $namespace already connected"
    return 0
  fi

  while IFS=$'\t' read -r source_id source_name source_endpoint source_status; do
    [[ -z "$source_id" ]] && continue
    warn "Replacing existing source $source_name ($source_status) at $source_endpoint"
    delete_source "$source_id"
  done < <(
    printf '%s' "$sources" | "$JQ_BIN" -r --arg namespace "$namespace" --arg name "$name" '
      .[] | select(.namespace == $namespace or .name == $name) |
      [.id, .name, .endpoint, .status] | @tsv
    '
  )

  local script_file result source_input
  script_file="$(mktemp "${TMPDIR:-/tmp}/executor-source-add.XXXXXX.ts")"
  source_input="$("$JQ_BIN" -cn \
    --arg endpoint "$endpoint" \
    --arg name "$name" \
    --arg namespace "$namespace" \
    '{ endpoint: $endpoint, name: $name, namespace: $namespace }'
  )"
  printf 'return await tools.executor.sources.add(%s);' "$source_input" >"$script_file"

  if ! result="$("$EXECUTOR_BIN" call --file "$script_file" 2>&1)"; then
    rm -f "$script_file"
    error "Failed to add source $name"
    printf '%s\n' "$result" >&2
    return 1
  fi
  rm -f "$script_file"

  local status
  status="$(printf '%s' "$result" | "$JQ_BIN" -r '.status // empty' 2>/dev/null || true)"
  if [[ "$status" == "connected" ]]; then
    info "Connected source $namespace -> $endpoint"
    return 0
  fi

  warn "Source $name did not report connected status"
  printf '%s\n' "$result" >&2
  return 1
}

sync_direct_source() {
  local name="$1"
  local namespace="$2"
  local endpoint="$3"

  ensure_source "$name" "$namespace" "$endpoint" || FAILURES+=("$name")
}

sync_stdio_bridge_source() {
  local name="$1"
  local namespace="$2"
  local port="$3"
  local command_string="$4"

  if ! start_stdio_bridge "$name" "$port" "$command_string"; then
    remove_matching_sources "$name" "$namespace" >/dev/null || true
    FAILURES+=("$name")
    return 0
  fi

  ensure_source "$name" "$namespace" "$(bridge_url "$port")" || FAILURES+=("$name")
}

EXECUTOR_BIN="$(require_bin executor "$HOME/.local/share/mise/shims/executor")"
SUPERGATEWAY_BIN="$(require_bin supergateway "$HOME/.local/share/mise/shims/supergateway")"
TMUX_BIN="$(require_bin tmux)"
JQ_BIN="$(require_bin jq)"
CURL_BIN="$(require_bin curl)"
CODEX_BIN="$(require_bin codex "$HOME/.local/share/mise/shims/codex")"

BASE_URL="${EXECUTOR_BASE_URL:-http://127.0.0.1:8788}"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/executor-mcp-bridges"
COMMAND_DIR="$STATE_ROOT/commands"
LOG_DIR="$STATE_ROOT/logs"
mkdir -p "$COMMAND_DIR" "$LOG_DIR"

ACCOUNT_ID=""
WORKSPACE_ID=""
FAILURES=()
SKIPPED=()

ensure_executor

sync_direct_source "deepwiki" "deepwiki" "https://mcp.deepwiki.com/mcp"
sync_direct_source "grep" "grep" "https://mcp.grep.app/"
stop_managed_process "parallel"
remove_matching_sources "parallel" "parallel" >/dev/null || true
remove_matching_sources "github" "github" >/dev/null || true
remove_matching_sources "context7" "context7" >/dev/null || true

sync_stdio_bridge_source "perplexity" "perplexity" 8813 "perplexity-mcp"
sync_stdio_bridge_source "exa" "exa" 8814 "npx -y exa-mcp-server"

if command -v mcp-atlassian >/dev/null 2>&1 && have_env JIRA_URL JIRA_USERNAME JIRA_API_TOKEN CONFLUENCE_URL CONFLUENCE_USERNAME CONFLUENCE_API_TOKEN; then
  sync_stdio_bridge_source "atlassian" "atlassian" 8815 "mcp-atlassian"
else
  warn "Skipping atlassian: command or required env vars missing"
  SKIPPED+=("atlassian")
fi

if command -v huggingface-mcp-server >/dev/null 2>&1 && have_env HF_TOKEN; then
  sync_stdio_bridge_source "huggingface" "huggingface" 8816 "huggingface-mcp-server"
else
  warn "Skipping huggingface: command or HF_TOKEN missing"
  SKIPPED+=("huggingface")
fi

sync_stdio_bridge_source "effect-docs" "effect_docs" 8817 "npx -y effect-mcp@latest"

if have_env NIA_API_KEY; then
  sync_stdio_bridge_source "nia" "nia" 8818 "pipx run nia-mcp-server"
else
  warn "Skipping nia: NIA_API_KEY is not set"
  SKIPPED+=("nia")
fi

printf -v codex_command '%q mcp-server' "$CODEX_BIN"
sync_stdio_bridge_source "codex" "codex" 8820 "$codex_command"

NX_MCP_WORKSPACE="${NX_MCP_WORKSPACE:-}"
if [[ -n "$NX_MCP_WORKSPACE" ]]; then
  if [[ -f "$NX_MCP_WORKSPACE/nx.json" ]]; then
    printf -v nx_command 'npx -y nx-mcp@latest %q' "$NX_MCP_WORKSPACE"
    sync_stdio_bridge_source "nx-mcp" "nx_mcp" 8819 "$nx_command"
  else
    warn "Skipping nx-mcp: $NX_MCP_WORKSPACE is not an Nx workspace root"
    SKIPPED+=("nx-mcp")
  fi
else
  warn "Skipping nx-mcp: set NX_MCP_WORKSPACE to an Nx workspace root"
  stop_managed_process "nx-mcp"
  remove_matching_sources "nx-mcp" "nx_mcp" >/dev/null || true
  SKIPPED+=("nx-mcp")
fi

echo
info "Executor MCP sync complete"

if ((${#SKIPPED[@]} > 0)); then
  printf 'Skipped: %s\n' "${SKIPPED[*]}"
fi

if ((${#FAILURES[@]} > 0)); then
  error "Failed sources: ${FAILURES[*]}"
  exit 1
fi
