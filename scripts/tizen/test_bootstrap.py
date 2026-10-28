"""SDK archives are external inputs; validate extraction boundaries."""
from pathlib import Path
import tempfile
import unittest
import zipfile

import bootstrap_linux


class BootstrapTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def archive(self, name, content=b'fixture', mode=0o100755):
        path = self.root / 'package.zip'
        with zipfile.ZipFile(path, 'w') as archive:
            item = zipfile.ZipInfo(name)
            item.external_attr = mode << 16
            archive.writestr(item, content)
        return path

    def test_preserves_executable_mode_and_ignores_metadata(self):
        bootstrap_linux.extract_package(self.archive('data/tools/compiler'), self.root / 'sdk')
        compiler = self.root / 'sdk/tools/compiler'
        self.assertTrue(compiler.stat().st_mode & 0o111)
        bootstrap_linux.extract_package(self.archive('pkginfo.manifest'), self.root / 'sdk')
        self.assertFalse((self.root / 'sdk/pkginfo.manifest').exists())

    def test_rejects_path_and_symlink_escape(self):
        for name in ('data/../../escape', '/data/escape', 'data/dir\\escape'):
            with self.subTest(name=name), self.assertRaises(ValueError):
                bootstrap_linux.extract_package(self.archive(name), self.root / 'sdk')
        with self.assertRaises(ValueError):
            bootstrap_linux.extract_package(self.archive('data/link', b'../../escape', 0o120777), self.root / 'sdk')

    def test_accepts_internal_relative_symlink(self):
        bootstrap_linux.extract_package(self.archive('data/lib/link.so', b'actual.so', 0o120777), self.root / 'sdk')
        self.assertTrue((self.root / 'sdk/lib/link.so').is_symlink())

    def test_arm_toolchain_passes_pinned_sysroot_during_cmake_compiler_checks(self):
        compiler = self.root / 'tizen sdk/bin/arm-linux-gnueabi-'
        sysroot = self.root / 'tizen sdk/rootstrap/device.core'
        toolchain = self.root / 'arm-toolchain.cmake'

        bootstrap_linux.write_arm_toolchain(toolchain, compiler, sysroot)

        generated = toolchain.read_text()
        expected = f'--sysroot=\\"{sysroot}\\"'
        self.assertIn(f'set(CMAKE_C_FLAGS_INIT "{expected} -march=', generated)
        self.assertIn(f'set(CMAKE_CXX_FLAGS_INIT "{expected} -march=', generated)
        self.assertIn(f'set(CMAKE_SYSROOT "{sysroot}")', generated)


if __name__ == '__main__':
    unittest.main()
