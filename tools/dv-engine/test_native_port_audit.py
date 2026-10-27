from pathlib import Path
import subprocess
import tempfile
import unittest

from audit_native_ports import apply_series, production_series


class NativePortAuditTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.build = self.root / "build"
        self.pool = self.build / "patches/mpv/pool"
        self.pool.mkdir(parents=True)
        self.source = self.root / "source"
        self.source.mkdir()
        subprocess.run(["git", "init", "-q", self.source], check=True)
        (self.source / "file.txt").write_text("original\n")

    def patch(self, name, old, new):
        path = self.pool / name
        path.write_text(f"diff --git a/file.txt b/file.txt\n--- a/file.txt\n+++ b/file.txt\n@@ -1 +1 @@\n-{old}\n+{new}\n")
        return path

    def test_series_order_and_real_application(self):
        self.patch("common.patch", "original", "shared")
        self.patch("android.patch", "shared", "android")
        (self.pool.parent / "series.common").write_text("# common first\ncommon.patch\n")
        (self.pool.parent / "series.android").write_text("android.patch\n")
        patches = production_series(self.build, "mpv", "android")
        result = apply_series(self.source, patches)
        self.assertEqual((self.source / "file.txt").read_text(), "android\n")
        self.assertEqual([p["name"] for p in result["applied"]], ["common.patch", "android.patch"])
        self.assertEqual(result["remaining"], [])
        self.assertIn("unverified", result["status"])

    def test_conflict_preserves_tree_and_does_not_skip(self):
        patches = [self.patch("first.patch", "original", "first"),
                   self.patch("conflict.patch", "wrong-base", "second"),
                   self.patch("last.patch", "first", "must-not-apply")]
        result = apply_series(self.source, patches)
        self.assertEqual(result["status"], "rebase_required")
        self.assertEqual(result["failed_patch"], "conflict.patch")
        self.assertEqual(result["remaining"], ["conflict.patch", "last.patch"])
        self.assertEqual((self.source / "file.txt").read_text(), "first\n")

    def test_duplicate_series_rejected(self):
        self.patch("same.patch", "original", "new")
        (self.pool.parent / "series.common").write_text("same.patch\n")
        (self.pool.parent / "series.apple").write_text("same.patch\n")
        with self.assertRaisesRegex(ValueError, "duplicate"):
            production_series(self.build, "mpv", "apple")

    def test_path_escape_rejected(self):
        (self.pool.parent / "series.common").write_text("../outside.patch\n")
        with self.assertRaisesRegex(ValueError, "Invalid"):
            production_series(self.build, "mpv", "linux")


if __name__ == "__main__":
    unittest.main()
