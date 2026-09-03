import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "fetch_linux_libmpv.py"
HAS_ZSTD = shutil.which("zstd") is not None


class FetchLinuxLibmpvTest(unittest.TestCase):
    def setUp(self) -> None:
        self._directory = tempfile.TemporaryDirectory(prefix="plezy-fetch-libmpv-test-")
        self.addCleanup(self._directory.cleanup)
        self.root = Path(self._directory.name)
        self.dest = self.root / "prefix"
        self.asset = self._build_asset()

    def _build_asset(self) -> Path:
        """A tiny prefix tree packed the way mpv-build publishes it."""
        tree = self.root / "tree"
        (tree / "lib/pkgconfig").mkdir(parents=True)
        (tree / "lib/pkgconfig/mpv.pc").write_text("Name: mpv\n", encoding="utf-8")
        asset = self.root / "libmpv-linux-test.tar.zst"
        if HAS_ZSTD:
            subprocess.run(
                ["tar", "--zstd", "-cf", str(asset), "-C", str(tree), "."],
                check=True,
            )
        else:
            asset.write_bytes(b"not an archive")
        return asset

    def _write_lock(self, checksum: str, machine: str = platform.machine()) -> Path:
        lock = self.root / "mpv-build.lock.json"
        lock.write_text(
            json.dumps(
                {
                    "artifacts": {
                        "linux": {
                            "assetBase": self.root.as_uri(),
                            "assets": {machine: {"asset": self.asset.name, "checksum": checksum}},
                        }
                    }
                }
            ),
            encoding="utf-8",
        )
        return lock

    def _run(self, lock: Path, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--lock", str(lock), "--dest", str(self.dest)],
            check=False,
            capture_output=True,
            text=True,
            env=env,
        )

    def _digest(self) -> str:
        return hashlib.sha256(self.asset.read_bytes()).hexdigest()

    @unittest.skipUnless(HAS_ZSTD, "zstd not installed")
    def test_checksum_mismatch_leaves_dest_untouched(self) -> None:
        lock = self._write_lock("0" * 64)

        result = self._run(lock)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not match locked", result.stderr)
        self.assertFalse(self.dest.exists())

    @unittest.skipUnless(HAS_ZSTD, "zstd not installed")
    def test_matching_checksum_extracts_prefix(self) -> None:
        lock = self._write_lock(self._digest())

        result = self._run(lock)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.dest / "lib/pkgconfig/mpv.pc").read_text(encoding="utf-8"),
            "Name: mpv\n",
        )

    @unittest.skipUnless(HAS_ZSTD, "zstd not installed")
    def test_unsupported_machine_is_a_clear_error(self) -> None:
        lock = self._write_lock(self._digest(), machine="not-this-machine")

        result = self._run(lock)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn(f"no linux asset for {platform.machine()!r}", result.stderr)
        self.assertIn("not-this-machine", result.stderr)
        self.assertFalse(self.dest.exists())

    def test_missing_zstd_fails_before_fetching(self) -> None:
        lock = self._write_lock(self._digest())
        empty_path = self.root / "empty-path"
        empty_path.mkdir()
        env = {key: value for key, value in os.environ.items() if key != "PATH"}
        env["PATH"] = str(empty_path)

        result = self._run(lock, env=env)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("zstd is required", result.stderr)
        self.assertNotIn("fetching", result.stdout)
        self.assertFalse(self.dest.exists())


if __name__ == "__main__":
    unittest.main()
