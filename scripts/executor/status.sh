#!/usr/bin/env bash
# Print the current Executor runtime and source inventory state.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

BASE_URL="$EXECUTOR_BASE_URL"
EXECUTOR_BIN="$(prefer_fallback_bin executor "$EXECUTOR_MISE_SHIM")"
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
printf 'Executor CLI: %s\n' "$(executor_version "$EXECUTOR_BIN")"
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

sources_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scopes/$SCOPE_ID/sources" 2>/dev/null || true)"
if [[ -n "$sources_json" && "$sources_json" != "null" ]]; then
  printf '%s' "$sources_json" \
    | "$JQ_BIN" -r '.[] | [.id, .kind, (.name // .id)] | @tsv' \
    | while IFS=$'\t' read -r source_id kind name; do
      tool_count="$(tool_count_for_source "$source_id" 2>/dev/null || printf '?')"
      print_row "$source_id" "$kind" "$name" "$tool_count"
    done
fi

policies_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scopes/$SCOPE_ID/policies" 2>/dev/null || true)"
if [[ -n "$policies_json" && "$policies_json" != "null" ]]; then
  printf '\nPolicy rules: %s\n' "$(printf '%s' "$policies_json" | "$JQ_BIN" 'length')"
  printf '%s' "$policies_json" \
    | "$JQ_BIN" -r '.[] | "  \(.action)\t\(.pattern)"'
fi
