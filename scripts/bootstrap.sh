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

export MISE_GLOBAL_CONFIG_FILE="$DOTFILES_DIR/chezmoi/dot_config/mise/config.toml"

echo
echo "Previewing workstation changes..."
"$MISE_BIN" bootstrap --dry-run

echo
echo "Bootstrap preparation complete. Review the preview, then run:"
echo "  Supply the repository age identity from removable media or another trusted path:"
echo "  CHEZMOI_AGE_IDENTITY_FILE=/path/to/key.txt MISE_GLOBAL_CONFIG_FILE=$MISE_GLOBAL_CONFIG_FILE $MISE_BIN bootstrap --yes --update"
echo "  MISE_GLOBAL_CONFIG_FILE=$MISE_GLOBAL_CONFIG_FILE $MISE_BIN bootstrap status --missing"
