#!/usr/bin/env python3
"""Regression tests for verified tvOS engine provisioning."""

from __future__ import annotations

import hashlib
import os
import shutil
import stat
import subprocess
import tarfile
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FETCH_ENGINE = ROOT / "tvos/scripts/fetch_engine.sh"


class FetchTvosEngineTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="plezy-tvos-engine-test-")
        self.root = Path(self.temporary.name)
        self.tvos = self.root / "tvos"
        (self.tvos / "scripts").mkdir(parents=True)
        shutil.copy2(FETCH_ENGINE, self.tvos / "scripts/fetch_engine.sh")
        (self.tvos / "engine.version").write_text("fixture-1\n", encoding="utf-8")
        (self.root / "pubspec.yaml").write_text("version: 1.2.3+4\n", encoding="utf-8")
        self.cache = self.root / "cache"
        self.archive = self.root / "engine.tar.gz"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        curl = self.bin / "curl"
        curl.write_text(
            """#!/usr/bin/env bash
set -euo pipefail
output=
while (( $# )); do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done
cp "$FIXTURE_ARCHIVE" "$output"
""",
            encoding="utf-8",
        )
        curl.chmod(curl.stat().st_mode | stat.S_IXUSR)
        self.env = os.environ | {
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "FIXTURE_ARCHIVE": str(self.archive),
            "FLUTTER_ROOT": str(self.root / "flutter"),
            "FLUTTER_TVOS_ENGINE_CACHE": str(self.cache),
            "FLUTTER_TVOS_RELEASES_URL": "https://example.invalid/flutter-tvos",
        }

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _write_archive(self, marker: str) -> str:
        source = self.root / "marker.txt"
        source.write_text(marker, encoding="utf-8")
        with tarfile.open(self.archive, "w:gz") as archive:
            archive.add(source, arcname="out/tvos_debug_sim_unopt_arm64/marker.txt")
        return hashlib.sha256(self.archive.read_bytes()).hexdigest()

    def _run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", "tvos/scripts/fetch_engine.sh"],
            cwd=self.root,
            env=self.env,
            check=False,
            capture_output=True,
            text=True,
        )

    def test_verified_archive_installs_and_reuses_matching_cache(self) -> None:
        digest = self._write_archive("reviewed engine")
        (self.tvos / "engine.sha256").write_text(f"{digest}\n", encoding="utf-8")

        first = self._run()

        self.assertEqual(first.returncode, 0, first.stderr)
        engine = self.cache / "vfixture-1"
        self.assertEqual(
            (engine / "out/tvos_debug_sim_unopt_arm64/marker.txt").read_text(encoding="utf-8"),
            "reviewed engine",
        )
        self.archive.unlink()

        second = self._run()

        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("using verified cached engine", second.stdout)

    def test_checksum_mismatch_leaves_no_partial_engine(self) -> None:
        self._write_archive("unreviewed engine")
        (self.tvos / "engine.sha256").write_text(f"{'0' * 64}\n", encoding="utf-8")

        result = self._run()

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.cache / "vfixture-1").exists())
        self.assertEqual(list(self.cache.glob(".engine.*")), [])

    def test_checksum_change_replaces_same_version_without_stale_files(self) -> None:
        first_digest = self._write_archive("first engine")
        checksum = self.tvos / "engine.sha256"
        checksum.write_text(f"{first_digest}\n", encoding="utf-8")
        self.assertEqual(self._run().returncode, 0)
        stale = self.cache / "vfixture-1/stale-from-previous-archive"
        stale.write_text("stale", encoding="utf-8")

        second_digest = self._write_archive("second engine")
        checksum.write_text(f"{second_digest}\n", encoding="utf-8")

        result = self._run()

        self.assertEqual(result.returncode, 0, result.stderr)
        marker = self.cache / "vfixture-1/out/tvos_debug_sim_unopt_arm64/marker.txt"
        self.assertEqual(marker.read_text(encoding="utf-8"), "second engine")
        self.assertFalse(stale.exists())
        self.assertEqual(
            (self.cache / "vfixture-1/.installed").read_text(encoding="utf-8").strip(),
            f"fixture-1 {second_digest}",
        )


if __name__ == "__main__":
    unittest.main()
