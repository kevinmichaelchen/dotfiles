#!/bin/sh
# Nix and nix-darwin aliases
# Shell-agnostic - can be sourced by bash, zsh, etc.

# nix-darwin aliases
alias dr='cd ~/dotfiles/nix-darwin && sudo darwin-rebuild switch --flake ~/dotfiles/nix-darwin\#$USER'
alias dru='cd ~/dotfiles/nix-darwin && nix flake update --flake ~/dotfiles/nix-darwin && sudo darwin-rebuild switch --flake ~/dotfiles/nix-darwin\#$USER'
alias dre='cd ~/dotfiles/nix-darwin && $EDITOR configuration.nix'
alias hme='cd ~/dotfiles/home-manager && $EDITOR home.nix'
