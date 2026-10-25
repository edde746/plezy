#!/usr/bin/env python3
"""Validate that release-worthy changes update the Unreleased changelog section."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
CHANGELOG_PATH = "CHANGELOG.md"
UNRELEASED_HEADING = "## [Unreleased]"
HEADING_PATTERN = re.compile(r"^## \[[^]]+\](?:\s+-\s+\d{4}-\d{2}-\d{2})?\s*$")
RELEASE_WORTHY_ROOTS = {
    "android",
    "assets",
    "ios",
    "lib",
    "linux",
    "macos",
    "packages",
    "packaging",
    "server",
    "web",
    "windows",
}
RELEASE_WORTHY_FILES = {
    "pubspec.yaml",
    "pubspec.lock",
    "scripts/announce_discord.py",
    "scripts/create_release_checksums.py",
    "scripts/generate_release_notes.py",
    "scripts/generate_winget_manifests.py",
}
RELEASE_WORTHY_WORKFLOWS = {
    ".github/workflows/build.yml",
    ".github/workflows/discord-release.yml",
    ".github/workflows/update-packages.yml",
    ".github/workflows/publish-chocolatey.yml",
    ".github/workflows/publish-winget.yml",
    ".github/workflows/release-containers.yml",
}
NON_RELEASE_DIRECTORY_NAMES = {"test", "tests", "__tests__"}
PLACEHOLDER_PATTERN = re.compile(
    r"\b(?:todo|tbd|placeholder)\b|add release notes here|\*\s*\(none\)\s*\*",
    re.IGNORECASE,
)


class ChangelogError(Exception):
    """A changelog validation or generation error."""


def git(*args: str, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=str(ROOT),
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if check and result.returncode != 0:
        raise ChangelogError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


def changed_paths(mode: str, base: str | None, head: str) -> list[str]:
    if mode == "staged":
        output = git("diff", "--cached", "--name-only", "--diff-filter=ACMRD", "-z")
    else:
        if not base:
            raise ChangelogError("range mode requires --base <ref> and --head <ref>")
        output = git(
            "diff",
            "--name-only",
            "--diff-filter=ACMRD",
            "-z",
            f"{base}...{head}",
        )
    return [path for path in output.split("\0") if path]


def is_release_worthy(path: str) -> bool:
    if path == CHANGELOG_PATH:
        return False
    if path in RELEASE_WORTHY_WORKFLOWS:
        return True
    if path in RELEASE_WORTHY_FILES:
        return True

    parsed = PurePosixPath(path)
    if not parsed.parts or parsed.parts[0] not in RELEASE_WORTHY_ROOTS:
        return False
    if any(part in NON_RELEASE_DIRECTORY_NAMES for part in parsed.parts):
        return False
    if parsed.name.endswith(("_test.dart", ".test.dart", ".spec.dart")):
        return False
    return True


def read_changelog(ref: str) -> str:
    if ref == ":index":
        return git("show", f":{CHANGELOG_PATH}", check=False)
    return git("show", f"{ref}:{CHANGELOG_PATH}", check=False)


def extract_section(changelog: str, heading: str) -> tuple[int, str]:
    lines = changelog.splitlines()
    headings = [index for index, line in enumerate(lines) if line == heading]
    if not headings:
        return 0, ""
    start = headings[0] + 1
    end = len(lines)
    for index in range(start, len(lines)):
        if lines[index].startswith("## ["):
            end = index
            break
    content = [line for line in lines[start:end] if line != "---"]
    return len(headings), "\n".join(content).strip()


def has_bullet(section: str) -> bool:
    return bool(re.search(r"^\s*-\s+\S", section, re.MULTILINE))


def validate(mode: str, base: str | None, head: str) -> None:
    release_paths = [path for path in changed_paths(mode, base, head) if is_release_worthy(path)]
    if not release_paths:
        print("No release-worthy changes need a changelog entry.")
        return

    before_ref, after_ref = ("HEAD", ":index") if mode == "staged" else (base, head)
    before_count, before_section = extract_section(read_changelog(before_ref), UNRELEASED_HEADING)
    after_changelog = read_changelog(after_ref)
    after_count, after_section = extract_section(after_changelog, UNRELEASED_HEADING)

    if after_count != 1:
        raise ChangelogError(
            f"{CHANGELOG_PATH} must contain exactly one {UNRELEASED_HEADING} heading; found {after_count}."
        )
    if not has_bullet(after_section) or PLACEHOLDER_PATTERN.search(after_section):
        raise ChangelogError(
            f"Release-worthy changes require a real bullet under {CHANGELOG_PATH} → {UNRELEASED_HEADING}."
        )
    if before_count == 1 and before_section == after_section:
        raise ChangelogError(
            f"Release-worthy changes were detected, but {CHANGELOG_PATH} → {UNRELEASED_HEADING} was not updated."
        )

    print(f"Changelog entry validated for {len(release_paths)} release-worthy path(s).")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    validate_parser = subparsers.add_parser("validate", help="validate staged changes or a Git range")
    validate_parser.add_argument("--mode", choices=("staged", "range"), default="staged")
    validate_parser.add_argument("--base", help="base ref used in range mode")
    validate_parser.add_argument("--head", default="HEAD", help="head ref used in range mode")
    args = parser.parse_args()

    try:
        validate(args.mode, args.base, args.head)
    except ChangelogError as error:
        print(f"changelog check: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
