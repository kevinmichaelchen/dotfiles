# shellcheck shell=bash
# Optional conveniences for Ubuntu's existing Bash configuration.
[[ $- == *i* ]] || return 0

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza --icons --group-directories-first -la'
  alias l='eza --icons --group-directories-first -l'
  alias la='eza --icons --group-directories-first -a'
  alias lt='eza --icons --group-directories-first --tree --level=2'
  alias tree='eza --tree'
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

if command -v fzf >/dev/null 2>&1; then
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
    export FZF_CTRL_T_COMMAND='fd --type f --type d --hidden --strip-cwd-prefix --exclude .git'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  eval "$(fzf --bash)"
fi

alias dot='cd ~/dotfiles'

# Shared aliases have no startup-time tool or network calls.
for module in git github pnpm; do
  # shellcheck disable=SC1090
  [[ ! -r "$HOME/.config/shell/$module.sh" ]] || source "$HOME/.config/shell/$module.sh"
done
unset module
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias bathelp='bat --plain --language=help'
fi
