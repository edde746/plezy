#!/usr/bin/env python3
"""Require every release-critical CI job to pass on the exact release SHA."""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs/maintainers/capability-manifest.json"
API_BASE = "https://api.github.com"
PER_PAGE = 100
MAX_PAGES = 20


class GateError(Exception):
    pass


def _request_json(url: str, token: str) -> dict:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "User-Agent": "PlezyNG-release-ci-gate",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = response.read(16 * 1024 * 1024 + 1)
    except urllib.error.HTTPError as error:
        raise GateError(f"GitHub Actions API request failed (HTTP {error.code}).") from None
    except (urllib.error.URLError, TimeoutError, OSError) as error:
        raise GateError(f"GitHub Actions API request failed ({type(error).__name__}).") from None
    if len(payload) > 16 * 1024 * 1024:
        raise GateError("GitHub Actions API response exceeded the 16 MiB safety limit.")
    try:
        result = json.loads(payload)
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise GateError("GitHub Actions API returned invalid JSON.") from None
    if not isinstance(result, dict):
        raise GateError("GitHub Actions API returned an unexpected response.")
    return result


def _pages(url: str, token: str, collection: str) -> list[dict]:
    records: list[dict] = []
    for page in range(1, MAX_PAGES + 1):
        separator = "&" if "?" in url else "?"
        result = _request_json(f"{url}{separator}per_page={PER_PAGE}&page={page}", token)
        values = result.get(collection)
        if not isinstance(values, list) or any(not isinstance(value, dict) for value in values):
            raise GateError(f"GitHub Actions API omitted the expected {collection} list.")
        records.extend(values)
        if len(values) < PER_PAGE:
            return records
    raise GateError("GitHub Actions API pagination exceeded the safety limit.")


def _manifest_gate() -> dict:
    try:
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        gate = data["releaseGate"]
        required = gate["requiredJobs"]
    except (OSError, json.JSONDecodeError, KeyError, TypeError):
        raise GateError("The capability manifest does not define the release CI contract.") from None
    if (
        gate.get("branch") != "main"
        or gate.get("event") != "workflow_dispatch"
        or gate.get("workflowId") != "ci.yml"
        or not isinstance(required, list)
        or not required
        or any(not isinstance(name, str) or not name.strip() for name in required)
        or len(required) != len(set(required))
    ):
        raise GateError("The capability manifest contains an invalid release CI contract.")
    return gate


def _required_environment() -> tuple[str, str, str, str]:
    token = os.environ.get("GH_TOKEN", "").strip()
    repository = os.environ.get("REPOSITORY", "").strip()
    commit_sha = os.environ.get("COMMIT_SHA", "").strip().lower()
    if not token:
        raise GateError("GH_TOKEN is required to inspect the release commit's CI run.")
    if re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository) is None:
        raise GateError("REPOSITORY must use owner/name form.")
    if re.fullmatch(r"[0-9a-f]{40}", commit_sha) is None:
        raise GateError("COMMIT_SHA must be the exact 40-character release commit SHA.")
    return token, repository, commit_sha, API_BASE


def _latest_run(token: str, repository: str, commit_sha: str, gate: dict) -> dict:
    owner, repo = repository.split("/", maxsplit=1)
    path = "/".join(urllib.parse.quote(value, safe="") for value in (owner, repo))
    query = urllib.parse.urlencode(
        {
            "head_sha": commit_sha,
            "branch": gate["branch"],
            "event": gate["event"],
        }
    )
    url = f"{API_BASE}/repos/{path}/actions/workflows/{urllib.parse.quote(gate['workflowId'], safe='')}/runs?{query}"
    runs = _pages(url, token, "workflow_runs")
    candidates = [
        run
        for run in runs
        if run.get("head_sha") == commit_sha
        and run.get("head_branch") == gate["branch"]
        and run.get("event") == gate["event"]
    ]
    if not candidates:
        raise GateError(
            f"No {gate['event']} run for {gate['workflowName']} exists on {gate['branch']} at {commit_sha}."
        )
    return max(
        candidates,
        key=lambda run: (
            int(run.get("run_number") or 0),
            int(run.get("run_attempt") or 0),
            int(run.get("id") or 0),
        ),
    )


def _check_jobs(token: str, repository: str, run: dict, gate: dict) -> list[str]:
    owner, repo = repository.split("/", maxsplit=1)
    path = "/".join(urllib.parse.quote(value, safe="") for value in (owner, repo))
    run_id = run.get("id")
    attempt = run.get("run_attempt")
    if not isinstance(run_id, int) or not isinstance(attempt, int) or attempt < 1:
        raise GateError("The selected CI run is missing its run or attempt identity.")
    url = f"{API_BASE}/repos/{path}/actions/runs/{run_id}/attempts/{attempt}/jobs"
    jobs = _pages(url, token, "jobs")
    errors = []
    for required_name in gate["requiredJobs"]:
        matches = [job for job in jobs if job.get("name") == required_name]
        if len(matches) != 1:
            errors.append(f"{required_name}: {'missing' if not matches else 'ambiguous'}")
            continue
        job = matches[0]
        status = job.get("status") or "missing"
        conclusion = job.get("conclusion") or "missing"
        if status != "completed" or conclusion != "success":
            errors.append(f"{required_name}: {status} / {conclusion}")
    return errors


def main() -> int:
    try:
        gate = _manifest_gate()
        token, repository, commit_sha, _ = _required_environment()
        run = _latest_run(token, repository, commit_sha, gate)
        run_status = run.get("status") or "missing"
        run_conclusion = run.get("conclusion") or "missing"
        if run_status != "completed" or run_conclusion != "success":
            raise GateError(
                f"The newest exact-SHA CI run must complete successfully; found {run_status} / {run_conclusion}."
            )
        job_errors = _check_jobs(token, repository, run, gate)
        if job_errors:
            raise GateError("Required CI jobs did not pass: " + "; ".join(job_errors))
        print(
            f"Release CI passed for {commit_sha}: run {run.get('run_number')} "
            f"attempt {run.get('run_attempt')} with {len(gate['requiredJobs'])} required jobs."
        )
        return 0
    except GateError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
