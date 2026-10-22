#!/usr/bin/env bash
# Synchronize the shared workstation configuration; upgrades are explicit.

set -euo pipefail

UPGRADE=false
case "${1:-}" in
  "") ;;
  --upgrade) UPGRADE=true; shift ;;
  --help|-h) echo "Usage: dot-update [--upgrade]"; exit 0 ;;
  *) echo "Usage: dot-update [--upgrade]" >&2; exit 2 ;;
esac
if [[ $# -ne 0 ]]; then
  echo "Usage: dot-update [--upgrade]" >&2
  exit 2
fi

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

export MISE_GLOBAL_CONFIG_FILE="$REPO_DIR/mise/config.toml"

echo "Updating dotfiles repository..."
if [[ -n "$(git -C "$REPO_DIR" status --porcelain)" ]]; then
  echo "Dotfiles has local changes. Review and commit or stash them before updating." >&2
  exit 1
fi
git -C "$REPO_DIR" pull --ff-only

echo "Applying workstation configuration..."
"$MISE_BIN" bootstrap --yes --update

if [[ "$UPGRADE" == true ]]; then
  echo "Upgrading machine-global packages..."
  "$MISE_BIN" bootstrap packages upgrade --yes
  echo "Updating versioned developer tools..."
  "$SCRIPT_DIR/update-tools.sh"
fi

echo "Update complete!"
