#!/usr/bin/env python3
"""Behavior tests for the package metadata read-back guard.

The guard exists because nothing between build-packages.py and the upload read
anything back out of what fpm wrote: a dropped or renamed `--depends` shipped a
package that installs cleanly and dies in the loader, with every earlier check
green. These tests hold that line, and the substring case below is the specific
regression the shell version it replaced once had - `libegl1` is a substring of
`libegl1-mesa`, so a package declaring neither used to pass.

dpkg-deb, rpm and bsdtar only answer on a machine that has them, so the fixtures
put stubs first on PATH and let the real script fork them. That keeps "an rpm
missing libdrm" a fixture rather than a machine, and keeps every assertion
running against the script CI runs.
"""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

# The Windows-safe stub installer, rather than a second copy of its PATHEXT
# reasoning. scripts/ is sys.path[0] however this file is invoked.
from test_check_bundle_host_deps import install_stub

ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "linux/packaging/check-package-deps.py"
BUILD_PACKAGES = ROOT / "linux/packaging/build-packages.py"

# The expected names come from build-packages.py the same way the guard reads
# them, so a library added there is exercised here without editing a fixture.
_spec = importlib.util.spec_from_file_location("build_packages", BUILD_PACKAGES)
PACKAGING = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(PACKAGING)
DISTROS = PACKAGING.DISTROS
NAME = PACKAGING.METADATA["name"]

# The tool each package format is read with, which is also what the fixtures stub.
TOOLS = {"deb": "dpkg-deb", "rpm": "rpm", "pacman": "bsdtar"}

# One stub per tool: it prints the fixture's answer for its own name, or fails
# the way an unreadable archive does. Baking the name in keeps the stub blind to
# the arguments, so it cannot accidentally pass by echoing its input.
STUB = """import json, os, sys

answers = json.loads(open(os.environ["PLEZY_TEST_ANSWERS"], encoding="utf-8").read())
answer = answers.get({name!r})
if answer is None:
    sys.stderr.write({name!r} + ": cannot read this archive\\n")
    sys.exit(1)
sys.stdout.write(answer)
"""


def declared_first_names(distro: str) -> list[str]:
    """What a correct package declares: one acceptable name per dependency."""
    return [dependency.split("|")[0].strip() for dependency in DISTROS[distro]["depends"]]


def decorate(names: list[str], version: str, qualifier: str) -> list[str]:
    """Dress the first two names the way the real tools report them.

    A constraint, an architecture qualifier and rpm's soname decoration are noise
    around a package name. Applying them to fixture names rather than asserting
    on a hand-written blob means the stripping is tested against the list the
    packages really declare.
    """
    if len(names) < 2:
        return names
    return [f"{names[0]} {version}", f"{names[1]}{qualifier}", *names[2:]]


def deb_metadata(names: list[str] | None = None) -> str:
    """`dpkg-deb -f ... Depends` output."""
    names = declared_first_names("deb") if names is None else names
    return ", ".join(decorate(names, "(>= 3.24.0)", ":amd64")) + "\n"


def rpm_metadata(names: list[str] | None = None) -> str:
    """`rpm -qpR` output, including the requires rpm adds by itself."""
    names = declared_first_names("rpm") if names is None else names
    automatic = ["/bin/sh", "libc.so.6(GLIBC_2.34)(64bit)", "rpmlib(PayloadIsXz) <= 5.2-1"]
    return "\n".join(automatic + decorate(names, ">= 3.24", "(x86-64)")) + "\n"


def pkginfo_metadata(names: list[str] | None = None) -> str:
    """A whole .PKGINFO, so the `depend = ` filter is what isolates the names."""
    names = declared_first_names("pacman") if names is None else names
    header = [f"pkgname = {NAME}", "pkgver = 1.2.3-1", "arch = x86_64"]
    depends = [f"depend = {name}" for name in decorate(names, ">=3.24", "")]
    return "\n".join(header + depends) + "\n"


def correct_metadata() -> dict[str, str]:
    return {"dpkg-deb": deb_metadata(), "rpm": rpm_metadata(), "bsdtar": pkginfo_metadata()}


class PackageDepsReadBackTest(unittest.TestCase):
    def _check(
        self,
        metadata: dict[str, str | None],
        arch: str = "x64",
        produce: tuple[str, ...] = ("deb", "rpm", "pacman"),
        install: tuple[str, ...] = ("dpkg-deb", "rpm", "bsdtar"),
        path: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        """Stage packages plus tool stubs and run the real guard over them."""
        with tempfile.TemporaryDirectory(prefix="plezy-package-deps-test-") as directory:
            staging = Path(directory)
            packages = staging / "packages"
            packages.mkdir()
            for distro in produce:
                (packages / f"{NAME}-linux-{arch}.{DISTROS[distro]['ext']}").write_bytes(b"")

            answers = staging / "answers.json"
            answers.write_text(json.dumps(metadata), encoding="utf-8")
            scripts, tools = staging / "stubs", staging / "tools"
            scripts.mkdir()
            tools.mkdir()
            for tool in install:
                install_stub(scripts, tools, tool, STUB.format(name=tool))

            return subprocess.run(
                [sys.executable, str(CHECKER), str(packages), "--arch", arch],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
                env={
                    **os.environ,
                    # The stubs first, so a machine that really has dpkg-deb
                    # answers from the fixture. `path=""` leaves only the stubs,
                    # which is how a tool is made genuinely absent.
                    "PATH": str(tools) + os.pathsep + (os.environ.get("PATH", "") if path is None else path),
                    "PLEZY_TEST_ANSWERS": str(answers),
                },
            )

    def test_packages_carrying_every_declared_dependency_pass(self) -> None:
        result = self._check(correct_metadata())

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("survived fpm", result.stdout)
        # Version constraints, deb's arch qualifier and rpm's soname decorations
        # are noise around a name, not a different package.
        self.assertNotIn("::error::", result.stderr)

    def test_a_dependency_fpm_dropped_is_named(self) -> None:
        """The regression the guard exists for: a name that reached fpm and not the package."""
        for distro in DISTROS:
            with self.subTest(distro=distro):
                dropped = declared_first_names(distro)[0]
                kept = declared_first_names(distro)[1:]
                metadata = correct_metadata()
                metadata[TOOLS[distro]] = {
                    "deb": deb_metadata,
                    "rpm": rpm_metadata,
                    "pacman": pkginfo_metadata,
                }[distro](kept)

                result = self._check(metadata)

                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn(f"the {distro} package does not require {dropped}", result.stderr)
                self.assertNotIn("survived fpm", result.stdout)

    def test_a_longer_package_name_does_not_satisfy_a_shorter_one(self) -> None:
        """`libegl1-mesa` is not `libegl1`, however much of one it contains."""
        names = [f"{name}-mesa" if name == "libegl1" else name for name in declared_first_names("deb")]
        self.assertIn("libegl1-mesa", names, "the deb list no longer contains libegl1")
        metadata = correct_metadata() | {"dpkg-deb": deb_metadata(names)}

        result = self._check(metadata)

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("the deb package does not require libegl1", result.stderr)

    def test_a_package_fpm_never_wrote_fails(self) -> None:
        result = self._check(correct_metadata(), produce=("deb", "pacman"))

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(f"{NAME}-linux-x64.rpm", result.stderr)
        self.assertIn("was not produced", result.stderr)
        self.assertNotIn("survived fpm", result.stdout)

    def test_an_unreadable_pkginfo_is_not_a_missing_dependency(self) -> None:
        """"the archive member was not found" must stay separable from "fpm dropped everything"."""
        result = self._check(correct_metadata() | {"bsdtar": ""})

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("could not read .PKGINFO", result.stderr)
        self.assertNotIn("does not require", result.stderr)

    def test_a_tool_that_cannot_run_is_a_failure_not_a_pass(self) -> None:
        """A guard that proved nothing must never report that it proved something.

        Both halves matter: a reader absent from the machine, and one present but
        refusing the archive. Either way nothing was read, so nothing is declared.
        """
        for distro, tool in TOOLS.items():
            with self.subTest(missing=tool):
                installed = tuple(name for name in TOOLS.values() if name != tool)
                absent = self._check(correct_metadata(), install=installed, path="")
                self.assertEqual(absent.returncode, 1, absent.stdout)
                self.assertIn(f"{tool} is not installed", absent.stderr)
                self.assertNotIn("survived fpm", absent.stdout)

            with self.subTest(failing=tool):
                broken = self._check(correct_metadata() | {tool: None})
                self.assertEqual(broken.returncode, 1, broken.stdout)
                self.assertIn(f"{tool} failed", broken.stderr)
                self.assertNotIn(f"the {distro} package does not require", broken.stderr)

    def test_the_release_architecture_is_read_from_its_own_files(self) -> None:
        """The release job ships arm64 too, and x64 filenames must not stand in for it."""
        result = self._check(correct_metadata(), arch="arm64")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        missing = self._check(correct_metadata(), arch="x64", produce=())
        self.assertEqual(missing.returncode, 1, missing.stdout)
        self.assertIn(f"{NAME}-linux-x64.deb", missing.stderr)


if __name__ == "__main__":
    unittest.main()
