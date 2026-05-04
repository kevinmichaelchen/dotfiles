#!/usr/bin/env bash
# Shared constants and helpers for Executor automation.

if [[ -n "${EXECUTOR_COMMON_SH_LOADED:-}" ]]; then
  return 0
fi
EXECUTOR_COMMON_SH_LOADED=1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

EXECUTOR_SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXECUTOR_REPO_ROOT="$(CDPATH= cd -- "$EXECUTOR_SCRIPT_DIR/../.." && pwd)"

EXECUTOR_RESTART_SCRIPT="$EXECUTOR_SCRIPT_DIR/restart.sh"
EXECUTOR_LAUNCHD_DAEMON_SCRIPT="$EXECUTOR_SCRIPT_DIR/launchd-daemon.sh"
EXECUTOR_STATUS_SCRIPT="$EXECUTOR_SCRIPT_DIR/status.sh"
EXECUTOR_MISE_SHIM="$HOME/.local/share/mise/shims/executor"

EXECUTOR_HOSTNAME="${EXECUTOR_HOSTNAME:-127.0.0.1}"
EXECUTOR_WEB_PORT="${EXECUTOR_WEB_PORT:-8788}"
EXECUTOR_BASE_URL="${EXECUTOR_BASE_URL:-http://${EXECUTOR_HOSTNAME}:${EXECUTOR_WEB_PORT}}"
EXECUTOR_SCOPE_DIR="${EXECUTOR_SCOPE_DIR:-$HOME/.executor}"
EXECUTOR_RUNTIME_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/executor/logs"

info() {
  echo -e "${GREEN}==>${NC} $*"
}

warn() {
  echo -e "${YELLOW}warn${NC} $*" >&2
}

error() {
  echo -e "${RED}err${NC} $*" >&2
}

resolve_bin() {
  local name="$1"
  local fallback="${2:-}"

  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi

  if [[ -n "$fallback" && -x "$fallback" ]]; then
    printf '%s\n' "$fallback"
    return 0
  fi

  return 1
}

require_bin() {
  local name="$1"
  local fallback="${2:-}"
  local resolved

  if ! resolved="$(resolve_bin "$name" "$fallback")"; then
    error "Required command not found: $name"
    exit 1
  fi

  printf '%s\n' "$resolved"
}

prefer_fallback_bin() {
  local name="$1"
  local fallback="${2:-}"

  if [[ -n "$fallback" && -x "$fallback" ]]; then
    printf '%s\n' "$fallback"
    return 0
  fi

  require_bin "$name"
}

executor_version() {
  local bin="$1"
  "$bin" --version 2>/dev/null | awk 'NF { value=$NF } END { sub(/^v/, "", value); print value }'
}
