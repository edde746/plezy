#!/usr/bin/env python3
"""Exercise updater trust configuration using the public RFC 8032 test vector."""
import base64
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SEED = base64.b64encode(bytes.fromhex("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")).decode()
PUBLIC = base64.b64encode(bytes.fromhex("d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a")).decode()
UPSTREAM = "q7t6eu1txRrqv1PeWDCRV95rFxnmD/D3GZWbUPMwUyU="


class UpdaterTrustTest(unittest.TestCase):
    def run_config(self, public="", private="", repository="snapetech-org/PlezyNG"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("macos/Runner/Info.plist", "windows/runner/Runner.rc"):
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / name, target)
            environment = dict(os.environ, GITHUB_REPOSITORY=repository,
                               SPARKLE_PUBLIC_KEY=public, SPARKLE_PRIVATE_KEY=private,
                               GITHUB_ENV=str(root / "github-env"))
            result = subprocess.run(["dart", "run", str(ROOT / "scripts/configure_updater.dart")],
                                    cwd=root, env=environment, capture_output=True, text=True)
            # No private signing material can appear in diagnostics.
            self.assertNotIn(SEED, result.stdout + result.stderr)
            written = (root / "macos/Runner/Info.plist").read_text()
            flag = (root / "github-env").read_text() if (root / "github-env").exists() else ""
            return result, written, flag

    def test_missing_key_keeps_manual_updates(self):
        result, _, flag = self.run_config()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("NATIVE_UPDATER_CONFIGURED=false", flag)

    def test_matching_key_configures_signed_updates(self):
        result, written, flag = self.run_config(PUBLIC, SEED)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(PUBLIC, written)
        self.assertIn("NATIVE_UPDATER_CONFIGURED=true", flag)

    def test_rejects_mismatched_or_unowned_keys(self):
        for public, private in ((UPSTREAM, ""), ("bad", ""), ("", SEED), (PUBLIC, "bad"),
                                (base64.b64encode(bytes(32)).decode(), SEED)):
            result, _, flag = self.run_config(public, private)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(flag, "")


if __name__ == "__main__":
    unittest.main()
