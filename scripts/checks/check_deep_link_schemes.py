#!/usr/bin/env python3
"""Check that installed apps can actually receive every supported URI scheme."""

import plistlib
import re
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SCHEMES = {"plezy", "plezyng", "plezxyng"}


def check() -> None:
    failures = []

    def expect(path: str, registered: set[str]) -> None:
        missing = SCHEMES - registered
        if missing:
            failures.append(f"{path}: missing {', '.join(sorted(missing))}")

    for platform in ("ios", "macos", "tvos"):
        path = f"{platform}/Runner/Info.plist"
        info = plistlib.loads((ROOT / path).read_bytes())
        expect(path, {s for row in info["CFBundleURLTypes"] for s in row["CFBundleURLSchemes"]})

    path = "android/app/src/main/AndroidManifest.xml"
    root = ET.parse(ROOT / path).getroot()
    expect(path, {e.get("{http://schemas.android.com/apk/res/android}scheme", "") for e in root.iter("data")})

    for path in ROOT.glob("linux/packaging/**/*.desktop"):
        expect(str(path.relative_to(ROOT)), set(re.findall(r"x-scheme-handler/([^;]+);", path.read_text())))

    path = "windows/build-msix.ps1"
    expect(path, set(re.findall(r'<uap:Protocol Name="([^"]+)"', (ROOT / path).read_text())))
    path = "windows/build-installer.ps1"
    expect(path, set(re.findall(r'Classes\\([^"\\]+)";.*ValueName: "URL Protocol"', (ROOT / path).read_text())))

    for path in ("windows/runner/main.cpp", "windows/runner/flutter_window.cpp"):
        expect(path, set(re.findall(r'starts_with\("([^:]+)://open-media\?', (ROOT / path).read_text())))

    if failures:
        raise SystemExit("\n".join(failures))
    print("Deep-link registrations agree across Android, Apple, Linux and Windows.")


if __name__ == "__main__":
    check()
