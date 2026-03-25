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
EXECUTOR_AUTH_ATLASSIAN_SCRIPT="$EXECUTOR_SCRIPT_DIR/auth-atlassian.sh"

EXECUTOR_BASE_URL="${EXECUTOR_BASE_URL:-http://127.0.0.1:8788}"
EXECUTOR_WORKSPACE_ROOT="${EXECUTOR_WORKSPACE_ROOT:-$HOME}"
EXECUTOR_STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/executor-mcp-bridges"
EXECUTOR_OPENAPI_SPEC_PORT="${EXECUTOR_OPENAPI_SPEC_PORT:-8821}"
EXECUTOR_OPENAPI_SPEC_DIR="$EXECUTOR_SCRIPT_DIR/openapi"

EXECUTOR_ATLASSIAN_SOURCE_NAME="atlassian"
EXECUTOR_ATLASSIAN_NAMESPACE="atlassian"
EXECUTOR_ATLASSIAN_ENDPOINT="https://mcp.atlassian.com/v1/mcp"
EXECUTOR_ATLASSIAN_TRANSPORT="streamable-http"

EXECUTOR_BRIDGE_PORTS=(8814 8817 8820 8821 8822)
EXECUTOR_TMUX_ENV_KEYS=(
  GITHUB_PERSONAL_ACCESS_TOKEN
  EXA_API_KEY
  JIRA_URL
  JIRA_USERNAME
  JIRA_API_TOKEN
  CONFLUENCE_URL
  CONFLUENCE_USERNAME
  CONFLUENCE_API_TOKEN
  HF_TOKEN
  NIA_API_KEY
  FIRECRAWL_API_KEY
)
EXECUTOR_LAUNCHD_ENV_FILES=(
  "$HOME/.config/shell/perplexity.sh"
  "$HOME/.config/shell/parallel.sh"
  "$HOME/.config/shell/exa.sh"
  "$HOME/.config/shell/firecrawl.sh"
  "$HOME/.config/shell/github.sh"
  "$HOME/.config/shell/jira.sh"
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

ensure_executor_workspace_root() {
  if [[ ! -d "$EXECUTOR_WORKSPACE_ROOT" ]]; then
    error "Executor workspace root does not exist: $EXECUTOR_WORKSPACE_ROOT"
    exit 1
  fi

  # Executor v1.2.x derives its local workspace config from process cwd.
  cd "$EXECUTOR_WORKSPACE_ROOT"
}
