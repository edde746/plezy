#!/usr/bin/env python3
"""Check generated outputs in an isolated worktree without mutating the caller."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

EXPLICIT_GENERATED = {
    "lib/data/ducet_order.dart",
    "lib/data/hid_key_labels.dart",
    "lib/data/iso_639_data.dart",
    "server/relay_protocol_gen.go",
}
DEPENDENCY_STATE = ("package_config.json", "package_graph.json")


def _run(root: Path, *args: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(args, cwd=root, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def _is_generated(relative: str) -> bool:
    return relative in EXPLICIT_GENERATED or (
        relative.startswith("lib/") and (relative.endswith(".g.dart") or relative.endswith(".freezed.dart"))
    )


def _generated_state(root: Path) -> dict[str, bytes]:
    state = {}
    lib = root / "lib"
    if lib.exists():
        for path in lib.rglob("*.dart"):
            relative = path.relative_to(root).as_posix()
            if _is_generated(relative) and path.is_file():
                state[relative] = path.read_bytes()
    for relative in EXPLICIT_GENERATED:
        path = root / relative
        if path.is_file():
            state[relative] = path.read_bytes()
    return state


def _nul_paths(result: bytes) -> list[str]:
    return [os.fsdecode(value) for value in result.split(b"\0") if value]


def _copy_overlay_path(source_root: Path, target_root: Path, relative: str) -> None:
    source = source_root / relative
    target = target_root / relative
    if not source.exists() and not source.is_symlink():
        if target.is_dir() and not target.is_symlink():
            shutil.rmtree(target)
        else:
            target.unlink(missing_ok=True)
        return

    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_dir() and not target.is_symlink():
        shutil.rmtree(target)
    else:
        target.unlink(missing_ok=True)
    if source.is_symlink():
        target.symlink_to(os.readlink(source))
    else:
        shutil.copy2(source, target)


def _copy_dependency_state(source_root: Path, target_root: Path) -> None:
    source = source_root / ".dart_tool"
    target = target_root / ".dart_tool"
    for relative in DEPENDENCY_STATE:
        source_path = source / relative
        if source_path.is_file():
            target.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_path, target / relative)


def _create_isolated_checkout(root: Path, destination: Path) -> None:
    _run(root, "git", "worktree", "add", "--detach", "--quiet", str(destination), "HEAD")
    changed = _nul_paths(_run(root, "git", "diff", "--name-only", "-z", "HEAD", "--").stdout)
    untracked = _nul_paths(_run(root, "git", "ls-files", "--others", "--exclude-standard", "-z").stdout)
    for relative in sorted(set(changed + untracked)):
        _copy_overlay_path(root, destination, relative)
    _copy_dependency_state(root, destination)


def _dirty_generated_paths(root: Path) -> set[str]:
    changed = _nul_paths(_run(root, "git", "diff", "--name-only", "-z", "--").stdout)
    untracked = _nul_paths(
        _run(
            root,
            "git",
            "ls-files",
            "--others",
            "--exclude-standard",
            "-z",
            "--",
            "lib",
            *EXPLICIT_GENERATED,
        ).stdout
    )
    return {relative for relative in changed + untracked if _is_generated(relative)}


def main(argv: list[str] | None = None) -> int:
    arguments = list(sys.argv[1:] if argv is None else argv)
    root = Path.cwd().resolve()
    caller_state = _generated_state(root)
    temporary = Path(tempfile.mkdtemp(prefix="plezy-codegen-check-"))
    checkout = temporary / "checkout"
    registered = True
    try:
        _create_isolated_checkout(root, checkout)
        result = subprocess.run(["bash", "scripts/codegen.sh", *arguments], cwd=checkout, check=False)
        if result.returncode != 0:
            return result.returncode

        expected_state = _generated_state(checkout)
        stale = {
            relative
            for relative in caller_state.keys() | expected_state.keys()
            if caller_state.get(relative) != expected_state.get(relative)
        }
        stale.update(_dirty_generated_paths(root))
        if stale:
            print("Generated files are out of date:", file=sys.stderr)
            for relative in sorted(stale):
                print(f"  {relative}", file=sys.stderr)
            print("Run 'scripts/codegen.sh' and commit the result.", file=sys.stderr)
            return 1
        return 0
    finally:
        if registered:
            subprocess.run(
                ["git", "worktree", "remove", "--force", str(checkout)],
                cwd=root,
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        shutil.rmtree(temporary, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
