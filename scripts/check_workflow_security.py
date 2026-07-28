#!/usr/bin/env python3
"""Enforce trust-boundary invariants across GitHub Actions workflows."""

from pathlib import Path
import re
import sys

from workflow_yaml import iter_uses_references, iter_workflow_files, scalar


ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"
CI_WORKFLOW = Path(".github/workflows/ci.yml")
FULL_SHA = re.compile(r"[0-9a-f]{40}")


def _active_text(text: str) -> str:
    return "\n".join(
        "" if line.lstrip().startswith("#") else line for line in text.splitlines()
    )


def _has_trigger(text: str, event: str) -> bool:
    lines = text.splitlines()
    on_key = r"""(?:on|'on'|"on")"""
    event_key = rf"""(?:{re.escape(event)}|'{re.escape(event)}'|"{re.escape(event)}")"""
    for index, line in enumerate(lines):
        if re.fullmatch(rf"{on_key}:\s*", line):
            for child in lines[index + 1 :]:
                if child.strip() and not child.startswith((" ", "\t")):
                    break
                if re.match(rf"^\s+{event_key}\s*:", child):
                    return True
        match = re.fullmatch(rf"{on_key}:\s*(.+?)\s*", line)
        if match is not None and re.search(
            rf"""(?:^|[\[{{,\s])['"]?{re.escape(event)}['"]?(?:$|[\]}},\s:])""",
            scalar(match.group(1)),
        ):
            return True
    return False


def _step_block(lines: list[str], line_index: int) -> str:
    uses_indent = len(lines[line_index]) - len(lines[line_index].lstrip())
    start = line_index
    for index in range(line_index, -1, -1):
        line = lines[index]
        indent = len(line) - len(line.lstrip())
        if re.match(r"^\s*-\s+", line) and indent <= uses_indent:
            start = index
            break
        if line.strip() and indent < uses_indent:
            break

    start_indent = len(lines[start]) - len(lines[start].lstrip())
    end = len(lines)
    for index in range(start + 1, len(lines)):
        line = lines[index]
        indent = len(line) - len(line.lstrip())
        if re.match(r"^\s*-\s+", line) and indent <= start_indent:
            end = index
            break
        if line.strip() and not line.lstrip().startswith("#") and indent < start_indent:
            end = index
            break
    return "\n".join(lines[start:end])


def _check_fail_open(path: Path, text: str) -> list[str]:
    """CI quality gates must not silently convert failures to successes."""
    if path.as_posix() != CI_WORKFLOW.as_posix():
        return []

    errors: list[str] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        match = re.match(
            r"""^\s*(?:-\s+)?(?:continue-on-error|'continue-on-error'|"continue-on-error")\s*:\s*(.*?)\s*$""",
            line,
        )
        if match is not None and scalar(match.group(1)).lower() != "false":
            errors.append(f"{path}:{line_number}: continue-on-error must remain false")
        if re.search(r"\|\|\s*true(?:\s|$)", line):
            errors.append(f"{path}:{line_number}: command must not suppress failure with || true")
    return errors


def check_workflow(path: Path, text: str) -> list[str]:
    errors: list[str] = []
    active = _active_text(text)

    for dangerous_trigger in ("pull_request_target", "workflow_run"):
        if _has_trigger(active, dangerous_trigger):
            errors.append(f"{path}: unaudited privileged trigger {dangerous_trigger}")

    pull_request = _has_trigger(active, "pull_request")
    lines = active.splitlines()
    for line_number, reference in iter_uses_references(active):
        if reference.startswith("./"):
            continue
        action, separator, ref = reference.rpartition("@")
        if not separator or not action or FULL_SHA.fullmatch(ref) is None:
            errors.append(
                f"{path}:{line_number}: external action must use a full commit SHA: {reference}"
            )
        if pull_request and action == "actions/checkout":
            step = _step_block(lines, line_number - 1)
            if re.search(
                r"""(?mi)^\s+(?:persist-credentials|'persist-credentials'|"persist-credentials")\s*:\s*['"]?false['"]?\s*(?:#.*)?$""",
                step,
            ) is None:
                errors.append(
                    f"{path}:{line_number}: pull-request checkout must discard GitHub credentials"
                )

    if re.search(
        r"https://raw\.githubusercontent\.com/[^/\s]+/[^/\s]+/(?:main|master)/",
        active,
    ):
        errors.append(f"{path}: raw GitHub downloads must use an immutable commit")

    if pull_request:
        if re.search(r"\bsecrets\s*(?:\.|\[)", active):
            errors.append(f"{path}: pull-request workflow must not reference repository secrets")
        if re.search(r"(?m)^\s+[a-zA-Z0-9_-]+:\s*write\s*(?:#.*)?$", active) or re.search(
            r"(?m)^\s*permissions:\s*\{[^}\n]*:\s*write(?:\s*[,}])", active
        ):
            errors.append(f"{path}: pull-request workflow must not request write permissions")

    errors.extend(_check_fail_open(path, active))
    return errors


def main() -> int:
    errors: list[str] = []
    for path in iter_workflow_files(WORKFLOWS):
        errors.extend(check_workflow(path.relative_to(ROOT), path.read_text(encoding="utf-8")))

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("workflow security checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
