#!/usr/bin/env bash
# Load the shell env launchd is missing, then reconcile executor sources.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:/opt/homebrew/bin:/etc/profiles/per-user/$USER/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash --shims)"
fi

for env_file in "${EXECUTOR_LAUNCHD_ENV_FILES[@]}"
do
  if [[ -f "$env_file" ]]; then
    # These files only export environment variables needed by executor sources.
    source "$env_file"
  fi
done

exec "$EXECUTOR_SYNC_SCRIPT"
