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

## Expanded marketplace review (2026-09-29, America/Chicago)

The live [catalog index](https://assets.herdr.dev/plugins/index.json), generated
2026-09-30 04:30 UTC, contains **1,428 plugin manifests in 1,387 repositories**.
All repository metadata was screened programmatically for coordination,
worktrees, messaging, review, memory, costs and notifications; 382 repositories
matched those broad keywords. This is metadata screening, not a code audit of
1,428 plugins. We then reviewed READMEs and executable manifests for the 20
repositories below, using the catalog's exact head commits. Projects additionally
had its configuration/operations docs and source reviewed in the original pass.
Third-party plugins were not installed or tested with authenticated agents.

| Plugin | Fit and recommendation |
| --- | --- |
| [Sessionizer](https://github.com/andrewchng/herdr-sessionizer) | **Best next addition for declarative setup.** TOML declares project roots, tabs, splits, commands and repo overrides. Fuzzy project/worktree/PR navigation. Bun build and fzf; those tools are already managed here. It lays out a checkout, not one worktree per agent automatically. |
| [Workspace Manager](https://github.com/razajamil/herdr-plugin-workspace-manager) | Declarative YAML layouts, branch rules and automatic layout on new worktrees. Good alternative when automatic per-repo setup is the priority; choose it or Sessionizer initially to avoid overlapping layout ownership. |
| [Swarm](https://github.com/StructuPath/herdr-swarm) | **Best bounded fan-out candidate.** Worktree per agent, configurable command presets, change visibility and review-first harvest. Includes merge/publish/prune operations and explicit cleanup gates. Review its Git mutation policy before enabling; custom shell presets require care. |
| [Projects](https://github.com/eliasstravik/herdr-projects) | **Best autonomous coordinator candidate.** Coordinator conversation, native harness profiles, parallel worktree threads, shared memory and PR follow-up. Broader automation than Swarm; setup changes hooks/skills and a ticker manages nudges and cleanup. |
| [Reviewr](https://github.com/persiyanov/herdr-reviewr) | **Best review addition.** Diff/file/PR pane with comments returned to the agent. Complementary to the coordinator/layout tools. |
| [Annotate](https://github.com/plannotator/herdr-annotate) | Strong for Markdown plans, agent replies and selected terminal text; documents OpenCode 1 and 2 support. Prefer it when feedback is mainly plans/prose rather than code diffs. |
| [Plannotator](https://github.com/plannotator/herdr-plannotator) | Existing Plannotator approval page inside a Herdr browser. Adds Browser, Chrome/Chromium and Bun requirements; heavier than terminal Annotate. |
| [Chatter](https://github.com/marcvermeeren/chatter) | Promising repo-scoped mixed-agent chat, tasks, shared notes and handoffs, with worktree spawning. Queued/status-aware delivery is richer than Messenger. Still an experiment with a state database and event hooks; not a verified OpenCode v2 adapter. |
| [Agent Messenger](https://github.com/aashishd/herdr-agent-messenger) | Lightweight live-pane messages across Claude/Codex/Pi/OpenCode. Installs adapters/skills using Bash and Python. Explicitly lacks delivery acknowledgements/threading; a message is not evidence the receiving agent acted. |
| [AWP](https://github.com/agentwireprotocol/awp) | Peer-to-peer, acknowledged messaging, disk queues and files across machines. Useful when we add remote workers; introduces a network daemon and native harness bootstrap, beyond local terminal coordination. |
| [Entwurf](https://github.com/junghan0611/entwurf) | Rich native harness bridges, mailboxes, ACP and peer dispatch. The reviewed Herdr manifest declares **Linux only**, despite broader macOS claims for other installation surfaces. Some paths use auto-approval. Not the Mac default. |
| [Dagr](https://github.com/aemrebarut/herdr-dagr) | Displays a producer-maintained DAG with attempts, review gates and evidence. Needs the orchestrator/skill to write run data; visualization does not independently dispatch or verify tasks. |
| [Memex](https://github.com/nicosuave/memex) | Search/resume across local transcripts, with opt-in usage tracking. Cost estimates are API-equivalent, not subscription bills. Useful after session history becomes a retrieval problem; transfers remain experimental. |
| [Token Dashboard](https://github.com/Davidcreador/herdr-token-dashboard) | Do not rely on it yet: its README documents OpenCode port 4096 and old message-file storage, while our v2 uses a different service layout. Codex/Claude dollar figures are list-price estimates, not actual subscription charges. Requires a v2 compatibility test. |
| [llmtrim](https://github.com/fkiene/llmtrim-herdr) | Not recommended for this setup. It rewrites outbound requests through local TLS interception and automatically edits proxy/certificate environment settings. Its savings/quality figures are author-reported, not verified on our workloads. |
| [Worktrunk](https://github.com/devashish2203/herdr-worktrunk) | Useful if we adopt Worktrunk's lifecycle hooks/merge workflow; adds a second worktree owner alongside Herdr. Core worktrees suffice initially. |
| [Radar](https://github.com/hhdebb/herdr-radar) | Better grouped agent/sidebar visibility, but startup installs a font and modifies Herdr/Ghostty/kitty config. Native labels, sorting and symbols already meet the initial need. |
| [Collie](https://github.com/AltanS/collie) | Phone/PWA control and notifications, normally via Tailscale with device pairing. Worth revisiting for mobile supervision; not needed for local mixed models. |
| [AgentBox](https://github.com/madarco/agentbox-herdr-plugin) | AgentBox sandbox launcher/UI; requires its separate CLI and setup. Worktrees isolate Git changes, while VMs address a different isolation need. |
| [Zoetrope](https://github.com/furkankly/zoetrope) | Read-only flow graphs from Claude/Codex transcripts. Useful debugging/observability, not a mixed-model dispatcher. Transcript formats can change. |

Recommendation: keep the current native launcher as the baseline; the next
layout/review additions should be **Sessionizer + Reviewr**. For actual automated
worker coordination, select **Swarm** for bounded fan-out or **Projects** for a
persistent coordinator and shared memory. Installing all coordination tools
would add competing ways to launch, track and clean the same work.
The current PR still installs only our local launcher, not these third-party
plugins. A plugin install should pin the reviewed source revision and check any
secondary binary downloads; a pinned manifest alone does not pin its installer.

Reviewed catalog revisions (for reproducibility):

| Repository | Commit |
| --- | --- |
| [andrewchng/herdr-sessionizer](https://github.com/andrewchng/herdr-sessionizer/tree/c3a7c88a5a79f7515471650d2fcbe6cded6b6a44) | `c3a7c88a5a79` |
| [razajamil/herdr-plugin-workspace-manager](https://github.com/razajamil/herdr-plugin-workspace-manager/tree/8302970a088b8dff4aca9a3d9034907d66be80a7) | `8302970a088b` |
| [StructuPath/herdr-swarm](https://github.com/StructuPath/herdr-swarm/tree/d90337f11c1e6bdb2ce4dd68d75a3d22326801d3) | `d90337f11c1e` |
| [junghan0611/entwurf](https://github.com/junghan0611/entwurf/tree/43b4f767bb45cb608ddff5b95d0d8ba4a11d3bf2) | `43b4f767bb45` |
| [aashishd/herdr-agent-messenger](https://github.com/aashishd/herdr-agent-messenger/tree/2120ccec98c37226b98a7a0ca6af6ad506c71a5e) | `2120ccec98c3` |
| [marcvermeeren/chatter](https://github.com/marcvermeeren/chatter/tree/0edc18f4a130a6e013b24f9090b07372c8c41feb) | `0edc18f4a130` |
| [agentwireprotocol/awp](https://github.com/agentwireprotocol/awp/tree/cc6d6ac3dc165ceb15a9cfe3173afa726e6b55c8) | `cc6d6ac3dc16` |
| [aemrebarut/herdr-dagr](https://github.com/aemrebarut/herdr-dagr/tree/52991f9a95a2b8c11518ed66f9530d938c1ba254) | `52991f9a95a2` |
| [Davidcreador/herdr-token-dashboard](https://github.com/Davidcreador/herdr-token-dashboard/tree/fd786877f7a7492ebaa6da0d4d0c50b2e8d536ef) | `fd786877f7a7` |
| [fkiene/llmtrim-herdr](https://github.com/fkiene/llmtrim-herdr/tree/88ed6fbeab1cfc1224bece3744b207659bc1123b) | `88ed6fbeab1c` |
| [nicosuave/memex](https://github.com/nicosuave/memex/tree/649355e4b442de9b63c24a3702f5c765233a84e4) | `649355e4b442` |
| [plannotator/herdr-annotate](https://github.com/plannotator/herdr-annotate/tree/cbba4732229191347ff5128e3da71f64474a6a49) | `cbba47322291` |
| [plannotator/herdr-plannotator](https://github.com/plannotator/herdr-plannotator/tree/e10b969ea1655dbfce25d1464eef6f27c790bb79) | `e10b969ea165` |
| [devashish2203/herdr-worktrunk](https://github.com/devashish2203/herdr-worktrunk/tree/8ceca541de8fb0d6006727e172534e1e2af17224) | `8ceca541de8f` |
| [hhdebb/herdr-radar](https://github.com/hhdebb/herdr-radar/tree/2425fa080b7b72f30c1299481282b23003a2ee61) | `2425fa080b7b` |
| [AltanS/collie](https://github.com/AltanS/collie/tree/b7ccd7574741e7a7aa8599e8273db48498168b1f) | `b7ccd7574741` |
| [madarco/agentbox-herdr-plugin](https://github.com/madarco/agentbox-herdr-plugin/tree/d92b7bb57a9a4c618881d2598f1c4a71decdbc04) | `d92b7bb57a9a` |
| [furkankly/zoetrope](https://github.com/furkankly/zoetrope/tree/b1f31dd26bd4e9e513885e39edb78d0850a5d1fe) | `b1f31dd26bd4` |
| [eliasstravik/herdr-projects](https://github.com/eliasstravik/herdr-projects/tree/4e4548c3c43888e6be1c96906215998f07dc63f0) | `4e4548c3c438` |
| [persiyanov/herdr-reviewr](https://github.com/persiyanov/herdr-reviewr/tree/cd618b48dc1f4d2cc092f3f26827ac72fb44773e) | `cd618b48dc1f` |

## Current model price comparison

Checked 2026-09-29 locally (2026-09-30 UTC). Prices are USD per **million tokens**;
these are interactive Standard-tier rates, not batch or training prices.

| Fireworks model | Input | Cached input | Output | Example: 100K uncached input + 10K output |
| --- | ---: | ---: | ---: | ---: |
| GLM 5.3 Flash | $0.15 | $0.03 | $0.50 | $0.020 |
| DeepSeek V4.1 Flash | $0.30 | $0.006 | $1.20 | $0.042 |
| GLM 5.3 | $1.40 | $0.26 | $4.40 | $0.184 |
| Kimi K3 (US) | $4.50 | $0.45 | $22.50 | $0.675 |

Source: [Fireworks serverless pricing](https://docs.fireworks.ai/serverless/pricing).
US-only GLM/DeepSeek routes and Priority/Fast tiers can cost more. The examples
are arithmetic for the stated token counts, not measured completion costs.
GLM 5.3 Flash is the economical current-generation default candidate on
Fireworks. A cache-dominated workload can favor DeepSeek's cheaper cache reads.
Kimi K3 is substantially more expensive here and should earn its place on a
specific difficult task rather than be the budget worker.

OpenRouter has many providers per model; its
[model catalog](https://openrouter.ai/api/v1/models) headline prices are not a
promise that the cheapest eligible endpoint will be selected. Comparing the
live [GLM 5.3 Flash endpoints](https://openrouter.ai/api/v1/models/z-ai/glm-5.3-flash/endpoints)
and [DeepSeek V4 Flash 0731 endpoints](https://openrouter.ai/api/v1/models/deepseek/deepseek-v4-flash-0731/endpoints):

- GLM 5.3 Flash / OpenInference: $0.02 input, $0.30 output; example $0.0050.
- DeepSeek V4 Flash 0731 / Sail Research FP4: $0.019 input, $0.30 output;
  example $0.0049.
- DeepSeek V4 Flash 0731 / Relace: $0.01 input, $0.64 output; example $0.0074.
- Kimi K3 / InferenceNet: $0.40 input, $9 output; example $0.13, from its
  [endpoint catalog](https://openrouter.ai/api/v1/models/moonshotai/kimi-k3/endpoints).

These are specific advertised routes, some quantized, with different capability
and reliability profiles. Their eligibility under our existing
`data_collection = "deny"` routing preference has not been established by these
public catalogs. Do not drop that preference just to reproduce a headline price.
Compare quality, cache hits, latency and retries on a real task; lowest token
price does not establish lowest cost per accepted change. Nothing here invokes
inference or changes the configured model.

For your team: use the existing OpenAI/Claude subscriptions first, **GLM 5.3
Flash on Fireworks** as the initial API-budget candidate, and **DeepSeek V4 Flash
0731 on OpenRouter** as a comparison worker. Kimi is an optional escalation or
independent evaluation, not automatically the cheapest third worker. This is a
recommendation; the PR has not yet pinned those worker models or verified their
account auth/routing.
