#!/usr/bin/env python3
"""Inspect local DV media and run bounded, opt-in standalone gpu-next trials.

This is a research tool. A stream tag, successful process exit, or available
renderer is never treated as proof of FEL reconstruction or DV HDMI output.
"""

from __future__ import annotations

import argparse
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from typing import Any


MAX_REPORT_BYTES = 8 * 1024 * 1024
CONFIG_TYPE = "dovi configuration record"
CONFIG_FIELDS = (
    "dv_version_major", "dv_version_minor", "dv_profile", "dv_level",
    "rpu_present_flag", "el_present_flag", "bl_present_flag",
    "dv_bl_signal_compatibility_id", "dv_md_compression",
)


def integer(value: Any) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, str) and value.isascii() and value.isdecimal():
        return int(value) if len(value) <= 10 else None
    return None


def base_layer(profile: int | None, compatibility: int | None) -> str:
    # Compatibility is profile-dependent. In particular P5 is never HDR10,
    # and a P7 configuration alone cannot distinguish MEL from FEL.
    allowed = {
        5: {0: "none"},
        7: {6: "hdr10"},
        8: {1: "hdr10", 2: "sdr", 4: "hlg"},
        9: {2: "sdr"},
        10: {0: "none", 1: "hdr10", 4: "hlg"},
        20: {0: "none", 4: "hlg"},
    }
    return allowed.get(profile, {}).get(compatibility, "unknown")


def inspect_probe(probe: Any) -> dict[str, Any]:
    if not isinstance(probe, dict) or not isinstance(probe.get("streams"), list):
        raise ValueError("ffprobe input must contain a streams array")
    videos = []
    for stream in probe["streams"]:
        if not isinstance(stream, dict) or stream.get("codec_type") != "video":
            continue
        disposition = stream.get("disposition") or {}
        if isinstance(disposition, dict) and integer(disposition.get("attached_pic")) == 1:
            continue
        side_data = stream.get("side_data_list") or []
        if not isinstance(side_data, list):
            raise ValueError("side_data_list must be an array")
        records = [
            entry for entry in side_data if isinstance(entry, dict)
            and str(entry.get("side_data_type", "")).lower() == CONFIG_TYPE
        ]
        item: dict[str, Any] = {
            "stream_index": integer(stream.get("index")),
            "codec": stream.get("codec_name"),
            "width": integer(stream.get("width")),
            "height": integer(stream.get("height")),
            "pixel_format": stream.get("pix_fmt"),
            "transfer": stream.get("color_transfer"),
            "primaries": stream.get("color_primaries"),
            "matrix": stream.get("color_space"),
            "dv_configuration": "not_reported",
            "base_layer_compatibility": "unknown",
            "enhancement_layer": "unknown",
            "issues": [],
        }
        if records:
            configs = [{key: integer(record.get(key)) for key in CONFIG_FIELDS} for record in records]
            cfg = configs[0]
            item["dv_configuration"] = cfg
            issues = item["issues"]
            if any(candidate != cfg for candidate in configs[1:]):
                issues.append("conflicting_configuration_records")
            profile, compatibility = cfg["dv_profile"], cfg["dv_bl_signal_compatibility_id"]
            for key in ("rpu_present_flag", "el_present_flag", "bl_present_flag"):
                if cfg[key] not in (0, 1):
                    issues.append(f"missing_or_invalid_{key}")
            for key, maximum in (("dv_profile", 127), ("dv_level", 63), ("dv_bl_signal_compatibility_id", 15)):
                if cfg[key] is None or not 0 <= cfg[key] <= maximum:
                    issues.append(f"missing_or_invalid_{key}")
            if cfg["rpu_present_flag"] == 0:
                issues.append("rpu_not_advertised")
            if cfg["bl_present_flag"] == 0:
                issues.append("base_layer_not_advertised_in_this_stream")
            if profile not in (5, 7, 8, 9, 10, 20):
                issues.append("legacy_or_unrecognized_profile_requires_separate_qualification")
            elif base_layer(profile, compatibility) == "unknown":
                issues.append("unrecognized_profile_compatibility_combination")
            expected_codec = {5: "hevc", 7: "hevc", 8: "hevc", 9: "h264", 10: "av1", 20: "hevc"}.get(profile)
            if expected_codec and stream.get("codec_name") != expected_codec:
                issues.append("profile_codec_mismatch")
            if profile in (5, 8, 9, 10, 20) and cfg["el_present_flag"] == 1:
                issues.append("unexpected_enhancement_flag_for_single_layer_profile")
            if cfg["dv_md_compression"] not in (None, 0):
                issues.append("metadata_compression_requires_decoder_qualification")
            if profile == 8 and compatibility == 2:
                issues.append("historical_profile_8_sdr_variant_requires_qualification")
            # Never publish a fallback from a contradictory configuration.
            if not issues:
                item["base_layer_compatibility"] = base_layer(profile, compatibility)
            if "conflicting_configuration_records" not in issues:
                item["enhancement_layer"] = {
                    0: "not_advertised", 1: "present_mel_or_fel_unclassified"
                }.get(cfg["el_present_flag"], "unknown")
            if profile == 20:
                item["view_configuration"] = "requires_mv_hevc_view_inspection"
        videos.append(item)
    return {
        "schema_version": 1,
        "video_streams": videos,
        "qualification": {
            "fel_reconstruction": "not_tested",
            "creative_metadata_rendering": "not_tested",
            "physical_dolby_vision_output": "not_tested",
        },
        "limits": [
            "Container configuration is advertised metadata, not decoded-frame evidence.",
            "Absent DV configuration does not prove the bitstream contains no DV metadata.",
            "MEL/FEL needs parsed RPU/NLQ evidence and matching enhancement frames.",
            "Standalone mpv results do not qualify PlezyNG's embedded renderer.",
        ],
    }


def read_json(path: Path) -> Any:
    with path.open("rb") as handle:
        data = handle.read(MAX_REPORT_BYTES + 1)
    if len(data) > MAX_REPORT_BYTES:
        raise ValueError("probe report exceeds 8 MiB")
    return json.loads(data)


def capture(args: list[str], timeout: float = 30) -> dict[str, Any]:
    # Files keep verbose native output out of RAM; retain only bounded tails.
    with tempfile.TemporaryFile() as output, tempfile.TemporaryFile() as errors:
        try:
            result = subprocess.run(args, stdin=subprocess.DEVNULL, stdout=output,
                                    stderr=errors, timeout=timeout, check=False)
        except (OSError, subprocess.TimeoutExpired) as exc:
            return {"available": False, "error": type(exc).__name__}
        output.seek(0)
        stdout = output.read(MAX_REPORT_BYTES + 1)
        errors.seek(0)
        stderr = errors.read(8192)
        if len(stdout) > MAX_REPORT_BYTES:
            return {"available": False, "error": "output_limit_exceeded"}
        return {"available": True, "exit_code": result.returncode,
                "stdout": stdout.decode("utf-8", errors="replace"),
                "stderr": stderr.decode("utf-8", errors="replace")}


def probe_file(media: Path, executable: str) -> dict[str, Any]:
    result = capture([
        executable, "-v", "error", "-protocol_whitelist", "file,pipe",
        "-select_streams", "v", "-show_streams", "-of", "json", str(media),
    ])
    if not result["available"] or result["exit_code"] != 0:
        raise ValueError(f"ffprobe failed: {result.get('error', result.get('stderr', ''))}")
    return inspect_probe(json.loads(result["stdout"]))


def trial_command(media: Path, executable: str, output: str, seconds: float) -> list[str]:
    if not math.isfinite(seconds) or not 1 <= seconds <= 60:
        raise ValueError("trial duration must be between 1 and 60 seconds")
    args = [executable, "--no-config", "--load-scripts=no", "--vo=gpu-next",
            "--hwdec=auto-safe", "--audio=no", "--sid=no", "--start=0",
            f"--length={seconds:g}", "--msg-level=all=info"]
    if output == "auto":
        args.append("--target-colorspace-hint=yes")
    elif output == "sdr":
        args += ["--target-colorspace-hint=no", "--target-trc=bt.1886",
                 "--target-prim=bt.709", "--target-peak=100"]
    else:
        raise ValueError("output must be auto or sdr")
    # End option parsing even for unusual local filenames. No shell is used.
    return args + ["--", str(media)]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--media", type=Path, help="local media file to inspect")
    source.add_argument("--probe-json", type=Path, help="saved ffprobe -show_streams JSON")
    parser.add_argument("--ffprobe", default="ffprobe")
    parser.add_argument("--mpv", help="mpv executable whose version and output drivers to inspect")
    parser.add_argument("--play", action="store_true", help="run the standalone trial (requires --media and --mpv)")
    parser.add_argument("--output", choices=("auto", "sdr"), default="auto")
    parser.add_argument("--seconds", type=float, default=15)
    args = parser.parse_args(argv)
    if args.play and (not args.media or not args.mpv):
        parser.error("--play requires --media and --mpv")
    try:
        if args.media:
            media = args.media.resolve(strict=True)
            if not media.is_file():
                raise ValueError("media must be a local regular file")
            report = probe_file(media, args.ffprobe)
        else:
            report = inspect_probe(read_json(args.probe_json))
        report["host"] = {"platform": sys.platform,
                          "session_type": os.environ.get("XDG_SESSION_TYPE", "unknown")}
        if args.mpv:
            report["standalone_engine"] = {
                "version": capture([args.mpv, "--no-config", "--load-scripts=no", "--version"]),
                "video_outputs": capture([args.mpv, "--no-config", "--load-scripts=no", "--vo=help"]),
            }
            if args.media:
                command = trial_command(media, args.mpv, args.output, args.seconds)
                report["standalone_trial"] = {"argv": command, "executed": args.play,
                    "output_intent": args.output,
                    "note": "This command does not request a TV-led DV HDMI transport."}
                if args.play:
                    result = capture(command, timeout=args.seconds + 30)
                    report["standalone_trial"]["result"] = result
                    if not result["available"] or result["exit_code"] != 0:
                        print(json.dumps(report, indent=2))
                        return 1
        print(json.dumps(report, indent=2))
        return 0
    except (OSError, ValueError) as exc:
        print(f"dv_lab: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
