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
    return {pin["identity"]: (pin["location"], pin["state"]["revision"]) for pin in data["pins"]}


def verify_swift_pins(path: Path, expected: list):
    if pin_map(json.loads(path.read_text())) != pin_map({"pins": expected}):
        raise ValueError("Swift dependency resolution drifted; review and pin before compiling")


def build_apple_devices(host: Path, work: Path, platforms: list[str], expected: list, results: dict) -> None:
    """Compile actual device SDK slices without installing or signing an app."""
    if not platforms:
        return
    if not shutil.which("xcodegen"):
        raise ValueError("iOS/tvOS builds require XcodeGen")
    run(["xcodegen", "generate"], cwd=host)
    project = host / "PlezyNGDVExperiment.xcodeproj"
    resolved = project / "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    resolved.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(host / "Package.resolved", resolved)
    for name in platforms:
        scheme, destination = {
            "ios": ("PlezyNGDVExperimentIOS", "generic/platform=iOS"),
            "tvos": ("PlezyNGDVExperimentTV", "generic/platform=tvOS"),
        }[name]
        run(["xcodebuild", "-project", project, "-scheme", scheme,
             "-configuration", "Debug", "-destination", destination,
             "-derivedDataPath", work / ("derived-" + name),
             "-disableAutomaticPackageResolution", "-onlyUsePackageVersionsFromResolvedFile",
             "CODE_SIGNING_ALLOWED=NO", "build"], cwd=host)
        verify_swift_pins(resolved, expected)
        results[name] = "compiled-device-sdk; unsigned, not installed or playback-tested"


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
    parser.add_argument("--apple-platform", choices=("macos", "ios", "tvos", "all"), default="macos",
                        help="SDK build selection; iOS/tvOS require XcodeGen and do not sign/install")
    args = parser.parse_args()
    if args.test and not args.build:
        parser.error("--test requires --build")
    if args.component != "apple" and args.apple_platform != "macos":
        parser.error("--apple-platform applies only to the Apple adapter")
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
            verify_swift_pins(source / "Package.resolved", spec["swift_pins"])
            host = work / "host"
            shutil.copytree(HERE.parent / "dv-apple" / "Host", host)
            shutil.copy2(source / "Package.resolved", host / "Package.resolved")
            if args.build:
                report["swift"] = run(["swift", "--version"], capture=True).strip()
                report["xcode"] = run(["xcodebuild", "-version"], capture=True).strip()
                run(["swift", "package", "resolve"], cwd=host)
                verify_swift_pins(host / "Package.resolved", spec["swift_pins"])
                platforms = ["macos", "ios", "tvos"] if args.apple_platform == "all" else [args.apple_platform]
                report["platform_builds"] = {}
                if "macos" in platforms:
                    run(["swift", "build", "--force-resolved-versions", "--product", "PlezyNGDVExperiment"], cwd=host)
                    report["platform_builds"]["macos"] = "compiled; playback not tested"
                build_apple_devices(host, work, [name for name in platforms if name != "macos"],
                                    spec["swift_pins"], report["platform_builds"])
                verify_swift_pins(host / "Package.resolved", spec["swift_pins"])
                report["build"] = "passed-requested-sdks"
                if args.test:
                    run(["swift", "test", "--force-resolved-versions", "--traits", "DualLayerDolbyVision",
                         "--filter", "Dovi|DualLayer"], cwd=source)
                    report["tests"] = "passed; real-file/GPU tests may report skips in the log"
        elif args.build:
            # FelBaker contains VS headers and a pinned libdovi submodule.
            # No VapourSynth runtime is needed to compile the plugin.
            run(["meson", "setup", work / "build", source, "--wrap-mode=nofallback", "-Dcpu_tier=generic"])
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

