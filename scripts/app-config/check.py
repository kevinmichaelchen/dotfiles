#!/usr/bin/env python3
"""Verify app-config preservation, first-run seeding, and safe failures."""

import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import tomllib

SCRIPT = Path(__file__).with_name("apply.py")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


with tempfile.TemporaryDirectory(prefix="app-config-check-") as temporary:
    home = Path(temporary)
    env = dict(os.environ, HOME=str(home), PYTHONDONTWRITEBYTECODE="1")

    def run(*args, success=True):
        result = subprocess.run([sys.executable, str(SCRIPT), *args], env=env,
                                text=True, capture_output=True)
        require((result.returncode == 0) == success, result.stdout + result.stderr)
        return result

    def seed(relative, value):
        path = home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value)
        return path

    def snapshot():
        return {str(p.relative_to(home)): (p.read_bytes(), p.stat().st_mtime_ns)
                for p in home.rglob("*") if p.is_file()}

    run("--dry-run")
    require(not list(home.iterdir()), "Fresh dry run created files")
    run()
    require((home / ".config/opencode/package.json").is_file(), "Missing first-run seed")
    require((home / ".claude/skills").resolve() == (home / ".agents/skills").resolve(), "Wrong skills link")
    seeded = snapshot()
    run()
    require(snapshot() == seeded, "Repeated first-run apply changed files")

    package = seed(".config/opencode/package.json", '{"dependencies":{"local":"1"}}\n')
    seed(".claude.json", json.dumps({"preferences": {"theme": "dark"}, "mcpServers": {
        "local": {"command": "keep"}, "executor-cloud": {"token": "private-fixture"}}}))
    seed(".codex/config.toml", '''# Keep my local preferences
model = "old"
service_tier = "old"
sandbox_mode = "workspace-write"
[projects."/example"]
trust_level = "trusted"
[mcp_servers.local]
command = "keep"
[mcp_servers.executor-cloud]
url = "old"
''')
    seed(".config/crush/crush.json", json.dumps({"theme": "local", "mcp": {"local": {"command": "keep"}}}))
    seed(".config/opencode/opencode.json", json.dumps({"model": "local/model", "plugin": ["local-plugin"],
        "provider": {"local": {"options": {"key": "private-fixture"}}}, "mcp": {"local": {"command": "keep"}}}))
    before = snapshot()
    preview = run("--dry-run")
    require("private-fixture" not in preview.stdout + preview.stderr, "Preview exposed contents")
    require(snapshot() == before, "Dry run modified existing files")
    run()
    data = json.loads((home / ".claude.json").read_text())
    require(data["preferences"]["theme"] == "dark" and "local" in data["mcpServers"], "Claude local settings lost")
    require("executor-cloud" not in data["mcpServers"], "Legacy MCP remained")
    data = tomllib.loads((home / ".codex/config.toml").read_text())
    require(data["sandbox_mode"] == "workspace-write" and data["projects"]["/example"]["trust_level"] == "trusted", "Codex local settings lost")
    require(data["model"] == "gpt-6.1-sol" and "service_tier" not in data, "Codex defaults did not converge")
    require("local" in data["mcp_servers"] and "executor-cloud" not in data["mcp_servers"], "Codex MCP merge failed")
    data = json.loads((home / ".config/opencode/opencode.json").read_text())
    require(data["model"] == "local/model" and data["plugin"] == ["local-plugin"], "OpenCode choices lost")
    require(data["provider"]["local"]["options"]["key"] == "private-fixture", "Unmanaged provider changed")
    data = json.loads((home / ".config/crush/crush.json").read_text())
    require(data["theme"] == "local" and "local" in data["mcp"], "Crush local settings lost")
    require(package.read_text() == '{"dependencies":{"local":"1"}}\n', "Existing package seed overwritten")
    for relative in (".claude.json", ".codex/config.toml", ".config/crush/crush.json", ".config/opencode/opencode.json"):
        require(stat.S_IMODE((home / relative).stat().st_mode) == 0o600, "Config permissions are not private")
    applied = snapshot()
    run()
    require(snapshot() == applied, "Repeated apply changed contents or mtimes")

    # A later malformed config must stop every write, including earlier targets.
    seed(".claude.json", '{"preferences": "keep"}\n')
    seed(".config/opencode/opencode.json", '{malformed')
    before = snapshot()
    run(success=False)
    require(snapshot() == before, "Malformed config allowed partial writes")
    seed(".config/opencode/opencode.json", '{}\n')
    (home / ".claude/skills").unlink()
    (home / ".claude/skills").mkdir()
    seed(".claude/skills/local.txt", "keep")
    before = snapshot()
    run(success=False)
    require(snapshot() == before, "Conflicting skill directory allowed writes")
    shutil.rmtree(home / ".claude/skills")
    config = home / ".codex/config.toml"
    config.unlink()
    config.symlink_to(home / "external.toml")
    seed("external.toml", 'model = "keep"\n')
    before = snapshot()
    run(success=False)
    require(snapshot() == before, "Config symlink was overwritten")
    # Run the real bootstrap launcher with fixture skill commands, without downloads.
    config.unlink()
    seed(".codex/config.toml", 'sandbox_mode = "workspace-write"\n')
    fixture = home / "fixture/scripts"
    shutil.copytree(SCRIPT.parent, fixture / "app-config")
    shutil.copy2(SCRIPT.parent.parent / "bootstrap-workstation.sh", fixture / "bootstrap-workstation.sh")
    skills = fixture / "agent-skills"
    skills.mkdir()
    for name, body in (
        ("install-security-tools.sh", 'test -f "$HOME/.codex/config.toml"\necho security >> "$HOME/order"'),
        ("sync.sh", 'test "$1" = --prune\necho sync >> "$HOME/order"'),
    ):
        stub = skills / name
        stub.write_text("#!/usr/bin/env bash\nset -eu\n" + body + "\n")
        stub.chmod(0o700)
    result = subprocess.run(["bash", str(fixture / "bootstrap-workstation.sh")], env=env,
                            capture_output=True, text=True)
    require(result.returncode == 0, result.stdout + result.stderr)
    require((home / "order").read_text() == "security\nsync\n", "Bootstrap skill order changed")
    (home / "order").unlink()
    seed(".claude.json", "{malformed")
    result = subprocess.run(["bash", str(fixture / "bootstrap-workstation.sh")], env=env,
                            capture_output=True, text=True)
    require(result.returncode != 0 and not (home / "order").exists(), "Bootstrap continued after config failure")
    print("Verified app settings, local preferences, seed preservation, private permissions, "
          "dry run, repeatability, malformed inputs, link conflicts, and bootstrap ordering")
