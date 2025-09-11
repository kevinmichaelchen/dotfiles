#!/usr/bin/env bash
# Update both Home-Manager and Chezmoi

echo "Updating dotfiles..."

# Update git repository
git pull

# Update and apply Home-Manager
echo "Updating Home-Manager..."
nix flake update ~/dotfiles/home-manager
home-manager switch --flake ~/dotfiles/home-manager

# Update Chezmoi
echo "Updating Chezmoi configs..."
chezmoi apply

echo "Update complete!"