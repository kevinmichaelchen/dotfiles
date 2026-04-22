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
| `executor/restart.sh` | Stop the executor runtime and re-run sync |
| `executor/status.sh` | Print executor runtime + source inventory |
| `executor/sync.sh` | Reconcile MCP + OpenAPI sources into local executor |
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

Executor automation is co-located under `scripts/executor/`:

- `common.sh`: shared paths, constants, and helper functions
- `sync.sh`: desired source inventory plus idempotent reconciliation
- `launchd-sync.sh`: launchd-friendly PATH/env bootstrap that delegates to `sync.sh`
- `restart.sh`: stop the runtime and re-run `sync.sh`
- `status.sh`: print runtime + source inventory

Every managed source is a hosted remote HTTP endpoint (MCP or OpenAPI) — no
stdio bridges, no supergateway. Auth is usually header-based and env-driven,
but Atlassian can also run from a persisted Executor OAuth connection; see
[docs/executor.md](../docs/executor.md) for the env contract.

The `sync.sh` script:

1. Ensures the runtime is serving `$EXECUTOR_SCOPE_DIR` (`~/.executor`). Launches `executor daemon run --hostname 127.0.0.1 --port 8788 --scope ~/.executor` via a detached tmux wrapper if not.
2. Reconciles each desired source against `GET /api/scopes/:id/{mcp,openapi}/sources/:namespace` — PATCHes a drift, POSTs a new source, or DELETE+POSTs when an immutable field changed.
3. Stores auth material in Executor's own secret store and references secrets from source configs instead of writing raw tokens into `executor.jsonc`.
4. Triggers a tool refresh on each MCP source after add/update.
5. Migrates a legacy object-shaped `executor.jsonc` to the modern array-based format before any add path runs.
6. Reloads the credential fragments in `~/.config/shell/*.sh` so manual runs do not reuse stale secret exports.
7. Skips sources whose credentials are not in the environment, except for
   sources that can run from a stored Executor OAuth connection (currently
   Atlassian via `atlassian_oauth`).

Executor persists sources in SQLite inside the scope directory, so on a warm
system `sync.sh` is close to a no-op — unchanged sources return an
"already up to date" line.

Can be run directly: `./scripts/executor/sync.sh`

Canonical architecture and runtime notes live in [docs/executor.md](../docs/executor.md).

## EXECUTOR RESTART SCRIPT

The `executor/restart.sh` script:

1. Stops the Executor daemon via `executor daemon stop`
2. Kills any remaining process on `$EXECUTOR_WEB_PORT`
3. Execs `./scripts/executor/sync.sh`

Source definitions live in SQLite, so restart preserves the inventory. Use this
only when the runtime process itself is wedged.

Can be run directly: `./scripts/executor/restart.sh`

## EXECUTOR LAUNCHD-SYNC SCRIPT

The `executor/launchd-sync.sh` script:

1. Recreates the minimal PATH launchd needs for Mise-managed CLIs
2. Sources the shell fragments that export API credentials (Perplexity, Parallel, Firecrawl, GitHub, Atlassian)
3. Execs `./scripts/executor/sync.sh`

It is the entrypoint used by the macOS LaunchAgent that keeps executor available
after login.

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
