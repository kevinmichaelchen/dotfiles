#!/usr/bin/env python3
"""Check ghq-based identities, including nested repos and linked worktrees."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

REPO = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='git-identities-') as temporary:
    home = Path(temporary)
    config_dir = home / '.config/git'
    config_dir.mkdir(parents=True)
    for name in ('identity', 'aspira'):
        shutil.copy2(REPO / 'dotfiles/.config/git' / name, config_dir / name)
    config = home / '.gitconfig'
    config.write_text('[include]\n    path = ~/.config/git/identity\n')
    env = {k: v for k, v in os.environ.items() if not k.startswith(('GIT_', 'XDG_'))}
    env.update(HOME=temporary, GIT_CONFIG_GLOBAL=str(config), GIT_CONFIG_NOSYSTEM='1')

    def git(path, *args):
        return subprocess.check_output(['git', '-C', str(path), *args], env=env, text=True,
                                       stderr=subprocess.PIPE).strip()

    def identity(path, email):
        for kind in ('AUTHOR', 'COMMITTER'):
            value = git(path, 'var', f'GIT_{kind}_IDENT')
            assert value.startswith(f'Kevin Chen <{email}> '), value

    personal = 'kevinmichaelchen@gmail.com'
    work = 'kevin.chen@aspiraconnect.com'
    cases = {
        'dotfiles': personal,
        'dev/github.com/kevinmichaelchen/skills': personal,
        'dev/github.com/AspiraVentures/project': work,
        'dev/github.com/Aspira-Secure/project': work,
        'dev/github.com/aspiraventures/nested/project': work,
        'dev/github.com/ASPIRA-SECURE/project': work,
        'dev/github.com/AspiraVenturesOther/project': personal,
        'other/project': personal,
    }
    for relative, email in cases.items():
        path = home / relative
        path.mkdir(parents=True)
        git(path, 'init', '-b', 'main')
        identity(path, email)

    main = home / 'dev/github.com/AspiraVentures/project'
    git(main, 'commit', '--allow-empty', '-m', 'Fixture')
    worktree = home / 'elsewhere-worktree'
    git(main, 'worktree', 'add', '-b', 'fixture', str(worktree))
    identity(worktree, work)
    git(main, 'config', 'user.email', 'override@example.test')
    identity(main, 'override@example.test')
    assert git(home, 'config', '--path', '--get', 'ghq.root') == str(home / 'dev')

print('Verified personal/work author and committer identities, case-insensitive paths, boundaries, worktrees, local overrides, and ghq root')
