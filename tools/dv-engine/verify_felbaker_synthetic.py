#!/usr/bin/env python3
"""Verify authored P7 controls and EL-dependent FelBaker output."""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
from pathlib import Path
import sys


def frame_planes(frame):
    """Read a planar RGB48 VapourSynth frame without assuming tight strides."""
    import numpy as np

    planes = []
    for plane in range(3):
        stride = frame.get_stride(plane)
        data = ctypes.string_at(frame.get_read_ptr(plane).value, stride * frame.height)
        planes.append(
            np.frombuffer(data, dtype=np.uint16)
            .reshape(frame.height, stride // 2)[:, : frame.width]
        )
    return planes


def validate_synthetic_control(
    *,
    bl_rate: tuple[int, int],
    el_rate: tuple[int, int],
    neutral_rpu: bytes,
    residual_rpu: bytes,
    base_layer_identical: bool,
    center_codes: tuple[int, int],
    outside_codes: tuple[int, int],
    el_luma_pattern_exact: bool,
    el_chroma_identical: bool,
    bl_dimensions: tuple[int, int],
    el_dimensions: tuple[int, int],
    bl_frames: int,
    el_frames: int,
) -> dict[str, object]:
    """Validate the sampled authored controls used by the output comparison."""
    if bl_dimensions != (3840, 2160) or el_dimensions != (1920, 1080):
        raise RuntimeError(
            f"unexpected BL/EL dimensions: BL={bl_dimensions} EL={el_dimensions}"
        )
    if bl_frames != 48 or el_frames != 48:
        raise RuntimeError(
            f"expected 48 frames per layer, got BL={bl_frames} EL={el_frames}"
        )
    if bl_rate != (24000, 1001) or el_rate != bl_rate:
        raise RuntimeError(
            f"expected matching 24000/1001 BL/EL rates, got BL={bl_rate} EL={el_rate}"
        )
    if not isinstance(neutral_rpu, bytes) or not neutral_rpu:
        raise RuntimeError("neutral-phase EL has no DolbyVisionRPU property")
    if not isinstance(residual_rpu, bytes) or not residual_rpu:
        raise RuntimeError("residual-phase EL has no DolbyVisionRPU property")
    if neutral_rpu != residual_rpu:
        raise RuntimeError("synthetic control phases must carry identical RPU metadata")
    if not base_layer_identical:
        raise RuntimeError("synthetic control phases must use identical decoded BL frames")
    if center_codes != (512, 640):
        raise RuntimeError(
            f"synthetic EL center codes were {center_codes}; expected neutral/residual 512/640"
        )
    if outside_codes != (512, 512):
        raise RuntimeError(
            f"synthetic EL outside control codes were {outside_codes}; expected 512/512"
        )
    if not el_luma_pattern_exact:
        raise RuntimeError("decoded EL luma did not match the authored residual patch exactly")
    if not el_chroma_identical:
        raise RuntimeError("decoded EL chroma changed between neutral and residual controls")
    return {
        "passed": True,
        "frame_count_per_layer": 48,
        "frame_rate": {"numerator": 24000, "denominator": 1001},
        "dimensions": {"bl": [3840, 2160], "el": [1920, 1080]},
        "sampled_bl_frames_identical": True,
        "sampled_rpu_properties_identical": True,
        "el_luma_pattern_matches_authored_patch": True,
        "el_chroma_unchanged": True,
        "el_luma_control_codes": {
            "center_neutral": center_codes[0],
            "center_residual": center_codes[1],
            "outside_neutral": outside_codes[0],
            "outside_residual": outside_codes[1],
        },
    }


def main() -> int:
    import numpy as np
    import vapoursynth as vs

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ffms-plugin", required=True, type=Path)
    parser.add_argument("--felbaker-plugin", required=True, type=Path)
    parser.add_argument("--bl", required=True, type=Path)
    parser.add_argument("--el", required=True, type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    for label, path in (
        ("FFMS2 plugin", args.ffms_plugin),
        ("FelBaker plugin", args.felbaker_plugin),
        ("base layer", args.bl),
        ("enhancement layer", args.el),
    ):
        if not path.is_file():
            parser.error(f"{label} does not exist or is not a file: {path}")
    if args.report and args.report.exists():
        parser.error(f"report already exists: {args.report}")

    core = vs.core
    core.std.LoadPlugin(str(args.ffms_plugin))
    core.std.LoadPlugin(str(args.felbaker_plugin))
    bl = core.ffms2.Source(str(args.bl), cache=False, threads=2)
    el = core.ffms2.Source(str(args.el), cache=False, threads=2)
    if bl.num_frames != 48 or el.num_frames != 48:
        raise RuntimeError(
            f"expected 48 frames per layer, got BL={bl.num_frames} EL={el.num_frames}"
        )

    neutral_index, residual_index = 8, 40
    neutral_bl_frame = bl.get_frame(neutral_index)
    residual_bl_frame = bl.get_frame(residual_index)
    neutral_el_frame = el.get_frame(neutral_index)
    residual_el_frame = el.get_frame(residual_index)
    neutral_bl = frame_planes(neutral_bl_frame)
    residual_bl = frame_planes(residual_bl_frame)
    neutral_el = frame_planes(neutral_el_frame)
    residual_el = frame_planes(residual_el_frame)
    neutral_rpu = neutral_el_frame.props.get("DolbyVisionRPU")
    residual_rpu = residual_el_frame.props.get("DolbyVisionRPU")
    el_height, el_width = neutral_el[0].shape
    expected_patch = np.zeros((el_height, el_width), dtype=np.bool_)
    expected_patch[
        el_height // 4 : el_height * 3 // 4,
        el_width // 4 : el_width * 3 // 4,
    ] = True
    el_luma_pattern_exact = (
        np.all(neutral_el[0] == 512)
        and np.all(residual_el[0][expected_patch] == 640)
        and np.all(residual_el[0][~expected_patch] == 512)
        and np.array_equal(neutral_el[0] != residual_el[0], expected_patch)
    )
    el_chroma_identical = all(
        np.all(neutral == 512)
        and np.all(residual == 512)
        and np.array_equal(neutral, residual)
        for neutral, residual in zip(neutral_el[1:], residual_el[1:])
    )
    control = validate_synthetic_control(
        bl_rate=(bl.fps_num, bl.fps_den),
        el_rate=(el.fps_num, el.fps_den),
        neutral_rpu=neutral_rpu,
        residual_rpu=residual_rpu,
        base_layer_identical=all(
            np.array_equal(before, after) for before, after in zip(neutral_bl, residual_bl)
        ),
        center_codes=(
            int(neutral_el[0][el_height // 2, el_width // 2]),
            int(residual_el[0][el_height // 2, el_width // 2]),
        ),
        outside_codes=(
            int(neutral_el[0][el_height // 8, el_width // 8]),
            int(residual_el[0][el_height // 8, el_width // 8]),
        ),
        el_luma_pattern_exact=bool(el_luma_pattern_exact),
        el_chroma_identical=bool(el_chroma_identical),
        bl_dimensions=(bl.width, bl.height),
        el_dimensions=(el.width, el.height),
        bl_frames=bl.num_frames,
        el_frames=el.num_frames,
    )

    baked = core.fel.Bake(bl, el, dovi_metadata=1)
    if baked.format.id != vs.RGB48 or baked.num_frames != 48:
        raise RuntimeError(
            f"unexpected FelBaker output: format={baked.format.name} frames={baked.num_frames}"
        )
    neutral = frame_planes(baked.get_frame(neutral_index))
    residual = frame_planes(baked.get_frame(residual_index))
    height, width = neutral[0].shape
    if any(plane.shape != (height, width) for plane in (*neutral, *residual)):
        raise RuntimeError("FelBaker returned inconsistent RGB plane dimensions")

    # The authored EL changes its central half-width/half-height region.
    x0, x1 = width // 4, width * 3 // 4
    y0, y1 = height // 4, height * 3 // 4
    outside_x1, outside_y1 = width // 4, height // 4
    patch_count = (x1 - x0) * (y1 - y0)
    outside_count = outside_x1 * outside_y1
    patch_sums = [0, 0, 0]
    outside_sums = [0, 0, 0]
    changed_patch = np.zeros((y1 - y0, x1 - x0), dtype=np.bool_)
    changed_outside = np.zeros((outside_y1, outside_x1), dtype=np.bool_)
    for channel, (before, after) in enumerate(zip(neutral, residual)):
        delta = np.abs(before.astype(np.int32) - after.astype(np.int32))
        patch_delta = delta[y0:y1, x0:x1]
        outside_delta = delta[:outside_y1, :outside_x1]
        patch_sums[channel] = int(patch_delta.sum())
        outside_sums[channel] = int(outside_delta.sum())
        changed_patch |= patch_delta > 2
        changed_outside |= outside_delta > 2

    patch_mean = sum(patch_sums) / (3 * patch_count)
    outside_mean = sum(outside_sums) / (3 * outside_count)
    patch_changed_pixels = int(changed_patch.sum())
    outside_changed_pixels = int(changed_outside.sum())
    if not patch_mean > 100 or not patch_mean > outside_mean * 10:
        raise RuntimeError(
            f"EL-dependent change did not dominate: patch={patch_mean:.3f} "
            f"outside={outside_mean:.3f} RGB48 codes"
        )

    version = core.ffms2.Version()
    if isinstance(version, bytes):
        version = version.decode("utf-8", errors="replace")
    report = {
        "ffms2_version": str(version),
        "base_layer_frames": bl.num_frames,
        "enhancement_layer_frames": el.num_frames,
        "rpu_property_bytes": len(neutral_rpu),
        "rpu_property_sha256": hashlib.sha256(neutral_rpu).hexdigest(),
        "residual_rpu_property_sha256": hashlib.sha256(residual_rpu).hexdigest(),
        "synthetic_control": control,
        "baker_format": baked.format.name,
        "baker_frames": baked.num_frames,
        "baker_width": width,
        "baker_height": height,
        "neutral_frame": neutral_index,
        "residual_frame": residual_index,
        "center_patch_mean_abs_rgb48_delta": patch_mean,
        "outside_control_mean_abs_rgb48_delta": outside_mean,
        "center_patch_pixels_changed_by_more_than_2_codes": patch_changed_pixels,
        "center_patch_pixel_count": patch_count,
        "outside_control_pixels_changed_by_more_than_2_codes": outside_changed_pixels,
        "outside_control_pixel_count": outside_count,
        "fel_residual_changes_output": True,
        "qualification": (
            "synthetic FelBaker path evidence only; not an independent Dolby reference, "
            "accuracy measurement, or display-output qualification"
        ),
    }
    encoded = json.dumps(report, indent=2) + "\n"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(encoded)
    sys.stdout.write(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
