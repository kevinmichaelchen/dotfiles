#!/usr/bin/env python3
"""Validate Ubuntu deployment and config isolation in a temporary home."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

REPO = Path(__file__).resolve().parent.parent
MISE = shutil.which('mise')
assert MISE, 'mise must be on PATH'

with tempfile.TemporaryDirectory(prefix='dotfiles-ubuntu-') as temporary:
    home = Path(temporary)
    checkout = home / 'dotfiles'
    for name in ('platforms', 'mise', 'dotfiles'):
        shutil.copytree(REPO / name, checkout / name)
    for name in ('.profile', '.bashrc'):
        (home / name).write_text('# existing machine settings\nexport KEEP_ME=yes\n')
    env = {k: v for k, v in os.environ.items() if not k.startswith(('MISE_', 'XDG_'))}
    env.update(HOME=temporary, MISE_GLOBAL_CONFIG_FILE=str(checkout / 'platforms/ubuntu/config.toml'),
               MISE_IGNORED_CONFIG_PATHS=str(checkout / 'mise/config.toml'),
               MISE_TRUSTED_CONFIG_PATHS=temporary, MISE_OFFLINE='1')
    for key, relative in [('XDG_CONFIG_HOME', '.config'), ('XDG_CACHE_HOME', '.cache'),
                          ('XDG_DATA_HOME', '.local/share'), ('XDG_STATE_HOME', '.local/state')]:
        env[key] = str(home / relative)

    def run(*args, success=True):
        result = subprocess.run(args, cwd=checkout, env=env, capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result

    run(MISE, 'dotfiles', 'apply', '--dry-run')
    assert not (home / '.config').exists(), 'Preview changed the home'
    run(MISE, 'dotfiles', 'apply', '--yes')
    before = {name: (home / name).read_bytes() for name in ('.profile', '.bashrc')}
    run(MISE, 'dotfiles', 'apply', '--yes')
    for name, content in before.items():
        assert (home / name).read_bytes() == content, 'Repeated apply changed startup file'
        assert content.startswith(b'# existing machine settings\nexport KEEP_ME=yes\n')
    assert (home / '.config/mise/config.toml').resolve() == checkout / 'platforms/ubuntu/config.toml'
    assert not (home / '.zshrc').exists()
    assert (home / '.gitconfig').is_file()
    assert not (home / '.codex').exists()

    # After deployment, normal discovery must exclude the Mac config without
    # relying on the bootstrap process's environment overrides.
    del env['MISE_IGNORED_CONFIG_PATHS']
    del env['MISE_GLOBAL_CONFIG_FILE']
    result = run(MISE, 'config', 'ls')
    assert 'dotfiles/mise/config.toml' not in result.stdout, result.stdout
    run(MISE, 'dotfiles', 'status')
    tools = run(MISE, 'ls', '--json').stdout
    assert 'node' not in tools and 'krunkit' not in tools, tools
    assert 'ripgrep' in tools and 'zoxide' in tools, tools

    # A real pre-existing config is a conflict, never an implicit overwrite.
    link = home / '.config/bash/interactive.bash'
    link.unlink()
    link.write_text('# local customizations\n')
    run(MISE, 'dotfiles', 'apply', '--yes', success=False)
    assert link.read_text() == '# local customizations\n'

config = tomllib.loads((REPO / 'platforms/ubuntu/config.toml').read_text())
lock = tomllib.loads((REPO / 'platforms/ubuntu/mise.lock').read_text())
assert set(config['tools']) == set(lock['tools'])
for entries in lock['tools'].values():
    for entry in entries:
        platform = entry['platforms.linux-x64']
        assert platform['url'] and platform['checksum']

if os.uname().sysname == 'Linux':
    for name in ('bootstrap.sh', 'update.sh', 'update-tools.sh'):
        result = subprocess.run(['bash', str(REPO / 'scripts' / name)], capture_output=True, text=True)
        assert result.returncode != 0 and 'macOS workstation' in result.stderr

print('Verified Ubuntu links, startup preservation, idempotence, conflicts, Mac config isolation, Linux locks, and platform guards')
