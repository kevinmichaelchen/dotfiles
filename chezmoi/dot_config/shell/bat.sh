#!/bin/sh
# bat aliases and functions
# Shell-agnostic - can be sourced by bash, zsh, etc.

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
