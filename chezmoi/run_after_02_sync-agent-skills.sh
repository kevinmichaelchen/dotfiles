#!/usr/bin/env bash
# Install agent skills declared by ~/dotfiles/skills-lock.json.

set -euo pipefail

"${HOME}/dotfiles/scripts/agent-skills/install-security-tools.sh"
"${HOME}/dotfiles/scripts/agent-skills/sync.sh" --prune
