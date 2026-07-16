#!/usr/bin/env bash
# Remove API-key material previously rendered from 1Password.

set -euo pipefail

rm -f \
  "$HOME/.config/shell/cerebras.sh" \
  "$HOME/.config/shell/exa.sh" \
  "$HOME/.config/shell/firecrawl.sh" \
  "$HOME/.config/shell/fireworks.sh" \
  "$HOME/.config/shell/huggingface.sh" \
  "$HOME/.config/shell/hygraph.sh" \
  "$HOME/.config/shell/jira.sh" \
  "$HOME/.config/shell/nia.sh" \
  "$HOME/.config/shell/openrouter.sh" \
  "$HOME/.config/shell/parallel.sh" \
  "$HOME/.config/shell/perplexity.sh" \
  "$HOME/.config/shell/railway.sh" \
  "$HOME/.config/shell/replicate.sh" \
  "$HOME/.config/crush/crush.json" \
  "$HOME/.config/opencode/opencode.json"

python3 <<'PY'
import json
from pathlib import Path
import re

claude_path = Path.home() / ".claude.json"
if claude_path.exists():
    data = json.loads(claude_path.read_text())
    servers = data.get("mcpServers", {})
    for name in ("executor", "executor-desktop", "executor-cloud"):
        servers.pop(name, None)
    claude_path.write_text(json.dumps(data, indent=2) + "\n")

codex_path = Path.home() / ".codex" / "config.toml"
if codex_path.exists():
    text = codex_path.read_text()
    pattern = re.compile(
        r"(?ms)^\[mcp_servers\.(?:executor|executor-desktop|executor-cloud)(?:\.[^\]]+)?\]\n.*?(?=^\[|\Z)"
    )
    cleaned = pattern.sub("", text).strip()
    codex_path.write_text(cleaned + "\n" if cleaned else "")
PY
