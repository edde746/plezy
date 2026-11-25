"""Checks a built matrix file against its spec entry with ffprobe (and dovi_tool for the RPUs).

`check` returns the list of mismatches (empty when the file is what the spec says) and the measured values that go
into matrix.json. Nothing here trusts the build: every property is read back from the muxed file.
"""

from __future__ import annotations

import json
import subprocess
from fractions import Fraction
from pathlib import Path

from spec import FPS_DEN, FPS_NUM, MASTERING, Clip

COLOR = {
    "sdr": {"color_range": "tv", "color_space": "bt709", "color_transfer": "bt709", "color_primaries": "bt709"},
    "hdr10": {"color_range": "tv", "color_space": "bt2020nc", "color_transfer": "smpte2084",
              "color_primaries": "bt2020"},
    # Profile 5 signals only full range: its base layer is IPTPQc2, which no VUI colour code describes.
    "dvp5": {"color_range": "pc", "color_space": None, "color_transfer": None, "color_primaries": None},
}
PIX_FMT = {8: "yuv420p", 10: "yuv420p10le"}


def run_json(cmd: list[str]) -> dict:
    out = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return json.loads(out.stdout)


def ffprobe(path: Path) -> dict:
    return run_json(["ffprobe", "-v", "error", "-show_format", "-show_streams", "-show_chapters", "-of", "json",
                     str(path)])


def first_frame_side_data(path: Path) -> list[dict]:
    info = run_json(["ffprobe", "-v", "error", "-select_streams", "v:0", "-read_intervals", "%+#1", "-show_frames",
                     "-show_entries", "frame=side_data_list", "-of", "json", str(path)])
    return info["frames"][0].get("side_data_list", []) if info.get("frames") else []


def subtitle_events(path: Path, index: int, bitmap: bool) -> int:
    """Cues in subtitle stream `index`: packets for text codecs, decoded display sets that show a picture for PGS
    (a PGS cue also has an empty display set that clears it)."""
    if bitmap:
        info = run_json(["ffprobe", "-v", "error", "-select_streams", f"s:{index}", "-show_frames", "-show_entries",
                         "subtitle=num_rects", "-of", "json", str(path)])
        return sum(1 for f in info.get("frames", []) if f.get("num_rects", 0) > 0)
    info = run_json(["ffprobe", "-v", "error", "-select_streams", f"s:{index}", "-show_packets", "-show_entries",
                     "packet=pts", "-of", "json", str(path)])
    return len(info.get("packets", []))


def rpu_summary(path: Path, work: Path) -> tuple[int, set[int]]:
    """Number of Dolby Vision RPUs in the video track and the profiles they carry."""
    es = work / "verify-rpu.hevc"
    rpu = work / "verify-rpu.bin"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(path), "-map", "0:v:0", "-c", "copy", "-bsf:v",
                    "hevc_mp4toannexb", "-f", "hevc", str(es)], check=True)
    subprocess.run(["dovi_tool", "extract-rpu", "-i", str(es), "-o", str(rpu)], check=True, capture_output=True)
    out = subprocess.run(["dovi_tool", "info", "-i", str(rpu), "-s"], check=True, capture_output=True, text=True)
    es.unlink()
    rpu.unlink()
    frames = profiles = None
    for line in out.stdout.splitlines():
        line = line.strip()
        if line.startswith("Frames:"):
            frames = int(line.split(":", 1)[1])
        elif line.startswith("Profile:"):
            profiles = {int(line.split(":", 1)[1].strip().split()[0].split(".")[0])}
    if frames is None or profiles is None:
        raise RuntimeError(f"unexpected dovi_tool summary:\n{out.stdout}")
    return frames, profiles


def decode_errors(path: Path) -> str:
    """Decodes every video and audio frame; returns FFmpeg's error output (empty when clean)."""
    r = subprocess.run(["ffmpeg", "-v", "error", "-nostdin", "-i", str(path), "-map", "0:v", "-map", "0:a", "-f",
                        "null", "-"], capture_output=True, text=True)
    return (r.stderr.strip() + (f"\nexit {r.returncode}" if r.returncode else "")).strip()


def _q(v: str | None) -> float | None:
    return None if v is None else float(Fraction(v))


def _side(entries: list[dict], kind: str) -> dict | None:
    return next((e for e in entries if e.get("side_data_type") == kind), None)


def _hdr_mismatches(where: str, side: list[dict], levels: dict) -> list[str]:
    bad = []
    md = _side(side, "Mastering display metadata")
    cll = _side(side, "Content light level metadata")
    if md is None:
        bad.append(f"{where}: no mastering display metadata")
    else:
        want = {"red_x": MASTERING["red"][0], "red_y": MASTERING["red"][1], "green_x": MASTERING["green"][0],
                "green_y": MASTERING["green"][1], "blue_x": MASTERING["blue"][0], "blue_y": MASTERING["blue"][1],
                "white_point_x": MASTERING["white"][0], "white_point_y": MASTERING["white"][1],
                "max_luminance": MASTERING["maxLuminance"], "min_luminance": MASTERING["minLuminance"]}
        for k, v in want.items():
            got = _q(md.get(k))
            # Containers and bitstreams store these at different precisions (1/50000, 1/65536, 1/16384 cd/m²…).
            tol = 0.0002 if k == "min_luminance" else max(0.001, v * 0.001)
            if got is None or abs(got - v) > tol:
                bad.append(f"{where}: mastering {k} {got} != {v}")
    if cll is None:
        bad.append(f"{where}: no content light level metadata")
    elif (cll.get("max_content"), cll.get("max_average")) != (levels["maxCll"], levels["maxFall"]):
        bad.append(f"{where}: MaxCLL/MaxFALL {cll.get('max_content')}/{cll.get('max_average')} != "
                   f"{levels['maxCll']}/{levels['maxFall']}")
    return bad


def check(clip: Clip, path: Path, work: Path, levels: dict | None) -> tuple[list[str], dict]:
    info = ffprobe(path)
    bad: list[str] = []
    measured: dict = {}

    def expect(what: str, got, want):
        if got != want:
            bad.append(f"{what}: {got!r} != {want!r}")

    fmt = info["format"]
    if "matroska" not in fmt.get("format_name", ""):
        bad.append(f"container {fmt.get('format_name')} is not Matroska")
    duration = float(fmt.get("duration", 0))
    if abs(duration - clip.seconds) > 0.1:
        bad.append(f"duration {duration:.3f}s != {clip.seconds:.3f}s")
    measured["durationSeconds"] = round(duration, 3)
    measured["bitRate"] = int(fmt["bit_rate"]) if "bit_rate" in fmt else None

    streams = info["streams"]
    videos = [s for s in streams if s["codec_type"] == "video"]
    audios = [s for s in streams if s["codec_type"] == "audio"]
    subs = [s for s in streams if s["codec_type"] == "subtitle"]
    expect("video tracks", len(videos), 1)
    expect("audio tracks", len(audios), len(clip.audio))
    expect("subtitle tracks", len(subs), len(clip.subtitles))
    if bad:
        return bad, measured

    v, vs = videos[0], clip.video
    expect("video codec", v["codec_name"], vs.codec)
    expect("video profile", v.get("profile"), vs.profile)
    expect("video size", (v["width"], v["height"]), (vs.width, vs.height))
    expect("video pix_fmt", v.get("pix_fmt"), PIX_FMT[vs.bit_depth])
    expect("video frame rate", v.get("r_frame_rate"), f"{FPS_NUM}/{FPS_DEN}")
    for k, want in COLOR[vs.signal].items():
        got = v.get(k)
        expect(f"video {k}", None if got in (None, "unknown") else got, want)
    expect("video default flag", v["disposition"]["default"], 1)

    stream_side = v.get("side_data_list", [])
    frame_side = first_frame_side_data(path)
    if vs.signal == "hdr10":
        bad += _hdr_mismatches("container", stream_side, levels)
        bad += _hdr_mismatches("bitstream", frame_side, levels)
    dovi = _side(stream_side, "DOVI configuration record")
    if vs.dovi:
        profile = int(vs.dovi.split(".")[0])
        compat = 0 if vs.dovi == "5" else 1
        if dovi is None:
            bad.append("no Dolby Vision configuration record (dvcC) on the video track")
        else:
            expect("dvcC profile", dovi.get("dv_profile"), profile)
            expect("dvcC bl_signal_compatibility_id", dovi.get("dv_bl_signal_compatibility_id"), compat)
            expect("dvcC rpu/bl/el present", (dovi.get("rpu_present_flag"), dovi.get("bl_present_flag"),
                                              dovi.get("el_present_flag")), (1, 1, 0))
            measured["doviLevel"] = dovi.get("dv_level")
        if _side(frame_side, "Dolby Vision Metadata") is None:
            bad.append("first frame carries no Dolby Vision RPU")
        rpus, profiles = rpu_summary(path, work)
        expect("RPUs (one per frame)", rpus, clip.frames)
        expect("RPU profile", profiles, {profile})
    elif dovi is not None:
        bad.append("unexpected Dolby Vision configuration record")

    for i, (s, a) in enumerate(zip(audios, clip.audio)):
        w = f"audio {i + 1}"
        expect(f"{w} codec", s["codec_name"], a.codec)
        expect(f"{w} profile", s.get("profile"), a.profile)
        expect(f"{w} channels", s.get("channels"), a.channels)
        expect(f"{w} layout", s.get("channel_layout"), a.layout)
        expect(f"{w} sample rate", int(s.get("sample_rate", 0)), a.sample_rate)
        if a.bits is not None:
            expect(f"{w} bits", int(s.get("bits_per_raw_sample", 0)), a.bits)
        tags, disp = s.get("tags", {}), s["disposition"]
        expect(f"{w} language", tags.get("language"), a.language_legacy)
        expect(f"{w} title", tags.get("title"), a.title)
        expect(f"{w} flags", (disp["default"], disp["forced"], disp["comment"], disp["original"]),
               (int(a.default), 0, int(a.commentary), int(a.original)))

    for i, (s, t) in enumerate(zip(subs, clip.subtitles)):
        w = f"subtitle {i + 1}"
        expect(f"{w} codec", s["codec_name"], t.codec)
        tags, disp = s.get("tags", {}), s["disposition"]
        expect(f"{w} language", tags.get("language"), t.language_legacy)
        expect(f"{w} title", tags.get("title"), t.title)
        expect(f"{w} flags", (disp["default"], disp["forced"], disp["hearing_impaired"]),
               (int(t.default), int(t.forced), int(t.hearing_impaired)))
        expect(f"{w} events", subtitle_events(path, i, t.codec == "hdmv_pgs_subtitle"), t.events)
        if t.codec == "hdmv_pgs_subtitle":
            expect(f"{w} canvas", (s.get("width"), s.get("height")), (1920, 1080))

    chapters = [(round(float(c["start_time"]), 3), c.get("tags", {}).get("title")) for c in info.get("chapters", [])]
    expect("chapters", chapters, [(float(t), name) for t, name in clip.chapters])

    errors = decode_errors(path)
    if errors:
        bad.append(f"decoding reported errors:\n{errors}")
    return bad, measured


def summary(path: Path) -> str:
    """One line per stream, for the build log."""
    info = ffprobe(path)
    lines = [f"{path.name}: {float(info['format']['duration']):.2f}s, {int(info['format'].get('bit_rate', 0)) // 1000}"
             f" kb/s, {len(info.get('chapters', []))} chapters"]
    for s in info["streams"]:
        t, d = s.get("tags", {}), s["disposition"]
        flags = ",".join(k for k in ("default", "forced", "hearing_impaired", "comment", "original") if d.get(k))
        if s["codec_type"] == "video":
            side = [e["side_data_type"] for e in s.get("side_data_list", [])]
            dv = _side(s.get("side_data_list", []), "DOVI configuration record")
            extra = f" DV p{dv['dv_profile']} l{dv['dv_level']} compat {dv['dv_bl_signal_compatibility_id']}" if dv else ""
            lines.append(f"  v {s['codec_name']} {s.get('profile')} {s['width']}x{s['height']} {s.get('pix_fmt')} "
                         f"{s.get('r_frame_rate')} range={s.get('color_range')} matrix={s.get('color_space')} "
                         f"trc={s.get('color_transfer')} prim={s.get('color_primaries')} side={side}{extra}")
        elif s["codec_type"] == "audio":
            lines.append(f"  a {s['codec_name']} {s.get('profile') or ''} {s.get('channels')}ch "
                         f"{s.get('channel_layout')} {s.get('sample_rate')}Hz bits={s.get('bits_per_raw_sample')} "
                         f"lang={t.get('language')} title={t.get('title')!r} [{flags}]")
        else:
            lines.append(f"  s {s['codec_name']} lang={t.get('language')} title={t.get('title')!r} [{flags}]")
    return "\n".join(lines)
