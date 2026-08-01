import hashlib
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
GENERATED_PATHS = (
    "lib/data/ducet_order.dart",
    "lib/data/hid_key_labels.dart",
    "lib/data/iso_639_data.dart",
    "lib/i18n/strings.g.dart",
    "lib/models/model.freezed.dart",
    "lib/models/model.g.dart",
    "lib/watch_together/services/relay_protocol.g.dart",
    "server/relay_protocol_gen.go",
)


def executable(path: Path, contents: str) -> None:
    path.write_text(contents, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


class CodegenCheckTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        temporary_root = Path(self.temp.name)
        repository = temporary_root / "repository"
        repository.mkdir()
        self.codegen_temp = Path(tempfile.mkdtemp(prefix="plezy-codegen-test-temp-"))
        subprocess.run(["git", "init", "-q"], cwd=repository, check=True)
        subprocess.run(["git", "config", "user.email", "fixture@example.invalid"], cwd=repository, check=True)
        subprocess.run(["git", "config", "user.name", "Fixture"], cwd=repository, check=True)
        subprocess.run(["git", "config", "core.autocrlf", "false"], cwd=repository, check=True)

        shutil.copy2(SCRIPT_DIR.parent / ".gitattributes", repository / ".gitattributes")

        (repository / "scripts").mkdir()
        shutil.copy2(SCRIPT_DIR / "codegen.sh", repository / "scripts" / "codegen.sh")
        shutil.copy2(SCRIPT_DIR / "check_codegen.py", repository / "scripts" / "check_codegen.py")
        (repository / "scripts" / "generate_relay_protocol.py").write_text("fixture\n", encoding="utf-8")
        (repository / "source.txt").write_text("version one\n", encoding="utf-8")
        for relative in GENERATED_PATHS:
            path = repository / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("version one\n", encoding="utf-8")

        self.bin = temporary_root / "fake-bin"
        self.bin.mkdir()
        executable(
            self.bin / "python3",
            """#!/usr/bin/env bash
write_lf() { tr -d '\\r' < source.txt > "$1"; }
if [[ "$1" == *check_codegen.py ]]; then exec "$REAL_PYTHON" "$@"; fi
mkdir -p lib/watch_together/services server
write_lf lib/watch_together/services/relay_protocol.g.dart
cp source.txt server/relay_protocol_gen.go
""",
        )
        executable(
            self.bin / "dart",
            """#!/usr/bin/env bash
write_lf() { tr -d '\\r' < source.txt > "$1"; }
if [ "${FAIL_DART:-0}" -ne 0 ]; then exit "$FAIL_DART"; fi
case "$*" in
  *"generate_ducet_ranks.dart")
    mkdir -p lib/data
    write_lf lib/data/ducet_order.dart
    ;;
  *"generate_hid_key_labels.dart")
    mkdir -p lib/data
    write_lf lib/data/hid_key_labels.dart
    ;;
  *"generate_iso_639_data.dart")
    mkdir -p lib/data
    write_lf lib/data/iso_639_data.dart
    ;;
  "run slang")
    mkdir -p lib/i18n
    write_lf lib/i18n/strings.g.dart
    ;;
  *"build_runner"*)
    mkdir -p lib/models
    write_lf lib/models/model.g.dart
    write_lf lib/models/model.freezed.dart
    printf '%s\n' "$*" > build-runner-args.txt
    ;;
esac
""",
        )
        subprocess.run(
            ["git", "add", ".gitattributes", "scripts", "source.txt", "lib", "server"],
            cwd=repository,
            check=True,
        )
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
        self.env = os.environ | {
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "REAL_PYTHON": sys.executable,
            "TMPDIR": str(self.codegen_temp),
        }


    def tearDown(self) -> None:
        self.temp.cleanup()
        shutil.rmtree(self.codegen_temp, ignore_errors=True)

    def generated_state(self) -> dict[str, str]:
        state = {}
        for relative in GENERATED_PATHS:
            path = self.root / relative
            if path.is_file():
                state[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
        for path in (self.root / "lib").rglob("*.dart"):
            relative = path.relative_to(self.root).as_posix()
            if relative.endswith(".g.dart") or relative.endswith(".freezed.dart"):
                state.setdefault(relative, hashlib.sha256(path.read_bytes()).hexdigest())
        return state

    def git_status(self) -> bytes:
        return subprocess.run(
            ["git", "status", "--porcelain=v1", "-z"],
            cwd=self.root,
            check=True,
            capture_output=True,
        ).stdout

    def run_codegen(self, *arguments: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", "scripts/codegen.sh", *arguments],
            cwd=self.root,
            env=self.env if env is None else env,
            check=False,
            capture_output=True,
            text=True,
        )

    def assert_isolation_cleaned_up(self) -> None:
        worktrees = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            cwd=self.root,
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        self.assertEqual(worktrees.count("worktree "), 1)
        self.assertEqual(list(self.codegen_temp.glob("plezy-codegen-check-*")), [])

    def test_crlf_worktree_keeps_generated_dart_lf_and_comparisons_byte_exact(self) -> None:
        self.assertIn(b"\r\n", (self.root / "source.txt").read_bytes())
        dart_outputs = [
            self.root / relative
            for relative in GENERATED_PATHS
            if relative.endswith(".dart")
        ]
        self.assertTrue(dart_outputs)
        self.assertTrue(all(b"\r\n" not in path.read_bytes() for path in dart_outputs))
        self.assertEqual(self.run_codegen("--check").returncode, 0)

        drifted = self.root / "lib/models/model.g.dart"
        drifted.write_bytes(drifted.read_bytes().replace(b"\n", b"\r\n"))
        result = self.run_codegen("--check")

        self.assertEqual(result.returncode, 1)
        self.assertIn("lib/models/model.g.dart", result.stderr)
        self.assertIn(b"\r\n", drifted.read_bytes())

    def test_stale_check_reports_sorted_paths_without_changing_caller(self) -> None:
        (self.root / "source.txt").write_text("version two\n", encoding="utf-8")
        before = self.generated_state()
        status_before = self.git_status()

        result = self.run_codegen("--check")

        self.assertEqual(result.returncode, 1)
        self.assertEqual(
            result.stderr.splitlines(),
            [
                "Generated files are out of date:",
                *(f"  {relative}" for relative in GENERATED_PATHS),
                "Run 'scripts/codegen.sh' and commit the result.",
            ],
        )
        self.assertEqual(self.generated_state(), before)
        self.assertEqual(self.git_status(), status_before)
        self.assert_isolation_cleaned_up()

    def test_generator_failure_propagates_without_partial_writes(self) -> None:
        (self.root / "source.txt").write_text("version two\n", encoding="utf-8")
        before = self.generated_state()
        status_before = self.git_status()

        result = self.run_codegen("--check", env=self.env | {"FAIL_DART": "7"})

        self.assertEqual(result.returncode, 7)
        self.assertEqual(self.generated_state(), before)
        self.assertEqual(self.git_status(), status_before)
        self.assert_isolation_cleaned_up()

    def test_index_boundary_requires_matching_staged_outputs(self) -> None:
        (self.root / "source.txt").write_text("version two\n", encoding="utf-8")
        self.assertEqual(self.run_codegen().returncode, 0)
        unstaged_state = self.generated_state()
        self.assertEqual(self.run_codegen("--check").returncode, 1)
        self.assertEqual(self.generated_state(), unstaged_state)

        subprocess.run(["git", "add", "source.txt", "lib", "server/relay_protocol_gen.go"], cwd=self.root, check=True)
        self.assertEqual(self.run_codegen("--check").returncode, 0)

        incorrect = self.root / "lib" / "models" / "model.g.dart"
        incorrect.write_text("incorrect staged output\n", encoding="utf-8")
        subprocess.run(["git", "add", str(incorrect.relative_to(self.root))], cwd=self.root, check=True)
        status_before = self.git_status()

        result = self.run_codegen("--check")

        self.assertEqual(result.returncode, 1)
        self.assertIn("lib/models/model.g.dart", result.stderr)
        self.assertEqual(incorrect.read_text(encoding="utf-8"), "incorrect staged output\n")
        self.assertEqual(self.git_status(), status_before)

    def test_rename_overlay_removes_source_before_running_generators(self) -> None:
        renamed = self.root / "renamed-source.txt"
        subprocess.run(["git", "mv", "source.txt", renamed.name], cwd=self.root, check=True)
        for command in (self.bin / "python3", self.bin / "dart"):
            contents = command.read_text(encoding="utf-8").replace(
                "source.txt", renamed.name
            )
            contents = contents.replace(
                "\n", "\nif [ -e source.txt ]; then exit 23; fi\n", 1
            )
            executable(command, contents)

        result = self.run_codegen("--check")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root / "source.txt").exists())
        self.assertEqual(renamed.read_text(encoding="utf-8"), "version one\n")
        self.assert_isolation_cleaned_up()

    def test_deleted_and_untracked_outputs_are_reported_without_repair(self) -> None:
        deleted = self.root / "lib" / "models" / "model.g.dart"
        deleted.unlink()
        untracked = self.root / "lib" / "models" / "extra.g.dart"
        untracked.write_text("caller sentinel\n", encoding="utf-8")
        status_before = self.git_status()

        result = self.run_codegen("--check")

        self.assertEqual(result.returncode, 1)
        self.assertIn("lib/models/extra.g.dart", result.stderr)
        self.assertIn("lib/models/model.g.dart", result.stderr)
        self.assertFalse(deleted.exists())
        self.assertEqual(untracked.read_text(encoding="utf-8"), "caller sentinel\n")
        self.assertEqual(self.git_status(), status_before)

    def test_deleted_explicit_dart_output_is_reported_without_repair(self) -> None:
        deleted = self.root / "lib" / "data" / "hid_key_labels.dart"
        deleted.unlink()
        status_before = self.git_status()

        result = self.run_codegen("--check")

        self.assertEqual(result.returncode, 1)
        self.assertIn("lib/data/hid_key_labels.dart", result.stderr)
        self.assertFalse(deleted.exists())
        self.assertEqual(self.git_status(), status_before)

    def test_write_mode_updates_outputs_and_forwards_build_runner_arguments(self) -> None:
        (self.root / "source.txt").write_text("version two\n", encoding="utf-8")

        result = self.run_codegen("--build-filter=lib/models/**")

        self.assertEqual(result.returncode, 0)
        for relative in GENERATED_PATHS:
            self.assertEqual((self.root / relative).read_text(encoding="utf-8"), "version two\n")
        self.assertEqual(
            (self.root / "build-runner-args.txt").read_text(encoding="utf-8"),
            "run build_runner build --build-filter=lib/models/**\n",
        )

if __name__ == "__main__":
    unittest.main()
