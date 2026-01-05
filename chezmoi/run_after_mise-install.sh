#!/bin/bash
# Run mise install after chezmoi apply to ensure all tools are installed
# This script runs automatically after chezmoi apply

if command -v mise &> /dev/null; then
  echo "Running mise install..."
  mise install --yes
else
  echo "Warning: mise not found, skipping mise install"
fi
