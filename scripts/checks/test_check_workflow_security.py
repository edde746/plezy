#!/usr/bin/env python3

from pathlib import Path
import unittest

from check_workflow_security import check_workflow


SAFE_SHA = "a" * 40
ROOT = Path(__file__).resolve().parents[2]
CI_PATH = Path(".github/workflows/ci.yml")


class WorkflowSecurityTests(unittest.TestCase):
    def check(self, text: str, path: Path | None = None) -> list[str]:
        return check_workflow(path or Path(".github/workflows/test.yml"), text)

    def test_accepts_read_only_pull_request_workflow_with_pinned_action(self) -> None:
        errors = self.check(
            f"""name: Test
on:
  pull_request: {{}}
jobs:
  test:
    permissions: {{contents: read}}
    steps:
      - name: Checkout
        uses: "actions/checkout@{SAFE_SHA}" # reviewed pin
        with:
          persist-credentials: "false"
"""
        )
        self.assertEqual(errors, [])

    def test_accepts_benign_ci_names_runners_matrices_and_commands(self) -> None:
        workflow = (ROOT / CI_PATH).read_text(encoding="utf-8")
        changed = (
            workflow.replace("name: CI - Sanity Checks", "name: Continuous integration")
            .replace("  analyze:\n", "  static-analysis:\n", 1)
            .replace("name: Code Analysis", "name: Repository checks", 1)
            .replace("runs-on: ubuntu-latest", "runs-on: internal-linux", 1)
            .replace("- sanitizer: address", "- sanitizer: memory", 1)
            .replace("dart run scripts/checks/check_analyzer.dart", "dart run tool/check.dart", 1)
        )

        self.assertEqual(self.check(changed, CI_PATH), [])

    def test_accepts_a_different_immutable_action_pin(self) -> None:
        workflow = f"jobs:\n  test:\n    steps:\n      - uses: actions/setup-go@{'b' * 40}\n"
        self.assertEqual(self.check(workflow), [])

    def test_rejects_mutable_action_reference(self) -> None:
        errors = self.check("jobs:\n  test:\n    steps:\n      - uses: actions/checkout@v7\n")
        self.assertTrue(any("full commit SHA" in error for error in errors))

    def test_rejects_missing_checkout_credential_guard_on_pull_requests(self) -> None:
        errors = self.check(
            f"""on: [pull_request]
jobs:
  test:
    steps:
      - uses: actions/checkout@{SAFE_SHA}
        with:
          fetch-depth: 1
      - run: echo 'persist-credentials: false elsewhere is not enough'
"""
        )
        self.assertTrue(any("discard GitHub credentials" in error for error in errors))

    def test_rejects_secrets_in_pull_request_workflow(self) -> None:
        errors = self.check(
            "on:\n  pull_request:\njobs:\n  test:\n    env:\n      TOKEN: ${{ secrets.TOKEN }}\n"
        )
        self.assertTrue(any("must not reference repository secrets" in error for error in errors))

    def test_rejects_block_or_flow_write_permission_on_pull_requests(self) -> None:
        block_errors = self.check(
            "on:\n  pull_request:\njobs:\n  test:\n    permissions:\n      contents: write\n"
        )
        flow_errors = self.check(
            "on: {pull_request: {}}\npermissions: {contents: write}\n"
        )
        self.assertTrue(any("must not request write permissions" in error for error in block_errors))
        self.assertTrue(any("must not request write permissions" in error for error in flow_errors))

    def test_rejects_privileged_untrusted_triggers(self) -> None:
        target_errors = self.check("on:\n  pull_request_target:\n")
        run_errors = self.check("on: [push, workflow_run]\n")
        self.assertTrue(any("pull_request_target" in error for error in target_errors))
        self.assertTrue(any("workflow_run" in error for error in run_errors))

    def test_rejects_mutable_raw_github_download(self) -> None:
        errors = self.check(
            "jobs:\n  test:\n    steps:\n      - run: curl https://raw.githubusercontent.com/o/r/main/tool.sh\n"
        )
        self.assertTrue(any("immutable commit" in error for error in errors))

    def test_rejects_ci_fail_open_constructs(self) -> None:
        continued = self.check(
            "jobs:\n  test:\n    steps:\n      - continue-on-error: ${{ github.event_name == 'push' }}\n        run: ./check\n",
            CI_PATH,
        )
        suppressed = self.check(
            "jobs:\n  test:\n    steps:\n      - run: ./check || true\n",
            CI_PATH,
        )
        explicit_false = self.check(
            "jobs:\n  test:\n    steps:\n      - continue-on-error: false\n        run: ./check\n",
            CI_PATH,
        )
        self.assertTrue(any("continue-on-error" in error for error in continued))
        self.assertTrue(any("suppress failure" in error for error in suppressed))
        self.assertEqual(explicit_false, [])

    def test_comments_do_not_create_security_findings(self) -> None:
        errors = self.check(
            """on:
  push:
# pull_request_target:
jobs:
  test:
    steps:
      # uses: actions/checkout@main
      - run: echo safe
"""
        )
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
