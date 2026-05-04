#!/usr/bin/env bash
# Load the Executor daemon LaunchAgent after chezmoi applies its plist.

set -euo pipefail

if [[ "${OSTYPE:-}" != darwin* ]]; then
  exit 0
fi

if ! command -v launchctl >/dev/null 2>&1; then
  echo "Warning: launchctl not found, skipping Executor LaunchAgent load"
  exit 0
fi

OLD_LABEL="com.kchen.executor-sync"
LABEL="com.kchen.executor-daemon"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"
ENTRYPOINT="$HOME/dotfiles/scripts/executor/launchd-daemon.sh"
DOMAIN="gui/$(id -u)"

if [[ ! -f "$PLIST_PATH" ]]; then
  echo "Warning: ${PLIST_PATH} not found, skipping executor LaunchAgent load"
  exit 0
fi

mkdir -p "$HOME/Library/Logs"

if launchctl print "${DOMAIN}/${OLD_LABEL}" >/dev/null 2>&1; then
  launchctl bootout "${DOMAIN}/${OLD_LABEL}" >/dev/null 2>&1 || true
fi

if [[ ! -x "$ENTRYPOINT" ]]; then
  echo "Warning: ${ENTRYPOINT} not found or not executable, skipping Executor LaunchAgent load"
  if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
    launchctl bootout "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true
  fi
  exit 0
fi

if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
  launchctl bootout "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true
fi

launchctl bootstrap "$DOMAIN" "$PLIST_PATH"
launchctl kickstart -k "${DOMAIN}/${LABEL}" >/dev/null 2>&1 || true
echo "Loaded LaunchAgent ${LABEL}"
