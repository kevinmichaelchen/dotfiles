#!/usr/bin/env bash
# Print the current Executor runtime and source inventory state.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

BASE_URL="$EXECUTOR_BASE_URL"
JQ_BIN="$(require_bin jq)"
CURL_BIN="$(require_bin curl)"
LSOF_BIN="$(resolve_bin lsof || true)"

if ! scope_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scope" 2>/dev/null)"; then
  error "Executor runtime is not reachable at ${BASE_URL%/}"
  exit 1
fi

daemon_pid=""
if [[ -n "$LSOF_BIN" ]]; then
  daemon_pid="$("$LSOF_BIN" -tiTCP:"${EXECUTOR_WEB_PORT}" -sTCP:LISTEN -n -P 2>/dev/null | head -n 1 || true)"
fi

SCOPE_ID="$(printf '%s' "$scope_json" | "$JQ_BIN" -r '.id // empty')"

if [[ -n "$daemon_pid" ]]; then
  printf 'Daemon reachable at %s (pid %s).\n' "${BASE_URL%/}" "$daemon_pid"
else
  printf 'Daemon reachable at %s.\n' "${BASE_URL%/}"
fi
printf 'Scope: %s\n\n' "$(printf '%s' "$scope_json" | "$JQ_BIN" -r '.dir // empty')"

printf '%-18s %-10s %-28s %s\n' "ID" "KIND" "NAME" "TOOLS"
printf '%-18s %-10s %-28s %s\n' "--" "----" "----" "-----"

print_row() {
  printf '%-18s %-10s %-28s %s\n' "$1" "$2" "$3" "$4"
}

tool_count_for_source() {
  local source_id="$1"
  "$CURL_BIN" -fsS "${BASE_URL%/}/api/scopes/$SCOPE_ID/sources/$source_id/tools" | "$JQ_BIN" 'length'
}

show_mcp_source() {
  local namespace="$1" source_json name tool_count
  source_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scopes/$SCOPE_ID/mcp/sources/$namespace" 2>/dev/null || true)"
  [[ -n "$source_json" && "$source_json" != "null" ]] || return 0
  name="$(printf '%s' "$source_json" | "$JQ_BIN" -r '.name // .namespace')"
  tool_count="$(tool_count_for_source "$namespace")"
  print_row "$namespace" "mcp" "$name" "$tool_count"
}

show_openapi_source() {
  local namespace="$1" source_json name tool_count
  source_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scopes/$SCOPE_ID/openapi/sources/$namespace" 2>/dev/null || true)"
  [[ -n "$source_json" && "$source_json" != "null" ]] || return 0
  name="$(printf '%s' "$source_json" | "$JQ_BIN" -r '.name // .namespace')"
  tool_count="$(tool_count_for_source "$namespace")"
  print_row "$namespace" "openapi" "$name" "$tool_count"
}

show_control_source() {
  local source_id="$1" name="$2" tool_count
  tool_count="$(tool_count_for_source "$source_id" 2>/dev/null || true)"
  [[ -n "$tool_count" ]] || return 0
  print_row "$source_id" "control" "$name" "$tool_count"
}

show_mcp_source "deepwiki"
show_mcp_source "grep"
show_mcp_source "exa"
show_mcp_source "github"
show_mcp_source "firecrawl"
show_mcp_source "atlassian"
show_control_source "graphql" "GraphQL"
show_openapi_source "executor_control"
show_control_source "openapi" "OpenAPI"
show_mcp_source "parallel_search"
show_openapi_source "perplexity_search"
