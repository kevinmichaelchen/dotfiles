# ZSH configuration managed by Chezmoi

# ZSH Options
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # Make cd push the old directory onto the stack
setopt PUSHD_IGNORE_DUPS    # Don't push duplicate directories
setopt PUSHD_SILENT         # Don't print the directory stack after pushd/popd
setopt HIST_VERIFY          # Don't execute immediately upon history expansion
setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks from history
setopt EXTENDED_GLOB        # Use extended globbing syntax
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell

# History configuration
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ZSH-specific completion settings
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Case-insensitive completion
zstyle ':completion:*' menu select                          # Highlight selection in completion menu

# Cache completion initialization for one day.
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Load Homebrew-provided Zsh plugins when present. mise's built-in Homebrew
# installer does not require the brew CLI, so fall back to the native prefix.
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
elif [[ -d /opt/homebrew ]]; then
  BREW_PREFIX="/opt/homebrew"
fi
[[ -n "${BREW_PREFIX:-}" ]] && \
  [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Initialize mise before adding user-local fallback paths.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
elif [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Load OrbStack shell integration when OrbStack is installed.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Only append to PATH if these directories aren't already there
[[ ":$PATH:" != *":$HOME/.opencode/bin:"* ]] && export PATH="$PATH:$HOME/.opencode/bin"
[[ -x "$HOME/.fiberplane/bin/fp" ]] && [[ ":$PATH:" != *":$HOME/.fiberplane/bin:"* ]] && export PATH="$PATH:$HOME/.fiberplane/bin"
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$PATH:$HOME/.local/bin"
[[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]] && export PATH="$PATH:$HOME/.cargo/bin"
[[ ":$PATH:" != *":$HOME/go/bin:"* ]] && export PATH="$PATH:$HOME/go/bin"
[[ ":$PATH:" != *":$HOME/.deno/bin:"* ]] && export PATH="$PATH:$HOME/.deno/bin"
# Keep Bun globals behind Mise-managed bins so pinned npm CLIs win resolution.
path=(${path:#$HOME/.bun/bin})
path+=("$HOME/.bun/bin")
export PATH="${(j/:/)path}"
# libpq is keg-only (not symlinked) to avoid conflicts with full PostgreSQL
[[ -d "/opt/homebrew/opt/libpq/bin" ]] && [[ ":$PATH:" != *":/opt/homebrew/opt/libpq/bin:"* ]] && export PATH="$PATH:/opt/homebrew/opt/libpq/bin"

# Load shell-agnostic aliases
[[ -f ~/.config/shell/executor-auth.sh ]] && source ~/.config/shell/executor-auth.sh
[[ -f ~/.config/shell/core.sh ]] && source ~/.config/shell/core.sh
[[ -f ~/.config/shell/bat.sh ]] && source ~/.config/shell/bat.sh
[[ -f ~/.config/shell/git.sh ]] && source ~/.config/shell/git.sh
[[ -f ~/.config/shell/pnpm.sh ]] && source ~/.config/shell/pnpm.sh
[[ -f ~/.config/shell/python.sh ]] && source ~/.config/shell/python.sh
[[ -f ~/.config/shell/testcontainers.sh ]] && source ~/.config/shell/testcontainers.sh
[[ -f ~/.config/shell/zed.sh ]] && source ~/.config/shell/zed.sh
[[ -f ~/.config/shell/github.sh ]] && source ~/.config/shell/github.sh

# Initialize Starship prompt
eval "$(starship init zsh)"

# Initialize zoxide (smarter cd)
eval "$(zoxide init zsh)"

# fzf shell key bindings and completion.
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
  export FZF_CTRL_T_COMMAND='fd --type f --type d --hidden --strip-cwd-prefix --exclude .git'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  source <(fzf --zsh)
fi

# Syntax highlighting must be sourced after other interactive shell setup.
if [[ -n "${BREW_PREFIX:-}" ]] && \
   [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Load machine-specific configuration if it exists
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
