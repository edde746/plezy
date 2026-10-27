"""Unit tests for the fail-closed public WebOS release gate."""

from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_release_eligibility import REQUIRED_GATES, release_eligibility_errors


SOURCE_COMMIT = "a" * 40
VERSION = "2.24.1"
PACKAGE_BYTES = b"verified webOS package fixture"


def approved_document(package_hash: str) -> dict[str, object]:
    return {
        "status": "release-qualified",
        "releaseEligibility": {
            "status": "approved",
            "validatedSourceCommit": SOURCE_COMMIT,
            "validatedVersion": VERSION,
            "validatedArtifactSha256": package_hash,
            "gates": {name: True for name in REQUIRED_GATES},
        }
    }


class ReleaseEligibilityTests(unittest.TestCase):
    def test_blocked_configuration_fails_closed(self) -> None:
        document = {
            "releaseEligibility": {
                "status": "blocked",
                "validatedSourceCommit": None,
                "validatedVersion": None,
                "validatedArtifactSha256": None,
                "gates": {name: False for name in REQUIRED_GATES},
            }
        }
        errors = release_eligibility_errors(
            document,
            source_commit=SOURCE_COMMIT,
            version=VERSION,
            artifact=None,
            preflight=True,
        )
        self.assertTrue(any("status is not approved" in error for error in errors))
        gate_errors = [
            error for error in errors if "required webOS release gate" in error
        ]
        self.assertEqual(len(gate_errors), len(REQUIRED_GATES))

    def test_preflight_requires_exact_commit_and_version(self) -> None:
        digest = hashlib.sha256(PACKAGE_BYTES).hexdigest()
        document = approved_document(digest)
        errors = release_eligibility_errors(
            document,
            source_commit="b" * 40,
            version="2.24.2",
            artifact=None,
            preflight=True,
        )
        self.assertIn("source commit does not match the C6-qualified source", errors)
        self.assertIn("release version does not match the C6-qualified package", errors)

    def test_preflight_accepts_matching_source_version_and_gates(self) -> None:
        document = approved_document(hashlib.sha256(PACKAGE_BYTES).hexdigest())
        self.assertEqual(
            release_eligibility_errors(
                document,
                source_commit=SOURCE_COMMIT,
                version=VERSION,
                artifact=None,
                preflight=True,
            ),
            [],
        )

    def test_artifact_must_match_qualified_sha256(self) -> None:
        document = approved_document("0" * 64)
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "candidate.ipk"
            artifact.write_bytes(PACKAGE_BYTES)
            errors = release_eligibility_errors(
                document,
                source_commit=SOURCE_COMMIT,
                version=VERSION,
                artifact=artifact,
                preflight=False,
            )
        self.assertIn("built IPK SHA-256 does not match the C6-qualified artifact", errors)

    def test_exact_qualified_artifact_passes(self) -> None:
        digest = hashlib.sha256(PACKAGE_BYTES).hexdigest()
        document = approved_document(digest)
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "candidate.ipk"
            artifact.write_bytes(PACKAGE_BYTES)
            errors = release_eligibility_errors(
                document,
                source_commit=SOURCE_COMMIT,
                version=VERSION,
                artifact=artifact,
                preflight=False,
            )
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
