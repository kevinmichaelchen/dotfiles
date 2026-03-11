#!/usr/bin/env bash
# Load the shell env launchd is missing, then reconcile executor sources.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:/opt/homebrew/bin:/etc/profiles/per-user/$USER/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash --shims)"
fi

for env_file in \
  "$HOME/.config/shell/perplexity.sh" \
  "$HOME/.config/shell/parallel.sh" \
  "$HOME/.config/shell/exa.sh" \
  "$HOME/.config/shell/firecrawl.sh" \
  "$HOME/.config/shell/jira.sh" \
  "$HOME/.config/shell/huggingface.sh" \
  "$HOME/.config/shell/nia.sh"
do
  if [[ -f "$env_file" ]]; then
    # These files only export environment variables needed by executor sources.
    source "$env_file"
  fi
done

exec "$SCRIPT_DIR/executor-sync-mcp.sh"
