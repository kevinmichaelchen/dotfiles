# scripts/AGENTS.md

## OVERVIEW

Automation scripts for bootstrapping new machines and updating existing
configurations. Scripts are **idempotent** and **non-destructive**.

## FILES

| File           | Purpose                               |
| -------------- | ------------------------------------- |
| `bootstrap.sh` | First-time setup for new machines     |
| `executor/common.sh` | Shared constants and helpers for executor automation |
| `executor/launchd-daemon.sh` | Run the shared Executor daemon under launchd |
| `executor/restart.sh` | Stop and restart the Executor daemon |
| `executor/status.sh` | Print executor runtime + source inventory |
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
- `launchd-daemon.sh`: launchd-friendly PATH/bootstrap that execs the Executor daemon in foreground
- `add-paper-mcp-source.sh`: register the local Paper Desktop MCP endpoint with the active Executor scope
- `ensure-readonly-search-policies.sh`: exact machine-wide approvals for read-only Perplexity and Parallel search
- `restart.sh`: stop and restart the daemon
- `status.sh`: print runtime + source inventory

Executor owns source state, secrets, OAuth Connections, policies, plugins, and
future workspace/nested-scope data. Do not add a steady-state source reconciler
back into dotfiles; manage sources through Executor UI/CLI. Machine-wide policy
seeding should stay exact and limited to tools that are truly read-only across
projects.

Paper Desktop MCP is intentionally a manual helper, not a Chezmoi apply hook:
the endpoint depends on the local Paper app being open, and its tools can write
to the currently open design file.

Canonical architecture and runtime notes live in [docs/executor.md](../docs/executor.md).

## EXECUTOR RESTART SCRIPT

The `executor/restart.sh` script:

1. Stops the Executor daemon via `executor daemon stop`
2. Restarts it through launchd if `com.kchen.executor-daemon` is loaded

Runtime state lives under `~/.executor`, so restart preserves the inventory. Use
this only when the runtime process itself is wedged. If the LaunchAgent is not
loaded, run `chezmoi apply` from the real `~/dotfiles` checkout first.

Can be run directly: `./scripts/executor/restart.sh`

## EXECUTOR LAUNCHD-DAEMON SCRIPT

The `executor/launchd-daemon.sh` script:

1. Recreates the minimal PATH launchd needs for Mise-managed CLIs
2. Activates Mise shims
3. Execs `executor daemon run --foreground --port 8788 --hostname 127.0.0.1 --scope ~/.executor`

It is the entrypoint used by the macOS LaunchAgent that keeps Executor available
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
