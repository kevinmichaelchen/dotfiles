#!/bin/sh
# bat aliases and functions
# Shell-agnostic - can be sourced by bash, zsh, etc.

# Set BAT_THEME dynamically based on macOS appearance
# Delta also respects BAT_THEME, so this applies to git diffs too
if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
  export BAT_THEME="Dracula"
else
  export BAT_THEME="OneHalfLight"
fi

# Use bat as cat with no paging
alias cat='bat --paging=never'

# batdiff - show git diff with syntax highlighting
batdiff() {
    git diff --name-only --relative --diff-filter=d "$@" | xargs -I {} git diff "$@" -- {} | bat --diff
}

# bathelp - colorize help messages
alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}
