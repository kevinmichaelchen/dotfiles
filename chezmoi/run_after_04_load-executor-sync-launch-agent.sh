#!/usr/bin/env bash
# Load the executor sync LaunchAgent after chezmoi applies its plist.

set -euo pipefail

if [[ "${OSTYPE:-}" != darwin* ]]; then
  exit 0
fi

if ! command -v launchctl >/dev/null 2>&1; then
  echo "Warning: launchctl not found, skipping executor LaunchAgent load"
  exit 0
fi

LABEL="com.kchen.executor-sync"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"
DOMAIN="gui/$(id -u)"

if [[ ! -f "$PLIST_PATH" ]]; then
  echo "Warning: ${PLIST_PATH} not found, skipping executor LaunchAgent load"
  exit 0
fi

mkdir -p "$HOME/Library/Logs"

if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
  launchctl bootout "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true
fi

launchctl bootstrap "$DOMAIN" "$PLIST_PATH"
launchctl kickstart -k "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true
echo "Loaded LaunchAgent ${LABEL}"
