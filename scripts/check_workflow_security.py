#!/usr/bin/env python3
"""Enforce trust-boundary invariants across GitHub Actions workflows."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"
FULL_SHA = re.compile(r"[0-9a-f]{40}")
PR_TRIGGER = re.compile(r"(?m)^  pull_request:\s*$")


def _active_text(text: str) -> str:
    return "\n".join(
        "" if line.lstrip().startswith("#") else line for line in text.splitlines()
    )


def check_workflow(path: Path, text: str) -> list[str]:
    errors: list[str] = []
    active = _active_text(text)

    for dangerous_trigger in ("pull_request_target:", "workflow_run:"):
        if dangerous_trigger in active:
            errors.append(f"{path}: unaudited privileged trigger {dangerous_trigger[:-1]}")

    checkout_count = 0
    for line_number, line in enumerate(active.splitlines(), start=1):
        match = re.match(r"^\s*(?:-\s+)?uses:\s+(.+?)\s*$", line)
        if match is None:
            continue
        reference = match.group(1).split(" #", maxsplit=1)[0].strip()
        if reference.startswith("./"):
            continue
        action, separator, ref = reference.rpartition("@")
        if not separator or not action or FULL_SHA.fullmatch(ref) is None:
            errors.append(
                f"{path}:{line_number}: external action must use a full commit SHA: {reference}"
            )
        if action == "actions/checkout":
            checkout_count += 1

    if re.search(
        r"https://raw\.githubusercontent\.com/[^/\s]+/[^/\s]+/(?:main|master)/",
        active,
    ):
        errors.append(f"{path}: raw GitHub downloads must use an immutable commit")

    if PR_TRIGGER.search(active):
        if "secrets." in active:
            errors.append(f"{path}: pull-request workflow must not reference repository secrets")
        if re.search(r"(?m)^\s+[a-zA-Z0-9_-]+:\s+write\s*$", active):
            errors.append(f"{path}: pull-request workflow must not request write permissions")
        if active.count("persist-credentials: false") != checkout_count:
            errors.append(
                f"{path}: every pull-request checkout must discard GitHub credentials"
            )

    return errors


def main() -> int:
    errors: list[str] = []
    for path in sorted(WORKFLOWS.glob("*.yml")):
        errors.extend(check_workflow(path.relative_to(ROOT), path.read_text(encoding="utf-8")))

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("workflow security checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
