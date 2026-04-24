#!/usr/bin/env bash
# Reconcile the desired MCP + OpenAPI source inventory into the local Executor runtime.
#
# Every source is a hosted remote endpoint. Auth is either header-based secrets
# or persisted Executor OAuth connections. The only local process is the
# Executor runtime itself.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

EXECUTOR_BIN="$(prefer_fallback_bin executor "$EXECUTOR_MISE_SHIM")"
TMUX_BIN="$(require_bin tmux)"
JQ_BIN="$(require_bin jq)"
CURL_BIN="$(require_bin curl)"
PYTHON_BIN="$(require_bin python3)"
BASE64_BIN="$(require_bin base64)"

BASE_URL="$EXECUTOR_BASE_URL"
OPENAPI_SPEC_DIR="$EXECUTOR_SCRIPT_DIR/openapi"
mkdir -p "$EXECUTOR_RUNTIME_LOG_DIR"

# Reload the canonical credential fragments so manual runs don't reuse stale
# shell exports after a secret rotation.
source_executor_env_files

SCOPE_ID=""
HTTP_STATUS=""
HTTP_BODY=""
FAILURES=()
SKIPPED=()

migrate_legacy_scope_config() {
  local config_file="$EXECUTOR_SCOPE_DIR/executor.jsonc"
  local sources_type backup_file

  [[ -f "$config_file" ]] || return 0

  sources_type="$("$JQ_BIN" -r '
    if type == "object" and has("sources") then
      (.sources | type)
    else
      ""
    end
  ' "$config_file" 2>/dev/null || true)"

  [[ "$sources_type" == "object" ]] || return 0

  backup_file="${config_file}.legacy-$(date +%Y%m%d%H%M%S).bak"
  cp "$config_file" "$backup_file"
  cat >"$config_file" <<'EOF'
{
  "sources": []
}
EOF

  warn "Backed up legacy Executor config to $backup_file"
  warn "Reset object-shaped executor.jsonc to a modern empty source array"
}

api() {
  local method="$1" path="$2" payload="${3:-}"
  local body_file; body_file="$(mktemp "${TMPDIR:-/tmp}/executor-api.XXXXXX")"
  local curl_status=0 args=(-sS -o "$body_file" -w '%{http_code}' -X "$method")

  if [[ -n "$payload" ]]; then
    args+=(-H 'content-type: application/json' -d "$payload")
  fi

  HTTP_STATUS="$("$CURL_BIN" "${args[@]}" "${BASE_URL%/}/api${path}")" || curl_status=$?
  HTTP_BODY="$(cat "$body_file")"
  rm -f "$body_file"

  (( curl_status == 0 )) && [[ "$HTTP_STATUS" =~ ^2 ]]
}

wait_for_ready() {
  local attempts=0
  while (( attempts < 30 )); do
    if "$CURL_BIN" -fsS "${BASE_URL%/}/api/docs" >/dev/null 2>&1; then
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 1
  done
  return 1
}

start_runtime() {
  local log_file="$EXECUTOR_RUNTIME_LOG_DIR/runtime.log"
  local pids pid

  "$EXECUTOR_BIN" daemon stop --base-url "$BASE_URL" >/dev/null 2>&1 || true

  pids="$(lsof -ti ":$EXECUTOR_WEB_PORT" 2>/dev/null || true)"
  for pid in $pids; do
    [[ -z "$pid" ]] && continue
    kill "$pid" 2>/dev/null || true
  done

  info "Starting Executor runtime on :$EXECUTOR_WEB_PORT"
  "$TMUX_BIN" has-session -t "$EXECUTOR_RUNTIME_SESSION_NAME" >/dev/null 2>&1 && \
    "$TMUX_BIN" kill-session -t "$EXECUTOR_RUNTIME_SESSION_NAME" >/dev/null 2>&1 || true
  "$TMUX_BIN" new-session -d -s "$EXECUTOR_RUNTIME_SESSION_NAME" \
    "exec </dev/null >$log_file 2>&1; exec $(printf '%q ' "$EXECUTOR_BIN" daemon run --port "$EXECUTOR_WEB_PORT" --hostname "$EXECUTOR_HOSTNAME" --scope "$EXECUTOR_SCOPE_DIR")"

  if ! wait_for_ready; then
    error "Executor runtime did not become ready"
    tail -n 40 "$log_file" >&2 || true
    exit 1
  fi
}

ensure_runtime() {
  mkdir -p "$EXECUTOR_SCOPE_DIR"
  migrate_legacy_scope_config

  if api GET /scope; then
    local dir; dir="$(printf '%s' "$HTTP_BODY" | "$JQ_BIN" -r '.dir // empty' 2>/dev/null || true)"
    if [[ "$dir" == "$EXECUTOR_SCOPE_DIR" ]]; then
      SCOPE_ID="$(printf '%s' "$HTTP_BODY" | "$JQ_BIN" -r '.id // empty')"
      info "Executor runtime already serving $EXECUTOR_SCOPE_DIR"
      return 0
    fi
    warn "Executor runtime serving '$dir'; restarting against $EXECUTOR_SCOPE_DIR"
  fi

  start_runtime

  if ! api GET /scope; then
    error "Executor runtime did not return scope metadata"
    printf '%s\n' "$HTTP_BODY" >&2
    exit 1
  fi

  SCOPE_ID="$(printf '%s' "$HTTP_BODY" | "$JQ_BIN" -r '.id // empty')"
  if [[ -z "$SCOPE_ID" ]]; then
    error "Executor did not return a scope id"
    exit 1
  fi
}

current_json_or_empty() {
  local path="$1"
  if ! api GET "$path"; then
    return 1
  fi

  if [[ "$HTTP_BODY" == "null" ]]; then
    return 1
  fi

  return 0
}

delete_source_id() {
  local source_id="$1"
  if api DELETE "/scopes/$SCOPE_ID/sources/$source_id"; then
    info "Removed source $source_id"
  else
    warn "Failed to remove source $source_id: $HTTP_BODY"
  fi
}

remove_sources_by_kind_url() {
  local kind="$1" url="$2" keep_id="${3:-}"
  local sources_json

  if ! api GET "/scopes/$SCOPE_ID/sources"; then
    warn "Failed to list sources for cleanup: $HTTP_BODY"
    return 0
  fi

  sources_json="$HTTP_BODY"
  while IFS=$'\t' read -r source_id source_name; do
    [[ -z "$source_id" ]] && continue
    [[ -n "$keep_id" && "$source_id" == "$keep_id" ]] && continue
    warn "Removing stale source $source_id ($source_name) for $url"
    delete_source_id "$source_id"
  done < <(
    printf '%s' "$sources_json" | "$JQ_BIN" -r \
      --arg kind "$kind" \
      --arg url "$url" '
        .[]
        | select(.kind == $kind and .url == $url)
        | [.id, .name]
        | @tsv
      '
  )
}

remove_source_id_if_kind_mismatch() {
  local source_id="$1" desired_kind="$2"
  local sources_json

  if ! api GET "/scopes/$SCOPE_ID/sources"; then
    warn "Failed to list sources for kind migration cleanup: $HTTP_BODY"
    return 0
  fi

  sources_json="$HTTP_BODY"
  while IFS=$'\t' read -r actual_kind source_name; do
    [[ -z "$actual_kind" ]] && continue
    warn "Removing stale $actual_kind source $source_id ($source_name) before reconciling as $desired_kind"
    delete_source_id "$source_id"
  done < <(
    printf '%s' "$sources_json" | "$JQ_BIN" -r \
      --arg source_id "$source_id" \
      --arg desired_kind "$desired_kind" '
        .[]
        | select(.id == $source_id and .kind != $desired_kind)
        | [.kind, .name]
        | @tsv
      '
  )
}

ensure_secret() {
  local secret_id="$1" secret_name="$2" secret_value="$3"
  local payload

  payload="$("$JQ_BIN" -cn \
    --arg id "$secret_id" \
    --arg name "$secret_name" \
    --arg value "$secret_value" \
    '{ id: $id, name: $name, value: $value }'
  )"

  if ! api POST "/scopes/$SCOPE_ID/secrets" "$payload"; then
    warn "Failed to store secret $secret_id: $HTTP_BODY"
    return 1
  fi
}

reconcile_mcp() {
  local name="$1" namespace="$2" endpoint="$3" transport="$4" headers_json="$5" auth_json="$6"
  local payload existing

  payload="$("$JQ_BIN" -cn \
    --arg name "$name" \
    --arg namespace "$namespace" \
    --arg endpoint "$endpoint" \
    --arg transport "$transport" \
    --argjson headers "$headers_json" \
    --argjson auth "$auth_json" '
      {
        transport: "remote",
        name: $name,
        namespace: $namespace,
        endpoint: $endpoint,
        remoteTransport: $transport,
        headers: $headers,
        queryParams: {},
        auth: $auth
      }'
  )"

  remove_source_id_if_kind_mismatch "$namespace" "mcp"
  remove_sources_by_kind_url "mcp" "$endpoint" "$namespace"

  if current_json_or_empty "/scopes/$SCOPE_ID/mcp/sources/$namespace"; then
    existing="$HTTP_BODY"
    local desired_shape cur_shape
    desired_shape="$("$JQ_BIN" -cS --arg name "$name" --arg endpoint "$endpoint" \
      --arg transport "$transport" --argjson headers "$headers_json" \
      --argjson auth "$auth_json" \
      -n '{name:$name, endpoint:$endpoint, transport:$transport, headers:$headers, auth:$auth}')"
    cur_shape="$(printf '%s' "$existing" | "$JQ_BIN" -cS '{
      name: .name,
      endpoint: .config.endpoint,
      transport: (.config.remoteTransport // "auto"),
      headers: (.config.headers // {}),
      auth: .config.auth
    }')"

    if [[ "$desired_shape" == "$cur_shape" ]]; then
      info "MCP source $namespace already up to date"
      return 0
    fi

    local patch_payload
    patch_payload="$("$JQ_BIN" -cn \
      --arg name "$name" \
      --arg endpoint "$endpoint" \
      --argjson headers "$headers_json" \
      --argjson auth "$auth_json" \
      '{ name: $name, endpoint: $endpoint, headers: $headers, queryParams: {}, auth: $auth }')"
    if api PATCH "/scopes/$SCOPE_ID/mcp/sources/$namespace" "$patch_payload"; then
      info "Updated MCP source $namespace"
    else
      warn "Patch failed for $name; recreating"
      api POST "/scopes/$SCOPE_ID/mcp/sources/remove" "$("$JQ_BIN" -cn --arg namespace "$namespace" '{ namespace: $namespace }')" >/dev/null || true
      if ! api POST "/scopes/$SCOPE_ID/mcp/sources" "$payload"; then
        warn "Failed to recreate MCP source $name: $HTTP_BODY"
        FAILURES+=("$name")
        return 0
      fi
      info "Recreated MCP source $namespace"
    fi
  else
    if ! api POST "/scopes/$SCOPE_ID/mcp/sources" "$payload"; then
      warn "Failed to add MCP source $name: $HTTP_BODY"
      FAILURES+=("$name")
      return 0
    fi
    info "Added MCP source $namespace"
  fi

  local refresh_payload
  refresh_payload="$("$JQ_BIN" -cn --arg namespace "$namespace" '{ namespace: $namespace }')"
  if api POST "/scopes/$SCOPE_ID/mcp/sources/refresh" "$refresh_payload"; then
    local tool_count
    tool_count="$(printf '%s' "$HTTP_BODY" | "$JQ_BIN" -r '.toolCount // empty' 2>/dev/null || true)"
    [[ -n "$tool_count" ]] && info "  $namespace: $tool_count tools"
  else
    warn "Refresh failed for $name: $HTTP_BODY"
  fi
}

reconcile_openapi() {
  local name="$1" namespace="$2" base_url="$3" spec_json="$4" headers_json="$5"
  local payload existing

  payload="$("$JQ_BIN" -cn \
    --arg name "$name" \
    --arg namespace "$namespace" \
    --arg baseUrl "$base_url" \
    --arg spec "$spec_json" \
    --argjson headers "$headers_json" \
    '{ name: $name, namespace: $namespace, baseUrl: $baseUrl, spec: $spec, headers: $headers }'
  )"

  remove_source_id_if_kind_mismatch "$namespace" "openapi"

  if current_json_or_empty "/scopes/$SCOPE_ID/openapi/sources/$namespace"; then
    existing="$HTTP_BODY"
    local desired_spec current_spec desired_rest current_rest
    desired_spec="$(printf '%s' "$spec_json" | "$JQ_BIN" -cS '.')"
    current_spec="$(printf '%s' "$existing" | "$JQ_BIN" -r '.config.spec // "{}"' | "$JQ_BIN" -cS '.')"
    desired_rest="$("$JQ_BIN" -cS -n --arg name "$name" --arg baseUrl "$base_url" \
      --argjson headers "$headers_json" '{name:$name, baseUrl:$baseUrl, headers:$headers}')"
    current_rest="$(printf '%s' "$existing" | "$JQ_BIN" -cS '{
      name: .name,
      baseUrl: .config.baseUrl,
      headers: (.config.headers // {})
    }')"

    if [[ "$desired_spec" == "$current_spec" && "$desired_rest" == "$current_rest" ]]; then
      info "OpenAPI source $namespace already up to date"
      return 0
    fi

    if [[ "$desired_spec" != "$current_spec" ]]; then
      warn "OpenAPI spec changed for $name; recreating"
      api DELETE "/scopes/$SCOPE_ID/sources/$namespace" >/dev/null || true
      if ! api POST "/scopes/$SCOPE_ID/openapi/specs" "$payload"; then
        warn "Failed to recreate OpenAPI source $name: $HTTP_BODY"
        FAILURES+=("$name")
        return 0
      fi
      info "Recreated OpenAPI source $namespace"
      return 0
    fi

    local patch_payload
    patch_payload="$("$JQ_BIN" -cn --arg name "$name" --arg baseUrl "$base_url" \
      --argjson headers "$headers_json" '{name:$name, baseUrl:$baseUrl, headers:$headers}')"
    if api PATCH "/scopes/$SCOPE_ID/openapi/sources/$namespace" "$patch_payload"; then
      info "Updated OpenAPI source $namespace"
    else
      warn "Patch failed for $name: $HTTP_BODY"
      FAILURES+=("$name")
    fi
  else
    if ! api POST "/scopes/$SCOPE_ID/openapi/specs" "$payload"; then
      warn "Failed to add OpenAPI source $name: $HTTP_BODY"
      FAILURES+=("$name")
      return 0
    fi
    info "Added OpenAPI source $namespace"
  fi
}

auth_none_json() {
  "$JQ_BIN" -cn '{ kind: "none" }'
}

auth_header_json() {
  local header_name="$1" secret_id="$2" prefix="${3:-}"

  if [[ -n "$prefix" ]]; then
    "$JQ_BIN" -cn \
      --arg headerName "$header_name" \
      --arg secretId "$secret_id" \
      --arg prefix "$prefix" \
      '{ kind: "header", headerName: $headerName, secretId: $secretId, prefix: $prefix }'
  else
    "$JQ_BIN" -cn \
      --arg headerName "$header_name" \
      --arg secretId "$secret_id" \
      '{ kind: "header", headerName: $headerName, secretId: $secretId }'
  fi
}

auth_oauth_json() {
  local connection_id="$1"
  "$JQ_BIN" -cn --arg connectionId "$connection_id" \
    '{ kind: "oauth2", connectionId: $connectionId }'
}

secret_header_ref_json() {
  local secret_id="$1" prefix="${2:-}"

  if [[ -n "$prefix" ]]; then
    "$JQ_BIN" -cn --arg secretId "$secret_id" --arg prefix "$prefix" \
      '{ secretId: $secretId, prefix: $prefix }'
  else
    "$JQ_BIN" -cn --arg secretId "$secret_id" '{ secretId: $secretId }'
  fi
}

connection_exists() {
  local connection_id="$1"

  if ! api GET "/scopes/$SCOPE_ID/connections"; then
    warn "Failed to list Executor connections: $HTTP_BODY"
    return 1
  fi

  printf '%s' "$HTTP_BODY" | "$JQ_BIN" -e \
    --arg connectionId "$connection_id" \
    '.[] | select(.id == $connectionId)' >/dev/null
}

control_plane_spec() {
  "$CURL_BIN" -fsS "${BASE_URL%/}/api/docs" | "$PYTHON_BIN" -c '
import json, re, sys
m = re.search(r"<script id=\"swagger-spec\" type=\"application/json\">(.*?)</script>", sys.stdin.read(), re.S)
if not m:
    sys.exit(1)
print(json.dumps(json.loads(m.group(1)), separators=(",", ":")))
'
}

# --- main ---------------------------------------------------------------------

ensure_runtime

# MCP sources: no-auth hosted endpoints.
for spec in \
  "deepwiki|deepwiki|https://mcp.deepwiki.com/mcp|streamable-http" \
  "grep|grep|https://mcp.grep.app/|auto"
do
  IFS='|' read -r name namespace endpoint transport <<<"$spec"
  reconcile_mcp "$name" "$namespace" "$endpoint" "$transport" '{}' "$(auth_none_json)"
done

# MCP sources: secret-backed hosted endpoints.
if have_env EXA_API_KEY; then
  if ensure_secret "exa_api_key" "Exa API Key" "$EXA_API_KEY"; then
    reconcile_mcp "exa" "exa" \
      "${EXA_ENDPOINT:-https://mcp.exa.ai/mcp}" "streamable-http" \
      '{}' \
      "$(auth_header_json "Authorization" "exa_api_key" "Bearer ")"
  else
    FAILURES+=("exa")
  fi
else
  warn "Skipping exa: EXA_API_KEY is not set"
  SKIPPED+=("exa")
fi

if have_env GITHUB_PERSONAL_ACCESS_TOKEN; then
  if ensure_secret "github_pat" "GitHub Personal Access Token" "$GITHUB_PERSONAL_ACCESS_TOKEN"; then
    headers="$("$JQ_BIN" -cn '{ "X-MCP-Readonly": "true" }')"
    reconcile_mcp "github" "github" \
      "https://api.githubcopilot.com/mcp/" "streamable-http" "$headers" \
      "$(auth_header_json "Authorization" "github_pat" "Bearer ")"
  else
    FAILURES+=("github")
  fi
else
  warn "Skipping github: GITHUB_PERSONAL_ACCESS_TOKEN is not set"
  SKIPPED+=("github")
fi

if have_env FIRECRAWL_API_KEY; then
  if ensure_secret "firecrawl_api_key" "Firecrawl API Key" "$FIRECRAWL_API_KEY"; then
    reconcile_mcp "firecrawl" "firecrawl" \
      "https://mcp.firecrawl.dev/v2/mcp" "streamable-http" \
      '{}' \
      "$(auth_header_json "Authorization" "firecrawl_api_key" "Bearer ")"
  else
    FAILURES+=("firecrawl")
  fi
else
  warn "Skipping firecrawl: FIRECRAWL_API_KEY is not set"
  SKIPPED+=("firecrawl")
fi

atlassian_connection_id="atlassian_oauth"
atlassian_email="${ATLASSIAN_EMAIL:-${JIRA_USERNAME:-}}"
atlassian_token="${ATLASSIAN_API_TOKEN:-${JIRA_API_TOKEN:-}}"
if connection_exists "$atlassian_connection_id"; then
  reconcile_mcp "atlassian" "atlassian" \
    "https://mcp.atlassian.com/v1/mcp" "streamable-http" \
    '{}' \
    "$(auth_oauth_json "$atlassian_connection_id")"
elif [[ -n "$atlassian_email" && -n "$atlassian_token" ]]; then
  atlassian_basic_secret="$(printf '%s:%s' "$atlassian_email" "$atlassian_token" | "$BASE64_BIN" | tr -d '\n')"
  if ensure_secret "atlassian_basic_token" "Atlassian Basic Auth Token" "$atlassian_basic_secret"; then
    reconcile_mcp "atlassian" "atlassian" \
      "https://mcp.atlassian.com/v1/mcp" "streamable-http" \
      '{}' \
      "$(auth_header_json "Authorization" "atlassian_basic_token" "Basic ")"
  else
    FAILURES+=("atlassian")
  fi
elif have_env ATLASSIAN_API_KEY; then
  if ensure_secret "atlassian_api_key" "Atlassian API Key" "$ATLASSIAN_API_KEY"; then
    reconcile_mcp "atlassian" "atlassian" \
      "https://mcp.atlassian.com/v1/mcp" "streamable-http" \
      '{}' \
      "$(auth_header_json "Authorization" "atlassian_api_key" "Bearer ")"
  else
    FAILURES+=("atlassian")
  fi
else
  warn "Skipping atlassian: set up the atlassian_oauth connection or provide ATLASSIAN_EMAIL+ATLASSIAN_API_TOKEN, JIRA_USERNAME+JIRA_API_TOKEN, or ATLASSIAN_API_KEY"
  SKIPPED+=("atlassian")
fi

# OpenAPI sources: external APIs with header-based auth.
if have_env PERPLEXITY_API_KEY; then
  if ensure_secret "perplexity_api_key" "Perplexity API Key" "$PERPLEXITY_API_KEY"; then
    headers="$("$JQ_BIN" -cn --argjson auth "$(secret_header_ref_json "perplexity_api_key" "Bearer ")" \
      '{ Authorization: $auth }')"
    reconcile_openapi "perplexity-search" "perplexity_search" \
      "https://api.perplexity.ai" \
      "$("$JQ_BIN" -cS '.' "$OPENAPI_SPEC_DIR/perplexity-search.openapi.json")" \
      "$headers"
  else
    FAILURES+=("perplexity-search")
  fi
else
  warn "Skipping perplexity-search: PERPLEXITY_API_KEY is not set"
  SKIPPED+=("perplexity-search")
fi

if have_env PARALLEL_API_KEY; then
  if ensure_secret "parallel_api_key" "Parallel API Key" "$PARALLEL_API_KEY"; then
    reconcile_mcp "parallel-search" "parallel_search" \
      "${PARALLEL_SEARCH_MCP_ENDPOINT:-https://search.parallel.ai/mcp}" \
      "streamable-http" \
      '{}' \
      "$(auth_header_json "Authorization" "parallel_api_key" "Bearer ")"
  else
    FAILURES+=("parallel-search")
  fi
else
  warn "Skipping parallel-search: PARALLEL_API_KEY is not set"
  SKIPPED+=("parallel-search")
fi

# Executor's own control plane, self-described.
if spec="$(control_plane_spec)"; then
  reconcile_openapi "executor-control-plane" "executor_control" \
    "${BASE_URL%/}/api" "$spec" '{}'
else
  warn "Skipping executor-control-plane: could not extract live OpenAPI spec"
  SKIPPED+=("executor-control-plane")
fi

echo
info "Executor sync complete"

if ((${#SKIPPED[@]} > 0)); then
  printf 'Skipped: %s\n' "${SKIPPED[*]}"
fi

if ((${#FAILURES[@]} > 0)); then
  error "Failed sources: ${FAILURES[*]}"
  exit 1
fi
