# Dotfiles

Workstation configuration built around mise for machine convergence and plain
dotfiles, with Chezmoi for modification templates, create-only files, external
repositories, and hooks.

## Architecture

The active configuration has two owners:

- **mise** manages machine-global packages, macOS defaults, language runtimes,
  development CLI versions, and plain configuration files through `[dotfiles]`.
- **Chezmoi** modifies selected JSON/TOML settings while preserving local keys,
  seeds create-only files, fetches external repositories, and runs the existing
  apply hooks. Authentication belongs to each tool or connected app.

```text
~/dotfiles/
├── mise/
│   ├── config.toml                  # workstation, tool, and dotfile declarations
│   └── mise.lock                    # locked tool artifacts
├── dotfiles/                        # plain files, with their real target names
│   ├── .config/shell/               # shared shell environment and aliases
│   ├── .config/zsh/custom.zsh       # interactive Zsh behavior
│   └── .zshrc                       # Zsh entry point
├── chezmoi/                         # modification templates and apply hooks
└── scripts/
    ├── bootstrap.sh                 # install mise and preview convergence
    ├── update.sh                    # apply and upgrade managed state
    └── check-dotfiles.py            # isolated migration and convergence checks
```

## Bootstrap

The bootstrap script clones this repository when needed, installs the current
mise release into `~/.local/bin`, trusts the repository config, and prints a dry
run including replacements. It does not apply the previewed workstation changes.

```bash
curl -fsSL \
  https://raw.githubusercontent.com/kevinmichaelchen/dotfiles/main/scripts/bootstrap.sh |
  bash
```

After reviewing the dry run, apply the configuration:

```bash
export MISE_GLOBAL_CONFIG_FILE="$HOME/dotfiles/mise/config.toml"
~/.local/bin/mise trust "$MISE_GLOBAL_CONFIG_FILE"
~/.local/bin/mise bootstrap --yes --update
~/.local/bin/mise bootstrap status --missing
```

`mise bootstrap` installs missing Homebrew formulae and casks, applies macOS
defaults, links plain dotfiles, installs versioned tools, and finally runs
Chezmoi. Mise links the shell startup files, including activation and
login-shell shims. The declarative phases are idempotent and skip state that already matches the
configuration.

## Migrating Existing Chezmoi Files

This layout expects the checkout at `~/dotfiles` (or a symlink there to your
checkout). Sources use explicit repository paths so they work both during the
first bootstrap and through the installed global-config symlink.

Existing regular files can conflict with the new links. Review local changes
against their sources in `dotfiles/` and keep any edits you want before replacing
those targets. Preview replacement without changing the machine:

```bash
export MISE_GLOBAL_CONFIG_FILE="$HOME/dotfiles/mise/config.toml"
mise trust "$MISE_GLOBAL_CONFIG_FILE"
mise dotfiles apply --force --dry-run
```

After reviewing, replace the plain-file targets once and finish bootstrap:

```bash
mise dotfiles apply --force --yes
mise bootstrap --yes
mise dotfiles status
```

Subsequent applies need no force flag. Each plain file has its own link, so
runtime files alongside OpenCode configuration and installed upstream agent
skills stay in place. Chezmoi no longer declares any of these 29 targets.
The config and lockfile link back to `mise/`, so tool updates use the repository
sources. No watcher or automatic history synchronization is enabled.

## Daily Usage

Apply the current checkout without upgrading existing packages:

```bash
export MISE_GLOBAL_CONFIG_FILE="$HOME/dotfiles/mise/config.toml"
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
`[bootstrap.packages]` in `mise/config.toml`. Use `brew:`,
`brew-cask:`, or the appropriate Linux package-manager prefix.

Add runtimes and versioned developer CLIs to `[tools]` in the same file. Prefer
checksum-capable Aqua, GitHub, or core mise backends where available, and
update `mise.lock` after changing versions.

Add macOS preferences to the friendly `[bootstrap.macos.*]` sections or to
`[bootstrap.macos.defaults]` for raw scalar defaults.

Keep plain personal files and shell behavior under `dotfiles/`, and declare each
target and source in `[dotfiles]`. Keep modification templates and hooks under
`chezmoi/`. Keep API keys and bearer tokens out of this repository and its templates. Authenticate with each
provider's browser/OAuth flow, CLI credential store, or connected app instead.

Executor does not require a dotfiles-managed bearer token. Cloud uses each MCP
client's OAuth flow, while Desktop runs locally over `executor mcp` stdio.
After the first apply on a machine, authenticate the Cloud endpoint in the
clients that expose an explicit login command:

```bash
codex mcp login executor
claude mcp login executor
opencode mcp auth executor
```

Crush connects through `mcp-remote`, which starts its OAuth flow when needed.

## Dotfile Commands

```bash
mde ~/.gitconfig   # edit a Mise-managed source
mdp               # preview plain-file changes
mda               # apply plain-file links
mds               # inspect plain-file status
```

These aliases use `mise dotfiles`, the descriptive spelling supported by the
installed Mise release. Editing through a target symlink also edits the source.

## Chezmoi Commands

```bash
cme ~/.codex/config.toml   # edit a Chezmoi-managed template
cmd                       # preview template/hook changes
cma                       # apply templates, externals, and hooks
cmu                       # update from the Chezmoi source
```

Chezmoi aliases always use `~/dotfiles/chezmoi` as the explicit source directory.

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
zsh -n dotfiles/.zshrc dotfiles/.config/zsh/custom.zsh
python3 scripts/check-dotfiles.py
mkdir -p /tmp/dotfiles-mise-check
cp mise/config.toml /tmp/dotfiles-mise-check/mise.toml
(cd /tmp/dotfiles-mise-check && mise fmt --check)
```

This configuration requires mise `2026.7.7` or newer, the release used to validate
the migration. Mise marks the bootstrap features experimental. The config declares that minimum explicitly so an
older executable fails with update guidance instead of misinterpreting it.

## Resources

- [mise dotfiles](https://mise.jdx.dev/dotfiles.html)
- [mise bootstrap](https://mise.jdx.dev/cli/bootstrap.html)
- [mise bootstrap packages](https://mise.jdx.dev/bootstrap/packages/)
- [mise macOS defaults](https://mise.jdx.dev/bootstrap/macos-defaults.html)
- [Chezmoi user guide](https://www.chezmoi.io/user-guide/command-overview/)
