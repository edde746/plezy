#!/usr/bin/env python3
"""Prepare isolated FEL source trees and audit production patch parity per port.

This is a rebase prerequisite, not a native build or a playback qualification.
Failed patches stay visible in the report; none are silently dropped.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

from build_adapters import checkout, run


HERE = Path(__file__).resolve().parent
PLATFORMS = ("android", "apple", "linux", "windows")
COMPONENTS = ("ffmpeg", "libplacebo", "mpv")


def production_series(build: Path, component: str, platform: str) -> list[Path]:
    if component not in COMPONENTS or platform not in PLATFORMS:
        raise ValueError("Unknown native component or platform")
    root = build / "patches" / component
    patches = []
    seen = set()
    for name in ("series.common", "series." + platform):
        path = root / name
        if not path.exists():
            continue
        for raw in path.read_text().splitlines():
            entry = raw.strip()
            if not entry or entry.startswith("#"):
                continue
            if not re.fullmatch(r"[A-Za-z0-9_.+-]+\.patch", entry) or entry in seen:
                raise ValueError(f"Invalid or duplicate patch in {path}: {entry}")
            seen.add(entry)
            patch = root / "pool" / entry
            if not patch.is_file() or patch.is_symlink():
                raise ValueError(f"Missing production patch: {patch}")
            patches.append(patch)
    return patches


def apply_series(source: Path, patches: list[Path]) -> dict:
    result = {"status": "not_run", "applied": [], "remaining": [p.name for p in patches]}
    for patch in patches:
        checked = subprocess.run(["git", "apply", "--check", str(patch)], cwd=source,
                                 text=True, capture_output=True, timeout=120)
        if checked.returncode:
            result.update(status="rebase_required", failed_patch=patch.name,
                          diagnostic=checked.stderr[-16384:])
            return result
        run(["git", "apply", patch], cwd=source)
        result["applied"].append({"name": patch.name,
                                  "sha256": hashlib.sha256(patch.read_bytes()).hexdigest()})
        result["remaining"].pop(0)
    result["status"] = "source_stack_applied; compile_and_runtime_unverified"
    return result


def audit(work: Path, platforms: list[str]) -> bool:
    if work.exists() and any(work.iterdir()):
        raise ValueError("Use an empty work directory; audits preserve failed trees for rebasing")
    work.mkdir(parents=True, exist_ok=True)
    app_lock = json.loads((HERE.parents[1] / "mpv-build.lock.json").read_text())
    engine_lock = json.loads((HERE / "engine.lock.json").read_text())
    build = work / "production-build"
    report = {"schema_version": 1, "native_build": "not_run", "pixel_validation": "not_run",
              "production_build_commit": app_lock["commit"], "engine_sources": engine_lock["sources"],
              "ports": {}}
    success = True
    try:
        checkout(build, {"url": f"https://github.com/{app_lock['repo']}.git", "commit": app_lock["commit"]})
        pristine = work / "pristine"
        pristine.mkdir()
        for component in COMPONENTS:
            checkout(pristine / component, engine_lock["sources"][component])
        for platform in platforms:
            port = work / "ports" / platform
            port.mkdir(parents=True)
            report["ports"][platform] = {}
            for component in COMPONENTS:
                source = port / component
                # Each worktree has an independent index and tracked files;
                # the verified source repository belongs only to this audit.
                run(["git", "-C", pristine / component, "worktree", "add", "--detach", source,
                     engine_lock["sources"][component]["commit"]])
                # Only patch applicability is checked here. Submodules are
                # fetched in the pristine checkout, not built in these trees.
                if component == "mpv":
                    run([sys.executable, HERE / "patches/apply_mpv_fel_failclosed.py", source])
                elif component == "libplacebo":
                    run(["git", "apply", HERE / "patches/libplacebo-reject-failed-fel.patch"], cwd=source)
                patches = production_series(build, component, platform)
                result = apply_series(source, patches)
                report["ports"][platform][component] = result
                if result["status"] == "rebase_required":
                    success = False
    except BaseException as error:
        report["failure"] = type(error).__name__
        raise
    finally:
        (work / "native-port-audit.json").write_text(json.dumps(report, indent=2) + "\n")
    return success


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--platform", choices=(*PLATFORMS, "all"), default="all")
    args = parser.parse_args()
    platforms = list(PLATFORMS) if args.platform == "all" else [args.platform]
    try:
        if not audit(args.work_dir.resolve(), platforms):
            parser.exit(1, "Production patch conflicts require rebasing; see native-port-audit.json\n")
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f"Port audit failed: {error}\n")


if __name__ == "__main__":
    main()
