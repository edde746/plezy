#!/usr/bin/env python3
"""Package a fully resolved Linux release bundle.

Requires native flatpak/flatpak-builder tools, ImageMagick and the target
Platform/SDK in the user installation. Cross-architecture builds also require
a binfmt interpreter for that SDK. The input is the same tree shipped in the
tarball, not a bare `flutter build linux` output. The build uses no network.
"""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))
from pubspec_version import parse_pubspec_version

APP_ID = "com.edde746.plezy"
ARCHITECTURES = {"x64": ("x86_64", 62), "arm64": ("aarch64", 183)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", required=True, type=Path)
    parser.add_argument("--arch", required=True, choices=ARCHITECTURES)
    parser.add_argument("--output", type=Path, default=PROJECT_ROOT)
    args = parser.parse_args()
    bundle = args.bundle.resolve()
    architecture, machine = ARCHITECTURES[args.arch]
    for required in ("plezy", "plezy.sh", "lib/libflutter_linux_gtk.so", "lib/libapp.so", "data/icudtl.dat"):
        if not (bundle / required).is_file():
            parser.error(f"Incomplete release bundle: missing {bundle / required}")
    if not list((bundle / "lib").glob("libmpv.so*")):
        parser.error("Release bundle must include the pinned libmpv")
    with (bundle / "plezy").open("rb") as executable:
        header = executable.read(20)
    if len(header) != 20 or header[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", header, 18)[0] != machine:
        parser.error(f"Bundle executable is not a little-endian 64-bit {architecture} ELF")
    image_tool = shutil.which("magick") or shutil.which("convert")
    if image_tool is None:
        parser.error("ImageMagick is required to produce the 512px application icon")

    version, _ = parse_pubspec_version((PROJECT_ROOT / "pubspec.yaml").read_text())
    args.output.mkdir(parents=True, exist_ok=True)
    output = args.output.resolve() / f"plezy-linux-{args.arch}.flatpak"
    template = SCRIPT_DIR / "flatpak"
    manifest = json.loads((template / f"{APP_ID}.json").read_text())

    with tempfile.TemporaryDirectory(prefix="plezy-flatpak-") as temporary:
        stage = Path(temporary)
        for name in ("plezy", "relocate-caches.py"):
            shutil.copy2(template / name, stage / name)
        desktop = (SCRIPT_DIR / f"{APP_ID}.desktop").read_text()
        (stage / f"{APP_ID}.desktop").write_text(desktop.replace("Icon=plezy", f"Icon={APP_ID}"))
        metadata = ET.parse(template / f"{APP_ID}.metainfo.xml")
        releases = ET.SubElement(metadata.getroot(), "releases")
        ET.SubElement(releases, "release", version=version.split("+", 1)[0],
                      date=datetime.now(timezone.utc).date().isoformat())
        metadata.write(stage / f"{APP_ID}.metainfo.xml", encoding="utf-8", xml_declaration=True)
        subprocess.run([image_tool, str(PROJECT_ROOT / "assets/plezy.png"), "-resize", "512x512",
                        str(stage / "plezy.png")], check=True)
        manifest["modules"][0]["sources"][0]["path"] = str(bundle)
        manifest_path = stage / f"{APP_ID}.json"
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
        subprocess.run([
            "flatpak-builder", "--user", "--disable-rofiles-fuse", "--force-clean",
            f"--arch={architecture}", f"--state-dir={stage / 'state'}", f"--repo={stage / 'repo'}",
            str(stage / "build"), str(manifest_path),
        ], check=True, cwd=stage)
        # Publish the file only after flatpak has successfully written the bundle.
        artifact = stage / output.name
        subprocess.run([
            "flatpak", "build-bundle", f"--arch={architecture}",
            "--runtime-repo=https://flathub.org/repo/flathub.flatpakrepo",
            str(stage / "repo"), str(artifact), APP_ID, "master",
        ], check=True)
        shutil.move(artifact, output)
    print(f"Created: {output}")


if __name__ == "__main__":
    main()
