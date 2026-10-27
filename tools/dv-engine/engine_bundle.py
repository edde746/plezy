"""Validate and describe a self-contained Windows experimental engine bundle."""

from __future__ import annotations

import hashlib
import argparse
import json
from pathlib import Path
import re
import struct


ENGINE_ID = "plezyng-dv-fel-v1"
MACHINES = {"x86_64": 0x8664, "aarch64": 0xAA64}


def pe_machine(path: Path) -> int:
    with path.open("rb") as stream:
        header = stream.read(64)
        if len(header) != 64 or header[:2] != b"MZ":
            raise ValueError(f"Not a PE image: {path.name}")
        offset = struct.unpack_from("<I", header, 60)[0]
        if offset < 64 or offset > 1024 * 1024:
            raise ValueError(f"Invalid PE header offset: {path.name}")
        stream.seek(offset)
        signature = stream.read(6)
        if len(signature) != 6 or signature[:4] != b"PE\0\0":
            raise ValueError(f"Invalid PE signature: {path.name}")
        return struct.unpack_from("<H", signature, 4)[0]


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def bundle_manifest(root: Path, architecture: str, source_pins: dict) -> dict:
    if architecture not in MACHINES:
        raise ValueError("Unsupported Windows architecture")
    required = ("libmpv-2.dll", "libmpv.dll.a", "include/mpv/client.h",
                "include/mpv/render.h", "feature-report.json")
    if any(not (root / name).is_file() for name in required):
        raise ValueError("Engine development files or feature report are missing")
    report_path = root / "feature-report.json"
    if report_path.stat().st_size > 1024 * 1024:
        raise ValueError("Engine feature report is too large")
    report = json.loads(report_path.read_text())
    if not isinstance(report, dict):
        raise ValueError("Engine feature report must be an object")
    if report.get("engine_id") != ENGINE_ID or report.get("render_backend") != "d3d11":
        raise ValueError("Engine runtime identity or render backend does not match")
    for feature in ("dovi_split", "paired_frame_api", "fel_nlq_api"):
        if report.get(feature) is not True:
            raise ValueError(f"Engine is missing {feature}")
    files = {}
    seen = set()
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise ValueError("Bundle symlinks are not allowed")
        if not path.is_file() or path == root / "engine-manifest.json":
            continue
        name = path.relative_to(root).as_posix()
        if not re.fullmatch(r"[A-Za-z0-9_./+ \-]+", name) or name.casefold() in seen:
            raise ValueError(f"Ambiguous bundle path: {name}")
        seen.add(name.casefold())
        if path.suffix.lower() in (".dll", ".exe") and pe_machine(path) != MACHINES[architecture]:
            raise ValueError(f"Wrong-architecture executable: {name}")
        files[name] = digest(path)
    return {"schema_version": 1, "engine_id": ENGINE_ID, "architecture": architecture,
            "qualification": "unverified", "sources": source_pins, "files": files}


def validate_bundle(root: Path, architecture: str) -> dict:
    manifest_path = root / "engine-manifest.json"
    if manifest_path.is_symlink() or manifest_path.stat().st_size > 1024 * 1024:
        raise ValueError("Invalid engine manifest")
    manifest = json.loads(manifest_path.read_text())
    if (not isinstance(manifest, dict) or manifest.get("schema_version") != 1 or manifest.get("engine_id") != ENGINE_ID or
            manifest.get("architecture") != architecture or not isinstance(manifest.get("sources"), dict)):
        raise ValueError("Engine manifest identity or architecture does not match")
    actual = bundle_manifest(root, architecture, manifest["sources"])
    if actual["files"] != manifest.get("files"):
        raise ValueError("Bundle file set or digest does not match the manifest")
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--architecture", required=True, choices=tuple(MACHINES))
    parser.add_argument("--source-lock", required=True, type=Path)
    args = parser.parse_args()
    try:
        manifest = validate_bundle(args.root, args.architecture)
        expected = json.loads(args.source_lock.read_text())["sources"]
        if manifest["sources"] != expected:
            raise ValueError("Bundle sources differ from the reviewed engine lock")
    except (ValueError, OSError, KeyError, TypeError) as error:
        parser.exit(1, f"Invalid experimental engine: {error}\n")
    print("Validated experimental engine; device/pixel qualification is still required")


if __name__ == "__main__":
    main()
