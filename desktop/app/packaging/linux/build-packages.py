#!/usr/bin/env python3
"""Package the Linux app image as plezy-linux-<arch>.deb, .rpm and .pkg.tar.zst, and the portable .tar.gz.

  build-packages.py --app <image dir> --arch x64|arm64 --version X.Y.Z[-<letters>.<number>] --output <dir>

stage-image.py assembles the tree (the image, plezy.sh, lib/mpv-deps) and checks DEPENDS against what it needs from
the host (check-host-deps.py). fpm (1.17.0) packages it as `plezy`, the name Plezy's earlier releases' packages had,
so a newer version replaces theirs: the tree in /opt/plezy, plezy.sh as /usr/bin/plezy, the desktop entry (with the
plezy:// scheme handler), the metainfo and the hicolor icons (desktop/app/icons, tools/brand's) as `plezy`; then
check-packages.py reads back what fpm wrote. The tarball holds the tree at its root, plezy.sh to start it. A beta's
version (3.0.0-beta.3) is written in each format's pre-release syntax (package_version).

Runs on Ubuntu 24.04 with fpm, rpm (rpmbuild), bsdtar (libarchive-tools), zstd and xz, and the libraries the app needs
from the host installed (check-host-deps.py resolves them).
"""

import argparse
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import tempfile

from linux_image import APP_ID, ARCHITECTURES

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parents[3]
ICONS = ROOT / "desktop" / "app" / "icons" / "hicolor"
ICON_SIZES = (16, 24, 32, 48, 64, 128, 256, 512)

METADATA = {
    "name": "plezy",
    "license": "GPL-3.0",
    "vendor": "edde746",
    "maintainer": "edde746 <noreply@github.com>",
    "url": "https://github.com/edde746/plezy",
    "description": "A modern Plex and Jellyfin client for desktop and mobile",
}

# What the app needs from the host, per package format: check-host-deps.py derives the libraries from the tree and
# fails on one these lack, and on a package that provides none of them. Debian's names are those before the 64-bit
# time_t rename, which the renamed packages (libasound2t64, …) Provide, so the deb installs on Debian 12 and 13 and
# Ubuntu 22.04 and 24.04.
DEPENDS = {
    "deb": [
        "libasound2", "libdrm2", "libegl1", "libfontconfig1", "libfreetype6", "libfribidi0", "libgbm1", "libgl1",
        "libglib2.0-0", "libgnutls30", "libharfbuzz0b", "liblcms2-2", "libpipewire-0.3-0", "libpulse0",
        "libsecret-1-0", "libstdc++6", "libva-drm2", "libva-wayland2", "libva-x11-2", "libva2", "libwayland-client0",
        "libwayland-cursor0", "libwayland-egl1", "libx11-6", "libxext6", "libxi6", "libxkbcommon0", "libxrandr2",
        "libxrender1", "libxtst6", "zlib1g",
    ],
    "rpm": [
        "alsa-lib", "fontconfig", "freetype", "fribidi", "glib2", "gnutls", "harfbuzz", "lcms2", "libX11", "libXext",
        "libXi", "libXrandr", "libXrender", "libXtst", "libdrm", "libglvnd-egl", "libglvnd-glx", "libsecret",
        "libstdc++", "libva", "libwayland-client", "libwayland-cursor", "libwayland-egl", "libxkbcommon",
        "mesa-libgbm", "pipewire-libs", "pulseaudio-libs", "zlib",
    ],
    "pacman": [
        "alsa-lib", "fontconfig", "freetype2", "fribidi", "gcc-libs", "glib2", "gnutls", "harfbuzz", "lcms2",
        "libdrm", "libglvnd", "libpipewire", "libpulse", "libsecret", "libva", "libx11", "libxext", "libxi",
        "libxkbcommon", "libxrandr", "libxrender", "libxtst", "mesa", "wayland", "zlib",
    ],
}

# Per format: the file's extension, the package architecture per release architecture, fpm's options, and what joins a
# pre-release's label to its version (package_version).
FORMATS = {
    "deb": {
        "ext": "deb",
        "arch": {"x64": "amd64", "arm64": "arm64"},
        "options": ["--category", "video", "--deb-compression", "xz", "--deb-priority", "optional"],
        "prerelease": "~",
    },
    "rpm": {
        "ext": "rpm",
        "arch": {"x64": "x86_64", "arm64": "aarch64"},
        # rpm owns only the folders a package lists: these make /opt/plezy's go with the package.
        "options": ["--category", "Multimedia", "--rpm-compression", "xzmt", "--rpm-os", "linux",
                    "--rpm-auto-add-directories"],
        "prerelease": "~",
    },
    "pacman": {
        "ext": "pkg.tar.zst",
        "arch": {"x64": "x86_64", "arm64": "aarch64"},
        "options": ["--pacman-compression", "zstd"],
        "prerelease": "",
    },
}

# The app's semantic version: version.xcconfig's MARKETING_VERSION, then on a beta -VERSION_PRERELEASE.
SEMANTIC_VERSION = re.compile(r"(\d+\.\d+\.\d+)(?:-([a-z]+)\.(\d+))?")


def package_version(distro: str, version: str) -> str:
    """The package's version (fpm's -v, before the iteration) for the app's semantic version: X.Y.Z as it is, a
    pre-release in the format's own syntax, which sorts before its release, so the release upgrades every beta of it.
    deb and rpm (4.10 and later) sort `~` before anything, the end included: 3.0.0~beta3 < 3.0.0. pacman has no such
    character, but vercmp sorts a trailing letter segment before the end: 3.0.0beta3 < 3.0.0. In all three the number
    orders the betas (beta3 < beta10) and the letters the stages (alpha < beta < rc)."""
    match = SEMANTIC_VERSION.fullmatch(version)
    if match is None:
        raise ValueError(f"version must be X.Y.Z or X.Y.Z-<letters>.<number> (3.0.0-beta.3); got {version!r}")
    release, label, number = match.groups()
    return release if label is None else f"{release}{FORMATS[distro]['prerelease']}{label}{number}"


def file_mappings(tree: Path) -> list[str]:
    """fpm's source=destination pairs: what each package installs where."""
    return [
        f"{tree}/=/opt/plezy/",
        f"{tree}/plezy.sh=/usr/bin/plezy",
        f"{SCRIPT_DIR}/{APP_ID}.desktop=/usr/share/applications/{APP_ID}.desktop",
        f"{SCRIPT_DIR}/{APP_ID}.metainfo.xml=/usr/share/metainfo/{APP_ID}.metainfo.xml",
        *(f"{ICONS}/{size}x{size}/apps/{APP_ID}.png=/usr/share/icons/hicolor/{size}x{size}/apps/plezy.png"
          for size in ICON_SIZES),
    ]


def fpm_command(distro: str, tree: Path, arch: str, version: str, output: Path) -> list[str]:
    config = FORMATS[distro]
    command = [
        "fpm", "-s", "dir", "-t", distro, "-n", METADATA["name"], "-v", package_version(distro, version),
        "--iteration", "1",
        "--license", METADATA["license"], "--vendor", METADATA["vendor"], "--maintainer", METADATA["maintainer"],
        "--url", METADATA["url"], "--description", METADATA["description"], "--architecture", config["arch"][arch],
        *config["options"],
    ]
    for package in DEPENDS[distro]:
        command += ["--depends", package]
    command += [
        "--after-install", str(SCRIPT_DIR / "after-install.sh"),
        "--after-upgrade", str(SCRIPT_DIR / "after-install.sh"),
        "--after-remove", str(SCRIPT_DIR / "after-remove.sh"),
        "--package", str(output / f"{METADATA['name']}-linux-{arch}.{config['ext']}"),
        *file_mappings(tree),
    ]
    return command


def root_owned(member: tarfile.TarInfo) -> tarfile.TarInfo:
    member.uid = member.gid = 0
    member.uname = member.gname = "root"
    return member


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--app", required=True, type=Path, help="the app image (createReleaseDistributable's Plezy/)")
    parser.add_argument("--arch", required=True, choices=ARCHITECTURES)
    parser.add_argument("--version", required=True, help="the app's semantic version: X.Y.Z, 3.0.0-beta.3 for a beta")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix=".plezy-packages-", dir=output) as temporary:
        subprocess.run([sys.executable, str(SCRIPT_DIR / "stage-image.py"), "--app", str(args.app), "--arch", args.arch,
                        "--output", temporary], check=True)
        tree = Path(temporary) / "plezy"
        for distro in FORMATS:
            package = output / f"{METADATA['name']}-linux-{args.arch}.{FORMATS[distro]['ext']}"
            package.unlink(missing_ok=True)
            subprocess.run(fpm_command(distro, tree, args.arch, args.version, output), check=True)
        tarball = output / f"{METADATA['name']}-linux-{args.arch}.tar.gz"
        with tarfile.open(tarball, "w:gz") as archive:
            for path in sorted(tree.iterdir()):
                archive.add(path, arcname=path.name, filter=root_owned)
        print(f"Created: {tarball}")

    subprocess.run([sys.executable, str(SCRIPT_DIR / "check-packages.py"), str(output), "--arch", args.arch,
                    "--version", args.version], check=True)


if __name__ == "__main__":
    main()
