#!/usr/bin/env bash
# Configure machine-local Determinate Nix settings.
#
# Determinate owns /etc/nix/nix.conf and includes /etc/nix/nix.custom.conf for
# user-managed settings. This script updates only a marked block in that custom
# file.

set -euo pipefail

CONFIG_FILE="${NIX_CUSTOM_CONF:-/etc/nix/nix.custom.conf}"
BEGIN_MARKER="# BEGIN dotfiles Determinate Nix 3.20 settings"
END_MARKER="# END dotfiles Determinate Nix 3.20 settings"

tmp_existing="$(mktemp)"
tmp_next="$(mktemp)"
cleanup() {
    rm -f "$tmp_existing" "$tmp_next"
}
trap cleanup EXIT

if [[ -f "$CONFIG_FILE" ]]; then
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$CONFIG_FILE" > "$tmp_existing"
else
    : > "$tmp_existing"
fi

{
    sed '${/^$/d;}' "$tmp_existing"
    printf '\n%s\n' "$BEGIN_MARKER"
    printf '# Warn on discouraged Nix literals without breaking existing flakes.\n'
    printf 'lint-url-literals = warn\n'
    printf 'lint-short-path-literals = warn\n'
    printf 'lint-absolute-path-literals = warn\n'
    printf '%s\n' "$END_MARKER"
} > "$tmp_next"

if [[ "${1:-}" == "--check" ]]; then
    if [[ -f "$CONFIG_FILE" ]]; then
        diff -u "$CONFIG_FILE" "$tmp_next" || true
    else
        cat "$tmp_next"
    fi
    exit 0
fi

root_group="$(id -gn 0 2>/dev/null || echo root)"
sudo install -m 0644 -o root -g "$root_group" "$tmp_next" "$CONFIG_FILE"

echo "Updated $CONFIG_FILE"
echo "Verify with: nix config show | rg 'lint-(url|short|absolute)-path-literals'"
