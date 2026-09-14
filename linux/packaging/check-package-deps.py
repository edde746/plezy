#!/usr/bin/env python3
"""Read the declared dependencies back out of the packages fpm just produced.

check-bundle-host-deps.py proves the depends lists in build-packages.py cover
every library the staged bundle loads from the host. Nothing proved those lists
survived fpm. A renamed flag or a dropped `--depends` produces a package that
installs cleanly and then dies in the loader before main(), with every earlier
check green - and only the artifact itself can show it. So this reads the
dependency metadata out of the finished .deb, .rpm and .pkg.tar.zst and fails
when a dependency build-packages.py declares is missing from any of them.

Every name comes from build-packages.py, so adding a library there is verified
here without a second edit. The release job and the package smoke build both run
this against the packages they built, which is why the assertions live here
rather than inline in two workflows that drift apart.
"""

import argparse
import importlib.util
import re
import shutil
import subprocess
import sys
from pathlib import Path

# The checkout this script lives in, derived from its own location so the
# packages may be anywhere; --root stays as the override.
PROJECT_ROOT = Path(__file__).resolve().parents[2]


class Unreadable(Exception):
    """A package whose dependency metadata could not be read at all.

    Kept distinct from "the metadata says nothing depends on X": a missing tool
    or an unreadable archive proves nothing, and must never be reported as a
    package that simply declared everything.
    """


def run(*command: str) -> str:
    program, *arguments = command
    # Resolved once and forked by full path, so what was probed for existence is
    # exactly what ran.
    resolved = shutil.which(program)
    if resolved is None:
        raise Unreadable(f"{program} is not installed, so this package's metadata cannot be read")
    result = subprocess.run([resolved, *arguments], capture_output=True, text=True)
    if result.returncode != 0:
        raise Unreadable(f"{program} failed: {result.stderr.strip() or result.stdout.strip() or 'no diagnostic'}")
    return result.stdout


def load_packaging(root: Path):
    """build-packages.py itself, so the expected names are never re-typed here."""
    spec = importlib.util.spec_from_file_location("build_packages", root / "linux/packaging/build-packages.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read_metadata(distro: str, package: Path) -> str:
    """The dependency text the built package carries, in its own format."""
    if distro == "deb":
        return run("dpkg-deb", "-f", str(package), "Depends")
    if distro == "rpm":
        return run("rpm", "-qpR", str(package))
    if distro == "pacman":
        # A pattern, not a literal name: fpm's pacman writer may store the entry
        # as `.PKGINFO` or `./.PKGINFO`. Guard the extraction rather than the
        # filtered list, so "the archive member was not found" stays separable
        # from "fpm dropped every dependency" - the second is the regression this
        # script exists to name, and it has to reach the comparison below.
        pkginfo = run("bsdtar", "-xOf", str(package), "--include", "*.PKGINFO")
        if not pkginfo.strip():
            raise Unreadable("could not read .PKGINFO out of the pacman package")
        return "\n".join(line.removeprefix("depend = ") for line in pkginfo.splitlines() if line.startswith("depend = "))
    # An unrecognised format is an error, not a skip: a distro added to DISTROS
    # without a reader here would otherwise ship entirely unverified.
    raise Unreadable(f"no reader for the {distro} package format is recorded in {Path(__file__).name}")


def declared_names(blob: str) -> set[str]:
    """Every package name the metadata requires, without version constraints.

    Names, not a substring search over the whole blob: `libegl1` is a substring
    of `libegl1-mesa`, so a package that declared neither used to pass on the
    strength of some unrelated longer dependency. Split on the separators all
    three formats use, then drop version constraints, rpm's soname decorations
    and deb's architecture qualifier.
    """
    found = set()
    for token in re.split(r"[,|\s]+", blob):
        name = re.sub(r"[<>=].*$", "", token).split("(")[0].split(":")[0]
        if name:
            found.add(name)
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("directory", type=Path, help="where build-packages.py wrote the packages")
    parser.add_argument("--arch", default="x64", help="the ARCH_SUFFIX the packages were built with")
    parser.add_argument("--root", type=Path, default=PROJECT_ROOT, help="repository root")
    arguments = parser.parse_args()

    packaging = load_packaging(arguments.root)
    errors: list[str] = []
    # An empty roster would walk no packages and still print success, which is
    # the one verdict a guard must never reach without evidence.
    if not packaging.DISTROS:
        errors.append("build-packages.py defines no package formats, so there was nothing to read back")

    for distro, config in packaging.DISTROS.items():
        package = arguments.directory / f"{packaging.METADATA['name']}-linux-{arguments.arch}.{config['ext']}"
        if not package.is_file():
            errors.append(f"{package} was not produced")
            continue

        try:
            metadata = read_metadata(distro, package)
        except Unreadable as failure:
            errors.append(f"{package.name}: {failure}")
            continue

        print(f"{distro}: {' '.join(metadata.split()) or '(nothing)'}")
        # A format that declares nothing cannot be checked against the package,
        # so emptying the list would otherwise turn this guard into a no-op.
        if not config["depends"]:
            errors.append(f"build-packages.py declares no dependencies for {distro}, so this proved nothing")
            continue

        declared = declared_names(metadata)
        for dependency in config["depends"]:
            # `libmpv2 | libmpv1` is one dependency with two acceptable names.
            if not any(name.strip() in declared for name in dependency.split("|")):
                errors.append(f"the {distro} package does not require {dependency}")

    for error in errors:
        print(f"::error::{error}", file=sys.stderr)
    if errors:
        return 1

    print(f"every dependency build-packages.py declares survived fpm into all {len(packaging.DISTROS)} packages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
