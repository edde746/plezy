#!/usr/bin/env python3
import os
import re
import subprocess
import shutil
import sys
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent.parent
BUILD_DIR = Path(os.environ["BUILD_DIR"]) if "BUILD_DIR" in os.environ else PROJECT_ROOT / "build/linux/x64/release/bundle"
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", PROJECT_ROOT))
ARCH_SUFFIX = os.environ.get("ARCH_SUFFIX", "x64")

# Package metadata
METADATA = {
    "name": "plezy",
    "license": "GPL-3.0",
    "vendor": "edde746",
    "maintainer": "edde746 <noreply@github.com>",
    "url": "https://github.com/edde746/plezy",
    "description": "A modern Plex and Jellyfin client for desktop and mobile",
}

# Icon sizes to generate
ICON_SIZES = [16, 32, 48, 64, 128, 256, 512]

# Architecture mappings per package format
ARCH_MAP = {
    "x64": {"deb": "amd64", "rpm": "x86_64", "pacman": "x86_64"},
    "arm64": {"deb": "arm64", "rpm": "aarch64", "pacman": "aarch64"},
}

# Distro-specific configuration
DISTROS = {
    "deb": {
        "type": "deb",
        "category": "video",
        "ext": "deb",
        "compression": ["--deb-compression", "xz", "--deb-priority", "optional"],
        # The native video plane links wayland-client, wayland-egl and EGL, and
        # bundle-libs.sh deliberately never bundles those: they are coupled to
        # the running compositor and GPU driver. So they have to be declared.
        #
        # libmpv itself travels *in* the package rather than being depended on,
        # because the plane needs the pinned Wayland-enabled build - a distro
        # libmpv without Wayland silently drops hwdec to vaapi-copy. That means
        # the libraries the host libmpv used to drag in transitively are now ours
        # to declare: libva and its drm/wayland backends for hwdec, and drm/gbm
        # underneath them.
        #
        # The X11 and xcb entries are not a mistake on a Wayland-only video
        # path: GTK links them whatever backend it runs, and ffmpeg's VA-API
        # brings libva-x11 with it. They used to arrive via the host gtk3 and
        # mpv packages.
        #
        # Miss any one of these and the loader fails before main() runs, so
        # check-bundle-host-deps.py re-derives the whole list from the built
        # bundle rather than trusting this comment - main() below runs it before
        # anything is packaged, and the release workflow runs it again.
        "depends": [
            "libgtk-3-0",
            "libepoxy0",
            "libasound2",
            "libevdev2",
            "libglib2.0-0",
            "libwayland-client0",
            "libwayland-cursor0",
            "libwayland-egl1",
            "libegl1",
            # libEGL.so.1 defers to libGLdispatch.so.0, which is a separate
            # package Debian only pulls in behind libegl1. The runner links it
            # directly, so it is declared directly.
            "libglvnd0",
            "libva2",
            "libva-drm2",
            "libva-wayland2",
            "libva-x11-2",
            "libdrm2",
            "libgbm1",
            "libx11-6",
            "libx11-xcb1",
            "libxext6",
            "libxcb1",
            "libxcb-dri3-0",
            "libxcb-render0",
            "libxcb-shm0",
        ],
    },
    "rpm": {
        "type": "rpm",
        "category": "Multimedia",
        "ext": "rpm",
        "compression": ["--rpm-compression", "xzmt"],
        # Fedora splits glvnd: libglvnd-egl carries libEGL.so.1 but the
        # libGLdispatch.so.0 it defers to lives in the base libglvnd package.
        "depends": [
            "gtk3",
            "libepoxy",
            "alsa-lib",
            "libevdev",
            "glib2",
            "libwayland-client",
            "libwayland-cursor",
            "libwayland-egl",
            "libglvnd",
            "libglvnd-egl",
            "libva",
            "libdrm",
            "mesa-libgbm",
            "libX11",
            "libX11-xcb",
            "libXext",
            "libxcb",
        ],
    },
    "pacman": {
        "type": "pacman",
        "category": None,
        "ext": "pkg.tar.zst",
        "compression": ["--pacman-compression", "zstd"],
        # Arch ships every libwayland-* in the one `wayland` package, libglvnd is
        # what provides both libEGL.so.1 and libGLdispatch.so.0, mesa is what
        # provides libgbm.so.1, and libx11 carries libX11-xcb.so.1 alongside
        # libX11.so.6.
        "depends": [
            "gtk3",
            "libepoxy",
            "alsa-lib",
            "libevdev",
            "glib2",
            "wayland",
            "libglvnd",
            "libva",
            "libdrm",
            "mesa",
            "libx11",
            "libxext",
            "libxcb",
        ],
    },
}


def get_version() -> str:
    """Extract version from pubspec.yaml."""
    pubspec = PROJECT_ROOT / "pubspec.yaml"
    content = pubspec.read_text()
    match = re.search(r"^version:\s*(.+)$", content, re.MULTILINE)
    if not match:
        raise RuntimeError("Could not find version in pubspec.yaml")
    return match.group(1).split("+")[0]


def generate_icons():
    """Generate icons at multiple sizes using ImageMagick."""
    print("Generating icons...")
    source = PROJECT_ROOT / "assets/plezy.png"

    for size in ICON_SIZES:
        dest_dir = SCRIPT_DIR / f"icons/{size}x{size}"
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / "plezy.png"

        # Try magick (ImageMagick 7) first, then convert (ImageMagick 6)
        for cmd in ["magick", "convert"]:
            if shutil.which(cmd):
                subprocess.run([cmd, str(source), "-resize", f"{size}x{size}", str(dest)], check=True)
                break
        else:
            print(f"Warning: ImageMagick not found, copying original icon for {size}x{size}")
            shutil.copy(source, dest)


def get_file_mappings() -> list[str]:
    """Get file mappings for fpm."""
    mappings = [
        f"{BUILD_DIR}/=/opt/plezy/",
        f"{SCRIPT_DIR}/com.edde746.plezy.desktop=/usr/share/applications/com.edde746.plezy.desktop",
        f"{SCRIPT_DIR}/plezy.sh=/usr/bin/plezy",
    ]

    for size in ICON_SIZES:
        mappings.append(
            f"{SCRIPT_DIR}/icons/{size}x{size}/plezy.png=/usr/share/icons/hicolor/{size}x{size}/apps/plezy.png"
        )

    return mappings


def build_package(distro: str, version: str):
    """Build a package for the specified distro."""
    config = DISTROS[distro]
    arch = ARCH_MAP[ARCH_SUFFIX][distro]
    output_file = OUTPUT_DIR / f"{METADATA['name']}-linux-{ARCH_SUFFIX}.{config['ext']}"

    print(f"Building .{config['ext']} package ({arch})...")

    cmd = [
        "fpm",
        "-s", "dir",
        "-t", config["type"],
        "-n", METADATA["name"],
        "-v", version,
        "--iteration", "1",
        "--license", METADATA["license"],
        "--vendor", METADATA["vendor"],
        "--maintainer", METADATA["maintainer"],
        "--url", METADATA["url"],
        "--description", METADATA["description"],
        "--architecture", arch,
    ]

    if config["category"]:
        cmd.extend(["--category", config["category"]])

    for dep in config["depends"]:
        cmd.extend(["--depends", dep])

    cmd.extend(config["compression"])

    cmd.extend([
        "--after-install", str(SCRIPT_DIR / "after-install.sh"),
        "--after-remove", str(SCRIPT_DIR / "after-remove.sh"),
        "--package", str(output_file),
    ])

    cmd.extend(get_file_mappings())

    subprocess.run(cmd, check=True)
    print(f"Created: {output_file}")


def main():
    # Verify build exists
    if not BUILD_DIR.exists():
        print(f"Error: Build directory not found at {BUILD_DIR}")
        print("Please run 'flutter build linux --release' first or set BUILD_DIR.")
        # The runner requires pkg-config to find mpv, and build-libmpv.sh exports
        # PKG_CONFIG_PATH only inside its own process. Without carrying it across,
        # the build either cannot configure at all or - worse, because it looks
        # like success - links whatever distro libmpv happens to be installed
        # instead of the pinned Wayland-enabled one these packages assume. CI sets
        # this explicitly for the same reason and installs no libmpv-dev.
        print("The build needs the pinned libmpv on its pkg-config path, which build-libmpv.sh")
        print("exports only for itself:")
        print('  PKG_CONFIG_PATH="$(pwd)/libmpv-prefix/lib/pkgconfig:$(pwd)/libmpv-prefix/lib/x86_64-linux-gnu/pkgconfig" \\')
        print("    flutter build linux --release")
        exit(1)

    # None of the three package manifests declares a host libmpv any more,
    # because the plane needs the pinned Wayland-enabled build and so ships it.
    # That makes a bundle without one unpackageable rather than merely thinner:
    # the runner's DT_NEEDED libmpv.so.2 would be satisfied by nothing and the
    # loader would fail before main(), on a package that installed cleanly.
    # Both workflows stage it first; this refuses the standalone path that the
    # message above otherwise invites.
    # The versioned soname, not `libmpv.so`. That bare name is the development
    # linker name; the runner records DT_NEEDED libmpv.so.2 and the loader will
    # not accept the unversioned file in its place. Matching `libmpv.so*` would
    # pass a staging tree carrying only the linker name - the exact failure this
    # check is named for, and the only thing standing between a hand-staged
    # bundle and a broken package when the host-dep guard is opted out of below.
    if not sorted((BUILD_DIR / "lib").glob("libmpv.so.[0-9]*")):
        print(f"Error: no libmpv found in {BUILD_DIR / 'lib'}")
        print("The packages declare no host libmpv, so one has to travel inside them.")
        print("Stage the bundle first, exactly as both workflows do:")
        # meson installs libmpv under an architecture triple on Debian and Ubuntu
        # while CMake installed shaderc straight into lib/, which is why the two
        # lines below are not the same shape. The workflows locate libmpv the same
        # way; a hardcoded libmpv-prefix/lib/libmpv.so* finds nothing there.
        print('  cp -a "$(dirname "$(find libmpv-prefix -name libmpv.so | head -1)")"/libmpv.so* <bundle>/lib/')
        # The pinned libmpv links libshaderc_shared, which build-libmpv.sh leaves
        # in libmpv-prefix - not a directory the loader searches. bundle-libs.sh
        # cannot recover it either: it resolves what ldd reports, and ldd cannot
        # find a soname that is only in the build prefix. So it is copied by hand
        # before the walk, or the bundle gets an unpinned host shaderc at best.
        print("  cp -a libmpv-prefix/lib/libshaderc_shared.so* <bundle>/lib/")
        print("  bash linux/packaging/bundle-libs.sh <bundle>")
        exit(1)

    # Nothing above reconciles the hand-maintained depends lists with what the
    # staged bundle actually loads, and a package that is short one host library
    # installs cleanly and then dies in the loader. Run the guard that does
    # reconcile them before any package exists. As a subprocess under this
    # interpreter, so its exit code and ::error:: annotations arrive unaltered.
    guard = SCRIPT_DIR / "check-bundle-host-deps.py"
    # Truthy tokens only. `PLEZY_SKIP_HOST_DEP_CHECK=0` reads to almost everyone
    # as "do not skip", and a bare non-empty test would have done the opposite -
    # which is the single outcome this whole block exists to prevent.
    skip = os.environ.get("PLEZY_SKIP_HOST_DEP_CHECK", "").strip().lower()
    if skip in {"1", "true", "yes", "on"}:
        # The guard reads deb ownership out of dpkg-query, which Fedora and Arch
        # do not have, so it cannot run there at all. The opt-out is for that
        # case and is an environment variable precisely so it cannot happen by
        # accident: a skip the caller did not ask for would hand back exactly the
        # unverified package this check exists to prevent, so it is never silent.
        print("WARNING: PLEZY_SKIP_HOST_DEP_CHECK is set, so the host dependency guard did not run.")
        print(f"WARNING: the depends lists in {Path(__file__).name} are unverified against {BUILD_DIR}.")
    else:
        guard_result = subprocess.run([sys.executable, str(guard), str(BUILD_DIR)])
        if guard_result.returncode != 0:
            print(f"Error: {guard.name} failed, so no packages were built.")
            print("Declare the libraries it named, or - only on a host without dpkg-query, such as")
            print("Fedora or Arch - set PLEZY_SKIP_HOST_DEP_CHECK=1 to package without the check.")
            exit(guard_result.returncode)

    version = get_version()
    print(f"Building {ARCH_SUFFIX} packages for {METADATA['name']} version {version}")

    # Make scripts executable
    for script in ["plezy.sh", "after-install.sh", "after-remove.sh"]:
        (SCRIPT_DIR / script).chmod(0o755)

    # Generate icons
    generate_icons()

    # Build all packages
    for distro in DISTROS:
        build_package(distro, version)

    print("\nAll packages built successfully!")
    for f in sorted(OUTPUT_DIR.glob(f"{METADATA['name']}-linux-{ARCH_SUFFIX}.*")):
        print(f"  {f}")


if __name__ == "__main__":
    main()
