#!/usr/bin/env bash
# Bootstrap script for new machines

echo "Setting up unified dotfiles..."

# Clone repository
git clone https://github.com/kevinmichaelchen/dotfiles.git ~/dotfiles

# Install Nix (if not present) using Determinate installer
if ! command -v nix &> /dev/null; then
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
fi

# Check if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS - using nix-darwin with integrated Home-Manager..."
    
    # Install nix-darwin (which includes Home-Manager as a module)
    nix run nix-darwin -- switch --flake ~/dotfiles/nix-darwin
    
    echo "nix-darwin installed. Use 'darwin-rebuild switch --flake ~/dotfiles/nix-darwin' for future updates."
else
    echo "Detected non-macOS - using standalone Home-Manager..."
    
    # Install Home-Manager standalone for non-macOS systems
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    
    # Apply Home-Manager configuration
    home-manager switch --flake ~/dotfiles/home-manager
    
    echo "Home-Manager installed. Use 'home-manager switch --flake ~/dotfiles/home-manager' for future updates."
fi

# Initialize Chezmoi
chezmoi init --source ~/dotfiles/chezmoi --apply

echo "Setup complete!"