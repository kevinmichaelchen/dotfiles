# shell/AGENTS.md

## OVERVIEW

Shell-agnostic configuration scripts sourced by `~/.config/zsh/custom.zsh`. Each
file configures a specific tool or domain. All files are automatically loaded —
no registration needed.

## FILE ORGANIZATION

**One file per tool/domain:**

| File                | Purpose                             |
| ------------------- | ----------------------------------- |
| `git.sh`            | Git aliases, functions, config      |
| `bat.sh`            | bat (cat replacement) configuration |
| `pnpm.sh`           | pnpm aliases and completions        |
| `python.sh`         | Python/pip configuration            |
| `nix.sh`            | Nix-related aliases                 |
| `testcontainers.sh` | Testcontainers config (Podman)      |
| `*.sh.tmpl`         | Files with 1Password secrets        |

## TEMPLATE VS PLAIN FILES

| Contains Secrets? | File Extension | Example                   |
| ----------------- | -------------- | ------------------------- |
| No                | `.sh`          | `git.sh`, `bat.sh`        |
| Yes               | `.sh.tmpl`     | `github.sh.tmpl` (tokens) |

**Template files** use 1Password integration:

```bash
# github.sh.tmpl
export GITHUB_TOKEN={{ onepasswordRead "op://Personal/GitHub/token" }}
```

## CONVENTIONS

### Shell Compatibility

Scripts should work in **both bash and zsh**:

- Use `[[ ]]` for conditionals (works in both)
- Use `function name()` syntax for functions
- Avoid zsh-specific features unless checking `$ZSH_VERSION`

### File Structure

```bash
# tool.sh

# === Exports (environment variables) ===
export TOOL_HOME="$HOME/.tool"
export TOOL_CONFIG="$HOME/.config/tool"

# === Aliases ===
alias tool-status='tool status --verbose'
alias tool-update='tool update && tool clean'

# === Functions ===
function tool-init() {
  # Initialize tool with sensible defaults
  tool init --defaults
}

# === Completions (if needed) ===
if [[ -n "$ZSH_VERSION" ]]; then
  # zsh-specific completion
fi
```

### Grouping Related Aliases

```bash
# Good: grouped by purpose
alias gs='git status'
alias ga='git add'
alias gc='git commit'

# Bad: scattered randomly
alias gs='git status'
alias docker-clean='docker system prune'
alias ga='git add'
```

## ADDING A NEW TOOL

1. **Create the file:**

   ```bash
   touch chezmoi/dot_config/shell/newtool.sh
   ```

2. **Add configuration:**

   ```bash
   # newtool.sh
   export NEWTOOL_HOME="$HOME/.newtool"
   alias nt='newtool'
   alias nt-status='newtool status'
   ```

3. **Apply:**

   ```bash
   cma
   ```

4. **Reload shell or source manually:**
   ```bash
   source ~/.config/shell/newtool.sh
   ```

**No other changes needed** — `custom.zsh` sources all `*.sh` files
automatically.

## ADDING SECRETS

1. **Create a template file:**

   ```bash
   touch chezmoi/dot_config/shell/newtool.sh.tmpl
   ```

2. **Add 1Password reference:**

   ```bash
   # newtool.sh.tmpl
   export NEWTOOL_API_KEY={{ onepasswordRead "op://Vault/Newtool/api-key" }}
   ```

3. **Apply (will prompt for 1Password auth):**
   ```bash
   cma
   ```

## ANTI-PATTERNS

| Don't                      | Why                      | Do Instead                 |
| -------------------------- | ------------------------ | -------------------------- |
| Put everything in one file | Hard to find, maintain   | One file per tool          |
| Hardcode secrets           | Security risk            | Use `.sh.tmpl` + 1Password |
| Use bash-only syntax       | May break in zsh         | Use portable syntax        |
| Add to `zsh/custom.zsh`    | That file sources these  | Create new `.sh` here      |
| Prefix with `dot_`         | Already in `dot_config/` | Just use `name.sh`         |

## HOW LOADING WORKS

In `~/.config/zsh/custom.zsh`:

```bash
# Source all shell config files
for file in ~/.config/shell/*.sh; do
  [[ -f "$file" ]] && source "$file"
done
```

Files are loaded in **alphabetical order**. If order matters, prefix with
numbers:

```
01-base.sh
02-exports.sh
99-cleanup.sh
```

## DEBUGGING

```bash
# Check if file is being sourced
echo "Loading newtool.sh" >> /tmp/shell-debug.log

# Test template output
chezmoi execute-template < chezmoi/dot_config/shell/newtool.sh.tmpl

# Source manually to see errors
source ~/.config/shell/newtool.sh
```
