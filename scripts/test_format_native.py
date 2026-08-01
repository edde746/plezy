import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "format_native.sh"
DIGEST = "a16be01dcc480aab2f55f444b620142152f66e31564b3b9376506d624c28a2ad"
JAVA_DIAGNOSTIC = (
    "A working JDK 17+ is required for Kotlin formatting. "
    "Set JAVA_HOME to a JDK 17+ installation or put java on PATH."
)


def executable(path: Path, contents: str) -> Path:
    path.write_text(contents, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)
    return path


class NativeFormatterTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir()
        shutil.copy2(SCRIPT, self.root / "scripts" / "format_native.sh")
        (self.root / "android").mkdir()
        (self.root / "android" / "fixture.kt").write_text("class Fixture\n", encoding="utf-8")

        self.bin = self.root / "bin"
        self.bin.mkdir()
        executable(self.bin / "git", "#!/bin/bash\nprintf 'android/fixture.kt\\0'\n")
        executable(
            self.bin / "shasum",
            f"""#!/bin/bash
for file do :; done
case "${{HASH_MODE:-valid}}" in
  valid) digest={DIGEST} ;;
  invalid) digest={'0' * 64} ;;
  cache-invalid)
    case "$file" in
      */ktlint-1.5.0) digest={'0' * 64} ;;
      *) digest={DIGEST} ;;
    esac
    ;;
esac
printf '%s  %s\\n' "$digest" "$file"
printf 'shasum\\n' >> "$HASH_MARKER"
""",
        )
        self.download = executable(
            self.root / "download-ktlint",
            """#!/bin/bash
set -e
java -version >/dev/null 2>&1
printf '%s\n' "$*" >> "$KTLINT_ARGS_MARKER"
printf 'launched\n' >> "$KTLINT_MARKER"
""",
        )
        executable(
            self.bin / "curl",
            """#!/bin/bash
printf 'downloaded\n' >> "$CURL_MARKER"
out=''
while [ $# -gt 0 ]; do
  if [ "$1" = '-o' ]; then out=$2; shift 2; else shift; fi
done
cp "$FAKE_DOWNLOAD" "$out"
""",
        )
        self.env = os.environ.copy()
        self.env.pop("JAVA_HOME", None)
        self.env.update(
            {
                "PATH": f"{self.bin}:{self.env['PATH']}",
                "FAKE_DOWNLOAD": str(self.download),
                "CURL_MARKER": str(self.root / "curl.marker"),
                "HASH_MARKER": str(self.root / "hash.marker"),
                "JAVA_MARKER": str(self.root / "java.marker"),
                "KTLINT_ARGS_MARKER": str(self.root / "ktlint-args.marker"),
                "KTLINT_MARKER": str(self.root / "ktlint.marker"),
            }
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    @property
    def cache(self) -> Path:
        return self.root / ".dart_tool" / "native-format" / "ktlint-1.5.0"

    def java(self, directory: Path, version: str | None, *, identity: str = "path", status: int = 0) -> Path:
        directory.mkdir(parents=True, exist_ok=True)
        if version is None:
            output = "echo 'unrecognized java output' >&2"
        else:
            output = f"echo 'openjdk version \"{version}\"' >&2"
        return executable(
            directory / "java",
            f"""#!/bin/bash
printf '{identity} %s\\n' "$*" >> "$JAVA_MARKER"
{output}
exit {status}
""",
        )

    def install_cache(self, contents: bytes | None = None) -> None:
        self.cache.parent.mkdir(parents=True, exist_ok=True)
        if contents is None:
            shutil.copy2(self.download, self.cache)
        else:
            self.cache.write_bytes(contents)
        self.cache.chmod(self.cache.stat().st_mode | stat.S_IXUSR)

    def reset_markers(self) -> None:
        for marker in self.root.glob("*.marker"):
            marker.unlink()

    def run_script(
        self, *arguments: str, env: dict[str, str] | None = None
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["/bin/bash", "scripts/format_native.sh", *arguments],
            cwd=self.root,
            env=self.env if env is None else env,
            check=False,
            capture_output=True,
            text=True,
        )

    def assert_java_rejection(self, result: subprocess.CompletedProcess[str]) -> None:
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stderr.splitlines().count(JAVA_DIAGNOSTIC), 1)
        self.assertNotIn("integer expression expected", result.stderr)
        self.assertFalse((self.root / "curl.marker").exists())
        self.assertFalse((self.root / "ktlint.marker").exists())

    def test_unusable_java_rejects_cold_and_warm_cache_before_execution(self) -> None:
        self.java(self.bin, "17.0.12", status=1)
        self.assert_java_rejection(self.run_script("--check"))

        self.install_cache()
        self.reset_markers()
        self.assert_java_rejection(self.run_script("--check"))

    def test_java_home_runtime_and_ktlint_arguments_are_used_by_check_and_fix(self) -> None:
        self.java(self.bin, "17.0.12", identity="path-shim", status=1)
        home = self.root / "jdk home"
        self.java(home / "bin", "17.0.12", identity="java-home")
        env = self.env | {"JAVA_HOME": str(home)}

        expected_arguments = {
            "--check": "android/fixture.kt",
            "--fix": "-F android/fixture.kt",
        }
        for mode, expected in expected_arguments.items():
            with self.subTest(mode=mode):
                self.reset_markers()
                result = self.run_script(mode, env=env)
                self.assertEqual(result.returncode, 0, result.stderr)
                java_calls = (self.root / "java.marker").read_text(encoding="utf-8").splitlines()
                self.assertEqual(java_calls, ["java-home -version", "java-home -version"])
                self.assertEqual(
                    (self.root / "ktlint-args.marker").read_text(encoding="utf-8").strip(),
                    expected,
                )

    def test_java_version_support_floor_fails_closed(self) -> None:
        for version in ("17.0.12", "21.0.2"):
            with self.subTest(accepted=version):
                self.java(self.bin, version)
                self.reset_markers()
                result = self.run_script("--check")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue((self.root / "ktlint.marker").exists())

        for version, status in (("1.8.0_402", 0), ("16.0.2", 0), (None, 0), ("17.0.12", 1)):
            with self.subTest(rejected=version, status=status):
                self.java(self.bin, version, status=status)
                self.reset_markers()
                self.assert_java_rejection(self.run_script("--check"))

    def test_cache_verification_replacement_and_mismatch_cleanup(self) -> None:
        self.java(self.bin, "17.0.12")
        self.install_cache()
        valid = self.run_script("--check")
        self.assertEqual(valid.returncode, 0, valid.stderr)
        self.assertFalse((self.root / "curl.marker").exists())
        self.assertEqual((self.root / "ktlint.marker").read_text(encoding="utf-8").splitlines(), ["launched"])

        self.install_cache(b"invalid cache sentinel\n")
        self.reset_markers()
        replaced = self.run_script("--check", env=self.env | {"HASH_MODE": "cache-invalid"})
        self.assertEqual(replaced.returncode, 0, replaced.stderr)
        self.assertEqual(self.cache.read_bytes(), self.download.read_bytes())
        self.assertTrue((self.root / "curl.marker").exists())
        self.assertTrue((self.root / "ktlint.marker").exists())

        sentinel = b"preserve invalid cache\n"
        self.install_cache(sentinel)
        self.reset_markers()
        mismatch = self.run_script("--check", env=self.env | {"HASH_MODE": "invalid"})
        self.assertNotEqual(mismatch.returncode, 0)
        self.assertIn("failed SHA-256 verification", mismatch.stderr)
        self.assertEqual(self.cache.read_bytes(), sentinel)
        self.assertFalse((self.root / "ktlint.marker").exists())
        self.assertEqual(list(self.cache.parent.glob(".ktlint-1.5.0.*")), [])

    def test_sha256sum_fallback_verifies_and_executes(self) -> None:
        self.java(self.bin, "17.0.12")
        minimal = self.root / "minimal-bin"
        minimal.mkdir()
        for name in ("git", "java", "curl"):
            shutil.copy2(self.bin / name, minimal / name)
        executable(
            minimal / "sha256sum",
            f"#!/bin/bash\nfor file do :; done\nprintf '{DIGEST}  %s\\n' \"$file\"\nprintf 'sha256sum\\n' >> \"$HASH_MARKER\"\n",
        )
        for name, source in {
            "chmod": "/bin/chmod",
            "cp": "/bin/cp",
            "dirname": "/usr/bin/dirname",
            "mkdir": "/bin/mkdir",
            "mktemp": "/usr/bin/mktemp",
            "mv": "/bin/mv",
            "rm": "/bin/rm",
        }.items():
            (minimal / name).symlink_to(source)

        result = self.run_script("--check", env=self.env | {"PATH": str(minimal)})

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "hash.marker").read_text(encoding="utf-8").splitlines(), ["sha256sum"])
        self.assertTrue((self.root / "ktlint.marker").exists())

    def test_repository_without_kotlin_does_not_require_java_or_ktlint(self) -> None:
        executable(self.bin / "git", "#!/bin/bash\nexit 0\n")
        self.java(self.bin, "17.0.12", status=1)

        result = self.run_script("--check")

        self.assertEqual(result.returncode, 0, result.stderr)
        for marker in ("curl.marker", "hash.marker", "java.marker", "ktlint.marker"):
            self.assertFalse((self.root / marker).exists())
        self.assertFalse(self.cache.parent.exists())


if __name__ == "__main__":
    unittest.main()
