# Dotfiles

## Overview

macOS-focused workstation configuration using Mise for machine convergence and
tool versions, plus Chezmoi for personal configuration files and shell behavior.

## Structure

```text
~/dotfiles/
├── chezmoi/
│   ├── dot_config/mise/    # packages, macOS defaults, runtimes, and CLIs
│   ├── dot_config/shell/   # shell-agnostic aliases and environment
│   ├── dot_config/zsh/     # interactive Zsh configuration
│   └── dot_zshrc           # Chezmoi-owned Zsh entry point
└── scripts/                # bootstrap, updates, and agent-skill maintenance
```

## Where to look

| Task | Location |
| --- | --- |
| Add a Homebrew formula/cask | `chezmoi/dot_config/mise/config.toml` under `[bootstrap.packages]` |
| Add a runtime or versioned CLI | `chezmoi/dot_config/mise/config.toml` under `[tools]` |
| Add a shell alias or environment setting | `chezmoi/dot_config/shell/*.sh` |
| Edit interactive Zsh behavior | `chezmoi/dot_config/zsh/custom.zsh` |
| Edit the prompt | `chezmoi/dot_config/starship.toml` |
| Configure authentication | Provider CLI, browser/OAuth flow, or connected app |

## Conventions

- Mise is the only owner of package installation, macOS defaults, runtimes,
  and versioned developer tools.
- Chezmoi owns dotfiles, shell behavior, and application configuration.
- Chezmoi prefixes `dot_` as `.`; templates use `.tmpl` only for non-secret
  machine-specific rendering.
- Keep API keys and bearer tokens out of the repository and Chezmoi templates.
- Run Chezmoi with `--source="$HOME/dotfiles/chezmoi"` or the repository aliases.

## Commands

```bash
# Preview and converge workstation state
mise bootstrap --dry-run
mise bootstrap --yes
mise bootstrap status --missing

# Apply Chezmoi directly
chezmoi apply --source="$HOME/dotfiles/chezmoi"

# Pull, converge, and upgrade
dot-update

# Upgrade versioned tools
./scripts/update-tools.sh
```

## Notes

- libpq is keg-only; `custom.zsh` adds its Homebrew bin directory to `PATH`.
- The bootstrap sequence is Mise packages/defaults/tools followed by Chezmoi.
- Provider-owned authentication is intentionally machine-local.
