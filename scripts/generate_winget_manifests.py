#!/usr/bin/env python3
"""Create a versioned WinGet manifest bundle for the combined Windows installer."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re
import zipfile


REPOSITORY = "snapetech-org/PlezyNG"
PACKAGE_ID = "SnapeTech.PlezyNG"
MANIFEST_VERSION = "1.12.0"
INSTALLER_NAME = "plezy-windows-installer.exe"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", help="semantic version for the release")
    parser.add_argument("installer", type=Path, help="combined Windows installer")
    parser.add_argument("output", type=Path, help="output directory for the manifest bundle")
    args = parser.parse_args()

    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        parser.error("version must use semantic versioning (for example 2.24.1)")
    if not args.installer.is_file():
        parser.error(f"Windows installer does not exist: {args.installer}")

    digest = sha256(args.installer)
    installer_url = (
        f"https://github.com/{REPOSITORY}/releases/download/{args.version}/{INSTALLER_NAME}"
    )
    package_dir = Path("manifests/s/SnapeTech/PlezyNG") / args.version
    output_dir = args.output / package_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    files = {
        f"{PACKAGE_ID}.yaml": f"""# yaml-language-server: $schema=https://aka.ms/winget-manifest.version.{MANIFEST_VERSION}.schema.json
PackageIdentifier: {PACKAGE_ID}
PackageVersion: {args.version}
DefaultLocale: en-US
ManifestType: version
ManifestVersion: {MANIFEST_VERSION}
""",
        f"{PACKAGE_ID}.installer.yaml": f"""# yaml-language-server: $schema=https://aka.ms/winget-manifest.installer.{MANIFEST_VERSION}.schema.json
PackageIdentifier: {PACKAGE_ID}
PackageVersion: {args.version}
Platform:
  - Windows.Desktop
MinimumOSVersion: 10.0.17763.0
InstallerType: inno
InstallModes:
  - silent
  - silentWithProgress
InstallerSwitches:
  Silent: /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
  SilentWithProgress: /SILENT /SUPPRESSMSGBOXES /NORESTART /SP-
UpgradeBehavior: install
Installers:
  - Architecture: x64
    InstallerUrl: {installer_url}
    InstallerSha256: {digest}
  - Architecture: arm64
    InstallerUrl: {installer_url}
    InstallerSha256: {digest}
AppsAndFeaturesEntries:
  - DisplayName: PlezyNG
    Publisher: SnapeTech
    DisplayVersion: {args.version}
    InstallerType: inno
    ProductCode: "{{4213385e-f7be-4f2b-95f9-54082a28bb8f}}_is1"
ManifestType: installer
ManifestVersion: {MANIFEST_VERSION}
""",
        f"{PACKAGE_ID}.locale.en-US.yaml": f"""# yaml-language-server: $schema=https://aka.ms/winget-manifest.defaultLocale.{MANIFEST_VERSION}.schema.json
PackageIdentifier: {PACKAGE_ID}
PackageVersion: {args.version}
PackageLocale: en-US
Publisher: SnapeTech
PublisherUrl: https://github.com/snapetech-org
PublisherSupportUrl: https://github.com/{REPOSITORY}/issues
PackageName: PlezyNG
PackageUrl: https://github.com/{REPOSITORY}
License: GPL-3.0-only
LicenseUrl: https://github.com/{REPOSITORY}/blob/main/LICENSE
ShortDescription: Plex client with Jellyfin and Emby support, offline downloads, and HDR
Description: PlezyNG is an enhanced Plex client that also supports Jellyfin and Emby. Browse movies, shows, and music across your servers, search connected libraries, and keep watchlists and viewing progress in sync. Download media for offline playback. Watch Live TV and DVR where your server supports them. Choose audio tracks and subtitles, adjust playback speed and audio sync, and use HDR or Dolby Vision on supported devices. Watch Together keeps playback in sync when everyone can access the same media on the same server. Use PlezyNG on phones, tablets, TVs, and desktop computers. You’ll need your own Plex, Jellyfin, or Emby server. Features vary by server, device, and media.
Moniker: plezyng
Tags:
  - media
  - plex
  - jellyfin
  - emby
  - video
ReleaseNotesUrl: https://github.com/{REPOSITORY}/releases/tag/{args.version}
ManifestType: defaultLocale
ManifestVersion: {MANIFEST_VERSION}
""",
    }

    for name, content in files.items():
        (output_dir / name).write_text(content, encoding="utf-8")

    archive = args.output / f"plezyng-winget-manifests-{args.version}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        for path in sorted(output_dir.iterdir()):
            bundle.write(path, (package_dir / path.name).as_posix())
    print(f"Wrote {archive} with SHA-256 {digest} for {INSTALLER_NAME}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
