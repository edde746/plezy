import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "build_release_candidate.sh"


class BuildReleaseCandidateDirectoriesTests(unittest.TestCase):
    def test_nested_host_tools_directory_is_created_with_private_permissions(self):
        script = SCRIPT.read_text(encoding="utf-8")
        setup_start = script.index('LOG_ROOT="$TASK_ROOT/logs"\n')
        setup_end = script.index("exec > >(tee", setup_start)
        setup_block = script[setup_start:setup_end]

        with tempfile.TemporaryDirectory(prefix="plezy-webos-task-dirs-") as temporary:
            task_root = Path(temporary) / "plezyng-webos-123"
            task_root.mkdir(mode=0o700)
            subprocess.run(
                [
                    "bash",
                    "-c",
                    "set -euo pipefail\nTASK_ROOT=\"$1\"\n" + setup_block,
                    "test-build-release-candidate-dirs",
                    str(task_root),
                ],
                check=True,
            )

            expected_directories = (
                task_root / "logs",
                task_root / "downloads",
                task_root / "custom-engine",
                task_root / "output",
                task_root / "host-tools",
                task_root / "host-tools/bin",
            )
            for directory in expected_directories:
                with self.subTest(directory=directory.relative_to(task_root)):
                    self.assertTrue(directory.is_dir())
                    self.assertEqual(directory.stat().st_mode & 0o777, 0o700)


if __name__ == "__main__":
    unittest.main()
