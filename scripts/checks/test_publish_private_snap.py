#!/usr/bin/env python3
"""Exercise publication validation and command boundaries without network/upload."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class PublishPrivateSnapTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="plezy-snap-upload-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "scripts").mkdir()
        (self.root / "linux/packaging/snap").mkdir(parents=True)
        self.script = self.root / "scripts/publish_private_snap.sh"
        shutil.copyfile(ROOT / "scripts/publish_private_snap.sh", self.script)
        shutil.copyfile(
            ROOT / "linux/packaging/snap/toolchain.lock.json",
            self.root / "linux/packaging/snap/toolchain.lock.json",
        )
        self.temporary = self.root / "job"
        self.packages = self.temporary / "plezyng-snap"
        self.packages.mkdir(parents=True)
        self.package = self.packages / "plezyng-linux-arm64.snap"
        self.package.write_bytes(b"fixture package; no real upload")
        self.manifest = self.packages / "SHA256SUMS.txt"
        self.manifest.write_text(
            hashlib.sha256(self.package.read_bytes()).hexdigest()
            + "  " + self.package.name + "\n"
        )
        self.bin = self.root / "bin"
        self.bin.mkdir()
        uname = self.bin / "uname"
        uname.write_text("#!/bin/sh\ncase \"$1\" in -s) echo Linux;; -m) echo \"${FAKE_MACHINE:-x86_64}\";; esac\n")
        uname.chmod(0o755)
        sudo = self.bin / "sudo"
        sudo.write_text("""#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
args=sys.argv[1:]
with open(os.environ['FAKE_COMMANDS'],'a') as log:
    log.write(json.dumps(args)+'\\n')
if 'podman' in args:
    args=args[args.index('podman')+1:]
    if args[:2]==['image','inspect']:
        print(os.environ.get('FAKE_IMAGE_ARCH','amd64'))
    elif args and args[0]=='run':
        Path(args[args.index('--cidfile')+1]).write_text('a'*64+'\\n')
        raise SystemExit(int(os.environ.get('FAKE_UPLOAD_STATUS','0')))
""")
        sudo.chmod(0o755)
        self.commands = self.root / "commands.jsonl"
        self.secret = "test-only-credential-must-never-appear-in-argv"
        self.env = os.environ | {
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "GITHUB_ACTIONS": "true", "GITHUB_RUN_ID": "123456",
            "RUNNER_ENVIRONMENT": "self-hosted", "RUNNER_TEMP": str(self.temporary),
            "HTTPS_PROXY": "http://10.0.2.100:3128",
            "SNAPCRAFT_STORE_CREDENTIALS": self.secret,
            "FAKE_COMMANDS": str(self.commands),
        }

    def run_helper(self, channel="stable", package=None, **env):
        return subprocess.run(
            ["bash", "-x", str(self.script), str(package or self.package), channel],
            env=self.env | env, text=True, capture_output=True,
        )

    def recorded(self):
        if not self.commands.exists():
            return []
        return [json.loads(line) for line in self.commands.read_text().splitlines()]

    def assert_rejected_before_tools(self, result):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.recorded(), [])
        self.assertNotIn(self.secret, result.stdout + result.stderr)

    def test_verified_arm_package_upload_on_x64_uses_environment_name_only(self):
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        commands = self.recorded()
        upload = next(args for args in commands if "run" in args)
        self.assertIn("--preserve-env=SNAPCRAFT_STORE_CREDENTIALS", upload)
        self.assertIn("SNAPCRAFT_STORE_CREDENTIALS", upload)
        self.assertIn(str(self.package) + ":/artifact/package.snap:ro", upload)
        self.assertEqual(upload[-4:], ["upload", "/artifact/package.snap", "--release", "stable"])
        self.assertTrue(any(args[-4:] == ["rm", "--force", "--ignore", "a" * 64] for args in commands))
        self.assertNotIn(self.secret, self.commands.read_text() + result.stdout + result.stderr)

    def test_upload_failure_propagates_and_cleans_only_owned_container(self):
        result = self.run_helper(FAKE_UPLOAD_STATUS="13")
        self.assertEqual(result.returncode, 13, result.stdout + result.stderr)
        self.assertEqual(self.recorded()[-1][-4:], ["rm", "--force", "--ignore", "a" * 64])

    def test_wrong_image_architecture_never_uploads(self):
        result = self.run_helper(FAKE_IMAGE_ARCH="arm64")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any("run" in args for args in self.recorded()))

    def test_untrusted_context_and_unsupported_host_fail_before_tools(self):
        for override in [{"GITHUB_ACTIONS": "false"}, {"RUNNER_ENVIRONMENT": "github-hosted"},
                         {"GITHUB_RUN_ID": "invalid"}, {"FAKE_MACHINE": "aarch64"}]:
            with self.subTest(override=override):
                self.assert_rejected_before_tools(self.run_helper(**override))

    def test_channel_proxy_and_credentials_fail_closed(self):
        self.assert_rejected_before_tools(self.run_helper(channel="stable,edge"))
        for proxy in ["", "http://user:password@proxy:3128", "http://proxy:3128/path", "http://proxy:3128\n"]:
            with self.subTest(proxy=proxy):
                self.assert_rejected_before_tools(self.run_helper(HTTPS_PROXY=proxy, https_proxy=""))
        self.assert_rejected_before_tools(self.run_helper(SNAPCRAFT_STORE_CREDENTIALS=""))

    def test_unmatched_and_duplicate_manifest_entries_fail_before_tools(self):
        correct = self.manifest.read_text()
        for contents in ["0" * 64 + "  " + self.package.name + "\n", correct * 2,
                         correct.replace(self.package.name, "some-other.snap")]:
            self.manifest.write_text(contents)
            self.assert_rejected_before_tools(self.run_helper())

    def test_symlink_package_and_checksum_manifest_fail_before_tools(self):
        original = self.package.with_suffix(".saved")
        self.package.rename(original)
        self.package.symlink_to(original)
        self.assert_rejected_before_tools(self.run_helper())
        self.package.unlink()
        original.rename(self.package)
        manifest = self.manifest.with_suffix(".saved")
        self.manifest.rename(manifest)
        self.manifest.symlink_to(manifest)
        self.assert_rejected_before_tools(self.run_helper())

    def test_outside_job_package_and_existing_container_receipt_fail_before_tools(self):
        outside = self.root / self.package.name
        shutil.copyfile(self.package, outside)
        self.assert_rejected_before_tools(self.run_helper(package=outside))
        (self.temporary / f"plezyng-snap-publish-{self.package.name}.cid").write_text("b" * 64)
        self.assert_rejected_before_tools(self.run_helper())


if __name__ == "__main__":
    unittest.main()
