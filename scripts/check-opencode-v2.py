#!/usr/bin/env python3
"""Check v2 normalization and native layering in isolated app state; no inference."""

import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parent.parent
MANAGED = REPO / 'dotfiles/.config/opencode/dotfiles.json'
# Resolve the native installation before isolating app state.
binary = sys.argv[1] if len(sys.argv) > 1 else shutil.which('opencode')
if binary is None:
    raise SystemExit('Install OpenCode v2 before running this check')
exe = Path(binary).resolve()
version = subprocess.check_output([str(exe), '--version'], text=True).strip()
if not version.startswith('opencode v2.'):
    raise SystemExit(f'Expected OpenCode v2, got {version}')

with tempfile.TemporaryDirectory(prefix='opencode-v2-check-', dir='/tmp') as temporary:
    home = Path(temporary)
    config = home / '.config/opencode'
    config.mkdir(parents=True)
    local = config / 'opencode.json'
    local.write_text(json.dumps({'model': 'openai/gpt-6.1-sol', 'agents': {
        'local-review': {'system': 'Keep my local agent', 'mode': 'subagent'}},
        'providers': {'openrouter': {'models': {
            'local-disabled-model': {'disabled': True}}}}}) + '\n')
    env = {k: v for k, v in os.environ.items()
           if not k.startswith(('OPENCODE_', 'XDG_')) and not k.endswith(('_API_KEY', '_TOKEN'))}
    env.update(HOME=temporary, XDG_CONFIG_HOME=str(home / '.config'),
               XDG_DATA_HOME=str(home / '.local/share'), XDG_CACHE_HOME=str(home / '.cache'),
               XDG_STATE_HOME=str(home / '.local/state'), OPENCODE_CONFIG=str(MANAGED),
               OPENCODE_DISABLE_MODELS_FETCH='true',
               OPENROUTER_API_KEY='fixture-not-a-real-key',
               FIREWORKS_API_KEY='fixture-not-a-real-key')

    def run(*args, override_env=None):
        result = subprocess.run([str(exe), *args], cwd=home, env=env | (override_env or {}),
                                text=True, capture_output=True, timeout=30)
        if result.returncode:
            raise RuntimeError(result.stderr or result.stdout)
        return result.stdout

    # Compare one bundled catalog snapshot, without live refreshes racing the
    # assertions. Private servers use placeholder keys and request no inference.
    empty = home / 'empty.json'
    empty.write_text('{}\n')

    def catalog(*, baseline=False):
        payload = json.loads(run('api', '--standalone', 'model.list',
                                 override_env={'OPENCODE_CONFIG': str(empty)} if baseline else None))
        return {(model['providerID'], model['id']): model for model in payload['data']}

    baseline = catalog(baseline=True)
    selected = ('openrouter', 'xiaomi/mimo-v2.6-pro')
    assert selected in baseline, 'MiMo Pro is missing from the upstream catalog'
    local_config = json.loads(local.read_text())
    local_config['providers']['openrouter']['models'][selected[1]] = {'disabled': True}
    local.write_text(json.dumps(local_config) + '\n')
    before = local.read_bytes()
    assert selected not in catalog(baseline=True), 'Fixture local disable was not applied'

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
        assert set(managed['mcp']['servers']) == {'executor'}
        assert managed['mcp']['servers']['executor']['disabled'] is False
        assert managed['agents']['title']['model'] == {
            'providerID': 'openai', 'model': 'gpt-6-luna'}
        assert managed['providers']['openrouter']['body']['provider']['data_collection'] == 'deny'
        assert 'update' not in managed, 'Native installation must control upgrades'
        assert 'model' not in managed, 'Primary model must remain local'
        assert not any(k in managed for k in ('provider', 'plugin', 'small_model'))
        available = catalog()
        shortlist = {(provider, model) for provider in ('openrouter', 'fireworks-ai')
                     for model in managed['providers'][provider]['models']}
        assert sum(provider == 'openrouter' for provider, _ in shortlist) == 7
        assert sum(provider == 'fireworks-ai' for provider, _ in shortlist) == 5
        for key in shortlist:
            assert key in baseline, f'{key} is missing upstream; do not accept fallback metadata'
            assert available[key]['enabled'] is True, f'{key} is not enabled'
            for field in ('modelID', 'capabilities', 'limit', 'cost', 'variants'):
                assert available[key].get(field) == baseline[key].get(field), (key, field)
            if key[0] == 'openrouter':
                assert available[key]['body']['provider']['data_collection'] == 'deny', key
        assert ('openrouter', 'local-disabled-model') not in available
        assert set(baseline) <= set(available), 'Managed shortlist removed other catalog entries'
        assert local.read_bytes() == before, 'OpenCode rewrote local settings'
        print(f'Verified {version}: native config loading/normalization, local state preservation, '
              'MCP wiring, title model, 12 enabled catalog options with inherited metadata, '
              'and privacy routing; no inference')
    finally:
        run('service', 'stop')
