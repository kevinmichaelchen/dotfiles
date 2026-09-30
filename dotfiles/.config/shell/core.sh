# shellcheck shell=sh
# Shared workstation environment and aliases.

export EDITOR="vim"
export GHQ_ROOT="$HOME/dev"
export CONTAINERS_MACHINE_PROVIDER="libkrun"

alias ls='eza --icons --group-directories-first'
alias ll='eza --icons --group-directories-first -la'
alias l='eza --icons --group-directories-first -l'
alias la='eza --icons --group-directories-first -a'
alias lt='eza --icons --group-directories-first --tree --level=2'
alias tree='eza --tree'
alias rg='rg --sort path'

alias dot='cd ~/dotfiles'
alias dot-update='cd ~/dotfiles && ./scripts/update.sh'

# Mise links configuration files; its bootstrap task synchronizes agent skills.
alias mda='mise dotfiles apply'
alias mdp='mise dotfiles apply --dry-run'
alias mds='mise dotfiles status'
alias mde='mise dotfiles edit'
