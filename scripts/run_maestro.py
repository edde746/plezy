#!/usr/bin/env python3
"""Build the Jellyfin fixture and run Plezy's Android Maestro suites."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import os
from pathlib import Path
import shlex
import signal
import shutil
import subprocess
import sys
import time
from typing import Mapping, Optional, Sequence, TextIO
import urllib.error
import urllib.request


ROOT_DIR = Path(__file__).resolve().parent.parent
APP_ID = "com.edde746.plezy"
FAULTS = ("music-failure", "recovery")


class RunnerError(RuntimeError):
    """A user-actionable runner failure."""

class RunnerSignal(Exception):
    def __init__(self, signum: int) -> None:
        super().__init__(f"Interrupted by signal {signum}")
        self.exit_status = 128 + signum


def _raise_signal(signum: int, _frame: object) -> None:
    raise RunnerSignal(signum)




@dataclass(frozen=True)
class SuitePreset:
    flow_target: str
    maestro_config: Optional[str]
    jellyfin_log: str
    diagnostics_dir: str
    use_adb_reverse: bool = False
    uninstall_before_install: bool = False


SUITES = {
    "basic": SuitePreset(
        flow_target=".maestro",
        maestro_config=None,
        jellyfin_log="build/maestro/jellyfin.log",
        diagnostics_dir="build/maestro/diagnostics",
    ),
    "catalog": SuitePreset(
        flow_target=".maestro/real_flows",
        maestro_config=None,
        jellyfin_log="build/maestro-real-jellyfin/jellyfin.log",
        diagnostics_dir="build/maestro-real-jellyfin/diagnostics",
        uninstall_before_install=True,
    ),
    "media": SuitePreset(
        flow_target=".maestro/media_flows",
        maestro_config=".maestro/media-config.yaml",
        jellyfin_log="build/maestro-media/jellyfin.log",
        diagnostics_dir="build/maestro/diagnostics",
        use_adb_reverse=True,
        uninstall_before_install=True,
    ),
}


@dataclass(frozen=True)
class RunnerConfig:
    command: str
    jellyfin_host: str
    jellyfin_port: int
    proxy_port: int
    jellyfin_image: str
    skip_jellyfin: bool
    skip_jellyfin_build: bool
    skip_build: bool
    jellyfin_fault: Optional[str]
    use_adb_reverse: bool
    device_id: Optional[str]
    apk_path: Path
    flow_target: Path
    maestro_config: Optional[Path]
    uninstall_before_install: bool
    diagnostics_dir: Path
    jellyfin_log: Path
    proxy_log: Path
    proxy_journal: Path
    host_jellyfin_url: str
    jellyfin_url: Optional[str]
    jellyfin_build_attempts: int


def _positive_int(value: str) -> int:
    try:
        parsed = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("must be a positive integer") from error
    if parsed < 1:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return parsed


def _add_bool_argument(parser: argparse.ArgumentParser, name: str, *, destination: str) -> None:
    group = parser.add_mutually_exclusive_group()
    group.add_argument(f"--{name}", dest=destination, action="store_true")
    group.add_argument(f"--no-{name}", dest=destination, action="store_false")
    parser.set_defaults(**{destination: None})


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command",
        choices=(*SUITES, "build-image"),
        nargs="?",
        default="basic",
        help="suite to run, or build-image to only build the Jellyfin fixture",
    )
    parser.add_argument("--device", dest="device_id")
    parser.add_argument("--apk", dest="apk_path")
    parser.add_argument("--flow", dest="flow_target")
    parser.add_argument("--config", dest="maestro_config")
    parser.add_argument("--fault", choices=FAULTS, dest="jellyfin_fault")
    parser.add_argument("--jellyfin-host")
    parser.add_argument("--jellyfin-port", type=int)
    parser.add_argument("--proxy-port", type=int)
    parser.add_argument("--jellyfin-image")
    parser.add_argument("--diagnostics-dir")
    parser.add_argument("--jellyfin-log")
    parser.add_argument("--proxy-log")
    parser.add_argument("--proxy-journal")
    parser.add_argument("--host-jellyfin-url")
    parser.add_argument("--jellyfin-url")
    parser.add_argument("--jellyfin-build-attempts", type=_positive_int)
    _add_bool_argument(parser, "skip-jellyfin", destination="skip_jellyfin")
    _add_bool_argument(parser, "skip-jellyfin-build", destination="skip_jellyfin_build")
    _add_bool_argument(parser, "skip-build", destination="skip_build")
    _add_bool_argument(parser, "adb-reverse", destination="use_adb_reverse")
    _add_bool_argument(parser, "uninstall-before-install", destination="uninstall_before_install")
    return parser


def _env_bool(environment: Mapping[str, str], name: str, default: bool) -> bool:
    value = environment.get(name)
    if value is None:
        return default
    normalized = value.strip().lower()
    if normalized in {"1", "true", "yes", "on"}:
        return True
    if normalized in {"0", "false", "no", "off"}:
        return False
    raise RunnerError(f"{name} must be one of 1, 0, true, false, yes, no, on, or off")


def _option(cli_value: object, environment: Mapping[str, str], name: str, default: object) -> object:
    if cli_value is not None:
        return cli_value
    return environment.get(name, default)
def _int_option(
    cli_value: Optional[int],
    environment: Mapping[str, str],
    name: str,
    default: int,
) -> int:
    value = _option(cli_value, environment, name, default)
    try:
        parsed = int(value)
    except (TypeError, ValueError) as error:
        raise RunnerError(f"{name} must be a positive integer") from error
    if parsed < 1:
        raise RunnerError(f"{name} must be a positive integer")
    return parsed




def _bool_option(
    cli_value: Optional[bool],
    environment: Mapping[str, str],
    name: str,
    default: bool,
) -> bool:
    if cli_value is not None:
        return cli_value
    return _env_bool(environment, name, default)


def _root_path(value: object) -> Path:
    path = Path(str(value))
    return path if path.is_absolute() else ROOT_DIR / path


def parse_config(argv: Optional[Sequence[str]] = None, environment: Optional[Mapping[str, str]] = None) -> RunnerConfig:
    args = _parser().parse_args(argv)
    env = os.environ if environment is None else environment
    preset = SUITES.get(args.command, SUITES["basic"])

    jellyfin_host = str(_option(args.jellyfin_host, env, "MAESTRO_JELLYFIN_HOST", "127.0.0.1"))
    jellyfin_port = _int_option(args.jellyfin_port, env, "MAESTRO_JELLYFIN_PORT", 8096)
    proxy_port = _int_option(args.proxy_port, env, "MAESTRO_JELLYFIN_PROXY_PORT", jellyfin_port + 1)
    config_value = _option(args.maestro_config, env, "MAESTRO_CONFIG", preset.maestro_config or "")
    fault_value = _option(args.jellyfin_fault, env, "MAESTRO_JELLYFIN_FAULT", "")
    fault = str(fault_value) or None
    if fault is not None and fault not in FAULTS:
        raise RunnerError(f"Unsupported MAESTRO_JELLYFIN_FAULT: {fault}")

    build_attempts = _int_option(
        args.jellyfin_build_attempts,
        env,
        "MAESTRO_JELLYFIN_BUILD_ATTEMPTS",
        2,
    )

    return RunnerConfig(
        command=args.command,
        jellyfin_host=jellyfin_host,
        jellyfin_port=jellyfin_port,
        proxy_port=proxy_port,
        jellyfin_image=str(
            _option(args.jellyfin_image, env, "MAESTRO_JELLYFIN_IMAGE", "plezy-jellyfin-demo:local")
        ),
        skip_jellyfin=_bool_option(args.skip_jellyfin, env, "MAESTRO_SKIP_JELLYFIN", False),
        skip_jellyfin_build=_bool_option(
            args.skip_jellyfin_build,
            env,
            "MAESTRO_SKIP_JELLYFIN_BUILD",
            False,
        ),
        skip_build=_bool_option(args.skip_build, env, "MAESTRO_SKIP_BUILD", False),
        jellyfin_fault=fault,
        use_adb_reverse=_bool_option(
            args.use_adb_reverse,
            env,
            "MAESTRO_USE_ADB_REVERSE",
            preset.use_adb_reverse,
        ),
        device_id=str(_option(args.device_id, env, "MAESTRO_DEVICE_ID", "")) or None,
        apk_path=_root_path(
            _option(
                args.apk_path,
                env,
                "MAESTRO_APK_PATH",
                "build/app/outputs/flutter-apk/app-debug.apk",
            )
        ),
        flow_target=_root_path(
            _option(args.flow_target, env, "MAESTRO_FLOW_TARGET", preset.flow_target)
        ),
        maestro_config=_root_path(config_value) if config_value else None,
        uninstall_before_install=_bool_option(
            args.uninstall_before_install,
            env,
            "MAESTRO_UNINSTALL_BEFORE_INSTALL",
            preset.uninstall_before_install,
        ),
        diagnostics_dir=_root_path(
            _option(args.diagnostics_dir, env, "MAESTRO_DIAGNOSTICS_DIR", preset.diagnostics_dir)
        ),
        jellyfin_log=_root_path(
            _option(args.jellyfin_log, env, "MAESTRO_JELLYFIN_LOG", preset.jellyfin_log)
        ),
        proxy_log=_root_path(
            _option(
                args.proxy_log,
                env,
                "MAESTRO_JELLYFIN_PROXY_LOG",
                "build/maestro/jellyfin-proxy.log",
            )
        ),
        proxy_journal=_root_path(
            _option(
                args.proxy_journal,
                env,
                "MAESTRO_JELLYFIN_PROXY_JOURNAL",
                "build/maestro/jellyfin-proxy-journal.jsonl",
            )
        ),
        host_jellyfin_url=str(
            _option(
                args.host_jellyfin_url,
                env,
                "MAESTRO_JELLYFIN_HOST_URL",
                f"http://{jellyfin_host}:{jellyfin_port}",
            )
        ),
        jellyfin_url=str(_option(args.jellyfin_url, env, "MAESTRO_JELLYFIN_URL", "")) or None,
        jellyfin_build_attempts=build_attempts,
    )


def _format_command(command: Sequence[object]) -> str:
    values = [str(value) for value in command]
    if os.name == "nt":
        return subprocess.list2cmdline(values)
    return shlex.join(values)


def _run_checked(command: Sequence[object], **kwargs: object) -> subprocess.CompletedProcess[str]:
    values = [str(value) for value in command]
    print(f"+ {_format_command(values)}", flush=True)
    return subprocess.run(values, cwd=ROOT_DIR, check=True, text=True, **kwargs)


def _require_commands(names: Sequence[str]) -> None:
    missing = [name for name in names if shutil.which(name) is None]
    if missing:
        raise RunnerError(f"Required command not found: {', '.join(missing)}")


def build_jellyfin_image(config: RunnerConfig) -> None:
    _require_commands(("docker",))
    command = (
        "docker",
        "build",
        "--file",
        ROOT_DIR / ".maestro/jellyfin-demo/Dockerfile",
        "--tag",
        config.jellyfin_image,
        ROOT_DIR,
    )
    for attempt in range(1, config.jellyfin_build_attempts + 1):
        try:
            _run_checked(command)
            return
        except subprocess.CalledProcessError:
            if attempt == config.jellyfin_build_attempts:
                raise RunnerError(
                    f"Jellyfin image build failed after {config.jellyfin_build_attempts} attempts"
                )
            print(f"Jellyfin image build attempt {attempt} failed; retrying", file=sys.stderr)
            time.sleep(5)


class MaestroRunner:
    def __init__(self, config: RunnerConfig) -> None:
        self.config = config
        self.device_id = config.device_id
        self.container_name: Optional[str] = None
        self.proxy_process: Optional[subprocess.Popen[str]] = None
        self.proxy_output: Optional[TextIO] = None
        self.reverse_configured = False
        self.device_service_port = config.jellyfin_port
        self.host_jellyfin_url = config.host_jellyfin_url
        self.device_settings: dict[tuple[str, str], str] = {}

    @property
    def adb_prefix(self) -> list[str]:
        prefix = ["adb"]
        if self.device_id:
            prefix.extend(("-s", self.device_id))
        return prefix

    def run(self) -> None:
        required = ["adb", "maestro"]
        if not self.config.skip_build:
            required.append("flutter")
        if not self.config.skip_jellyfin:
            required.append("docker")
        _require_commands(required)
        self._select_device()
        self._prepare_output_directories()

        if not self.config.skip_jellyfin:
            if not self.config.skip_jellyfin_build:
                build_jellyfin_image(self.config)
            self._start_jellyfin()
        self._wait_for_health(self.host_jellyfin_url, attempts=120, interval=0.25, service="Jellyfin")

        if self.config.jellyfin_fault:
            self._start_proxy()

        if not self.config.skip_build:
            _run_checked(("flutter", "pub", "get"))
            _run_checked(("flutter", "build", "apk", "--debug"))

        self._prepare_device()
        _run_checked((*self.adb_prefix, "install", "-r", self.config.apk_path))
        _run_checked(self.maestro_command())

    def maestro_command(self) -> list[str]:
        default_url = f"http://10.0.2.2:{self.device_service_port}"
        if self.config.use_adb_reverse:
            default_url = f"http://127.0.0.1:{self.device_service_port}"
        jellyfin_url = self.config.jellyfin_url or default_url
        command = ["maestro", "test", "-e", f"JELLYFIN_URL={jellyfin_url}"]
        if self.device_id:
            command.extend(("--device", self.device_id))
        if self.config.maestro_config:
            command.extend(("--config", str(self.config.maestro_config)))
        command.append(str(self.config.flow_target))
        return command

    def _prepare_output_directories(self) -> None:
        for path in (
            self.config.diagnostics_dir,
            self.config.jellyfin_log.parent,
            self.config.proxy_log.parent,
            self.config.proxy_journal.parent,
        ):
            path.mkdir(parents=True, exist_ok=True)

    def _select_device(self) -> None:
        if not self.config.use_adb_reverse or self.device_id:
            return
        result = subprocess.run(
            ("adb", "devices"),
            cwd=ROOT_DIR,
            check=True,
            capture_output=True,
            text=True,
        )
        devices = []
        for line in result.stdout.splitlines()[1:]:
            fields = line.split()
            if len(fields) >= 2 and fields[1] == "device":
                devices.append(fields[0])
        if len(devices) != 1:
            raise RunnerError("Set --device to the Android device serial when using --adb-reverse")
        self.device_id = devices[0]

    def _start_jellyfin(self) -> None:
        name = f"plezy-maestro-jellyfin-{self.config.jellyfin_port}-{os.getpid()}"
        result = _run_checked(
            (
                "docker",
                "run",
                "--detach",
                "--rm",
                "--name",
                name,
                "--publish",
                f"{self.config.jellyfin_host}:{self.config.jellyfin_port}:8096",
                self.config.jellyfin_image,
            ),
            capture_output=True,
        )
        self.container_name = result.stdout.strip() or name

    def _wait_for_health(self, base_url: str, *, attempts: int, interval: float, service: str) -> None:
        health_url = f"{base_url.rstrip('/')}/health"
        last_error: Optional[Exception] = None
        for _ in range(attempts):
            try:
                with urllib.request.urlopen(health_url, timeout=1) as response:
                    response.read()
                return
            except (OSError, urllib.error.URLError) as error:
                last_error = error
                time.sleep(interval)
        raise RunnerError(f"{service} did not become ready at {base_url}: {last_error}")

    def _start_proxy(self) -> None:
        self.proxy_output = self.config.proxy_log.open("w", encoding="utf-8")
        self.proxy_process = subprocess.Popen(
            (
                sys.executable,
                str(ROOT_DIR / "scripts/maestro_jellyfin_proxy.py"),
                "--host",
                self.config.jellyfin_host,
                "--port",
                str(self.config.proxy_port),
                "--upstream",
                self.host_jellyfin_url,
                "--fault",
                self.config.jellyfin_fault or "",
                "--journal",
                str(self.config.proxy_journal),
            ),
            cwd=ROOT_DIR,
            stdout=self.proxy_output,
            stderr=subprocess.STDOUT,
            text=True,
        )
        proxy_url = f"http://{self.config.jellyfin_host}:{self.config.proxy_port}"
        for _ in range(50):
            if self.proxy_process.poll() is not None:
                raise RunnerError(f"Jellyfin fault proxy exited early; see {self.config.proxy_log}")
            try:
                self._wait_for_health(proxy_url, attempts=1, interval=0, service="Jellyfin fault proxy")
                self.host_jellyfin_url = proxy_url
                self.device_service_port = self.config.proxy_port
                return
            except RunnerError:
                time.sleep(0.1)
        raise RunnerError(f"Jellyfin fault proxy did not become ready; see {self.config.proxy_log}")

    def _adb_run(
        self,
        *arguments: object,
        check: bool = True,
        quiet: bool = False,
        timeout: int = 30,
    ) -> subprocess.CompletedProcess[str]:
        kwargs: dict[str, object] = {}
        if quiet:
            kwargs.update(stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return subprocess.run(
            [*self.adb_prefix, *(str(argument) for argument in arguments)],
            cwd=ROOT_DIR,
            check=check,
            text=True,
            timeout=timeout,
            **kwargs,
        )

    def _adb_capture(self, *arguments: object) -> Optional[str]:
        command = [*self.adb_prefix, *(str(argument) for argument in arguments)]
        try:
            result = subprocess.run(
                command,
                cwd=ROOT_DIR,
                check=False,
                capture_output=True,
                text=True,
                timeout=10,
            )
        except subprocess.TimeoutExpired as error:
            raise RunnerError(f"ADB command timed out: {_format_command(command)}") from error
        return result.stdout.strip() if result.returncode == 0 else None

    def _prepare_device(self) -> None:
        _run_checked((*self.adb_prefix, "wait-for-device"), timeout=60)
        for namespace, key in (
            ("global", "stay_on_while_plugged_in"),
            ("secure", "immersive_mode_confirmations"),
            ("global", "hide_error_dialogs"),
        ):
            value = self._adb_capture("shell", "settings", "get", namespace, key)
            if value is not None:
                self.device_settings[(namespace, key)] = value

        self._adb_run(
            "shell",
            "settings",
            "put",
            "secure",
            "immersive_mode_confirmations",
            "confirmed",
            check=False,
            quiet=True,
        )
        self._adb_run(
            "shell",
            "settings",
            "put",
            "global",
            "hide_error_dialogs",
            "1",
            check=False,
            quiet=True,
        )
        self._adb_run("shell", "input", "keyevent", "KEYCODE_BACK", check=False, quiet=True)
        _run_checked((*self.adb_prefix, "shell", "svc", "power", "stayon", "true"))
        _run_checked((*self.adb_prefix, "shell", "input", "keyevent", "KEYCODE_WAKEUP"))
        _run_checked((*self.adb_prefix, "shell", "wm", "dismiss-keyguard"))

        if self.config.use_adb_reverse:
            _run_checked(
                (
                    *self.adb_prefix,
                    "reverse",
                    f"tcp:{self.device_service_port}",
                    f"tcp:{self.device_service_port}",
                )
            )
            self.reverse_configured = True
        if self.config.uninstall_before_install:
            self._adb_run("uninstall", APP_ID, check=False, quiet=True)

    def collect_failure_diagnostics(self, exit_status: int) -> None:
        try:
            self.config.diagnostics_dir.mkdir(parents=True, exist_ok=True)
            state_path = self.config.diagnostics_dir / "run-state.txt"
            with state_path.open("w", encoding="utf-8") as output:
                output.write(f"exit_status={exit_status}\n")
                output.write(f"jellyfin_host_url={self.host_jellyfin_url}\n")
                output.write(f"jellyfin_container={self.container_name or ''}\n")
                output.write(f"jellyfin_fault={self.config.jellyfin_fault or ''}\n")
                output.write(f"proxy_pid={self.proxy_process.pid if self.proxy_process else ''}\n")
                try:
                    with urllib.request.urlopen(
                        f"{self.host_jellyfin_url.rstrip('/')}/health",
                        timeout=2,
                    ) as response:
                        output.write(response.read().decode(errors="replace"))
                        output.write("\n")
                except Exception as error:  # Diagnostics must not hide the original failure.
                    output.write(f"health_error={error}\n")

            if self.container_name:
                self._write_command_output(
                    ("docker", "logs", self.container_name),
                    self.config.jellyfin_log,
                )
            self._write_command_output(("adb", "devices", "-l"), self.config.diagnostics_dir / "adb-devices.txt")
            for filename, arguments in (
                ("device-properties.txt", ("shell", "getprop")),
                ("device-processes.txt", ("shell", "ps", "-A")),
                ("device-activities.txt", ("shell", "dumpsys", "activity", "activities")),
                ("device-windows.txt", ("shell", "dumpsys", "window", "windows")),
                ("device-logcat.txt", ("logcat", "-d", "-v", "threadtime")),
            ):
                self._write_command_output(
                    (*self.adb_prefix, *arguments),
                    self.config.diagnostics_dir / filename,
                )
            if os.name == "nt" and shutil.which("tasklist"):
                self._write_command_output(("tasklist",), self.config.diagnostics_dir / "host-processes.txt")
            elif shutil.which("ps"):
                self._write_command_output(("ps", "-ef"), self.config.diagnostics_dir / "host-processes.txt")
            if shutil.which("lsof"):
                self._write_command_output(
                    ("lsof", "-nP", f"-iTCP:{self.device_service_port}"),
                    self.config.diagnostics_dir / "jellyfin-listeners.txt",
                )
        except Exception as error:  # Diagnostics are best effort.
            print(f"Failed to collect Maestro diagnostics: {error}", file=sys.stderr)

    def _write_command_output(self, command: Sequence[object], path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as output:
            subprocess.run(
                [str(value) for value in command],
                cwd=ROOT_DIR,
                check=False,
                stdout=output,
                stderr=subprocess.STDOUT,
                text=True,
                timeout=15,
            )

    def _adb_best_effort(self, *arguments: object) -> None:
        try:
            self._adb_run(*arguments, check=False, quiet=True, timeout=5)
        except (OSError, subprocess.SubprocessError):
            pass

    def cleanup(self) -> None:
        for (namespace, key), value in self.device_settings.items():
            operation = "delete" if value == "null" else "put"
            arguments = ["shell", "settings", operation, namespace, key]
            if operation == "put":
                arguments.append(value)
            self._adb_best_effort(*arguments)

        if self.reverse_configured:
            self._adb_best_effort(
                "reverse",
                "--remove",
                f"tcp:{self.device_service_port}",
            )
        try:
            if self.proxy_process:
                self.proxy_process.terminate()
                try:
                    self.proxy_process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    self.proxy_process.kill()
                    self.proxy_process.wait()
        finally:
            if self.proxy_output:
                self.proxy_output.close()

        if self.container_name:
            try:
                self._write_command_output(
                    ("docker", "logs", self.container_name),
                    self.config.jellyfin_log,
                )
            except (OSError, subprocess.SubprocessError):
                pass
            try:
                subprocess.run(
                    ("docker", "stop", "--time", "15", self.container_name),
                    cwd=ROOT_DIR,
                    check=False,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    text=True,
                    timeout=30,
                )
            except (OSError, subprocess.SubprocessError):
                pass


def run(config: RunnerConfig) -> int:
    if config.command == "build-image":
        build_jellyfin_image(config)
        return 0

    runner = MaestroRunner(config)
    exit_status = 0
    try:
        runner.run()
    except KeyboardInterrupt:
        exit_status = 130
        print("Maestro run interrupted", file=sys.stderr)
    except RunnerSignal as error:
        exit_status = error.exit_status
        print(str(error), file=sys.stderr)
    except subprocess.CalledProcessError as error:
        exit_status = error.returncode or 1
        print(f"Command failed ({exit_status}): {_format_command(error.cmd)}", file=sys.stderr)
    except (OSError, RunnerError) as error:
        exit_status = 1
        print(error, file=sys.stderr)
    finally:
        if exit_status:
            runner.collect_failure_diagnostics(exit_status)
        runner.cleanup()
    return exit_status


def main(argv: Optional[Sequence[str]] = None) -> int:
    signal.signal(signal.SIGINT, _raise_signal)
    signal.signal(signal.SIGTERM, _raise_signal)
    try:
        config = parse_config(argv)
        return run(config)
    except RunnerSignal as error:
        return error.exit_status
    except KeyboardInterrupt:
        return 130
    except (OSError, RunnerError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
