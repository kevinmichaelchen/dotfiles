#!/usr/bin/env bash
# Update repository, workstation state, and versioned developer tools.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MISE_BIN="${MISE_BIN:-}"

if [[ -z "$MISE_BIN" ]]; then
  MISE_BIN="$(command -v mise || true)"
fi
if [[ -z "$MISE_BIN" && -x "$HOME/.local/bin/mise" ]]; then
  MISE_BIN="$HOME/.local/bin/mise"
fi
if [[ -z "$MISE_BIN" ]]; then
  echo "mise is not installed; run ./scripts/bootstrap.sh first" >&2
  exit 1
fi

export MISE_GLOBAL_CONFIG_FILE="$REPO_DIR/chezmoi/dot_config/mise/config.toml"

echo "Updating dotfiles repository..."
git -C "$REPO_DIR" pull

echo "Applying workstation configuration..."
"$MISE_BIN" bootstrap --yes --update

echo "Upgrading machine-global packages..."
"$MISE_BIN" bootstrap packages upgrade --yes

echo "Updating versioned developer tools..."
"$SCRIPT_DIR/update-tools.sh"

echo "Update complete!"
