# chezmoi/AGENTS.md

## OVERVIEW

Personal configuration files managed by **Chezmoi**. Supports templating with
**1Password** for secrets. This is the "quick iteration" layer — configs that
change frequently or need machine-specific customization.

## STRUCTURE

```
chezmoi/
├── dot_config/
│   ├── shell/          # Shell aliases and env vars (*.sh, *.sh.tmpl)
│   ├── zsh/            # ZSH-specific config (custom.zsh)
│   ├── mise/           # Dev tool versions (config.toml)
│   ├── starship.toml   # Prompt theme (Rose Pine)
│   ├── git/            # Git config
│   ├── bat/            # bat (cat replacement) config
│   ├── ghostty/        # Terminal config
│   └── ...
└── AGENTS.md           # This file
```

## NAMING CONVENTIONS

| Prefix/Suffix | Transformation            | Example                        |
| ------------- | ------------------------- | ------------------------------ |
| `dot_`        | Becomes `.` in target     | `dot_config/` → `.config/`     |
| `.tmpl`       | Template (processes vars) | `github.sh.tmpl` → `github.sh` |
| `private_`    | Sets chmod 600            | `private_ssh/` → `ssh/` (0600) |
| `executable_` | Sets chmod +x             | `executable_script` → `script` |

## 1PASSWORD TEMPLATES

Files ending in `.tmpl` are processed by Chezmoi's template engine. Use
`onepasswordRead` for secrets:

```bash
# In a .sh.tmpl file
export GITHUB_TOKEN={{ onepasswordRead "op://Personal/GitHub Token/credential" }}
export API_KEY={{ onepasswordRead "op://Work/API Key/password" }}
```

**Requirements:**

- 1Password CLI installed (`op`)
- "Integrate with 1Password CLI" enabled in 1Password settings
- Signed into 1Password CLI (`op signin`)

## WHERE TO ADD THINGS

### Shell Aliases

| Type                    | Location                     | Rationale                   |
| ----------------------- | ---------------------------- | --------------------------- |
| Stable, rarely change   | `home-manager/home.nix`      | Declarative, version-pinned |
| Evolving, tool-specific | `dot_config/shell/*.sh`      | Quick iteration, no rebuild |
| Needs secrets           | `dot_config/shell/*.sh.tmpl` | 1Password integration       |

### Environment Variables

| Type                    | Location                                     |
| ----------------------- | -------------------------------------------- |
| Secrets (API keys)      | `dot_config/shell/*.sh.tmpl`                 |
| Tool config (no secret) | `dot_config/shell/*.sh`                      |
| Session-wide            | `home-manager/home.nix` (`sessionVariables`) |

### Tool Configuration

| Tool     | Location                      |
| -------- | ----------------------------- |
| Git      | `dot_config/git/`             |
| Starship | `dot_config/starship.toml`    |
| Mise     | `dot_config/mise/config.toml` |
| Ghostty  | `dot_config/ghostty/`         |
| bat      | `dot_config/bat/`             |
| tmux     | `dot_config/tmux/`            |

## WORKFLOW

```bash
# Edit a file (opens in $EDITOR, copies back on save)
cme dot_config/shell/git.sh

# Preview what would change
cmd

# Apply changes to home directory
cma

# Full command (what aliases expand to)
chezmoi apply --source=$HOME/dotfiles/chezmoi
```

## ANTI-PATTERNS

| Don't                            | Why                          | Do Instead                 |
| -------------------------------- | ---------------------------- | -------------------------- |
| Hardcode secrets                 | Exposes credentials in git   | Use `.tmpl` with 1Password |
| Edit `~/.config/*` directly      | Changes lost on next apply   | Edit here, then `cma`      |
| Run `chezmoi` without `--source` | Uses wrong source directory  | Use `cm*` aliases          |
| Add dev runtimes here            | Mise manages those           | Edit `mise/config.toml`    |
| Create new shell in `zsh/`       | Shell scripts go in `shell/` | Add `shell/*.sh` instead   |

## ADDING A NEW TOOL CONFIG

1. **Create the config file:**

   ```bash
   mkdir -p chezmoi/dot_config/newtool
   touch chezmoi/dot_config/newtool/config.toml
   ```

2. **If it needs secrets, use `.tmpl`:**

   ```bash
   touch chezmoi/dot_config/newtool/config.toml.tmpl
   ```

3. **Apply:**
   ```bash
   cma
   ```

## TEMPLATE SYNTAX

Chezmoi uses Go's `text/template` syntax:

```
# Variable substitution
{{ .chezmoi.username }}
{{ .chezmoi.hostname }}

# 1Password secret
{{ onepasswordRead "op://Vault/Item/field" }}

# Conditional
{{ if eq .chezmoi.os "darwin" }}
# macOS-specific config
{{ end }}

# Environment variable
{{ env "HOME" }}
```

## DEBUGGING

```bash
# See what chezmoi would do
chezmoi diff --source=$HOME/dotfiles/chezmoi

# Execute template and see output
chezmoi execute-template < dot_config/shell/test.sh.tmpl

# Verbose apply
chezmoi apply --source=$HOME/dotfiles/chezmoi --verbose
```
