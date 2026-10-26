#!/usr/bin/env python3
"""Verify and safely relocate LG's pinned webOS NDK environment script."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shlex
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = ROOT / "tools" / "webos" / "compatibility.json"
TARGET_SYSROOT = "sysroots/ca9v1-webosmllib32-linux-gnueabi"
HOST_SYSROOT = "sysroots/x86_64-starfishsdk-linux"


class EnvironmentError(ValueError):
    pass


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _read_regular_file(path: Path, root: Path | None = None) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise EnvironmentError(f"expected a regular NDK file: {path}")
    resolved = path.resolve(strict=True)
    if root is not None:
        try:
            resolved.relative_to(root)
        except ValueError as exc:
            raise EnvironmentError(f"NDK file escapes the NDK root: {path}") from exc
    try:
        return resolved.read_bytes()
    except OSError as exc:
        raise EnvironmentError(f"cannot read {path}: {exc}") from exc


def _hash_file(root: Path, relative: str) -> str:
    path = root / relative
    if not path.exists():
        raise EnvironmentError(f"pinned NDK file is missing: {path}")
    resolved = path.resolve(strict=True)
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise EnvironmentError(f"pinned NDK file escapes the NDK root: {path}") from exc
    if not resolved.is_file():
        raise EnvironmentError(f"pinned NDK file is not regular: {path}")
    return _sha256(resolved.read_bytes())


def _lock() -> dict[str, object]:
    try:
        return json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise EnvironmentError(f"cannot read compatibility lock: {exc}") from exc


def verified_environment(root_arg: Path) -> tuple[Path, str]:
    if root_arg.is_symlink():
        raise EnvironmentError("NDK root must not be a symbolic link")
    try:
        root = root_arg.resolve(strict=True)
    except OSError as exc:
        raise EnvironmentError(f"NDK root does not exist: {exc}") from exc
    if not root.is_dir():
        raise EnvironmentError("NDK root is not a directory")
    if re.fullmatch(r"/[A-Za-z0-9_./-]+", str(root)) is None:
        raise EnvironmentError("NDK root contains characters unsupported by LG's environment script")

    lock = _lock()
    build = lock["engineBuild"]
    revision_file = _read_regular_file(root / "version-ca9v1-webosmllib32-linux-gnueabi", root)
    if _sha256(revision_file) != build["ndkVersionFileSha256"]:
        raise EnvironmentError("NDK version metadata does not match the pinned webOS SDK")
    if f"Metadata Revision: {build['ndkMetadataRevision']}".encode() not in revision_file:
        raise EnvironmentError("NDK metadata revision does not match the pinned webOS SDK")

    for relative in (TARGET_SYSROOT, HOST_SYSROOT):
        path = root / relative
        if path.is_symlink() or not path.is_dir():
            raise EnvironmentError(f"required NDK sysroot is missing or linked: {path}")

    tools = build["ndkTools"]
    for name, record in tools.items():
        actual = _hash_file(root, record["path"])
        if actual != record["sha256"]:
            raise EnvironmentError(f"pinned NDK {name} tool hash changed")

    target_triple = "arm-webosmllib32-linux-gnueabi"
    alias_directory = root / HOST_SYSROOT / "usr/bin" / target_triple
    for name in ("ar", "readelf", "nm", "strip"):
        alias = alias_directory / f"{target_triple}-{name}"
        expected_target = (root / tools[name]["path"]).resolve(strict=True)
        if not alias.is_symlink() or alias.resolve(strict=True) != expected_target:
            raise EnvironmentError(f"NDK {name} target-triple alias differs from the pinned tool")

    gcc = root / "sysroots/x86_64-starfishsdk-linux/usr/bin/arm-webos-linux-gnueabi/arm-webos-linux-gnueabi-gcc"
    try:
        gcc_version = subprocess.run(
            [str(gcc), "-dumpfullversion"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        raise EnvironmentError(f"cannot query pinned NDK GCC: {exc}") from exc
    if gcc_version != build["gccVersion"]:
        raise EnvironmentError("NDK GCC version does not match the compatibility lock")

    script_name = build["ndkEnvironmentSetupScript"]
    script_path = root / script_name
    script = _read_regular_file(script_path, root).decode("utf-8", errors="strict")
    sysroot_assignment = re.search(
        r"^export SDKTARGETSYSROOT=(/[^\n]+)/sysroots/ca9v1-webosmllib32-linux-gnueabi$",
        script,
        flags=re.MULTILINE,
    )
    if sysroot_assignment is None:
        raise EnvironmentError("NDK environment script has no recognized target sysroot prefix")
    source_prefix = sysroot_assignment.group(1)
    if "\n" in source_prefix or not source_prefix.startswith("/"):
        raise EnvironmentError("NDK environment script has an unsafe source prefix")
    normalized_script = script.replace(source_prefix, "${WEBOS_NDK_ROOT}")
    if _sha256(normalized_script.encode("utf-8")) != build["ndkEnvironmentSetupNormalizedSha256"]:
        raise EnvironmentError("NDK environment setup script differs from the reviewed SDK script")

    expected_files = build["ndkEnvironmentSetupFiles"]
    expected_by_directory: dict[str, set[str]] = {}
    for record in expected_files:
        relative = record["path"]
        if _hash_file(root, relative) != record["sha256"]:
            raise EnvironmentError(f"pinned NDK environment fragment changed: {relative}")
        parent, _, name = relative.rpartition("/")
        expected_by_directory.setdefault(parent, set()).add(name)

    for directory in (
        "sysroots/ca9v1-webosmllib32-linux-gnueabi/environment-setup.d",
        "sysroots/x86_64-starfishsdk-linux/environment-setup.d",
    ):
        path = root / directory
        if not path.exists():
            continue
        if path.is_symlink() or not path.is_dir():
            raise EnvironmentError(f"NDK environment fragment directory is unsafe: {path}")
        actual_names = {child.name for child in path.iterdir()}
        expected_names = expected_by_directory.get(directory, set())
        if actual_names != expected_names:
            raise EnvironmentError(f"unexpected NDK environment fragments in {directory}")

    return root, normalized_script


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--verify", action="store_true")
    mode.add_argument("--emit-shell", action="store_true")
    args = parser.parse_args()
    try:
        root, script = verified_environment(args.root)
    except (OSError, UnicodeDecodeError, KeyError, TypeError, EnvironmentError) as exc:
        print(f"webOS NDK verification failed: {exc}", file=sys.stderr)
        return 1
    if args.emit_shell:
        # The only emitted code is the vendor script whose normalized bytes
        # were checked against the repository lock immediately above.
        sys.stdout.write(f"export WEBOS_NDK_ROOT={shlex.quote(str(root))}\n")
        sys.stdout.write(script)
    else:
        print("Verified pinned LG webOS NDK metadata, tools, and environment scripts.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
