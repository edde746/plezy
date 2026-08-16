#!/usr/bin/env python3

import hashlib
import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("verify_runtime_inputs.py")
SPEC = importlib.util.spec_from_file_location("verify_runtime_inputs", SCRIPT)
CHECKER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(CHECKER)
REPOSITORY = Path(__file__).resolve().parents[2]

FIXTURES = (
    "pubspec.lock",
    "linux/CMakeLists.txt",
    "linux/packaging/build-libmpv.sh",
    "linux/packaging/native-inputs.json",
    "packages/wakelock_plus/pubspec.yaml",
    "packages/wakelock_plus/pubspec.lock",
    "packages/wakelock_plus/provenance.json",
    "packages/wakelock_plus/pigeons/messages.dart",
    "packages/wakelock_plus/android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt",
    "packages/wakelock_plus/ios/wakelock_plus/Sources/wakelock_plus/include/wakelock_plus/messages.g.h",
    "packages/wakelock_plus/ios/wakelock_plus/Sources/wakelock_plus/messages.g.m",
)


class RuntimeInputVerifierTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        temporary_root = Path(self.temporary.name)
        repository = temporary_root / "repository"
        repository.mkdir()
        for relative in (".gitattributes", *FIXTURES):
            source = REPOSITORY / relative
            destination = repository / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
        (repository / "crlf-control.txt").write_bytes(b"control\n")
        subprocess.run(["git", "init", "-q"], cwd=repository, check=True)
        subprocess.run(["git", "config", "user.email", "fixture@example.invalid"], cwd=repository, check=True)
        subprocess.run(["git", "config", "user.name", "Fixture"], cwd=repository, check=True)
        subprocess.run(["git", "config", "core.autocrlf", "false"], cwd=repository, check=True)
        subprocess.run(["git", "add", "."], cwd=repository, check=True)
        subprocess.run(["git", "commit", "-qm", "fixture"], cwd=repository, check=True)

        self.root = temporary_root / "worktree"
        subprocess.run(
            [
                "git",
                "clone",
                "-q",
                "-c",
                "core.autocrlf=true",
                str(repository),
                str(self.root),
            ],
            check=True,
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _json(self, relative: str) -> dict:
        return json.loads((self.root / relative).read_text(encoding="utf-8"))

    def _write_json(self, relative: str, payload: dict) -> None:
        (self.root / relative).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    def test_reviewed_inputs_pass_library_and_offline_cli(self) -> None:
        self.assertEqual([], CHECKER.validate(self.root))
        completed = subprocess.run(
            [sys.executable, str(SCRIPT), "--root", str(self.root)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, completed.returncode, completed.stdout + completed.stderr)
        self.assertIn("verified offline", completed.stdout)

    def test_crlf_worktree_preserves_canonical_lf_provenance_inputs(self) -> None:
        self.assertIn(b"\r\n", (self.root / "crlf-control.txt").read_bytes())
        provenance = self._json("packages/wakelock_plus/provenance.json")

        for relative, expected in provenance["artifacts"].items():
            contents = (self.root / "packages/wakelock_plus" / relative).read_bytes()
            self.assertNotIn(b"\r\n", contents, relative)
            self.assertEqual(expected, hashlib.sha256(contents).hexdigest(), relative)

        self.assertEqual([], CHECKER.validate(self.root))

    def test_crlf_artifact_drift_is_not_normalized_before_hashing(self) -> None:
        relative = "pigeons/messages.dart"
        path = self.root / "packages/wakelock_plus" / relative
        canonical = path.read_bytes()
        self.assertIn(b"\n", canonical)
        path.write_bytes(canonical.replace(b"\n", b"\r\n"))

        errors = CHECKER.validate(self.root)

        self.assertTrue(any(str(path) in error and "SHA-256 drift" in error for error in errors))
        provenance = self._json("packages/wakelock_plus/provenance.json")
        self.assertNotEqual(
            provenance["artifacts"][relative],
            hashlib.sha256(path.read_bytes()).hexdigest(),
        )

    def test_rejects_linux_cmake_checksum_drift(self) -> None:
        path = self.root / "linux/CMakeLists.txt"
        path.write_text(path.read_text(encoding="utf-8").replace("9fe4d6f5", "0fe4d6f5"), encoding="utf-8")

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("simdutf SHA-256 differs" in error for error in errors))

    def test_rejects_malformed_native_pin_and_version_url_drift(self) -> None:
        manifest = self._json("linux/packaging/native-inputs.json")
        manifest["inputs"]["ffmpeg"]["sha256"] = "not-a-digest"
        manifest["inputs"]["mpv"]["url"] = "https://example.invalid/mpv-current.tar.gz"
        self._write_json("linux/packaging/native-inputs.json", manifest)

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("ffmpeg.sha256" in error for error in errors))
        self.assertTrue(any("mpv.url" in error and "declared version" in error for error in errors))

    def test_reports_missing_simdutf_fields_without_crashing(self) -> None:
        manifest = self._json("linux/packaging/native-inputs.json")
        simdutf = manifest["inputs"]["simdutf"]
        simdutf.pop("url")
        simdutf.pop("sha256")
        self._write_json("linux/packaging/native-inputs.json", manifest)

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("simdutf.url" in error and "non-empty text" in error for error in errors))
        self.assertTrue(any("simdutf.sha256" in error and "lowercase full SHA-256" in error for error in errors))

    def test_rejects_disconnected_production_acquisition(self) -> None:
        path = self.root / "linux/packaging/build-libmpv.sh"
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                'download_verified "$MPV_URL" "$MPV_SHA256"',
                'curl "$MPV_URL"',
            ),
            encoding="utf-8",
        )

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("MPV_URL" in error and "manifest-backed" in error for error in errors))

    def test_rejects_binding_source_or_output_drift(self) -> None:
        schema = self.root / "packages/wakelock_plus/pigeons/messages.dart"
        schema.write_text(schema.read_text(encoding="utf-8") + "// changed\n", encoding="utf-8")
        kotlin = self.root / (
            "packages/wakelock_plus/android/src/main/kotlin/"
            "dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt"
        )
        kotlin.write_bytes(kotlin.read_bytes() + b"\n")

        errors = CHECKER.validate(self.root)

        self.assertGreaterEqual(sum("SHA-256 drift" in error for error in errors), 2)

    def test_rejects_generator_and_external_client_lock_drift(self) -> None:
        pubspec = self.root / "packages/wakelock_plus/pubspec.yaml"
        pubspec.write_text(pubspec.read_text(encoding="utf-8").replace("pigeon: 26.2.3", "pigeon: ^26.2.3"), encoding="utf-8")
        lock = self.root / "packages/wakelock_plus/pubspec.lock"
        lock.write_text(
            lock.read_text(encoding="utf-8").replace(
                "24b84143787220a403491c2e5de0877fbbb87baf3f0b18a2a988973863db4b03",
                "04b84143787220a403491c2e5de0877fbbb87baf3f0b18a2a988973863db4b03",
            ),
            encoding="utf-8",
        )
        root_lock = self.root / "pubspec.lock"
        root_lock.write_text(
            root_lock.read_text(encoding="utf-8").replace(
                "24b84143787220a403491c2e5de0877fbbb87baf3f0b18a2a988973863db4b03",
                "14b84143787220a403491c2e5de0877fbbb87baf3f0b18a2a988973863db4b03",
            ),
            encoding="utf-8",
        )

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("Pigeon must be pinned exactly" in error for error in errors))
        self.assertTrue(any("platform-interface version/checksum differs" in error for error in errors))
        self.assertTrue(any("runtime platform-interface" in error for error in errors))

    def test_missing_binding_reports_error_without_discarding_earlier_errors(self) -> None:
        manifest = self._json("linux/packaging/native-inputs.json")
        manifest["inputs"]["simdutf"].pop("url")
        self._write_json("linux/packaging/native-inputs.json", manifest)
        kotlin = self.root / (
            "packages/wakelock_plus/android/src/main/kotlin/"
            "dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt"
        )
        kotlin.unlink()

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("simdutf.url" in error for error in errors))
        self.assertTrue(any(str(kotlin) in error and "cannot read generated binding" in error for error in errors))

    def test_accepts_benign_prose_contract_edits(self) -> None:
        native = self._json("linux/packaging/native-inputs.json")
        native["refreshContract"] = {"rules": ["Reworded maintainer guidance."]}
        native["inputs"]["ffmpeg"]["provenance"] = "Reviewed release evidence."
        self._write_json("linux/packaging/native-inputs.json", native)

        provenance = self._json("packages/wakelock_plus/provenance.json")
        provenance["plezyDeltas"] = ["Reworded local-change notes."]
        provenance["refreshContract"] = ["Reworded refresh guidance."]
        provenance["externalDartClient"]["contract"] = "Reworded client guidance."
        self._write_json("packages/wakelock_plus/provenance.json", provenance)

        self.assertEqual([], CHECKER.validate(self.root))

    def test_rejects_dart_output_from_host_only_schema(self) -> None:
        schema = self.root / "packages/wakelock_plus/pigeons/messages.dart"
        schema.write_text(
            schema.read_text(encoding="utf-8").replace(
                "PigeonOptions(",
                "PigeonOptions(\n    dartOut: '../other/lib/messages.g.dart',",
            ),
            encoding="utf-8",
        )

        errors = CHECKER.validate(self.root)

        self.assertTrue(any("must not generate Dart outputs" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
