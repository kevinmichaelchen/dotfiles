#!/bin/bash
# Install Claude Code CLI via official install script
# This runs once on initial setup. Updates handled by: claude update

if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "Claude Code already installed: $(claude --version 2>/dev/null | head -1)"
fi
