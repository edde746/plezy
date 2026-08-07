#!/usr/bin/env python3
"""Check that every library the built bundle needs from the host is declared.

bundle-libs.sh ships most of what the app links, but deliberately leaves the
graphics stack, the audio stack and the C runtime to the host: those are coupled
to the running compositor, the GPU driver and the kernel, so a bundled copy is
worse than useless. Everything it leaves behind has to be named as a package
dependency instead. Miss one and the loader fails before main() runs - which is
invisible to any amount of reading package metadata, and invisible to CI unless
something derives the requirement from the artifact.

That matters more than it used to. libmpv now travels inside the package instead
of being depended on, because the plane needs the pinned Wayland-enabled build.
The host `mpv` dependency that went away had been quietly providing libva, libdrm
and their friends transitively.

The deb answer is derived, not written down: dpkg owns the authoritative mapping
from a file to the package providing it, so a library that appears in the bundle
cannot slip past by being absent from a list someone forgot to update. rpm and
pacman names cannot be resolved on a Debian-family runner, so those stay
recorded below; their job is to fail loudly when a new library lands and nobody
thought about Fedora and Arch.

Coverage is checked in one direction only. A declared dependency that nothing
links is harmless - it installs a package the user probably has. A linked
library that nothing declares is a broken install, so that is the direction
worth failing on.
"""

import argparse
import importlib.util
import os
import subprocess
import sys
from pathlib import Path

# Sonames provided by the base system on every distro. No package declares a
# dependency on the C runtime or the dynamic loader; they are the floor that
# has to exist for dpkg itself to run.
BASELINE_PREFIXES = (
    "linux-vdso.so",
    "ld-linux",
    "libc.so",
    "libm.so",
    "libpthread.so",
    "libdl.so",
    "librt.so",
    "libmvec.so",
    "libresolv.so",
    "libnss_",
)

# The non-deb package that provides each host soname. Fedora and Arch cannot be
# queried from here, so this is the one place where those names are asserted
# rather than derived - and an unlisted soname is an error, so adding a library
# forces the decision instead of silently shipping a package that cannot start.
OTHER_DISTROS = {
    "libEGL.so.1": {"rpm": "libglvnd-egl", "pacman": "libglvnd"},
    "libGL.so.1": {"rpm": "libglvnd-glx", "pacman": "libglvnd"},
    "libGLESv2.so.2": {"rpm": "libglvnd-egl", "pacman": "libglvnd"},
    "libGLX.so.0": {"rpm": "libglvnd-glx", "pacman": "libglvnd"},
    "libGLdispatch.so.0": {"rpm": "libglvnd", "pacman": "libglvnd"},
    "libOpenGL.so.0": {"rpm": "libglvnd-opengl", "pacman": "libglvnd"},
    "libX11-xcb.so.1": {"rpm": "libX11-xcb", "pacman": "libx11"},
    "libX11.so.6": {"rpm": "libX11", "pacman": "libx11"},
    "libXext.so.6": {"rpm": "libXext", "pacman": "libxext"},
    "libasound.so.2": {"rpm": "alsa-lib", "pacman": "alsa-lib"},
    "libdrm.so.2": {"rpm": "libdrm", "pacman": "libdrm"},
    "libepoxy.so.0": {"rpm": "libepoxy", "pacman": "libepoxy"},
    "libgbm.so.1": {"rpm": "mesa-libgbm", "pacman": "mesa"},
    "libva-drm.so.2": {"rpm": "libva", "pacman": "libva"},
    "libva-wayland.so.2": {"rpm": "libva", "pacman": "libva"},
    "libva-x11.so.2": {"rpm": "libva", "pacman": "libva"},
    "libva.so.2": {"rpm": "libva", "pacman": "libva"},
    "libvdpau.so.1": {"rpm": "libvdpau", "pacman": "libvdpau"},
    "libvulkan.so.1": {"rpm": "vulkan-loader", "pacman": "vulkan-icd-loader"},
    "libwayland-client.so.0": {"rpm": "libwayland-client", "pacman": "wayland"},
    "libwayland-cursor.so.0": {"rpm": "libwayland-cursor", "pacman": "wayland"},
    "libwayland-egl.so.1": {"rpm": "libwayland-egl", "pacman": "wayland"},
    "libwayland-server.so.0": {"rpm": "libwayland-server", "pacman": "wayland"},
    "libxcb-dri3.so.0": {"rpm": "libxcb", "pacman": "libxcb"},
    "libxcb-present.so.0": {"rpm": "libxcb", "pacman": "libxcb"},
    "libxcb-randr.so.0": {"rpm": "libxcb", "pacman": "libxcb"},
    "libxcb-render.so.0": {"rpm": "libxcb", "pacman": "libxcb"},
    "libxcb-shm.so.0": {"rpm": "libxcb", "pacman": "libxcb"},
    "libxcb-sync.so.1": {"rpm": "libxcb", "pacman": "libxcb"},
    "libxcb-xfixes.so.0": {"rpm": "libxcb", "pacman": "libxcb"},
    "libxcb.so.1": {"rpm": "libxcb", "pacman": "libxcb"},
}


def run(*command: str) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True)


def load_distros(root: Path) -> dict:
    """Read DISTROS out of build-packages.py rather than duplicating it."""
    spec = importlib.util.spec_from_file_location("build_packages", root / "linux/packaging/build-packages.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.DISTROS


def host_libraries(bundle: Path) -> tuple[dict[str, str], list[str]]:
    """soname -> host path for what the bundle resolves outside itself.

    Also returns problems worth failing on. An unresolved entry is the loudest
    possible version of the failure this whole check exists to prevent - the
    loader finding nothing at all - so it must never be quietly skipped for not
    looking like a path.
    """
    shipped = {path.name for path in bundle.rglob("*.so*")}
    binaries = [bundle / "plezy", *sorted(bundle.glob("lib/*.so*"))]
    needed: dict[str, str] = {}
    problems: list[str] = []
    for binary in binaries:
        result = run("ldd", str(binary))
        # ldd exits non-zero for a file it cannot read as an object. Statically
        # linked objects are the benign case and say so on stdout.
        if result.returncode != 0 and "not a dynamic executable" not in (result.stdout + result.stderr):
            problems.append(f"ldd could not read {binary}: {result.stderr.strip() or 'no diagnostic'}")
            continue
        for line in result.stdout.splitlines():
            soname, separator, remainder = line.partition("=>")
            soname = soname.strip()
            remainder = remainder.strip()
            if not separator or not soname:
                continue
            if remainder.startswith("not found"):
                problems.append(f"{binary.name} needs {soname}, which resolves to nothing on this machine")
                continue
            path = remainder.split(" (")[0]
            if not path.startswith("/"):
                continue
            # A library that ships beside the binary needs nothing declared,
            # even when the loader happened to resolve this copy from the host.
            if soname in shipped or soname.startswith(BASELINE_PREFIXES):
                continue
            needed[soname] = path
    return needed, problems


def deb_owner(path: str) -> str:
    """The deb package owning a file, following symlinks when dpkg needs it."""
    for candidate in (path, os.path.realpath(path)):
        owner = run("dpkg-query", "-S", candidate).stdout.partition(":")[0].strip()
        if owner:
            # A diverted or multi-arch answer can carry an architecture suffix.
            return owner.split(",")[0].split(":")[0]
    return ""


def deb_names(package: str) -> set[str]:
    """The package's own name plus everything it Provides."""
    provides = run("dpkg-query", "-W", "-f", "${Provides}", package).stdout
    names = {package}
    for entry in provides.split(","):
        name = entry.split("(")[0].strip()
        if name:
            names.add(name)
    return names


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path, help="the built Flutter bundle directory")
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="repository root")
    arguments = parser.parse_args()

    if not (arguments.bundle / "plezy").exists():
        print(f"::error::{arguments.bundle}/plezy does not exist - nothing to check", file=sys.stderr)
        return 1

    distros = load_distros(arguments.root)
    # "a | b" is satisfied by either name, so compare against the flattened set.
    declared = {
        distro: {name.strip() for dependency in config["depends"] for name in dependency.split("|")}
        for distro, config in distros.items()
    }

    needed, errors = host_libraries(arguments.bundle)
    for soname, path in sorted(needed.items()):
        owner = deb_owner(path)
        if not owner:
            errors.append(f"{soname} ({path}) belongs to no deb package, so it cannot be checked or declared")
        elif not (deb_names(owner) & declared["deb"]):
            errors.append(f"{soname} comes from deb package '{owner}', which linux/packaging/build-packages.py does not declare")

        others = OTHER_DISTROS.get(soname)
        if others is None:
            errors.append(f"{soname} has no rpm/pacman package recorded in {Path(__file__).name}")
            continue
        for distro, package in sorted(others.items()):
            if distro in declared and package not in declared[distro]:
                errors.append(f"{soname} needs '{package}' on {distro}, which build-packages.py does not declare")

    for error in errors:
        print(f"::error::{error}", file=sys.stderr)
    if errors:
        return 1

    print(f"every one of the {len(needed)} host libraries the bundle needs is declared on all {len(distros)} distros:")
    for soname in sorted(needed):
        print(f"  {soname:<28} {deb_owner(needed[soname])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
