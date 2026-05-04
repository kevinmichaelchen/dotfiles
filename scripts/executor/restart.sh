#!/usr/bin/env bash
# Stop the Executor runtime and re-run sync. Source state lives in SQLite, so
# this is only needed when the runtime process itself is wedged.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

EXECUTOR_BIN="$(prefer_fallback_bin executor "$EXECUTOR_MISE_SHIM")"
LABEL="com.kchen.executor-daemon"
DOMAIN="gui/$(id -u)"

if "$EXECUTOR_BIN" daemon stop --base-url "$EXECUTOR_BASE_URL" >/dev/null 2>&1; then
  info "Stopped Executor daemon via CLI"
fi

if [[ "${OSTYPE:-}" == darwin* ]] && command -v launchctl >/dev/null 2>&1 && \
  launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
  launchctl kickstart -k "${DOMAIN}/${LABEL}" >/dev/null
  info "Restarted Executor daemon via launchd"
  exit 0
fi

error "LaunchAgent $LABEL is not loaded; run chezmoi apply or start scripts/executor/launchd-daemon.sh under a supervisor"
exit 1
