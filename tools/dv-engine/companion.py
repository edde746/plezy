#!/usr/bin/env python3
"""Offline BL+EL reconstruction to an ordinary HDR/SDR optimized version.

Requires explicit local tools/plugins; never downloads executable code, listens
on a port, overwrites a source or claims that encoder success qualifies FEL.
Input is a synchronized pair of elementary HEVC streams retaining original RPU.
"""

from __future__ import annotations

import argparse
from fractions import Fraction
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


MAX_PROBE = 1024 * 1024


def regular(path: Path) -> Path:
    path = path.resolve(strict=True)
    if not path.is_file():
        raise ValueError("only local regular files are accepted")
    return path


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def probe(ffprobe: Path, path: Path, *, elementary=False, timeout=60) -> dict:
    command = [str(ffprobe), "-v", "error", "-protocol_whitelist", "file,pipe"]
    command += ["-f", "hevc"] if elementary else ["-format_whitelist", "matroska,mov"]
    command += ["-select_streams", "v:0", "-show_streams", "-of", "json", str(path)]
    with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        result = subprocess.run(command, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
                                check=False, timeout=timeout)
        stdout.seek(0)
        data = stdout.read(MAX_PROBE + 1)
    if result.returncode or len(data) > MAX_PROBE:
        raise ValueError("ffprobe failed or exceeded its output budget")
    streams = json.loads(data).get("streams", [])
    if len(streams) != 1:
        raise ValueError("expected exactly one selected video stream")
    return streams[0]


def validate_shape(bl: dict, el: dict) -> tuple[int, int]:
    width, height = bl.get("width"), bl.get("height")
    if (type(width) is not int or type(height) is not int or
            width < 16 or height < 16 or width > 8192 or height > 4320 or width % 2 or height % 2):
        raise ValueError("unsupported or unbounded BL dimensions")
    if bl.get("codec_name") != "hevc" or el.get("codec_name") != "hevc":
        raise ValueError("both layers must be HEVC")
    if (el.get("width"), el.get("height")) not in ((width, height), (width // 2, height // 2)):
        raise ValueError("EL must be full or half BL dimensions")
    if bl.get("pix_fmt") != "yuv420p10le" or el.get("pix_fmt") != "yuv420p10le":
        raise ValueError("this companion recipe currently accepts 10-bit 4:2:0 layers only")
    return width, height


def bake_script(bl: Path, el: Path, ffms: Path, baker: Path, fps: Fraction, frames: int) -> str:
    # JSON is data loaded by the script, never interpolated Python expressions.
    config = json.dumps({"bl": str(bl), "el": str(el), "ffms": str(ffms), "baker": str(baker),
                         "fps_num": fps.numerator, "fps_den": fps.denominator, "frames": frames})
    return '''import json
import vapoursynth as vs
core = vs.core
core.max_cache_size = 512
config = json.loads(CONFIG_JSON)
core.std.LoadPlugin(config['ffms'])
core.std.LoadPlugin(config['baker'])
bl = core.ffms2.Source(config['bl'], cache=False, threads=2)
el = core.ffms2.Source(config['el'], cache=False, threads=2)
if bl.num_frames != el.num_frames or bl.num_frames < 1:
    raise ValueError('BL/EL decoded frame counts differ')
count = config['frames'] or bl.num_frames
if count > bl.num_frames:
    raise ValueError('requested frame count exceeds source')
bl, el = bl[:count], el[:count]
# Bake reads original RPU from FFMS2 frame properties; it refuses absent or
# unsupported mapping. Do not replace this with metadata stripping or BL-only.
baked = core.fel.Bake(bl, el, no_resample=0, non_parallel=0, dovi_metadata=1)
if baked.format.id != vs.RGB48:
    raise ValueError('unexpected reconstruction pixel layout')
baked = core.std.AssumeFPS(baked, fpsnum=config['fps_num'], fpsden=config['fps_den'])
baked.set_output()
'''.replace("CONFIG_JSON", repr(config))


def encode_command(ffmpeg: Path, output: Path, *, width: int, height: int, fps: Fraction,
                   target: str, peak_nits: float, frames: int, audio: Path | None = None) -> list[str]:
    if target not in ("hdr10", "sdr") or not math.isfinite(peak_nits) or not 100 <= peak_nits <= 10000:
        raise ValueError("invalid target or source peak")
    args = [str(ffmpeg), "-hide_banner", "-nostdin", "-v", "error", "-n",
            "-protocol_whitelist", "file,pipe", "-f", "rawvideo", "-pixel_format", "gbrp16le",
            "-video_size", f"{width}x{height}", "-framerate", str(fps),
            "-color_range", "pc", "-color_primaries", "bt2020", "-color_trc", "smpte2084",
            "-colorspace", "rgb", "-i", "pipe:0"]
    if audio:
        args += ["-protocol_whitelist", "file,pipe", "-format_whitelist", "matroska,mov,mpegts",
                 "-i", str(audio)]
    args += ["-map", "0:v:0"]
    if audio:
        # A companion optimized version uses AAC for the broadest native-client
        # carriage. Pad short audio, then stop at video EOF; neither a short
        # audio track nor a long tail changes the derived video's duration.
        args += ["-map", "1:a:0?", "-c:a", "aac", "-b:a", "384k", "-af", "apad", "-shortest"]
    else:
        args += ["-an"]
    source = "matrixin=gbr:transferin=smpte2084:primariesin=2020:rangein=full"
    if target == "hdr10":
        vf = f"zscale={source}:matrix=2020_ncl:transfer=smpte2084:primaries=2020:range=limited:dither=error_diffusion,format=yuv420p10le"
        args += ["-vf", vf, "-c:v", "libx265", "-preset", "medium", "-crf", "18",
                 "-x265-params", "pools=2:frame-threads=2:repeat-headers=1",
                 "-color_primaries", "bt2020", "-color_trc", "smpte2084", "-colorspace", "bt2020nc"]
    else:
        vf = (f"zscale={source}:transfer=linear:npl=100,format=gbrpf32le,"
              f"tonemap=tonemap=mobius:desat=0:peak={peak_nits / 100:g},"
              "zscale=primaries=709:transfer=709:matrix=709:range=limited:dither=error_diffusion,format=yuv420p")
        args += ["-vf", vf, "-c:v", "libx264", "-preset", "medium", "-crf", "18",
                 "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709"]
    args += ["-color_range", "tv", "-map_metadata", "-1", "-map_chapters", "-1"]
    if frames:
        args += ["-frames:v", str(frames)]
        if audio:
            args += ["-t", str(float(Fraction(frames, 1) / fps))]
    return args + ["-f", "matroska", str(output)]


def pipe_processes(producer: list[str], consumer: list[str], *, timeout: float, cwd: Path) -> None:
    """Drain both stderr streams to files; kill and reap both on any failure."""
    started = time.monotonic()
    processes = []
    with tempfile.TemporaryFile() as first_log, tempfile.TemporaryFile() as second_log:
        try:
            first = subprocess.Popen(producer, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=first_log, cwd=cwd)
            processes.append(first)
            second = subprocess.Popen(consumer, stdin=first.stdout, stdout=subprocess.DEVNULL, stderr=second_log, cwd=cwd)
            processes.append(second)
            first.stdout.close()
            # The encoder consumes to EOF, unless it has an explicit frame cap.
            second.wait(timeout=max(0.01, timeout - (time.monotonic() - started)))
            first.wait(timeout=max(0.01, timeout - (time.monotonic() - started)))
            if first.returncode or second.returncode:
                raise RuntimeError(f"pipeline failed: decoder={first.returncode}, encoder={second.returncode}")
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
            for process in processes:
                process.wait()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for key in ("bl", "el", "ffms-plugin", "felbaker-plugin", "vspipe", "ffmpeg", "ffprobe", "output"):
        parser.add_argument("--" + key, type=Path, required=True)
    parser.add_argument("--audio", type=Path, help="optional local original container; audio must share video start time")
    parser.add_argument("--fps", type=Fraction, required=True, help="original rational frame rate, e.g. 24000/1001")
    parser.add_argument("--target", choices=("hdr10", "sdr"), default="hdr10")
    parser.add_argument("--peak-nits", type=float, default=1000, help="explicit source peak assumption for SDR mapping")
    parser.add_argument("--frames", type=int, default=0, help="0 for whole source; use 120 for the first trial")
    parser.add_argument("--timeout", type=float, default=3600)
    parser.add_argument("--execute", action="store_true", help="otherwise validate inputs and print the plan")
    args = parser.parse_args(argv)
    if not 1 <= args.fps <= 120 or not 0 <= args.frames <= 10_000_000:
        parser.error("invalid frame rate or frame budget")
    if not math.isfinite(args.timeout) or not 1 <= args.timeout <= 86400:
        parser.error("timeout must be 1..86400 seconds")
    paths = {k: regular(getattr(args, k)) for k in
             ("bl", "el", "ffms_plugin", "felbaker_plugin", "vspipe", "ffmpeg", "ffprobe")}
    audio = regular(args.audio) if args.audio else None
    output = args.output.absolute()
    if output.exists() or output.with_suffix(output.suffix + ".json").exists():
        parser.error("output or its report already exists")
    if output.suffix != ".mkv" or not output.parent.is_dir():
        parser.error("output must be a new .mkv in an existing directory")
    if paths["bl"] == paths["el"]:
        parser.error("BL and EL must be different files")
    bl = probe(paths["ffprobe"], paths["bl"], elementary=True)
    el = probe(paths["ffprobe"], paths["el"], elementary=True)
    width, height = validate_shape(bl, el)
    report = {"schema_version": 1, "recipe": "felbaker-rgb48-v1", "target": args.target,
              "fps": str(args.fps), "width": width, "height": height,
              "frames_requested": args.frames, "lossless": False,
              "reconstruction": "not_executed", "fel_qualified": False,
              "physical_dolby_vision_output": "not_requested",
              "sdr_peak_nits_assumption": args.peak_nits if args.target == "sdr" else None,
              "input_and_tool_sha256": {k: digest(v) for k, v in paths.items()}}
    if audio:
        report["input_and_tool_sha256"]["audio"] = digest(audio)
    if not args.execute:
        print(json.dumps(report, indent=2))
        return 0
    if shutil.disk_usage(output.parent).free < 1024 * 1024 * 1024:
        raise ValueError("at least 1 GiB of free working space is required")
    with tempfile.TemporaryDirectory(prefix="plezyng-dv-", dir=output.parent) as temporary:
        work = Path(temporary)
        script, partial = work / "bake.vpy", work / "derived.mkv"
        script.write_text(bake_script(paths["bl"], paths["el"], paths["ffms_plugin"],
                                     paths["felbaker_plugin"], args.fps, args.frames))
        command = encode_command(paths["ffmpeg"], partial, width=width, height=height, fps=args.fps,
                                 target=args.target, peak_nits=args.peak_nits, frames=args.frames, audio=audio)
        pipe_processes([str(paths["vspipe"]), "--requests", "2", str(script), "-"], command,
                       timeout=args.timeout, cwd=work)
        encoded = probe(paths["ffprobe"], partial)
        expected = ("hevc", "smpte2084", "bt2020") if args.target == "hdr10" else ("h264", "bt709", "bt709")
        if (encoded.get("codec_name"), encoded.get("color_transfer"), encoded.get("color_primaries")) != expected:
            raise ValueError("encoded output does not carry the requested color tags")
        report.update(reconstruction="pipeline_completed_unqualified", output_sha256=digest(partial))
        # link is atomic and refuses an output created since the preflight.
        os.link(partial, output)
        try:
            with output.with_suffix(output.suffix + ".json").open("x") as stream:
                json.dump(report, stream, indent=2)
                stream.write("\n")
        except BaseException:
            output.unlink()
            raise
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
