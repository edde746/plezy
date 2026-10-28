"""Package boundary tests. Synthetic archives are never installable TV builds."""
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace
import zipfile

import package


def elf(arch='arm'):
    data = bytearray(64)
    data[:4] = b'\x7fELF'
    data[4], machine = package.ELF_TARGETS[arch]
    data[5] = 1
    struct.pack_into('<H', data, 18, machine)
    return bytes(data)


class PackageTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.manifest = (package.ROOT / 'tizen/tizen-manifest.xml').read_bytes()

    def archive(self, *, arch='arm', omit=None, extra=None, manifest=None):
        entries = {'tizen-manifest.xml': manifest or self.manifest,
                   'author-signature.xml': b'<Signature/>', 'signature1.xml': b'<Signature/>'}
        entries.update({f'lib/{name}': elf(arch) for name in
                        ('libapp.so', 'libdart_smb2.so', 'libplezy_sqlite3.so', 'libplezy_torrent.so',
                         'libflutter_engine.so', 'libflutter_plugins.so', 'libflutter_tizen_tv.so',
                         'libftpw_video_player_videohole.so')})
        entries.update({'bin/plezyng': elf(arch), 'res/icudtl.dat': b'fixture',
                        'res/flutter_assets/AssetManifest.bin': b'fixture'})
        if arch == 'x64' and manifest is None:
            entries['tizen-manifest.xml'] = self.manifest.replace(b'api-version="6.0"', b'api-version="8.0"')
        entries.update(extra or {})
        entries.pop(omit, None)
        path = self.root / 'fixture.tpk'
        with zipfile.ZipFile(path, 'w') as archive:
            for name, content in entries.items():
                archive.writestr(name, content)
        return path

    def test_report_is_structural_not_hardware_qualification(self):
        path = self.archive()
        report = package.inspect_package(path, 'arm')
        self.assertEqual(report['app_id'], 'org.snapetech.plezyng')
        self.assertEqual(report['sha256'], package.sha256(path))
        self.assertTrue(report['signature_files_present'])
        self.assertFalse(report['hardware_qualified'])

    def test_emulator_or_mixed_abi_cannot_pass_as_tv(self):
        for path in (self.archive(arch='x64', manifest=self.manifest),):
            with self.assertRaisesRegex(ValueError, 'Wrong architecture'):
                package.inspect_package(path, 'arm')
        path = self.archive(extra={'lib/plugin.so': elf('x64')})
        with self.assertRaisesRegex(ValueError, 'Wrong architecture'):
            package.inspect_package(path, 'arm')

    def test_signature_storage_library_and_identity_are_required(self):
        for omit in ('signature1.xml', 'lib/libdart_smb2.so', 'lib/libplezy_sqlite3.so', 'lib/libplezy_torrent.so',
                     'lib/libflutter_engine.so', 'lib/libflutter_plugins.so',
                     'lib/libftpw_video_player_videohole.so', 'bin/plezyng', 'res/icudtl.dat'):
            with self.subTest(omit=omit), self.assertRaises(ValueError):
                package.inspect_package(self.archive(omit=omit), 'arm')
        with self.assertRaisesRegex(ValueError, 'identity'):
            package.inspect_package(self.archive(manifest=self.manifest.replace(b'org.snapetech.plezyng', b'other.app')), 'arm')

    def test_private_material_and_unsafe_paths_are_rejected(self):
        for name in ('cert/author.p12', 'distributor.pfx', 'private.key', 'profiles.xml', '.env', '../escape', '/absolute', 'dir\\file'):
            with self.subTest(name=name), self.assertRaises(ValueError):
                package.inspect_package(self.archive(extra={name: b'private'}), 'arm')
        path = self.archive()
        with zipfile.ZipFile(path, 'a') as archive:
            info = zipfile.ZipInfo('link')
            info.external_attr = 0o120777 << 16
            archive.writestr(info, 'outside')
        with self.assertRaisesRegex(ValueError, 'Unsafe'):
            package.inspect_package(path, 'arm')

    def test_manifest_entities_are_not_expanded(self):
        raw = b'<!DOCTYPE manifest [<!ENTITY x "unsafe">]>' + self.manifest
        with self.assertRaisesRegex(ValueError, 'Unsafe manifest'):
            package.inspect_package(self.archive(manifest=raw), 'arm')

    def test_catalogue_excludes_emulator_and_is_disabled(self):
        import re
        recipe = json.loads((package.ROOT / 'packaging/tizen/apps2samsung.json').read_text())
        self.assertFalse(recipe['enabled'])
        pattern = recipe['assets'][0]['match']
        self.assertIsNotNone(re.fullmatch(pattern, 'PlezyNG-tizen-arm.tpk'))
        for name in ('PlezyNG-tizen-x64.tpk', 'PlezyNG-tizen-arm-tester.tpk', 'PlezyNG-tizen-arm-signed.tpk',
                     'PlezyNG-tizen-arm.tpk.sha256', 'Other-tizen-arm.tpk'):
            self.assertIsNone(re.fullmatch(pattern, name))

    def test_api_floor_and_launcher_abi_are_checked(self):
        with self.assertRaisesRegex(ValueError, 'Expected API'):
            package.inspect_package(self.archive(manifest=self.manifest.replace(b'api-version="6.0"', b'api-version="2.24.1"')), 'arm')
        with self.assertRaisesRegex(ValueError, 'Wrong architecture'):
            package.inspect_package(self.archive(extra={'bin/plezyng': elf('x64')}), 'arm')
        self.assertEqual(package.inspect_package(self.archive(arch='x64'), 'x64')['minimum_api'], '8.0')

    def test_resign_rejects_digest_mismatch_without_running_signer(self):
        args = SimpleNamespace(package=self.archive(), sha256='0' * 64, arch='arm',
                               security_profile='test', output=self.root / 'signed')
        with patch.object(package, 'run') as signer, self.assertRaisesRegex(ValueError, 'SHA-256'):
            package.resign(args)
        signer.assert_not_called()

    def test_resign_preserves_payload_and_rejects_noop_or_changed_app(self):
        source = self.archive()
        for kind in ('valid', 'noop', 'tampered'):
            args = SimpleNamespace(package=source, sha256=package.sha256(source), arch='arm',
                                   security_profile='test', output=self.root / kind)
            def signer(*command, **kwargs):
                if kind == 'noop':
                    return
                path = Path(command[-1])
                with zipfile.ZipFile(path) as archive:
                    entries = {row.filename: archive.read(row) for row in archive.infolist()}
                entries['author-signature.xml'] = b'<Signature>replacement fixture</Signature>'
                if kind == 'tampered':
                    entries['res/icudtl.dat'] = b'changed app'
                with zipfile.ZipFile(path, 'w') as archive:
                    for name, content in entries.items():
                        archive.writestr(name, content)
            with self.subTest(kind=kind), patch.object(package, 'run', side_effect=signer):
                if kind == 'valid':
                    package.resign(args)
                    report = json.loads((args.output / 'PlezyNG-tizen-arm-signed.tpk.json').read_text())
                    self.assertTrue(report['payload_unchanged'])
                    self.assertFalse(report['tv_install_verified'])
                else:
                    with self.assertRaisesRegex(ValueError, 'no change' if kind == 'noop' else 'changed the application'):
                        package.resign(args)
                    self.assertFalse((args.output / 'PlezyNG-tizen-arm-signed.tpk').exists())

    def test_stage_keeps_overrides_excludes_untracked_and_checks_native_digests(self):
        source, stage, native = [self.root / p for p in ('source', 'stage', 'native')]
        for directory in (source, stage, native):
            directory.mkdir()
        subprocess.run(['git', 'init', '-q', source], check=True)
        files = {
            'pubspec.yaml': 'name: fixture\nversion: 3.4.5+7\ndependencies:\n  pdfrx: ^2.10.1\ndependency_overrides:\n  existing:\n    path: packages/existing\n',
            'tizen/tizen-manifest.xml': self.manifest.decode(),
            'scripts/tizen/smb_build_hook.dart': '// staged hook',
            'scripts/tizen/publication_reader_screen.dart': '// TV reader',
            'assets/plezy.png': 'fixture image',
        }
        for name, content in files.items():
            p = source / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content)
        subprocess.run(['git', '-C', source, 'add', '.'], check=True)
        (source / 'author.p12').write_text('must not copy')
        smb = self.root / 'pub-cache/dart_smb2'
        (smb / 'hook').mkdir(parents=True)
        (smb / 'pubspec.yaml').write_text('name: dart_smb2\nversion: 0.2.3\n')
        (smb / 'hook/build.dart').write_text('// upstream hook')
        (source / '.dart_tool').mkdir()
        (source / '.dart_tool/package_config.json').write_text(json.dumps({'packages': [{'name': 'dart_smb2', 'rootUri': smb.as_uri()}]}))
        report = {'architecture': 'arm', 'pins': package.PINS, 'libraries': {}}
        for name in ('libdart_smb2.so', 'libplezy_sqlite3.so', 'libplezy_torrent.so'):
            p = native / name
            p.write_bytes(elf())
            report['libraries'][name] = package.sha256(p)
        (native / 'native-build.json').write_text(json.dumps(report))
        package.stage(source, stage, native, 'arm')
        pubspec = (stage / 'pubspec.yaml').read_text()
        self.assertIn('path: packages/existing', pubspec)
        self.assertNotIn('pdfrx:', pubspec)
        self.assertEqual((stage / 'lib/screens/sources/publication_reader_screen.dart').read_text(), '// TV reader')
        self.assertIn('path: packages/dart_smb2_tizen', pubspec)
        self.assertFalse((stage / 'author.p12').exists())
        self.assertIn('version="3.4.5"', (stage / 'tizen/tizen-manifest.xml').read_text())
        self.assertIn('api-version="6.0"', (stage / 'tizen/tizen-manifest.xml').read_text())
        self.assertEqual((smb / 'hook/build.dart').read_text(), '// upstream hook')
        self.assertEqual((stage / 'packages/dart_smb2_tizen/hook/build.dart').read_text(), '// staged hook')
        (native / 'libdart_smb2.so').write_bytes(elf() + b'tampered')
        with self.assertRaisesRegex(ValueError, 'Native input mismatch'):
            package.stage(source, self.root / 'invalid-stage', native, 'arm')


if __name__ == '__main__':
    unittest.main()
