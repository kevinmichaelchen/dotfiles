#!/usr/bin/env bash
# Stop the Executor runtime and re-run sync. Source state lives in SQLite, so
# this is only needed when the runtime process itself is wedged.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

EXECUTOR_BIN="$(prefer_fallback_bin executor "$EXECUTOR_MISE_SHIM")"
TMUX_BIN="$(resolve_bin tmux || true)"

if "$EXECUTOR_BIN" daemon stop --base-url "$EXECUTOR_BASE_URL" >/dev/null 2>&1; then
  info "Stopped Executor daemon via CLI"
fi

if [[ -n "$TMUX_BIN" ]]; then
  # Clean up legacy stdio-bridge sessions (pre-rewrite).
  while IFS= read -r session; do
    [[ -z "$session" ]] && continue
    info "Killing legacy bridge session $session"
    "$TMUX_BIN" kill-session -t "$session" >/dev/null 2>&1 || true
  done < <("$TMUX_BIN" list-sessions -F '#{session_name}' 2>/dev/null | grep '^executor-mcp-' || true)
fi

pids="$(lsof -ti ":$EXECUTOR_WEB_PORT" 2>/dev/null || true)"
for pid in $pids; do
  [[ -z "$pid" ]] && continue
  info "Killing pid $pid on :$EXECUTOR_WEB_PORT"
  kill "$pid" 2>/dev/null || true
done

exec "$EXECUTOR_SYNC_SCRIPT"
