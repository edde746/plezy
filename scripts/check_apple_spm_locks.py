#!/usr/bin/env python3
"""Validate duplicate Apple SwiftPM locks against resolved Flutter plugins."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import url2pathname

LOCK_PAIRS = {
    "iOS": (
        Path("ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"),
        Path("ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"),
    ),
    "macOS": (
        Path("macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"),
        Path("macos/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"),
    ),
}
SENTRY_IDENTITY = "sentry-cocoa"
EXACT_REQUIREMENT = re.compile(
    r"\.package\s*\(\s*url\s*:\s*[\"'][^\"']*sentry-cocoa(?:\.git)?[\"']\s*,\s*exact\s*:\s*[\"']([^\"']+)[\"']",
    re.DOTALL,
)


def _load_pin_map(path: Path, errors: list[str]) -> dict[str, dict]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"{path}: cannot read version-2 SwiftPM lock: {error}")
        return {}
    if not isinstance(payload, dict) or payload.get("version") != 2 or not isinstance(payload.get("pins"), list):
        errors.append(f"{path}: expected a version-2 SwiftPM lock with a pins array")
        return {}

    pins: dict[str, dict] = {}
    for pin in payload["pins"]:
        identity = pin.get("identity") if isinstance(pin, dict) else None
        if not isinstance(identity, str):
            errors.append(f"{path}: pin without a string identity")
            continue
        canonical = {
            "kind": pin.get("kind"),
            "location": pin.get("location"),
            "state": pin.get("state"),
        }
        if identity in pins:
            errors.append(f"{path}: duplicate pin identity {identity}")
        pins[identity] = canonical
    return pins


def _resolved_sentry_root(root: Path, errors: list[str]) -> Path | None:
    config_path = root / ".dart_tool/package_config.json"
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"{config_path}: unavailable ({error}); run flutter pub get first")
        return None
    packages = config.get("packages") if isinstance(config, dict) else None
    if not isinstance(packages, list):
        errors.append(f"{config_path}: missing packages list; run flutter pub get first")
        return None
    package = next(
        (item for item in packages if isinstance(item, dict) and item.get("name") == "sentry_flutter"),
        None,
    )
    if package is None or not isinstance(package.get("rootUri"), str):
        errors.append(f"{config_path}: sentry_flutter is not resolved; run flutter pub get first")
        return None

    uri = package["rootUri"]
    parsed = urlparse(uri)
    if parsed.scheme == "file":
        return Path(url2pathname(parsed.path))
    if parsed.scheme:
        errors.append(f"{config_path}: unsupported sentry_flutter root URI {uri!r}")
        return None
    return (config_path.parent / unquote(uri)).resolve()


def _manifest_requirement(path: Path, errors: list[str]) -> str | None:
    try:
        source = path.read_text(encoding="utf-8")
    except OSError as error:
        errors.append(f"{path}: unavailable ({error}); run flutter pub get first")
        return None
    versions = EXACT_REQUIREMENT.findall(source)
    if len(versions) != 1:
        errors.append(f"{path}: expected exactly one exact sentry-cocoa requirement, found {len(versions)}")
        return None
    return versions[0]


def validate(root: Path) -> list[str]:
    root = root.resolve()
    errors: list[str] = []
    lock_maps: dict[Path, dict[str, dict]] = {}
    for platform, relative_paths in LOCK_PAIRS.items():
        first_path, second_path = (root / path for path in relative_paths)
        first = _load_pin_map(first_path, errors)
        second = _load_pin_map(second_path, errors)
        lock_maps[first_path] = first
        lock_maps[second_path] = second
        if first != second:
            identities = sorted(set(first) | set(second))
            differing = [identity for identity in identities if first.get(identity) != second.get(identity)]
            errors.append(
                f"{platform} SwiftPM locks differ between {first_path} and {second_path}: "
                + ", ".join(differing)
            )

    sentry_root = _resolved_sentry_root(root, errors)
    required_versions: list[str] = []
    if sentry_root is not None:
        for platform in ("ios", "macos"):
            version = _manifest_requirement(sentry_root / platform / "sentry_flutter/Package.swift", errors)
            if version is not None:
                required_versions.append(version)
    if len(set(required_versions)) > 1:
        errors.append("iOS and macOS sentry_flutter manifests require different sentry-cocoa versions")

    required_version = required_versions[0] if required_versions and len(set(required_versions)) == 1 else None
    sentry_pins: list[tuple[Path, dict]] = []
    for path, pins in lock_maps.items():
        pin = pins.get(SENTRY_IDENTITY)
        if pin is None:
            errors.append(f"{path}: missing {SENTRY_IDENTITY} pin")
            continue
        sentry_pins.append((path, pin))
        state = pin.get("state")
        version = state.get("version") if isinstance(state, dict) else None
        if required_version is not None and version != required_version:
            errors.append(f"{path}: {SENTRY_IDENTITY} is {version!r}, manifest requires exactly {required_version}")

    if sentry_pins:
        canonical_path, canonical_pin = sentry_pins[0]
        for path, pin in sentry_pins[1:]:
            if pin != canonical_pin:
                errors.append(f"{path}: {SENTRY_IDENTITY} state differs from {canonical_path}")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args(argv)
    errors = validate(args.root)
    if errors:
        for error in errors:
            print(f"error: {error}")
        return 1
    print("Apple SwiftPM locks match each other and the resolved Sentry manifests.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
