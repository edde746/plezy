#!/usr/bin/env python3
"""Enforce an exact, expiring baseline for the website's Bun audit results."""

from __future__ import annotations

import argparse
from collections.abc import Callable
from dataclasses import dataclass
from datetime import date, timedelta
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Any


MAX_ACCEPTANCE_DAYS = 90
MAX_AUDIT_OUTPUT_BYTES = 5 * 1024 * 1024
MAX_DIAGNOSTICS = 20
MAX_ID_LENGTH = 128
MAX_PACKAGE_LENGTH = 214
MAX_RANGE_LENGTH = 256
MAX_RATIONALE_LENGTH = 500
MAX_SCANNER_DIAGNOSTIC_LENGTH = 300
SEVERITIES = frozenset({"low", "moderate", "high", "critical"})
ISO_DATE = re.compile(r"\d{4}-\d{2}-\d{2}")
PACKAGE_NAME = re.compile(
    r"(?:@[a-z0-9][a-z0-9._~-]*/)?[a-z0-9][a-z0-9._~-]*",
    re.IGNORECASE,
)
ANSI_ESCAPE = re.compile(r"\x1b\[[0-9;]*m")
EXPECTED_BUN_BANNER = re.compile(r"bun audit v1\.3\.14 \([0-9a-f]{8}\)")


@dataclass(frozen=True)
class Advisory:
    advisory_id: str
    package: str
    severity: str
    vulnerable_range: str

    @property
    def identity(self) -> tuple[str, str]:
        return (self.advisory_id, self.package)

    @property
    def label(self) -> str:
        return f"{self.advisory_id} ({self.package})"


@dataclass(frozen=True)
class Acceptance:
    advisory: Advisory
    expires_on: date
    rationale: str


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read valid JSON from {path}: {error}") from error


def _parse_iso_date(value: Any, field: str) -> date:
    if not isinstance(value, str) or ISO_DATE.fullmatch(value) is None:
        raise ValueError(f"{field} must be an ISO date in YYYY-MM-DD form")
    try:
        parsed = date.fromisoformat(value)
    except ValueError as error:
        raise ValueError(f"{field} must be an ISO date in YYYY-MM-DD form") from error
    if parsed.isoformat() != value:
        raise ValueError(f"{field} must be an ISO date in YYYY-MM-DD form")
    return parsed

def _bounded_string(
    value: Any,
    *,
    field: str,
    maximum: int,
    pattern: re.Pattern[str] | None = None,
) -> str:
    if (
        not isinstance(value, str)
        or not value
        or value != value.strip()
        or len(value) > maximum
        or any(ord(character) < 32 for character in value)
        or (pattern is not None and pattern.fullmatch(value) is None)
    ):
        raise ValueError(f"{field} is invalid")
    return value


def load_baseline(path: Path) -> tuple[date, dict[tuple[str, str], Acceptance]]:
    payload = _load_json(path)
    if not isinstance(payload, dict) or set(payload) != {
        "schemaVersion",
        "reviewedOn",
        "accepted",
    }:
        raise ValueError("baseline must contain schemaVersion, reviewedOn, and accepted")
    if payload["schemaVersion"] != 1:
        raise ValueError("unsupported baseline schemaVersion")
    reviewed_on = _parse_iso_date(payload["reviewedOn"], "reviewedOn")
    entries = payload["accepted"]
    if not isinstance(entries, list):
        raise ValueError("baseline accepted must be a list")

    accepted: dict[tuple[str, str], Acceptance] = {}
    required = {
        "id",
        "package",
        "severity",
        "vulnerableRange",
        "expiresOn",
        "rationale",
    }
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict) or set(entry) != required:
            raise ValueError(f"baseline accepted[{index}] has an unknown schema")
        if not isinstance(entry["id"], (str, int)) or isinstance(entry["id"], bool):
            raise ValueError(f"baseline accepted[{index}] has an invalid advisory id")
        advisory_id = _bounded_string(
            str(entry["id"]),
            field=f"baseline accepted[{index}].id",
            maximum=MAX_ID_LENGTH,
            pattern=re.compile(r"[A-Za-z0-9][A-Za-z0-9._:-]*"),
        )
        package = _bounded_string(
            entry["package"],
            field=f"baseline accepted[{index}].package",
            maximum=MAX_PACKAGE_LENGTH,
            pattern=PACKAGE_NAME,
        )
        severity = _bounded_string(
            entry["severity"],
            field=f"baseline accepted[{index}].severity",
            maximum=16,
        )
        if severity not in SEVERITIES:
            raise ValueError(f"baseline accepted[{index}].severity is invalid")
        vulnerable_range = _bounded_string(
            entry["vulnerableRange"],
            field=f"baseline accepted[{index}].vulnerableRange",
            maximum=MAX_RANGE_LENGTH,
        )
        rationale = _bounded_string(
            entry["rationale"],
            field=f"baseline accepted[{index}].rationale",
            maximum=MAX_RATIONALE_LENGTH,
        )
        advisory = Advisory(
            advisory_id=advisory_id,
            package=package,
            severity=severity,
            vulnerable_range=vulnerable_range,
        )
        expires_on = _parse_iso_date(entry["expiresOn"], f"accepted[{index}].expiresOn")
        if expires_on < reviewed_on:
            raise ValueError(f"baseline {advisory.label} expires before its review date")
        if expires_on > reviewed_on + timedelta(days=MAX_ACCEPTANCE_DAYS):
            raise ValueError(
                f"baseline {advisory.label} expires more than {MAX_ACCEPTANCE_DAYS} days after review"
            )
        if advisory.identity in accepted:
            raise ValueError(f"duplicate baseline advisory {advisory.label}")
        accepted[advisory.identity] = Acceptance(
            advisory=advisory,
            expires_on=expires_on,
            rationale=rationale,
        )
    return reviewed_on, accepted


def parse_audit_json(output: str) -> dict[tuple[str, str], Advisory]:
    if len(output.encode("utf-8")) > MAX_AUDIT_OUTPUT_BYTES:
        raise ValueError("bun audit result exceeds the policy size limit")
    try:
        payload = json.loads(output)
    except json.JSONDecodeError as error:
        raise ValueError(f"bun audit returned malformed JSON: {error.msg}") from error
    if not isinstance(payload, dict):
        raise ValueError("bun audit result must be a package object")

    advisories: dict[tuple[str, str], Advisory] = {}
    for package_value, package_entries in payload.items():
        package = _bounded_string(
            package_value,
            field="bun audit package name",
            maximum=MAX_PACKAGE_LENGTH,
            pattern=PACKAGE_NAME,
        )
        if not isinstance(package_entries, list) or not package_entries:
            raise ValueError(f"bun audit entries for {package} must be a non-empty list")
        for index, entry in enumerate(package_entries):
            if not isinstance(entry, dict):
                raise ValueError(f"bun audit entry {package}[{index}] must be an object")
            required = ("id", "severity", "vulnerable_versions")
            if any(field not in entry for field in required):
                raise ValueError(f"bun audit entry {package}[{index}] has an unknown schema")
            if not isinstance(entry["id"], (str, int)) or isinstance(entry["id"], bool):
                raise ValueError(f"bun audit entry {package}[{index}] has an invalid id")
            advisory_id = _bounded_string(
                str(entry["id"]),
                field=f"bun audit entry {package}[{index}].id",
                maximum=MAX_ID_LENGTH,
                pattern=re.compile(r"[A-Za-z0-9][A-Za-z0-9._:-]*"),
            )
            severity = _bounded_string(
                entry["severity"],
                field=f"bun audit entry {package}[{index}].severity",
                maximum=16,
            )
            if severity not in SEVERITIES:
                raise ValueError(f"bun audit entry {package}[{index}].severity is invalid")
            vulnerable_range = _bounded_string(
                entry["vulnerable_versions"],
                field=f"bun audit entry {package}[{index}].vulnerable_versions",
                maximum=MAX_RANGE_LENGTH,
            )
            advisory = Advisory(
                advisory_id=advisory_id,
                package=package,
                severity=severity,
                vulnerable_range=vulnerable_range,
            )
            if advisory.identity in advisories:
                raise ValueError(f"bun audit returned duplicate advisory {advisory.label}")
            advisories[advisory.identity] = advisory
    return advisories


def _has_scanner_diagnostic(stderr: str) -> bool:
    rendered = ANSI_ESCAPE.sub("", stderr).strip()
    return bool(rendered) and EXPECTED_BUN_BANNER.fullmatch(rendered) is None


def evaluate(
    *,
    exit_code: int,
    output: str,
    accepted: dict[tuple[str, str], Acceptance],
    today: date,
    stderr: str = "",
) -> list[str]:
    if exit_code not in (0, 1):
        return [f"bun audit execution failed with exit code {exit_code}"]
    if _has_scanner_diagnostic(stderr):
        return ["bun audit reported a scanner or network diagnostic"]
    try:
        current = parse_audit_json(output)
    except (UnicodeError, ValueError) as error:
        return [str(error)]
    if exit_code == 0 and current:
        return ["bun audit exited cleanly but returned advisories"]
    if exit_code == 1 and not current:
        return ["bun audit exited with advisories but returned an empty result"]

    errors = []
    for identity, advisory in sorted(current.items()):
        acceptance = accepted.get(identity)
        if acceptance is None:
            errors.append(f"unaccepted advisory {advisory.label}")
            continue
        if acceptance.expires_on < today:
            errors.append(
                f"expired acceptance {advisory.label} ({acceptance.expires_on.isoformat()})"
            )
        if acceptance.advisory.severity != advisory.severity:
            errors.append(
                f"severity changed for {advisory.label}: "
                f"{acceptance.advisory.severity} -> {advisory.severity}"
            )
        if acceptance.advisory.vulnerable_range != advisory.vulnerable_range:
            errors.append(
                f"vulnerable range changed for {advisory.label}: "
                f"{acceptance.advisory.vulnerable_range} -> {advisory.vulnerable_range}"
            )
    for identity, acceptance in sorted(accepted.items()):
        if identity not in current:
            errors.append(f"stale baseline advisory {acceptance.advisory.label}")
    if len(errors) > MAX_DIAGNOSTICS:
        omitted = len(errors) - MAX_DIAGNOSTICS
        return errors[:MAX_DIAGNOSTICS] + [
            f"{omitted} additional policy error(s) omitted"
        ]
    return errors


def _run_bun_audit(project: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bun", "audit", "--json"],
        cwd=project,
        check=False,
        capture_output=True,
        text=True,
    )

def _scanner_diagnostic(value: str) -> str:
    compact = " ".join(value.split())
    if len(compact) > MAX_SCANNER_DIAGNOSTIC_LENGTH:
        return f"{compact[:MAX_SCANNER_DIAGNOSTIC_LENGTH]}..."
    return compact


def main(
    argv: list[str] | None = None,
    *,
    run_audit: Callable[[Path], subprocess.CompletedProcess[str]] = _run_bun_audit,
    today: date | None = None,
) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    args = parser.parse_args(argv)
    evaluation_date = date.today() if today is None else today

    project = args.project.resolve()
    baseline_path = args.baseline
    if not baseline_path.is_absolute():
        baseline_path = project / baseline_path
    if not (project / "bun.lock").is_file():
        print(f"ERROR: missing Bun lockfile in {project}", file=sys.stderr)
        return 1
    try:
        reviewed_on, accepted = load_baseline(baseline_path)
        if reviewed_on > evaluation_date:
            raise ValueError("baseline reviewedOn cannot be in the future")
    except ValueError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    try:
        result = run_audit(project)
    except (OSError, subprocess.SubprocessError) as error:
        print(f"ERROR: cannot execute bun audit: {_scanner_diagnostic(str(error))}", file=sys.stderr)
        return 1
    errors = evaluate(
        exit_code=result.returncode,
        output=result.stdout,
        stderr=result.stderr,
        accepted=accepted,
        today=evaluation_date,
    )
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        if result.stderr.strip():
            print(
                f"ERROR: bun audit diagnostic: {_scanner_diagnostic(result.stderr)}",
                file=sys.stderr,
            )
        return 1

    print(f"Bun advisory policy passed ({len(accepted)} reviewed acceptance(s)).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
