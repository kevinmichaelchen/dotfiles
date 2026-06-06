#!/usr/bin/env bash
# Nix store/cache cleanup and maintenance
#
# Run periodically to free disk space by removing older generations while
# preserving recent rollback points, garbage collecting unreferenced store paths,
# and compacting Nix caches.

set -euo pipefail

echo "=== Nix Store Cleanup ==="
keep_generations="${NIX_CLEANUP_KEEP_GENERATIONS:-5}"

if ! [[ "$keep_generations" =~ ^[1-9][0-9]*$ ]]; then
    echo "NIX_CLEANUP_KEEP_GENERATIONS must be a positive integer" >&2
    exit 1
fi

echo "Retention: keeping the most recent $keep_generations generations"
echo "Before:"
du -sh /nix/store
du -sh "$HOME/.cache/nix" 2>/dev/null || true

echo ""
echo "Deleting generations outside the retention window..."

# Delete older darwin-system generations while keeping recent rollback points
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  - darwin-system generations"
    sudo nix-env --delete-generations +"$keep_generations" --profile /nix/var/nix/profiles/system
fi

# Delete older home-manager generations while keeping recent rollback points
if [[ -d ~/.local/state/nix/profiles ]]; then
    echo "  - home-manager generations"
    nix-env --delete-generations +"$keep_generations" --profile ~/.local/state/nix/profiles/home-manager 2>/dev/null || true
fi

# Delete older user profile generations while keeping recent rollback points
echo "  - user profile generations"
nix-env --delete-generations +"$keep_generations"

echo ""
echo "Running garbage collection..."
nix-collect-garbage

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
