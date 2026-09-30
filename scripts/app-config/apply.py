#!/usr/bin/env python3
"""Maintain app-owned settings without replacing unrelated local preferences."""

import argparse
import json
import os
from pathlib import Path
import stat
import tempfile
import tomllib

import claude
import codex
import crush
import opencode

SETTINGS = (
    (".claude.json", claude.transform, json.loads),
    (".codex/config.toml", codex.transform, tomllib.loads),
    (".config/crush/crush.json", crush.transform, json.loads),
    (".config/opencode/opencode.json", opencode.transform, json.loads),
)


def plan(home):
    changes = []
    for relative, transform, parse in SETTINGS:
        path = home / relative
        if path.is_symlink():
            raise ValueError(f"Refusing to replace symlink: {relative}")
        raw = path.read_text() if path.exists() else ""
        try:
            if raw.strip():
                data = parse(raw)
                if not isinstance(data, dict):
                    raise ValueError("Expected an object or table")
            content = transform(raw)
            parse(content)
        except (ValueError, TypeError, AttributeError) as error:
            raise ValueError(f"Invalid configuration: {relative}; no files written") from error
        if content != raw or stat.S_IMODE(path.stat().st_mode) != 0o600:
            changes.append((path, content))

    # Preserve any existing dependency manifest, including local edits.
    package = home / ".config/opencode/package.json"
    if not package.exists() and not package.is_symlink():
        changes.append((package, Path(__file__).with_name("opencode-package.json").read_text()))

    # The Claude projection includes both repository and lock-managed skills.
    skills = home / ".claude/skills"
    if skills.is_symlink():
        if skills.resolve() != (home / ".agents/skills").resolve():
            raise ValueError("Conflicting ~/.claude/skills link; no files written")
    elif skills.exists():
        raise ValueError("Conflicting ~/.claude/skills directory; no files written")
    return changes, skills


def write_private(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    # Write beside the destination so the rename is atomic and starts private.
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w") as stream:
            stream.write(content)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="List pending writes without changing files")
    args = parser.parse_args()
    home = Path.home()
    try:
        changes, skills = plan(home)
        for path, content in changes:
            print(f"{'Would update' if args.dry_run else 'Update'} ~/{path.relative_to(home)}")
            if not args.dry_run:
                write_private(path, content)
        if not skills.is_symlink():
            print(f"{'Would link' if args.dry_run else 'Link'} ~/.claude/skills -> ../.agents/skills")
            if not args.dry_run:
                (home / ".agents/skills").mkdir(parents=True, exist_ok=True)
                skills.parent.mkdir(parents=True, exist_ok=True)
                skills.symlink_to("../.agents/skills")
    except (OSError, ValueError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
