#!/usr/bin/env bash
# Store Executor client credentials locally on this machine, outside Chezmoi.

set -euo pipefail

auth_file="${EXECUTOR_AUTH_FILE:-$HOME/.config/shell/executor-auth.sh}"
dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"

read -r -s -p "Executor Cloud API key: " cloud_key
printf '\n'
read -r -s -p "Executor Desktop MCP token: " desktop_token
printf '\n'

if [[ -z "$cloud_key" || -z "$desktop_token" ]]; then
  echo "Both Executor credentials are required" >&2
  exit 1
fi

mkdir -p \
  "$(dirname "$auth_file")" \
  "$HOME/.codex" \
  "$HOME/.config/opencode" \
  "$HOME/.config/crush"
tmp="$(mktemp "${TMPDIR:-/tmp}/executor-auth.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
umask 077
{
  printf '# Machine-local Executor credentials; intentionally not managed by Chezmoi.\n'
  printf 'export EXECUTOR_CLOUD_API_KEY=%q\n' "$cloud_key"
  printf 'export EXECUTOR_DESKTOP_MCP_TOKEN=%q\n' "$desktop_token"
} >"$tmp"
install -m 600 "$tmp" "$auth_file"

EXECUTOR_CLOUD_API_KEY="$cloud_key" \
EXECUTOR_DESKTOP_MCP_TOKEN="$desktop_token" \
  chezmoi apply --source="$dotfiles_dir/chezmoi" \
    "$HOME/.codex/config.toml" \
    "$HOME/.claude.json" \
    "$HOME/.config/opencode/opencode.json" \
    "$HOME/.config/crush/crush.json"

echo "Stored Executor credentials in $auth_file and updated client wiring"
