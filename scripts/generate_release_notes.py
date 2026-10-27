#!/usr/bin/env python3
"""Render release notes from a versioned CHANGELOG.md section and Unreleased."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HEADING_PATTERN = re.compile(r"^## \[([^]]+)\](?:\s+-\s+\d{4}-\d{2}-\d{2})?\s*$")
PLACEHOLDER_PATTERN = re.compile(
    r"\b(?:todo|tbd|placeholder)\b|add release notes here|no recorded changes|no changes",
    re.IGNORECASE,
)


def sections(changelog: str) -> tuple[dict[str, str], set[str]]:
    lines = changelog.splitlines()
    result: dict[str, str] = {}
    heading_counts: dict[str, int] = {}
    heading_index = None
    heading_name = None

    def save(end: int) -> None:
        if heading_index is None or heading_name is None:
            return
        body = [line for line in lines[heading_index + 1 : end] if line != "---"]
        result[heading_name] = "\n".join(body).strip()

    for index, line in enumerate(lines):
        match = HEADING_PATTERN.fullmatch(line)
        if not match:
            continue
        save(index)
        heading_index = index
        heading_name = match.group(1)
        heading_counts[heading_name] = heading_counts.get(heading_name, 0) + 1

    save(len(lines))
    duplicates = {name for name, count in heading_counts.items() if count > 1}
    return result, duplicates


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", help="release version, for example 2.24.1")
    parser.add_argument(
        "--changelog",
        type=Path,
        default=ROOT / "CHANGELOG.md",
        help="path to the project changelog",
    )
    args = parser.parse_args()

    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        parser.error("version must use semantic versioning (for example 2.24.1)")
    try:
        changelog = args.changelog.read_text(encoding="utf-8")
    except OSError as error:
        print(f"release notes: cannot read changelog: {error}", file=sys.stderr)
        return 1

    entries, duplicates = sections(changelog)
    if args.version in duplicates:
        print(f"release notes: CHANGELOG.md has duplicate sections for {args.version}.", file=sys.stderr)
        return 1
    if "Unreleased" in duplicates:
        print("release notes: CHANGELOG.md has duplicate [Unreleased] sections.", file=sys.stderr)
        return 1
    versioned = entries.get(args.version, "")
    unreleased = entries.get("Unreleased", "")
    if versioned and unreleased:
        section = (
            f"{versioned}\n\n### Additional release updates\n\n{unreleased}"
        )
    else:
        section = versioned or unreleased
    if (
        not section
        or not re.search(r"^\s*-\s+\S", section, re.MULTILINE)
        or PLACEHOLDER_PATTERN.search(section)
    ):
        print(
            f"release notes: CHANGELOG.md needs a meaningful, non-placeholder section for {args.version} or [Unreleased].",
            file=sys.stderr,
        )
        return 1

    print(f"# PlezyNG {args.version}\n\n{section}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
