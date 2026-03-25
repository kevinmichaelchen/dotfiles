#!/usr/bin/env bash
# Bootstrap Atlassian Rovo MCP OAuth for the local Executor workspace.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

BASE_URL="$EXECUTOR_BASE_URL"
EXECUTOR_BIN="$(prefer_fallback_bin executor "$HOME/.local/share/mise/shims/executor")" || {
  error "executor not found"
  exit 1
}
JQ_BIN="$(require_bin jq)"
CURL_BIN="$(require_bin curl)"
OPEN_BIN="$(resolve_bin open || true)"

"$EXECUTOR_SYNC_SCRIPT" >/dev/null

doctor_json="$("$EXECUTOR_BIN" doctor --json)"
ACCOUNT_ID="$(printf '%s' "$doctor_json" | "$JQ_BIN" -r '.status.installation.accountId // .status.installation.actorScopeId // empty')"
WORKSPACE_ID="$(printf '%s' "$doctor_json" | "$JQ_BIN" -r '.status.installation.workspaceId // .status.installation.scopeId // empty')"

if [[ -z "$ACCOUNT_ID" || -z "$WORKSPACE_ID" ]]; then
  error "Executor did not report a local account/workspace"
  exit 1
fi

connect_payload="$("$JQ_BIN" -cn \
  --arg name "$EXECUTOR_ATLASSIAN_SOURCE_NAME" \
  --arg namespace "$EXECUTOR_ATLASSIAN_NAMESPACE" \
  --arg endpoint "$EXECUTOR_ATLASSIAN_ENDPOINT" \
  --arg transport "$EXECUTOR_ATLASSIAN_TRANSPORT" '
    {
      name: $name,
      namespace: $namespace,
      kind: "mcp",
      endpoint: $endpoint,
      transport: $transport
    }
  '
)"

result="$("$CURL_BIN" -fsS \
  -H "x-executor-account-id: $ACCOUNT_ID" \
  -H "content-type: application/json" \
  -X POST \
  "$BASE_URL/v1/workspaces/$WORKSPACE_ID/sources/connect" \
  -d "$connect_payload"
)"

kind="$(printf '%s' "$result" | "$JQ_BIN" -r '.kind // empty')"

case "$kind" in
  connected)
    info "Atlassian is already connected in Executor"
    exit 0
    ;;
  oauth_required)
    auth_url="$(printf '%s' "$result" | "$JQ_BIN" -r '.authorizationUrl // empty')"
    if [[ -z "$auth_url" ]]; then
      error "Atlassian OAuth was requested but no authorization URL was returned"
      exit 1
    fi

    info "Opening Atlassian OAuth in your browser"
    if [[ -n "$OPEN_BIN" ]]; then
      "$OPEN_BIN" "$auth_url" >/dev/null 2>&1 || warn "Failed to open browser automatically"
    fi
    printf '%s\n' "$auth_url"
    info "Finish the browser flow, then run $EXECUTOR_SYNC_SCRIPT"
    exit 0
    ;;
  credential_required)
    error "Atlassian requested non-OAuth credentials; this repo expects OAuth-backed setup"
    printf '%s\n' "$result" >&2
    exit 1
    ;;
  *)
    error "Unexpected Atlassian connect result"
    printf '%s\n' "$result" >&2
    exit 1
    ;;
esac
