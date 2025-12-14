# AGENTS.md

A unified approach to managing system configuration using Nix/Home-Manager for reproducible package management and Chezmoi for personal dotfile synchronization.

## 📋 Overview

This repository combines the best of both worlds:
- **Nix/Home-Manager**: Declarative, reproducible system package management
- **Chezmoi**: Flexible, templated personal configuration management

## 🗂️ Directory Structure

```
~/dotfiles/
├── nix-darwin/            # macOS system configuration (includes Home-Manager)
│   ├── flake.nix          # Flake with nix-darwin, Home-Manager, and nix-homebrew
│   └── configuration.nix  # System-level macOS configuration
│
├── home-manager/          # Standalone Home-Manager (for non-macOS systems)
│   ├── flake.nix          # Flake definition for reproducible builds
│   ├── flake.lock         # Locked dependencies
│   └── home.nix           # User packages and configuration
│
├── chezmoi/               # Chezmoi-managed personal configs
│   ├── .chezmoiignore     # Files for Chezmoi to ignore
│   ├── dot_gitconfig      # Git configuration
│   ├── dot_vimrc          # Vim configuration
│   └── dot_config/        # .config directory files
│       ├── git/
│       │   └── kevinmichaelchen  # Personal git config for GitHub repos
│       ├── shell/
│       │   ├── bat.sh     # bat aliases and functions (cat, batdiff, help)
│       │   ├── git.sh     # Shell-agnostic git aliases
│       │   ├── pnpm.sh    # PNPM configuration
│       │   ├── python.sh  # Python/UV configuration
│       │   └── zed.sh     # Zed editor configuration
│       ├── mise/
│       │   └── config.toml   # Mise version manager config (node, npm packages)
│       ├── starship.toml  # Starship prompt configuration
│       └── zsh/
│           └── custom.zsh # Zsh configuration
│
└── scripts/               # Helper automation scripts
    ├── bootstrap.sh       # Initial machine setup
    └── update.sh          # Update both systems
```