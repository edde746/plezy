#!/usr/bin/env python3
"""Build pinned native sources into the XCFramework used by the local pod.
Runs on the build host; never downloads an executable or an unverified binary.
"""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / 'packages/plezy_torrent'

def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)

def build(platform):
    specs = {
        'ios': [('iphoneos', 'arm64'), ('iphonesimulator', 'arm64;x86_64')],
        'tvos': [('appletvos', 'arm64'), ('appletvsimulator', 'arm64;x86_64')],
        'macos': [('macosx', 'arm64;x86_64')],
    }[platform]
    destination = PACKAGE / ('ios' if platform == 'tvos' else platform) / 'Frameworks' / platform / 'PlezyTorrent.xcframework'
    inputs = [Path(__file__).read_bytes(), platform.encode(),
              subprocess.check_output(['xcodebuild', '-version']),
              subprocess.check_output(['cmake', '--version'])]
    inputs.extend(f.read_bytes() for f in sorted((PACKAGE / 'src').glob('*')) if f.is_file())
    fingerprint = hashlib.sha256(b''.join(inputs)).hexdigest()
    stamp = destination.parent / 'source.sha256'
    if destination.exists() and stamp.exists() and stamp.read_text() == fingerprint:
        return
    work = ROOT / 'build/p2p' / platform
    frameworks = []
    for sdk, arch in specs:
        out = work / sdk
        command = ['cmake', '-S', PACKAGE / 'src', '-B', out, '-G', 'Xcode',
                   '-DCMAKE_OSX_SYSROOT=' + sdk, '-DCMAKE_OSX_ARCHITECTURES=' + arch,
                   '-DCMAKE_OSX_DEPLOYMENT_TARGET=' + {'macos': '13.0', 'ios': '15.5', 'tvos': '15.0'}[platform],
                   '-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO',
                   '-DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO',
                   '-DCMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT=dwarf-with-dsym',
                   '-DFETCHCONTENT_BASE_DIR=' + str(ROOT / 'build/p2p/dependencies')]
        if platform != 'macos':
            command += ['-DCMAKE_SYSTEM_NAME=' + ('iOS' if platform == 'ios' else 'tvOS')]
        run(*command)
        run('cmake', '--build', out, '--config', 'Release', '--parallel', str(os.cpu_count() or 2))
        frameworks.extend(out.glob('Release*/PlezyTorrent.framework'))
    if len(frameworks) != len(specs):
        raise RuntimeError('Missing native framework slices')
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        shutil.rmtree(destination)
    args = ['xcodebuild', '-create-xcframework']
    for framework in frameworks:
        args += ['-framework', framework]
    run(*args, '-output', destination)
    stamp.write_text(fingerprint)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('platform', choices=['ios', 'tvos', 'macos'])
    build(parser.parse_args().platform)
