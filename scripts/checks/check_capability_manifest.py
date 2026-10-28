#!/usr/bin/env python3
"""Keep audit status, release checks, locale claims, and public docs aligned."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from workflow_yaml import job_block, scalar


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "docs/maintainers/capability-manifest.json"
ERRORS: list[str] = []
FINDING_IDS = [f"F{index:02d}" for index in range(1, 17)]
STATUSES = {"implemented", "partial", "gated"}


def require(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def display_name(workflow: str, key: str) -> str:
    block = job_block(workflow, key)
    require(bool(block), f"missing CI job {key}")
    match = re.search(r"(?m)^    name: (.+)$", block)
    require(match is not None, f"CI job {key} has no display name")
    return scalar(match.group(1)) if match else ""


def matrix_job_names(workflow: str, key: str, field: str) -> list[str]:
    template = display_name(workflow, key)
    placeholder = f"${{{{ matrix.{field} }}}}"
    require(placeholder in template, f"CI job {key} no longer names matrix field {field}")
    block = job_block(workflow, key)
    values = re.findall(rf"(?m)^\s+- {re.escape(field)}: ([A-Za-z0-9_-]+)\s*$", block)
    require(bool(values), f"CI job {key} has no {field} matrix values")
    require(len(values) == len(set(values)), f"CI job {key} repeats a {field} matrix value")
    return [template.replace(placeholder, value) for value in values]


def expected_ci_jobs(workflow: str) -> tuple[set[str], set[str]]:
    direct = (
        "analyze",
        "test",
        "android-test",
        "native-format",
        "dependency-check",
        "server",
    )
    required = {display_name(workflow, key) for key in direct}
    for key, field in (
        ("linux-native-test", "sanitizer"),
        ("apple-native-test", "platform"),
        ("windows-native-test", "arch"),
    ):
        required.update(matrix_job_names(workflow, key, field))
    optional_block = job_block(workflow, "linux-packages")
    optional = {display_name(workflow, "linux-packages")}
    require("inputs.build_linux_packages" in optional_block, "Linux package smoke build must remain conditional")
    return required, optional


def _load_manifest() -> dict | None:
    try:
        value = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        ERRORS.append(f"cannot read {MANIFEST_PATH.relative_to(ROOT)}: {error}")
        return None
    if not isinstance(value, dict):
        ERRORS.append("capability manifest root must be an object")
        return None
    return value


def _validate_paths(paths: object, label: str) -> None:
    if not isinstance(paths, list) or not paths:
        ERRORS.append(f"{label} must list at least one evidence path")
        return
    for value in paths:
        if not isinstance(value, str) or not value:
            ERRORS.append(f"{label} contains an invalid evidence path")
            continue
        candidate = (ROOT / value).resolve()
        if ROOT not in candidate.parents and candidate != ROOT:
            ERRORS.append(f"{label} escapes the repository: {value}")
        elif not candidate.exists():
            ERRORS.append(f"{label} references a missing path: {value}")


def check_manifest(data: dict) -> None:
    require(data.get("schemaVersion") == 1, "unsupported capability manifest schemaVersion")
    require(bool(data.get("reviewedOn")), "capability manifest needs a reviewedOn date")

    findings = data.get("findings")
    if not isinstance(findings, list):
        ERRORS.append("findings must be a list")
        findings = []
    ids = [item.get("id") for item in findings if isinstance(item, dict)]
    require(ids == FINDING_IDS, "findings must contain F01 through F16 once, in order")
    for item in findings:
        if not isinstance(item, dict):
            ERRORS.append("each finding must be an object")
            continue
        require(item.get("implementationStatus") in STATUSES, f"{item.get('id')} has an invalid implementationStatus")
        require(item.get("confidence") in {"high", "medium", "low", "unknown"}, f"{item.get('id')} has invalid confidence")
        require(bool(item.get("title")) and bool(item.get("qualification")), f"{item.get('id')} needs title and qualification")
        _validate_paths(item.get("evidence"), str(item.get("id", "finding")))

    for boundary in data.get("productBoundaries", []):
        if not isinstance(boundary, dict):
            ERRORS.append("each product boundary must be an object")
            continue
        require(boundary.get("status") in STATUSES | {"isolated"}, f"{boundary.get('area')} has an invalid status")
        require(bool(boundary.get("open")), f"{boundary.get('area')} needs an explicit open condition")
        _validate_paths(boundary.get("evidence"), str(boundary.get("area", "product boundary")))

    release = data.get("release")
    if not isinstance(release, dict):
        ERRORS.append("release must be an object")
        return
    gate = release.get("releaseGate")
    if not isinstance(gate, dict):
        ERRORS.append("releaseGate must be an object")
        return

    workflow_file = gate.get("workflowFile")
    workflow_id = gate.get("workflowId")
    require(isinstance(workflow_file, str) and (ROOT / workflow_file).is_file(), "release gate workflow file is missing")
    require(isinstance(workflow_file, str) and Path(workflow_file).name == workflow_id, "release gate workflowId must match its file name")
    require(gate.get("branch") == "main", "release gate must require main")
    require(gate.get("event") == "workflow_dispatch", "release gate must require a manual CI dispatch")
    require(bool(gate.get("workflowName")), "release gate needs the workflow display name")

    ci_path = ROOT / ".github/workflows/ci.yml"
    build_path = ROOT / ".github/workflows/build.yml"
    ci_text = ci_path.read_text(encoding="utf-8") if ci_path.is_file() else ""
    build_text = build_path.read_text(encoding="utf-8") if build_path.is_file() else ""
    require(re.search(r"(?m)^name: CI - Sanity Checks\s*$", ci_text) is not None, "CI display name changed")
    require("workflow_dispatch:" in ci_text, "CI must remain explicitly dispatchable")
    require("python3 scripts/verify_release_ci.py" in build_text, "release workflow must call the exact-SHA CI verifier")
    require("GH_TOKEN: ${{ github.token }}" in build_text, "release gate needs an Actions read token")
    require("COMMIT_SHA: ${{ github.sha }}" in build_text, "release gate must use the immutable workflow SHA")
    validate_job = job_block(build_text, "validate-trusted-ref")
    require("actions: read" in validate_job, "release validation job needs Actions read permission")

    required_jobs, optional_jobs = expected_ci_jobs(ci_text)
    manifest_required = release.get("requiredCiJobs")
    manifest_optional = release.get("optionalCiJobs")
    gate_required = gate.get("requiredJobs")
    require(isinstance(manifest_required, list), "release.requiredCiJobs must be a list")
    require(isinstance(manifest_optional, list), "release.optionalCiJobs must be a list")
    require(isinstance(gate_required, list), "releaseGate.requiredJobs must be a list")
    if isinstance(manifest_required, list):
        require(set(manifest_required) == required_jobs, "required CI job names differ from the expanded workflow jobs")
    if isinstance(gate_required, list):
        require(set(gate_required) == required_jobs, "release gate does not require every expanded CI job")
    if isinstance(manifest_optional, list):
        require(set(manifest_optional) == optional_jobs, "optional CI job names differ from the workflow")

    localization = data.get("localization")
    if not isinstance(localization, dict):
        ERRORS.append("localization must be an object")
    else:
        locale_directory = ROOT / str(localization.get("directory", ""))
        file_pattern = localization.get("filePattern")
        locale_count = localization.get("localeChoices")
        actual_count = len(list(locale_directory.glob(file_pattern))) if isinstance(file_pattern, str) else 0
        require(actual_count == locale_count, f"manifest locale count {locale_count} differs from {actual_count} locale files")
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        require(f"Localized across {locale_count} locale choices" in readme, "README locale count differs from the manifest")
        require(bool(localization.get("qualityStatus")), "localization must distinguish coverage from language QA")

    releases_page = release.get("releasesPage")
    public_latest = release.get("publicLatestAvailable")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    privacy = (ROOT / "PRIVACY.md").read_text(encoding="utf-8")
    require(isinstance(releases_page, str) and releases_page in readme, "README must link the configured releases page")
    require(isinstance(public_latest, bool), "release.publicLatestAvailable must be boolean")
    if public_latest is False:
        require("/releases/latest/download" not in readme.lower(), "README links a latest asset while no public latest release exists")
        require(release.get("publicationStatus") == "draft", "a missing public latest release must be labeled draft")
        require("draft" in readme.lower() and "no public" in readme.lower(), "README must explain that no public latest download exists")
    for phrase in ("off by default", "Trakt", "full source path", "source credentials", "encrypted progress"):
        require(phrase.lower() in privacy.lower(), f"privacy notice is missing '{phrase}'")


def main() -> int:
    data = _load_manifest()
    if data is not None:
        check_manifest(data)
    if ERRORS:
        for error in ERRORS:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("capability manifest checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
