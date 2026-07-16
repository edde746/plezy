#!/usr/bin/env python3
"""Run the Maestro groups assigned to each CI emulator."""

from __future__ import annotations

import argparse
from collections.abc import Sequence

import run_maestro


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
            "--flow",
            ".maestro/flows/05_playback.yaml",
            "--jellyfin-log",
            "build/maestro-legacy/jellyfin.log",
            "--diagnostics-dir",
            "build/maestro-legacy/diagnostics",
        ),
    ),
}


def run_group(name: str) -> int:
    failed = False
    for arguments in GROUPS[name]:
        print(f"==> Maestro {' '.join(arguments)}", flush=True)
        exit_status = run_maestro.main(arguments)
        if exit_status >= 128:
            return exit_status
        failed = failed or exit_status != 0
    return 1 if failed else 0


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("group", choices=GROUPS)
    args = parser.parse_args(argv)
    return run_group(args.group)


if __name__ == "__main__":
    raise SystemExit(main())
