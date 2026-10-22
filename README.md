# Dotfiles

Workstation configuration managed by Mise. App settings are declared in native
config layers that preserve machine-local preferences and runtime state.

## Architecture

- **Mise** manages packages, macOS defaults, developer tools, external Git
  checkouts, and plain dotfiles.
- **Native app config layers** declare shared Codex, Claude, and OpenCode
  settings; the apps merge those with their own local state.
- **Skill scripts** install and scan the pinned skills in `skills-lock.json`.

```text
~/dotfiles/
├── mise/
│   ├── config.toml                  # workstation, tools, repos, dotfiles, tasks
│   └── mise.lock                    # locked tool artifacts
├── dotfiles/                        # plain files with their real target names
│   ├── .config/shell/               # shared shell environment and aliases
│   ├── .config/zsh/custom.zsh       # interactive Zsh behavior
│   └── .zshrc                       # Zsh entry point
└── scripts/
    ├── agent-skills/                # pinned skill installation and scanning
    ├── bootstrap.sh                 # install Mise and preview convergence
    └── update.sh                    # apply and upgrade managed state
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
defaults, follows the declared external Git branches, links plain dotfiles, and
installs versioned tools. Its final bootstrap task installs skill security tooling
and synchronizes pinned agent skills. Mise links the shell startup files,
including activation and login-shell shims. The declarative phases are idempotent and skip state that already matches the
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
mkdir -p "$HOME/.agents/skills"  # source for the Claude skills projection
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
skills stay in place. Chezmoi is no longer used or installed by this repository.
The config and lockfile link back to `mise/`, so tool updates use the repository
sources. Tool upgrades are explicit; no dotfiles watcher or automatic history
synchronization is enabled.

## Daily Usage

Apply the current checkout without upgrading existing packages:

```bash
export MISE_GLOBAL_CONFIG_FILE="$HOME/dotfiles/mise/config.toml"
mise bootstrap --yes
```

Pull with fast-forward only and apply the recorded tool versions on each machine:

```bash
dot-update
```

The checkout must be clean before updating. This command applies workstation
state without refreshing developer tool versions or upgrading existing Homebrew
packages. Shared global tools use the committed macOS ARM lockfile by default.
Locked mode is scoped to `global`: project tools, including `packageManager`
pnpm versions, follow each project's own lock policy. This lets `mise prune`
resolve tracked project requirements even when those projects have no lockfile.

Run explicit upgrades from one machine, review the generated changes, and
commit `mise/config.toml`, `mise/mise.lock`, and referenced dependency sidecars:

```bash
dot-update --upgrade             # also upgrade Homebrew packages
./scripts/update-tools.sh        # developer tools and Claude Code only
```

The maintenance script opts out of locked mode for that run, preserves the
seven-day release-age policy and harness exceptions, and previews pruning.
Codex and OpenCode follow `latest` during explicit maintenance; normal installs
use their recorded versions. Claude Code uses its native updater and can still
update independently. No Mise background tool-update service or `auto_update`
options are declared.

On previously configured machines, retire the old updater service once:

```bash
mise bootstrap services remove mise-tool-update
```

For Crush retirement, the repo no longer declares its binary or config. Remove
old installations explicitly with `mise uninstall --all aqua:charmbracelet/crush`.
Its local session data remains available.

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
target and source in `[dotfiles]`. Use the apps' native config layers for shared
settings. Keep API keys and bearer tokens out of this repository.
Authenticate with each provider's browser/OAuth flow, CLI credential store, or
connected app instead.

See [Executor](docs/executor.md) for client authentication, catalog ownership,
and policy guidance.

## Dotfile Commands

```bash
mde ~/.config/git/shared   # edit shared Git preferences
mdp               # preview plain-file changes
mda               # apply plain-file links
mds               # inspect plain-file status
```

These aliases use `mise dotfiles`, the descriptive spelling supported by the
installed Mise release. Editing through a target symlink also edits the source.

## Updating the other machines once

Before pulling this migration on a machine with the old symlinks, preserve its
current Git identity, credentials, and Codex trust and UI state as regular local files.
Do this **before stashing**, since those links currently point into the checkout:

```bash
for relative in .gitconfig .codex/dotfiles.config.toml; do
  target="$HOME/$relative"
  source="$HOME/dotfiles/dotfiles/$relative"
  if [ -L "$target" ] && [ "$target" -ef "$source" ]; then
    saved=$(mktemp "${target}.migration.XXXXXX")
    cp -p "$target" "$saved"
    mv "$saved" "$target"
  fi
done
cd ~/dotfiles
git stash push --include-untracked -m "before multi-machine config migration"
git pull --ff-only
mise dotfiles apply '~/.config/git/shared' '~/.gitconfig/shared' \
  '~/.codex/dotfiles.config.toml/shared'
```

Review any saved tool/config changes with `git stash show --include-untracked -p`;
reapply wanted tool edits selectively. The local Git/Codex state is already
preserved, so avoid restoring it into the shared sources. The stash remains
available for review.

Verify the migration on each machine:

```bash
test ! -L ~/.gitconfig && test ! -L ~/.codex/dotfiles.config.toml
git status --short
```

Both app-owned files must be regular local files. A remaining Codex profile
symlink lets UI writes change the shared source and dirty the checkout.

## Machine-local Git settings

`~/.gitconfig` is a regular local file with a Mise-managed include block for
`~/.config/git/shared`. The shared file holds preferences; identity and
credential helpers remain local. The pre-dotfiles hook converts only the old
repository-owned root symlink and preserves its entire contents. The included
shared preferences take precedence over inherited copies of those settings.

On a new machine, set the appropriate identity before committing:

```bash
git config --global user.name "Kevin Chen"
git config --global user.email "YOUR_EMAIL_FOR_THIS_MACHINE"
gh auth setup-git
```

The personal repository identity override remains in the shared conditional
include. Existing machines retain their identity and credential helpers during
migration. To change shared Git preferences, edit `dotfiles/.gitconfig`.

## App Settings

Desired settings live in ordinary config files, deployed by Mise:

| App         | Managed source                            | Native loading mechanism                                           |
| ----------- | ----------------------------------------- | ------------------------------------------------------------------ |
| Codex       | `dotfiles/.codex/dotfiles.config.toml`    | Mise merges shared keys into a local profile; `--profile dotfiles` selects it |
| Claude Code | `dotfiles/.config/claude/mcp.json`        | `--mcp-config` adds the declared servers for the session           |
| OpenCode    | `dotfiles/.config/opencode/dotfiles.json` | `OPENCODE_CONFIG` adds an override layer after local global config |

Codex's profile is a regular local file. Mise owns only keys declared in the
shared source and preserves hook trust, UI state, and other application-written
keys. Applying the merge entry converts an existing link to that same source
into a local file. Shared defaults exclude hook approvals and UI state.

The shared shell module selects the Codex profile and Claude MCP file for CLI
sessions and exports the OpenCode override path. Explicit profile/MCP/config
choices take precedence over these shell defaults. Start a new shell after
applying dotfiles. For clients launched outside that shell, select the Codex
profile or pass the Claude MCP file explicitly; these defaults are not forced
into their base configs.

Shared MCP defaults declare only the hosted `executor` server. Keep `nia` and
`codex` registrations in app-owned local configs when needed; Nia credentials
stay local. The standalone research, framework, and `executor-desktop` servers
are no longer part of the default set. Existing local registrations are merged,
so changing these shared files does not remove old entries from app-owned
configs. Use `codex mcp list` and `claude mcp list` to check those separately.

The app-owned `~/.claude.json`, `~/.codex/config.toml`, OpenCode's local global
config and dependency manifest remain unmanaged.
Shared settings override matching keys through native loading; local choices
outside those keys remain intact.

OpenCode v2 uses its native provider login and usage statistics; the v1-only
Codex-auth and TokenScope plugins and dependency seed are removed. Its primary
model and dependency manifest remain local; the title agent uses GPT-6 Luna.
See the [OpenCode v2 guide](dotfiles/.config/opencode/README.md) for subscription
versus API model choices, the dated objective comparison, and migration. Use the
project-scoped [OpenCode model curator](.agents/skills/opencode-model-curator/SKILL.md)
when researching or changing those options. For an existing v2 background service,
set its managed config environment once with
`opencode service set env OPENCODE_CONFIG "$HOME/.config/opencode/dotfiles.json"`.
Mise links Claude's skills directory to `~/.agents/skills`.

Native loading references: [Codex profiles](https://developers.openai.com/codex/config-basic/),
[Claude MCP config](https://code.claude.com/docs/en/cli-reference),
[OpenCode config](https://opencode.ai/v2/docs/config/).

## External Repositories

`[bootstrap.repos]` follows TPM's `master` branch because the tmux config loads
TPM and the Rose Pine plugin through it. Mise clones or updates TPM during
bootstrap. Dirty checkouts or conflicting origins fail instead of discarding
local work.

```bash
mise bootstrap repos apply --dry-run
mise bootstrap repos apply --yes
```

## Agent Skills

Agent skills are declared in `skills-lock.json`. The final bootstrap task runs
the existing security-tool installer and `sync.sh`, installing and
verifying pinned skills under `~/.agents/skills`.

See the [skill script guide](scripts/agent-skills/README.md) for sync, updates,
scanning, and adding upstream skills.

## Validation

Repository-only checks that do not apply workstation state:

```bash
shellcheck scripts/bootstrap.sh scripts/update.sh dotfiles/.config/shell/agents.sh
zsh -n dotfiles/.zshrc dotfiles/.config/zsh/custom.zsh
python3 scripts/check-dotfiles.py
python3 scripts/check-repos.py
python3 scripts/check-native-config.py
mkdir -p /tmp/dotfiles-mise-check
cp mise/config.toml /tmp/dotfiles-mise-check/mise.toml
(cd /tmp/dotfiles-mise-check && mise fmt --check)
```

This configuration requires mise `2026.10.6` or newer, the release used to validate
the automatic tool-update service. Mise marks the bootstrap features experimental. The config declares that minimum explicitly so an
older executable fails with update guidance instead of misinterpreting it.

## Resources

- [Executor setup and ownership](docs/executor.md)
- [Local household agent on the 16 GB M4 Mac mini](docs/local-household-agent.md)
- [Podman VM provider](vfkit.md)
- [tmux setup](docs/tmux.md)

- [mise dotfiles](https://mise.jdx.dev/dotfiles.html)
- [mise bootstrap](https://mise.jdx.dev/cli/bootstrap.html)
- [mise bootstrap packages](https://mise.jdx.dev/bootstrap/packages/)
- [mise macOS defaults](https://mise.jdx.dev/bootstrap/macos-defaults.html)
- [Mise Git repositories](https://mise.jdx.dev/bootstrap/repos.html)

## Repository maintenance

Project skills live in `.agents/skills/`; shared upstream skills are pinned in
`skills-lock.json`. Agents must never execute deletion commands, including
uninstall, prune, or scripts that delete files internally. They provide the
exact cleanup commands for the operator instead. Dry-run previews are allowed.

Commit `mise/config.toml`, `mise/mise.lock`, and generated `mise/.mise/locks/`
dependency sidecars together. They are reproducibility inputs, not caches.

Herdr and its companion plugins are no longer declared or installed by this
repository.
