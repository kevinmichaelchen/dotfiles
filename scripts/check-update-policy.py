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

print('Verified locked installs, explicit upgrades, fast-forward pull, dirty-checkout guard, and argument validation')
