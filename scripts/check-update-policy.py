#!/usr/bin/env python3
"""Check update orchestration without pulling, installing, or upgrading anything."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

REPO = Path(__file__).resolve().parent.parent
config = tomllib.loads((REPO / "mise/config.toml").read_text())
assert config["settings"]["locked"] is True
assert config["settings"]["locked_scopes"] == ["global"]
assert "mise-tool-update" not in config["bootstrap"].get("services", {})
assert all(not isinstance(tool, dict) or "auto_update" not in tool
           for tool in config["tools"].values())

with tempfile.TemporaryDirectory(prefix="update policy ") as temporary:
    root = Path(temporary)
    scripts = root / "scripts"
    scripts.mkdir()
    shutil.copy2(REPO / "scripts/update.sh", scripts / "update.sh")
    binaries = root / "bin"
    binaries.mkdir()
    log = root / "calls"
    for name in ("git", "mise"):
        path = binaries / name
        path.write_text('''#!/bin/bash
printf '%s' "${0##*/}" >> "$CALL_LOG"
printf ' <%s>' "$@" >> "$CALL_LOG"
printf '\\n' >> "$CALL_LOG"
if [[ "${0##*/}" == git && "${3:-}" == status && "${DIRTY:-}" == 1 ]]; then
  echo ' M mise/config.toml'
fi
''')
        path.chmod(0o755)
    updater = scripts / "update-tools.sh"
    updater.write_text('#!/bin/bash\necho tool-upgrades >> "$CALL_LOG"\n')
    updater.chmod(0o755)
    env = dict(os.environ, PATH=str(binaries) + os.pathsep + os.environ["PATH"],
               MISE_BIN=str(binaries / "mise"), CALL_LOG=str(log))

    def run(*args, dirty=False):
        log.write_text("")
        result = subprocess.run(["bash", str(scripts / "update.sh"), *args],
                                env=dict(env, DIRTY="1" if dirty else "0"),
                                text=True, capture_output=True)
        return result, log.read_text().splitlines()

    result, calls = run()
    assert result.returncode == 0, result.stderr
    assert any('<pull> <--ff-only>' in call for call in calls), calls
    assert any('<bootstrap> <--yes> <--update>' in call for call in calls), calls
    assert not any('upgrade' in call for call in calls), calls
    result, calls = run('--upgrade')
    assert result.returncode == 0, result.stderr
    assert any('<packages> <upgrade>' in call for call in calls), calls
    assert calls[-1] == 'tool-upgrades', calls
    result, calls = run(dirty=True)
    assert result.returncode != 0 and len(calls) == 1, calls
    assert 'commit or stash' in result.stderr
    for args in [('--unknown',), ('--upgrade', 'extra')]:
        result, calls = run(*args)
        assert result.returncode == 2 and not calls, calls

# Exercise the real resolver offline: a project pin without a lock must work,
# while the same pin in global config must still require a lock entry.
with tempfile.TemporaryDirectory(prefix="locked scope ") as temporary:
    root = Path(temporary)
    project = root / "project"
    project.mkdir()
    tools = f'[tools]\nnode = "{config["tools"]["node"]}"\n'
    (project / "mise.toml").write_text(tools)
    global_config = root / "config.toml"
    settings = '[settings]\nlocked = true\nlocked_scopes = ["global"]\n'
    global_config.write_text(settings)
    env = {key: value for key, value in os.environ.items()
           if not key.startswith("MISE_") or key == "MISE_DATA_DIR"}
    env.update(MISE_GLOBAL_CONFIG_FILE=str(global_config), MISE_OFFLINE="1",
               MISE_TRUSTED_CONFIG_PATHS=temporary, MISE_STATE_DIR=str(root / "state"),
               XDG_STATE_HOME=str(root / "xdg-state"))
    mise = shutil.which("mise")
    assert mise, "Validation requires mise on PATH"
    result = subprocess.run([mise, "-C", str(project), "which", "node"],
                            env=env, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    assert "not in the lockfile" not in result.stderr, result.stderr
    global_config.write_text(settings + tools)
    result = subprocess.run([mise, "-C", temporary, "which", "node"],
                            env=env, capture_output=True, text=True)
    assert result.returncode != 0 and "not in the lockfile" in result.stderr, result.stderr

print('Verified global-only locking, unlocked project resolution, explicit upgrades, '
      'fast-forward pull, dirty-checkout guard, and argument validation')
