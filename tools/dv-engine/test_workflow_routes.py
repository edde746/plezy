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
    def test_trusted_dolby_jobs_are_main_only_and_private_jit(self):
        paths = ("dv-platforms.yml", "dv-experimental.yml")
        for name in paths:
            with self.subTest(workflow=name):
                source = (WORKFLOWS / name).read_text()
                self.assertIn("branches: [main]", source)
                self.assertIn("github.ref == 'refs/heads/main'", source)
                self.assertNotRegex(
                    source,
                    r"(?m)^\s*runs-on:\s*(?:ubuntu|windows|macos|xcode)-",
                )
                for hosted_label in (
                    "ubuntu-24.04",
                    "ubuntu-latest",
                    "windows-2025",
                    "windows-latest",
                    "macos-15",
                    "macos-latest",
                    "xcode-27",
                ):
                    self.assertNotIn(hosted_label, source)
                self.assertNotIn("|| 'ubuntu-latest'", source)

    def test_linux_jobs_use_run_scoped_broker_labels(self):
        expected = {
            "dv-platforms.yml": (
                "linux-contracts",
                "app-tests",
                "felbaker-source",
            ),
            "dv-experimental.yml": ("linux-engine",),
        }
        for workflow, jobs in expected.items():
            source = (WORKFLOWS / workflow).read_text()
            for job_id in jobs:
                with self.subTest(workflow=workflow, job=job_id):
                    block = job_block(source, job_id)
                    self.assertIn("group: ng-shared-main-jit", block)
                    self.assertIn(
                        "format('ng-main-run-{0}', github.run_id)", block
                    )
                    self.assertIn(
                        f"format('gha-{{0}}-{job_id}', github.run_id)", block
                    )

    def test_platform_specific_jobs_cannot_match_static_or_trusted_runners(self):
        platforms = (WORKFLOWS / "dv-platforms.yml").read_text()
        windows = job_block(platforms, "windows-contracts")
        self.assertIn("group: packer-windows", windows)
        self.assertIn("on-demand", windows)
        self.assertIn("PlezyNG", windows)

        for job_id in ("apple-contracts", "apple-source"):
            with self.subTest(job=job_id):
                block = job_block(platforms, job_id)
                self.assertIn("group: private-apple-builds", block)
                self.assertIn("private-apple-jit", block)

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
