#!/usr/bin/env python3

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_apple_spm_locks.py")
SPEC = importlib.util.spec_from_file_location("check_apple_spm_locks", SCRIPT)
CHECKER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(CHECKER)

GOOD_VERSION = "8.58.3"
GOOD_REVISION = "dad229c665bfd043c5d80ac7aa77717cbd19a1c3"


class AppleSpmLockCheckerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self._write_package_config()
        self._write_manifests(GOOD_VERSION)
        self._write_all_locks(GOOD_VERSION, GOOD_REVISION)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _write_package_config(self) -> None:
        path = self.root / ".dart_tool/package_config.json"
        path.parent.mkdir(parents=True)
        path.write_text(
            json.dumps(
                {
                    "configVersion": 2,
                    "packages": [{"name": "sentry_flutter", "rootUri": "../packages/sentry_flutter"}],
                }
            ),
            encoding="utf-8",
        )

    def _write_manifests(self, version: str) -> None:
        source = f'.package(url: "https://github.com/getsentry/sentry-cocoa", exact: "{version}")\n'
        for platform in ("ios", "macos"):
            path = self.root / f"packages/sentry_flutter/{platform}/sentry_flutter/Package.swift"
            path.parent.mkdir(parents=True)
            path.write_text(source, encoding="utf-8")

    def _lock_payload(self, version: str, revision: str) -> dict:
        return {
            "originHash": "fixture",
            "pins": [
                {
                    "identity": "sentry-cocoa",
                    "kind": "remoteSourceControl",
                    "location": "https://github.com/getsentry/sentry-cocoa",
                    "state": {"revision": revision, "version": version},
                }
            ],
            "version": 2,
        }

    def _write_lock(self, relative: Path, version: str, revision: str) -> None:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self._lock_payload(version, revision)), encoding="utf-8")

    def _write_all_locks(self, version: str, revision: str) -> None:
        for paths in CHECKER.LOCK_PAIRS.values():
            for path in paths:
                self._write_lock(path, version, revision)

    def test_consistent_graph_passes_library_and_cli(self) -> None:
        self.assertEqual([], CHECKER.validate(self.root))
        completed = subprocess.run(
            [sys.executable, str(SCRIPT), "--root", str(self.root)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, completed.returncode, completed.stdout + completed.stderr)
        self.assertIn("Apple SwiftPM locks match", completed.stdout)

    def test_reports_project_workspace_version_mismatch(self) -> None:
        workspace = CHECKER.LOCK_PAIRS["iOS"][1]
        self._write_lock(workspace, "8.58.0", "old")

        errors = CHECKER.validate(self.root)

        self.assertTrue(any(str(workspace) in error and "sentry-cocoa" in error for error in errors))
        self.assertTrue(any("iOS SwiftPM locks differ" in error for error in errors))

    def test_reports_all_locks_stale_against_manifests(self) -> None:
        self._write_all_locks("8.58.0", "old")

        errors = CHECKER.validate(self.root)

        self.assertEqual(4, sum("manifest requires exactly 8.58.3" in error for error in errors))

    def test_reports_same_version_with_different_revision(self) -> None:
        workspace = CHECKER.LOCK_PAIRS["macOS"][1]
        self._write_lock(workspace, GOOD_VERSION, "different")

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("macOS SwiftPM locks differ" in error and "sentry-cocoa" in error for error in errors))
        self.assertTrue(any("state differs" in error for error in errors))

    def test_reports_missing_resolved_package_inputs(self) -> None:
        (self.root / ".dart_tool/package_config.json").unlink()

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("flutter pub get first" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
