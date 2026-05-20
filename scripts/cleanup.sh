#!/usr/bin/env bash
# Nix store/cache cleanup and maintenance
#
# Run periodically to free disk space by removing old generations
# garbage collecting unreferenced store paths, and compacting Nix caches.

set -euo pipefail

echo "=== Nix Store Cleanup ==="
echo "Before:"
du -sh /nix/store
du -sh "$HOME/.cache/nix" 2>/dev/null || true

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
echo "Cleaning Nix tarball caches..."
tarball_cache="$HOME/.cache/nix/tarball-cache"
tarball_cache_v2="$HOME/.cache/nix/tarball-cache-v2"

if [[ -d "$tarball_cache" ]]; then
    echo "  - removing historical tarball-cache"
    rm -rf "$tarball_cache"
fi

if [[ -d "$tarball_cache_v2/objects" ]]; then
    if command -v git >/dev/null 2>&1; then
        echo "  - compacting tarball-cache-v2"
        git -C "$tarball_cache_v2" multi-pack-index write
        git -C "$tarball_cache_v2" multi-pack-index repack
        git -C "$tarball_cache_v2" multi-pack-index expire
    else
        echo "  - git not found; skipping tarball-cache-v2 compaction"
    fi
fi

echo ""
echo "=== Cleanup Complete ==="
echo "After:"
du -sh /nix/store
du -sh "$HOME/.cache/nix" 2>/dev/null || true
