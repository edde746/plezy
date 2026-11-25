#!/usr/bin/env python3
"""Assemble the Linux app tree the deb, rpm and pacman packages, the portable tarball and the AppImage are cut from.

  stage-image.py --app <image dir> --arch x64|arm64 --output <dir>

Writes <dir>/plezy: the app image as built (createReleaseDistributable's Plezy/), plezy.sh at its root (the packages
install it as /usr/bin/plezy; the tarball's and the AppImage's entry point), and in lib/mpv-deps the Ubuntu libraries
libmpv links under Ubuntu's sonames (linux_image.UBUNTU_LIBS), as this host resolves libmpv's dependencies: run it on
Ubuntu 24.04, where mpv-build builds libmpv, with those packages installed. Each must come from its Ubuntu package,
whose copyright file must be the one the image carries among its licence texts. Then check-host-deps.py checks that
every library the tree needs from the host is one the packages declare, and fails the run otherwise.
"""

import argparse
from pathlib import Path
import shutil
import subprocess
import sys

from linux_image import ARCHITECTURES, MPV_DEPS, UBUNTU_LIBS, check_image, elf_machine, notice_problem

SCRIPT_DIR = Path(__file__).resolve().parent


def resolved(library: Path) -> dict[str, str]:
    """soname → path for the dependencies of `library` the dynamic linker finds on this host (ldd)."""
    result = subprocess.run(["ldd", str(library)], capture_output=True, text=True, check=True)
    found = {}
    for line in result.stdout.splitlines():
        soname, separator, rest = line.partition("=>")
        path = rest.strip().split(" (")[0]
        if separator and path.startswith("/"):
            found[soname.strip()] = path
    return found


def deb_owner(path: str) -> str:
    """The deb package that installed `path` (or the file it links to), without its architecture; empty if none."""
    for candidate in (path, str(Path(path).resolve())):
        owner = subprocess.run(["dpkg-query", "-S", candidate], capture_output=True, text=True).stdout
        if owner:
            return owner.partition(":")[0].split(",")[0].strip()
    return ""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--app", required=True, type=Path, help="the app image (createReleaseDistributable's Plezy/)")
    parser.add_argument("--arch", required=True, choices=ARCHITECTURES)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    machine = ARCHITECTURES[args.arch][1]

    app = args.app.resolve()
    for problem in check_image(app, args.arch):
        parser.error(problem)
    libmpv = sorted((app / "lib" / "app" / "resources" / "mpv").rglob("libmpv.so.2"))[0]
    host = resolved(libmpv)
    libraries = {}
    for soname, (package, folder) in UBUNTU_LIBS.items():
        path = host.get(soname)
        if path is None:
            parser.error(f"libmpv needs {soname}, which this host doesn't have: install Ubuntu's {package}")
        if elf_machine(Path(path).resolve()) != machine:
            parser.error(f"{path} is not a library for {args.arch}")
        owner = deb_owner(path)
        if owner != package:
            parser.error(f"{path} is from {owner or 'no deb package'}, not Ubuntu's {package}")
        problem = notice_problem(app, package, folder, Path("/usr/share/doc") / package / "copyright")
        if problem:
            parser.error(problem)
        libraries[soname] = Path(path).resolve()

    tree = args.output.resolve() / "plezy"
    if tree.exists():
        parser.error(f"{tree} exists")
    shutil.copytree(app, tree, symlinks=True)
    shutil.copyfile(SCRIPT_DIR / "plezy.sh", tree / "plezy.sh")
    (tree / "plezy.sh").chmod(0o755)
    (tree / MPV_DEPS).mkdir()
    for soname, library in libraries.items():
        shutil.copyfile(library, tree / MPV_DEPS / soname)
        (tree / MPV_DEPS / soname).chmod(0o644)

    subprocess.run([sys.executable, str(SCRIPT_DIR / "check-host-deps.py"), str(tree), "--arch", args.arch], check=True)
    print(f"Staged: {tree}")


if __name__ == "__main__":
    main()
