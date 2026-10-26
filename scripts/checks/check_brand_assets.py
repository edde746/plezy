#!/usr/bin/env python3
"""Verify approved branding and all committed exports, using only the stdlib."""

from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(root: Path = ROOT) -> list[str]:
    errors = []
    config_path = root / 'assets/branding/brand.json'
    config = json.loads(config_path.read_text())
    manifest = json.loads((root / 'assets/branding/asset-manifest.json').read_text())
    for path, expected in [
        (root / config['source'], config['source_sha256']),
        (config_path, manifest['config_sha256']),
        (root / 'scripts/codegen/generate_brand_assets.py', manifest['generator_sha256']),
    ]:
        if digest(path) != expected:
            errors.append(f'Brand source or generator changed: {path.relative_to(root)}')
    if manifest['source_sha256'] != config['source_sha256']:
        errors.append('Manifest does not describe the approved master')
    exports = manifest['exports']
    for path, expected in exports.items():
        file = root / path
        if not file.is_file() or digest(file) != expected:
            errors.append(f'Missing or stale brand export: {path}')
    for target in config['targets']:
        path = target['path']
        if path not in exports:
            errors.append(f'Untracked brand export: {path}')
        file = root / path
        if path.endswith('.png') and file.is_file():
            data = file.read_bytes()
            if data[:8] != b'\x89PNG\r\n\x1a\n' or list(struct.unpack('>II', data[16:24])) != target['size']:
                errors.append(f'Incorrect PNG dimensions: {path}')

    themes = set(config['themes'])
    catalog = (root / 'lib/services/app_icon/app_icon_catalog.dart').read_text()
    catalog_ids = set(re.findall(r"AppIconOption\._\('([a-z0-9_]+)'", catalog))
    android = (root / 'android/app/src/main/AndroidManifest.xml').read_text()
    android_ids = set(re.findall(r'android:name="\.appicon\.([a-z0-9_]+)"', android))
    tvos = (root / 'tvos/Runner/Info.plist').read_text()
    tvos_ids = set(re.findall(r'<string>AppIcon-([a-z0-9_]+)</string>', tvos))
    if not (len(themes) == 23 and themes == catalog_ids == android_ids == tvos_ids):
        errors.append('Permanent alternate icon ids differ across platforms')
    for theme in themes:
        required = [
            f'ios/Runner/AlternateAppIcons.xcassets/AppIcon-{theme}.appiconset/icon.png',
            f'assets/app_icons/previews/{theme}.webp',
            f'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_{theme}.webp',
            f'android/app/src/main/res/drawable-xhdpi/tv_banner_{theme}.webp',
        ]
        for density in ('xhdpi', 'xxhdpi', 'xxxhdpi'):
            for layer in ('background', 'foreground', 'monochrome'):
                required.append(f'android/app/src/main/res/drawable-{density}/ic_launcher_{theme}_{layer}.webp')
        for path in required:
            if path not in exports:
                errors.append(f'Alternate art missing from manifest: {path}')
    for platform in ('ios', 'macos'):
        icon = root / platform / 'plezy.icon'
        definition = json.loads((icon / 'icon.json').read_text())
        for group in definition['groups']:
            for layer in group['layers']:
                if not (icon / 'Assets' / layer['image-name']).is_file():
                    errors.append(f'Missing Icon Composer asset: {platform}/{layer["image-name"]}')
    for layer in ('foreground', 'monochrome'):
        if (root / f'android/app/src/main/res/drawable/ic_launcher_{layer}.xml').exists():
            errors.append(f'Obsolete Android vector shadows the selected {layer} PNG')
    # The old unique curve must not survive in source SVG / Android resources.
    for directory in ('assets', 'ios/plezy.icon', 'macos/plezy.icon', 'android/app/src/main/res'):
        for path in (root / directory).rglob('*'):
            if path.suffix in ('.svg', '.xml') and 'M335.65,192.66L68.01,38.14' in path.read_text():
                errors.append(f'Obsolete wave mark: {path.relative_to(root)}')
    return errors


if __name__ == '__main__':
    failures = check()
    if failures:
        print('\n'.join(failures), file=sys.stderr)
        raise SystemExit(1)
    print('Branding source, exports, dimensions, platform ids and native references verified.')
