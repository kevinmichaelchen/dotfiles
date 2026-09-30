"""Maintain selected codex settings while preserving unrelated settings."""

import re


def transform(raw):
    text = raw

    section_match = re.search(r"(?m)^\[", text)
    preamble = text[: section_match.start()] if section_match else text
    sections = text[section_match.start() :] if section_match else ""

    preamble = re.sub(
        r"(?m)^(?:model|model_reasoning_effort|service_tier)\s*=.*\n?",
        "",
        preamble,
    ).strip()
    sections = re.sub(
        r'(?ms)^\[mcp_servers\.(?:executor|executor-desktop|executor-cloud)(?:\.[^\]]+)?\]\n.*?(?=^\[|\Z)',
        "",
        sections,
    ).strip()

    model_defaults = (
        'model = "gpt-6.1-sol"\n'
        'model_reasoning_effort = "high"'
    )
    mcp_servers = (
        '[mcp_servers.executor]\n'
        'type = "http"\n'
        'url = "https://executor.sh/kevin-chen-s-organization/mcp"\n\n'
        '[mcp_servers.executor-desktop]\n'
        'command = "executor"\n'
        'args = ["mcp"]\n'
    )

    parts = [model_defaults]
    if preamble:
        parts.append(preamble)
    if sections:
        parts.append(sections)
    parts.append(mcp_servers)
    text = "\n\n".join(parts)
    return text.rstrip() + "\n"
