#!/usr/bin/env bash
# Run the shared Executor daemon under launchd.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/executor/common.sh
source "$SCRIPT_DIR/common.sh"

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:/opt/homebrew/bin:/etc/profiles/per-user/$USER/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash --shims)"
fi

EXECUTOR_BIN="$(prefer_fallback_bin executor "$EXECUTOR_MISE_SHIM")"

exec "$EXECUTOR_BIN" daemon run \
  --foreground \
  --port "$EXECUTOR_WEB_PORT" \
  --hostname "$EXECUTOR_HOSTNAME" \
  --scope "$EXECUTOR_SCOPE_DIR"
