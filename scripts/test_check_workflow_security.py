#!/usr/bin/env python3

from pathlib import Path
import unittest

from check_workflow_security import check_workflow


SAFE_SHA = "a" * 40


class WorkflowSecurityTests(unittest.TestCase):
    def check(self, text: str) -> list[str]:
        return check_workflow(Path(".github/workflows/test.yml"), text)

    def test_accepts_read_only_pull_request_workflow_with_pinned_action(self) -> None:
        errors = self.check(
            f"""name: Test
on:
  pull_request:
jobs:
  test:
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@{SAFE_SHA} # v7
        with:
          persist-credentials: false
"""
        )
        self.assertEqual(errors, [])

    def test_rejects_mutable_action_reference(self) -> None:
        errors = self.check("jobs:\n  test:\n    steps:\n      - uses: actions/checkout@v7\n")
        self.assertTrue(any("full commit SHA" in error for error in errors))

    def test_rejects_secrets_in_pull_request_workflow(self) -> None:
        errors = self.check(
            "on:\n  pull_request:\njobs:\n  test:\n    env:\n      TOKEN: ${{ secrets.TOKEN }}\n"
        )
        self.assertTrue(any("must not reference repository secrets" in error for error in errors))

    def test_rejects_write_permission_in_pull_request_workflow(self) -> None:
        errors = self.check(
            "on:\n  pull_request:\njobs:\n  test:\n    permissions:\n      contents: write\n"
        )
        self.assertTrue(any("must not request write permissions" in error for error in errors))

    def test_rejects_privileged_untrusted_trigger(self) -> None:
        errors = self.check("on:\n  pull_request_target:\n")
        self.assertTrue(any("unaudited privileged trigger" in error for error in errors))

    def test_rejects_mutable_raw_github_download(self) -> None:
        errors = self.check(
            "jobs:\n  test:\n    steps:\n      - run: curl https://raw.githubusercontent.com/o/r/main/tool.sh\n"
        )
        self.assertTrue(any("immutable commit" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
