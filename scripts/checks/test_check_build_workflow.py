#!/usr/bin/env python3
"""Behavior tests for the privileged build-workflow guard."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "scripts/checks/check_build_workflow.py"
WORKFLOW = ROOT / ".github/workflows/build.yml"
SETUP_FLUTTER_GIT = ROOT / ".github/actions/setup-flutter-git/action.yml"


class BuildWorkflowGuardTest(unittest.TestCase):
    def _run(self, workflow: str, action: str | None = None) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory(prefix="plezy-build-workflow-test-") as directory:
            # The checker resolves the shared bootstrap beside the workflow, so
            # the fixture has to mirror the real `.github` layout.
            github = Path(directory) / ".github"
            fixture = github / "workflows/build.yml"
            fixture.parent.mkdir(parents=True)
            fixture.write_text(workflow, encoding="utf-8")
            bootstrap = github / "actions/setup-flutter-git/action.yml"
            bootstrap.parent.mkdir(parents=True)
            bootstrap.write_text(action if action is not None else self._action(), encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(CHECKER), str(fixture)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def _workflow(self) -> str:
        return WORKFLOW.read_text(encoding="utf-8")

    def _action(self) -> str:
        return SETUP_FLUTTER_GIT.read_text(encoding="utf-8")

    def test_locked_root_signer_passes(self) -> None:
        result = self._run(self._workflow())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("architecture matrix checks passed", result.stdout)

    def test_windows_arm_flutter_without_release_tag_is_rejected(self) -> None:
        action = self._action().replace(
            'git -C $root fetch --depth 1 origin "refs/tags/${version}:refs/tags/${version}"',
            "git -C $root fetch --depth 1 origin 559ffa3f75e7402d65a8def9c28389a9b2e6fe42",
            1,
        )
        self.assertNotEqual(action, self._action(), "fixture mutation no longer matches the action")

        result = self._run(self._workflow(), action)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refs/tags/${version}", result.stderr)

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

    def test_draft_release_without_explicit_tag_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            " && inputs.release_tag != '' }}",
            " }}",
            1,
        )
        self.assertNotEqual(workflow, self._workflow(), "fixture mutation no longer matches workflow")

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must require an explicit release tag", result.stderr)

    def test_release_run_without_tagged_name_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            "run-name: ${{ inputs.release_tag != '' && format('Release {0}', inputs.release_tag) "
            "|| format('Build {0}', github.sha) }}\n",
            "",
            1,
        )
        self.assertNotEqual(workflow, self._workflow(), "fixture mutation no longer matches workflow")

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must expose their tag in the run name", result.stderr)

    def test_release_tag_without_exact_target_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            "          target_commitish: ${{ github.sha }}\n",
            "",
            1,
        )
        self.assertNotEqual(workflow, self._workflow(), "fixture mutation no longer matches workflow")

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must target the exact build commit", result.stderr)



if __name__ == "__main__":
    unittest.main()
