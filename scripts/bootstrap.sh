#!/usr/bin/env bash
# Prepare a new workstation for the mise bootstrap workflow.

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}"

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  git clone https://github.com/kevinmichaelchen/dotfiles.git "$DOTFILES_DIR"
fi

echo "Installing the current mise release to $MISE_BIN..."
curl --fail --location --show-error https://mise.run |
  MISE_INSTALL_PATH="$MISE_BIN" sh

export MISE_GLOBAL_CONFIG_FILE="$DOTFILES_DIR/mise/config.toml"

echo
"$MISE_BIN" trust "$MISE_GLOBAL_CONFIG_FILE"

echo "Previewing workstation changes (including dotfile replacements)..."
"$MISE_BIN" bootstrap --force-dotfiles --dry-run

echo
echo "Bootstrap preparation complete. Keep any local dotfile edits before replacing targets."
echo "After reviewing the preview, run:"
echo "  MISE_GLOBAL_CONFIG_FILE=$MISE_GLOBAL_CONFIG_FILE $MISE_BIN bootstrap --force-dotfiles --yes --update"
echo "  MISE_GLOBAL_CONFIG_FILE=$MISE_GLOBAL_CONFIG_FILE $MISE_BIN bootstrap status --missing"
