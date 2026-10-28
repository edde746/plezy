#!/usr/bin/env python3
"""Build, inspect and install the native Samsung TV package. No publication."""
from __future__ import annotations

import argparse
from contextlib import nullcontext
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import secrets
import shutil
import struct
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PINS = json.loads((Path(__file__).with_name('toolchain.json')).read_text())
APP_ID = 'org.snapetech.plezyng'
NS = {'t': 'http://tizen.org/ns/packages'}
ELF_TARGETS = {'arm': (1, 40), 'x64': (2, 62)}


def run(*args, cwd=None):
    environment = os.environ.copy()
    # Suppress Flutter's automatic cloud-instance metadata probe on build hosts.
    environment.setdefault('CI', 'true')
    subprocess.run([str(a) for a in args], cwd=cwd, env=environment, check=True)


def sha256(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def elf_arch(data):
    if len(data) < 20 or data[:4] != b'\x7fELF' or data[5] != 1:
        raise ValueError('Expected a little-endian ELF library')
    kind = (data[4], struct.unpack_from('<H', data, 18)[0])
    for name, value in ELF_TARGETS.items():
        if kind == value:
            return name
    raise ValueError(f'Unsupported ELF machine/class: {kind}')


def inspect_package(path, arch, *, signed=True):
    """Reject wrong identity/ABI, unsigned packages, secrets and unsafe ZIPs.

    Presence of XML signatures is structural validation; device installation
    verifies the certificate chain and DUID authorization.
    """
    path = Path(path)
    if path.suffix.lower() != '.tpk':
        raise ValueError('Expected a .tpk')
    with zipfile.ZipFile(path) as archive:
        rows = archive.infolist()
        names = [r.filename for r in rows]
        if len(names) != len(set(names)):
            raise ValueError('Duplicate ZIP entries')
        for row in rows:
            p = PurePosixPath(row.filename)
            if p.is_absolute() or '..' in p.parts or '\\' in row.filename or (row.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError('Unsafe package entry')
            if p.suffix.lower() in {'.p12', '.pfx', '.key'} or p.name in {'profiles.xml', '.env'}:
                raise ValueError('Private material in package')
        if signed and not {'author-signature.xml', 'signature1.xml'} <= set(names):
            raise ValueError('The package must be signed with the selected Samsung profile')
        manifests = [n for n in names if PurePosixPath(n).name == 'tizen-manifest.xml']
        if len(manifests) != 1:
            raise ValueError('Expected one Tizen manifest')
        raw = archive.read(manifests[0])
        if len(raw) > 128 * 1024 or b'<!DOCTYPE' in raw.upper() or b'<!ENTITY' in raw.upper():
            raise ValueError('Unsafe manifest XML')
        manifest = ET.fromstring(raw)
        app = manifest.find('t:ui-application', NS)
        profile = manifest.find('t:profile', NS)
        if manifest.get('package') != APP_ID or app is None or app.get('appid') != APP_ID or app.get('type') != 'capp' or app.get('exec') != 'plezyng':
            raise ValueError('Package identity/type does not match PlezyNG')
        if profile is None or profile.get('name') != 'tv':
            raise ValueError('Expected TV profile')
        version = manifest.get('version', '')
        if not re.fullmatch(r'\d+\.\d+\.\d+', version):
            raise ValueError('Expected numeric Tizen version')
        libraries = [n for n in names if n.endswith('.so') or '.so.' in n]
        required = {'libapp.so', 'libplezy_sqlite3.so', 'libdart_smb2.so', 'libplezy_torrent.so',
                    'libflutter_engine.so', 'libflutter_tizen_tv.so', 'libflutter_plugins.so',
                    'libftpw_video_player_videohole.so'}
        if not required <= {PurePosixPath(n).name for n in libraries}:
            raise ValueError('Missing application, Flutter runtime or native plugin libraries')
        if not {'bin/plezyng', 'res/icudtl.dat', 'res/flutter_assets/AssetManifest.bin'} <= set(names):
            raise ValueError('Missing native launcher or Flutter resources')
        minimum_api = {'arm': '6.0', 'x64': '8.0'}[arch]
        if manifest.get('api-version') != minimum_api:
            raise ValueError(f'Expected API {minimum_api} for {arch}')
        for name in libraries + ['bin/plezyng']:
            with archive.open(name) as stream:
                if elf_arch(stream.read(64)) != arch:
                    raise ValueError(f'Wrong architecture: {name}')
        return {'app_id': APP_ID, 'version': version, 'architecture': arch, 'sha256': sha256(path),
                'size': path.stat().st_size, 'signature_files_present': {'author-signature.xml', 'signature1.xml'} <= set(names),
                'minimum_api': minimum_api, 'hardware_qualified': False, 'native_libraries': libraries}


def checkout(repo, revision, destination):
    # Only fixed repositories/revisions from the checked-in pin file are used.
    run('git', 'init', '-q', destination)
    run('git', '-C', destination, 'fetch', '--depth=1', f'https://github.com/{repo}.git', revision)
    run('git', '-C', destination, 'checkout', '--detach', 'FETCH_HEAD')
    actual = subprocess.check_output(['git', '-C', str(destination), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != revision:
        raise ValueError('Source revision mismatch')


def native(args):
    """Cross-compile the storage libraries with an explicit Samsung toolchain."""
    out = Path(args.output).resolve()
    out.mkdir(parents=True, exist_ok=True)
    toolchain = Path(args.toolchain).resolve(strict=True)
    sources = out / 'sources'
    sources.mkdir(exist_ok=True)
    for name, repo, revision in [
        ('libsmb2', 'sahlberg/libsmb2', PINS['libsmb2_revision']),
        ('libsmb2-scripts', 'ales-drnz/libsmb2-scripts', PINS['libsmb2_scripts_revision']),
    ]:
        if (sources / name).exists():
            raise ValueError(f'{sources / name} already exists; use a fresh native output directory')
        if args.source_root:
            local = Path(args.source_root).resolve() / name
            actual = subprocess.check_output(['git', '-C', str(local), 'rev-parse', 'HEAD'], text=True).strip()
            if actual != revision or subprocess.check_output(['git', '-C', str(local), 'status', '--porcelain']):
                raise ValueError(f'Offline source must be a clean checkout of {name} at {revision}')
            # Copy only tracked files; ignored credentials/build caches are not
            # corresponding source and must never enter the redistribution.
            paths = subprocess.check_output(['git', '-C', str(local), 'ls-files', '-z']).decode().split('\0')
            for filename in filter(None, paths):
                source = local / filename
                if source.is_symlink():
                    raise ValueError(f'Unexpected source symlink: {filename}')
                target = sources / name / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
        else:
            checkout(repo, revision, sources / name)
    for patch in sorted((sources / 'libsmb2-scripts/patches/libsmb2/shared').glob('patch_*.py')):
        run(sys.executable, patch, sources / 'libsmb2')
    run('cmake', '-S', sources / 'libsmb2', '-B', out / 'smb-build', f'-DCMAKE_TOOLCHAIN_FILE={toolchain}',
        '-DCMAKE_BUILD_TYPE=Release', '-DBUILD_SHARED_LIBS=ON', '-DENABLE_EXAMPLES=OFF', '-DENABLE_UTILS=OFF',
        '-DENABLE_LIBKRB5=OFF', '-DENABLE_GSSAPI=OFF', '-DENABLE_LIBDCERPC=OFF', '-DCMAKE_POLICY_VERSION_MINIMUM=3.5')
    run('cmake', '--build', out / 'smb-build', '--parallel', args.jobs)
    candidates = list((out / 'smb-build').rglob('libsmb2.so'))
    if len(candidates) != 1:
        raise ValueError('Expected one libsmb2.so output')
    shutil.copyfile(candidates[0], out / 'libdart_smb2.so')

    archive_path = sources / 'sqlite.zip'
    with urllib.request.urlopen(PINS['sqlite_url'], timeout=60) as response, archive_path.open('wb') as stream:
        shutil.copyfileobj(response, stream)
    if sha256(archive_path) != PINS['sqlite_sha256']:
        raise ValueError('SQLite archive digest mismatch')
    sqlite = sources / 'sqlite'
    sqlite.mkdir()
    with zipfile.ZipFile(archive_path) as archive:
        for name in ('sqlite3.c', 'sqlite3.h', 'sqlite3ext.h'):
            matches = [n for n in archive.namelist() if PurePosixPath(n).name == name]
            if len(matches) != 1:
                raise ValueError('Unexpected SQLite archive layout')
            (sqlite / name).write_bytes(archive.read(matches[0]))
    if hashlib.sha3_256((sqlite / 'sqlite3.c').read_bytes()).hexdigest() != PINS['sqlite_source_sha3_256']:
        raise ValueError('SQLite source digest mismatch')
    (sqlite / 'CMakeLists.txt').write_text('''cmake_minimum_required(VERSION 3.16)
project(plezy_sqlite3 C)
add_library(plezy_sqlite3 SHARED sqlite3.c)
target_compile_definitions(plezy_sqlite3 PRIVATE SQLITE_THREADSAFE=1 SQLITE_ENABLE_FTS5 SQLITE_ENABLE_RTREE SQLITE_ENABLE_COLUMN_METADATA SQLITE_ENABLE_DBSTAT_VTAB)
target_link_libraries(plezy_sqlite3 PRIVATE m dl pthread)
target_link_options(plezy_sqlite3 PRIVATE "-Wl,-Bsymbolic-functions")
''')
    run('cmake', '-S', sqlite, '-B', out / 'sqlite-build', f'-DCMAKE_TOOLCHAIN_FILE={toolchain}', '-DCMAKE_BUILD_TYPE=Release')
    run('cmake', '--build', out / 'sqlite-build', '--parallel', args.jobs)
    shutil.copyfile(out / 'sqlite-build/libplezy_sqlite3.so', out / 'libplezy_sqlite3.so')
    run('cmake', '-S', ROOT / 'packages/plezy_torrent/src', '-B', out / 'torrent-build',
        f'-DCMAKE_TOOLCHAIN_FILE={toolchain}', '-DCMAKE_BUILD_TYPE=Release',
        f'-DFETCHCONTENT_BASE_DIR={sources / "torrent-dependencies"}')
    run('cmake', '--build', out / 'torrent-build', '--parallel', args.jobs)
    shutil.copyfile(out / 'torrent-build/libplezy_torrent.so', out / 'libplezy_torrent.so')
    report = {'architecture': args.arch, 'pins': PINS, 'libraries': {}}
    for name in ('libplezy_sqlite3.so', 'libdart_smb2.so', 'libplezy_torrent.so'):
        path = out / name
        if elf_arch(path.read_bytes()[:64]) != args.arch:
            raise ValueError('Toolchain produced the wrong architecture')
        report['libraries'][name] = sha256(path)
    (out / 'native-build.json').write_text(json.dumps(report, indent=2) + '\n')


def stage(source, destination, native_dir, arch):
    # Copy only Git-tracked inputs, including local modifications, so tokens,
    # profiles and build caches cannot be swept into the package.
    tracked = subprocess.check_output(['git', '-C', str(source), 'ls-files', '-z']).decode().split('\0')
    for name in filter(None, tracked):
        path = source / name
        if path.is_symlink():
            raise ValueError(f'Symlink source is not allowed: {name}')
        if path.is_file():
            dest = destination / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, dest)
    native_dir = Path(native_dir).resolve()
    report = json.loads((native_dir / 'native-build.json').read_text())
    if report['architecture'] != arch or report['pins'] != PINS:
        raise ValueError('Native inputs do not match the pinned toolchain/architecture')
    native_target = destination / 'tizen/lib'
    native_target.mkdir(parents=True, exist_ok=True)
    for name in ('libdart_smb2.so', 'libplezy_sqlite3.so', 'libplezy_torrent.so'):
        path = native_dir / name
        if sha256(path) != report['libraries'][name] or elf_arch(path.read_bytes()[:64]) != arch:
            raise ValueError(f'Native input mismatch: {name}')
        dest = native_target / name if name in {'libplezy_sqlite3.so', 'libplezy_torrent.so'} else destination / 'build-inputs' / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, dest)
    icon = destination / 'tizen/shared/res/plezyng.png'
    icon.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source / 'assets/plezy.png', icon)
    config = json.loads((source / '.dart_tool/package_config.json').read_text())
    smb = next(p for p in config['packages'] if p['name'] == 'dart_smb2')
    uri = urllib.parse.urljoin((source / '.dart_tool/package_config.json').as_uri(), smb['rootUri'])
    smb_root = Path(urllib.request.url2pathname(urllib.parse.urlparse(uri).path))
    if not re.search(r'^version:\s*' + re.escape(PINS['dart_smb2_version']) + r'\s*$', (smb_root / 'pubspec.yaml').read_text(), re.M):
        raise ValueError('Review the Tizen SMB hook for this dart_smb2 version')
    override = destination / 'packages/dart_smb2_tizen'
    shutil.copytree(smb_root, override)
    shutil.copyfile(source / 'scripts/tizen/smb_build_hook.dart', override / 'hook/build.dart')
    # Preserve every existing root override. Never mutate the shared pub cache.
    pubspec = destination / 'pubspec.yaml'
    text = pubspec.read_text()
    if text.count('\ndependency_overrides:\n') != 1 or re.search(r'^hooks:', text, re.M):
        raise ValueError('Review the staged pubspec merge after root hook/override changes')
    text = text.replace('\ndependency_overrides:\n', '\ndependency_overrides:\n  dart_smb2:\n    path: packages/dart_smb2_tizen\n', 1)
    text += '\nhooks: ' + json.dumps({'user_defines': {
            'sqlite3': {'source': 'system', 'name': 'plezy_sqlite3'},
            'dart_smb2': {'libsmb2': str(destination / 'build-inputs/libdart_smb2.so')},
        }}) + '\n'
    # The reader already rejects TVs at runtime. Remove its desktop PDFium
    # hook from this target entirely instead of bundling a foreign-ABI binary.
    text, removed = re.subn(r'^  pdfrx:.*\n', '', text, flags=re.M)
    if removed != 1:
        raise ValueError('Review the Tizen reader exclusion after dependency changes')
    reader = destination / 'lib/screens/sources/publication_reader_screen.dart'
    reader.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source / 'scripts/tizen/publication_reader_screen.dart', reader)
    pubspec.write_text(text)
    version = re.search(r'^version:\s*(\d+\.\d+\.\d+)', text, re.M)
    if version is None:
        raise ValueError('Missing application version')
    manifest = destination / 'tizen/tizen-manifest.xml'
    # Whitespace before version is deliberate: a word boundary also matches
    # the suffix of api-version and would overwrite the SDK API with 2.24.1.
    manifest_text = re.sub(r'(<manifest\b[^>]*?\sversion=")[^"]+', lambda m: m[1] + version[1], manifest.read_text())
    if arch == 'x64':
        manifest_text = re.sub(r'\bapi-version="[^"]+"', 'api-version="8.0"', manifest_text)
    manifest.write_text(manifest_text)


def build(args):
    sdk = Path(args.sdk).resolve(strict=True)
    actual = subprocess.check_output(['git', '-C', str(sdk), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != PINS['flutter_tizen_revision']:
        raise ValueError('flutter-tizen revision differs from toolchain.json')
    actual_flutter = subprocess.check_output(['git', '-C', str(sdk / 'flutter'), 'rev-parse', 'HEAD'], text=True).strip()
    if actual_flutter != PINS['flutter_revision']:
        raise ValueError('Flutter revision differs from toolchain.json')
    flutter = sdk / 'bin/flutter-tizen'
    run(flutter, '--version')
    run(flutter, 'pub', 'get', '--enforce-lockfile', cwd=ROOT)
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    if args.work_dir:
        work_dir = Path(args.work_dir).resolve()
        if work_dir.exists() and any(work_dir.iterdir()):
            raise ValueError('Work directory must be empty; it is preserved for diagnosing build failures')
        work_dir.mkdir(parents=True, exist_ok=True)
    context = nullcontext(args.work_dir) if args.work_dir else tempfile.TemporaryDirectory(prefix='plezyng-tizen-')
    with context as temp:
        project = Path(temp)
        stage(ROOT, project, args.native, args.arch)
        run(flutter, 'pub', 'get', cwd=project)
        run(flutter, 'build', 'tpk', '--release', '--device-profile', 'tv', '--target-arch', args.arch,
            '--security-profile', args.security_profile, '--dart-define=PLEZY_TIZEN=true', cwd=project)
        packages = list((project / 'build/tizen/tpk').glob('*.tpk'))
        if len(packages) != 1:
            raise ValueError('Expected exactly one newly built TPK')
        report = inspect_package(packages[0], args.arch)
        suffix = '-tester' if args.tester else ''
        name = f'PlezyNG-tizen-{args.arch}{suffix}.tpk'
        shutil.copyfile(packages[0], output / name)
        (output / (name + '.sha256')).write_text(f"{report['sha256']}  {name}\n")
        report['source_commit'] = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', 'HEAD'], text=True).strip()
        report['source_dirty'] = subprocess.run(['git', '-C', str(ROOT), 'diff', '--quiet', 'HEAD']).returncode != 0
        report['toolchain'] = PINS
        report['native_inputs'] = json.loads((Path(args.native) / 'native-build.json').read_text())
        report['target_scope'] = ('experimental Tizen 6-9; Tizen 10/GCC 14.2 is not qualified'
                                  if args.arch == 'arm' else 'experimental x64 emulator; not a TV build')
        report['signing'] = 'development-only-requires-tv-resigning' if args.tester else 'selected-profile-requires-device-verification'
        report['tv_install_verified'] = False
        report['catalogue_eligible'] = False
        (output / (name + '.json')).write_text(json.dumps(report, indent=2) + '\n')
        shutil.copyfile(project / 'pubspec.lock', output / 'pubspec-tizen.lock')
        shutil.copyfile(Path(args.native) / 'native-build.json', output / 'native-build.json')
        # Preserve corresponding native sources and applied patches for redistribution.
        shutil.make_archive(str(output / f'PlezyNG-tizen-{args.arch}-native-sources'), 'gztar', args.native, 'sources')


def install(args):
    inspect_package(args.package, args.arch)
    # Select a configured device explicitly. No automatic discovery/first-TV choice.
    path = Path(args.package).resolve()
    run('tizen', 'install', '-t', args.target, '-n', path.name, '--', path.parent)
    if args.launch:
        run('tizen', 'run', '-t', args.target, '-p', APP_ID)


def package_payload(path):
    """Hash each uncompressed payload entry so re-signing cannot alter the app."""
    with zipfile.ZipFile(path) as archive:
        return {row.filename: hashlib.sha256(archive.read(row)).hexdigest()
                for row in archive.infolist()
                if not row.is_dir() and row.filename not in {'author-signature.xml', 'signature1.xml'}}


def resign(args):
    """Apply the tester's existing Samsung profile without compiling anything."""
    source = Path(args.package).resolve(strict=True)
    if sha256(source) != args.sha256.lower():
        raise ValueError('Downloaded package does not match the expected SHA-256')
    inspect_package(source, args.arch)
    payload = package_payload(source)
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    result = output / f'PlezyNG-tizen-{args.arch}-signed.tpk'
    if result.exists():
        raise ValueError('Signed output already exists; choose a fresh output directory')
    with tempfile.TemporaryDirectory(prefix='plezyng-sign-', dir=output) as temp:
        staged = Path(temp) / source.name
        shutil.copyfile(source, staged)
        run('tizen', 'package', '-t', 'tpk', '-S', 'off', '-s', args.security_profile, '--', staged)
        candidates = list(Path(temp).glob('*.tpk'))
        if len(candidates) != 1:
            raise ValueError('Expected one re-signed TPK')
        report = inspect_package(candidates[0], args.arch)
        if package_payload(candidates[0]) != payload:
            raise ValueError('Re-signing changed the application payload')
        with zipfile.ZipFile(source) as before, zipfile.ZipFile(candidates[0]) as after:
            if all(before.read(name) == after.read(name) for name in ('author-signature.xml', 'signature1.xml')):
                raise ValueError('Signing produced no change; check the selected profile and SDK signing logs')
        shutil.copyfile(candidates[0], result)
    (output / (result.name + '.sha256')).write_text(f"{report['sha256']}  {result.name}\n")
    report.update({'signing': 'tester-selected-profile', 'tv_install_verified': False,
                   'input_sha256': args.sha256.lower(), 'payload_unchanged': True})
    (output / (result.name + '.json')).write_text(json.dumps(report, indent=2) + '\n')
    print(result)


def tester_profile(args):
    """Create a local development profile, without Samsung credentials or DUIDs."""
    sdk = Path(args.sdk_root).resolve(strict=True)
    info = dict(line.split('=', 1) for line in (sdk / 'sdk.info').read_text().splitlines() if '=' in line)
    data = Path(info['TIZEN_SDK_DATA_PATH']).resolve(strict=True)
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,60}', args.name):
        raise ValueError('Use a simple, unique profile name')
    profiles = data / 'profile/profiles.xml'
    if profiles.exists() and any(row.get('name') == args.name for row in ET.parse(profiles).iter('profile')):
        raise ValueError('Profile already exists; reuse it explicitly or choose another name')
    private = data / 'plezyng-development-certificates' / args.name
    private.mkdir(mode=0o700, parents=True, exist_ok=False)
    password = secrets.token_urlsafe(24)
    cli = sdk / 'tools/ide/bin/tizen'
    if os.name == 'nt':
        cli = cli.with_suffix('.bat')
    # The CLI logs its arguments locally. Never upload SDK logs or this private
    # directory; these credentials are disposable and are not Samsung keys.
    result = subprocess.run([str(cli), 'certificate', '-a', args.name, '-n', 'PlezyNG development handoff',
        '-f', 'author', '-p', password, '--', str(private)], capture_output=True)
    if result.returncode:
        raise ValueError('Development certificate creation failed; inspect local SDK logs')
    certificate = private / 'author.p12'
    certificate.chmod(0o600)
    # SDK 10 ships an i386 secret-tool that cannot run on every headless x64
    # host. Its Java reader also supports inline CipherUtil passwords. Use
    # that SDK implementation only for this disposable development profile.
    # This is reversible encoding, not secure storage for Samsung signing keys.
    classpath = str(sdk / 'tools/ide/lib-ncli/*')
    with tempfile.TemporaryDirectory(prefix='profile-helper-', dir=private) as temp:
        source = Path(temp) / 'ProfilePassword.java'
        source.write_text('''import java.io.*;
import org.tizen.common.util.CipherUtil;
public class ProfilePassword {
 public static void main(String[] args) throws Exception {
  String password=new BufferedReader(new InputStreamReader(System.in,"UTF-8")).readLine();
  java.nio.file.Files.write(java.nio.file.Paths.get(args[0]), CipherUtil.getEncryptedString(password).getBytes("UTF-8"));
 }
}
''')
        subprocess.run([str(sdk / 'jdk/bin/javac'), '-cp', classpath, str(source)], cwd=temp, check=True, capture_output=True)
        encoded_file = Path(temp) / 'encoded'
        subprocess.run([str(sdk / 'jdk/bin/java'), '-cp', temp + os.pathsep + classpath,
                        'ProfilePassword', str(encoded_file)], input=password + '\n', text=True,
                       cwd=temp, capture_output=True, check=True)
        encoded = encoded_file.read_text().strip()
    if not encoded or encoded.endswith('.pwd'):
        raise ValueError('SDK password encoding failed')
    template = (sdk / 'tools/ide/conf-ncli/profiles.xml').read_text()
    template = ET.fromstring(template.replace('<SDK_PATH>', str(sdk)).replace('<Your Certificate (.p12) Path>', str(certificate)))
    profile = next(template.iter('profile'))
    profile.set('name', args.name)
    next(item for item in profile if item.get('distributor') == '0').set('password', encoded)
    tree = ET.parse(profiles) if profiles.exists() else ET.ElementTree(ET.Element('profiles', version='3.1'))
    tree.getroot().append(profile)
    profiles.parent.mkdir(parents=True, exist_ok=True)
    tree.write(profiles, encoding='UTF-8', xml_declaration=True)
    profiles.chmod(0o600)
    run(cli, 'cli-config', f'profiles.path={profiles}')
    print(f'Development-only profile: {args.name}. A TV owner must re-sign the TPK.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    n = sub.add_parser('native')
    n.add_argument('--toolchain', required=True, help='Samsung SDK CMake toolchain file (compiler, sysroot, ABI)')
    n.add_argument('--output', required=True)
    n.add_argument('--jobs', type=int, default=2)
    n.add_argument('--source-root', help='Optional clean, pinned libsmb2 and libsmb2-scripts checkouts for offline builds')
    b = sub.add_parser('build')
    b.add_argument('--sdk', required=True, help='Pinned flutter-tizen checkout')
    b.add_argument('--native', required=True, help='Output from native subcommand')
    b.add_argument('--output', default=str(ROOT / 'build/tizen-release'))
    b.add_argument('--security-profile', required=True, help='Existing Samsung Certificate Manager profile name')
    b.add_argument('--tester', action='store_true', help='Produce a development-signed handoff; tester must re-sign for their TV')
    b.add_argument('--work-dir', help='Optional empty directory to preserve the staged project and build diagnostics')
    i = sub.add_parser('inspect')
    i.add_argument('package')
    ins = sub.add_parser('install')
    ins.add_argument('package')
    ins.add_argument('--target', required=True, help='Explicit Tizen Device Manager target')
    ins.add_argument('--launch', action='store_true')
    s = sub.add_parser('resign', help='Re-sign a prebuilt tester TPK with your TV-authorized Samsung profile')
    s.add_argument('package')
    s.add_argument('--sha256', required=True, help='Expected SHA-256 from the downloaded handoff')
    s.add_argument('--security-profile', required=True)
    s.add_argument('--output', required=True)
    profile = sub.add_parser('tester-profile', help='Create a development-only profile in a dedicated SDK')
    profile.add_argument('--sdk-root', required=True, help='Tizen SDK root, not flutter-tizen')
    profile.add_argument('--name', default='PlezyNG-Tester')
    for p in (n, b, i, ins, s):
        p.add_argument('--arch', choices=ELF_TARGETS, default='arm')
    args = parser.parse_args()
    try:
        if args.command == 'inspect':
            print(json.dumps(inspect_package(args.package, args.arch), indent=2))
        else:
            {'native': native, 'build': build, 'install': install, 'resign': resign,
             'tester-profile': tester_profile}[args.command](args)
    except (ValueError, OSError, subprocess.CalledProcessError, zipfile.BadZipFile, ET.ParseError) as error:
        parser.exit(1, f'Tizen packaging failed: {error}\n')


if __name__ == '__main__':
    main()
