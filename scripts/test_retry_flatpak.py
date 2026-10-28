import io
import subprocess
import unittest
from unittest.mock import Mock

from retry_flatpak import run_with_retries


class RetryFlatpakTests(unittest.TestCase):
    def test_retries_transient_failure_and_succeeds(self):
        run = Mock(
            side_effect=[
                subprocess.CompletedProcess([], 56),
                subprocess.CompletedProcess([], 0),
            ]
        )
        sleep = Mock()
        errors = io.StringIO()

        result = run_with_retries(
            "install", ["--user", "flathub", "org.freedesktop.Platform//25.08"],
            run=run, sleep=sleep, stderr=errors,
        )

        self.assertEqual(result, 0)
        self.assertEqual(run.call_count, 2)
        sleep.assert_called_once_with(15)
        self.assertIn("retry 2/3", errors.getvalue())

    def test_returns_final_failure_after_three_attempts(self):
        run = Mock(
            side_effect=[
                subprocess.CompletedProcess([], 56),
                subprocess.CompletedProcess([], 56),
                subprocess.CompletedProcess([], 56),
            ]
        )
        sleep = Mock()

        result = run_with_retries("remote-add", ["--if-not-exists", "flathub"], run=run, sleep=sleep)

        self.assertEqual(result, 56)
        self.assertEqual(run.call_count, 3)
        self.assertEqual([call.args[0] for call in sleep.call_args_list], [15, 30])

    def test_rejects_other_flatpak_operations(self):
        with self.assertRaisesRegex(ValueError, "unsupported Flatpak operation"):
            run_with_retries("uninstall", ["org.example.App"], run=Mock(), sleep=Mock())


if __name__ == "__main__":
    unittest.main()
