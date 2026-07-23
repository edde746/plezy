#!/usr/bin/env python3
"""Behavior tests for the privileged build-workflow guard."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts/check_build_workflow.py"
WORKFLOW = ROOT / ".github/workflows/build.yml"


class BuildWorkflowGuardTest(unittest.TestCase):
    def _run(self, workflow: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory(prefix="plezy-build-workflow-test-") as directory:
            fixture = Path(directory) / "build.yml"
            fixture.write_text(workflow, encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(CHECKER), str(fixture)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def _workflow(self) -> str:
        return WORKFLOW.read_text(encoding="utf-8")

    def test_locked_root_signer_passes(self) -> None:
        result = self._run(self._workflow())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("architecture matrix checks passed", result.stdout)

    def test_mutable_download_in_signing_step_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            "          try {\n",
            "          Invoke-WebRequest -Uri https://raw.githubusercontent.com/example/main/sign.dart -OutFile sign.dart\n"
            "          try {\n",
            1,
        )

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("mutable or ad-hoc input: raw.githubusercontent.com", result.stderr)
        self.assertIn("mutable or ad-hoc input: invoke-webrequest", result.stderr)

    def test_inline_dependency_resolution_in_signing_step_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            "          try {\n",
            "          Set-Content -Path pubspec.yaml -Value 'dependencies: {}'\n"
            "          dart pub get\n"
            "          try {\n",
            1,
        )

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("mutable or ad-hoc input: pubspec.yaml", result.stderr)
        self.assertIn("mutable or ad-hoc input: dart pub get", result.stderr)

    def test_downloaded_signer_execution_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            "dart run auto_updater:sign_update plezy-windows-installer.exe $keyPath",
            "dart run sign.dart plezy-windows-installer.exe $keyPath",
            1,
        )

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must execute the locked auto_updater package", result.stderr)

    def test_unlocked_install_is_rejected(self) -> None:
        prefix, package_and_after = self._workflow().split("  package-windows:\n", 1)
        workflow = prefix + "  package-windows:\n" + package_and_after.replace(
            "flutter pub get --enforce-lockfile --no-example",
            "flutter pub get",
            1,
        )

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("enforced root dependency lock", result.stderr)

    def test_missing_finally_cleanup_is_rejected(self) -> None:
        workflow = self._workflow().replace("          } finally {\n", "          }\n", 1)

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cleanup must run from a finally block", result.stderr)

    def test_libmpv_cache_without_native_manifest_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            "hashFiles('linux/packaging/build-libmpv.sh', 'linux/packaging/native-inputs.json')",
            "hashFiles('linux/packaging/build-libmpv.sh')",
            1,
        )

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("native input manifest", result.stderr)


if __name__ == "__main__":
    unittest.main()
