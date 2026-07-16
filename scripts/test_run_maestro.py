#!/usr/bin/env python3

from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
from dataclasses import replace
import io
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import run_maestro  # noqa: E402
import run_maestro_ci  # noqa: E402


class ParseConfigTests(unittest.TestCase):
    def test_basic_defaults(self) -> None:
        config = run_maestro.parse_config([], {})

        self.assertEqual(config.command, "basic")
        self.assertEqual(config.flow_target, run_maestro.ROOT_DIR / ".maestro")
        self.assertIsNone(config.maestro_config)
        self.assertFalse(config.use_adb_reverse)
        self.assertFalse(config.uninstall_before_install)

    def test_suite_presets_replace_shell_wrappers(self) -> None:
        catalog = run_maestro.parse_config(["catalog"], {})
        media = run_maestro.parse_config(["media"], {})

        self.assertEqual(catalog.flow_target, run_maestro.ROOT_DIR / ".maestro/real_flows")
        self.assertEqual(
            catalog.diagnostics_dir,
            run_maestro.ROOT_DIR / "build/maestro-real-jellyfin/diagnostics",
        )
        self.assertTrue(catalog.uninstall_before_install)
        self.assertEqual(media.flow_target, run_maestro.ROOT_DIR / ".maestro/media_flows")
        self.assertEqual(media.maestro_config, run_maestro.ROOT_DIR / ".maestro/media-config.yaml")
        self.assertTrue(media.use_adb_reverse)
        self.assertTrue(media.uninstall_before_install)

    def test_cli_options_override_compatible_environment_values(self) -> None:
        config = run_maestro.parse_config(
            [
                "media",
                "--no-adb-reverse",
                "--flow",
                "custom/flow.yaml",
                "--device",
                "cli-device",
            ],
            {
                "MAESTRO_USE_ADB_REVERSE": "1",
                "MAESTRO_FLOW_TARGET": "environment/flow.yaml",
                "MAESTRO_DEVICE_ID": "environment-device",
                "MAESTRO_SKIP_BUILD": "true",
            },
        )

        self.assertFalse(config.use_adb_reverse)
        self.assertEqual(config.flow_target, run_maestro.ROOT_DIR / "custom/flow.yaml")
        self.assertEqual(config.device_id, "cli-device")
        self.assertTrue(config.skip_build)

    def test_invalid_environment_values_fail_early(self) -> None:
        with self.assertRaisesRegex(run_maestro.RunnerError, "MAESTRO_SKIP_BUILD"):
            run_maestro.parse_config([], {"MAESTRO_SKIP_BUILD": "sometimes"})
        with self.assertRaisesRegex(run_maestro.RunnerError, "MAESTRO_JELLYFIN_PORT"):
            run_maestro.parse_config([], {"MAESTRO_JELLYFIN_PORT": "invalid"})
        with self.assertRaisesRegex(run_maestro.RunnerError, "MAESTRO_JELLYFIN_BUILD_ATTEMPTS"):
            run_maestro.parse_config([], {"MAESTRO_JELLYFIN_BUILD_ATTEMPTS": "0"})


class CommandTests(unittest.TestCase):
    def test_media_command_contains_resolved_preset_and_device_url(self) -> None:
        config = run_maestro.parse_config(["media", "--device", "emulator-5554"], {})
        command = run_maestro.MaestroRunner(config).maestro_command()

        self.assertEqual(
            command,
            [
                "maestro",
                "test",
                "-e",
                "JELLYFIN_URL=http://127.0.0.1:8096",
                "--device",
                "emulator-5554",
                "--config",
                str(run_maestro.ROOT_DIR / ".maestro/media-config.yaml"),
                str(run_maestro.ROOT_DIR / ".maestro/media_flows"),
            ],
        )

    def test_explicit_device_url_wins_over_network_mode(self) -> None:
        config = run_maestro.parse_config(
            ["basic", "--adb-reverse", "--jellyfin-url", "http://device.test:9000"],
            {},
        )

        command = run_maestro.MaestroRunner(config).maestro_command()

        self.assertIn("JELLYFIN_URL=http://device.test:9000", command)


class LifecycleTests(unittest.TestCase):
    def test_runner_failure_collects_diagnostics_and_cleans_up(self) -> None:
        config = run_maestro.parse_config([], {})
        with patch.object(run_maestro, "MaestroRunner") as runner_type:
            runner = runner_type.return_value
            runner.run.side_effect = run_maestro.RunnerError("failed")
            with redirect_stderr(io.StringIO()):
                exit_status = run_maestro.run(config)

        self.assertEqual(exit_status, 1)
        runner.collect_failure_diagnostics.assert_called_once_with(1)
        runner.cleanup.assert_called_once_with()

    def test_image_build_retries_once(self) -> None:
        config = replace(run_maestro.parse_config(["build-image"], {}), jellyfin_build_attempts=2)
        failure = subprocess.CalledProcessError(1, ["docker", "build"])
        success = subprocess.CompletedProcess(["docker", "build"], 0)

        with (
            patch.object(run_maestro, "_require_commands"),
            patch.object(run_maestro, "_run_checked", side_effect=[failure, success]) as run_command,
            patch.object(run_maestro.time, "sleep") as sleep,
            redirect_stderr(io.StringIO()),
        ):
            run_maestro.build_jellyfin_image(config)

        self.assertEqual(run_command.call_count, 2)
        sleep.assert_called_once_with(5)


class CiGroupTests(unittest.TestCase):
    def test_android_15_group_runs_every_suite_after_failure(self) -> None:
        expected_runs = len(run_maestro_ci.GROUPS["android-15"])
        statuses = [0, 1, *([0] * (expected_runs - 2))]

        with (
            patch.object(run_maestro_ci.run_maestro, "main", side_effect=statuses) as run,
            redirect_stdout(io.StringIO()),
        ):
            exit_status = run_maestro_ci.run_group("android-15")

        self.assertEqual(exit_status, 1)
        self.assertEqual(run.call_count, expected_runs)

    def test_group_recipes_are_valid_runner_invocations(self) -> None:
        for recipes in run_maestro_ci.GROUPS.values():
            for arguments in recipes:
                with self.subTest(arguments=arguments):
                    run_maestro.parse_config(arguments, {})

    def test_group_stops_after_interruption(self) -> None:
        with (
            patch.object(run_maestro_ci.run_maestro, "main", return_value=143) as run,
            redirect_stdout(io.StringIO()),
        ):
            exit_status = run_maestro_ci.run_group("android-15")

        self.assertEqual(exit_status, 143)
        run.assert_called_once_with(("basic",))


if __name__ == "__main__":
    unittest.main()
