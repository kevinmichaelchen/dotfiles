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

# Environment variables
export EDITOR="vim"
export VOLTA_HOME="$HOME/.volta"

# Fix PATH for nix-darwin (macOS path_helper overrides /etc/zshenv)
[[ ":$PATH:" != *":/etc/profiles/per-user/$USER/bin:"* ]] && export PATH="/etc/profiles/per-user/$USER/bin:$PATH"

# Only append to PATH if these directories aren't already there
[[ ":$PATH:" != *":$HOME/.opencode/bin:"* ]] && export PATH="$PATH:$HOME/.opencode/bin"
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$PATH:$HOME/.local/bin"
[[ ":$PATH:" != *":$VOLTA_HOME/bin:"* ]] && export PATH="$PATH:$VOLTA_HOME/bin"
[[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]] && export PATH="$PATH:$HOME/.cargo/bin"
[[ ":$PATH:" != *":$HOME/go/bin:"* ]] && export PATH="$PATH:$HOME/go/bin"
[[ ":$PATH:" != *":$HOME/.deno/bin:"* ]] && export PATH="$PATH:$HOME/.deno/bin"

# Load shell-agnostic aliases
[[ -f ~/.config/shell/bat.sh ]] && source ~/.config/shell/bat.sh
[[ -f ~/.config/shell/claude.sh ]] && source ~/.config/shell/claude.sh
[[ -f ~/.config/shell/exa.sh ]] && source ~/.config/shell/exa.sh
[[ -f ~/.config/shell/git.sh ]] && source ~/.config/shell/git.sh
[[ -f ~/.config/shell/pnpm.sh ]] && source ~/.config/shell/pnpm.sh
[[ -f ~/.config/shell/python.sh ]] && source ~/.config/shell/python.sh
[[ -f ~/.config/shell/testcontainers.sh ]] && source ~/.config/shell/testcontainers.sh
[[ -f ~/.config/shell/zed.sh ]] && source ~/.config/shell/zed.sh
[[ -f ~/.config/shell/github.sh ]] && source ~/.config/shell/github.sh
[[ -f ~/.config/shell/hygraph.sh ]] && source ~/.config/shell/hygraph.sh
[[ -f ~/.config/shell/context7.sh ]] && source ~/.config/shell/context7.sh

# Initialize Starship prompt
eval "$(starship init zsh)"

# Initialize zoxide (smarter cd)
eval "$(zoxide init zsh)"

# Load machine-specific configuration if it exists
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local