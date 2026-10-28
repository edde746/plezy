import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "retain_private_candidate.py"
SPEC = importlib.util.spec_from_file_location("retain_private_candidate", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PrivateCandidateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="plezy-webos-retention-")
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name).resolve()
        self.source = root / "source"
        self.destination = root / "private-outputs"
        self.source.mkdir()
        self.destination.mkdir()
        self.files = {
            "org.snapetech.plezyng_3.0.0_arm.ipk": b"verified test package",
            "webos-engine-provenance.json": b'{"source": "test"}\n',
            "webos-compatibility.json": b'{"releaseEligible": false}\n',
        }
        for name, content in self.files.items():
            (self.source / name).write_bytes(content)
        self.checksums = "".join(
            f"{hashlib.sha256(content).hexdigest()}  {name}\n"
            for name, content in self.files.items()
        )
        (self.source / "SHA256SUMS.txt").write_text(self.checksums)
        self.env = {
            "GHA_JIT_OUTPUTS": str(self.destination),
            "GITHUB_REPOSITORY": "snapetech-org/PlezyNG",
            "GITHUB_JOB": "build-webos", "GITHUB_RUN_ID": "42",
            "GITHUB_RUN_ATTEMPT": "1", "GITHUB_SHA": "a" * 40,
        }
        self.addCleanup(patch.stopall)
        patch.object(MODULE, "PRIVATE_OUTPUTS", self.destination).start()
        self.mount = patch.object(Path, "is_mount", return_value=True).start()

    def test_exact_candidate_and_identity_survive_copy(self):
        receipt = MODULE.retain(self.source, "3.0.0+159", self.env)
        data = json.loads(receipt.read_text())
        self.assertEqual(data["identity"]["GITHUB_SHA"], "a" * 40)
        self.assertEqual(data["version"], "3.0.0")
        self.assertEqual(set(data["files"]), set(self.files) | {"SHA256SUMS.txt"})
        for name, digest in data["files"].items():
            self.assertEqual((self.destination / name).read_bytes(), (self.source / name).read_bytes())
            self.assertEqual(hashlib.sha256((self.destination / name).read_bytes()).hexdigest(), digest)

    def test_missing_private_mount_fails_before_copy(self):
        self.mount.return_value = False
        with self.assertRaisesRegex(ValueError, "not mounted"):
            MODULE.retain(self.source, "3.0.0", self.env)
        self.assertEqual(list(self.destination.iterdir()), [])

    def test_wrong_job_identity_or_output_path_fails(self):
        for key, value in (("GITHUB_JOB", "build-linux"), ("GITHUB_REPOSITORY", "other/repo"),
                           ("GITHUB_SHA", "main"), ("GHA_JIT_OUTPUTS", str(self.source))):
            with self.subTest(key=key), self.assertRaises(ValueError):
                MODULE.retain(self.source, "3.0.0", self.env | {key: value})

    def test_previous_output_is_never_overwritten(self):
        sentinel = self.destination / "previous.ipk"
        sentinel.write_bytes(b"preserved")
        with self.assertRaisesRegex(ValueError, "empty"):
            MODULE.retain(self.source, "3.0.0", self.env)
        self.assertEqual(sentinel.read_bytes(), b"preserved")

    def test_bad_or_duplicate_checksums_never_produce_receipt(self):
        for content in (self.checksums.replace(self.checksums[:64], "0" * 64, 1),
                        self.checksums + self.checksums.splitlines()[0] + "\n"):
            with self.subTest(content=content[:64]):
                (self.source / "SHA256SUMS.txt").write_text(content)
                with self.assertRaisesRegex(ValueError, "checksum"):
                    MODULE.retain(self.source, "3.0.0", self.env)
                self.assertFalse((self.destination / MODULE.RECEIPT).exists())
                for path in self.destination.iterdir():
                    path.unlink()

    def test_symlinks_and_extra_files_cannot_escape_allowlist(self):
        extra = self.source / "unexpected.txt"
        extra.write_text("not an output")
        with self.assertRaisesRegex(ValueError, "exactly one"):
            MODULE.retain(self.source, "3.0.0", self.env)
        extra.unlink()
        ipk = self.source / "org.snapetech.plezyng_3.0.0_arm.ipk"
        ipk.unlink()
        ipk.symlink_to(self.source / "webos-compatibility.json")
        with self.assertRaises(OSError):
            MODULE.retain(self.source, "3.0.0", self.env)
        self.assertFalse((self.destination / MODULE.RECEIPT).exists())

    def test_another_version_cannot_be_retained(self):
        with self.assertRaisesRegex(ValueError, "version-matched"):
            MODULE.retain(self.source, "2.25.0", self.env)


if __name__ == "__main__":
    unittest.main()
