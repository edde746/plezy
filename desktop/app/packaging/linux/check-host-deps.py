#!/usr/bin/env python3
"""Check that every library the staged Linux app tree needs from the host is a dependency the packages declare.

  check-host-deps.py <tree> --arch x64|arm64

<tree> is stage-image.py's: the app image with plezy.sh and lib/mpv-deps. The app carries JetBrains Runtime, libmpv
and the Ubuntu libraries in lib/mpv-deps, and takes everything else from the host: the C library, the graphics,
Wayland and X11 stack, audio, fonts, VA-API and the libraries libmpv was linked against. A library the packages don't
declare installs cleanly and then fails the app on a system without it, so this derives what the tree needs from the
tree itself and fails on every library build-packages.py's DEPENDS lacks:

- the libraries every ELF object in the tree, and each native library inside its jars that is for this architecture
  (sqlite-jdbc's, which it unpacks at run time), links directly (readelf's NEEDED entries), where ldd resolves them
  with lib/mpv-deps (plezy.sh's) and the runtime's lib/server (where libjvm.so is) on the linker's path. What those
  libraries link in turn is their packages' to declare;
- the libraries loaded by name at run time (DLOPENED), which no ELF header names.

A library resolved inside the tree is the app's own; one that resolves nowhere is an error. For each host library,
dpkg says which deb package provides it, which (or a name it Provides) must be declared; the rpm and pacman packages
that provide it are recorded in OTHER_DISTROS, as this host can't ask Fedora or Arch, and must be declared. A declared
package that provides none of the libraries is an error too: the lists hold what the app needs, nothing else. Runs on
Ubuntu 24.04 (dpkg-query), the release's build host. PLEZY_HOST_TOOLS names a directory searched for readelf, ldd,
ldconfig and dpkg-query ahead of PATH (the tests' stand-ins).
"""

import argparse
import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

from linux_image import ARCHITECTURES, MPV_DEPS, elf_machine

SCRIPT_DIR = Path(__file__).resolve().parent

# The C library and the dynamic linker: every system has them, and no package declares them.
BASELINE = ("linux-vdso.so", "ld-linux", "libc.so", "libm.so", "libpthread.so", "libdl.so", "librt.so", "libmvec.so",
            "libresolv.so", "libnss_")

# Loaded by name at run time (dlopen, or the JDK's FFM SymbolLookup.libraryLookup): libsecret and GLib
# (LibsecretStore), EGL, wayland-egl, wayland-client and X11 (mpv-jvm's video plane and window code), and JetBrains
# Runtime's: fontconfig (its font manager) and, in an X11 session, XRandR (its display modes).
DLOPENED = (
    "libsecret-1.so.0",
    "libglib-2.0.so.0",
    "libEGL.so.1",
    "libwayland-egl.so.1",
    "libwayland-client.so.0",
    "libX11.so.6",
    "libfontconfig.so.1",
    "libXrandr.so.2",
)

# The rpm (Fedora) and pacman (Arch) package that provides each host library.
OTHER_DISTROS = {
    "libEGL.so.1": {"rpm": "libglvnd-egl", "pacman": "libglvnd"},
    "libGL.so.1": {"rpm": "libglvnd-glx", "pacman": "libglvnd"},
    "libX11.so.6": {"rpm": "libX11", "pacman": "libx11"},
    "libXext.so.6": {"rpm": "libXext", "pacman": "libxext"},
    "libXi.so.6": {"rpm": "libXi", "pacman": "libxi"},
    "libXrandr.so.2": {"rpm": "libXrandr", "pacman": "libxrandr"},
    "libXrender.so.1": {"rpm": "libXrender", "pacman": "libxrender"},
    "libXtst.so.6": {"rpm": "libXtst", "pacman": "libxtst"},
    "libasound.so.2": {"rpm": "alsa-lib", "pacman": "alsa-lib"},
    "libdrm.so.2": {"rpm": "libdrm", "pacman": "libdrm"},
    "libfontconfig.so.1": {"rpm": "fontconfig", "pacman": "fontconfig"},
    "libfreetype.so.6": {"rpm": "freetype", "pacman": "freetype2"},
    "libfribidi.so.0": {"rpm": "fribidi", "pacman": "fribidi"},
    "libgbm.so.1": {"rpm": "mesa-libgbm", "pacman": "mesa"},
    "libglib-2.0.so.0": {"rpm": "glib2", "pacman": "glib2"},
    "libgnutls.so.30": {"rpm": "gnutls", "pacman": "gnutls"},
    "libharfbuzz.so.0": {"rpm": "harfbuzz", "pacman": "harfbuzz"},
    "liblcms2.so.2": {"rpm": "lcms2", "pacman": "lcms2"},
    "libpipewire-0.3.so.0": {"rpm": "pipewire-libs", "pacman": "libpipewire"},
    "libpulse.so.0": {"rpm": "pulseaudio-libs", "pacman": "libpulse"},
    "libsecret-1.so.0": {"rpm": "libsecret", "pacman": "libsecret"},
    "libstdc++.so.6": {"rpm": "libstdc++", "pacman": "gcc-libs"},
    "libva-drm.so.2": {"rpm": "libva", "pacman": "libva"},
    "libva-wayland.so.2": {"rpm": "libva", "pacman": "libva"},
    "libva-x11.so.2": {"rpm": "libva", "pacman": "libva"},
    "libva.so.2": {"rpm": "libva", "pacman": "libva"},
    "libwayland-client.so.0": {"rpm": "libwayland-client", "pacman": "wayland"},
    "libwayland-cursor.so.0": {"rpm": "libwayland-cursor", "pacman": "wayland"},
    "libwayland-egl.so.1": {"rpm": "libwayland-egl", "pacman": "wayland"},
    "libxkbcommon.so.0": {"rpm": "libxkbcommon", "pacman": "libxkbcommon"},
    "libz.so.1": {"rpm": "zlib", "pacman": "zlib"},
}

HOST_TOOLS = os.environ.get("PLEZY_HOST_TOOLS")


def run(*command: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
    program, *arguments = command
    located = (shutil.which(program, path=HOST_TOOLS) if HOST_TOOLS else None) or shutil.which(program)
    if located is None:
        raise SystemExit(f"{program} is not installed: this check runs on Ubuntu (readelf, ldd, ldconfig, dpkg-query)")
    return subprocess.run([located, *arguments], capture_output=True, text=True, env=env)


def declared_depends() -> dict[str, list[str]]:
    """build-packages.py's DEPENDS, read from the script rather than written twice."""
    spec = importlib.util.spec_from_file_location("build_packages", SCRIPT_DIR / "build-packages.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.DEPENDS


def objects(tree: Path, machine: int, unpacked: Path) -> list[Path]:
    """The tree's ELF objects, and the native libraries for this architecture in its jars, unpacked into `unpacked`."""
    found = [path for path in sorted(tree.rglob("*")) if path.is_file() and not path.is_symlink() and elf_machine(path)]
    for jar in sorted(tree.rglob("*.jar")):
        with zipfile.ZipFile(jar) as archive:
            for member in archive.namelist():
                if not member.lower().endswith(".so"):
                    continue
                target = unpacked / jar.name / member
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(member))
                if elf_machine(target) == machine:
                    found.append(target)
    return found


def needs(tree: Path, machine: int, arch: str) -> tuple[dict[str, str], list[str]]:
    """soname → host path of each library the tree needs from the host, and the problems found on the way."""
    environment = {**os.environ, "LD_LIBRARY_PATH": f"{tree / MPV_DEPS}:{tree / 'lib' / 'runtime' / 'lib' / 'server'}"}
    host: dict[str, str] = {}
    problems: list[str] = []
    with tempfile.TemporaryDirectory() as unpacked:
        for path in objects(tree, machine, Path(unpacked)):
            name = path.relative_to(unpacked) if path.is_relative_to(unpacked) else path.relative_to(tree)
            header = run("readelf", "-d", str(path))
            if header.returncode != 0:
                problems.append(f"readelf could not read {name}: {header.stderr.strip()}")
                continue
            direct = re.findall(r"\(NEEDED\)\s+Shared library: \[([^]]+)\]", header.stdout)
            if not direct:
                continue
            result = run("ldd", str(path), env=environment)
            if result.returncode != 0:
                problems.append(f"ldd could not read {name}: {result.stderr.strip() or result.stdout.strip()}")
                continue
            resolved = {}
            for line in result.stdout.splitlines():
                soname, separator, rest = line.partition("=>")
                if separator:
                    resolved[soname.strip()] = rest.strip().split(" (")[0]
            for soname in direct:
                if soname.startswith(BASELINE):
                    continue
                library = resolved.get(soname, "not found")
                if not library.startswith("/"):
                    problems.append(f"{name} needs {soname}, which resolves to nothing on this host")
                elif not Path(library).resolve().is_relative_to(tree):
                    host[soname] = library
    tag = {"x64": "x86-64", "arm64": "AArch64"}[arch]
    cache = run("ldconfig", "-p").stdout.splitlines()
    for soname in DLOPENED:
        paths = [line.split("=>")[1].strip() for line in cache
                 if line.strip().startswith(soname + " ") and tag in line and "=>" in line]
        if paths:
            host.setdefault(soname, paths[0])
        else:
            problems.append(f"the app loads {soname} at run time, which this host doesn't have")
    return host, problems


def deb_names(path: str) -> tuple[str, set[str]]:
    """The deb package providing `path` (or the file it links to), and its names: its own and those it Provides."""
    for candidate in (path, str(Path(path).resolve())):
        owner = run("dpkg-query", "-S", candidate).stdout.partition(":")[0].split(",")[0].strip()
        if owner:
            provides = run("dpkg-query", "-W", "-f", "${Provides}", owner).stdout
            return owner, {owner} | {entry.split("(")[0].strip() for entry in provides.split(",") if entry.strip()}
    return "", set()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("tree", type=Path, help="stage-image.py's tree")
    parser.add_argument("--arch", required=True, choices=ARCHITECTURES)
    args = parser.parse_args()
    tree = args.tree.resolve()
    if not (tree / "bin" / "Plezy").is_file() or not (tree / MPV_DEPS).is_dir():
        parser.error(f"{tree} is not a staged app tree (bin/Plezy, {MPV_DEPS})")

    depends = declared_depends()
    host, errors = needs(tree, ARCHITECTURES[args.arch][1], args.arch)
    if not host and not errors:
        errors.append(f"ldd found no host library for {tree} at all, which proves nothing")
    used = {distro: set() for distro in depends}
    owners = {}
    for soname, path in sorted(host.items()):
        owner, names = deb_names(path)
        owners[soname] = owner
        matched = names & set(depends["deb"])
        if not owner:
            errors.append(f"{soname} ({path}) is from no deb package")
        elif not matched:
            errors.append(f"{soname} is from the deb package {owner}, which build-packages.py's DEPENDS['deb'] lacks")
        used["deb"] |= matched
        others = OTHER_DISTROS.get(soname)
        if others is None:
            errors.append(f"{soname}: no rpm or pacman package recorded in check-host-deps.py's OTHER_DISTROS")
            continue
        for distro, package in others.items():
            used[distro].add(package)
            if package not in depends[distro]:
                errors.append(f"{soname} is in the {distro} package {package}, which DEPENDS['{distro}'] lacks")
    for distro, packages in depends.items():
        for package in sorted(set(packages) - used[distro]):
            errors.append(f"DEPENDS['{distro}'] declares {package}, which provides none of the libraries the app needs")

    for error in errors:
        print(f"::error::{error}", file=sys.stderr)
    if errors:
        return 1
    print(f"Every one of the {len(host)} libraries the app needs from the host is declared for deb, rpm and pacman:")
    for soname, owner in owners.items():
        print(f"  {soname:<26} {owner:<24} {OTHER_DISTROS[soname]['rpm']:<20} {OTHER_DISTROS[soname]['pacman']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
