#!/usr/bin/env bash
# Update developer tools; deletion is a manual operator action.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export MISE_GLOBAL_CONFIG_FILE="$REPO_DIR/mise/config.toml"
# This explicit maintenance command may refresh the shared config and lockfile.
export MISE_LOCKED=false
cd "$REPO_DIR"

if command -v mise >/dev/null 2>&1; then
  echo "Updating runtimes before dependent tools..."
  mise upgrade --bump --no-prune node go rust
  # Parallel CLI's locked PyYAML dependency has no Python 3.15 wheel yet.
  mise upgrade --bump --no-prune python@3.14
  echo "Updating remaining Mise tools..."
  mise upgrade --bump --no-prune --exclude python
  echo "Refreshing lockfile metadata..."
  mise lock --global --platform macos-arm64
  echo "Verifying available updates..."
  mise outdated --bump
  echo "Previewing unused installations (nothing is removed)..."
  mise prune --dry-run
  echo "To delete unused versions yourself: mise prune --yes"
else
  echo "Warning: mise not found; skipping Mise updates" >&2
fi

if command -v claude >/dev/null 2>&1; then
  claude update
  claude --version
else
  echo "Warning: claude not found; skipping Claude Code update" >&2
fi

echo "Developer tool update complete."
