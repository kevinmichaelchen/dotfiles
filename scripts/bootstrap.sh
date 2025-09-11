#!/usr/bin/env bash
# Bootstrap script for new machines

echo "Setting up unified dotfiles..."

# Clone repository
git clone https://github.com/kevinmichaelchen/dotfiles.git ~/dotfiles

# Install Nix (if not present) using Determinate installer
if ! command -v nix &> /dev/null; then
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
fi

# Install Home-Manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

# Apply Home-Manager configuration
home-manager switch --flake ~/dotfiles/home-manager

# Initialize Chezmoi
chezmoi init --source ~/dotfiles/chezmoi --apply

echo "Setup complete!"