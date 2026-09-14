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
import shutil
import subprocess
import sys
from pathlib import Path

# The checkout this script lives in. Derived from its own location rather than
# the working directory, so build-packages.py is still found when CI invokes
# the check from the build tree; --root stays as the override.
PROJECT_ROOT = Path(__file__).resolve().parents[2]

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

# Where the loader actually looks for a soname, relative to the bundle root:
# linux/CMakeLists.txt gives plezy RPATH $ORIGIN/lib and plezy.sh exports
# $INSTALL_DIR/lib. Nothing in the bundle carries a RUNPATH of its own, so this
# one directory is the whole search path for every object in it.
LOADER_DIRECTORIES = ("lib",)

# The non-deb package that provides each host soname. Fedora and Arch cannot be
# queried from here, so this is the one place where those names are asserted
# rather than derived - and an unlisted soname is an error, so adding a library
# forces the decision instead of silently shipping a package that cannot start.
OTHER_DISTROS = {
    "libEGL.so.1": {"rpm": "libglvnd-egl", "pacman": "libglvnd"},
    "libGL.so.1": {"rpm": "libglvnd-glx", "pacman": "libglvnd"},
    # Fedora splits glvnd by API: -egl, -gles, -glx and -opengl sit over the
    # base libglvnd that carries libGLdispatch, so GLES is not the EGL package.
    "libGLESv2.so.2": {"rpm": "libglvnd-gles", "pacman": "libglvnd"},
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


# ldd and dpkg-query are the entire evidence base for this check, so they have
# to be substitutable: PLEZY_HOST_TOOLS names a directory searched ahead of
# PATH, which is what lets scripts/test_check_bundle_host_deps.py drive real
# runs of this script against a synthetic bundle on any machine.
HOST_TOOLS = os.environ.get("PLEZY_HOST_TOOLS")


def locate(program: str) -> str | None:
    """Where `program` resolves, PLEZY_HOST_TOOLS ahead of PATH."""
    override = shutil.which(program, path=HOST_TOOLS) if HOST_TOOLS else None
    return override or shutil.which(program)


def run(*command: str) -> subprocess.CompletedProcess:
    program, *arguments = command
    return subprocess.run([locate(program) or program, *arguments], capture_output=True, text=True)


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
    # Only what the loader will search counts as shipped. The dlopen'd
    # gdk-pixbuf loaders and GIO modules below lib/ are opened by explicit path
    # and never resolve a soname for anyone, so a nested module whose filename
    # happens to equal one the executable really takes from the host would
    # otherwise make that host library look bundled and pass the check
    # vacuously.
    shipped = {path.name for directory in LOADER_DIRECTORIES for path in (bundle / directory).glob("*.so*")}
    # rglob for the objects to inspect, though: those same modules pull in host
    # libraries nothing else in the bundle links, and scanning only lib/*.so*
    # left their dependencies out of ldd entirely.
    binaries = [bundle / "plezy", *sorted(bundle.rglob("*.so*"))]
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
                # Unless the bundle ships it. Bundled objects carry no RUNPATH of
                # their own - bundle-libs.sh copies and strips, it does not
                # patchelf - so running ldd on one in isolation resolves its
                # DT_NEEDED entries against the system cache only, and a library
                # that exists nowhere but the bundle reads as missing. At runtime
                # the executable's own $ORIGIN/lib finds it, which is what makes
                # shipping it sufficient. libshaderc_shared is exactly this case:
                # no distro package installs it, which is why both workflows copy
                # it in by hand.
                if soname in shipped:
                    continue
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
    parser.add_argument("--root", type=Path, default=PROJECT_ROOT, help="repository root")
    arguments = parser.parse_args()

    if not (arguments.bundle / "plezy").exists():
        print(f"::error::{arguments.bundle}/plezy does not exist - nothing to check", file=sys.stderr)
        return 1

    # ldd and dpkg-query are the entire evidence base. Without them this walk
    # finds nothing and would otherwise report a bundle with no host libraries
    # at all, which is the one failure mode a guard must never have. dpkg-query
    # also pins the check to a Debian-family host: Fedora and Arch cannot answer
    # which package owns a file, so the check genuinely cannot run there and says
    # so instead of passing. build-packages.py carries the deliberate opt-out for
    # anyone who has to package from such a host anyway.
    absent = [tool for tool in ("ldd", "dpkg-query") if locate(tool) is None]
    if absent:
        print(
            f"::error::{' and '.join(absent)} not found - this check derives deb package ownership "
            "from dpkg-query, so it only runs on a Debian or Ubuntu host",
            file=sys.stderr,
        )
        return 1

    distros = load_distros(arguments.root)
    # "a | b" is satisfied by either name, so compare against the flattened set.
    declared = {
        distro: {name.strip() for dependency in config["depends"] for name in dependency.split("|")}
        for distro, config in distros.items()
    }

    needed, errors = host_libraries(arguments.bundle)
    # A real bundle always needs *something* from the host: bundle-libs.sh
    # deliberately leaves the graphics stack behind, so an empty result means the
    # walk found nothing rather than that nothing is needed - a silently
    # successful no-op is the worst outcome for a guard.
    if not needed and not errors:
        errors.append(
            f"no host libraries were found for {arguments.bundle} at all, which cannot be right - "
            "ldd produced nothing usable, so this proved nothing"
        )
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
