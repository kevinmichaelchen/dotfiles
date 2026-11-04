#!/usr/bin/env bash
# Preview or apply Ubuntu packages, developer tools, and Bash configuration.
set -euo pipefail

case "${1:---dry-run}" in
  --dry-run) APPLY=false ;;
  --apply) APPLY=true ;;
  *) echo "Usage: bootstrap-ubuntu.sh [--dry-run|--apply]" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { echo "Unexpected arguments" >&2; exit 2; }
[[ "$(uname -s)" == Linux ]] || { echo "Ubuntu setup requires Linux" >&2; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Sources intentionally use ~/dotfiles, matching the Mac setup's convention.
[[ "$REPO_DIR" -ef "$HOME/dotfiles" ]] || {
  echo "Check out this repository at ~/dotfiles before applying it." >&2; exit 1;
}
MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}"
[[ -x "$MISE_BIN" ]] || { echo "Install Mise first: https://mise.jdx.dev/installing-mise.html" >&2; exit 1; }
export MISE_GLOBAL_CONFIG_FILE="$REPO_DIR/platforms/ubuntu/config.toml"
export MISE_IGNORED_CONFIG_PATHS="$REPO_DIR/mise/config.toml${MISE_IGNORED_CONFIG_PATHS:+:$MISE_IGNORED_CONFIG_PATHS}"

if [[ "$APPLY" == true ]]; then
  "$MISE_BIN" bootstrap packages apply --yes
  "$MISE_BIN" install
  # Conflicting real files require explicit operator review/replacement.
  "$MISE_BIN" dotfiles apply --yes
else
  "$MISE_BIN" bootstrap packages apply --dry-run
  "$MISE_BIN" install --dry-run
  "$MISE_BIN" dotfiles apply --dry-run
fi
