#!/usr/bin/env bash
# Ensure machine-wide approvals for read-only search tools that otherwise prompt.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

BASE_URL="$EXECUTOR_BASE_URL"
CURL_BIN="$(require_bin curl)"
JQ_BIN="$(require_bin jq)"

readonly_policies=(
  "perplexity_search.search.searchSearchPost"
  "parallel_search.search.webSearchV1betaSearchPost"
)

if ! scope_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scope" 2>/dev/null)"; then
  error "Executor runtime is not reachable at ${BASE_URL%/}"
  exit 1
fi

scope_id="$(printf '%s' "$scope_json" | "$JQ_BIN" -r '.id // empty')"
if [[ -z "$scope_id" ]]; then
  error "Executor runtime did not return a scope id"
  exit 1
fi

policies_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scopes/$scope_id/policies")"

for pattern in "${readonly_policies[@]}"; do
  existing_action="$(
    printf '%s' "$policies_json" \
      | "$JQ_BIN" -r --arg pattern "$pattern" '.[] | select(.pattern == $pattern) | .action' \
      | head -n 1
  )"

  case "$existing_action" in
    approve)
      info "Policy already approves $pattern"
      continue
      ;;
    require_approval|block)
      error "Policy for $pattern is $existing_action; refusing to override it automatically"
      exit 1
      ;;
  esac

  payload="$("$JQ_BIN" -nc --arg pattern "$pattern" '{pattern: $pattern, action: "approve"}')"
  "$CURL_BIN" -fsS \
    -X POST "${BASE_URL%/}/api/scopes/$scope_id/policies" \
    -H 'content-type: application/json' \
    --data "$payload" >/dev/null
  info "Approved read-only search tool $pattern"

  policies_json="$("$CURL_BIN" -fsS "${BASE_URL%/}/api/scopes/$scope_id/policies")"
done
