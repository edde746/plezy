#!/usr/bin/env python3
"""Behavior tests for the bundle host dependency guard.

The nested-module case reproduces the bug that motivated them: bundle-libs.sh
installs the dlopen'd gdk-pixbuf loaders and GIO modules into lib/
subdirectories, and the guard scanned lib/*.so* only - so those modules counted
as bundled while their own host dependencies never reached ldd, and the check
reported success over exactly the undeclared library it exists to catch.

ldd and dpkg-query only answer on a Debian-family machine, so the checker
resolves both through PLEZY_HOST_TOOLS and the fixtures here install stubs
there. That keeps "a bundle that needs libpng16" a fixture rather than a
machine, and keeps the tests exercising the real script end to end.
"""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "linux/packaging/check-bundle-host-deps.py"
BUILD_PACKAGES = ROOT / "linux/packaging/build-packages.py"

# A host library whose deb owner and rpm/pacman names build-packages.py all
# declare, so its presence alone never fails a fixture.
DECLARED_SONAME = "libepoxy.so.0"
DECLARED_PATH = "/usr/lib/x86_64-linux-gnu/libepoxy.so.0"
DECLARED_OWNER = "libepoxy0"

# One nothing declares. Chosen from the gdk-pixbuf loaders' real dependencies,
# which is how this class of miss actually reaches a user.
UNDECLARED_SONAME = "libpng16.so.16"
UNDECLARED_PATH = "/usr/lib/x86_64-linux-gnu/libpng16.so.16"
UNDECLARED_OWNER = "libpng16-16"

PIXBUF_LOADER = "lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-png.so"

# Both stubs answer from the JSON the fixture writes. Keeping them as scripts
# rather than mocks means the checker really forks, parses real ldd-shaped
# output and really fails on the exit status it would see in CI.
LDD_STUB = r"""import json, os, sys

answers = json.loads(open(os.environ["PLEZY_TEST_ANSWERS"], encoding="utf-8").read())
for line in answers["ldd"].get(os.path.basename(sys.argv[1]), []):
    print("\t" + line)
"""

DPKG_QUERY_STUB = r"""import json, os, sys

answers = json.loads(open(os.environ["PLEZY_TEST_ANSWERS"], encoding="utf-8").read())
if sys.argv[1] == "-S":
    owner = answers["owners"].get(sys.argv[2], "")
    if not owner:
        sys.stderr.write("dpkg-query: no path found matching pattern %s\n" % sys.argv[2])
        sys.exit(1)
    print("%s: %s" % (owner, sys.argv[2]))
else:
    # dpkg-query -W -f ${Provides} <package>
    sys.stdout.write(answers["provides"].get(sys.argv[-1], ""))
"""


def install_stub(scripts: Path, tools: Path, name: str, source: str) -> None:
    """Put a fake `name` where the checker's PLEZY_HOST_TOOLS lookup will find it.

    The stub itself is Python; the file the checker spawns has to be something
    the platform can execute directly, so it gets a wrapper. The two live in
    different directories because a Windows PATHEXT search would otherwise be
    free to pick the .py over the .bat.
    """
    stub = scripts / f"{name}.py"
    stub.write_text(source, encoding="utf-8")
    if os.name == "nt":
        (tools / f"{name}.bat").write_text(f'@echo off\r\n"{sys.executable}" "{stub}" %*\r\n', encoding="utf-8")
        return
    wrapper = tools / name
    wrapper.write_text(f'#!/bin/sh\nexec "{sys.executable}" "{stub}" "$@"\n', encoding="utf-8")
    wrapper.chmod(0o755)


def stage_bundle(
    staging: Path,
    ldd: dict[str, list[str]],
    owners: dict[str, str],
    shipped: tuple[str, ...] = (),
    install: tuple[str, ...] = ("ldd", "dpkg-query"),
) -> tuple[Path, dict[str, str]]:
    """A synthetic bundle plus host-tool stubs, and the environment that finds them."""
    bundle = staging / "bundle"
    bundle.mkdir()
    (bundle / "plezy").write_bytes(b"")
    for name in shipped:
        library = bundle / name
        library.parent.mkdir(parents=True, exist_ok=True)
        library.write_bytes(b"")

    answers = staging / "answers.json"
    answers.write_text(json.dumps({"ldd": ldd, "owners": owners, "provides": {}}), encoding="utf-8")
    scripts, tools = staging / "stubs", staging / "tools"
    scripts.mkdir()
    tools.mkdir()
    for name, source in (("ldd", LDD_STUB), ("dpkg-query", DPKG_QUERY_STUB)):
        if name in install:
            install_stub(scripts, tools, name, source)

    return bundle, {
        **os.environ,
        "PLEZY_HOST_TOOLS": str(tools),
        "PLEZY_TEST_ANSWERS": str(answers),
    }


class BundleHostDepsGuardTest(unittest.TestCase):
    def _check(
        self,
        ldd: dict[str, list[str]],
        owners: dict[str, str],
        shipped: tuple[str, ...] = (),
        cwd: Path | None = None,
        install: tuple[str, ...] = ("ldd", "dpkg-query"),
        path: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        """Stage a synthetic bundle plus host-tool stubs and run the real checker."""
        with tempfile.TemporaryDirectory(prefix="plezy-bundle-deps-test-") as directory:
            bundle, env = stage_bundle(Path(directory), ldd, owners, shipped, install)
            if path is not None:
                env["PATH"] = path

            return subprocess.run(
                [sys.executable, str(CHECKER), str(bundle)],
                cwd=cwd or ROOT,
                check=False,
                capture_output=True,
                text=True,
                env=env,
            )

    def test_a_bundle_whose_host_libraries_are_all_declared_passes(self) -> None:
        result = self._check(
            ldd={
                "plezy": [
                    # No "=>" on this one: it must not be read as a soname.
                    "linux-vdso.so.1 (0x00007ffd1b3fe000)",
                    f"{DECLARED_SONAME} => {DECLARED_PATH} (0x00007f9c2c000000)",
                    "libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f9c2b800000)",
                    # Resolved from the host copy, but the bundle ships its own.
                    "libmpv.so.2 => /usr/lib/x86_64-linux-gnu/libmpv.so.2 (0x00007f9c2b400000)",
                ],
                "libgiognutls.so": [f"{DECLARED_SONAME} => {DECLARED_PATH} (0x00007f9c2c000000)"],
            },
            owners={DECLARED_PATH: DECLARED_OWNER},
            shipped=("lib/libmpv.so.2", "lib/gio/modules/libgiognutls.so"),
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("every one of the 1 host libraries", result.stdout)

    def test_an_undeclared_host_library_is_named(self) -> None:
        result = self._check(
            ldd={"plezy": [f"{UNDECLARED_SONAME} => {UNDECLARED_PATH} (0x00007f9c2c000000)"]},
            owners={UNDECLARED_PATH: UNDECLARED_OWNER},
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(UNDECLARED_SONAME, result.stderr)
        self.assertIn(f"deb package '{UNDECLARED_OWNER}'", result.stderr)

    def test_a_library_declared_for_deb_but_not_for_rpm_is_still_rejected(self) -> None:
        """Every other negative fixture fails on the Debian arm first.

        Fedora and Arch names cannot be resolved on this runner, so they are the
        half most likely to be forgotten - and a package that installs on Fedora
        and then cannot start is exactly as broken as one that fails on Debian.
        libGLESv2 is the live example: it is mapped to libglvnd-gles, which is
        deliberately not declared because nothing links GLES today, so the moment
        something does the guard has to say so rather than wave it through on the
        strength of a satisfied deb dependency.
        """
        soname = "libGLESv2.so.2"
        path = f"/usr/lib/x86_64-linux-gnu/{soname}"
        result = self._check(
            ldd={"plezy": [f"{soname} => {path} (0x00007f9c2c000000)"]},
            # Owned by a package the deb list does declare, so only the non-deb
            # half can be what rejects this.
            owners={path: "libegl1"},
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("libglvnd-gles", result.stderr)
        self.assertIn("rpm", result.stderr)
        # Proving the deb arm was satisfied, so the rejection came from the other.
        self.assertNotIn("comes from deb package", result.stderr)

    def test_a_walk_that_finds_nothing_is_not_a_pass(self) -> None:
        """An empty result means the walk failed, not that nothing is needed.

        bundle-libs.sh always leaves the graphics stack to the host, so a real
        bundle cannot need zero host libraries. Reporting success here would make
        every later breakage invisible, which is the worst thing a guard can do.
        """
        result = self._check(ldd={"plezy": []}, owners={})

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("proved nothing", result.stderr)

    def test_a_library_reached_only_through_a_nested_module_is_still_checked(self) -> None:
        """The gdk-pixbuf loaders sit two directories below lib/, and dlopen finds them.

        Nothing else in the bundle links libpng, so a scan that stops at
        lib/*.so* sees a fully declared bundle and a user sees the loader fail.
        """
        result = self._check(
            ldd={
                "plezy": [f"{DECLARED_SONAME} => {DECLARED_PATH} (0x00007f9c2c000000)"],
                "libpixbufloader-png.so": [f"{UNDECLARED_SONAME} => {UNDECLARED_PATH} (0x00007f9c2b000000)"],
            },
            owners={DECLARED_PATH: DECLARED_OWNER, UNDECLARED_PATH: UNDECLARED_OWNER},
            shipped=(PIXBUF_LOADER,),
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(UNDECLARED_SONAME, result.stderr)

    def test_a_nested_module_cannot_satisfy_a_top_level_dependency(self) -> None:
        """Only lib/ is on the loader path, so only lib/ can make a soname bundled.

        plezy carries RPATH $ORIGIN/lib and plezy.sh exports $INSTALL_DIR/lib.
        The gdk-pixbuf loaders two directories below are opened by explicit
        path and resolve nothing for the executable, so a module whose basename
        happens to equal a host soname must not suppress it - otherwise the
        package under-declares and the check still passes.
        """
        result = self._check(
            ldd={
                "plezy": [
                    f"{DECLARED_SONAME} => {DECLARED_PATH} (0x00007f9c2c000000)",
                    f"{UNDECLARED_SONAME} => {UNDECLARED_PATH} (0x00007f9c2b000000)",
                ]
            },
            owners={DECLARED_PATH: DECLARED_OWNER, UNDECLARED_PATH: UNDECLARED_OWNER},
            shipped=(f"lib/gdk-pixbuf-2.0/2.10.0/loaders/{UNDECLARED_SONAME}",),
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(UNDECLARED_SONAME, result.stderr)
        self.assertIn(f"deb package '{UNDECLARED_OWNER}'", result.stderr)

    def test_a_soname_the_bundle_ships_is_not_a_missing_dependency(self) -> None:
        """ldd on a bundled library in isolation cannot see its siblings.

        Bundled objects carry no RUNPATH - bundle-libs.sh copies and strips - so
        a library that exists nowhere but the bundle reads as `not found` when
        ldd is pointed at one of them directly. At runtime the executable's own
        $ORIGIN/lib resolves it. libshaderc_shared is the real instance: no
        distro package ships it, which is why both workflows copy it by hand, so
        faulting it here would fail the release for a library that is present.
        """
        result = self._check(
            ldd={
                "plezy": [f"{DECLARED_SONAME} => {DECLARED_PATH} (0x00007f9c2c000000)"],
                # The bundled libmpv needs a bundled shaderc, and sees nothing.
                "libmpv.so.2": ["libshaderc_shared.so.1 => not found"],
            },
            owners={DECLARED_PATH: DECLARED_OWNER},
            shipped=("lib/libmpv.so.2", "lib/libshaderc_shared.so.1"),
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("resolves to nothing", result.stderr)

    def test_a_library_that_resolves_to_nothing_fails(self) -> None:
        """`=> not found` is the failure this check exists to prevent, already happened."""
        result = self._check(
            ldd={"libplezyextra.so.1": ["libfoo.so.1 => not found"]},
            owners={},
            shipped=("lib/libplezyextra.so.1",),
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("libfoo.so.1", result.stderr)
        self.assertIn("resolves to nothing", result.stderr)

    def test_the_checker_reads_build_packages_from_any_working_directory(self) -> None:
        """--root defaulted to cwd, so running the check from the build tree crashed."""
        result = self._check(
            ldd={"plezy": [f"{DECLARED_SONAME} => {DECLARED_PATH} (0x00007f9c2c000000)"]},
            owners={DECLARED_PATH: DECLARED_OWNER},
            cwd=Path(tempfile.gettempdir()),
        )

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_a_host_without_dpkg_query_fails_instead_of_passing(self) -> None:
        """Fedora and Arch have no dpkg-query, so the check cannot run there.

        Every answer it gives comes from ldd and dpkg-query. Missing one, the
        walk would find nothing and report a bundle needing nothing from the
        host - so the absence has to be an error the reader can act on, never a
        skip and never a traceback.
        """
        result = self._check(
            ldd={"plezy": [f"{DECLARED_SONAME} => {DECLARED_PATH} (0x00007f9c2c000000)"]},
            owners={DECLARED_PATH: DECLARED_OWNER},
            install=("ldd",),
            path="",
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("dpkg-query not found", result.stderr)
        self.assertIn("Debian or Ubuntu host", result.stderr)
        self.assertNotIn("Traceback", result.stderr)


class BuildPackagesGuardWiringTest(unittest.TestCase):
    """build-packages.py is the only path a maintainer packaging by hand takes.

    CI ran the guard as its own step, so the script itself never did, and its own
    error message invited the standalone path that skipped it.
    """

    def test_an_undeclared_host_library_stops_packaging(self) -> None:
        with tempfile.TemporaryDirectory(prefix="plezy-packaging-test-") as directory:
            staging = Path(directory)
            bundle, env = stage_bundle(
                staging,
                ldd={"plezy": [f"{UNDECLARED_SONAME} => {UNDECLARED_PATH} (0x00007f9c2c000000)"]},
                owners={UNDECLARED_PATH: UNDECLARED_OWNER},
                shipped=("lib/libmpv.so.2",),
            )
            output = staging / "packages"
            output.mkdir()
            env |= {"BUILD_DIR": str(bundle), "OUTPUT_DIR": str(output)}

            result = subprocess.run(
                [sys.executable, str(BUILD_PACKAGES)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
                env=env,
            )
            produced = sorted(path.name for path in output.iterdir())

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(UNDECLARED_SONAME, result.stderr)
        self.assertIn("no packages were built", result.stdout)
        self.assertEqual(produced, [])

    def test_the_opt_out_says_out_loud_what_it_costs(self) -> None:
        """The escape hatch for dpkg-query-less hosts must announce itself.

        A skip nobody can see in the log is indistinguishable from the guard
        having passed, which is the whole failure this wiring removes.
        """
        with tempfile.TemporaryDirectory(prefix="plezy-packaging-optout-test-") as directory:
            staging = Path(directory)
            # A copy, not the checkout's script: past this point main() writes
            # generated icons next to itself, and a test has no business dirtying
            # the working tree. Everything under test happens before that, and the
            # copy's missing sibling guard would fail loudly if it did run.
            packaging = staging / "linux/packaging"
            packaging.mkdir(parents=True)
            script = packaging / BUILD_PACKAGES.name
            script.write_text(BUILD_PACKAGES.read_text(encoding="utf-8"), encoding="utf-8")
            bundle = staging / "bundle"
            (bundle / "lib").mkdir(parents=True)
            (bundle / "lib/libmpv.so.2").write_bytes(b"")

            result = subprocess.run(
                [sys.executable, str(script)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
                env={
                    **os.environ,
                    "BUILD_DIR": str(bundle),
                    "OUTPUT_DIR": str(staging / "packages"),
                    "PLEZY_SKIP_HOST_DEP_CHECK": "1",
                },
            )

        self.assertIn("PLEZY_SKIP_HOST_DEP_CHECK is set", result.stdout)
        self.assertIn("unverified", result.stdout)

    def test_a_falsey_opt_out_does_not_skip(self) -> None:
        """`=0` means "do not skip" to almost everyone, and must behave that way.

        A bare non-empty test would read `0`, `false` and `no` as consent, which
        is the exact opposite of what the person typing them meant - and hands
        back the unverified package this wiring exists to withhold.
        """
        for value in ("0", "false", "no", "off", ""):
            with self.subTest(value=value), tempfile.TemporaryDirectory(prefix="plezy-packaging-falsey-") as directory:
                staging = Path(directory)
                packaging = staging / "linux/packaging"
                packaging.mkdir(parents=True)
                script = packaging / BUILD_PACKAGES.name
                script.write_text(BUILD_PACKAGES.read_text(encoding="utf-8"), encoding="utf-8")
                bundle = staging / "bundle"
                (bundle / "lib").mkdir(parents=True)
                (bundle / "lib/libmpv.so.2").write_bytes(b"")

                result = subprocess.run(
                    [sys.executable, str(script)],
                    cwd=ROOT,
                    check=False,
                    capture_output=True,
                    text=True,
                    env={
                        **os.environ,
                        "BUILD_DIR": str(bundle),
                        "OUTPUT_DIR": str(staging / "packages"),
                        "PLEZY_SKIP_HOST_DEP_CHECK": value,
                    },
                )

                self.assertNotIn("PLEZY_SKIP_HOST_DEP_CHECK is set", result.stdout)
                # The guard ran, so packaging stopped on its verdict rather than
                # continuing past an unverified bundle.
                self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
