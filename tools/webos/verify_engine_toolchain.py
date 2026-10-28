#!/usr/bin/env python3
"""Verify the pinned host and LG NDK tools used to build the webOS engine."""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import shutil
import subprocess
import sys
from pathlib import Path

from ndk_environment import verified_environment


ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = ROOT / "tools" / "webos" / "compatibility.json"


class ToolchainError(ValueError):
    pass


def _sha256(path: Path, allowed_root: Path | None = None) -> str:
    if not path.exists():
        raise ToolchainError(f"pinned build tool is missing: {path}")
    resolved = path.resolve(strict=True)
    if allowed_root is not None:
        try:
            resolved.relative_to(allowed_root.resolve(strict=True))
        except ValueError as exc:
            raise ToolchainError(f"pinned build tool escapes its root: {path}") from exc
    if not resolved.is_file():
        raise ToolchainError(f"pinned build tool is not a regular file: {path}")
    digest = hashlib.sha256()
    with resolved.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _version(binary: Path, args: list[str]) -> str:
    try:
        result = subprocess.run(
            [str(binary), *args],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        raise ToolchainError(f"cannot query pinned build tool {binary}: {exc}") from exc
    return (result.stdout or result.stderr).strip()


def verify(
    sdk_root_arg: Path,
    ndk_root_arg: Path,
    ninja_arg: Path,
    python_arg: Path,
) -> None:
    try:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ToolchainError(f"cannot read compatibility lock: {exc}") from exc
    build = lock["engineBuild"]

    roots: dict[str, Path] = {}
    for name, path_arg in (
        ("Flutter SDK", sdk_root_arg),
        ("webOS NDK", ndk_root_arg),
    ):
        if path_arg.is_symlink():
            raise ToolchainError(f"{name} root must not be a symbolic link")
        try:
            path = path_arg.resolve(strict=True)
        except OSError as exc:
            raise ToolchainError(f"{name} root is missing: {exc}") from exc
        if not path.is_dir():
            raise ToolchainError(f"{name} root is not a directory")
        roots[name] = path

    sdk_root = roots["Flutter SDK"]
    ndk_root, _ = verified_environment(roots["webOS NDK"])

    for key, expected_key in (("hostArgs", "hostArgsSha256"), ("armArgs", "armArgsSha256")):
        path = ROOT / build[key]
        if _sha256(path, ROOT) != build[expected_key]:
            raise ToolchainError(f"reviewed GN arguments changed: {build[key]}")

    wrappers = (
        (ROOT / "tools/webos/engine-toolchain/clang", build["clangWrapperSha256"]),
        (ROOT / "tools/webos/engine-toolchain/clang++", build["clangxxWrapperSha256"]),
    )
    for path, expected in wrappers:
        if _sha256(path, ROOT) != expected:
            raise ToolchainError(f"reviewed custom toolchain wrapper changed: {path.name}")

    if python_arg.is_symlink():
        raise ToolchainError("pinned Python interpreter must not be a symbolic link")
    python_bin = python_arg.resolve(strict=True)
    ubuntu_version = platform.freedesktop_os_release().get("VERSION_ID")
    expected_python_sha256 = build["pythonSha256ByUbuntu"].get(ubuntu_version)
    if expected_python_sha256 is None:
        raise ToolchainError(f"no pinned Python hash for Ubuntu {ubuntu_version}")
    if _sha256(python_bin) != expected_python_sha256:
        raise ToolchainError("pinned Python interpreter hash changed")
    python_version = _version(python_bin, ["--version"]).removeprefix("Python ")
    if python_version != build["pythonVersion"]:
        raise ToolchainError("pinned Python version changed")
    path_python = shutil.which("python3")
    if path_python is None or _sha256(Path(path_python)) != expected_python_sha256:
        raise ToolchainError("python3 on PATH does not resolve to the pinned interpreter")

    ninja = ninja_arg.resolve(strict=True)
    if _sha256(ninja) != build["ninjaSha256"]:
        raise ToolchainError("pinned Ninja binary hash changed")
    if _version(ninja, ["--version"]) != build["ninjaVersion"]:
        raise ToolchainError("pinned Ninja version changed")

    # The SDK verifier checks the source revisions and the GN/Clang binaries;
    # require its expected checkout-relative inputs here as a guard against
    # accidentally verifying a different SDK root.
    if not (sdk_root / "flutter/engine/src/flutter/third_party/gn/gn").is_file():
        raise ToolchainError("pinned GN binary is missing from the Flutter SDK")
    vpython3 = sdk_root / "flutter/engine/src/flutter/third_party/depot_tools/vpython3"
    if _sha256(vpython3, sdk_root) != build["vpython3Sha256"]:
        raise ToolchainError("pinned depot_tools vpython3 wrapper changed")
    vpython_source = vpython3.read_text(encoding="utf-8")
    if build["vpythonBypass"] not in vpython_source:
        raise ToolchainError("pinned vpython3 wrapper lacks the locked local-interpreter mode")
    print("Verified pinned GN arguments, engine wrappers, vpython3, Python, Ninja, and LG webOS NDK.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk-root", type=Path, required=True)
    parser.add_argument("--ndk-root", type=Path, required=True)
    parser.add_argument("--ninja", type=Path, required=True)
    parser.add_argument("--python", type=Path, required=True)
    args = parser.parse_args()
    try:
        verify(args.sdk_root, args.ndk_root, args.ninja, args.python)
    except (OSError, KeyError, TypeError, ToolchainError) as exc:
        print(f"webOS engine toolchain verification failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
