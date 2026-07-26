#!/usr/bin/env python3
"""Require immutable commit pins for remote GitHub Actions dependencies."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import workflow_yaml

ROOT = Path(__file__).resolve().parent.parent
WORKFLOWS = ROOT / ".github" / "workflows"
ACTIONS = ROOT / ".github" / "actions"
REMOTE_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_./-]+)?@[0-9a-fA-F]{40}$")


def iter_action_files(directory: Path = ACTIONS):
    """Local composite actions run in the same trust boundary as the workflows."""
    yield from sorted((*directory.glob("*/action.yml"), *directory.glob("*/action.yaml")))


def iter_uses_references(path: Path):
    return workflow_yaml.iter_uses_references(path.read_text(encoding="utf-8"))


def validate_reference(reference: str) -> str | None:
    if reference.startswith("./"):
        return None
    if REMOTE_RE.fullmatch(reference):
        return None
    return "remote actions must use a full 40-character commit SHA"


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    paths = (
        [Path(value) for value in args]
        if args
        else [*workflow_yaml.iter_workflow_files(WORKFLOWS), *iter_action_files()]
    )
    violations = []
    for path in paths:
        for line_number, reference in iter_uses_references(path):
            reason = validate_reference(reference)
            if reason:
                try:
                    display_path = path.resolve().relative_to(ROOT)
                except ValueError:
                    display_path = path
                violations.append(f"{display_path}:{line_number}: {reference!r}: {reason}")
    if violations:
        print("Mutable or malformed GitHub Actions references:", file=sys.stderr)
        for violation in violations:
            print(f"  {violation}", file=sys.stderr)
        return 1
    print(f"Workflow action pins verified ({len(paths)} files).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
