#!/usr/bin/env python3
"""Validate Herdr and native integrations in a temporary home; no inference."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import tomllib

REPO = Path(__file__).resolve().parent.parent
HERDR = shutil.which("herdr")
if not HERDR:
    raise SystemExit("Validation requires the pinned Herdr binary on PATH")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


with tempfile.TemporaryDirectory(prefix="herdr-check-", dir="/tmp") as temporary:
    home = Path(temporary)
    env = {k: v for k, v in os.environ.items()
           if not k.startswith(("HERDR_", "XDG_", "CLAUDE_", "CODEX_", "OPENCODE_", "MISE_"))}
    env.update(HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
               XDG_STATE_HOME=str(home / ".state"), XDG_CACHE_HOME=str(home / ".cache"),
               XDG_DATA_HOME=str(home / ".data"), HERDR_SOCKET_PATH=str(home / "api.sock"),
               SHELL="/bin/sh")
    config = home / ".config/herdr"
    shutil.copytree(REPO / "dotfiles/.config/herdr", config)
    env["HERDR_CONFIG_PATH"] = str(config / "config.toml")
    # Disable remote manifest fetch only in the isolated, offline fixture.
    fixture = (config / "config.toml").read_text().replace("manifest_check = true", "manifest_check = false")
    fixture = fixture.replace('default_shell = "/bin/zsh"', 'default_shell = "/bin/sh"')
    (config / "config.toml").write_text(fixture)
    agents = home / "bin"
    agents.mkdir()
    env["PATH"] = f"{agents}:{env['PATH']}"
    for name in ("codex", "claude", "opencode"):
        stub = agents / name
        stub.write_text('#!/bin/sh\npython3 -c '\
                        "'import json,os,sys;from pathlib import Path;"
                        "Path(os.environ[\"HOME\"],sys.argv[1]+\".json\").write_text("
                        "json.dumps({\"args\":sys.argv[2:],\"cwd\":os.getcwd(),"
                        "\"config\":os.environ.get(\"OPENCODE_CONFIG\")}))' "
                        f'{name} "$@"\nexec sleep 30\n')
        stub.chmod(0o755)

    def run(*args):
        result = subprocess.run([HERDR, *args], env=env, cwd=home, text=True,
                                capture_output=True, timeout=15)
        require(result.returncode == 0, f"{args}: {result.stdout}\n{result.stderr}")
        return result.stdout

    # Validate the actual repository config before modifying the offline fixture.
    raw_env = dict(env, HERDR_CONFIG_PATH=str(REPO / "dotfiles/.config/herdr/config.toml"))
    subprocess.run([HERDR, "config", "check"], env=raw_env, check=True, timeout=15)
    run("plugin", "link", str(config / "plugins/agents"), "--enabled")
    # Seed local preferences, then exercise native installers twice.
    (home / ".codex").mkdir()
    (home / ".claude").mkdir()
    (home / ".config/opencode").mkdir()
    (home / ".codex/config.toml").write_text('sandbox_mode = "workspace-write"\n')
    (home / ".claude/settings.json").write_text('{"env":{"LOCAL":"keep"}}')
    (home / ".config/opencode/cli.json").write_text('{"theme":"local"}')
    for _ in range(2):
        for name in ("codex", "claude", "opencode"):
            run("integration", "install", name)
    require(tomllib.loads((home / ".codex/config.toml").read_text())["sandbox_mode"] == "workspace-write",
            "Codex preference lost")
    require(json.loads((home / ".claude/settings.json").read_text())["env"]["LOCAL"] == "keep",
            "Claude preference lost")
    require(json.loads((home / ".config/opencode/cli.json").read_text())["theme"] == "local",
            "OpenCode preference lost")
    before = {p: p.read_bytes() for p in home.rglob("*") if p.is_file() and p.suffix in (".json", ".toml", ".js", ".sh")}
    for name in ("codex", "claude", "opencode"):
        run("integration", "install", name)
    require(all(p.read_bytes() == content for p, content in before.items()), "Integration reinstall changed configuration")
    status = run("integration", "status")
    require(all(f"{name}: current" in status for name in ("codex", "claude", "opencode")), "Integration not current")

    with (home / "server-output.log").open("w") as log:
        server = subprocess.Popen([HERDR, "server"], env=env, cwd=home, stdout=log, stderr=log)
        try:
            deadline = time.monotonic() + 10
            while not (home / "api.sock").exists() and time.monotonic() < deadline:
                require(server.poll() is None, "Fixture server failed to start")
                time.sleep(0.1)
            workspace = json.loads(run("workspace", "create", "--cwd", str(home), "--label", "fixture"))["result"]["workspace"]
            workspace_id = workspace["workspace_id"] if isinstance(workspace, dict) else workspace
            for name in ("codex", "claude", "opencode"):
                commands = tomllib.loads((config / "config.toml").read_text())["keys"]["command"]
                command = next(c["command"] for c in commands if f"--entrypoint {name} " in c["command"])
                launch_env = dict(env, HERDR_BIN_PATH=HERDR,
                                  HERDR_ACTIVE_WORKSPACE_ID=str(workspace_id),
                                  HERDR_ACTIVE_PANE_CWD=str(home))
                subprocess.run(["/bin/sh", "-c", command], env=launch_env, cwd=home,
                               check=True, capture_output=True, timeout=15)
                deadline = time.monotonic() + 5
                while not (home / f"{name}.json").exists() and time.monotonic() < deadline:
                    time.sleep(0.1)
                data = json.loads((home / f"{name}.json").read_text())
                require(Path(data["cwd"]).resolve() == home.resolve(), f"{name} launched in wrong checkout")
                if name == "codex":
                    require(data["args"] == ["--profile", "dotfiles"], "Codex layer missing")
                elif name == "claude":
                    require(data["args"] == ["--mcp-config", str(home / ".config/claude/mcp.json")], "Claude layer missing")
                else:
                    require(data["config"] == str(home / ".config/opencode/dotfiles.json"), "OpenCode layer missing")
            print("Verified config, plugin tab launches/CWD, config layers, and native integration preservation/idempotence")
        finally:
            if server.poll() is None:
                subprocess.run([HERDR, "server", "stop"], env=env, capture_output=True, timeout=10)
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()
