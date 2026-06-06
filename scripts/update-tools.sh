#!/usr/bin/env bash
# Update developer CLI tools managed by Mise.

set -euo pipefail

echo "Updating developer tools (Mise)..."

if command -v mise >/dev/null 2>&1; then
  echo "Checking for outdated Mise tools..."
  mise outdated || true

  echo "Upgrading Mise tools..."
  if ! mise upgrade; then
    cat >&2 <<'EOF'
Mise upgrade failed.

GitHub attestations stay enabled during automatic updates. If the failure is a
known temporary attestation outage for gh, recover manually after reviewing it:

  MISE_GITHUB_ATTESTATIONS=false mise install github:cli/cli@latest
  mise upgrade
EOF
    exit 1
  fi

  echo "Refreshing Mise lockfile metadata..."
  mise lock --global --platform macos-arm64

  echo "Pruning unused Mise versions..."
  mise prune --yes

  echo "Verifying Mise tool state..."
  mise outdated
else
  echo "Warning: mise not found, skipping Mise upgrade/prune"
fi

echo "Developer tool update complete."
