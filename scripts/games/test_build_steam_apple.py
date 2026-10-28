"""Apple archive transaction checks; these do not substitute for an SDK build."""
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import build_steam_apple as builder


class AppleArchiveTest(unittest.TestCase):
    def exercise(self, platform='macosx', architectures='arm64 x86_64', fail=None):
        with tempfile.TemporaryDirectory() as temporary:
            derived = Path(temporary)
            destination = derived / 'plezy-steam'
            destination.mkdir()
            final = destination / 'libplezy_steam.a'
            final.write_bytes(b'previous verified archive')
            commands = []

            def run(*args):
                commands.append(args)
                if args[:2] == ('/usr/bin/cmake', '--build'):
                    directory = Path(args[2])
                    for name in ('libplezy_steam_runtime.a', 'libplezy_ihs.a',
                                 'libplezy_protobuf_c.a', 'libplezy_pyrowave_metal.a',
                                 'opus/libopus.a', 'mbedtls/library/libmbedcrypto.a',
                                 'mbedtls/3rdparty/everest/libeverest.a',
                                 'mbedtls/3rdparty/p256-m/libp256m.a'):
                        if fail == 'missing crypto' and name.endswith('libeverest.a'):
                            continue
                        archive = directory / name
                        archive.parent.mkdir(parents=True, exist_ok=True)
                        archive.write_bytes(b'architecture archive')
                if args[:2] == ('xcrun', 'libtool'):
                    Path(args[args.index('-o') + 1]).write_bytes(b'combined architecture')
                if args[:3] == ('xcrun', 'lipo', '-create'):
                    Path(args[-1]).write_bytes(b'new universal archive')
                if '-verify_arch' in args and fail == 'architecture mismatch':
                    raise subprocess.CalledProcessError(1, args)

            environment = {'PLATFORM_NAME': platform, 'ARCHS': architectures,
                           'DERIVED_FILE_DIR': str(derived)}
            with patch.dict(builder.os.environ, environment, clear=True), \
                    patch.object(builder.shutil, 'which', return_value='/usr/bin/cmake'), \
                    patch.object(builder.subprocess, 'check_output', return_value='/SDKs/Apple.sdk\n'), \
                    patch.object(builder, 'run', side_effect=run):
                if fail:
                    with self.assertRaises((SystemExit, subprocess.CalledProcessError)):
                        builder.build()
                    self.assertEqual(final.read_bytes(), b'previous verified archive')
                else:
                    builder.build()
                    self.assertEqual(final.read_bytes(), b'new universal archive')
            return commands

    def test_universal_archive_includes_crypto_dependencies_for_each_architecture(self):
        commands = self.exercise()
        combines = [command for command in commands if command[:2] == ('xcrun', 'libtool')]
        self.assertEqual(len(combines), 2)
        for arch, command in zip(('arm64', 'x86_64'), combines):
            self.assertTrue(any(f'macosx-{arch}/mbedtls/3rdparty/everest/libeverest.a' in p for p in command))
            self.assertTrue(any(f'macosx-{arch}/mbedtls/3rdparty/p256-m/libp256m.a' in p for p in command))
        self.assertEqual(commands[-1][-3:], ('-verify_arch', 'arm64', 'x86_64'))

    def test_missing_crypto_dependency_preserves_previous_archive(self):
        commands = self.exercise(fail='missing crypto')
        self.assertFalse(any(command[:2] == ('xcrun', 'lipo') for command in commands))

    def test_wrong_architecture_preserves_previous_archive(self):
        self.exercise(fail='architecture mismatch')

    def test_device_rejects_intel_before_fetch_or_build(self):
        commands = self.exercise(platform='iphoneos', architectures='x86_64', fail='bad architecture')
        self.assertEqual(commands, [])

    def test_each_apple_sdk_has_an_isolated_build_directory(self):
        for platform in ('iphoneos', 'iphonesimulator', 'appletvos', 'appletvsimulator'):
            with self.subTest(platform=platform):
                commands = self.exercise(platform=platform, architectures='arm64')
                build = next(c for c in commands if c[:2] == ('/usr/bin/cmake', '--build'))
                self.assertEqual(Path(build[2]).name, f'{platform}-arm64')


if __name__ == '__main__':
    unittest.main()
