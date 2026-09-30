#!/usr/bin/env python3
"""Check v2 normalization and native layering in isolated app state; no inference."""

import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parent.parent
MANAGED = REPO / 'dotfiles/.config/opencode/dotfiles.json'
# Resolve before isolating XDG paths, which also affect Mise's install directory.
exe = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(subprocess.check_output(
    ['mise', '-C', str(REPO / 'mise'), 'which', 'opencode'], text=True).strip()).resolve()
version = subprocess.check_output([str(exe), '--version'], text=True).strip()
if not version.startswith('opencode v2.'):
    raise SystemExit(f'Expected OpenCode v2, got {version}')

with tempfile.TemporaryDirectory(prefix='opencode-v2-check-', dir='/tmp') as temporary:
    home = Path(temporary)
    config = home / '.config/opencode'
    config.mkdir(parents=True)
    local = config / 'opencode.json'
    local.write_text(json.dumps({'model': 'openai/gpt-6.1-sol', 'agents': {
        'local-review': {'system': 'Keep my local agent', 'mode': 'subagent'}}}) + '\n')
    before = local.read_bytes()
    env = {k: v for k, v in os.environ.items()
           if not k.startswith(('OPENCODE_', 'XDG_')) and not k.endswith(('_API_KEY', '_TOKEN'))}
    env.update(HOME=temporary, XDG_CONFIG_HOME=str(home / '.config'),
               XDG_DATA_HOME=str(home / '.local/share'), XDG_CACHE_HOME=str(home / '.cache'),
               XDG_STATE_HOME=str(home / '.local/state'), OPENCODE_CONFIG=str(MANAGED))

    def run(*args):
        result = subprocess.run([str(exe), *args], cwd=home, env=env,
                                text=True, capture_output=True, timeout=30)
        if result.returncode:
            raise RuntimeError(result.stderr or result.stdout)
        return result.stdout

    # Service defaults use a fixed port; give this fixture its own free port.
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1', 0))
        port = reservation.getsockname()[1]
    run('service', 'set', 'port', str(port))
    try:
        sources = json.loads(run('debug', 'config'))
        documents = {entry['path']: entry['info'] for entry in sources if entry['type'] == 'document'}
        assert str(local) in documents, 'Local global config was not loaded'
        managed = documents[str(MANAGED)]
        assert set(managed['mcp']['servers']) == {'executor', 'executor-desktop'}
        assert managed['mcp']['servers']['executor']['disabled'] is False
        assert managed['agents']['title']['model'] == {
            'providerID': 'openai', 'model': 'gpt-6-luna'}
        assert managed['providers']['openrouter']['body']['provider']['data_collection'] == 'deny'
        assert managed['update'] == 'disable', 'Mise must own upgrades'
        assert 'model' not in managed, 'Primary model must remain local'
        assert not any(k in managed for k in ('provider', 'plugin', 'small_model'))
        assert local.read_bytes() == before, 'OpenCode rewrote local settings'
        print(f'Verified {version}: native config loading/normalization, local state preservation, '
              'MCP wiring, title model, and privacy routing; no inference')
    finally:
        run('service', 'stop')
