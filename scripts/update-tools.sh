#!/usr/bin/env bash
# Update developer CLI tools managed by Mise and Claude Code.

set -euo pipefail

echo "Updating developer tools (Mise + Claude Code)..."

if command -v mise >/dev/null 2>&1; then
  echo "Checking for outdated Mise tools..."
  mise outdated || true

  echo "Upgrading Mise tools..."
  if ! mise upgrade; then
    echo "Mise upgrade failed; retrying github:cli/cli without GitHub attestations."
    MISE_GITHUB_ATTESTATIONS=false mise install github:cli/cli@latest
    mise upgrade
  fi

  echo "Pruning unused Mise versions..."
  mise prune --yes

  echo "Verifying Mise tool state..."
  mise outdated
else
  echo "Warning: mise not found, skipping Mise upgrade/prune"
fi

if command -v claude >/dev/null 2>&1; then
  echo "Updating Claude Code..."
  claude update
  echo "Claude version: $(claude --version 2>/dev/null | head -1)"
else
  echo "Warning: claude not found, skipping Claude update"
fi

echo "Developer tool update complete."
