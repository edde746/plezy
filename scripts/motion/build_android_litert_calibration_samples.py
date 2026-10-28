#!/usr/bin/env python3
"""Build reproducible LiteRT W8A8 calibration tensors from an SDR video clip.

The Android ANVIL graph accepts two RGB frames packed as six float32 channels
in NCHW order. This utility selects evenly spaced consecutive pairs, decodes
them through FFmpeg, and writes both 1280x720 and 1920x1080 calibration sets.
ANVIL playback applies H.264 motion-vector prealignment before inference; these
samples intentionally retain the decoded consecutive frames and document that
limitation in metadata.
"""

from __future__ import annotations

import argparse
import fractions
import hashlib
import json
import subprocess
from pathlib import Path
from typing import Any


RESOLUTIONS = {
    "720p": (1280, 720),
    "1080p": (1920, 1080),
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def probe_video(path: Path, ffprobe: str) -> dict[str, Any]:
    result = subprocess.run(
        [
            ffprobe,
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=width,height,avg_frame_rate,r_frame_rate,nb_frames,pix_fmt,color_transfer,color_primaries,color_space",
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
    parsed = json.loads(result.stdout)
    streams = parsed.get("streams", [])
    if not streams:
        raise ValueError(f"No video stream found in {path}")
    stream = streams[0]
    rate = None
    rate_text = "unknown"
    for candidate in (stream.get("avg_frame_rate"), stream.get("r_frame_rate")):
        if not candidate:
            continue
        try:
            parsed_rate = fractions.Fraction(candidate)
        except (ValueError, ZeroDivisionError):
            continue
        if parsed_rate > 0:
            rate = parsed_rate
            rate_text = candidate
            break
    if rate is None:
        raise ValueError(f"Could not determine a positive video frame rate: {rate_text}")

    raw_count = stream.get("nb_frames")
    if raw_count and raw_count.isdigit():
        frame_count = int(raw_count)
    else:
        duration = float(parsed.get("format", {}).get("duration", 0))
        frame_count = round(duration * float(rate))
    if frame_count < 2:
        raise ValueError("The source must contain at least two video frames")

    width = int(stream["width"])
    height = int(stream["height"])
    if width < 640 or height < 360:
        raise ValueError(f"Calibration source is unexpectedly small: {width}x{height}")
    transfer = str(stream.get("color_transfer") or "unknown").lower()
    if transfer in {"smpte2084", "arib-std-b67"}:
        raise ValueError(f"Calibration source must be SDR; found HDR transfer {transfer}")
    return {
        "width": width,
        "height": height,
        "frame_rate": f"{rate.numerator}/{rate.denominator}",
        "frame_count": frame_count,
        "pixel_format": stream.get("pix_fmt", "unknown"),
        "color_transfer": transfer,
        "color_primaries": stream.get("color_primaries", "unknown"),
        "color_space": stream.get("color_space", "unknown"),
    }


def sample_pair_indices(frame_count: int, pair_count: int) -> list[int]:
    if pair_count < 2:
        raise ValueError("Use at least two pairs so calibration covers multiple scenes")
    if pair_count > frame_count - 1:
        raise ValueError(f"Requested {pair_count} pairs from only {frame_count} frames")
    indices: list[int] = []
    for sample_index in range(pair_count):
        frame_index = round((sample_index + 0.5) * frame_count / pair_count)
        frame_index = min(frame_count - 2, max(0, frame_index))
        indices.append(frame_index)
    if len(set(indices)) != pair_count:
        raise ValueError("The source is too short to place distinct calibration pairs")
    return indices


def decode_selected_frames(
    source: Path,
    indices: list[int],
    width: int,
    height: int,
    ffmpeg: str,
) -> bytes:
    selected = sorted({index for first in indices for index in (first, first + 1)})
    expression = "+".join(f"eq(n\\,{index})" for index in selected)
    filters = [f"select={expression}"]
    filters.extend(
        (
            f"scale={width}:{height}:force_original_aspect_ratio=decrease:flags=area",
            f"pad={width}:{height}:(ow-iw)/2:(oh-ih)/2:color=black",
        )
    )
    command = [
        ffmpeg,
        "-nostdin",
        "-v",
        "error",
        "-i",
        str(source),
        "-map",
        "0:v:0",
        "-an",
        "-sn",
        "-dn",
        "-vf",
        ",".join(filters),
        "-fps_mode",
        "passthrough",
        "-frames:v",
        str(len(selected)),
        "-pix_fmt",
        "rgb24",
        "-f",
        "rawvideo",
        "pipe:1",
    ]
    result = subprocess.run(command, check=True, capture_output=True)
    expected_bytes = len(selected) * width * height * 3
    if len(result.stdout) != expected_bytes:
        raise RuntimeError(
            f"FFmpeg decoded {len(result.stdout)} bytes; expected {expected_bytes} "
            f"for {len(selected)} RGB frames at {width}x{height}"
        )
    return result.stdout


def write_resolution_samples(
    source: Path,
    output_root: Path,
    resolution: str,
    dimensions: tuple[int, int],
    pair_indices: list[int],
    frame_rate: fractions.Fraction,
    ffmpeg: str,
) -> list[dict[str, Any]]:
    import numpy as np

    width, height = dimensions
    frame_bytes = width * height * 3
    selected = sorted({index for first in pair_indices for index in (first, first + 1)})
    raw = decode_selected_frames(source, pair_indices, width, height, ffmpeg)
    frames = {
        frame_index: np.frombuffer(
            raw[offset * frame_bytes : (offset + 1) * frame_bytes], dtype=np.uint8
        ).reshape(height, width, 3)
        for offset, frame_index in enumerate(selected)
    }

    directory = output_root / resolution
    directory.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, Any]] = []
    listing: list[str] = []
    for sample_index, first_frame in enumerate(pair_indices):
        previous = frames[first_frame].transpose(2, 0, 1)
        current = frames[first_frame + 1].transpose(2, 0, 1)
        tensor = np.concatenate((previous, current), axis=0).astype(np.float32)
        tensor *= 1.0 / 255.0
        filename = f"pair-{sample_index:03d}.f32"
        sample_path = directory / filename
        tensor.tofile(sample_path)
        listing.append(filename)
        records.append(
            {
                "file": filename,
                "sha256": sha256_file(sample_path),
                "first_frame": first_frame,
                "second_frame": first_frame + 1,
                "first_timestamp_seconds": round(float(first_frame / frame_rate), 6),
                "second_timestamp_seconds": round(float((first_frame + 1) / frame_rate), 6),
            }
        )
    (directory / "input_list.txt").write_text("\n".join(listing) + "\n", encoding="utf-8")
    return records


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="Representative SDR input video")
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--pairs", type=int, default=12, help="Evenly spaced adjacent frame pairs")
    parser.add_argument(
        "--allow-untagged-sdr",
        action="store_true",
        help="Accept a source whose color-transfer metadata is unknown after confirming it is SDR.",
    )
    parser.add_argument("--source-url", help="Canonical source URL, recorded in calibration metadata")
    parser.add_argument("--source-license", help="Source license, recorded in calibration metadata")
    parser.add_argument("--source-attribution", help="Required credit for the source, recorded in metadata")
    parser.add_argument("--ffmpeg", default="ffmpeg")
    parser.add_argument("--ffprobe", default="ffprobe")
    args = parser.parse_args()

    source = args.input.resolve(strict=True)
    output_root = args.output_dir.resolve()
    probe = probe_video(source, args.ffprobe)
    if probe["color_transfer"] == "unknown" and not args.allow_untagged_sdr:
        raise ValueError("Source transfer is untagged; confirm SDR and pass --allow-untagged-sdr")
    pair_indices = sample_pair_indices(probe["frame_count"], args.pairs)
    frame_rate = fractions.Fraction(probe["frame_rate"])
    output_root.mkdir(parents=True, exist_ok=True)

    samples: dict[str, Any] = {}
    for resolution, dimensions in RESOLUTIONS.items():
        records = write_resolution_samples(
            source,
            output_root,
            resolution,
            dimensions,
            pair_indices,
            frame_rate,
            args.ffmpeg,
        )
        samples[resolution] = {
            "width": dimensions[0],
            "height": dimensions[1],
            "resize": (
                "FFmpeg swscale area; aspect-preserving fit with centered black bars"
                if abs(probe["width"] / probe["height"] - dimensions[0] / dimensions[1]) > 0.001
                else "FFmpeg swscale area; aspect-preserving fit"
            ),
            "pairs": records,
        }

    metadata = {
        "format": 1,
        "source": {
            "filename": source.name,
            "url": args.source_url,
            "license": args.source_license,
            "attribution": args.source_attribution,
            "bytes": source.stat().st_size,
            "sha256": sha256_file(source),
            **probe,
            "untagged_sdr_explicitly_accepted": args.allow_untagged_sdr,
        },
        "tensor": {
            "dtype": "float32",
            "layout": "NCHW",
            "shape": "[1, 6, height, width]",
            "channels": ["previous.R", "previous.G", "previous.B", "current.R", "current.G", "current.B"],
            "normalization": "RGB samples divided by 255 into [0, 1]",
            "pair_alignment": "decoded consecutive frames; playback motion-vector prealignment is not reproduced",
        },
        "sampling": {
            "policy": "evenly spaced consecutive frame pairs across the full source duration",
            "pair_count": args.pairs,
        },
        "samples": samples,
    }
    metadata_path = output_root / "metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Wrote {args.pairs} calibration pairs per resolution to {output_root}")
    print(f"Source SHA-256: {metadata['source']['sha256']}")
    print(f"Metadata: {metadata_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
