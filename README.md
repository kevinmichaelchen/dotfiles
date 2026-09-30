# Dotfiles

Workstation configuration managed by Mise. App settings are declared in native
config layers that preserve machine-local preferences and runtime state.

## Architecture

- **Mise** manages packages, macOS defaults, developer tools, external Git
  checkouts, and plain dotfiles.
- **Native app config layers** declare shared Codex, Claude, OpenCode, and Crush
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
target and source in `[dotfiles]`. Use the apps' native config layers for shared
settings. Keep API keys and bearer tokens out of this repository.
Authenticate with each provider's browser/OAuth flow, CLI credential store, or
connected app instead.

Executor does not require a dotfiles-managed bearer token. Cloud uses each MCP
client's OAuth flow, while Desktop runs locally over `executor mcp` stdio.
After the first apply on a machine, authenticate the Cloud endpoint in the
clients that expose an explicit login command:

```bash
codex mcp login executor
opencode mcp auth executor
```

For Claude Code, launch `claude` from a new configured shell and authenticate
Executor through `/mcp`; its MCP file is loaded for the session. Crush connects
through `mcp-remote`, which starts its OAuth flow when needed.

## Dotfile Commands

```bash
mde ~/.gitconfig   # edit a Mise-managed source
mdp               # preview plain-file changes
mda               # apply plain-file links
mds               # inspect plain-file status
```

These aliases use `mise dotfiles`, the descriptive spelling supported by the
installed Mise release. Editing through a target symlink also edits the source.

## App Settings

Desired settings live in ordinary config files, linked by Mise:

| App | Managed source | Native loading mechanism |
| --- | --- | --- |
| Codex | `dotfiles/.codex/dotfiles.config.toml` | `--profile dotfiles` layers over local `~/.codex/config.toml` |
| Claude Code | `dotfiles/.config/claude/mcp.json` | `--mcp-config` adds the declared servers for the session |
| OpenCode | `dotfiles/.config/opencode/dotfiles.json` | `OPENCODE_CONFIG` adds an override layer after local global config |
| Crush | `dotfiles/.config/crush/crushrc` | Native declarations load alongside local `crush.json` and app data |

The shared shell module selects the Codex profile and Claude MCP file for CLI
sessions and exports the OpenCode override path. Explicit profile/MCP/config
choices take precedence over these shell defaults. Start a new shell after
applying dotfiles. For clients launched outside that shell, select the Codex
profile or pass the Claude MCP file explicitly; these defaults are not forced
into their base configs.

The app-owned `~/.claude.json`, `~/.codex/config.toml`, OpenCode's local global
config and dependency manifest, and Crush's local JSON/data remain unmanaged.
Shared settings override matching keys through native loading; local choices
outside those keys remain intact. Crush uses its supported Bash config DSL to
declare MCP servers in memory, and optionally sources `crushrc.local` for local
overrides. No configuration mutation script runs during bootstrap.

OpenCode v2 uses its native provider login and usage statistics; the v1-only
Codex-auth and TokenScope plugins and dependency seed are removed. Its primary
model and dependency manifest remain local; the title agent uses GPT-6 Luna.
See the [OpenCode v2 guide](dotfiles/.config/opencode/README.md) for subscription
versus API model choices and migration. For an existing v2 background service,
set its managed config environment once with
`opencode service set env OPENCODE_CONFIG "$HOME/.config/opencode/dotfiles.json"`.
Mise links Claude's skills directory to `~/.agents/skills`.

The former one-time credential/binary cleanup migrations and nested Mise install
hook have been removed. Existing Chezmoi installations are not uninstalled.

Native loading references: [Codex profiles](https://developers.openai.com/codex/config-basic/),
[Claude MCP config](https://code.claude.com/docs/en/cli-reference),
[OpenCode config](https://opencode.ai/v2/docs/config/), and
[Crush config](https://github.com/charmbracelet/crush/blob/v0.96.1/docs/config/README.md).

## External Repositories

`[bootstrap.repos]` follows TPM's `master` branch because the tmux config loads
TPM and the Rose Pine plugin through it. Mise clones or updates TPM during
bootstrap. The unrelated Hugging Face project is no longer cloned by dotfiles. Dirty checkouts or
conflicting origins fail instead of discarding local work.

```bash
mise bootstrap repos apply --dry-run
mise bootstrap repos apply --yes
```

## Agent Skills

Agent skills are declared in `skills-lock.json`. The final bootstrap task runs
the existing security-tool installer and `sync.sh --prune`, installing and
verifying pinned skills under `~/.agents/skills`.

```bash
~/dotfiles/scripts/agent-skills/sync.sh --prune
~/dotfiles/scripts/agent-skills/update-lock.sh
~/dotfiles/scripts/agent-skills/update-lock.sh --apply
~/dotfiles/scripts/agent-skills/scan.sh --all
```

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

This configuration requires mise `2026.7.7` or newer, the release used to validate
the migration. Mise marks the bootstrap features experimental. The config declares that minimum explicitly so an
older executable fails with update guidance instead of misinterpreting it.

## Resources

- [mise dotfiles](https://mise.jdx.dev/dotfiles.html)
- [mise bootstrap](https://mise.jdx.dev/cli/bootstrap.html)
- [mise bootstrap packages](https://mise.jdx.dev/bootstrap/packages/)
- [mise macOS defaults](https://mise.jdx.dev/bootstrap/macos-defaults.html)
- [Mise Git repositories](https://mise.jdx.dev/bootstrap/repos.html)

## Mixed-agent workstation

[Herdr setup and workflow](docs/herdr.md) runs Codex, Claude Code and OpenCode v2
in persistent tabs, with native subscription auth and separate Git worktrees
for writing agents. After bootstrap, opt in with `mise run herdr:setup`.
