#!/usr/bin/env python3
"""Fail closed before a webOS IPK is published from a public release."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import stat
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
DEFAULT_COMPATIBILITY = ROOT / "compatibility.json"
REQUIRED_GATES = (
    "vendorRuntimeRedistributionPermission",
    "approvedPrivateJitReproduction",
    "testedDeviceReNewStatusConfirmed",
    "exactCandidateFirstFrameOnC6",
    "exactCandidateSignInArtworkPlaybackOnC6",
)
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{40,64}$")
VERSION_PATTERN = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def release_eligibility_errors(
    document: dict[str, Any],
    *,
    source_commit: str,
    version: str,
    artifact: Path | None,
    preflight: bool,
) -> list[str]:
    errors: list[str] = []
    if document.get("status") != "release-qualified":
        errors.append("top-level compatibility status is not release-qualified")
    eligibility = document.get("releaseEligibility")
    if not isinstance(eligibility, dict):
        return ["compatibility.json has no releaseEligibility object"]

    if eligibility.get("status") != "approved":
        errors.append("webOS release eligibility status is not approved")

    gates = eligibility.get("gates")
    if not isinstance(gates, dict):
        errors.append("webOS release eligibility gates are missing or malformed")
    else:
        for name in REQUIRED_GATES:
            if gates.get(name) is not True:
                errors.append(f"required webOS release gate is not approved: {name}")

    if not COMMIT_PATTERN.fullmatch(source_commit):
        errors.append("source commit must be a full hexadecimal Git object ID")
    if eligibility.get("validatedSourceCommit") != source_commit:
        errors.append("source commit does not match the C6-qualified source")

    if not VERSION_PATTERN.fullmatch(version):
        errors.append("release version must use semantic versioning")
    if eligibility.get("validatedVersion") != version:
        errors.append("release version does not match the C6-qualified package")

    expected_hash = eligibility.get("validatedArtifactSha256")
    if not isinstance(expected_hash, str) or not SHA256_PATTERN.fullmatch(
        expected_hash
    ):
        errors.append("the exact C6-qualified IPK SHA-256 is missing or malformed")

    if preflight:
        if artifact is not None:
            errors.append("preflight must not receive an artifact path")
    elif artifact is None:
        errors.append("the built IPK path is required for exact artifact verification")
    elif artifact.suffix != ".ipk":
        errors.append("the public release artifact must use the .ipk extension")
    elif artifact.is_symlink():
        errors.append("the built IPK must not be a symbolic link")
    else:
        try:
            artifact_stat = artifact.stat(follow_symlinks=False)
        except OSError as error:
            errors.append(f"cannot inspect built IPK: {error}")
        else:
            if not stat.S_ISREG(artifact_stat.st_mode):
                errors.append("the built IPK must be a regular file")
            elif artifact_stat.st_size <= 0:
                errors.append("the built IPK must not be empty")
            elif isinstance(expected_hash, str) and SHA256_PATTERN.fullmatch(expected_hash):
                try:
                    actual_hash = sha256_file(artifact)
                except OSError as error:
                    errors.append(f"cannot hash built IPK: {error}")
                else:
                    if actual_hash != expected_hash:
                        errors.append(
                            "built IPK SHA-256 does not match the C6-qualified artifact"
                        )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compatibility", type=Path, default=DEFAULT_COMPATIBILITY)
    parser.add_argument(
        "--source-commit",
        help="Expected tested app-source commit (defaults to the recorded approval commit)",
    )
    parser.add_argument("--version", required=True)
    parser.add_argument("--artifact", type=Path)
    parser.add_argument("--preflight", action="store_true")
    args = parser.parse_args()

    if not args.preflight and args.artifact is None:
        parser.error("--artifact is required unless --preflight is used")

    try:
        document = json.loads(args.compatibility.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"ERROR: cannot read webOS compatibility data: {error}", file=sys.stderr)
        return 2
    if not isinstance(document, dict):
        print("ERROR: webOS compatibility data must be a JSON object", file=sys.stderr)
        return 2

    eligibility = document.get("releaseEligibility")
    recorded_source = (
        eligibility.get("validatedSourceCommit")
        if isinstance(eligibility, dict)
        else None
    )
    source_commit = args.source_commit
    if source_commit is None:
        source_commit = recorded_source if isinstance(recorded_source, str) else ""

    errors = release_eligibility_errors(
        document,
        source_commit=source_commit,
        version=args.version,
        artifact=args.artifact,
        preflight=args.preflight,
    )
    if errors:
        for error in errors:
            print(f"BLOCKED: {error}", file=sys.stderr)
        return 1

    print("The exact webOS artifact is approved for public release.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
