#!/usr/bin/env python3
"""Prepare pinned visualization dependency sources. Does not build or run tests."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def git(directory, *args):
    return subprocess.check_output(['git', '-C', str(directory), *args], text=True).strip()


def checkout(name, root, spec):
    destination = root / name
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
    return destination


def prepare(name, root, lock, here, platform):
    spec = lock[name]
    patch = here / spec['patch']
    if hashlib.sha256(patch.read_bytes()).hexdigest() != spec['patchSha256']:
        raise SystemExit(f'{name}: patch digest does not match sources.lock.json')
    destination = checkout(name, root, spec)
    for path, expected in spec.get('submodules', {}).items():
        git(destination, 'submodule', 'update', '--init', '--', path)
        if git(destination / path, 'rev-parse', 'HEAD') != expected:
            raise SystemExit(f'{name}: unexpected submodule revision for {path}')
    if name == 'mpv':
        build = checkout('mpv-build', root, lock['appMpvBuild'])
        versions = json.loads((build / 'versions.json').read_text())
        if versions['components']['mpv']['commit'] != spec['commit']:
            raise SystemExit('mpv-build manifest does not match the locked mpv source')
        seen = set()
        for series in ['common', platform]:
            manifest = build / 'patches' / 'mpv' / f'series.{series}'
            for line in manifest.read_text().splitlines():
                filename = line.split('#', 1)[0].strip()
                if not filename:
                    continue
                if Path(filename).name != filename or filename in seen:
                    raise SystemExit(f'Invalid or duplicate patch in {manifest}: {filename}')
                seen.add(filename)
                git(destination, 'apply', str(build / 'patches' / 'mpv' / 'pool' / filename))
        print(f'mpv: composed {len(seen)} locked common/{platform} source patches')
    git(destination, 'apply', str(patch))
    print(f'{name}: prepared {spec["commit"]} with {spec["patch"]}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, required=True)
    parser.add_argument('--component', choices=['projectm', 'mpv', 'all'], default='all')
    parser.add_argument('--platform', choices=['linux', 'windows', 'apple', 'android'], default='linux',
                        help='mpv-build patch series; each platform needs its own clean destination')
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    lock = json.loads((here / 'sources.lock.json').read_text())
    root = args.destination.resolve()
    root.mkdir(parents=True, exist_ok=True)
    for name in ['projectm', 'mpv'] if args.component == 'all' else [args.component]:
        prepare(name, root, lock, here, args.platform)


if __name__ == '__main__':
    main()
