#!/usr/bin/env python3
"""Verify the exact patched LG Flutter/webOS source checkout used by the build."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = ROOT / "tools" / "webos" / "compatibility.json"


class CheckoutError(ValueError):
    pass


def _git(repo: Path, *args: str) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise CheckoutError(f"git {' '.join(args)} failed in {repo}: {detail}")
    return result.stdout


def _sha256(path: Path, allowed_root: Path) -> str:
    if not path.exists():
        raise CheckoutError(f"pinned SDK tool is missing or not a regular file: {path}")
    resolved = path.resolve(strict=True)
    try:
        resolved.relative_to(allowed_root.resolve(strict=True))
    except ValueError as exc:
        raise CheckoutError(f"pinned SDK tool escapes the SDK checkout: {path}") from exc
    if not resolved.is_file():
        raise CheckoutError(f"pinned SDK tool is missing or not a regular file: {path}")
    digest = hashlib.sha256()
    with resolved.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _verify_revision(repo: Path, expected: str, label: str) -> None:
    actual = _git(repo, "rev-parse", "HEAD").decode("ascii").strip()
    if actual != expected:
        raise CheckoutError(f"{label} checkout is not at the pinned revision")


def _verify_clean(repo: Path, label: str) -> None:
    if _git(repo, "status", "--porcelain", "--untracked-files=all").strip():
        raise CheckoutError(f"{label} checkout has local changes or untracked files")


def _diff_from_head(repo: Path, added_paths: list[str]) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo), "diff", "HEAD", "--binary"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise CheckoutError(f"cannot read source changes in {repo}: {detail}")
    diff = result.stdout
    for relative in added_paths:
        tracked = subprocess.run(
            ["git", "-C", str(repo), "ls-files", "--error-unmatch", "--", relative],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if tracked.returncode == 0:
            continue
        new_path = repo / relative
        if new_path.is_symlink() or not new_path.is_file():
            raise CheckoutError(f"required patched source file is missing or not regular: {new_path}")
        added = subprocess.run(
            ["git", "-C", str(repo), "diff", "--no-index", "--binary", "--", "/dev/null", relative],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if added.returncode != 1:
            detail = added.stderr.decode("utf-8", errors="replace").strip()
            raise CheckoutError(f"cannot include new source file {new_path}: {detail}")
        diff += added.stdout
    return diff


def _verify_patch(
    repo: Path,
    patch_path: Path,
    expected_hash: str,
    added_paths: list[str],
) -> None:
    if repo.is_symlink() or not repo.is_dir():
        raise CheckoutError(f"SDK source checkout is missing: {repo}")
    if patch_path.is_symlink() or not patch_path.is_file():
        raise CheckoutError(f"reviewed source patch is missing: {patch_path}")
    patch = patch_path.read_bytes()
    patch_hash = hashlib.sha256(patch).hexdigest()
    if patch_hash != expected_hash:
        raise CheckoutError(f"reviewed patch hash changed: {patch_path}")
    if hashlib.sha256(_diff_from_head(repo, added_paths)).hexdigest() != expected_hash:
        raise CheckoutError(f"SDK source differs from reviewed patch: {repo}")
    _git(repo, "diff", "--check", "HEAD")


def verify(sdk_root: Path) -> None:
    try:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CheckoutError(f"cannot read {LOCK_PATH}: {exc}") from exc
    sdk = lock["sdk"]
    patches = lock["sdkPatches"]
    engine_build = lock["engineBuild"]
    flutter_root = sdk_root / "flutter"
    engine_root = flutter_root / "engine" / "src"
    _verify_revision(sdk_root, sdk["revision"], "LG flutter-webos")
    _verify_revision(flutter_root, sdk["frameworkRevision"], "nested Flutter framework")

    # engine/src is part of the nested Flutter framework checkout. Its Git HEAD
    # is frameworkRevision; engine.version separately identifies the engine
    # source revision consumed by the Flutter tool.
    if _git(flutter_root, "status", "--porcelain", "--untracked-files=all", "--", "engine/src").strip():
        raise CheckoutError("Flutter engine source has local changes or untracked files")

    third_party = engine_root / "flutter" / "third_party"
    for name, revision in (
        ("dart", sdk["dartRevision"]),
        ("skia", sdk["skiaRevision"]),
        ("depot_tools", engine_build["depotToolsRevision"]),
    ):
        dependency = third_party / name
        _verify_revision(dependency, revision, f"Flutter engine {name}")
        _verify_clean(dependency, f"Flutter engine {name}")

    for relative, expected in (
        ("flutter/buildtools/linux-x64/clang/bin/clang", engine_build["clangSha256"]),
        ("flutter/buildtools/linux-x64/clang/bin/clang++", engine_build["clangSha256"]),
        ("flutter/third_party/gn/gn", engine_build["gnSha256"]),
    ):
        if _sha256(engine_root / relative, sdk_root) != expected:
            raise CheckoutError(f"pinned Flutter engine tool changed: {relative}")

    flutter_version = (
        flutter_root / "bin" / "internal" / "engine.version"
    ).read_text(encoding="ascii").strip()
    if flutter_version != sdk["engineRevision"]:
        raise CheckoutError("Flutter framework engine.version does not match the pinned engine source")

    sdk_patch = patches["flutterWebOS"]
    framework_patch = patches["flutterFramework"]
    _verify_patch(
        sdk_root,
        ROOT / sdk_patch["path"],
        sdk_patch["sha256"],
        [],
    )
    _verify_patch(
        flutter_root,
        ROOT / framework_patch["path"],
        framework_patch["sha256"],
        framework_patch["addedFiles"],
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sdk_root", type=Path)
    args = parser.parse_args()
    try:
        verify(args.sdk_root.resolve(strict=True))
    except (OSError, KeyError, TypeError, CheckoutError) as exc:
        print(f"webOS SDK checkout verification failed: {exc}", file=sys.stderr)
        return 1
    print("Verified pinned Flutter-webOS, Flutter framework, engine source, and patches.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
