# Herdr: subscriptions and API agents together

Herdr runs the native CLIs in persistent terminal tabs. Use Codex with your
OpenAI login, Claude Code with your Claude login, and OpenCode v2 for API models.
Herdr does not pool subscription quotas or translate subscription logins into
API keys. All three can run at once; their normal approval prompts remain.

## Apply once

After the parent Mise migration PR is applied:

```sh
export MISE_GLOBAL_CONFIG_FILE="$HOME/dotfiles/mise/config.toml"
mise install github:herdrdev/herdr
mise dotfiles apply --dry-run
mise dotfiles apply --yes
mise run herdr:setup
herdr
```

If an existing Herdr config conflicts, compare it with the repository source
before replacing that file. The setup task uses Herdr's native integration
installers: they register session hooks in local Codex and Claude settings and
OpenCode's TUI configuration, preserving unrelated entries. They are explicit
setup operations, not Python config editors or automatic bootstrap hooks.
Codex and Claude must already have their configuration directories. Check
`herdr integration status` after upgrading Herdr; rerun the task when hooks
need updating. Restart existing agent processes after installing integrations;
OpenCode v2 also needs its shared service restarted (`opencode service stop`).
If OpenCode defers registration while migrating an old TUI config, complete
that native migration and rerun setup.

Dotfiles owns only Herdr's `config.toml` and our small local plugin manifest.
Herdr owns plugin registration, named sessions, machines, logs, worktrees and
runtime state. Settings in Herdr's UI may write through the config symlink;
review the resulting Git diff. Use Mise for upgrades, not `herdr update`.
The pinned release is 0.9.3; the lockfile records the macOS arm64 binary checksum.

## Daily workflow

The prefix is **Ctrl+S**, leaving Ctrl+B available for outer tmux. Herdr panes
use login Zsh so Mise activation and workstation PATH setup load normally.
Run Herdr directly in Ghostty when possible. If Ctrl+S freezes an outer shell,
disable that shell's software flow control with `stty -ixon` before launching.

| After Ctrl+S | Action |
| --- | --- |
| Alt+C | Codex tab, using the `dotfiles` profile |
| Alt+A | Claude Code tab, using the declared MCP file |
| Alt+O | OpenCode v2 tab, using its declared config layer |
| ] / [ | Next / previous agent |
| Alt+1…9 | Focus an agent by its sidebar index |
| Shift+G | Create a Git worktree and open its workspace |
| Alt+G | Open an existing worktree |
| U | Copy mode |
| O | Focus the latest notification target |
| Q | Detach; processes keep running |
| ? | Show all shortcuts |

The launcher is a declarative local Herdr plugin: three native commands, no
build step, event hooks, background jobs or downloaded third-party code. Each
opens a tab in the selected checkout. If your terminal does not transmit Alt
combinations, use the equivalent CLI from a shell in the desired workspace:

```sh
herdr plugin pane open --plugin kevin.agents --entrypoint codex
herdr plugin pane open --plugin kevin.agents --entrypoint claude
herdr plugin pane open --plugin kevin.agents --entrypoint opencode
```

Give every agent that edits code its own worktree and branch. Create/open the
worktree first, then launch its agent there. Tabs alone share the checkout and
provide no Git isolation. A useful starting team is Codex for implementation,
Claude for independent review, and OpenCode for bounded API-backed work. Keep
review agents read-only when they inspect the implementation checkout.

Ask a coordinator to read `herdr --skill` before controlling other panes. It
can use `agent list`, `agent prompt`, `agent read` and `agent wait`. Have workers
write results to a file when you need reliable structured handoffs. Screen
status is a hint: particularly for Codex, `unknown` is not completion, and a
wait can finish for an already-running turn rather than your new prompt.
Review output and changes before merging.

## Model spending

Start with the subscriptions you already pay for. The launchers preserve native
model selection: Codex uses the existing dotfiles profile; Claude and OpenCode
use their own saved selection. No prompts, inference requests or API charges
happen during setup. Sign in through each CLI's native auth flow.

For OpenRouter or Fireworks, choose an available economical model in OpenCode's
model picker (for example a current GLM, Kimi or DeepSeek offering). Compare the
provider's current price and performance on one bounded task before expanding
parallelism. Model catalogs and prices change too quickly to hardcode a
supposed universal cheapest choice here. Keep keys in native credential
storage; do not put them in Herdr or this repository. OpenCode's declared
OpenRouter layer requests providers that deny data collection; that may narrow
available routes.

## Why these defaults

Rosé Pine follows the existing prompt theme, with Dawn for light terminals.
Priority sorting puts agents needing attention first; labels and symbol status
indicators distinguish the CLIs. In-app notifications need no system permission.
Native session restore is enabled, but terminal screen history is not copied
to a second persistent archive. Herdr still keeps its ordinary session state,
logs and native agent transcripts. Detaching keeps processes alive; a cold
restart resumes supported conversations, not arbitrary processes. Sleep and
reboot are not continuous execution. SSH machines remain opt-in.

Herdr's binary is Mise-managed. Agent detection manifest updates remain enabled
so upstream can fix screen recognition independently of a binary upgrade.

## Plugins considered

The marketplace is automatically indexed GitHub content, not a reviewed
extension collection. We use core worktrees and a local manifest initially.

- [Herdr Projects](https://github.com/eliasstravik/herdr-projects) is the most
  relevant next step for autonomous coordinator/worker threads and shared
  memory. Its setup also modifies harness hooks and skills; its ticker nudges
  agents, follows PRs, and cleans resolved worktrees. Keep it a deliberate
  separate adoption rather than silently enabling that policy here.
- [Reviewr](https://github.com/persiyanov/herdr-reviewr) adds a diff/PR review UI
  and sends review comments to agents. Useful if terminal review becomes a
  bottleneck; it is not required to run mixed agents.
- Remote-machine and live-handoff features are useful later. The handoff blog
  describes same-machine Unix process transfer, not reboot recovery. This
  configuration does not invoke Herdr's self-updater to perform it.

## Sources and validation

Reviewed the docs, all seven posts linked by the blog index, the marketplace,
and configuration/plugin/integration code at release
[0.9.3](https://github.com/herdrdev/herdr/tree/v0.9.3).
The website's next docs can differ from the binary; test against the pin.

- [Configuration](https://herdr.dev/docs/configuration/),
  [CLI](https://herdr.dev/docs/cli-reference/),
  [integrations](https://herdr.dev/docs/integrations/),
  [session state](https://herdr.dev/docs/session-state/)
- [Plugins](https://herdr.dev/docs/plugins/),
  [marketplace](https://herdr.dev/plugins/), [blog](https://herdr.dev/blog/)

Run `python3 scripts/check-herdr.py` with Herdr on PATH. It validates the config,
links the plugin, launches each manifest command with fake agent executables,
and tests native hook installation/idempotence in an isolated temporary home.
No account login, paid model call or live workstation change is needed.
