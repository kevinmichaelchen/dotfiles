#!/usr/bin/env python3
"""Exercise dotfile convergence in a temporary home, without tools or hooks."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

REPO = Path(__file__).resolve().parent.parent
MISE = shutil.which("mise")
if not MISE:
    raise SystemExit("Validation requires mise on PATH")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


with tempfile.TemporaryDirectory(prefix="dotfiles-check-") as temporary:
    home = Path(temporary)
    checkout = home / "dotfiles"
    for directory in ("mise", "dotfiles"):
        shutil.copytree(REPO / directory, checkout / directory)
    config = checkout / "mise/config.toml"
    entries = tomllib.loads(config.read_text())["dotfiles"]
    env = os.environ.copy()
    # Keep configuration, caches, state, and trust records inside the fixture.
    for key in list(env):
        if key.startswith(("MISE_", "XDG_", "CHEZMOI_")):
            del env[key]
    env.update({
        "HOME": str(home),
        "XDG_CONFIG_HOME": str(home / ".config"),
        "XDG_CACHE_HOME": str(home / ".cache"),
        "XDG_DATA_HOME": str(home / ".local/share"),
        "XDG_STATE_HOME": str(home / ".local/state"),
        "MISE_GLOBAL_CONFIG_FILE": str(config),
        "MISE_TRUSTED_CONFIG_PATHS": str(home),
        "MISE_OFFLINE": "1",
    })

    def run(*args, success=True):
        result = subprocess.run(args, cwd=home, env=env, text=True, capture_output=True)
        require((result.returncode == 0) == success,
                f"Unexpected result from {args}:\n{result.stdout}\n{result.stderr}")
        return result

    def expand(path):
        require(path.startswith("~/"), f"Expected home-relative path: {path}")
        return home / path[2:]

    # Seed real files as an existing Chezmoi workstation would have them.
    for target, entry in entries.items():
        source = expand(entry["source"])
        require(source.is_file(), f"Missing source: {source}")
        destination = expand(target)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
    neighbor = home / ".config/opencode/runtime-local.json"
    neighbor.write_text('{"keep": true}\n')
    # A locally changed real file must require explicit replacement.
    expand("~/.zshrc").write_text("# machine-local change\n")
    conflict = run(MISE, "dotfiles", "apply", success=False)
    require("--force" in conflict.stderr, "Expected an explicit replacement conflict")
    run(MISE, "dotfiles", "apply", "--force", "--dry-run")
    require(not expand("~/.zshrc").is_symlink(), "Dry run changed a target")
    run(MISE, "dotfiles", "apply", "--force", "--yes")
    for target, entry in entries.items():
        destination = expand(target)
        require(destination.is_symlink(), f"Target is not linked: {target}")
        require(destination.resolve() == expand(entry["source"]).resolve(),
                f"Wrong source for {target}")

    # Load through the installed global-config link after initial bootstrap.
    env["MISE_GLOBAL_CONFIG_FILE"] = str(home / ".config/mise/config.toml")
    run(MISE, "dotfiles", "apply", "--yes")
    run(MISE, "dotfiles", "status")
    require(neighbor.read_text() == '{"keep": true}\n', "Unmanaged neighbor changed")
    require((checkout / "mise/mise.lock").read_bytes() == (REPO / "mise/mise.lock").read_bytes(),
            "Validation changed lockfile contents")

    # Repository declarations parse and preview without network or checkout writes.
    run(MISE, "bootstrap", "repos", "apply", "--dry-run")
    require(not (home / ".tmux/plugins/tpm").exists(), "Repo dry run created a checkout")
    run(MISE, "bootstrap", "--only", "task", "--dry-run")
    print(f"Verified {len(entries)} links: migration conflicts, dry run, repeated apply, "
          "installed-config loading, unmanaged files, lockfile, and repository preview")
