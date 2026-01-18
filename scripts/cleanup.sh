#!/usr/bin/env bash
# Nix store cleanup and maintenance
#
# Run periodically to free disk space by removing old generations
# and garbage collecting unreferenced store paths.

set -euo pipefail

echo "=== Nix Store Cleanup ==="
echo "Before:"
du -sh /nix/store

echo ""
echo "Deleting old generations..."

# Delete old darwin-system generations (keeps only current)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  - darwin-system generations"
    sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
fi

# Delete old home-manager generations
if [[ -d ~/.local/state/nix/profiles ]]; then
    echo "  - home-manager generations"
    nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager 2>/dev/null || true
fi

# Delete old user profile generations
echo "  - user profile generations"
nix-env --delete-generations old

echo ""
echo "Running garbage collection..."
nix-collect-garbage -d

echo ""
echo "=== Cleanup Complete ==="
echo "After:"
du -sh /nix/store
