#!/usr/bin/env bash
# Detach only the former repo-owned Git symlink; preserve every local setting.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$HOME/.gitconfig"
SOURCE="$REPO_DIR/dotfiles/.gitconfig"

if [[ -L "$TARGET" ]]; then
  if [[ ! "$TARGET" -ef "$SOURCE" ]]; then
    echo "Refusing to migrate unrelated Git config symlink: $TARGET" >&2
    exit 1
  fi
  TEMP_CONFIG="$(mktemp "$HOME/.gitconfig.migration.XXXXXX")"
  cp -p "$TARGET" "$TEMP_CONFIG"
  mv "$TEMP_CONFIG" "$TARGET"
  echo "Preserved Git settings in a regular $TARGET"
fi
