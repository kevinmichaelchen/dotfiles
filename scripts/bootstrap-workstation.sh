#!/usr/bin/env bash
# Maintain app settings and pinned skills after Mise has installed the tools.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/app-config/apply.py"
"$SCRIPT_DIR/agent-skills/install-security-tools.sh"
"$SCRIPT_DIR/agent-skills/sync.sh" --prune
