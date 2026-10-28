#!/usr/bin/env python3
"""Resolve pinned Steam engine sources and apply reviewed local integration patches."""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import errno
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]


def run(*args: str, cwd: Path | None = None) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def checkout(destination: Path, specification: dict, recursive_submodules: bool = True) -> None:
    run('git', 'init', '--quiet', str(destination))
    run('git', 'remote', 'add', 'origin', specification['repository'], cwd=destination)
    run('git', 'fetch', '--quiet', '--depth=1', 'origin', specification['revision'], cwd=destination)
    run('git', 'checkout', '--quiet', '--detach', 'FETCH_HEAD', cwd=destination)
    if run('git', 'rev-parse', 'HEAD', cwd=destination) != specification['revision']:
        raise ValueError('Unexpected native source revision')
    if recursive_submodules:
        run('git', 'submodule', 'update', '--init', '--recursive', '--depth=1', cwd=destination)


@contextmanager
def preparation_lock(destination: Path, timeout: float = 300):
    """Serialize Xcode targets/architectures sharing the same source checkout.

    Keep the lock inode after release: unlinking it can let a third process
    acquire a different file while a waiting process still owns the first.
    A dead builder releases its kernel lock without manual cleanup.
    """
    destination.parent.mkdir(parents=True, exist_ok=True)
    with (destination.parent / f'.{destination.name}-prepare.lock').open('a+b') as lock:
        if os.name == 'nt':
            import msvcrt
            if lock.seek(0, os.SEEK_END) == 0:
                lock.write(b'\0')
                lock.flush()

            def acquire():
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)

            def release():
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            import fcntl

            def acquire():
                fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)

            def release():
                fcntl.flock(lock.fileno(), fcntl.LOCK_UN)

        deadline = time.monotonic() + timeout
        while True:
            try:
                acquire()
                break
            except OSError as error:
                if error.errno not in (errno.EACCES, errno.EAGAIN, errno.EDEADLK):
                    raise
                if time.monotonic() >= deadline:
                    raise TimeoutError('Another Steam source preparation is still running') from error
                time.sleep(0.05)
        try:
            yield
        finally:
            release()


def prepare(destination: Path) -> None:
    with preparation_lock(destination):
        prepare_locked(destination)


def prepare_locked(destination: Path) -> None:
    source_lock = json.loads((ROOT / 'games-native.lock.json').read_text())
    lock = source_lock['steamRuntime']
    pyrowave = lock['pyrowave']
    granite = source_lock['steamResearch']['granite']
    ihs_patches = sorted((ROOT / 'scripts/games/patches').glob('steam-runtime-*.patch'))
    digest = hashlib.sha256(Path(__file__).read_bytes() + json.dumps(lock, sort_keys=True).encode())
    digest.update(json.dumps(granite, sort_keys=True).encode())
    for patch in ihs_patches:
        digest.update(patch.read_bytes())
    recipe = digest.hexdigest()
    marker = destination / '.plezy-recipe'
    if marker.exists() and marker.read_text() == recipe:
        return
    if destination.exists():
        default_destination = (ROOT / '.dart_tool/games/steam').resolve()
        if destination == default_destination and marker.exists():
            previous_recipe = marker.read_text().strip()[:12]
            archive = destination.with_name(f'{destination.name}-stale-{previous_recipe}')
            if archive.exists():
                raise SystemExit(f'Stale native source archive already exists: {archive}')
            destination.rename(archive)
        else:
            raise SystemExit(f'Stale native sources: review and remove {destination} before regenerating')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='steam-', dir=destination.parent) as staging:
        prepared = Path(staging) / 'source'
        prepared.mkdir()
        for name, specification in lock.items():
            if name == 'pyrowave':
                continue
            checkout(prepared / name, specification)
        checkout(prepared / 'pyrowave', pyrowave)
        granite_source = prepared / 'pyrowave/Granite'
        checkout(granite_source, granite, recursive_submodules=False)
        submodules = granite.get('submodules', {})
        for path, revision in sorted(submodules.items()):
            run('git', 'submodule', 'update', '--init', '--depth=1', '--', path, cwd=granite_source)
            if run('git', '-C', path, 'rev-parse', 'HEAD', cwd=granite_source) != revision:
                raise ValueError(f'Unexpected Granite submodule revision: {path}')
        ihs = prepared / 'ihslib'
        for patch in ihs_patches:
            run('git', 'apply', '--check', str(patch), cwd=ihs)
            run('git', 'apply', str(patch), cwd=ihs)
        (prepared / '.plezy-recipe').write_text(recipe)
        shutil.move(str(prepared), destination)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / '.dart_tool/games/steam')
    prepare(parser.parse_args().output.resolve())
