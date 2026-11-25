#!/usr/bin/env python3
"""Write the release's appcast.xml, the Sparkle feed the macOS app (Sparkle) and the Windows app read for updates.

One item for the release: title `Version X`, sparkle:version the build number (CURRENT_PROJECT_VERSION, which the apps
compare with their own), sparkle:shortVersionString X (MARKETING_VERSION), the release notes page, and an enclosure
per platform whose EdDSA signature the release build wrote: the macOS DMG (`<macos-dir>/macos-ed-signature.txt`,
`macos-dmg-size.txt`; Apple silicon only, sparkle:hardwareRequirements arm64) and the Windows installer (`<windows-dir>/win-ed-signature.txt`, `win-installer-size.txt`),
which the Windows app runs with `/SILENT /SP-`. A platform without a signature (a build without SPARKLE_PRIVATE_KEY)
gets no enclosure, so no app is offered an update it would refuse. A signature without its size file, or a size that
isn't the file's beside it, fails.

The apps read the feed from the `appcast` branch (update-packages.yml copies it there from the published release).

  tools/appcast.py --version 2.26.0 --build-number 160 --macos-dir <dir> --windows-dir <dir> --output appcast.xml
"""

from __future__ import annotations

import argparse
import base64
import binascii
import re
import sys
from pathlib import Path

DOWNLOADS = "https://github.com/edde746/plezy/releases/download"
RELEASE_NOTES = "https://gh-html.edde746.dev/edde746/plezy"

# (signature file, size file, asset, extra enclosure attributes, sparkle:os)
PLATFORMS = {
    "macos": ("macos-ed-signature.txt", "macos-dmg-size.txt", "plezy-macos.dmg", [], "macos"),
    "windows": (
        "win-ed-signature.txt",
        "win-installer-size.txt",
        "plezy-windows-installer.exe",
        ['sparkle:installerArguments="/SILENT /SP-"'],
        "windows",
    ),
}


class AppcastError(Exception):
    pass


def enclosure(platform: str, directory: Path, version: str) -> list[str]:
    """The enclosure's lines, or none when the platform's build wrote no signature."""
    signature_name, size_name, asset, extra, os_name = PLATFORMS[platform]
    signature_file = directory / signature_name
    signature = signature_file.read_text(encoding="ascii").strip() if signature_file.is_file() else ""
    if not signature:
        return []
    try:
        if len(base64.b64decode(signature, validate=True)) != 64:
            raise AppcastError(f"{signature_file}: not a 64-byte EdDSA signature")
    except binascii.Error:
        raise AppcastError(f"{signature_file}: not base64") from None
    size_file = directory / size_name
    if not size_file.is_file():
        raise AppcastError(f"{signature_file} has no {size_name} beside it")
    size = size_file.read_text(encoding="ascii").strip()
    if not size.isdigit() or int(size) == 0:
        raise AppcastError(f"{size_file}: not a size: {size!r}")
    asset_file = directory / asset
    if asset_file.is_file() and asset_file.stat().st_size != int(size):
        raise AppcastError(f"{size_file} says {size} bytes, {asset_file} has {asset_file.stat().st_size}")
    return [
        f'      <enclosure url="{DOWNLOADS}/{version}/{asset}"',
        f'       length="{size}" type="application/octet-stream"',
        f'       sparkle:edSignature="{signature}"',
        *(f"       {attribute}" for attribute in extra),
        f'       sparkle:os="{os_name}" />',
    ]


def appcast(version: str, build_number: str, macos_dir: Path, windows_dir: Path) -> str:
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise AppcastError(f"version {version!r} is not major.minor.patch")
    if not re.fullmatch(r"[1-9]\d*", build_number):
        raise AppcastError(f"build number {build_number!r} is not a positive integer")
    # The Mac app is built for Apple silicon only: Sparkle (2.9 or later, which every release since the first has carried)
    # skips the item on an Intel Mac, which stays on the release it has. WinSparkle and the Windows app ignore the element.
    mac = enclosure("macos", macos_dir, version)
    if mac:
        mac = ["      <sparkle:hardwareRequirements>arm64</sparkle:hardwareRequirements>", *mac]
    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">',
        "  <channel>",
        "    <title>Plezy Updates</title>",
        "    <item>",
        f"      <title>Version {version}</title>",
        f"      <sparkle:version>{build_number}</sparkle:version>",
        f"      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>",
        f"      <sparkle:releaseNotesLink>{RELEASE_NOTES}/{version}</sparkle:releaseNotesLink>",
        *mac,
        *enclosure("windows", windows_dir, version),
        "    </item>",
        "  </channel>",
        "</rss>",
    ]
    return "\n".join(lines) + "\n"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--version", required=True, help="MARKETING_VERSION, the release tag")
    parser.add_argument("--build-number", required=True, help="CURRENT_PROJECT_VERSION")
    parser.add_argument("--macos-dir", type=Path, required=True, help="the macos-dmg artifact")
    parser.add_argument("--windows-dir", type=Path, required=True, help="the windows-installer artifact")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        text = appcast(args.version, args.build_number, args.macos_dir, args.windows_dir)
    except AppcastError as error:
        print(f"appcast.py: {error}", file=sys.stderr)
        return 1
    args.output.write_text(text, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
