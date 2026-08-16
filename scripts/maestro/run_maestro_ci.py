#!/usr/bin/env python3
"""Run automatic Maestro groups and guarded destructive manual targets."""

from __future__ import annotations

import argparse
import sys
from collections.abc import Sequence

import run_maestro


ANDROID_15_INSTRUMENTATION_CLASSES = (
    "androidx.media3.decoder.ffmpeg.PlezyFfmpegPlaybackTest,"
    "com.edde746.plezy.exoplayer.PlezyAudioModePlaybackTest"
)
ANDROID_15_INSTRUMENTATION_TARGET = "android-15-instrumentation"
# Separate R8 reachability from instrumentation: these suites exercise APIs the app
# does not call directly, so shrinking them is expected. Covers name-based reachability (#1703).
ANDROID_R8_REACHABILITY_CLASSES = "androidx.media3.decoder.ffmpeg.FfmpegDecoderReachabilityTest"
ANDROID_R8_REACHABILITY_TARGET = "android-r8-reachability"


GROUPS: dict[str, tuple[tuple[str, ...], ...]] = {
    "android-15": (
        ("basic",),
        ("catalog",),
        ("media",),
        (
            "basic",
            "--flow",
            ".maestro/regression_flows/03_tv_library_focus.yaml",
            "--jellyfin-log",
            "build/maestro-tv/library-focus.log",
            "--diagnostics-dir",
            "build/maestro-tv/library-focus-diagnostics",
        ),
        (
            "basic",
            "--flow",
            ".maestro/regression_flows/04_tv_player_keys.yaml",
            "--jellyfin-log",
            "build/maestro-tv/player-keys.log",
            "--diagnostics-dir",
            "build/maestro-tv/player-keys-diagnostics",
        ),
        (
            "basic",
            "--flow",
            ".maestro/regression_flows/05_tv_next_episode_back.yaml",
            "--jellyfin-log",
            "build/maestro-tv/next-episode.log",
            "--diagnostics-dir",
            "build/maestro-tv/next-episode-diagnostics",
        ),
        (
            "basic",
            "--flow",
            ".maestro/regression_flows/07_sheet_back_dismiss.yaml",
            "--jellyfin-log",
            "build/maestro-sheets/back-dismiss.log",
            "--diagnostics-dir",
            "build/maestro-sheets/back-dismiss-diagnostics",
        ),
        (
            "basic",
            "--flow",
            ".maestro/regression_flows/08_track_choice_survives_pending_pass.yaml",
            "--jellyfin-log",
            "build/maestro-tracks/pending-pass.log",
            "--diagnostics-dir",
            "build/maestro-tracks/pending-pass-diagnostics",
        ),
        (
            "basic",
            "--flow",
            ".maestro/regression_flows/09_language_picker_locales.yaml",
            "--jellyfin-log",
            "build/maestro-i18n/language-picker.log",
            "--diagnostics-dir",
            "build/maestro-i18n/language-picker-diagnostics",
        ),
        (
            "basic",
            "--fault",
            "music-failure",
            "--flow",
            ".maestro/real_flows/02_music_browse.yaml",
            "--jellyfin-log",
            "build/maestro-recovery/music-jellyfin.log",
            "--proxy-journal",
            "build/maestro-recovery/music-proxy-journal.jsonl",
            "--diagnostics-dir",
            "build/maestro-recovery/music-diagnostics",
        ),
        (
            "basic",
            "--fault",
            "offline",
            "--flow",
            ".maestro/flows/09_download_offline_playback.yaml",
            "--jellyfin-log",
            "build/maestro-offline/jellyfin.log",
            "--proxy-log",
            "build/maestro-offline/jellyfin-proxy.log",
            "--proxy-journal",
            "build/maestro-offline/proxy-journal.jsonl",
            "--diagnostics-dir",
            "build/maestro-offline/diagnostics",
        ),
        (
            "basic",
            "--fault",
            "recovery",
            "--flow",
            ".maestro/regression_flows/06_playback_recovery.yaml",
            "--jellyfin-log",
            "build/maestro-recovery/jellyfin.log",
            "--proxy-journal",
            "build/maestro-recovery/proxy-journal.jsonl",
            "--diagnostics-dir",
            "build/maestro-recovery/diagnostics",
        ),
    ),
    "android-9": (
        (
            "basic",
            # API 28 uses adb reverse because 10.0.2.2 routing is unreliable here.
            "--adb-reverse",
            "--flow",
            ".maestro/flows/05_playback.yaml",
            "--jellyfin-log",
            "build/maestro-legacy/jellyfin.log",
            "--diagnostics-dir",
            "build/maestro-legacy/diagnostics",
        ),
    ),
    # Manual Android TV hardware target; workflow runs phone-emulator TV regressions.
    "android-tv-device": (
        (
            "basic",
            "--adb-reverse",
            "--flow",
            ".maestro/regression_flows/10_tv_settings_navigation.yaml",
            "--jellyfin-log",
            "build/maestro-tv-device/settings-navigation.log",
            "--diagnostics-dir",
            "build/maestro-tv-device/settings-navigation-diagnostics",
        ),
    ),
}


DESTRUCTIVE_MANUAL_TARGETS: dict[str, tuple[tuple[str, ...], ...]] = {
    "profile-regressions": (
        (
            "basic",
            "--flow",
            ".maestro/regression_flows/01_profile_switch_isolation.yaml",
            "--jellyfin-log",
            "build/maestro-profile-regressions/profile-switch-isolation-jellyfin.log",
            "--diagnostics-dir",
            "build/maestro-profile-regressions/profile-switch-isolation-diagnostics",
        ),
        (
            "basic",
            "--flow",
            ".maestro/regression_flows/02_profile_teardown.yaml",
            "--jellyfin-log",
            "build/maestro-profile-regressions/profile-teardown-jellyfin.log",
            "--diagnostics-dir",
            "build/maestro-profile-regressions/profile-teardown-diagnostics",
        ),
    ),
}


def run_android_15_instrumentation() -> None:
    print("==> Android 15 filtered instrumentation", flush=True)
    run_maestro._run_checked(
        (
            "android/gradlew",
            "-p",
            "android",
            ":app:connectedDebugAndroidTest",
            "-x",
            ":app:compileFlutterBuildDebug",
            f"-Pandroid.testInstrumentationRunnerArguments.class={ANDROID_15_INSTRUMENTATION_CLASSES}",
        )
    )


def run_android_r8_reachability() -> None:
    print("==> Android R8 reachability", flush=True)
    # Run minified instrumentation to catch reflective, JNI, and native-load keep
    # regressions. Do not exclude the Flutter build; CI only prebuilds debug.
    run_maestro._run_checked(
        (
            "android/gradlew",
            "-p",
            "android",
            ":app:connectedMinifiedAndroidTest",
            "-Pplezy.testBuildType=minified",
            f"-Pandroid.testInstrumentationRunnerArguments.class={ANDROID_R8_REACHABILITY_CLASSES}",
        )
    )


def run_recipes(recipes: tuple[tuple[str, ...], ...]) -> int:
    failed = False
    for arguments in recipes:
        print(f"==> Maestro {' '.join(arguments)}", flush=True)
        exit_status = run_maestro.main(arguments)
        if exit_status >= 128:
            return exit_status
        failed = failed or exit_status != 0
    return 1 if failed else 0


def run_group(name: str) -> int:
    return run_recipes(GROUPS[name])


def run_target(name: str, *, disposable_emulator: bool = False) -> int:
    if name in DESTRUCTIVE_MANUAL_TARGETS:
        if not disposable_emulator:
            print(
                f"Refusing destructive manual target {name!r}: "
                "re-run with --disposable-emulator only on a disposable emulator.",
                file=sys.stderr,
            )
            return 2
        print(f"==> DESTRUCTIVE manual Maestro target: {name}", flush=True)
        return run_recipes(DESTRUCTIVE_MANUAL_TARGETS[name])
    if name == ANDROID_15_INSTRUMENTATION_TARGET:
        run_android_15_instrumentation()
        return 0
    if name == ANDROID_R8_REACHABILITY_TARGET:
        run_android_r8_reachability()
        return 0
    return run_group(name)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "target",
        choices=(
            *GROUPS,
            ANDROID_15_INSTRUMENTATION_TARGET,
            ANDROID_R8_REACHABILITY_TARGET,
            *DESTRUCTIVE_MANUAL_TARGETS,
        ),
    )
    parser.add_argument(
        "--disposable-emulator",
        action="store_true",
        help="opt in to a destructive manual target on a disposable emulator",
    )
    args = parser.parse_args(argv)
    return run_target(args.target, disposable_emulator=args.disposable_emulator)


if __name__ == "__main__":
    raise SystemExit(main())
