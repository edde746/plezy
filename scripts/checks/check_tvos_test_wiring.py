#!/usr/bin/env python3
"""Validate tvOS RunnerTests project wiring against the files on disk."""

from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path

PROJECT_PATH = Path("tvos/Runner.xcodeproj/project.pbxproj")
RUNNER_TESTS_PATH = Path("tvos/RunnerTests")
COMPILED_TEST_EXTENSIONS = {".swift", ".m", ".mm"}

_OBJECT = re.compile(
    r"^(?P<indent>[ \t]*)(?P<uuid>[0-9A-F]+) /\* (?P<comment>[^\n]+?) \*/ = \{\n"
    r"(?P<body>.*?)^(?P=indent)\};",
    re.MULTILINE | re.DOTALL,
)
_LIST_ENTRY = re.compile(r"^[ \t]*([0-9A-F]+) /\* ([^\n]+?) \*/,?[ \t]*$", re.MULTILINE)


def _assignment(body: str, name: str) -> str | None:
    match = re.search(rf"^[ \t]*{re.escape(name)} = ([^;\n]+);[ \t]*$", body, re.MULTILINE)
    return match.group(1) if match else None


def _list_entries(body: str, name: str) -> list[tuple[str, str]] | None:
    match = re.search(
        rf"^[ \t]*{re.escape(name)} = \(\n(?P<entries>.*?)^[ \t]*\);[ \t]*$",
        body,
        re.MULTILINE | re.DOTALL,
    )
    if match is None:
        return None
    return [(entry.group(1), entry.group(2)) for entry in _LIST_ENTRY.finditer(match.group("entries"))]


def _describe_difference(label: str, actual: list[str], expected: list[str], errors: list[str]) -> None:
    duplicates = sorted(name for name, count in Counter(actual).items() if count > 1)
    if duplicates:
        errors.append(f"{label} has duplicate entries: {', '.join(duplicates)}")

    missing = sorted(set(expected) - set(actual))
    if missing:
        errors.append(f"{label} is missing: {', '.join(missing)}")
    unexpected = sorted(set(actual) - set(expected))
    if unexpected:
        errors.append(f"{label} has stale entries: {', '.join(unexpected)}")


def validate(root: Path) -> list[str]:
    root = root.resolve()
    errors: list[str] = []
    tests_path = root / RUNNER_TESTS_PATH
    project_path = root / PROJECT_PATH

    try:
        test_files = sorted(path.name for path in tests_path.iterdir() if not path.name.startswith("."))
    except OSError as error:
        errors.append(f"{tests_path}: cannot read RunnerTests directory: {error}")
        return errors

    try:
        project = project_path.read_text(encoding="utf-8")
    except OSError as error:
        errors.append(f"{project_path}: cannot read Xcode project: {error}")
        return errors

    objects = {match.group("uuid"): match.group("body") for match in _OBJECT.finditer(project)}
    groups = [
        body
        for body in objects.values()
        if _assignment(body, "isa") == "PBXGroup"
        and _assignment(body, "name") == "RunnerTests"
        and _assignment(body, "path") == "RunnerTests"
    ]
    if len(groups) != 1:
        errors.append(f"{project_path}: expected one RunnerTests PBXGroup, found {len(groups)}")
    else:
        children = _list_entries(groups[0], "children")
        if children is None:
            errors.append(f"{project_path}: RunnerTests PBXGroup has no children list")
        else:
            _describe_difference("RunnerTests PBXGroup", [name for _, name in children], test_files, errors)

    targets = [
        body
        for body in objects.values()
        if _assignment(body, "isa") == "PBXNativeTarget" and _assignment(body, "name") == "RunnerTests"
    ]
    if len(targets) != 1:
        errors.append(f"{project_path}: expected one RunnerTests PBXNativeTarget, found {len(targets)}")
        return errors

    build_phases = _list_entries(targets[0], "buildPhases")
    if build_phases is None:
        errors.append(f"{project_path}: RunnerTests target has no buildPhases list")
        return errors
    source_phase_ids = [uuid for uuid, comment in build_phases if comment == "Sources"]
    if len(source_phase_ids) != 1:
        errors.append(f"{project_path}: RunnerTests target must reference one Sources phase, found {len(source_phase_ids)}")
        return errors

    source_phase = objects.get(source_phase_ids[0])
    if source_phase is None or _assignment(source_phase, "isa") != "PBXSourcesBuildPhase":
        errors.append(f"{project_path}: RunnerTests Sources phase object is missing or invalid")
        return errors
    source_entries = _list_entries(source_phase, "files")
    if source_entries is None:
        errors.append(f"{project_path}: RunnerTests Sources phase has no files list")
        return errors

    source_names = [name.removesuffix(" in Sources") for _, name in source_entries]
    compiled_test_files = [name for name in test_files if Path(name).suffix in COMPILED_TEST_EXTENSIONS]
    _describe_difference("RunnerTests Sources phase", source_names, compiled_test_files, errors)
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args(argv)
    errors = validate(args.root)
    if errors:
        for error in errors:
            print(f"error: {error}")
        return 1
    print("tvOS RunnerTests project wiring matches the files on disk.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
