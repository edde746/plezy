#!/usr/bin/env python3
"""Deterministic tests for the exact Bun advisory policy."""

import contextlib
from datetime import date
import io
import json
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from check_bun_audit import Acceptance, Advisory, evaluate, load_baseline, main


TODAY = date(2026, 7, 21)
ADVISORY = Advisory("111", "fixture-package", "high", "<2.0.0")
ACCEPTANCE = Acceptance(ADVISORY, date(2026, 8, 1), "Not reachable in static output.")


def audit_json(
    *,
    advisory_id: int = 111,
    severity: str = "high",
    vulnerable_range: str = "<2.0.0",
) -> str:
    return json.dumps(
        {
            "fixture-package": [
                {
                    "id": advisory_id,
                    "severity": severity,
                    "vulnerable_versions": vulnerable_range,
                    "url": "https://example.invalid/advisory",
                }
            ]
        }
    )


class BunAuditPolicyTest(unittest.TestCase):
    def test_clean_audit_with_empty_baseline_passes(self) -> None:
        self.assertEqual(evaluate(exit_code=0, output="{}", accepted={}, today=TODAY), [])

    def test_exact_reviewed_advisory_passes(self) -> None:
        self.assertEqual(
            evaluate(
                exit_code=1,
                output=audit_json(),
                accepted={ADVISORY.identity: ACCEPTANCE},
                today=TODAY,
                stderr="\x1b[1mbun audit \x1b[0m\x1b[2mv1.3.14 (d1632b29)\x1b[0m\n",
            ),
            [],
        )

    def test_new_advisory_is_rejected(self) -> None:
        errors = evaluate(exit_code=1, output=audit_json(), accepted={}, today=TODAY)
        self.assertEqual(errors, ["unaccepted advisory 111 (fixture-package)"])

    def test_changed_severity_and_range_are_rejected(self) -> None:
        errors = evaluate(
            exit_code=1,
            output=audit_json(severity="critical", vulnerable_range="<3.0.0"),
            accepted={ADVISORY.identity: ACCEPTANCE},
            today=TODAY,
        )
        self.assertTrue(any("severity changed" in error for error in errors))
        self.assertTrue(any("vulnerable range changed" in error for error in errors))

    def test_expired_acceptance_is_rejected(self) -> None:
        expired = Acceptance(ADVISORY, date(2026, 7, 20), "Reviewed fixture debt.")
        errors = evaluate(
            exit_code=1,
            output=audit_json(),
            accepted={ADVISORY.identity: expired},
            today=TODAY,
        )
        self.assertEqual(errors, ["expired acceptance 111 (fixture-package) (2026-07-20)"])

    def test_stale_baseline_entry_is_rejected(self) -> None:
        errors = evaluate(
            exit_code=0,
            output="{}",
            accepted={ADVISORY.identity: ACCEPTANCE},
            today=TODAY,
        )
        self.assertEqual(errors, ["stale baseline advisory 111 (fixture-package)"])

    def test_duplicate_and_overlong_acceptances_are_rejected(self) -> None:
        entry = {
            "id": 111,
            "package": "fixture-package",
            "severity": "high",
            "vulnerableRange": "<2.0.0",
            "expiresOn": "2026-08-01",
            "rationale": "Not reachable in static output.",
        }
        with tempfile.TemporaryDirectory() as directory:
            baseline = Path(directory) / "baseline.json"
            baseline.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [entry, entry],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "duplicate baseline advisory"):
                load_baseline(baseline)

            entry["id"] = 112
            entry["expiresOn"] = "2026-11-01"
            baseline.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [entry],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "more than 90 days"):
                load_baseline(baseline)

            entry["expiresOn"] = "2026-08-01"
            entry["unexpected"] = True
            baseline.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [entry],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "unknown schema"):
                load_baseline(baseline)

    def test_malformed_json_and_schema_are_rejected(self) -> None:
        malformed = evaluate(exit_code=1, output="not-json", accepted={}, today=TODAY)
        self.assertTrue(any("malformed JSON" in error for error in malformed))

        unknown = evaluate(
            exit_code=1,
            output=json.dumps({"fixture-package": [{"id": 111}]}),
            accepted={},
            today=TODAY,
        )
        self.assertTrue(any("unknown schema" in error for error in unknown))

        empty_package = evaluate(
            exit_code=0,
            output=json.dumps({"fixture-package": []}),
            accepted={},
            today=TODAY,
        )
        self.assertTrue(any("non-empty list" in error for error in empty_package))

    def test_scanner_failure_and_inconsistent_exit_are_rejected(self) -> None:
        self.assertEqual(
            evaluate(exit_code=2, output="", accepted={}, today=TODAY),
            ["bun audit execution failed with exit code 2"],
        )
        self.assertEqual(
            evaluate(exit_code=1, output="{}", accepted={}, today=TODAY),
            ["bun audit exited with advisories but returned an empty result"],
        )

    def test_missing_lockfile_fails_before_scanner_execution(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            baseline = project / "baseline.json"
            baseline.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [],
                    }
                ),
                encoding="utf-8",
            )
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                status = main(["--project", str(project), "--baseline", str(baseline)])
            self.assertEqual(status, 1)
            self.assertIn("missing Bun lockfile", stderr.getvalue())

            (project / "bun.lock").write_text("", encoding="utf-8")

            def execution_failure(_: Path) -> subprocess.CompletedProcess[str]:
                raise OSError("registry unavailable")

            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                status = main(
                    ["--project", str(project), "--baseline", str(baseline)],
                    run_audit=execution_failure,
                    today=TODAY,
                )
            self.assertEqual(status, 1)
            self.assertIn("cannot execute bun audit", stderr.getvalue())


    def test_noncanonical_dates_and_invalid_acceptance_fields_are_rejected(self) -> None:
        entry = {
            "id": 111,
            "package": "*",
            "severity": "high",
            "vulnerableRange": "<2.0.0",
            "expiresOn": "20260801",
            "rationale": "Not reachable in static output.",
        }
        with tempfile.TemporaryDirectory() as directory:
            baseline = Path(directory) / "baseline.json"
            baseline.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [entry],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "package is invalid"):
                load_baseline(baseline)

            entry["package"] = "fixture-package"
            baseline.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [entry],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "YYYY-MM-DD"):
                load_baseline(baseline)

            entry["expiresOn"] = "2026-07-20"
            baseline.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [entry],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "expires before"):
                load_baseline(baseline)

    def test_duplicate_audit_advisory_and_unknown_severity_are_rejected(self) -> None:
        duplicate = json.dumps(
            {
                "fixture-package": [
                    {
                        "id": 111,
                        "severity": "high",
                        "vulnerable_versions": "<2.0.0",
                    },
                    {
                        "id": 111,
                        "severity": "high",
                        "vulnerable_versions": "<2.0.0",
                    },
                ]
            }
        )
        self.assertTrue(
            any(
                "duplicate advisory" in error
                for error in evaluate(
                    exit_code=1, output=duplicate, accepted={}, today=TODAY
                )
            )
        )
        invalid_severity = audit_json(severity="unknown")
        self.assertTrue(
            any(
                "severity is invalid" in error
                for error in evaluate(
                    exit_code=1,
                    output=invalid_severity,
                    accepted={},
                    today=TODAY,
                )
            )
        )

    def test_network_diagnostic_fails_closed_without_echoing_payload(self) -> None:
        diagnostic = "registry timeout " + ("secret-response " * 100)
        self.assertEqual(
            evaluate(
                exit_code=1,
                output=audit_json(),
                stderr=diagnostic,
                accepted={ADVISORY.identity: ACCEPTANCE},
                today=TODAY,
            ),
            ["bun audit reported a scanner or network diagnostic"],
        )

        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "bun.lock").write_text("", encoding="utf-8")
            (project / "baseline.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [],
                    }
                ),
                encoding="utf-8",
            )
            stderr = io.StringIO()
            result = subprocess.CompletedProcess(
                args=["bun", "audit", "--json"],
                returncode=2,
                stdout="",
                stderr=diagnostic,
            )
            with contextlib.redirect_stderr(stderr):
                status = main(
                    ["--project", str(project), "--baseline", "baseline.json"],
                    run_audit=lambda _: result,
                    today=TODAY,
                )
            rendered = stderr.getvalue()
            self.assertEqual(status, 1)
            self.assertIn("execution failed with exit code 2", rendered)
            self.assertLess(len(rendered), 500)
            self.assertNotIn(diagnostic, rendered)

    def test_main_uses_injected_audit_result_and_exact_baseline(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "bun.lock").write_text("", encoding="utf-8")
            (project / "baseline.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "reviewedOn": "2026-07-21",
                        "accepted": [
                            {
                                "id": 111,
                                "package": "fixture-package",
                                "severity": "high",
                                "vulnerableRange": "<2.0.0",
                                "expiresOn": "2026-08-01",
                                "rationale": "Not reachable in static output.",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            seen = []

            def run_audit(path: Path) -> subprocess.CompletedProcess[str]:
                seen.append(path)
                return subprocess.CompletedProcess(
                    args=["bun", "audit", "--json"],
                    returncode=1,
                    stdout=audit_json(),
                    stderr="",
                )

            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                status = main(
                    ["--project", str(project), "--baseline", "baseline.json"],
                    run_audit=run_audit,
                    today=TODAY,
                )
            self.assertEqual(status, 0)
            self.assertEqual(seen, [project.resolve()])
            self.assertIn("1 reviewed acceptance", stdout.getvalue())

    def test_diagnostics_are_count_bounded(self) -> None:
        payload = {
            f"fixture-{index}": [
                {
                    "id": index,
                    "severity": "high",
                    "vulnerable_versions": "<2.0.0",
                }
            ]
            for index in range(30)
        }
        errors = evaluate(
            exit_code=1,
            output=json.dumps(payload),
            accepted={},
            today=TODAY,
        )
        self.assertEqual(len(errors), 21)
        self.assertEqual(errors[-1], "10 additional policy error(s) omitted")

if __name__ == "__main__":
    unittest.main()
