#!/usr/bin/env bash
# Bootstrap script for new machines

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}🚀 Setting up unified dotfiles...${NC}\n"

# Clone repository if not already present
if [ ! -d "$HOME/dotfiles" ]; then
    echo -e "${BLUE}📦 Cloning dotfiles repository...${NC}"
    git clone https://github.com/kevinmichaelchen/dotfiles.git ~/dotfiles
else
    echo -e "${GREEN}✓${NC} Dotfiles repository already exists at ~/dotfiles"
fi

# Install Nix (if not present) using Determinate installer
if ! command -v nix &> /dev/null; then
    echo -e "${BLUE}📦 Installing Nix package manager...${NC}"
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
else
    echo -e "${GREEN}✓${NC} Nix is already installed"
fi

# Check if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${MAGENTA}🍎 Detected macOS${NC}"
    NEXT_COMMAND="sudo nix run nix-darwin -- switch --flake ~/dotfiles/nix-darwin#default"
    UPDATE_COMMAND="darwin-rebuild switch --flake ~/dotfiles/nix-darwin#default"
else
    echo -e "${MAGENTA}🐧 Detected Linux/Unix${NC}"
    NEXT_COMMAND="nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager && nix-channel --update && home-manager switch --flake ~/dotfiles/home-manager"
    UPDATE_COMMAND="home-manager switch --flake ~/dotfiles/home-manager"
fi

echo -e "\n${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}✨ Bootstrap preparation complete!${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}${BOLD}📋 Next Steps:${NC}\n"

echo -e "${CYAN}1. Apply system configuration:${NC}"
echo -e "   ${BOLD}${NEXT_COMMAND}${NC}\n"

echo -e "${CYAN}2. After nix-darwin/home-manager installs packages, initialize Chezmoi:${NC}"
echo -e "   ${BOLD}chezmoi init --source ~/dotfiles/chezmoi --apply${NC}\n"

echo -e "${CYAN}3. For future updates, use:${NC}"
echo -e "   ${BOLD}${UPDATE_COMMAND}${NC}"
echo -e "   ${BOLD}chezmoi apply${NC}\n"

echo -e "${GREEN}${BOLD}Happy hacking! 🎉${NC}"