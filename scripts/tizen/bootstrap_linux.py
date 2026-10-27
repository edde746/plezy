#!/usr/bin/env python3
"""Install a pinned, isolated ARM Tizen build SDK from Samsung package archives.

This is the legacy Tizen 6-9 toolchain. It is not the 2026/GCC 14.2 target.
No root account, GUI, host package manager, .NET or TV is needed. Samsung SDK
license terms apply: https://samsungtizenos.com/tools-download/
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import platform
import shutil
import subprocess
import tempfile
import urllib.request
import zipfile

PINS = json.loads(Path(__file__).with_name('sdk-linux-arm.json').read_text())


def extract_package(archive, destination):
    """Samsung archives place the installed files under data/."""
    destination = Path(destination).resolve()
    with zipfile.ZipFile(archive) as source:
        for row in source.infolist():
            rel = PurePosixPath(row.filename)
            if rel.is_absolute() or '..' in rel.parts or '\\' in row.filename:
                raise ValueError('Unsafe SDK archive path')
            if not rel.parts or rel.parts[0] != 'data':
                continue
            target = destination.joinpath(*rel.parts[1:])
            if not target.resolve().is_relative_to(destination):
                raise ValueError('SDK archive escapes installation directory')
            if row.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            mode = row.external_attr >> 16
            if mode & 0o170000 == 0o120000:
                link = source.read(row).decode()
                if not (target.parent / link).resolve().is_relative_to(destination):
                    raise ValueError('SDK symlink escapes installation directory')
                if target.is_symlink():
                    if os.readlink(target) == link:
                        continue
                    target.unlink()
                target.symlink_to(link)
            else:
                target.write_bytes(source.read(row))
                target.chmod(mode & 0o777 or 0o644)


def install(destination):
    destination = Path(destination).resolve()
    if destination.exists() and any(destination.iterdir()):
        raise ValueError('Choose an empty SDK directory')
    destination.mkdir(parents=True, exist_ok=True)
    sdk = destination / 'tizen-studio'
    data = destination / 'tizen-studio-data'
    sdk.mkdir()
    data.mkdir()
    for package in PINS['packages']:
        print('Installing', package['name'], package['version'], flush=True)
        with tempfile.TemporaryDirectory(prefix='download-', dir=destination) as temp:
            archive = Path(temp) / 'package.zip'
            with urllib.request.urlopen(package['url'], timeout=120) as response, archive.open('wb') as out:
                shutil.copyfileobj(response, out)
            with archive.open('rb') as stream:
                if hashlib.file_digest(stream, 'sha256').hexdigest() != package['sha256']:
                    raise ValueError('SDK archive SHA-256 mismatch: ' + package['name'])
            extract_package(archive, sdk)
    (sdk / 'sdk.info').write_text(f'TIZEN_SDK_INSTALLED_PATH={sdk}\nTIZEN_SDK_DATA_PATH={data}\nJDK_PATH={sdk / "jdk"}\n')
    (sdk / 'sdk.version').write_text('TIZEN_SDK_VERSION=' + PINS['sdk_version'] + '\n')
    compiler = sdk / 'tools/arm-linux-gnueabi-gcc-9.2/bin/arm-linux-gnueabi-'
    sysroot = sdk / 'platforms/tizen-6.0/iot-headed/rootstraps/iot-headed-6.0-device.core'
    toolchain = destination / 'arm-toolchain.cmake'
    toolchain.write_text(f'''set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_C_COMPILER "{compiler}gcc")
set(CMAKE_CXX_COMPILER "{compiler}g++")
set(CMAKE_SYSROOT "{sysroot}")
set(CMAKE_C_FLAGS_INIT "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -fPIC")
set(CMAKE_CXX_FLAGS_INIT "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -fPIC")
set(CMAKE_FIND_ROOT_PATH "{sysroot}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
''')
    (destination / 'sdk-provenance.json').write_text(json.dumps(PINS, indent=2) + '\n')
    # LLVM 10 needs the legacy libtinfo ABI, absent on Ubuntu 24.04. Extract
    # this pinned Debian package locally; do not replace system libraries.
    compatibility = PINS['host_compatibility']
    archive = destination / 'host-compatibility.deb'
    with urllib.request.urlopen(compatibility['url'], timeout=120) as response, archive.open('wb') as out:
        shutil.copyfileobj(response, out)
    with archive.open('rb') as stream:
        if hashlib.file_digest(stream, 'sha256').hexdigest() != compatibility['sha256']:
            raise ValueError('Host compatibility package SHA-256 mismatch')
    subprocess.run(['dpkg-deb', '--extract', str(archive), str(destination / 'host-deps')], check=True)
    archive.unlink()
    library_path = str(destination / 'host-deps/lib/x86_64-linux-gnu')
    environment = os.environ.copy()
    environment['LD_LIBRARY_PATH'] = library_path + (':' + environment['LD_LIBRARY_PATH'] if environment.get('LD_LIBRARY_PATH') else '')
    (destination / 'build-environment.json').write_text(json.dumps({
        'TIZEN_SDK': str(sdk), 'TIZEN_CMAKE_TOOLCHAIN_ARM': str(toolchain),
        'LD_LIBRARY_PATH': environment['LD_LIBRARY_PATH'], 'CI': 'true',
    }, indent=2) + '\n')
    subprocess.run([str(compiler) + 'gcc', '--version'], check=True)
    subprocess.run([str(sdk / 'tools/ide/bin/tizen'), 'version'], check=True)
    subprocess.run([str(sdk / 'tools/llvm-10/bin/clang'), '--version'], env=environment, check=True)
    print(f'TIZEN_SDK={sdk}\nCMake toolchain: {toolchain}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', required=True)
    parser.add_argument('--accept-license', action='store_true', required=True,
                        help='Accept Samsung SDK terms before downloading/installing')
    args = parser.parse_args()
    if platform.system() != 'Linux' or platform.machine() not in ('x86_64', 'AMD64'):
        parser.error('This SDK bootstrap supports Linux x64 only')
    # CMake syntax cannot safely represent these characters in tool paths.
    if any(c in str(Path(args.directory).resolve()) for c in ('"', ';', '$', '\n', '\\')):
        parser.error('Choose a simple SDK path without CMake metacharacters')
    install(args.directory)


if __name__ == '__main__':
    main()
