#!/usr/bin/env bash
# Register the local Paper Desktop MCP server with the shared Executor scope.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

BASE_URL="$EXECUTOR_BASE_URL"
PAPER_MCP_ENDPOINT="${PAPER_MCP_ENDPOINT:-http://127.0.0.1:29979/mcp}"
PAPER_MCP_NAMESPACE="${PAPER_MCP_NAMESPACE:-paper}"
PAPER_MCP_NAME="${PAPER_MCP_NAME:-Paper Desktop}"

CURL_BIN="$(require_bin curl)"
JQ_BIN="$(require_bin jq)"

if ! scope_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scope" 2>/dev/null)"; then
  error "Executor runtime is not reachable at ${BASE_URL%/}"
  exit 1
fi

scope_id="$(printf '%s' "$scope_json" | "$JQ_BIN" -r '.id // empty')"
if [[ -z "$scope_id" ]]; then
  error "Executor runtime did not return a scope id"
  exit 1
fi

if ! probe_json="$(
  "$CURL_BIN" -fsS \
    -X POST "${BASE_URL%/}/api/scopes/$scope_id/mcp/probe" \
    -H 'content-type: application/json' \
    --data "$("$JQ_BIN" -nc --arg endpoint "$PAPER_MCP_ENDPOINT" '{endpoint: $endpoint}')" \
    2>/dev/null
)"; then
  error "Paper MCP endpoint is not reachable at $PAPER_MCP_ENDPOINT"
  error "Open Paper Desktop with a design file, then retry."
  exit 1
fi

connected="$(printf '%s' "$probe_json" | "$JQ_BIN" -r '.connected // false')"
if [[ "$connected" != "true" ]]; then
  error "Executor probe did not connect to Paper MCP at $PAPER_MCP_ENDPOINT"
  printf '%s\n' "$probe_json" | "$JQ_BIN" '.' >&2
  exit 1
fi

tool_count="$(printf '%s' "$probe_json" | "$JQ_BIN" -r '.toolCount // "unknown"')"
server_name="$(printf '%s' "$probe_json" | "$JQ_BIN" -r '.serverName // .name // "Paper MCP"')"

payload="$(
  "$JQ_BIN" -nc \
    --arg name "$PAPER_MCP_NAME" \
    --arg namespace "$PAPER_MCP_NAMESPACE" \
    --arg endpoint "$PAPER_MCP_ENDPOINT" \
    '{
      transport: "remote",
      name: $name,
      namespace: $namespace,
      endpoint: $endpoint,
      remoteTransport: "streamable-http",
      auth: {kind: "none"}
    }'
)"

update_payload="$(
  "$JQ_BIN" -nc \
    --arg name "$PAPER_MCP_NAME" \
    --arg endpoint "$PAPER_MCP_ENDPOINT" \
    '{
      name: $name,
      endpoint: $endpoint,
      remoteTransport: "streamable-http",
      auth: {kind: "none"}
    }'
)"

if source_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scopes/$scope_id/mcp/sources/$PAPER_MCP_NAMESPACE" 2>/dev/null)"; then
  if [[ -n "$source_json" && "$source_json" != "null" ]]; then
    "$CURL_BIN" -fsS \
      -X PATCH "${BASE_URL%/}/api/scopes/$scope_id/mcp/sources/$PAPER_MCP_NAMESPACE" \
      -H 'content-type: application/json' \
      --data "$update_payload" >/dev/null
    info "Updated $PAPER_MCP_NAMESPACE MCP source for $server_name ($tool_count tools)"
    exit 0
  fi
fi

"$CURL_BIN" -fsS \
  -X POST "${BASE_URL%/}/api/scopes/$scope_id/mcp/sources" \
  -H 'content-type: application/json' \
  --data "$payload" >/dev/null

info "Added $PAPER_MCP_NAMESPACE MCP source for $server_name ($tool_count tools)"
