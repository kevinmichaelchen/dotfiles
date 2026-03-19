#!/usr/bin/env bash
# Sync local MCP inventory into executor, bridging stdio MCP servers to local HTTP.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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

prefer_fallback_bin() {
  local name="$1"
  local fallback="${2:-}"

  if [[ -n "$fallback" && -x "$fallback" ]]; then
    printf '%s\n' "$fallback"
    return 0
  fi

  require_bin "$name"
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

spec_url() {
  local filename="$1"
  printf 'http://127.0.0.1:%s/%s\n' "$OPENAPI_SPEC_PORT" "$filename"
}

control_plane_spec_url() {
  printf '%s/v1/openapi.json\n' "${BASE_URL%/}"
}

wait_for_health() {
  local name="$1"
  local url="$2"
  local attempts=0

  while (( attempts < 30 )); do
    if "$CURL_BIN" -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 1
  done

  warn "Service $name did not become healthy at $url"
  return 1
}

start_managed_process_with_ready_url() {
  local name="$1"
  local port="$2"
  local ready_url="$3"
  shift 3

  local log_file="$LOG_DIR/${name}.log"
  local command_file="$COMMAND_DIR/${name}.sh"
  local session_name="executor-mcp-${name}"

  if "$CURL_BIN" -fsS "$ready_url" >/dev/null 2>&1; then
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

  if ! wait_for_health "$name" "$ready_url"; then
    warn "Recent log output for $name:"
    tail -n 40 "$log_file" >&2 || true
    return 1
  fi

  return 0
}

start_managed_process() {
  local name="$1"
  local port="$2"
  shift 2

  start_managed_process_with_ready_url "$name" "$port" "$(health_url "$port")" "$@"
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

start_static_server() {
  local name="$1"
  local port="$2"
  local directory="$3"

  start_managed_process_with_ready_url \
    "$name" \
    "$port" \
    "http://127.0.0.1:${port}/" \
    "$PYTHON_BIN" \
    -m http.server "$port" \
    --bind 127.0.0.1 \
    --directory "$directory"
}

sync_tmux_env() {
  local key

  for key in "$@"; do
    if [[ -n "${!key:-}" ]]; then
      "$TMUX_BIN" set-environment -g "$key" "${!key}"
    else
      "$TMUX_BIN" set-environment -gu "$key" >/dev/null 2>&1 || true
    fi
  done
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

connect_source() {
  local payload="$1"
  "$CURL_BIN" -fsS \
    -X POST \
    -H "content-type: application/json" \
    -H "x-executor-account-id: $ACCOUNT_ID" \
    "$BASE_URL/v1/workspaces/$WORKSPACE_ID/sources/connect" \
    -d "$payload"
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
  script_file="$(mktemp "${TMPDIR:-/tmp}/executor-source-add.XXXXXX")"
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

ensure_openapi_source() {
  local name="$1"
  local namespace="$2"
  local endpoint="$3"
  local spec_url="$4"
  local auth_json="$5"
  local sources existing source_id matches connect_payload result status

  sources="$(api_sources)"
  existing="$(
    printf '%s' "$sources" | "$JQ_BIN" -c --arg name "$name" '
      map(select(.kind == "openapi" and .name == $name)) | first
    '
  )"

  if [[ "$existing" != "null" ]]; then
    matches="$(
      printf '%s' "$existing" | "$JQ_BIN" -r \
        --arg endpoint "$endpoint" \
        --arg namespace "$namespace" \
        --arg specUrl "$spec_url" '
          if .endpoint == $endpoint
            and .namespace == $namespace
            and .specUrl == $specUrl
            and .status == "connected"
            and .enabled == true
          then
            "true"
          else
            "false"
          end
        '
    )"

    if [[ "$matches" == "true" ]]; then
      info "Source $namespace already connected"
      return 0
    fi

    source_id="$(printf '%s' "$existing" | "$JQ_BIN" -r '.id')"
    warn "Replacing existing OpenAPI source $name"
    delete_source "$source_id"
  fi

  connect_payload="$("$JQ_BIN" -cn \
    --arg name "$name" \
    --arg namespace "$namespace" \
    --arg endpoint "$endpoint" \
    --arg specUrl "$spec_url" \
    --argjson auth "$auth_json" \
    '
      {
        name: $name,
        kind: "openapi",
        endpoint: $endpoint,
        namespace: $namespace,
        specUrl: $specUrl,
        auth: $auth
      }
    '
  )"

  info "Connecting OpenAPI source $name"
  result="$(connect_source "$connect_payload")"
  status="$(printf '%s' "$result" | "$JQ_BIN" -r '.kind // empty' 2>/dev/null || true)"
  if [[ "$status" != "connected" ]]; then
    warn "OpenAPI source $name did not connect cleanly"
    printf '%s\n' "$result" >&2
    return 1
  fi

  result="$(printf '%s' "$result" | "$JQ_BIN" -c '.source')"
  status="$(printf '%s' "$result" | "$JQ_BIN" -r '.status // empty' 2>/dev/null || true)"
  if [[ "$status" != "connected" ]]; then
    warn "OpenAPI source $name did not report connected status"
    printf '%s\n' "$result" >&2
    return 1
  fi

  info "Connected source $namespace -> $endpoint"
  return 0
}

sync_openapi_source() {
  local name="$1"
  local namespace="$2"
  local endpoint="$3"
  local spec_url="$4"
  local auth_json="$5"

  ensure_openapi_source "$name" "$namespace" "$endpoint" "$spec_url" "$auth_json" || FAILURES+=("$name")
}

EXECUTOR_BIN="$(prefer_fallback_bin executor "$HOME/.local/share/mise/shims/executor")"
SUPERGATEWAY_BIN="$(prefer_fallback_bin supergateway "$HOME/.local/share/mise/shims/supergateway")"
GITHUB_MCP_BIN="$(resolve_bin github-mcp-server "$HOME/.local/share/mise/shims/github-mcp-server" || true)"
TMUX_BIN="$(require_bin tmux)"
JQ_BIN="$(require_bin jq)"
CURL_BIN="$(require_bin curl)"
PYTHON_BIN="$(require_bin python3)"

BASE_URL="${EXECUTOR_BASE_URL:-http://127.0.0.1:8788}"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/executor-mcp-bridges"
COMMAND_DIR="$STATE_ROOT/commands"
LOG_DIR="$STATE_ROOT/logs"
OPENAPI_SPEC_DIR="$SCRIPT_DIR/executor-openapi"
OPENAPI_SPEC_PORT="${EXECUTOR_OPENAPI_SPEC_PORT:-8821}"
mkdir -p "$COMMAND_DIR" "$LOG_DIR"

ACCOUNT_ID=""
WORKSPACE_ID=""
FAILURES=()
SKIPPED=()

ensure_executor

if [[ ! -d "$OPENAPI_SPEC_DIR" ]]; then
  error "Missing OpenAPI spec directory: $OPENAPI_SPEC_DIR"
  exit 1
fi

start_static_server "openapi-specs" "$OPENAPI_SPEC_PORT" "$OPENAPI_SPEC_DIR"
sync_tmux_env \
  GITHUB_PERSONAL_ACCESS_TOKEN \
  EXA_API_KEY \
  JIRA_URL \
  JIRA_USERNAME \
  JIRA_API_TOKEN \
  CONFLUENCE_URL \
  CONFLUENCE_USERNAME \
  CONFLUENCE_API_TOKEN \
  HF_TOKEN \
  NIA_API_KEY \
  FIRECRAWL_API_KEY

no_auth="$("$JQ_BIN" -cn '{ kind: "none" }')"

if "$CURL_BIN" -fsS "$(control_plane_spec_url)" >/dev/null 2>&1; then
  sync_openapi_source \
    "executor-control-plane" \
    "executor_control" \
    "${BASE_URL%/}/" \
    "$(control_plane_spec_url)" \
    "$no_auth"
else
  warn "Skipping executor-control-plane: $(control_plane_spec_url) is unavailable"
  remove_matching_sources "executor-control-plane" "executor_control" >/dev/null || true
  SKIPPED+=("executor-control-plane")
fi

sync_direct_source "deepwiki" "deepwiki" "https://mcp.deepwiki.com/mcp"
sync_direct_source "grep" "grep" "https://mcp.grep.app/"
stop_managed_process "github"
remove_matching_sources "github" "github" >/dev/null || true
stop_managed_process "parallel"
remove_matching_sources "parallel" "parallel" >/dev/null || true
remove_matching_sources "parallel-search" "parallel_search" >/dev/null || true
remove_matching_sources "parallel-task" "parallel_task" >/dev/null || true
remove_matching_sources "context7" "context7" >/dev/null || true
stop_managed_process "codex"
remove_matching_sources "codex" "codex" >/dev/null || true

stop_managed_process "perplexity"
remove_matching_sources "perplexity" "perplexity" >/dev/null || true
stop_managed_process "atlassian"
remove_matching_sources "atlassian" "atlassian" >/dev/null || true
stop_managed_process "huggingface"
remove_matching_sources "huggingface" "huggingface" >/dev/null || true
stop_managed_process "nia"
remove_matching_sources "nia" "nia" >/dev/null || true

if have_env PERPLEXITY_API_KEY; then
  perplexity_auth="$("$JQ_BIN" -cn --arg token "$PERPLEXITY_API_KEY" '
    {
      kind: "bearer",
      headerName: "Authorization",
      prefix: "Bearer ",
      token: $token
    }
  ')"
  sync_openapi_source \
    "perplexity-search" \
    "perplexity_search" \
    "https://api.perplexity.ai/" \
    "$(spec_url "perplexity-search.openapi.json")" \
    "$perplexity_auth"
else
  warn "Skipping perplexity-search: PERPLEXITY_API_KEY is not set"
  SKIPPED+=("perplexity-search")
fi

if have_env PARALLEL_API_KEY; then
  parallel_auth="$("$JQ_BIN" -cn --arg token "$PARALLEL_API_KEY" '
    {
      kind: "bearer",
      headerName: "x-api-key",
      prefix: "",
      token: $token
    }
  ')"
  sync_openapi_source \
    "parallel-search" \
    "parallel_search" \
    "https://api.parallel.ai/" \
    "$(spec_url "parallel-search.openapi.json")" \
    "$parallel_auth"
else
  warn "Skipping parallel-search: PARALLEL_API_KEY is not set"
  SKIPPED+=("parallel-search")
fi

if [[ -n "$GITHUB_MCP_BIN" ]] && have_env GITHUB_PERSONAL_ACCESS_TOKEN; then
  github_toolsets="actions,code_security,dependabot,discussions,gists,issues,labels,orgs,projects,pull_requests,repos,secret_protection,security_advisories,stargazers,users"
  sync_stdio_bridge_source \
    "github" \
    "github" \
    8822 \
    "$GITHUB_MCP_BIN stdio --read-only --toolsets $github_toolsets"
else
  warn "Skipping github: command or GITHUB_PERSONAL_ACCESS_TOKEN missing"
  SKIPPED+=("github")
fi

sync_stdio_bridge_source "exa" "exa" 8814 "npx -y exa-mcp-server"

sync_stdio_bridge_source "effect-docs" "effect_docs" 8817 "npx -y effect-mcp@latest"

if have_env FIRECRAWL_API_KEY; then
  sync_stdio_bridge_source "firecrawl" "firecrawl" 8820 "npx -y firecrawl-mcp"
else
  warn "Skipping firecrawl: FIRECRAWL_API_KEY is not set"
  SKIPPED+=("firecrawl")
fi

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
