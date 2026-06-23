#!/usr/bin/env bash
# Update system configuration and dotfiles.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Updating dotfiles..."

# Update git repository
git pull

# Check if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Updating nix-darwin..."
    nix flake update --flake "$HOME/dotfiles/nix-darwin"
    sudo darwin-rebuild switch --flake "$HOME/dotfiles/nix-darwin#$USER"
else
    echo "Updating Home-Manager..."
    nix flake update --flake "$HOME/dotfiles/home-manager"
    home-manager switch --flake "$HOME/dotfiles/home-manager#$USER"
fi

# Update Chezmoi from explicit source dir
echo "Updating Chezmoi configs..."
chezmoi apply --source="$HOME/dotfiles/chezmoi"

# Update developer tools
echo "Updating developer tools..."
"$SCRIPT_DIR/update-tools.sh"

echo "Update complete!"
