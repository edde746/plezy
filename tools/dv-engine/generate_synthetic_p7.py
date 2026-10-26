#!/usr/bin/env python3
"""Generate and validate a short, authored Dolby Vision Profile 7 FEL stream.

The video layers are generated here. The only downloaded fixture is the
384-byte MIT-licensed FEL RPU test vector from dovi_tool, pinned by URL and
SHA-256. No film or other third-party video is used.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import shlex
import shutil
import struct
import subprocess
import urllib.request


RPU_URL = (
    "https://raw.githubusercontent.com/quietvoid/dovi_tool/"
    "ef85991cfc31e26bc3ffed76364965f29f9fd281/assets/tests/fel_orig.bin"
)
RPU_SHA256 = "b2b27714b7279c4e24d1a795cb6f95d3ad06745db96d360698ee0932184117a0"
BL_WIDTH, BL_HEIGHT = 3840, 2160
EL_WIDTH, EL_HEIGHT = BL_WIDTH // 2, BL_HEIGHT // 2
FRAME_RATE = "24000/1001"
BASE_CODES = (256, 384, 512, 640)
EL_NEUTRAL = 512
EL_RESIDUAL = 640


def _sample(value: int) -> bytes:
    return struct.pack("<H", value)


def make_bl_frame(width: int = BL_WIDTH, height: int = BL_HEIGHT) -> bytes:
    """A fixed four-level BT.2020 luma pattern with neutral chroma."""
    if width < 4 or width % 4 or height < 2 or height % 2:
        raise ValueError("base dimensions must be divisible by four and two")
    stripe = width // 4
    row = b"".join(_sample(code) * stripe for code in BASE_CODES)
    y = row * height
    chroma = _sample(512) * (width // 2) * (height // 2)
    return y + chroma + chroma


def make_el_frame(width: int = EL_WIDTH, height: int = EL_HEIGHT, *, residual: bool) -> bytes:
    """Neutral EL or a positive luma residual in a centered half-frame patch."""
    if width < 4 or height < 4 or width % 2 or height % 2:
        raise ValueError("enhancement dimensions must be even and at least 4x4")
    x0, x1 = width // 4, (width * 3) // 4
    y0, y1 = height // 4, (height * 3) // 4
    neutral = _sample(EL_NEUTRAL) * width
    residual_row = (
        _sample(EL_NEUTRAL) * x0
        + _sample(EL_RESIDUAL) * (x1 - x0)
        + _sample(EL_NEUTRAL) * (width - x1)
    )
    y = b"".join(
        (residual_row if residual and y0 <= row < y1 else neutral)
        for row in range(height)
    )
    chroma = _sample(512) * (width // 2) * (height // 2)
    return y + chroma + chroma


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_exact(stream, size: int) -> bytes:
    result = bytearray()
    while len(result) < size:
        chunk = stream.read(size - len(result))
        if not chunk:
            break
        result.extend(chunk)
    return bytes(result)


def _run(args: list[str], log_path: Path, *, timeout: int = 600) -> str:
    completed = subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False)
    log_path.write_text("$ " + shlex.join(args) + "\n" + completed.stdout + completed.stderr)
    if completed.returncode:
        raise RuntimeError(f"{args[0]} exited {completed.returncode}; see {log_path}")
    return completed.stdout


def validate_mp4_probe(probe: dict, frames: int) -> dict:
    """Require the MP4 container to identify a timestamped Profile 7 FEL track."""
    streams = probe.get("streams")
    if not isinstance(streams, list) or len(streams) != 1:
        raise RuntimeError("MP4 probe did not find exactly one video stream")
    stream = streams[0]
    config = next(
        (item for item in stream.get("side_data_list", [])
         if item.get("side_data_type") == "DOVI configuration record"),
        None,
    )
    expected = {
        "dv_profile": 7,
        "rpu_present_flag": 1,
        "el_present_flag": 1,
        "bl_present_flag": 1,
    }
    if not config or any(config.get(key) != value for key, value in expected.items()):
        raise RuntimeError("MP4 Dolby Vision configuration is not Profile 7 BL+EL+RPU")
    has_el_decoder_config = any(
        item.get("side_data_type") == "HEVC enhancement-layer decoder configuration"
        for item in stream.get("side_data_list", [])
    )
    if not has_el_decoder_config:
        raise RuntimeError("MP4 is missing the HEVC enhancement-layer decoder configuration")
    if stream.get("codec_name") != "hevc" or stream.get("codec_tag_string") not in ("dvh1", "hvc1"):
        raise RuntimeError("MP4 video track is not a supported HEVC sample entry")
    if stream.get("r_frame_rate") != FRAME_RATE or stream.get("avg_frame_rate") != FRAME_RATE:
        raise RuntimeError("MP4 frame rate does not preserve the authored rational rate")
    if int(stream.get("nb_frames", -1)) != frames:
        raise RuntimeError("MP4 frame count does not match the authored layers")
    try:
        start = float(stream["start_time"])
        duration = float(stream["duration"])
        time_base_num, time_base_den = map(int, stream["time_base"].split("/"))
    except (KeyError, TypeError, ValueError) as error:
        raise RuntimeError("MP4 video track is missing usable timing metadata") from error
    if (time_base_num != 1 or time_base_den <= 0 or not math.isfinite(start)
            or not math.isfinite(duration) or start < 0
            or abs(duration - frames * 1001 / 24000) > 0.002):
        raise RuntimeError("MP4 video track has invalid timestamps or duration")
    return {
        "codec_tag": stream["codec_tag_string"],
        "profile": config["dv_profile"],
        "rpu_present": bool(config["rpu_present_flag"]),
        "enhancement_layer_present": bool(config["el_present_flag"]),
        "enhancement_layer_decoder_config": has_el_decoder_config,
        "base_layer_present": bool(config["bl_present_flag"]),
        "frame_rate": stream["avg_frame_rate"],
        "time_base": stream["time_base"],
        "frames": frames,
        "start_time": start,
        "duration": duration,
    }


def validate_mp4_packets(probe: dict, frames: int) -> dict:
    """Require one distinct, monotonically decodable PTS/DTS per authored frame."""
    packets = probe.get("packets")
    if not isinstance(packets, list) or len(packets) != frames:
        raise RuntimeError("MP4 packet count does not match the authored frame count")
    try:
        pts = [int(packet["pts"]) for packet in packets]
        dts = [int(packet["dts"]) for packet in packets]
        durations = [int(packet["duration"]) for packet in packets]
    except (KeyError, TypeError, ValueError) as error:
        raise RuntimeError("MP4 packet is missing presentation/decode timestamps") from error
    expected_pts = [index * 1001 for index in range(frames)]
    if (sorted(pts) != expected_pts or any(b <= a for a, b in zip(dts, dts[1:]))
            or any(duration != 1001 for duration in durations)):
        raise RuntimeError("MP4 PTS/DTS cadence does not match 24000/1001 fps")
    return {
        "packet_count": len(packets),
        "presentation_timestamps_unique_and_complete": True,
        "decode_timestamps_monotonic": True,
        "packet_duration_ticks": 1001,
    }


def _encode_x265(
    executable: str,
    output: Path,
    log_path: Path,
    *,
    width: int,
    height: int,
    frames: int,
    frame_factory,
    hdr10: bool,
) -> None:
    keyint = frames // 2
    command = [
        executable,
        "--input", "-",
        "--input-res", f"{width}x{height}",
        "--fps", FRAME_RATE,
        "--input-depth", "10",
        "--input-csp", "i420",
        "--output-depth", "10",
        "--profile", "main10",
        "--preset", "ultrafast",
        "--lossless",
        "--keyint", str(keyint),
        "--min-keyint", str(keyint),
        "--no-scenecut",
        "--no-open-gop",
        "--repeat-headers",
        "--aud",
        "--frames", str(frames),
        "--pools", "4",
        "--frame-threads", "2",
    ]
    if hdr10:
        command += [
            "--colorprim", "bt2020",
            "--transfer", "smpte2084",
            "--colormatrix", "bt2020nc",
            "--range", "limited",
            "--hdr10",
            "--master-display", "G(8500,39850)B(6550,2300)R(35400,14600)WP(15635,16450)L(100000000,50)",
            "--max-cll", "10000,400",
        ]
    command += ["-o", str(output)]
    with log_path.open("w") as log:
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=log)
        try:
            assert process.stdin is not None
            for index in range(frames):
                process.stdin.write(frame_factory(index))
            process.stdin.close()
            status = process.wait(timeout=600)
        except BaseException:
            process.kill()
            process.wait()
            raise
    if status:
        detail = log_path.read_text(errors="replace")[-2000:]
        raise RuntimeError(f"x265 exited {status}; see {log_path}\n{detail}")


def _fetch_rpu(path: Path, custom: Path | None) -> None:
    if custom is not None:
        data = custom.read_bytes()
    else:
        request = urllib.request.Request(RPU_URL, headers={"User-Agent": "PlezyNG-DV-synthetic-test"})
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read(16 * 1024 + 1)
    if len(data) != 384 or hashlib.sha256(data).hexdigest() != RPU_SHA256:
        raise ValueError("FEL RPU fixture size or SHA-256 did not match the pinned MIT test vector")
    path.write_bytes(data)


def _check_el(ffmpeg: str, path: Path, width: int, height: int, frames: int, log_path: Path) -> dict:
    command = [
        ffmpeg, "-v", "error", "-i", str(path), "-frames:v", str(frames),
        "-f", "rawvideo", "-pix_fmt", "yuv420p10le", "pipe:1",
    ]
    with log_path.open("wb") as log:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=log)
        assert process.stdout is not None
        frame_bytes = width * height * 3
        y_bytes = width * height * 2
        center = ((height // 2) * width + (width // 2)) * 2
        outside = ((height // 8) * width + (width // 8)) * 2
        observed = []
        try:
            for frame_index in range(frames):
                frame = _read_exact(process.stdout, frame_bytes)
                if len(frame) != frame_bytes:
                    raise RuntimeError(f"decoded EL ended at frame {frame_index}; see {log_path}")
                center_value = struct.unpack_from("<H", frame, center)[0]
                outside_value = struct.unpack_from("<H", frame, outside)[0]
                expected_center = EL_NEUTRAL if frame_index < frames // 2 else EL_RESIDUAL
                if center_value != expected_center or outside_value != EL_NEUTRAL:
                    raise RuntimeError(
                        f"EL frame {frame_index} codes were center={center_value}, outside={outside_value}; "
                        f"expected center={expected_center}, outside={EL_NEUTRAL}"
                    )
                observed.append({"frame": frame_index, "center_y": center_value, "outside_y": outside_value})
            if process.stdout.read(1):
                raise RuntimeError(f"decoded EL had more than {frames} frames; see {log_path}")
            status = process.wait(timeout=120)
        except BaseException:
            process.kill()
            process.wait()
            raise
    if status:
        raise RuntimeError(f"ffmpeg exited {status}; see {log_path}")
    return {
        "decoded_frames": len(observed),
        "neutral_phase_center_code": observed[0]["center_y"],
        "residual_phase_center_code": observed[-1]["center_y"],
        "outside_patch_code": observed[0]["outside_y"],
        "codes_match_design": True,
    }


def generate(args) -> dict:
    out = args.out_dir.absolute()
    if out.exists() and any(out.iterdir()):
        raise ValueError("use a new, empty output directory")
    out.mkdir(parents=True, exist_ok=True)
    for label, executable in (
        ("x265", args.x265), ("dovi_tool", args.dovi_tool), ("ffmpeg", args.ffmpeg),
        ("ffprobe", args.ffprobe), ("MP4Box", args.mp4box),
    ):
        if not Path(executable).is_file() and shutil.which(executable) is None:
            raise ValueError(f"required tool not found: {label}")

    frames = args.frames
    if frames < 24 or frames > 240 or frames % 2:
        raise ValueError("--frames must be an even number from 24 through 240")

    template = out / "fel_orig.bin"
    _fetch_rpu(template, args.rpu_template)
    bl = out / "base.hevc"
    el = out / "enhancement.hevc"
    p7_el = out / "enhancement-with-rpu.hevc"
    p7 = out / "synthetic-p7-fel.hevc"
    p7_mp4 = out / "synthetic-p7-fel.mp4"
    rpu = out / "extracted-rpu.bin"
    demux_bl = out / "demuxed-base.hevc"
    demux_el = out / "demuxed-enhancement.hevc"

    _encode_x265(
        args.x265, bl, out / "encode-base.log", width=BL_WIDTH, height=BL_HEIGHT,
        frames=frames, frame_factory=lambda _: make_bl_frame(), hdr10=True,
    )
    _encode_x265(
        args.x265, el, out / "encode-enhancement.log", width=EL_WIDTH, height=EL_HEIGHT,
        frames=frames, frame_factory=lambda index: make_el_frame(residual=index >= frames // 2),
        hdr10=False,
    )

    duplicate = out / "duplicate-rpu.json"
    duplicate.write_text(json.dumps({"duplicate": [{"source": 0, "offset": 1, "length": frames - 1}]}) + "\n")
    repeated_rpu = out / "repeated-fel-rpu.bin"
    _run([args.dovi_tool, "editor", "--input", str(template), "--json", str(duplicate),
          "--rpu-out", str(repeated_rpu)], out / "repeat-rpu.log")
    _run([args.dovi_tool, "inject-rpu", "--input", str(el), "--rpu-in", str(repeated_rpu),
          "--output", str(p7_el)], out / "inject-rpu.log")
    _run([args.dovi_tool, "mux", "--bl", str(bl), "--el", str(p7_el), "--output", str(p7)],
         out / "mux-p7.log")
    credential_key = out / ".mp4box-credentials.key"
    try:
        _run([args.mp4box, f"-cred={credential_key}", "-add",
              f"{p7}:fps={FRAME_RATE}:dvp=7", "-new", str(p7_mp4)],
             out / "mux-p7-mp4.log")
    finally:
        credential_key.unlink(missing_ok=True)
    probe = json.loads(_run(
        [args.ffprobe, "-v", "error", "-select_streams", "v:0", "-show_streams", "-of", "json", str(p7_mp4)],
        out / "probe-p7-mp4.log",
    ))
    container_check = validate_mp4_probe(probe, frames)
    packet_probe = json.loads(_run(
        [args.ffprobe, "-v", "error", "-select_streams", "v:0", "-show_packets",
         "-show_entries", "packet=pts,dts,duration", "-of", "json", str(p7_mp4)],
        out / "probe-p7-packets.log",
    ))
    container_check["packet_timestamps"] = validate_mp4_packets(packet_probe, frames)
    _run([args.dovi_tool, "extract-rpu", "--input", str(p7), "--rpu-out", str(rpu)],
         out / "extract-rpu.log")
    _run([args.dovi_tool, "demux", "--input", str(p7), "--bl-out", str(demux_bl),
          "--el-out", str(demux_el)], out / "demux-p7.log")

    rpu_bytes = rpu.read_bytes()
    rpu_count = rpu_bytes.count(b"\x00\x00\x00\x01")
    if rpu_count != frames:
        raise RuntimeError(f"expected {frames} RPU NAL units, found {rpu_count}")
    info_output = _run([args.dovi_tool, "info", "--input", str(rpu), "--frame", "0"],
                       out / "rpu-info.log")
    rpu_info = json.loads(info_output[info_output.find("{"):])
    if rpu_info.get("dovi_profile") != 7 or rpu_info.get("el_type") != "FEL":
        raise RuntimeError("generated stream's RPU did not identify Profile 7 FEL")
    el_result = _check_el(args.ffmpeg, demux_el, EL_WIDTH, EL_HEIGHT, frames, out / "decode-el.log")

    files = [template, bl, el, p7_el, p7, p7_mp4, rpu, demux_bl, demux_el]
    manifest = {
        "schema_version": 1,
        "kind": "synthetic Dolby Vision Profile 7 FEL test input",
        "source_media": "none; both HEVC layers are authored by this generator",
        "base_layer": {"width": BL_WIDTH, "height": BL_HEIGHT, "frame_rate": FRAME_RATE},
        "enhancement_layer": {"width": EL_WIDTH, "height": EL_HEIGHT, "frames": frames},
        "frame_count": frames,
        "rpu": {"profile": 7, "el_type": "FEL", "frames": rpu_count,
                "url": RPU_URL, "sha256": RPU_SHA256, "license": "MIT (dovi_tool test asset)"},
        "enhancement_design": {
            "first_half_center_luma_code": EL_NEUTRAL,
            "second_half_center_luma_code": EL_RESIDUAL,
            "outside_patch_luma_code": EL_NEUTRAL,
            "design_check": el_result,
        },
        "container_check": container_check,
        "qualification": "valid synthetic P7 FEL input; not an independent Dolby pixel reference or output qualification",
        "sha256": {path.name: _sha256(path) for path in files},
    }
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--frames", type=int, default=48)
    parser.add_argument("--x265", default=shutil.which("x265") or "x265")
    parser.add_argument("--dovi-tool", default=shutil.which("dovi_tool") or "dovi_tool")
    parser.add_argument("--ffmpeg", default=shutil.which("ffmpeg") or "ffmpeg")
    parser.add_argument("--ffprobe", default=shutil.which("ffprobe") or "ffprobe")
    parser.add_argument("--mp4box", default=shutil.which("MP4Box") or "MP4Box")
    parser.add_argument("--rpu-template", type=Path, help="local copy of the pinned 384-byte MIT test vector")
    args = parser.parse_args()
    try:
        report = generate(args)
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        parser.error(str(error))
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
