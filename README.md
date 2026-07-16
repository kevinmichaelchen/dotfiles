# Dotfiles

Workstation configuration built around mise for machine convergence and
Chezmoi for personal configuration files.

## Architecture

The active configuration has two owners:

- **mise** manages machine-global packages, macOS defaults, language runtimes,
  and development CLI versions.
- **Chezmoi** manages dotfiles, shell behavior, application configuration,
  and machine-specific templates. Authentication belongs to each tool or
  connected app, not to Chezmoi.

The previous `nix-darwin/` and `home-manager/` configurations remain in the
repository temporarily as a rollback reference. They are not called by the
bootstrap or update workflows.

```text
~/dotfiles/
├── chezmoi/
│   ├── dot_config/mise/config.toml  # workstation and tool declarations
│   ├── dot_config/shell/            # shared shell environment and aliases
│   ├── dot_config/zsh/custom.zsh    # interactive Zsh behavior
│   └── dot_zshrc                    # Chezmoi-owned Zsh entry point
├── scripts/
│   ├── bootstrap.sh                 # install mise and preview convergence
│   ├── update.sh                    # apply and upgrade managed state
│   └── update-tools.sh              # upgrade and lock mise tools
├── nix-darwin/                      # inactive migration fallback
└── home-manager/                    # inactive migration fallback
```

## Bootstrap

The bootstrap script clones this repository when needed, installs the current
mise release into `~/.local/bin`, and prints a dry run. It does not apply the
previewed workstation changes.

```bash
curl -fsSL \
  https://raw.githubusercontent.com/kevinmichaelchen/dotfiles/main/scripts/bootstrap.sh |
  bash
```

After reviewing the dry run, apply the configuration:

```bash
export MISE_GLOBAL_CONFIG_FILE="$HOME/dotfiles/chezmoi/dot_config/mise/config.toml"
~/.local/bin/mise bootstrap --yes --update
~/.local/bin/mise bootstrap status --missing
```

`mise bootstrap` installs missing Homebrew formulae and casks, applies macOS
defaults, installs versioned tools, and finally runs Chezmoi. Chezmoi owns the
shell startup files, including mise activation and login-shell shims. The
declarative phases are idempotent and skip state that already matches the
configuration.

## Daily Usage

Apply the current checkout without upgrading existing packages:

```bash
export MISE_GLOBAL_CONFIG_FILE="$HOME/dotfiles/chezmoi/dot_config/mise/config.toml"
mise bootstrap --yes
```

Pull the repository, converge machine state, upgrade machine-global packages,
and update locked development tools:

```bash
dot-update
```

Inspect drift without changing the machine:

```bash
mise bootstrap status
mise bootstrap status --missing
mise bootstrap packages status
mise bootstrap macos defaults status
```

Preview any application step with `--dry-run`:

```bash
mise bootstrap --dry-run
mise bootstrap packages apply --dry-run
mise bootstrap macos defaults apply --dry-run
```

## Ownership

Add machine-global libraries, services, terminal programs, and macOS apps to
`[bootstrap.packages]` in `chezmoi/dot_config/mise/config.toml`. Use `brew:`,
`brew-cask:`, or the appropriate Linux package-manager prefix.

Add runtimes and versioned developer CLIs to `[tools]` in the same file. Prefer
checksum-capable Aqua, GitHub, or core mise backends where available, and
update `mise.lock` after changing versions.

Add macOS preferences to the friendly `[bootstrap.macos.*]` sections or to
`[bootstrap.macos.defaults]` for raw scalar defaults.

Keep personal files and shell behavior under `chezmoi/`. Keep API keys and
bearer tokens out of this repository and its templates. Authenticate with each
provider's browser/OAuth flow, CLI credential store, or connected app instead.

Executor Cloud and Desktop are the only retained bearer credentials. Provision
them once per machine into an unmanaged mode-`0600` shell file, then let the
script update the four client configs:

```bash
~/dotfiles/scripts/configure-executor-auth.sh
```

New shells load `~/.config/shell/executor-auth.sh` automatically. Until that
file is provisioned, Chezmoi skips only the Executor client targets and applies
everything else.

## Chezmoi Commands

```bash
cme ~/.gitconfig  # edit a managed file
cmd               # preview Chezmoi changes
cma               # apply Chezmoi files
cmu               # update from the Chezmoi source
```

The aliases always use `~/dotfiles/chezmoi` as the explicit source directory.

## Agent Skills

Agent skills are declared in `skills-lock.json`. Chezmoi runs
`run_after_02_sync-agent-skills.sh`, which installs and verifies pinned skills
under `~/.agents/skills`.

```bash
~/dotfiles/scripts/agent-skills/sync.sh --prune
~/dotfiles/scripts/agent-skills/update-lock.sh
~/dotfiles/scripts/agent-skills/update-lock.sh --apply
~/dotfiles/scripts/agent-skills/scan.sh --all
```

## Validation

Repository-only checks that do not apply workstation state:

```bash
shellcheck scripts/bootstrap.sh scripts/update.sh
zsh -n chezmoi/dot_zshrc chezmoi/dot_config/zsh/custom.zsh
mkdir -p /tmp/dotfiles-mise-check
cp chezmoi/dot_config/mise/config.toml /tmp/dotfiles-mise-check/mise.toml
(cd /tmp/dotfiles-mise-check && mise fmt --check)
```

The bootstrap features require mise `2026.6.7` or newer and are currently
marked experimental by mise. The config declares that minimum explicitly so an
older executable fails with update guidance instead of misinterpreting it.

## Retiring nix-darwin

Keep the current nix-darwin generation in place until `mise bootstrap` has
completed, `mise bootstrap status --missing` succeeds, and a fresh login shell
can resolve the expected commands. Then remove nix-darwin's activated system
integration with its locally installed uninstaller:

```bash
sudo darwin-uninstaller
exec zsh -l
```

This does not uninstall Determinate Nix itself. The legacy configuration remains
in this repository until the mise migration has been exercised successfully.

## Resources

- [mise bootstrap](https://mise.jdx.dev/cli/bootstrap.html)
- [mise bootstrap packages](https://mise.jdx.dev/bootstrap/packages/)
- [mise macOS defaults](https://mise.jdx.dev/bootstrap/macos-defaults.html)
- [Chezmoi user guide](https://www.chezmoi.io/user-guide/command-overview/)
