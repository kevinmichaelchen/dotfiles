"""Maintain selected claude settings while preserving unrelated settings."""

import json


def transform(raw):
    raw = raw.strip()
    data = json.loads(raw) if raw else {}

    servers = data.setdefault("mcpServers", {})
    for name in ("executor", "executor-desktop", "executor-cloud"):
        servers.pop(name, None)

    servers["executor"] = {
        "type": "http",
        "url": "https://executor.sh/kevin-chen-s-organization/mcp",
    }
    servers["executor-desktop"] = {
        "type": "stdio",
        "command": "executor",
        "args": ["mcp"],
    }

    return json.dumps(data, indent=2) + "\n\n"
