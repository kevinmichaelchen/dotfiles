# scripts/AGENTS.md

## OVERVIEW

Automation scripts for bootstrapping new machines and updating existing
configurations. Scripts are **idempotent** and **non-destructive**.

## FILES

| File           | Purpose                               |
| -------------- | ------------------------------------- |
| `bootstrap.sh` | First-time setup for new machines     |
| `update.sh`    | Pull latest changes and apply configs |
| `cleanup.sh`   | Nix store maintenance and GC          |

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
3. Applies chezmoi configs

Can be run via alias: `dot-update`

## CLEANUP SCRIPT

The `cleanup.sh` script frees disk space by removing old Nix generations and
garbage collecting unreferenced store paths.

**What it cleans:**

| Target                        | Command                                                                  |
| ----------------------------- | ------------------------------------------------------------------------ |
| darwin-system generations     | `sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system` |
| home-manager generations      | `nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager` |
| user profile generations      | `nix-env --delete-generations old`                                       |
| unreferenced store paths      | `nix-collect-garbage -d`                                                 |

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
