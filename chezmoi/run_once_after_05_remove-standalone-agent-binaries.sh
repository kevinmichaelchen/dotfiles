#!/bin/sh
# Let Mise-managed Homebrew packages own the OpenCode and Codex executables.

set -eu

rm -f "$HOME/.local/bin/codex"
rm -f "$HOME/.opencode/bin/opencode"
