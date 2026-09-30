#!/usr/bin/env python3
"""Validate native config files and CLI layer selection without starting sessions."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import tomllib

REPO = Path(__file__).resolve().parent.parent
SOURCE = REPO / "dotfiles"
AGENTS = SOURCE / ".config/shell/agents.sh"
for path in SOURCE.rglob("*.json"):
    if path.name != "dprint.jsonc":
        json.loads(path.read_text())
profile = SOURCE / ".codex/dotfiles.config.toml"
tomllib.loads(profile.read_text())


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


with tempfile.TemporaryDirectory(prefix="native layers ") as temporary:
    home = Path(temporary)
    binaries = home / "bin"
    binaries.mkdir()
    for app in ("codex", "claude"):
        path = binaries / app
        path.write_text(f"#!{sys.executable}\nimport json,sys\nprint(json.dumps(sys.argv[1:]))\n")
        path.chmod(0o700)
    env = {key: value for key, value in os.environ.items()
           if key not in ("BASH_ENV", "ENV", "OPENCODE_CONFIG", "CODEX_HOME")}
    env.update(HOME=temporary, PATH=str(binaries) + os.pathsep + env["PATH"], AGENT_SHELL=str(AGENTS))

    def invoke(shell, app, *args, custom_env=None):
        result = subprocess.run([shell, "-c", '. "$AGENT_SHELL"; ' + app + ' "$@"', "fixture", *args],
                                cwd=home, env=custom_env or env, text=True, capture_output=True)
        require(result.returncode == 0, result.stderr)
        return json.loads(result.stdout)

    for shell in ("bash", "zsh", "sh"):
        require(invoke(shell, "codex", "exec", "a prompt with spaces") ==
                ["--profile", "dotfiles", "exec", "a prompt with spaces"], "Codex default profile missing")
        require(invoke(shell, "codex", "--profile=local", "exec", "prompt") ==
                ["--profile=local", "exec", "prompt"], "Explicit Codex profile overwritten")
        require(invoke(shell, "codex", "-p", "local", "exec", "prompt") ==
                ["-p", "local", "exec", "prompt"], "Short Codex profile overwritten")
        require(invoke(shell, "claude", "--print", "a prompt with spaces") ==
                ["--print", "a prompt with spaces", "--mcp-config", str(home / ".config/claude/mcp.json")],
                "Claude prompt or MCP layer changed")
        require(invoke(shell, "claude", "mcp", "list") == ["mcp", "list"], "Claude management command changed")
        require(invoke(shell, "claude", "--mcp-config", "local.json") ==
                ["--mcp-config", "local.json"], "Explicit Claude MCP config overwritten")
        require(invoke(shell, "claude", "--", "literal prompt") ==
                ["--", "literal prompt"], "Claude end-of-options marker changed")
        result = subprocess.run([shell, "-c", '. "$AGENT_SHELL"; printf "%s" "$OPENCODE_CONFIG"'],
                                env=env, text=True, capture_output=True, check=True)
        require(result.stdout == str(home / ".config/opencode/dotfiles.json"), "OpenCode config layer missing")
        result = subprocess.run([shell, "-c", '. "$AGENT_SHELL"; printf "%s" "$OPENCODE_CONFIG"'],
                                env=dict(env, OPENCODE_CONFIG="custom.json"), text=True, capture_output=True, check=True)
        require(result.stdout == "custom.json", "Explicit OpenCode config layer overwritten")

    # Exercise real Codex profile loading without starting MCP servers or sessions.
    codex = shutil.which("codex")
    require(codex is not None, "Validation requires Codex on PATH")
    codex_home = home / ".codex"
    codex_home.mkdir()
    shutil.copy2(profile, codex_home / "dotfiles.config.toml")
    local = codex_home / "config.toml"
    local.write_text('sandbox_mode="workspace-write"\n[mcp_servers.local]\ncommand="echo"\n')
    before = local.read_bytes()
    result = subprocess.run([codex, "--profile", "dotfiles", "mcp", "list", "--json"], cwd=home,
                            env=dict(env, CODEX_HOME=str(codex_home)), text=True, capture_output=True, timeout=30)
    require(result.returncode == 0, result.stderr)
    names = {entry["name"] for entry in json.loads(result.stdout)}
    require({"local", "executor", "executor-desktop"} <= names, "Codex did not merge profile and local config")
    require(local.read_bytes() == before, "Codex user config was rewritten")

    # Crush's native DSL runs in-memory; mock its builtin to inspect declarations.
    config = home / ".config/crush"
    config.mkdir(parents=True)
    (config / "crushrc.local").write_text('mcp add local --type stdio --command echo\n')
    result = subprocess.run(["bash", "-c", '''
      mcp() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "$@"; }
      source "$1"
    ''', "fixture", str(SOURCE / ".config/crush/crushrc")], cwd=home, env=env,
                            text=True, capture_output=True, check=True)
    declarations = [json.loads(line) for line in result.stdout.splitlines()]
    require([entry[1] for entry in declarations] == ["executor", "executor-desktop", "local"],
            "Crush declarations or local override loading changed")
    require("--args=mcp-remote@0.1.38" in declarations[0], "Crush transport changed")
    print("Verified native config syntax, shell layer selection, explicit overrides, "
          "Codex profile merging without writes, and Crush declarations")
