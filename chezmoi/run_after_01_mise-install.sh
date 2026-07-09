#!/bin/bash
# Run mise install after chezmoi apply to ensure all tools are installed
# This script runs automatically after chezmoi apply

if [[ "${MISE_BOOTSTRAP_ACTIVE:-0}" == "1" ]]; then
  echo "Mise bootstrap already installed configured tools; skipping nested install"
elif command -v mise &> /dev/null; then
  echo "Running mise install..."
  mise install --yes -C "$HOME"

  echo "Pruning unused tool versions..."
  mise prune --yes
else
  echo "Warning: mise not found, skipping mise install"
fi
