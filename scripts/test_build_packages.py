#!/usr/bin/env python3

import configparser
import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
BUILD_PACKAGES = ROOT / "linux/packaging/build-packages.py"
REPOSITORY_PATH = "/etc/yum.repos.d/plezy.repo"
REQUIRED_TOOLS = (
    "fpm",
    "rpm",
)

def load_build_packages():
    spec = importlib.util.spec_from_file_location("build_packages", BUILD_PACKAGES)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {BUILD_PACKAGES}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def assert_repository_behavior(test: unittest.TestCase, contents: str) -> None:
    config = configparser.ConfigParser(interpolation=None)
    config.read_string(contents)
    repository = config["plezy"]
    test.assertTrue(repository.getboolean("enabled"))
    test.assertTrue(repository.getboolean("gpgcheck"))
    test.assertTrue(repository.getboolean("repo_gpgcheck"))
    base_url = urlparse(repository["baseurl"])
    key_url = urlparse(repository["gpgkey"])
    test.assertEqual((base_url.scheme, base_url.netloc, base_url.path), ("https", "plezy.app", "/rpm/$basearch/"))
    test.assertEqual(
        (key_url.scheme, key_url.netloc, key_url.path),
        ("https", "plezy.app", "/rpm/RPM-GPG-KEY-plezy"),
    )

class BuildPackagesTest(unittest.TestCase):
    @unittest.skipIf(
        any(shutil.which(tool) is None for tool in REQUIRED_TOOLS),
        "RPM packaging toolchain is unavailable",
    )
    def test_installing_the_unsigned_rpm_registers_authenticated_updates(self) -> None:
        module = load_build_packages()
        source = ROOT / "linux/packaging"

        with tempfile.TemporaryDirectory(prefix="plezy-package-test-") as directory:
            fixture = Path(directory)
            packaging = fixture / "packaging"
            bundle = fixture / "bundle"
            output = fixture / "output"
            shutil.copytree(source, packaging)
            bundle.mkdir()
            output.mkdir()
            for size in module.ICON_SIZES:
                icon = packaging / f"icons/{size}x{size}/plezy.png"
                icon.parent.mkdir(parents=True, exist_ok=True)
                icon.write_bytes(b"package fixture")
            executable = bundle / "plezy"
            executable.write_text("#!/bin/sh\n", encoding="utf-8")
            executable.chmod(0o755)

            module.SCRIPT_DIR = packaging
            module.BUILD_DIR = bundle
            module.OUTPUT_DIR = output
            module.ARCH_SUFFIX = "x64"
            module.build_package("rpm", "1.2.3")

            rpm_path = output / "plezy-linux-x64.rpm"
            unsigned = subprocess.run(
                ["rpm", "--checksig", str(rpm_path)],
                check=True,
                capture_output=True,
                text=True,
            ).stdout
            self.assertNotIn("signatures OK", unsigned)

            install_root = fixture / "installed"
            (install_root / "var/lib/rpm").mkdir(parents=True)
            subprocess.run(
                ["rpm", "--root", str(install_root), "--dbpath", "/var/lib/rpm", "--initdb"],
                check=True,
                capture_output=True,
            )
            subprocess.run(
                [
                    "rpm",
                    "--root",
                    str(install_root),
                    "--dbpath",
                    "/var/lib/rpm",
                    "--nodeps",
                    "--noscripts",
                    "--install",
                    str(rpm_path),
                ],
                check=True,
                capture_output=True,
            )
            assert_repository_behavior(
                self,
                (install_root / REPOSITORY_PATH.lstrip("/")).read_text(encoding="utf-8"),
            )

if __name__ == "__main__":
    unittest.main()
