#!/usr/bin/env bash
# Tear down all executor MCP bridges and re-sync from scratch.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

SYNC_SCRIPT="$EXECUTOR_SYNC_SCRIPT"
STATE_ROOT="$EXECUTOR_STATE_ROOT"

TMUX_BIN="$(require_bin tmux)"
EXECUTOR_BIN="$(resolve_bin executor "$HOME/.local/share/mise/shims/executor" || true)"

if [[ -n "$EXECUTOR_BIN" ]]; then
  info "Stopping executor daemon"
  "$EXECUTOR_BIN" down >/dev/null 2>&1 || true
else
  warn "executor not found; skipping daemon shutdown"
fi

info "Stopping executor MCP tmux sessions"
while IFS= read -r session; do
  [[ -z "$session" ]] && continue
  "$TMUX_BIN" kill-session -t "$session" 2>/dev/null || true
  info "  Killed $session"
done < <("$TMUX_BIN" list-sessions -F '#{session_name}' 2>/dev/null | grep '^executor-mcp-')

info "Killing orphaned bridge processes on known ports"
for port in "${EXECUTOR_BRIDGE_PORTS[@]}"; do
  pids="$(lsof -ti ":$port" 2>/dev/null || true)"
  for pid in $pids; do
    [[ -z "$pid" ]] && continue
    kill "$pid" 2>/dev/null || true
    info "  Killed pid $pid on :$port"
  done
done

info "Cleaning up state directory"
rm -f "$STATE_ROOT"/pids/*.pid
rm -f "$STATE_ROOT"/commands/*.sh
rm -f "$STATE_ROOT"/logs/*.log
info "  Removed stale pids, commands, logs"

info "Running executor sync"
exec "$SYNC_SCRIPT"
