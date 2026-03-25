# scripts/AGENTS.md

## OVERVIEW

Automation scripts for bootstrapping new machines and updating existing
configurations. Scripts are **idempotent** and **non-destructive**.

## FILES

| File           | Purpose                               |
| -------------- | ------------------------------------- |
| `bootstrap.sh` | First-time setup for new machines     |
| `executor/common.sh` | Shared constants and helpers for executor automation |
| `executor/launchd-sync.sh` | Load shell env and run executor sync under launchd |
| `executor/auth-atlassian.sh` | Kick off Atlassian Rovo MCP OAuth for Executor |
| `executor/restart.sh` | Kill all executor bridges and re-sync from scratch |
| `executor/sync.sh` | Sync MCP sources into local executor |
| `update.sh`       | Pull latest changes and apply configs |
| `update-tools.sh` | Upgrade Mise tools and Claude Code     |
| `cleanup.sh`      | Nix store maintenance and GC            |

## BOOTSTRAP SEQUENCE

The `bootstrap.sh` script prepares a new machine:

```
1. Clone repo (if ~/dotfiles missing)
2. Check Nix installed (exit with instructions if not)
3. Detect OS (darwin vs linux)
4. Print next commands (doesn't auto-execute dangerous operations)
```

**Full bootstrap flow (manual steps included):**

```bash
# 1. Install Nix (Determinate installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh

# 2. Run bootstrap
./scripts/bootstrap.sh

# 3. Apply nix-darwin (macOS) — printed by bootstrap
sudo nix run nix-darwin -- switch --flake ~/dotfiles/nix-darwin#default

# 4. Initialize chezmoi — printed by bootstrap
chezmoi init --source ~/dotfiles/chezmoi --apply

# 5. Install mise tools
mise install
```

## CONVENTIONS

### Idempotency

Scripts are safe to run multiple times:

```bash
# Good: check before acting
if [ ! -d "$HOME/dotfiles" ]; then
    git clone ...
fi

# Bad: always clone (fails if exists)
git clone ...
```

### Non-Destructive

Scripts **prepare and inform**, they don't auto-execute risky operations:

```bash
# Good: print command for user to run
echo "Run: darwin-rebuild switch --flake ..."

# Bad: auto-run system-changing commands
darwin-rebuild switch --flake ...
```

### OS Detection

```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS-specific
else
    # Linux/other
fi
```

### Color Output

Use defined color variables for consistency:

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

echo -e "${GREEN}✓${NC} Success message"
echo -e "${RED}✗${NC} Error message"
echo -e "${YELLOW}⚠${NC} Warning message"
```

## ANTI-PATTERNS

| Don't                        | Why                           | Do Instead                   |
| ---------------------------- | ----------------------------- | ---------------------------- |
| Auto-run darwin-rebuild      | Dangerous without review      | Print command for user       |
| Assume macOS                 | Repo supports Linux too       | Check `$OSTYPE`              |
| Skip prerequisite checks     | Confusing errors later        | Validate Nix installed first |
| Use `set -e` without thought | Can hide useful error context | Handle errors explicitly     |
| Hardcode paths               | Breaks for different users    | Use `$HOME`, `$USER`         |

## ADDING A NEW SCRIPT

1. **Create executable file:**

   ```bash
   touch scripts/newscript.sh
   chmod +x scripts/newscript.sh
   ```

2. **Add shebang and structure:**

   ```bash
   #!/usr/bin/env bash
   # Description of what this script does

   # Colors
   RED='\033[0;31m'
   GREEN='\033[0;32m'
   NC='\033[0m'

   # Check prerequisites
   if ! command -v required-tool &> /dev/null; then
       echo -e "${RED}✗${NC} required-tool not found"
       exit 1
   fi

   # Main logic
   echo -e "${GREEN}✓${NC} Doing the thing..."
   ```

3. **Document in this file** if it's a core script.

## UPDATE SCRIPT

The `update.sh` script:

1. Pulls latest git changes
2. Applies nix-darwin (macOS) or home-manager (Linux)
3. Applies chezmoi configs from `~/dotfiles/chezmoi`
4. Calls `./scripts/update-tools.sh` for CLI tool upgrades

Can be run via alias: `dot-update`

## UPDATE-TOOLS SCRIPT

The `update-tools.sh` script:

1. Runs `mise upgrade` to update all Mise-managed tools
2. Runs `mise prune --yes` to remove unused tool versions
3. Runs `claude update` if Claude Code is installed
4. Verifies final state with `mise outdated` and `claude --version`

If `mise upgrade` fails on `github:cli/cli` attestation verification, it retries that install once with `MISE_GITHUB_ATTESTATIONS=false` and reruns `mise upgrade`.

Can be run directly: `./scripts/update-tools.sh`

## EXECUTOR SCRIPTS

Executor automation is now co-located under `scripts/executor/`:

- `common.sh`: shared paths, constants, and helper functions
- `sync.sh`: desired source inventory plus idempotent reconciliation
- `launchd-sync.sh`: launchd-friendly PATH/env bootstrap that delegates to `sync.sh`
- `auth-atlassian.sh`: one-time or refresh auth bootstrap for the Atlassian source
- `restart.sh`: hard reset path that tears down bridges and re-runs `sync.sh`

The `sync.sh` script:

1. Normalizes the Executor workspace root to `$HOME` (or `$EXECUTOR_WORKSPACE_ROOT`) before touching the daemon
2. Ensures the local `executor` daemon is running
3. Starts local helper services for stdio-backed MCP sources and curated OpenAPI specs
4. Adds or reconciles executor sources in the active workspace, including the local `executor-control-plane` OpenAPI source plus focused external OpenAPI sources like `perplexity-search` and `parallel-search`, plus the Atlassian Rovo MCP remote source
5. Removes retired or conflicting executor-managed sources before re-registering the current inventory
6. Skips repo-scoped sources like `nx-mcp` unless the required workspace path is provided

Executor `v1.2.x` lets the script take advantage of the daemon's own `/v1/openapi.json` route while leaving actor-scoped auth material inside Executor for sources that need it. Current managed source set includes Executor Control Plane, DeepWiki, grep, GitHub, Exa, Effect docs, Firecrawl, Atlassian, Perplexity Search, and Parallel Search. Atlassian uses a remote MCP endpoint with persistent OAuth stored by Executor after a one-time browser flow.

Can be run directly: `./scripts/executor/sync.sh`

## EXECUTOR AUTH-ATLASSIAN SCRIPT

The `executor/auth-atlassian.sh` script:

1. Runs `./scripts/executor/sync.sh` to ensure Executor and the source inventory exist
2. Reconnects the managed `atlassian` MCP source against `https://mcp.atlassian.com/v1/mcp`
3. Opens the Atlassian OAuth authorization URL in the browser when consent is required
4. Leaves the resulting source and auth material inside Executor so later launchd syncs can reconnect it automatically

Use this once per machine or whenever Atlassian auth needs to be refreshed.

Canonical architecture and runtime notes live in [docs/executor.md](../docs/executor.md).

## EXECUTOR RESTART SCRIPT

The `executor/restart.sh` script does a full teardown and re-sync:

1. Stops the local `executor` daemon
2. Kills all `executor-mcp-*` tmux sessions
3. Kills orphaned processes on known bridge ports (8814, 8817, 8820, 8821, 8822)
4. Cleans up stale PID files, command scripts, and logs
5. Runs `./scripts/executor/sync.sh` to bring everything back up

Use this when bridges are in a broken state or you need a clean restart.
For routine reconciliation that skips already-healthy bridges, use `sync.sh` directly.

Can be run directly: `./scripts/executor/restart.sh`

## EXECUTOR LAUNCHD-SYNC SCRIPT

The `executor/launchd-sync.sh` script:

1. Recreates the minimal PATH launchd needs for Mise-managed CLIs
2. Sources the shell fragments that export API credentials for the remaining executor-managed sources, including `jira.sh`
3. Runs `./scripts/executor/sync.sh`, which pins Executor's workspace root before starting the daemon

It is the entrypoint used by the macOS LaunchAgent that keeps executor available after login.

## CLEANUP SCRIPT

The `cleanup.sh` script frees disk space by removing old Nix generations and
garbage collecting unreferenced store paths.

**What it cleans:**

| Target                    | Command                                                                               |
| ------------------------- | ------------------------------------------------------------------------------------- |
| darwin-system generations | `sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system`        |
| home-manager generations  | `nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager` |
| user profile generations  | `nix-env --delete-generations old`                                                    |
| unreferenced store paths  | `nix-collect-garbage -d`                                                              |

**When to run:**

- When disk space is low (check with `du -sh /nix/store`)
- After many `darwin-rebuild switch` cycles
- Periodically (e.g., monthly)

**Note:** This deletes all generations except current. You lose the ability to
rollback to previous configurations. If you want to keep recent generations:

```bash
# Keep last 3 generations instead of just current
sudo nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system
```

## DEBUGGING

```bash
# Run with debug output
bash -x scripts/bootstrap.sh

# Check what OS is detected
echo $OSTYPE
```
