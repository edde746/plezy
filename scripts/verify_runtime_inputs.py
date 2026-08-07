#!/usr/bin/env python3
"""Offline verification for reviewed Linux native and vendored binding inputs."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

HEX_256 = re.compile(r"^[0-9a-f]{64}$")
HEX_COMMIT = re.compile(r"^[0-9a-f]{40}$")
NATIVE_NAMES = {"ffmpeg", "shaderc", "libplacebo", "mpv", "simdutf"}
BINDING_ARTIFACTS = {
    "pigeons/messages.dart",
    "android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt",
    "ios/wakelock_plus/Sources/wakelock_plus/include/wakelock_plus/messages.g.h",
    "ios/wakelock_plus/Sources/wakelock_plus/messages.g.m",
}


def _load_json(path: Path, errors: list[str]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"{path}: cannot load JSON: {error}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"{path}: top-level value must be an object")
        return {}
    return value


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _require_text(value: Any, label: str, errors: list[str]) -> str:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{label}: must be non-empty text")
        return ""
    return value


def _locked_package(lock_text: str, name: str) -> tuple[str, str] | None:
    pattern = re.compile(
        rf"^  {re.escape(name)}:\n(?P<body>(?:    .*\n|      .*\n)+?)(?=^  [a-zA-Z0-9_]+:|\Z)",
        re.MULTILINE,
    )
    match = pattern.search(lock_text)
    if match is None:
        return None
    body = match.group("body")
    version = re.search(r'^    version: "([^\"]+)"$', body, re.MULTILINE)
    checksum = re.search(r'^      sha256: "?([0-9a-f]{64})"?$', body, re.MULTILINE)
    if version is None or checksum is None:
        return None
    return version.group(1), checksum.group(1)


def _validate_native(root: Path, errors: list[str]) -> None:
    manifest_path = root / "linux/packaging/native-inputs.json"
    manifest = _load_json(manifest_path, errors)
    if manifest.get("formatVersion") != 1:
        errors.append(f"{manifest_path}: formatVersion must be 1")


    inputs = manifest.get("inputs")
    if not isinstance(inputs, dict) or set(inputs) != NATIVE_NAMES:
        errors.append(f"{manifest_path}: inputs must be exactly {sorted(NATIVE_NAMES)}")
        return

    for name, value in inputs.items():
        label = f"{manifest_path}: inputs.{name}"
        if not isinstance(value, dict):
            errors.append(f"{label}: must be an object")
            continue
        kind = value.get("kind")
        version = _require_text(value.get("version"), f"{label}.version", errors)
        url = _require_text(value.get("url"), f"{label}.url", errors)
        _require_text(value.get("provenance"), f"{label}.provenance", errors)
        if url and not url.startswith("https://"):
            errors.append(f"{label}.url: production source must use HTTPS")
        # A fallback source is optional, but it is a production source when it is
        # used, so it answers to the same rule as the primary.
        mirror = value.get("mirror")
        if mirror is not None:
            if not isinstance(mirror, str) or not mirror.startswith("https://"):
                errors.append(f"{label}.mirror: production source must use HTTPS")
        if version and url and name in {"ffmpeg", "mpv", "simdutf"} and version not in url:
            errors.append(f"{label}.url: must identify declared version {version}")
        if kind == "archive":
            checksum = value.get("sha256")
            if not isinstance(checksum, str) or HEX_256.fullmatch(checksum) is None:
                errors.append(f"{label}.sha256: must be a lowercase full SHA-256")
        elif kind == "git":
            ref = value.get("ref")
            commit = value.get("commit")
            if not isinstance(ref, str) or ref != f"v{version}":
                errors.append(f"{label}.ref: must be v{version}")
            if not isinstance(commit, str) or HEX_COMMIT.fullmatch(commit) is None:
                errors.append(f"{label}.commit: must be a lowercase full Git commit")
        else:
            errors.append(f"{label}.kind: must be archive or git")

    cmake_path = root / "linux/CMakeLists.txt"
    try:
        cmake = cmake_path.read_text(encoding="utf-8")
    except OSError as error:
        errors.append(f"{cmake_path}: cannot read: {error}")
        cmake = ""
    simdutf = inputs.get("simdutf")
    if isinstance(simdutf, dict):
        simdutf_url = simdutf.get("url")
        simdutf_sha256 = simdutf.get("sha256")
        if isinstance(simdutf_url, str) and simdutf_url and f"URL {simdutf_url}" not in cmake:
            errors.append(f"{cmake_path}: simdutf URL differs from native-inputs.json")
        if (
            isinstance(simdutf_sha256, str)
            and HEX_256.fullmatch(simdutf_sha256) is not None
            and f"URL_HASH SHA256={simdutf_sha256}" not in cmake
        ):
            errors.append(f"{cmake_path}: simdutf SHA-256 differs from native-inputs.json")

    builder_path = root / "linux/packaging/build-libmpv.sh"
    try:
        builder = builder_path.read_text(encoding="utf-8")
    except OSError as error:
        errors.append(f"{builder_path}: cannot read: {error}")
        return
    required_builder_contracts = (
        "native-inputs.json",
        'download_verified "$FFMPEG_URL" "$FFMPEG_SHA256"',
        'download_verified "$MPV_URL" "$MPV_SHA256"',
        '"$SHADERC_URL" "$SHADERC_REF" "$SHADERC_COMMIT"',
        '"$LIBPLACEBO_URL" "$LIBPLACEBO_REF" "$LIBPLACEBO_COMMIT"',
        'git submodule update --init --recursive',
    )
    for contract_text in required_builder_contracts:
        if contract_text not in builder:
            errors.append(f"{builder_path}: missing manifest-backed acquisition contract {contract_text!r}")
    if re.search(r"curl[^\n]*\|[^\n]*tar", builder):
        errors.append(f"{builder_path}: archive extraction must not consume a curl stream")


def _validate_wakelock(root: Path, errors: list[str]) -> None:
    package = root / "packages/wakelock_plus"
    provenance_path = package / "provenance.json"
    provenance = _load_json(provenance_path, errors)
    if provenance.get("formatVersion") != 1:
        errors.append(f"{provenance_path}: formatVersion must be 1")

    upstream = provenance.get("upstream")
    if not isinstance(upstream, dict) or HEX_COMMIT.fullmatch(str(upstream.get("commit", ""))) is None:
        errors.append(f"{provenance_path}: upstream.commit must be a full Git commit")


    artifacts = provenance.get("artifacts")
    if not isinstance(artifacts, dict) or set(artifacts) != BINDING_ARTIFACTS:
        errors.append(f"{provenance_path}: artifacts must be exactly the schema and three host outputs")
    else:
        for relative, expected in artifacts.items():
            path = package / relative
            if not isinstance(expected, str) or HEX_256.fullmatch(expected) is None:
                errors.append(f"{provenance_path}: invalid artifact SHA-256 for {relative}")
            elif not path.is_file():
                errors.append(f"{path}: required binding artifact is missing")
            else:
                actual = _sha256(path)
                if actual != expected:
                    errors.append(f"{path}: SHA-256 drift (expected {expected}, got {actual})")

    try:
        pubspec = (package / "pubspec.yaml").read_text(encoding="utf-8")
        lock = (package / "pubspec.lock").read_text(encoding="utf-8")
        schema = (package / "pigeons/messages.dart").read_text(encoding="utf-8")
        root_lock = (root / "pubspec.lock").read_text(encoding="utf-8")
    except OSError as error:
        errors.append(f"{package}: cannot read package provenance input: {error}")
        return

    generator = provenance.get("generator") if isinstance(provenance.get("generator"), dict) else {}
    client = provenance.get("externalDartClient") if isinstance(provenance.get("externalDartClient"), dict) else {}
    expected_pigeon = (str(generator.get("version", "")), str(generator.get("archiveSha256", "")))
    expected_client = (str(client.get("version", "")), str(client.get("archiveSha256", "")))
    if not re.search(rf"^  pigeon: {re.escape(expected_pigeon[0])}$", pubspec, re.MULTILINE):
        errors.append(f"{package / 'pubspec.yaml'}: Pigeon must be pinned exactly to {expected_pigeon[0]}")
    if not re.search(
        rf"^  wakelock_plus_platform_interface: {re.escape(expected_client[0])}$", pubspec, re.MULTILINE
    ):
        errors.append(
            f"{package / 'pubspec.yaml'}: wakelock_plus_platform_interface must be pinned exactly to {expected_client[0]}"
        )
    if _locked_package(lock, "pigeon") != expected_pigeon:
        errors.append(f"{package / 'pubspec.lock'}: Pigeon version/checksum differs from provenance.json")
    if _locked_package(lock, "wakelock_plus_platform_interface") != expected_client:
        errors.append(
            f"{package / 'pubspec.lock'}: platform-interface version/checksum differs from provenance.json"
        )
    if _locked_package(root_lock, "wakelock_plus_platform_interface") != expected_client:
        errors.append(
            f"{root / 'pubspec.lock'}: runtime platform-interface version/checksum differs from provenance.json"
        )

    if "dartPackageName: 'wakelock_plus_platform_interface'" not in schema:
        errors.append(f"{package / 'pigeons/messages.dart'}: external Dart package name is not explicit")
    if re.search(r"\bdart(?:Test)?Out\s*:", schema):
        errors.append(f"{package / 'pigeons/messages.dart'}: host-only schema must not generate Dart outputs")
    for relative in BINDING_ARTIFACTS - {"pigeons/messages.dart"}:
        if relative not in schema:
            errors.append(f"{package / 'pigeons/messages.dart'}: missing owned output {relative}")

    binding_sources = (
        ("Kotlin", package / "android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt"),
        ("Objective-C", package / "ios/wakelock_plus/Sources/wakelock_plus/messages.g.m"),
    )
    for generated_name, generated_path in binding_sources:
        try:
            generated = generated_path.read_text(encoding="utf-8")
        except OSError as error:
            errors.append(f"{generated_path}: cannot read generated binding: {error}")
            continue
        if "26.2.3" not in generated:
            errors.append(f"{generated_name} binding was not generated by Pigeon 26.2.3")
        for method in ("WakelockPlusApi.toggle", "WakelockPlusApi.isEnabled"):
            if method not in generated:
                errors.append(f"{generated_name} binding is missing channel suffix {method}")
        for tag in ("129", "130"):
            if tag not in generated:
                errors.append(f"{generated_name} binding is missing codec tag {tag}")


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    _validate_native(root, errors)
    _validate_wakelock(root, errors)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    arguments = parser.parse_args()
    errors = validate(arguments.root.resolve())
    if errors:
        print("Runtime input provenance verification failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Runtime input provenance verified offline")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
