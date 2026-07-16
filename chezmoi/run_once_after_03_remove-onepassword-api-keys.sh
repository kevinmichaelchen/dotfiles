#!/usr/bin/env bash
# Remove API-key material previously rendered from 1Password.

set -euo pipefail

rm -f \
  "$HOME/.config/shell/cerebras.sh" \
  "$HOME/.config/shell/exa.sh" \
  "$HOME/.config/shell/firecrawl.sh" \
  "$HOME/.config/shell/fireworks.sh" \
  "$HOME/.config/shell/huggingface.sh" \
  "$HOME/.config/shell/hygraph.sh" \
  "$HOME/.config/shell/jira.sh" \
  "$HOME/.config/shell/nia.sh" \
  "$HOME/.config/shell/openrouter.sh" \
  "$HOME/.config/shell/parallel.sh" \
  "$HOME/.config/shell/perplexity.sh" \
  "$HOME/.config/shell/railway.sh" \
  "$HOME/.config/shell/replicate.sh"
