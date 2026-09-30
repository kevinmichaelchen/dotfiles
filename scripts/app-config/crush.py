"""Maintain selected crush settings while preserving unrelated settings."""

import json


def transform(raw):
    raw = raw.strip()
    data = json.loads(raw) if raw else {"$schema": "https://charm.land/crush.json"}

    servers = data.setdefault("mcp", {})
    for name in ("executor", "executor-desktop", "executor-cloud"):
        servers.pop(name, None)

    servers["executor"] = {
        "type": "stdio",
        "command": "mise",
        "args": [
            "exec", "--", "sfw", "npx", "-y", "mcp-remote@0.1.38",
            "https://executor.sh/kevin-chen-s-organization/mcp",
            "--transport", "http-only",
        ],
        "env": {"SFW_SKIP_UPDATE_CHECK": "1"},
        "timeout": 120,
    }
    servers["executor-desktop"] = {
        "type": "stdio",
        "command": "executor",
        "args": ["mcp"],
        "timeout": 120,
    }

    return json.dumps(data, indent=2) + "\n\n"
