#!/usr/bin/env python3
"""Fetch exact source revisions and build opt-in adapters outside the release app."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import platform
import re
import shutil
import subprocess


HERE = Path(__file__).resolve().parent


def run(args, *, cwd=None, capture=False):
    return subprocess.run(list(map(str, args)), cwd=cwd, check=True, timeout=3600,
                          text=True, stdout=subprocess.PIPE if capture else None).stdout


def pin_map(data):
    pins = data.get("pins")
    if not isinstance(pins, list):
        raise ValueError("Swift dependency lock has no pin list")
    result = {}
    for pin in pins:
        identity = pin.get("identity")
        state = pin.get("state")
        if (not isinstance(identity, str) or not identity or identity in result
                or not isinstance(state, dict)):
            raise ValueError("Swift dependency lock contains an invalid or duplicate pin")
        result[identity] = (
            pin.get("kind"), pin.get("location"), state.get("revision"), state.get("version"),
        )
    return result


def verify_swift_pins(path: Path, expected: list, *, required=()):
    actual_pins = pin_map(json.loads(path.read_text()))
    expected_pins = pin_map({"pins": expected})
    required = set(required)
    if (not actual_pins or not required.issubset(actual_pins)
            or not actual_pins.keys() <= expected_pins.keys()
            or any(actual_pins[name] != expected_pins[name] for name in actual_pins)):
        raise ValueError("Swift dependency resolution drifted; review and pin before compiling")


def patch_felbaker_vs_output_key(source: Path) -> str:
    """Match FelBaker's return declarations to VapourSynth's `clip` output key."""
    entry = source / "src/VapourSynthEntry.cpp"
    text = entry.read_text()
    replacements = (
        ('"baked:vnode;", bakeFilter', '"clip:vnode;", bakeFilter'),
        ('"baked_rgb:vnode;", rgbFilter', '"clip:vnode;", rgbFilter'),
    )
    for old, new in replacements:
        if text.count(old) != 1:
            raise ValueError("FelBaker VapourSynth output signature changed; review the adapter patch")
        text = text.replace(old, new, 1)
    entry.write_text(text)
    return hashlib.sha256(entry.read_bytes()).hexdigest()


def checkout(source: Path, spec: dict):
    if not re.fullmatch(r"[0-9a-f]{40}", spec["commit"]):
        raise ValueError("source must name a full commit")
    if not re.fullmatch(r"https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git", spec["url"]):
        raise ValueError("source must be an explicit HTTPS GitHub repository")
    run(["git", "init", source])
    run(["git", "-C", source, "remote", "add", "origin", spec["url"]])
    run(["git", "-C", source, "-c", "protocol.file.allow=never", "fetch", "--depth=1", "origin", spec["commit"]])
    run(["git", "-C", source, "checkout", "--detach", spec["commit"]])
    if run(["git", "-C", source, "rev-parse", "HEAD"], capture=True).strip() != spec["commit"]:
        raise ValueError("source revision mismatch")
    run(["git", "-C", source, "-c", "protocol.file.allow=never", "submodule", "update", "--init", "--recursive"])
    for path, revision in spec.get("submodules", {}).items():
        if run(["git", "-C", source / path, "rev-parse", "HEAD"], capture=True).strip() != revision:
            raise ValueError("submodule revision mismatch")
    status = run(["git", "-C", source, "submodule", "status", "--recursive"], capture=True)
    if any(line[:1] != " " for line in status.splitlines()):
        raise ValueError("unresolved submodule")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--component", choices=("apple", "felbaker"), required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--test", action="store_true", help="run upstream tests after building (Apple)")
    args = parser.parse_args()
    if args.test and not args.build:
        parser.error("--test requires --build")
    if args.component == "apple" and args.build and platform.system() != "Darwin":
        parser.error("Apple builds require a Mac with Xcode 27")
    if args.component == "felbaker" and args.test:
        parser.error("FelBaker media tests need local VapourSynth/FFMS2; see the handoff")
    work = args.work_dir.absolute()
    if work.exists() and any(work.iterdir()):
        parser.error("use a new, empty work directory")
    work.mkdir(parents=True, exist_ok=True)
    lock = json.loads((HERE / "adapters.lock.json").read_text())
    name = "aether" if args.component == "apple" else "felbaker"
    spec = lock["sources"][name]
    source = work / "sources" / name
    source.parent.mkdir()
    report = {"schema_version": 1, "component": name, "source": spec,
              "host": platform.platform(), "build": "not_run", "tests": "not_run",
              "real_fel_pixels": "not_tested", "physical_dv_output": "not_tested"}
    try:
        checkout(source, spec)
        if name == "aether":
            required_pins = spec.get("swift_required_pins", ())
            verify_swift_pins(source / "Package.resolved", spec["swift_pins"], required=required_pins)
            host = work / "host"
            shutil.copytree(HERE.parent / "dv-apple" / "Host", host)
            shutil.copy2(source / "Package.resolved", host / "Package.resolved")
            if args.build:
                report["swift"] = run(["swift", "--version"], capture=True).strip()
                report["xcode"] = run(["xcodebuild", "-version"], capture=True).strip()
                run(["swift", "package", "resolve"], cwd=host)
                verify_swift_pins(host / "Package.resolved", spec["swift_pins"], required=required_pins)
                run(["swift", "build", "--force-resolved-versions", "--product", "PlezyNGDVExperiment"], cwd=host)
                report["build"] = "passed"
                if args.test:
                    run(["swift", "test", "--force-resolved-versions", "--traits", "DualLayerDolbyVision",
                         "--filter", "Dovi|DualLayer"], cwd=source)
                    report["tests"] = "passed; real-file/GPU tests may report skips in the log"
        elif args.build:
            # The plugin uses VS headers and a pinned libdovi submodule. The
            # upstream Meson integration tests need FFMS2, which is unrelated
            # to compiling this plugin, so keep them out of this source build.
            report["patched_vapoursynth_entry_sha256"] = patch_felbaker_vs_output_key(source)
            run(["meson", "setup", work / "build", source, "--wrap-mode=nofallback",
                 "-Dcpu_tier=generic", "-Dtests=false"])
            run(["meson", "compile", "-C", work / "build", "-j", "2"])
            report["build"] = "passed"
        report["source_lock_sha256"] = hashlib.sha256((HERE / "adapters.lock.json").read_bytes()).hexdigest()
    except BaseException as error:
        report["failure"] = type(error).__name__
        raise
    finally:
        (work / "adapter-report.json").write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
