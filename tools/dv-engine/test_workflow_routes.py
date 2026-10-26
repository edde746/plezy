"""Keep Dolby build workflows on the intended private JIT trust lanes."""
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"


def job_block(source: str, job_id: str) -> str:
    match = re.search(
        rf"(?ms)^  {re.escape(job_id)}:\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\Z)",
        source,
    )
    if match is None:
        raise AssertionError(f"missing workflow job {job_id}")
    return match.group(1)


class DolbyWorkflowRouteTests(unittest.TestCase):
    def test_trusted_dolby_workflows_use_scoped_pushes_and_private_jit(self):
        paths = {
            "dv-platforms.yml": "codex/dv-platform-*",
            "dv-experimental.yml": "codex/dv-experimental-*",
        }
        for name, branch in paths.items():
            with self.subTest(workflow=name):
                source = (WORKFLOWS / name).read_text()
                self.assertIn("workflow_dispatch:", source)
                self.assertIn("push:", source)
                self.assertIn(branch, source)
                self.assertNotIn("pull_request:", source)
                self.assertNotRegex(
                    source,
                    r"(?m)^\s*runs-on:\s*(?:ubuntu|windows|macos|xcode)-",
                )
                self.assertNotIn("|| 'ubuntu-latest'", source)

    def test_dolby_jobs_use_run_scoped_private_jit_labels(self):
        expected = {
            "dv-platforms.yml": {
                "contracts": (
                    ("ng-shared-main-jit", "packer-windows"),
                    "{0}-{1}-contracts",
                ),
                "app-tests": (("ng-shared-main-jit",), "{0}-app-tests"),
                "felbaker-source": (
                    ("ng-shared-main-jit",),
                    "{0}-felbaker-source",
                ),
                "apple-source": (
                    ("ng-shared-main-jit",),
                    "{0}-apple-source",
                ),
            },
            "dv-experimental.yml": {
                "linux-engine": (("ng-shared-main-jit",), "{0}-linux-engine"),
            },
        }
        for workflow, jobs in expected.items():
            source = (WORKFLOWS / workflow).read_text()
            for job_id, (groups, label) in jobs.items():
                with self.subTest(workflow=workflow, job=job_id):
                    block = job_block(source, job_id)
                    for group in groups:
                        self.assertIn(f'"group":"{group}"', block)
                    self.assertIn("fromJSON(format(", block)
                    self.assertIn('"ng-main-run-{0}"', block)
                    self.assertIn("github.run_id", block)
                    if "{1}" in label:
                        self.assertIn("strategy.job-index", block)
                    self.assertIn(
                        f'"gha-{label}"',
                        block,
                    )

    def test_platform_specific_jobs_route_to_private_platform_pools(self):
        platforms = (WORKFLOWS / "dv-platforms.yml").read_text()
        contracts = job_block(platforms, "contracts")
        self.assertIn("windows-2025", contracts)
        self.assertIn("matrix.os == 'windows-2025'", contracts)
        self.assertIn('"group":"packer-windows"', contracts)
        self.assertIn('"Windows","X64"', contracts)
        self.assertIn("macos-15", contracts)
        self.assertIn('"macOS","ARM64"', contracts)

        apple = job_block(platforms, "apple-source")
        self.assertIn('"group":"ng-shared-main-jit"', apple)
        self.assertIn('"macOS","ARM64"', apple)

    def test_untrusted_pull_requests_only_use_the_gvisor_sandbox(self):
        source = (WORKFLOWS / "dv-fork-validation.yml").read_text()
        self.assertIn("pull_request_target:", source)
        self.assertIn("branches: [main]", source)
        self.assertIn("'tools/dv-engine/**'", source)
        self.assertIn("'.github/workflows/dv-*.yml'", source)
        self.assertIn("group: gvisor-sandbox", source)
        self.assertIn("labels: gvisor-sandbox", source)
        self.assertIn("persist-credentials: false", source)
        self.assertNotIn("secrets.", source)
        self.assertNotIn("ubuntu-latest", source)
        self.assertNotIn("ng-shared-main-jit", source)


if __name__ == "__main__":
    unittest.main()
