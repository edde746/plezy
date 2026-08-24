#!/usr/bin/env python3

from __future__ import annotations

import ast
from contextlib import redirect_stderr, redirect_stdout
from dataclasses import replace
import io
from pathlib import Path
import re
import shlex
import subprocess
import sys
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import run_maestro  # noqa: E402
import run_maestro_ci  # noqa: E402


ROOT_DIR = Path(__file__).resolve().parents[2]
SCRIPTS_DIR = ROOT_DIR / "scripts"
LOCAL_SCRIPT_TEST_DISPATCHER = SCRIPTS_DIR / "ci_checks.sh"
CI_SCRIPT_TEST_DISPATCHER = ROOT_DIR / ".github/workflows/ci.yml"
# The guard roster both dispatchers above delegate to. It discovers the script
# tests by glob, so a new test_*.py under scripts/ or scripts/*/ is picked up
# without being listed.
GUARD_SCRIPT_TEST_DISPATCHER = SCRIPTS_DIR / "ci_guard_checks.sh"
SCRIPT_TEST_DISPATCHERS = (
    LOCAL_SCRIPT_TEST_DISPATCHER,
    CI_SCRIPT_TEST_DISPATCHER,
    GUARD_SCRIPT_TEST_DISPATCHER,
    SCRIPTS_DIR / "ci_website_checks.sh",
)
REGRESSION_FLOWS_DIR = ROOT_DIR / ".maestro/regression_flows"


def _is_main_guard(expression: ast.expr) -> bool:
    if (
        not isinstance(expression, ast.Compare)
        or len(expression.ops) != 1
        or not isinstance(expression.ops[0], ast.Eq)
        or len(expression.comparators) != 1
    ):
        return False
    left = expression.left
    right = expression.comparators[0]
    return (
        isinstance(left, ast.Name)
        and left.id == "__name__"
        and isinstance(right, ast.Constant)
        and right.value == "__main__"
    ) or (
        isinstance(right, ast.Name)
        and right.id == "__name__"
        and isinstance(left, ast.Constant)
        and left.value == "__main__"
    )


def _executable_script_tests() -> set[str]:
    executable = set()
    for path in (*SCRIPTS_DIR.glob("test_*.py"), *SCRIPTS_DIR.glob("*/test_*.py")):
        module = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        if any(isinstance(node, ast.If) and _is_main_guard(node.test) for node in module.body):
            executable.add(path.name)
    return executable


def _dispatched_script_tests(path: Path) -> list[str]:
    dispatched = []
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        # `for guard_test in scripts/test_*.py scripts/*/test_*.py; do` dispatches the whole roster.
        loop = re.match(r"for\s+\w+\s+in\s+(scripts/test_\*\.py scripts/\*/test_\*\.py)\s*;?\s*(?:do)?$", stripped)
        if loop:
            for pattern in loop.group(1).split():
                dispatched.extend(sorted(match.name for match in ROOT_DIR.glob(pattern)))
            continue
        try:
            command = shlex.split(stripped, comments=True)
        except ValueError:
            continue
        if len(command) < 2 or Path(command[0]).name not in {"python", "python3"}:
            continue
        script_name = Path(command[1]).name
        if script_name.startswith("test_") and script_name.endswith(".py"):
            dispatched.append(script_name)
    return dispatched


def _registered_regression_flows(
    targets: dict[str, tuple[tuple[str, ...], ...]],
) -> set[str]:
    registered = set()
    for recipes in targets.values():
        for arguments in recipes:
            flow_target = run_maestro.parse_config(arguments, {}).flow_target
            if flow_target.parent == REGRESSION_FLOWS_DIR:
                registered.add(flow_target.relative_to(ROOT_DIR).as_posix())
    return registered


class ScriptTestDispatchTests(unittest.TestCase):
    def test_every_executable_script_test_has_a_dispatcher(self) -> None:
        dispatched = {
            script
            for dispatcher in SCRIPT_TEST_DISPATCHERS
            for script in _dispatched_script_tests(dispatcher)
        }

        self.assertSetEqual(dispatched, _executable_script_tests())

    def test_real_jellyfin_fixture_test_is_in_local_and_ci_guards(self) -> None:
        # Both aggregates reach the roster through the shared guard script, so
        # the fixture test is covered exactly when the glob picks it up.
        for dispatcher in (LOCAL_SCRIPT_TEST_DISPATCHER, CI_SCRIPT_TEST_DISPATCHER):
            with self.subTest(dispatcher=dispatcher):
                self.assertIn(
                    f"bash {GUARD_SCRIPT_TEST_DISPATCHER.relative_to(ROOT_DIR).as_posix()}",
                    dispatcher.read_text(encoding="utf-8"),
                )

        self.assertEqual(
            _dispatched_script_tests(GUARD_SCRIPT_TEST_DISPATCHER).count("test_maestro_real_jellyfin.py"),
            1,
        )


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

    def test_offline_fault_exposes_host_proxy_control_url(self) -> None:
        config = run_maestro.parse_config(["basic", "--fault", "offline", "--adb-reverse"], {})
        runner = run_maestro.MaestroRunner(config)
        runner.host_jellyfin_url = "http://127.0.0.1:8097"
        runner.device_service_port = 8097

        command = runner.maestro_command()

        self.assertIn("JELLYFIN_URL=http://127.0.0.1:8097", command)
        self.assertIn("JELLYFIN_CONTROL_URL=http://127.0.0.1:8097", command)

    def test_flutter_build_enables_stable_physical_device_controls(self) -> None:
        self.assertEqual(
            run_maestro.flutter_build_command(),
            (
                "flutter",
                "build",
                "apk",
                "--debug",
                "--dart-define=PLEZY_MAESTRO_E2E=true",
            ),
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

    def test_health_wait_rejects_degraded_until_healthy(self) -> None:
        runner = run_maestro.MaestroRunner(run_maestro.parse_config([], {}))
        degraded = MagicMock()
        degraded.__enter__.return_value.read.return_value = b"Degraded"
        healthy = MagicMock()
        healthy.__enter__.return_value.read.return_value = b" Healthy\n"

        with (
            patch.object(run_maestro.urllib.request, "urlopen", side_effect=[degraded, healthy]),
            patch.object(run_maestro.time, "sleep") as sleep,
        ):
            runner._wait_for_health("http://jellyfin.test", attempts=2, interval=0.25, service="Jellyfin")

        sleep.assert_called_once_with(0.25)


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

    def test_android_15_instrumentation_has_an_isolated_target(self) -> None:
        with (
            patch.object(run_maestro_ci, "run_android_15_instrumentation") as instrumentation,
            redirect_stdout(io.StringIO()),
        ):
            exit_status = run_maestro_ci.run_target(run_maestro_ci.ANDROID_15_INSTRUMENTATION_TARGET)

        self.assertEqual(exit_status, 0)
        instrumentation.assert_called_once_with()

    def test_all_automatic_and_manual_recipes_are_valid_runner_invocations(
        self,
    ) -> None:
        target_sets = (
            ("automatic", run_maestro_ci.GROUPS),
            ("destructive-manual", run_maestro_ci.DESTRUCTIVE_MANUAL_TARGETS),
        )
        for classification, targets in target_sets:
            for target, recipes in targets.items():
                for arguments in recipes:
                    with self.subTest(
                        classification=classification,
                        target=target,
                        arguments=arguments,
                    ):
                        run_maestro.parse_config(arguments, {})

    def test_top_level_regression_flow_inventory_is_complete(self) -> None:
        inventory = {
            path.relative_to(ROOT_DIR).as_posix()
            for path in REGRESSION_FLOWS_DIR.glob("*.yaml")
        }
        automatic = _registered_regression_flows(run_maestro_ci.GROUPS)
        destructive_manual = _registered_regression_flows(
            run_maestro_ci.DESTRUCTIVE_MANUAL_TARGETS
        )

        self.assertFalse(automatic & destructive_manual)
        self.assertSetEqual(automatic | destructive_manual, inventory)

    def test_profile_regressions_are_only_in_the_destructive_manual_target(self) -> None:
        profile_flows = {
            ".maestro/regression_flows/01_profile_switch_isolation.yaml",
            ".maestro/regression_flows/02_profile_teardown.yaml",
        }
        manual_profile_flows = _registered_regression_flows(
            {
                "profile-regressions": run_maestro_ci.DESTRUCTIVE_MANUAL_TARGETS[
                    "profile-regressions"
                ]
            }
        )

        self.assertSetEqual(manual_profile_flows, profile_flows)
        self.assertTrue(
            profile_flows.isdisjoint(
                _registered_regression_flows(run_maestro_ci.GROUPS)
            )
        )

    def test_destructive_manual_recipes_have_distinct_diagnostics(self) -> None:
        for target, recipes in run_maestro_ci.DESTRUCTIVE_MANUAL_TARGETS.items():
            with self.subTest(target=target):
                configs = [
                    run_maestro.parse_config(arguments, {}) for arguments in recipes
                ]
                self.assertEqual(
                    len({config.jellyfin_log for config in configs}), len(configs)
                )
                self.assertEqual(
                    len({config.diagnostics_dir for config in configs}), len(configs)
                )

    def test_destructive_manual_target_requires_disposable_emulator_opt_in(
        self,
    ) -> None:
        with (
            patch.object(run_maestro_ci.run_maestro, "main") as run,
            redirect_stderr(io.StringIO()) as error_output,
        ):
            exit_status = run_maestro_ci.main(["profile-regressions"])

        self.assertEqual(exit_status, 2)
        run.assert_not_called()
        self.assertIn("Refusing destructive manual target", error_output.getvalue())
        self.assertIn("--disposable-emulator", error_output.getvalue())

    def test_destructive_manual_target_runs_after_explicit_opt_in(self) -> None:
        recipes = run_maestro_ci.DESTRUCTIVE_MANUAL_TARGETS["profile-regressions"]
        with (
            patch.object(run_maestro_ci.run_maestro, "main", return_value=0) as run,
            redirect_stdout(io.StringIO()),
        ):
            exit_status = run_maestro_ci.main(
                ["profile-regressions", "--disposable-emulator"]
            )

        self.assertEqual(exit_status, 0)
        self.assertEqual(
            [invocation.args[0] for invocation in run.call_args_list], list(recipes)
        )

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
