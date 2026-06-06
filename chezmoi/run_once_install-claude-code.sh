#!/bin/bash
# Install Claude Code CLI through npm instead of executing a remote shell script.
# This runs once on initial setup. Updates handled by: claude update

if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code..."
  if ! command -v npm &> /dev/null; then
    if command -v mise &> /dev/null; then
      echo "npm not found; installing configured Node.js runtime with mise..."
      mise install node
    fi
  fi

  if ! command -v npm &> /dev/null; then
    echo "npm is required to install Claude Code. Install Node.js, then re-apply chezmoi." >&2
    exit 1
  fi

  CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-2.1.167}"
  npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"
else
  echo "Claude Code already installed: $(claude --version 2>/dev/null | head -1)"
fi
