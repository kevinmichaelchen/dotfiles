#!/usr/bin/env bash
# Update system configuration and Chezmoi

echo "Updating dotfiles..."

# Update git repository
git pull

# Check if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Updating nix-darwin..."
    nix flake update ~/dotfiles/nix-darwin
    darwin-rebuild switch --flake ~/dotfiles/nix-darwin
else
    echo "Updating Home-Manager..."
    nix flake update ~/dotfiles/home-manager
    home-manager switch --flake ~/dotfiles/home-manager
fi

# Update Chezmoi
echo "Updating Chezmoi configs..."
chezmoi apply

echo "Update complete!"