#!/usr/bin/env bash
# Print safe Executor diagnostics without reading secret values.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

EXECUTOR_BIN="$(prefer_fallback_bin executor "$EXECUTOR_MISE_SHIM")"
CURL_BIN="$(require_bin curl)"
JQ_BIN="$(require_bin jq)"

printf 'Executor CLI: %s\n' "$(executor_version "$EXECUTOR_BIN")"
printf 'Expected scope: %s\n' "$EXECUTOR_SCOPE_DIR"
printf 'Daemon URL: %s\n' "${EXECUTOR_BASE_URL%/}"

if scope_json="$("$CURL_BIN" -fsS "${EXECUTOR_BASE_URL%/}/api/scope" 2>/dev/null)"; then
  printf 'Daemon: reachable\n'
  printf 'Active scope: %s\n' "$(printf '%s' "$scope_json" | "$JQ_BIN" -r '.dir // .id // empty')"
else
  printf 'Daemon: not reachable\n'
fi

if [[ "${OSTYPE:-}" == darwin* ]] && command -v launchctl >/dev/null 2>&1; then
  label="com.kchen.executor-daemon"
  domain="gui/$(id -u)"
  if launchctl print "${domain}/${label}" >/dev/null 2>&1; then
    printf 'LaunchAgent: loaded (%s/%s)\n' "$domain" "$label"
  else
    printf 'LaunchAgent: not loaded (%s/%s)\n' "$domain" "$label"
  fi
fi

if command -v pgrep >/dev/null 2>&1; then
  printf '\nExecutor processes:\n'
  process_list="$(pgrep -fl 'executor( |$|-)' || true)"
  if [[ -z "$process_list" ]]; then
    printf '  none found\n'
  else
    printf '%s\n' "$process_list"
    process_count="$(printf '%s\n' "$process_list" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
    if [[ "$process_count" -gt 2 ]]; then
      printf '  warning: multiple Executor processes can repeat startup probes; prefer the shared HTTP daemon\n'
    fi
  fi
fi

config_file="${EXECUTOR_SCOPE_DIR%/}/executor.jsonc"
if [[ -f "$config_file" ]]; then
  printf '\nConfig file: %s\n' "$config_file"
  if grep -Eq '"sources"[[:space:]]*:' "$config_file"; then
    printf '  contains a sources key; Executor 1.4.28+ keeps live sources in SQLite, not this file\n'
  fi
  if grep -Eq '"plugins"[[:space:]]*:' "$config_file"; then
    printf '  contains plugin entries\n'
  fi
fi

cat <<'EOF'

Keychain prompt notes:
  macOS prompts can happen when Executor's built-in keychain provider probes or
  reads OS Keychain entries. Repeated Executor process restarts can repeat that
  probe. This dotfiles repo keeps launchd idempotent by default; use
  scripts/executor/restart.sh only when you intentionally want a restart.

  Codex, Claude, OpenCode, and Crush should point at the shared HTTP MCP daemon
  instead of spawning command-backed `executor mcp` processes.

  Prefer Executor's 1Password provider for API tokens you already keep in
  1Password. Avoid storing new Executor source credentials in the macOS
  Keychain unless you specifically want that backend.
EOF
