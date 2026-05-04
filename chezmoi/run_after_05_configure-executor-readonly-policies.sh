#!/usr/bin/env bash
# Seed exact machine-wide approvals for read-only Executor search tools.

set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
POLICY_SCRIPT="${DOTFILES_DIR}/scripts/executor/ensure-readonly-search-policies.sh"

if [[ ! -x "$POLICY_SCRIPT" ]]; then
  echo "Warning: $POLICY_SCRIPT not found or not executable, skipping Executor read-only policy setup" >&2
  exit 0
fi

if ! "$POLICY_SCRIPT"; then
  echo "Warning: Executor read-only policy setup failed; run $POLICY_SCRIPT after the daemon is reachable" >&2
  exit 0
fi
