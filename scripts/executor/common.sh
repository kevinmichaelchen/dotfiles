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

EXECUTOR_SYNC_SCRIPT="$EXECUTOR_SCRIPT_DIR/sync.sh"
EXECUTOR_RESTART_SCRIPT="$EXECUTOR_SCRIPT_DIR/restart.sh"
EXECUTOR_LAUNCHD_SYNC_SCRIPT="$EXECUTOR_SCRIPT_DIR/launchd-sync.sh"
EXECUTOR_STATUS_SCRIPT="$EXECUTOR_SCRIPT_DIR/status.sh"
EXECUTOR_MISE_SHIM="$HOME/.local/share/mise/shims/executor"

EXECUTOR_HOSTNAME="${EXECUTOR_HOSTNAME:-127.0.0.1}"
EXECUTOR_WEB_PORT="${EXECUTOR_WEB_PORT:-8788}"
EXECUTOR_BASE_URL="${EXECUTOR_BASE_URL:-http://${EXECUTOR_HOSTNAME}:${EXECUTOR_WEB_PORT}}"
EXECUTOR_SCOPE_DIR="${EXECUTOR_SCOPE_DIR:-$HOME/.executor}"
EXECUTOR_RUNTIME_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/executor-mcp-bridges/logs"
EXECUTOR_RUNTIME_SESSION_NAME="${EXECUTOR_RUNTIME_SESSION_NAME:-executor-runtime}"

EXECUTOR_LAUNCHD_ENV_FILES=(
  "$HOME/.config/shell/perplexity.sh"
  "$HOME/.config/shell/parallel.sh"
  "$HOME/.config/shell/firecrawl.sh"
  "$HOME/.config/shell/exa.sh"
  "$HOME/.config/shell/github.sh"
  "$HOME/.config/shell/jira.sh"
  "$HOME/.config/shell/atlassian.sh"
)

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

have_env() {
  local key
  for key in "$@"; do
    if [[ -z "${!key:-}" ]]; then
      return 1
    fi
  done
  return 0
}

source_executor_env_files() {
  local file
  for file in "${EXECUTOR_LAUNCHD_ENV_FILES[@]}"; do
    [[ -f "$file" ]] || continue
    # shellcheck disable=SC1090
    source "$file"
  done
}
