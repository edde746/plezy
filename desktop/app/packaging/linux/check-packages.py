#!/usr/bin/env python3
"""Read back the packages build-packages.py wrote and check what they say against what it declares.

  check-packages.py <dir> --arch x64|arm64 --version X.Y.Z

For plezy-linux-<arch>.deb, .rpm and .pkg.tar.zst: the package's name, version (iteration 1) and architecture, its
dependencies, exactly build-packages.py's DEPENDS (a flag fpm dropped would leave a package that installs and then
can't start), its install and remove scripts, and the files every install needs (FILES: the launcher, libmpv and
lib/mpv-deps, the wrapper as /usr/bin/plezy, the desktop entry, the metainfo, the icons). For plezy-linux-<arch>.tar.gz:
the tree at its root (TARBALL_FILES). Needs dpkg-deb, rpm and bsdtar.
"""

import argparse
import importlib.util
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile

from linux_image import APP_ID, ARCHITECTURES, MPV_DEPS, UBUNTU_LIBS

SCRIPT_DIR = Path(__file__).resolve().parent
ARCH_TRIPLES = {"x64": "x86_64-linux-gnu", "arm64": "aarch64-linux-gnu"}


def packaging():
    spec = importlib.util.spec_from_file_location("build_packages", SCRIPT_DIR / "build-packages.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def tree_files(arch: str) -> list[str]:
    """What the staged tree holds that every install needs, relative to its root."""
    return [
        "plezy.sh",
        "bin/Plezy",
        "lib/app/Plezy.cfg",
        "lib/runtime/lib/server/libjvm.so",
        f"lib/app/resources/mpv/lib/{ARCH_TRIPLES[arch]}/libmpv.so.2",
        *(f"{MPV_DEPS}/{soname}" for soname in UBUNTU_LIBS),
    ]


def package_files(arch: str, icon_sizes) -> list[str]:
    """The absolute paths every package installs that an install needs."""
    return [
        *(f"/opt/plezy/{path}" for path in tree_files(arch)),
        "/usr/bin/plezy",
        f"/usr/share/applications/{APP_ID}.desktop",
        f"/usr/share/metainfo/{APP_ID}.metainfo.xml",
        *(f"/usr/share/icons/hicolor/{size}x{size}/apps/plezy.png" for size in icon_sizes),
    ]


def run(*command: str) -> str:
    if shutil.which(command[0]) is None:
        raise SystemExit(f"{command[0]} is not installed")
    return subprocess.run(command, capture_output=True, text=True, check=True).stdout


def read_deb(package: Path) -> dict:
    fields = {name: run("dpkg-deb", "-f", str(package), name).strip() for name in ("Package", "Version", "Architecture", "Depends")}
    files = {re.sub(r" -> .*$", "", line.split(None, 5)[5]).removeprefix(".") for line in run("dpkg-deb", "-c", str(package)).splitlines()}
    # dpkg-deb -I lists the control members, the maintainer scripts among them.
    info = run("dpkg-deb", "-I", str(package))
    return {
        "identity": (fields["Package"], fields["Version"], fields["Architecture"]),
        "depends": {entry.strip() for entry in fields["Depends"].split(",") if entry.strip()},
        "files": {path.rstrip("/") for path in files},
        "scripts": {name for name in ("postinst", "postrm") if re.search(rf"\s{name}\s", info)},
    }


def read_rpm(package: Path) -> dict:
    name, version, release, arch = run("rpm", "-qp", "--qf", "%{NAME}\n%{VERSION}\n%{RELEASE}\n%{ARCH}\n", str(package)).split()
    requires = {line.split()[0] for line in run("rpm", "-qpR", str(package)).splitlines() if line.strip()}
    scripts = run("rpm", "-qp", "--scripts", str(package))
    return {
        "identity": (name, f"{version}-{release}", arch),
        # rpmbuild's own requirements (its features, the scripts' shell) are not the app's.
        "depends": {entry for entry in requires if not entry.startswith(("rpmlib(", "/bin/sh"))},
        "files": set(run("rpm", "-qpl", str(package)).splitlines()),
        "scripts": {name for name, header in (("postinst", "postinstall scriptlet"), ("postrm", "postuninstall scriptlet"))
                    if header in scripts},
    }


def read_pacman(package: Path) -> dict:
    pkginfo = run("bsdtar", "-xOf", str(package), ".PKGINFO")
    values: dict[str, list[str]] = {}
    for line in pkginfo.splitlines():
        key, separator, value = line.partition(" = ")
        if separator:
            values.setdefault(key, []).append(value)
    members = set(run("bsdtar", "-tf", str(package)).splitlines())
    install = run("bsdtar", "-xOf", str(package), ".INSTALL") if ".INSTALL" in members else ""
    return {
        "identity": (values["pkgname"][0], values["pkgver"][0], values["arch"][0]),
        "depends": set(values.get("depend", [])),
        "files": {"/" + member.rstrip("/") for member in members if not member.startswith(".")},
        "scripts": {name for name, function in (("postinst", "post_install"), ("postrm", "post_remove")) if function in install},
    }


READERS = {"deb": read_deb, "rpm": read_rpm, "pacman": read_pacman}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--arch", required=True, choices=ARCHITECTURES)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()
    module = packaging()
    name = module.METADATA["name"]
    errors = []
    for distro, config in module.FORMATS.items():
        package = args.directory / f"{name}-linux-{args.arch}.{config['ext']}"
        if not package.is_file():
            errors.append(f"{package} was not written")
            continue
        found = READERS[distro](package)
        expected = (name, f"{args.version}-1", config["arch"][args.arch])
        if found["identity"] != expected:
            errors.append(f"{package.name} is {found['identity']}, not {expected}")
        declared = set(module.DEPENDS[distro])
        if found["depends"] != declared:
            errors.append(f"{package.name} depends on {sorted(found['depends'])}, not DEPENDS['{distro}'] "
                          f"(missing {sorted(declared - found['depends'])}, extra {sorted(found['depends'] - declared)})")
        for path in package_files(args.arch, module.ICON_SIZES):
            if path not in found["files"]:
                errors.append(f"{package.name} lacks {path}")
        for script in ("postinst", "postrm"):
            if script not in found["scripts"]:
                errors.append(f"{package.name} has no {script} script")
        print(f"{package.name}: {' '.join(found['identity'])}, {len(found['files'])} files, depends {' '.join(sorted(found['depends']))}")

    tarball = args.directory / f"{name}-linux-{args.arch}.tar.gz"
    if tarball.is_file():
        with tarfile.open(tarball) as archive:
            members = set(archive.getnames())
        for path in tree_files(args.arch):
            if path not in members:
                errors.append(f"{tarball.name} lacks {path}")
        print(f"{tarball.name}: {len(members)} entries")
    else:
        errors.append(f"{tarball} was not written")

    for error in errors:
        print(f"::error::{error}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
