#!/usr/bin/env python3
"""Verify that the synthetic FEL patch reaches embedded mpv's render output.

This checks EL-dependent pixels and the real mpv/libplacebo graph. It does not
compare against Dolby's reference composer or qualify display output.
"""

from __future__ import annotations

import argparse
import json
import math
import os
from pathlib import Path
import re
import subprocess


PHASE_BOUNDARY_SECONDS = 24 * 1001 / 24000
CAPTURE_LINE = re.compile(r"rendered and read back at ([0-9]+(?:\.[0-9]+)?) s")
RPU_REPLACEMENT_WARNING = "Multiple Dolby Vision RPUs found in one AU. Skipping previous."


def rpu_replacement_warning_count(log_text: str) -> int:
    return log_text.count(RPU_REPLACEMENT_WARNING)


def rpu_association_status(replacement_warning_count: int) -> str:
    if replacement_warning_count < 0:
        raise ValueError("replacement_warning_count must not be negative")
    if replacement_warning_count:
        return "unqualified: FFmpeg replaced a pending RPU buffer before frame attachment"
    return "unverified: no replacement warning observed, but frame identity was not checked"


def capture_environment(
    library_paths: list[Path], *, software_gles: bool, base_environment=None
) -> dict[str, str]:
    """Build a process-local EGL environment with explicit engine library paths."""
    environment = dict(os.environ if base_environment is None else base_environment)
    environment["EGL_PLATFORM"] = "surfaceless"
    if software_gles:
        environment["LIBGL_ALWAYS_SOFTWARE"] = "1"
    else:
        environment.pop("LIBGL_ALWAYS_SOFTWARE", None)
    paths = [str(path) for path in library_paths]
    if environment.get("LD_LIBRARY_PATH"):
        paths.append(environment["LD_LIBRARY_PATH"])
    if paths:
        environment["LD_LIBRARY_PATH"] = os.pathsep.join(paths)
    return environment


def read_ppm(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    header = data.split(b"\n", 3)
    if len(header) != 4 or header[0] != b"P6" or header[2] != b"255":
        raise ValueError(f"{path} is not a supported binary P6 PPM")
    try:
        width, height = map(int, header[1].split())
    except (TypeError, ValueError) as error:
        raise ValueError(f"{path} has an invalid PPM size") from error
    pixels = header[3]
    if width <= 0 or height <= 0 or len(pixels) != width * height * 3:
        raise ValueError(f"{path} PPM pixel data length does not match its size")
    return width, height, pixels


def capture_seconds(stdout: str) -> float:
    match = CAPTURE_LINE.search(stdout)
    if not match:
        raise RuntimeError("render helper did not report a captured frame")
    value = float(match.group(1))
    if not math.isfinite(value):
        raise RuntimeError("render helper reported a non-finite capture timestamp")
    return value


def compare_pixels(width: int, height: int, first: bytes, second: bytes) -> dict:
    if len(first) != len(second) or len(first) != width * height * 3:
        raise ValueError("readback dimensions or byte lengths differ")
    center_x0, center_x1 = width // 4, 3 * width // 4
    center_y0, center_y1 = height // 4, 3 * height // 4
    sums = {"center": 0, "outside": 0}
    channels = {"center": 0, "outside": 0}
    changed_pixels = {"center": 0, "outside": 0}
    pixels_gt2 = {"center": 0, "outside": 0}

    for y in range(height):
        for x in range(width):
            region = "center" if center_x0 <= x < center_x1 and center_y0 <= y < center_y1 else "outside"
            pixel_changed = False
            pixel_gt2 = False
            offset = (y * width + x) * 3
            for index in range(offset, offset + 3):
                delta = abs(first[index] - second[index])
                sums[region] += delta
                channels[region] += 1
                pixel_changed |= delta != 0
                pixel_gt2 |= delta > 2
            changed_pixels[region] += int(pixel_changed)
            pixels_gt2[region] += int(pixel_gt2)

    center_mean = sums["center"] / channels["center"]
    outside_mean = sums["outside"] / channels["outside"]
    center_pixels = (center_x1 - center_x0) * (center_y1 - center_y0)
    outside_pixels = width * height - center_pixels
    return {
        "size": [width, height],
        "center_patch_mean_abs_channel_delta": center_mean,
        "outside_patch_mean_abs_channel_delta": outside_mean,
        "center_patch_pixels_changed": changed_pixels["center"],
        "outside_patch_pixels_changed": changed_pixels["outside"],
        "center_patch_pixels_changed_by_more_than_2": pixels_gt2["center"],
        "outside_patch_pixels_changed_by_more_than_2": pixels_gt2["outside"],
        "center_patch_pixel_count": center_pixels,
        "outside_patch_pixel_count": outside_pixels,
        "max_abs_channel_delta": max(
            abs(a - b) for a, b in zip(first, second)
        ),
        "fel_patch_dominates": center_mean >= 3 and center_mean >= 10 * max(outside_mean, 0.01),
    }


def verify(args) -> dict:
    if args.capture_neutral < 0.5 or args.capture_residual <= args.capture_neutral:
        raise ValueError("capture times must be >= 0.5 seconds and ordered neutral then residual")
    if args.capture_neutral >= args.phase_boundary or args.capture_residual < args.phase_boundary:
        raise ValueError("capture times must land on opposite sides of the EL phase boundary")
    for label, path in (("render helper", args.runner), ("input MP4", args.input)):
        if not path.is_file():
            raise ValueError(f"{label} does not exist: {path}")
    library_paths = list(args.library_path)
    bundled_library_directory = args.runner.resolve().parent.parent / "lib"
    if bundled_library_directory.is_dir() and bundled_library_directory not in library_paths:
        library_paths.insert(0, bundled_library_directory)
    for path in library_paths:
        if not path.is_dir():
            raise ValueError(f"library path is not a directory: {path}")
    if args.out_dir.exists() and any(args.out_dir.iterdir()):
        raise ValueError("use a new, empty output directory")
    args.out_dir.mkdir(parents=True, exist_ok=True)

    environment = capture_environment(library_paths, software_gles=not args.egl_gpu)
    captures = []
    warning_count = 0
    for phase, timestamp in (("neutral", args.capture_neutral), ("residual", args.capture_residual)):
        ppm = args.out_dir / f"{phase}.ppm"
        log = args.out_dir / f"{phase}.mpv.log"
        command = [
            str(args.runner), str(args.input), str(ppm), str(log),
            str(timestamp), args.hwdec,
        ]
        result = subprocess.run(command, capture_output=True, text=True, env=environment, check=False)
        (args.out_dir / f"{phase}.stdout.log").write_text(result.stdout + result.stderr)
        if result.returncode:
            raise RuntimeError(f"render helper failed for {phase}; see {log}")
        log_text = log.read_text(errors="replace")
        required = (
            "Found Dolby Vision config record: profile 7",
            "Dolby Vision Profile 7 splitter:",
            "[el_pair]",
            "sh_dovi_compose_nlq",
        )
        if any(marker not in log_text for marker in required):
            raise RuntimeError(f"mpv did not confirm the full P7 FEL graph for {phase}; see {log}")
        phase_warning_count = rpu_replacement_warning_count(log_text)
        warning_count += phase_warning_count
        actual = capture_seconds(result.stdout)
        if phase == "neutral" and actual >= args.phase_boundary:
            raise RuntimeError("neutral capture landed after the designed EL residual begins")
        if phase == "residual" and actual < args.phase_boundary:
            raise RuntimeError("residual capture landed before the designed EL residual begins")
        captures.append({
            "phase": phase,
            "requested_seconds": timestamp,
            "captured_seconds": actual,
            "hwdec": args.hwdec,
            "rpu_replacement_warnings": phase_warning_count,
        })

    width, height, neutral = read_ppm(args.out_dir / "neutral.ppm")
    residual_width, residual_height, residual = read_ppm(args.out_dir / "residual.ppm")
    if (width, height) != (residual_width, residual_height):
        raise RuntimeError("mpv readback dimensions differ between EL phases")
    comparison = compare_pixels(width, height, neutral, residual)
    if not comparison["fel_patch_dominates"]:
        raise RuntimeError("EL residual did not produce the expected center-patch pixel change")

    report = {
        "schema_version": 1,
        "input": str(args.input),
        "renderer": (
            "embedded libmpv opengl-next via GPU EGL/GLES"
            if args.egl_gpu
            else "embedded libmpv opengl-next via software GLES"
        ),
        "captures": captures,
        "mpv_graph": "Profile 7 splitter, [el_pair], and sh_dovi_compose_nlq confirmed in both logs",
        "pixel_comparison": comparison,
        "rpu_replacement_warning_count": warning_count,
        "rpu_association_status": rpu_association_status(warning_count),
        "qualification": "synthetic FEL graph/pixel-path evidence only; no independent Dolby pixel reference, RPU/frame identity proof, zero-copy hardware, or physical output qualification",
    }
    (args.out_dir / "render-report.json").write_text(json.dumps(report, indent=2) + "\n")
    if warning_count:
        raise RuntimeError(
            f"FFmpeg replaced a pending RPU buffer {warning_count} time(s); "
            f"captures are diagnostic only; see {args.out_dir / 'render-report.json'}"
        )
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runner", type=Path, required=True, help="compiled tools/dv-engine/real_clip_smoke.c helper")
    parser.add_argument("--input", type=Path, required=True, help="synthetic-p7-fel.mp4 from generate_synthetic_p7.py")
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--hwdec", choices=("no", "vaapi-copy"), default="no")
    parser.add_argument("--egl-gpu", action="store_true",
                        help="use the system EGL/GLES device instead of forcing software rendering")
    parser.add_argument("--library-path", type=Path, action="append", default=[],
                        help="directory added before existing LD_LIBRARY_PATH; repeat as needed")
    parser.add_argument("--phase-boundary", type=float, default=PHASE_BOUNDARY_SECONDS)
    parser.add_argument("--capture-neutral", type=float, default=0.5)
    parser.add_argument("--capture-residual", type=float, default=1.4)
    args = parser.parse_args()
    try:
        report = verify(args)
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        parser.error(str(error))
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
