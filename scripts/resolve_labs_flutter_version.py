#!/usr/bin/env python3
"""Resolve the Flutter SDK pin from an official Plezy build workflow."""

from __future__ import annotations

import re
import sys


NUMERIC_VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
FLUTTER_PIN = re.compile(r"^\s*flutter-version:\s*(.*?)\s*$")
ENV_REFERENCE = "${{ env.FLUTTER_VERSION }}"


def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def top_level_flutter_version(workflow: str) -> str | None:
    in_top_level_env = False
    values: list[str] = []

    for line in workflow.splitlines():
        if line and not line[0].isspace() and not line.lstrip().startswith("#"):
            in_top_level_env = line.rstrip() == "env:"
            continue
        if not in_top_level_env:
            continue
        match = re.match(r"^[ \t]+FLUTTER_VERSION:\s*(.*?)\s*$", line)
        if match:
            values.append(unquote(match.group(1)))

    unique = sorted(set(values))
    if len(unique) > 1:
        raise ValueError(f"Found conflicting top-level FLUTTER_VERSION values: {unique}")
    return unique[0] if unique else None


def resolve_flutter_version(workflow: str) -> str:
    env_version = top_level_flutter_version(workflow)
    resolved: set[str] = set()
    pins = 0

    for line in workflow.splitlines():
        match = FLUTTER_PIN.match(line)
        if not match:
            continue
        pins += 1
        value = unquote(match.group(1))
        if value == ENV_REFERENCE:
            if env_version is None:
                raise ValueError("flutter-version references env.FLUTTER_VERSION, but the top-level env pin is missing")
            resolved.add(env_version)
        elif NUMERIC_VERSION.fullmatch(value):
            resolved.add(value)
        else:
            raise ValueError(f"Unsupported upstream flutter-version value: {value}")

    if pins == 0:
        raise ValueError("The upstream build workflow has no flutter-version pins")
    if len(resolved) != 1:
        raise ValueError(f"Expected one upstream Flutter version, found: {sorted(resolved)}")

    version = resolved.pop()
    if not NUMERIC_VERSION.fullmatch(version):
        raise ValueError(f"Official Flutter pin is not numeric X.Y.Z: {version}")
    return version


def main() -> None:
    try:
        print(resolve_flutter_version(sys.stdin.read()))
    except ValueError as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main()
