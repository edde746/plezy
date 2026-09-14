#!/usr/bin/env python3
"""Regression tests for the CPU detection in scripts/run_tests.sh.

The detector picks the concurrency the whole suite runs at, and getting it wrong
is silent: too high just makes CI slower. Every limit below can be the binding
one independently, so each is pinned here against fixtures rather than trusted
to whichever file happens to exist on the runner.
"""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT_DIR = Path(__file__).resolve().parents[2]
RUN_TESTS = ROOT_DIR / "scripts" / "run_tests.sh"
# Resolved up front: one test empties PATH, which would otherwise hide bash too.
BASH = shutil.which("bash") or "/bin/bash"


class DetectCpusTests(unittest.TestCase):
    def detect(
        self,
        *,
        nproc: int | None = None,
        cpu_max: str | None = None,
        cfs_quota: str | None = None,
        cfs_period: str | None = None,
        tools: bool = True,
    ) -> str:
        """Source run_tests.sh against fixtures and return detect_cpus output."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            cgroup = tmp / "cgroup"
            (cgroup / "cpu").mkdir(parents=True)

            if nproc is not None:
                stub = bin_dir / "nproc"
                stub.write_text(f"#!/bin/sh\necho {nproc}\n", encoding="utf-8")
                stub.chmod(0o755)

            if cpu_max is not None:
                (cgroup / "cpu.max").write_text(f"{cpu_max}\n", encoding="utf-8")
            if cfs_quota is not None:
                (cgroup / "cpu" / "cpu.cfs_quota_us").write_text(f"{cfs_quota}\n", encoding="utf-8")
            if cfs_period is not None:
                (cgroup / "cpu" / "cpu.cfs_period_us").write_text(f"{cfs_period}\n", encoding="utf-8")

            # An empty PATH hides nproc/sysctl/getconf so the no-signal fallback
            # is reachable; otherwise keep the real PATH so the stub shadows it.
            path = f"{bin_dir}:{os.environ.get('PATH', '')}" if tools else str(bin_dir)
            environment = {
                **os.environ,
                "PATH": path,
                "PLEZY_CGROUP_ROOT": str(cgroup),
            }
            result = subprocess.run(
                [BASH, "-c", f'source "{RUN_TESTS}"; detect_cpus'],
                capture_output=True,
                text=True,
                check=True,
                env=environment,
            )
            return result.stdout.strip()

    def test_uses_the_online_cpu_count_when_uncapped(self) -> None:
        self.assertEqual(self.detect(nproc=8), "8")

    def test_cgroup_v2_quota_caps_a_larger_online_count(self) -> None:
        # 200000/100000 == 2 CPUs of quota on an 8-core host.
        self.assertEqual(self.detect(nproc=8, cpu_max="200000 100000"), "2")

    def test_affinity_caps_a_larger_cgroup_v2_quota(self) -> None:
        # The regression this suite exists for: a container can carry a quota
        # worth 8 CPUs while being pinned to 2. Reading the quota alone and
        # returning it would oversubscribe by 4x.
        self.assertEqual(self.detect(nproc=2, cpu_max="800000 100000"), "2")

    def test_unlimited_cgroup_v2_quota_falls_through_to_affinity(self) -> None:
        self.assertEqual(self.detect(nproc=6, cpu_max="max 100000"), "6")

    def test_cgroup_v1_quota_caps_a_larger_online_count(self) -> None:
        self.assertEqual(
            self.detect(nproc=8, cfs_quota="200000", cfs_period="100000"),
            "2",
        )

    def test_unlimited_cgroup_v1_quota_falls_through_to_affinity(self) -> None:
        self.assertEqual(
            self.detect(nproc=6, cfs_quota="-1", cfs_period="100000"),
            "6",
        )

    def test_smallest_limit_wins_when_both_cgroup_versions_are_present(self) -> None:
        self.assertEqual(
            self.detect(
                nproc=16,
                cpu_max="800000 100000",
                cfs_quota="300000",
                cfs_period="100000",
            ),
            "3",
        )

    def test_partial_quota_rounds_up(self) -> None:
        # 2.5 CPUs of quota should not truncate to 2 and waste half a core.
        self.assertEqual(self.detect(nproc=8, cpu_max="250000 100000"), "3")

    def test_sub_single_core_quota_floors_at_one(self) -> None:
        self.assertEqual(self.detect(nproc=8, cpu_max="50000 100000"), "1")

    def test_malformed_quota_is_ignored_rather_than_trusted(self) -> None:
        self.assertEqual(self.detect(nproc=8, cpu_max="garbage"), "8")
        self.assertEqual(self.detect(nproc=8, cfs_quota="", cfs_period="100000"), "8")
        self.assertEqual(self.detect(nproc=8, cpu_max="200000 0"), "8")

    def test_falls_back_conservatively_with_no_signal_at_all(self) -> None:
        self.assertEqual(self.detect(tools=False), "4")


class RunTestsInvocationTests(unittest.TestCase):
    def run_with_fake_flutter(self, arguments: list[str]) -> str:
        """Run the script with `flutter` stubbed so it echoes its own argv."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            bin_dir = tmp / "bin"
            bin_dir.mkdir()
            cgroup = tmp / "cgroup"
            (cgroup / "cpu").mkdir(parents=True)

            flutter = bin_dir / "flutter"
            flutter.write_text('#!/bin/sh\necho "FLUTTER $*"\n', encoding="utf-8")
            flutter.chmod(0o755)
            nproc = bin_dir / "nproc"
            nproc.write_text("#!/bin/sh\necho 8\n", encoding="utf-8")
            nproc.chmod(0o755)

            result = subprocess.run(
                [str(RUN_TESTS), *arguments],
                capture_output=True,
                text=True,
                check=True,
                env={
                    **os.environ,
                    "PATH": f"{bin_dir}:{os.environ.get('PATH', '')}",
                    "PLEZY_CGROUP_ROOT": str(cgroup),
                },
            )
            return result.stdout

    def test_injects_the_detected_concurrency(self) -> None:
        self.assertIn("FLUTTER test -j 8", self.run_with_fake_flutter([]))

    def test_forwards_extra_arguments(self) -> None:
        output = self.run_with_fake_flutter(["test/widgets/example_test.dart"])
        self.assertIn("FLUTTER test -j 8 test/widgets/example_test.dart", output)

    def test_explicit_concurrency_is_not_overridden(self) -> None:
        for flag in (["-j", "2"], ["--concurrency=2"]):
            with self.subTest(flag=flag):
                output = self.run_with_fake_flutter(flag)
                self.assertIn(f"FLUTTER test {' '.join(flag)}", output)
                self.assertNotIn("-j 8", output)


if __name__ == "__main__":
    unittest.main()
