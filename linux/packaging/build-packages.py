#!/usr/bin/env python3
import os
import re
import subprocess
import shutil
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent.parent
BUILD_DIR = PROJECT_ROOT / "build/linux/x64/release/bundle"
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", PROJECT_ROOT))

# Package metadata
METADATA = {
    "name": "plezy",
    "license": "Proprietary",
    "vendor": "edde746",
    "maintainer": "edde746 <noreply@github.com>",
    "url": "https://github.com/edde746/plezy",
    "description": "A modern Plex client for desktop and mobile",
}

# Icon sizes to generate
ICON_SIZES = [16, 32, 48, 64, 128, 256, 512]

# Distro-specific configuration
DISTROS = {
    "deb": {
        "type": "deb",
        "arch": "amd64",
        "category": "video",
        "ext": "deb",
        "compression": ["--deb-compression", "xz", "--deb-priority", "optional"],
        "depends": [
            "libgtk-3-0",
            "libmpv2 | libmpv1",
            "libepoxy0",
            "libasound2",
            "libglib2.0-0",
        ],
    },
    "rpm": {
        "type": "rpm",
        "arch": "x86_64",
        "category": "Multimedia",
        "ext": "rpm",
        "compression": ["--rpm-compression", "xzmt"],
        "depends": [
            "gtk3",
            "mpv-libs",
            "libepoxy",
            "alsa-lib",
            "glib2",
        ],
    },
    "pacman": {
        "type": "pacman",
        "arch": "x86_64",
        "category": None,
        "ext": "pkg.tar.zst",
        "compression": ["--pacman-compression", "zstd"],
        "depends": [
            "gtk3",
            "mpv",
            "libepoxy",
            "alsa-lib",
            "glib2",
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
    output_file = OUTPUT_DIR / f"{METADATA['name']}-linux.{config['ext']}"

    print(f"Building .{config['ext']} package...")

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
        "--architecture", config["arch"],
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
        print("Please run 'flutter build linux --release' first")
        exit(1)

    version = get_version()
    print(f"Building packages for {METADATA['name']} version {version}")

    # Make scripts executable
    for script in ["plezy.sh", "after-install.sh", "after-remove.sh"]:
        (SCRIPT_DIR / script).chmod(0o755)

    # Generate icons
    generate_icons()

    # Build all packages
    for distro in DISTROS:
        build_package(distro, version)

    print("\nAll packages built successfully!")
    for f in OUTPUT_DIR.glob(f"{METADATA['name']}-linux.*"):
        print(f"  {f}")


if __name__ == "__main__":
    main()
