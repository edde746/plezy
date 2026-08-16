#!/usr/bin/env python3
"""Remux local codec fixtures into long-running copies for interactive E2E flows."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import shutil
import subprocess
import sys

from maestro_fixtures import MEDIA_FIXTURE_SPECS


def _duration(path: Path) -> float:
    result = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "json",
            str(path),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    payload = json.loads(result.stdout)
    try:
        duration = float(payload["format"]["duration"])
    except (KeyError, TypeError, ValueError) as error:
        raise ValueError(f"ffprobe returned no duration for {path}") from error
    if duration <= 0:
        raise ValueError(f"media duration must be positive: {path}")
    return duration


def prepare_media(
    source_directory: Path,
    output_directory: Path,
    *,
    duration: float,
    extend_filenames: frozenset[str] | None = None,
) -> None:
    if duration <= 0:
        raise ValueError("target duration must be positive")
    if shutil.which("ffmpeg") is None or shutil.which("ffprobe") is None:
        raise RuntimeError("ffmpeg and ffprobe are required for the local codec suite")

    source_directory = source_directory.expanduser().resolve()
    output_directory = output_directory.expanduser().resolve()
    output_directory.mkdir(parents=True, exist_ok=True)

    for spec in MEDIA_FIXTURE_SPECS:
        source = source_directory / spec.filename
        if not source.is_file():
            raise FileNotFoundError(f"missing codec fixture: {source}")
        output = output_directory / spec.filename
        if extend_filenames is not None and spec.filename not in extend_filenames:
            shutil.copy2(source, output)
            continue
        if output.is_file() and output.stat().st_mtime_ns >= source.stat().st_mtime_ns:
            try:
                if _duration(output) >= duration:
                    print(f"Reusing {output.name}")
                    continue
            except (subprocess.CalledProcessError, ValueError):
                pass

        source_duration = _duration(source)
        remux_duration = duration + 5
        repeat_count = max(0, math.ceil(remux_duration / source_duration) - 1)
        temporary = output.with_name(f"{output.stem}.tmp{output.suffix}")
        temporary.unlink(missing_ok=True)
        print(f"Preparing {output.name} ({source_duration:.1f}s -> {duration:.1f}s)")
        try:
            subprocess.run(
                [
                    "ffmpeg",
                    "-y",
                    "-v",
                    "error",
                    "-stream_loop",
                    str(repeat_count),
                    "-i",
                    str(source),
                    "-map",
                    "0",
                    "-c",
                    "copy",
                    "-t",
                    str(remux_duration),
                    str(temporary),
                ],
                check=True,
            )
            if _duration(temporary) < duration:
                raise ValueError(f"prepared fixture is shorter than {duration}s: {temporary}")
            temporary.replace(output)
        finally:
            temporary.unlink(missing_ok=True)


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Directory containing the six untracked codec fixtures")
    parser.add_argument("output", type=Path, help="Directory for derived long-running fixtures")
    parser.add_argument("--duration", type=float, default=300, help="Minimum output duration in seconds")
    parser.add_argument(
        "--extend",
        action="append",
        choices=[spec.filename for spec in MEDIA_FIXTURE_SPECS],
        dest="extend_filenames",
        help="Only extend this fixture; may be repeated. By default every fixture is extended.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(sys.argv[1:] if argv is None else argv)
    try:
        extend_filenames = frozenset(args.extend_filenames) if args.extend_filenames is not None else None
        prepare_media(
            args.source,
            args.output,
            duration=args.duration,
            extend_filenames=extend_filenames,
        )
    except (FileNotFoundError, RuntimeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Codec fixture preparation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
