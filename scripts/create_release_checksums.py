#!/usr/bin/env python3
"""Write SHA256SUMS.txt for the binary assets staged for a GitHub release."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path


ASSET_SUFFIXES = (
    ".aab",
    ".apk",
    ".deb",
    ".dmg",
    ".exe",
    ".flatpak",
    ".ipa",
    ".msixbundle",
    ".nupkg",
    ".rpm",
    ".tar.gz",
    ".7z",
    ".zip",
    ".zst",
)


def is_release_asset(path: Path) -> bool:
    name = path.name.lower()
    return name != "sha256sums.txt" and any(name.endswith(suffix) for suffix in ASSET_SUFFIXES)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("assets", type=Path, help="directory containing the release assets")
    args = parser.parse_args()

    if not args.assets.is_dir():
        parser.error(f"asset directory does not exist: {args.assets}")

    paths = sorted(
        (path for path in args.assets.rglob("*") if path.is_file() and is_release_asset(path)),
        key=lambda path: path.name,
    )
    names = [path.name for path in paths]
    if len(names) != len(set(names)):
        parser.error("release assets contain duplicate basenames; GitHub release assets must be unique")
    if not paths:
        parser.error("no release assets found")

    output = args.assets / "SHA256SUMS.txt"
    lines = [f"{sha256(path)}  {path.name}" for path in paths]
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {output} for {len(paths)} release asset(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
