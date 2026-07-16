# Dotfiles

## Overview

Unified dotfiles using **nix-darwin + Home-Manager** for declarative package
management and **Chezmoi** for templated personal configs. macOS-focused
(aarch64-darwin).

## STRUCTURE

```
~/dotfiles/
├── nix-darwin/           # macOS system config (embeds Home-Manager)
│   ├── flake.nix         # Multi-user flake (kevinchen, kchen)
│   └── configuration.nix # Homebrew, system defaults
├── home-manager/         # Standalone HM for Linux (imports home.nix)
│   └── home.nix          # Shared: packages, aliases, programs
├── chezmoi/              # Personal configs and machine-specific templates
│   ├── dot_config/
│   │   ├── shell/        # Shell-agnostic aliases (git, bat, etc.)
│   │   ├── zsh/          # ZSH config (sources shell/*.sh)
│   │   ├── mise/         # Dev tools (node, go, rust, cargo:*)
│   │   ├── opencode/     # OpenCode AI agent config
│   │   └── starship.toml # Rose Pine prompt theme
│   └── dot_local/
│       └── share/
│           └── crush/    # Crush AI agent config
└── scripts/              # bootstrap.sh, update.sh
```

## WHERE TO LOOK

| Task                          | Location                              | Notes                  |
| ----------------------------- | ------------------------------------- | ---------------------- |
| Add system package            | `home-manager/home.nix`               | `home.packages` list   |
| Add Homebrew formula/cask     | `nix-darwin/configuration.nix`        | `homebrew.brews/casks` |
| Add dev tool (node, rust, go) | `chezmoi/dot_config/mise/config.toml` | Mise manages runtimes  |
| Add shell alias (stable)      | `home-manager/home.nix`               | `home.shellAliases`    |
| Add shell alias (evolving)    | `chezmoi/dot_config/shell/*.sh`       | Sourced by custom.zsh  |
| Edit ZSH config               | `chezmoi/dot_config/zsh/custom.zsh`   | PATH, evals, sources   |
| Edit prompt                   | `chezmoi/dot_config/starship.toml`    | Rose Pine theme        |
| Configure tool authentication | Provider CLI or connected app         | Keep keys out of Chezmoi |

## CONVENTIONS

### Philosophy: "Use Nix Less"

- **Nix/HM**: Stable packages, shells, one-time setups
- **Chezmoi**: Quick-iteration configs and templates
- **Mise**: Dev runtimes and tools (node, go, rust, cargo:_, npm:_)

### Naming

- Chezmoi prefixes: `dot_` → `.`, `.tmpl` → machine-specific template
- Shell scripts: `*.sh` (shell-agnostic, sourced by zsh/bash)

### PATH Order (intentional)

```
mise tools → Nix per-user → ~/.local/bin → Homebrew
```

mise takes precedence over Nix for dev tools.

### Multi-User Flake

`nix-darwin/flake.nix` defines `mkDarwinConfig` for usernames:

- `kevinchen` (personal)
- `kchen` (work)
- `default` → kevinchen

## ANTI-PATTERNS

| Don't                        | Why                      | Do Instead                     |
| ---------------------------- | ------------------------ | ------------------------------ |
| Add dev tools to home.nix    | Mise manages runtimes    | Add to `mise/config.toml`      |
| Edit ~/.zshrc directly       | HM generates it          | Edit `chezmoi/.../custom.zsh`  |
| Use nix-darwin on Linux      | Linux uses standalone HM | Check `$OSTYPE` in scripts     |
| Put API keys in Chezmoi      | Use provider-owned auth  | Browser/OAuth login or app connection |
| Run `chezmoi` without source | Uses wrong source dir    | Use `cm`, `cma`, `cme` aliases |

## COMMANDS

```bash
# Apply system config (macOS)
darwin-rebuild switch --flake ~/dotfiles/nix-darwin#default
# or: dr (alias)

# Apply chezmoi configs
chezmoi apply --source=$HOME/dotfiles/chezmoi
# or: cma (alias)

# Update everything
dot-update  # pulls git + applies both

# Edit configs
hme         # home.nix
dre         # configuration.nix (nix-darwin)
cme <file>  # chezmoi edit

# Install mise tools after editing config.toml
mise install
```

## NOTES

- **Ghostty**: macOS builds require Homebrew (Nix can't do app bundles). See
  `configuration.nix` comments.
- **libpq**: Keg-only in Homebrew, PATH added in `custom.zsh` for psql.
- **Bootstrap sequence**: Nix → darwin-rebuild → chezmoi apply → mise install
