#!/usr/bin/env python3
"""Prepare pinned visualization dependency sources. Does not build or run tests."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def git(directory, *args):
    return subprocess.check_output(['git', '-C', str(directory), *args], text=True).strip()


def prepare(name, root, lock, here):
    spec = lock[name]
    destination = root / name
    patch = here / spec['patch']
    if hashlib.sha256(patch.read_bytes()).hexdigest() != spec['patchSha256']:
        raise SystemExit(f'{name}: patch digest does not match sources.lock.json')
    if destination.is_symlink():
        raise SystemExit(f'{name}: source directory must not be a symlink')
    if not destination.exists():
        destination.mkdir()
        subprocess.run(['git', 'init', str(destination)], check=True)
        git(destination, 'remote', 'add', 'origin', spec['repository'])
        git(destination, 'fetch', '--depth', '1', 'origin', spec['commit'])
        git(destination, 'checkout', '--detach', 'FETCH_HEAD')
    if git(destination, 'rev-parse', 'HEAD') != spec['commit']:
        raise SystemExit(f'{name}: refusing an unexpected source revision')
    if git(destination, 'status', '--porcelain', '--untracked-files=all'):
        raise SystemExit(f'{name}: use a clean source tree; existing work will not be replaced')
    for path, expected in spec.get('submodules', {}).items():
        git(destination, 'submodule', 'update', '--init', '--', path)
        if git(destination / path, 'rev-parse', 'HEAD') != expected:
            raise SystemExit(f'{name}: unexpected submodule revision for {path}')
    git(destination, 'apply', str(patch))
    print(f'{name}: prepared {spec["commit"]} with {spec["patch"]}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, required=True)
    parser.add_argument('--component', choices=['projectm', 'mpv', 'all'], default='all')
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    lock = json.loads((here / 'sources.lock.json').read_text())
    root = args.destination.resolve()
    root.mkdir(parents=True, exist_ok=True)
    for name in ['projectm', 'mpv'] if args.component == 'all' else [args.component]:
        prepare(name, root, lock, here)


if __name__ == '__main__':
    main()
