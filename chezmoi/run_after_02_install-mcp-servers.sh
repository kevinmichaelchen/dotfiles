#!/bin/bash
# Install MCP servers from local forks (security: trust our forks over upstream)
# Runs after chezmoi apply to ensure repos are cloned first

set -euo pipefail

# Activate mise so tools installed in run_after_01 are on PATH
if command -v mise &> /dev/null; then
  eval "$(mise activate bash --shims)"
fi

MCP_REPOS=(
  "$HOME/dev/github.com/kevinmichaelchen/perplexity-mcp"
  "$HOME/dev/github.com/kevinmichaelchen/huggingface-mcp-server"
)

if ! command -v uv &> /dev/null; then
  echo "Warning: uv not found, skipping MCP server installation"
  exit 0
fi

for repo in "${MCP_REPOS[@]}"; do
  if [[ -d "$repo" ]]; then
    echo "Installing MCP server from $repo..."
    uv tool install --force "$repo"
  else
    echo "Warning: $repo not found, skipping"
  fi
done
