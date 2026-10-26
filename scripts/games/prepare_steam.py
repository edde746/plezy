#!/usr/bin/env python3
"""Resolve pinned Steam engine sources and apply reviewed local integration patches."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def run(*args: str, cwd: Path | None = None) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def checkout(destination: Path, specification: dict) -> None:
    run('git', 'init', '--quiet', str(destination))
    run('git', 'remote', 'add', 'origin', specification['repository'], cwd=destination)
    run('git', 'fetch', '--quiet', '--depth=1', 'origin', specification['revision'], cwd=destination)
    run('git', 'checkout', '--quiet', '--detach', 'FETCH_HEAD', cwd=destination)
    if run('git', 'rev-parse', 'HEAD', cwd=destination) != specification['revision']:
        raise ValueError('Unexpected native source revision')
    run('git', 'submodule', 'update', '--init', '--recursive', '--depth=1', cwd=destination)


def prepare(destination: Path) -> None:
    lock = json.loads((ROOT / 'games-native.lock.json').read_text())['steamRuntime']
    local_patches = sorted((ROOT / 'scripts/games/patches').glob('steam-runtime-*.patch'))
    digest = hashlib.sha256(Path(__file__).read_bytes() + json.dumps(lock, sort_keys=True).encode())
    for patch in local_patches:
        digest.update(patch.read_bytes())
    recipe = digest.hexdigest()
    marker = destination / '.plezy-recipe'
    if marker.exists() and marker.read_text() == recipe:
        return
    if destination.exists():
        raise SystemExit(f'Stale native sources: review and remove {destination} before regenerating')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='steam-', dir=destination.parent) as staging:
        prepared = Path(staging) / 'source'
        prepared.mkdir()
        for name, specification in lock.items():
            checkout(prepared / name, specification)
        ihs = prepared / 'ihslib'
        for patch in local_patches:
            run('git', 'apply', '--check', str(patch), cwd=ihs)
            run('git', 'apply', str(patch), cwd=ihs)
        (prepared / '.plezy-recipe').write_text(recipe)
        shutil.move(str(prepared), destination)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / '.dart_tool/games/steam')
    prepare(parser.parse_args().output.resolve())
