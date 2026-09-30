#!/usr/bin/env python3
"""Check Mise repository convergence against a local upstream, without network."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile

MISE = shutil.which("mise")
if not MISE:
    raise SystemExit("Validation requires mise on PATH")

with tempfile.TemporaryDirectory(prefix="mise-repos-check-") as temporary:
    home = Path(temporary)
    upstream = home / "upstream"
    target = home / "target"
    config = home / "config.toml"
    env = {key: value for key, value in os.environ.items()
           if not key.startswith(("MISE_", "XDG_"))}
    env.update({
        "HOME": temporary,
        "MISE_GLOBAL_CONFIG_FILE": str(config),
        "MISE_STATE_DIR": str(home / "state"),
        "MISE_TRUSTED_CONFIG_PATHS": temporary,
        "MISE_OFFLINE": "1",
        "GIT_AUTHOR_NAME": "Fixture",
        "GIT_AUTHOR_EMAIL": "fixture@example.invalid",
        "GIT_COMMITTER_NAME": "Fixture",
        "GIT_COMMITTER_EMAIL": "fixture@example.invalid",
    })
    for key in ("XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_STATE_HOME"):
        env[key] = str(home / key.lower())

    def run(*args, input=None, success=True):
        result = subprocess.run(args, cwd=home, env=env, text=True,
                                capture_output=True, input=input)
        if (result.returncode == 0) != success:
            raise RuntimeError(result.stdout + result.stderr)
        return result

    run("git", "init", "-b", "main", str(upstream))
    (upstream / "file").write_text("first")
    run("git", "-C", str(upstream), "add", "file")
    run("git", "-C", str(upstream), "commit", "-F", "-", input="Fixture initial commit\n")
    config.write_text(f'[bootstrap.repos]\n"{target}" = {{url="{upstream}", ref="main"}}\n')
    run(MISE, "bootstrap", "repos", "apply", "--yes")
    (upstream / "file").write_text("second")
    run("git", "-C", str(upstream), "add", "file")
    run("git", "-C", str(upstream), "commit", "-F", "-", input="Fixture upstream update\n")
    run(MISE, "bootstrap", "repos", "apply", "--yes")
    if (target / "file").read_text() != "second":
        raise RuntimeError("Apply did not follow the upstream branch")
    (target / "file").write_text("local change")
    result = run(MISE, "bootstrap", "repos", "apply", "--yes", success=False)
    if (target / "file").read_text() != "local change" or "local changes" not in result.stderr:
        raise RuntimeError("Dirty checkout was not protected")
    print("Verified repository cloning, upstream branch updates, and dirty-checkout protection")
