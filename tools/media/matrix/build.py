# /// script
# requires-python = ">=3.11"
# dependencies = ["numpy==2.5.3", "pillow==12.3.0"]
# ///
"""Builds the playback matrix into an output directory and writes tools/media/matrix.json.

Run through tools/media/make-matrix.sh. Each file is generated from the entries in spec.py, muxed with mkvmerge,
then read back with ffprobe/dovi_tool and compared with its entry; any mismatch fails the build. A file whose
inputs, generator code and tool versions are unchanged since the last build (and whose bytes still match) is not
rebuilt, but it is verified again.
"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

import numpy
import PIL

import pattern
import pgs
import verify
from spec import BEEP_HZ, CLIPS, FPS_DEN, FPS_NUM, MASTERING, Audio, Clip, Download

HERE = Path(__file__).resolve().parent
MEDIA = HERE.parent
SUBS = HERE / "subs"
MATRIX_JSON = MEDIA / "matrix.json"
FPS = f"{FPS_NUM}/{FPS_DEN}"
# Fixed thread counts keep the encoders' output independent of the machine's core count.
X264 = "threads=8:keyint=48:min-keyint=24:scenecut=0"
X265 = "pools=8:frame-threads=2:keyint=48:min-keyint=24:scenecut=0:repeat-headers=1:log-level=error"
SVT = "lp=6:keyint=48:scd=0"


def log(msg: str):
    print(msg, flush=True)


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        raise SystemExit(f"command failed ({r.returncode}): {' '.join(cmd)}\n{r.stdout}\n{r.stderr}")
    return r


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


# -- tool versions -------------------------------------------------------------------------------------------------


def tool_versions() -> dict:
    ffmpeg = run(["ffmpeg", "-hide_banner", "-version"]).stdout.split("\n")[0]
    mkvmerge = run(["mkvmerge", "--version"]).stdout.strip()
    dovi = run(["dovi_tool", "--version"]).stdout.strip()
    return {
        "ffmpeg": re.search(r"ffmpeg version (\S+)", ffmpeg).group(1),
        "mkvmerge": re.search(r"mkvmerge (v\S+)", mkvmerge).group(1),
        "dovi_tool": dovi.split()[-1],
        "numpy": numpy.__version__,
        "pillow": PIL.__version__,
    }


def encoder_versions(work: Path) -> dict:
    """Versions of the encoder libraries FFmpeg links, read from what they write (SEI strings, SVT's banner)."""
    probe = work / "probe"
    probe.mkdir(parents=True, exist_ok=True)
    src = ["-f", "lavfi", "-i", "testsrc2=s=64x64:r=24:d=0.2"]
    run(["ffmpeg", "-v", "error", "-y", *src, "-c:v", "libx264", "-f", "h264", str(probe / "v.h264")])
    run(["ffmpeg", "-v", "error", "-y", *src, "-c:v", "libx265", "-x265-params", "log-level=error", "-f", "hevc",
         str(probe / "v.hevc")])
    svt = run(["ffmpeg", "-v", "error", "-y", *src, "-c:v", "libsvtav1", "-f", "ivf", str(probe / "v.ivf")]).stderr
    x264 = re.search(rb"x264 - core (\d+ r\d+ \w+)", (probe / "v.h264").read_bytes())
    x265 = re.search(rb"x265 \(build \d+\) - ([^:]+):", (probe / "v.hevc").read_bytes())
    svt_v = re.search(r"SVT-AV1 Encoder Lib (v\S+)", svt)
    shutil.rmtree(probe)
    if not (x264 and x265 and svt_v):
        raise SystemExit("could not read the x264/x265/SVT-AV1 versions")
    return {"x264": x264.group(1).decode(), "x265": x265.group(1).decode(), "svt-av1": svt_v.group(1)}


# -- inputs ----------------------------------------------------------------------------------------------------------


def fetch(d: Download, work_root: Path) -> Path:
    """The pinned download, from the cache under the work root or fetched and checked against its sha256."""
    dest = work_root / "downloads" / Path(urllib.request.url2pathname(d.url.rsplit("/", 1)[1])).name
    if dest.exists() and dest.stat().st_size == d.size and sha256(dest) == d.sha256:
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    log(f"  downloading {d.url}")
    req = urllib.request.Request(d.url, headers={"User-Agent": "plezy-make-matrix"})
    with urllib.request.urlopen(req, timeout=120) as r, tmp.open("wb") as f:
        shutil.copyfileobj(r, f)
    got = sha256(tmp)
    if got != d.sha256 or tmp.stat().st_size != d.size:
        tmp.unlink()
        raise SystemExit(f"{d.url}: sha256 {got} / {tmp.stat().st_size if tmp.exists() else '?'} bytes, "
                         f"expected {d.sha256} / {d.size}")
    tmp.rename(dest)
    return dest


def video_es(clip: Clip, work: Path) -> tuple[Path, dict | None]:
    """Renders the pattern into the encoder and returns the elementary stream and the HDR light levels."""
    v = clip.video
    signal = pattern.Signal(v.signal, v.bit_depth)
    pat = pattern.Pattern(signal, v.width, v.height, clip.frames, f"Plezy playback matrix · {clip.id}",
                          list(v.lines), clip.chapters if v.chapter_label else ())
    levels = pat.light_levels() if v.signal != "sdr" else None
    raw = ["-f", "rawvideo", "-pix_fmt", signal.pix_fmt, "-s", f"{v.width}x{v.height}", "-r", FPS, "-i", "-"]
    if v.grain:
        raw += ["-vf", f"noise=alls={v.grain}:allf=t"]
    quality = ["-b:v", v.bitrate] if v.bitrate else None
    if v.codec == "h264":
        out = work / "video.h264"
        enc = ["-c:v", "libx264", "-preset", "slow", "-crf", "18", "-profile:v", "high", "-x264-params",
               f"{X264}:colorprim=bt709:transfer=bt709:colormatrix=bt709:range=tv", "-f", "h264"]
    elif v.codec == "hevc":
        out = work / "video.hevc"
        if v.signal == "hdr10":
            color = (f"colorprim=bt2020:transfer=smpte2084:colormatrix=bt2020nc:range=limited:hdr10=1:hdr10-opt=1:"
                     f"master-display={x265_master_display()}:max-cll={levels['maxCll']},{levels['maxFall']}")
        else:
            color = "range=full"
        enc = ["-c:v", "libx265", "-preset", "medium", "-crf", "16", "-x265-params", f"{X265}:{color}", "-f", "hevc"]
    elif v.codec == "av1" and v.signal == "sdr":
        out = work / "video.ivf"
        params = f"{SVT}:color-primaries=bt709:transfer-characteristics=bt709:matrix-coefficients=bt709:color-range=studio"
        enc = ["-c:v", "libsvtav1", "-preset", "8", *(quality or ["-crf", "24"]), "-svtav1-params", params, "-f", "ivf"]
    elif v.codec == "av1":
        out = work / "video.ivf"
        m = MASTERING
        params = (f"{SVT}:enable-hdr=1:color-primaries=bt2020:transfer-characteristics=smpte2084:"
                  f"matrix-coefficients=bt2020-ncl:color-range=studio:"
                  f"mastering-display=G({m['green'][0]},{m['green'][1]})B({m['blue'][0]},{m['blue'][1]})"
                  f"R({m['red'][0]},{m['red'][1]})WP({m['white'][0]},{m['white'][1]})"
                  f"L({m['maxLuminance']:g},{m['minLuminance']:g}):"
                  f"content-light={levels['maxCll']},{levels['maxFall']}")
        enc = ["-c:v", "libsvtav1", "-preset", "8", "-crf", "24", "-svtav1-params", params, "-f", "ivf"]
    elif v.codec == "mpeg2video":
        # Main profile at High level (4/4), as broadcast HD and DVD remuxes carry it.
        out = work / "video.m2v"
        enc = ["-c:v", "mpeg2video", "-profile:v", "4", "-level:v", "4", *(quality or ["-q:v", "2"]), "-g", "12",
               "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709", "-f", "mpeg2video"]
    else:
        raise ValueError(v.codec)
    cmd = ["ffmpeg", "-hide_banner", "-v", "error", "-y", *raw, *enc, str(out)]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        for n in range(clip.frames):
            pat.write_frame(n, proc.stdin)
        proc.stdin.close()
    except BrokenPipeError:
        pass
    err = proc.stderr.read().decode(errors="replace")
    if proc.wait() != 0:
        raise SystemExit(f"video encode failed: {' '.join(cmd)}\n{err}")
    # SVT-AV1 prints its banner on stderr whatever the log level; anything else is a problem.
    noise = [line for line in err.splitlines() if line.strip() and not line.startswith("Svt[info]")]
    if noise:
        raise SystemExit(f"video encoder complained: {' '.join(cmd)}\n" + "\n".join(noise))
    if v.dovi:
        out = inject_rpu(clip, out, levels, work)
    return out, levels


def x265_master_display() -> str:
    m = MASTERING

    def xy(p):
        return f"({round(p[0] * 50000)},{round(p[1] * 50000)})"

    return (f"G{xy(m['green'])}B{xy(m['blue'])}R{xy(m['red'])}WP{xy(m['white'])}"
            f"L({round(m['maxLuminance'] * 10000)},{round(m['minLuminance'] * 10000)})")


def inject_rpu(clip: Clip, es: Path, levels: dict, work: Path) -> Path:
    """Generates a Dolby Vision RPU per frame (dovi_tool) and interleaves it with the base layer."""
    config = {
        "cm_version": "V40",
        "profile": clip.video.dovi,
        "length": clip.frames,
        "level6": {
            "max_display_mastering_luminance": round(MASTERING["maxLuminance"]),
            "min_display_mastering_luminance": round(MASTERING["minLuminance"] * 10000),
            "max_content_light_level": levels["maxCll"],
            "max_frame_average_light_level": levels["maxFall"],
        },
        "shots": [{"start": 0, "duration": clip.frames, "metadata_blocks": [{"Level1": levels["l1"]}]}],
    }
    cfg = work / "rpu.json"
    cfg.write_text(json.dumps(config, indent=2))
    rpu = work / "rpu.bin"
    run(["dovi_tool", "generate", "-j", str(cfg), "-o", str(rpu)])
    out = work / "video.dv.hevc"
    run(["dovi_tool", "inject-rpu", "-i", str(es), "--rpu-in", str(rpu), "-o", str(out)])
    return out


def audio_es(a: Audio, clip: Clip, index: int, work: Path) -> Path:
    if a.download:
        src = fetch(a.download, work.parent)  # `work` is the clip's scratch directory, removed after the build
        out = work / f"audio{index}.{a.codec}"
        run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-c", "copy", "-t", f"{a.trim_seconds:.6f}", "-f",
             a.codec, str(out)])
        return out
    beep = "lt(mod(t,1),0.125)"
    exprs = []
    for hz in a.tones:
        if hz < 100:  # LFE: a steady low tone, no beep
            exprs.append(f"0.1*sin(2*PI*{hz}*t)")
        else:
            exprs.append(f"0.1*sin(2*PI*{hz}*t)*(1-{beep})+0.3*sin(2*PI*{BEEP_HZ}*t)*{beep}")
    src = f"aevalsrc=exprs='{'|'.join(exprs)}':c={a.layout}:s={a.sample_rate}:d={clip.seconds:.6f}"
    if a.codec == "aac":
        out, enc = work / f"audio{index}.aac", ["-c:a", "aac", "-b:a", a.bitrate, "-f", "adts"]
    elif a.codec == "ac3":
        out, enc = work / f"audio{index}.ac3", ["-c:a", "ac3", "-b:a", a.bitrate, "-f", "ac3"]
    elif a.codec == "truehd":
        out, enc = work / f"audio{index}.thd", ["-c:a", "truehd", "-strict", "experimental", "-sample_fmt", "s32p",
                                                 "-f", "truehd"]
    else:
        raise ValueError(a.codec)
    run(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", src, *enc, str(out)])
    return out


def subtitle_file(t, index: int, work: Path) -> Path:
    src = SUBS / t.source
    if t.codec != "hdmv_pgs_subtitle":
        return src
    cues = pgs.parse_srt(src)
    if len(cues) != t.events:
        raise SystemExit(f"{t.source}: {len(cues)} cues, spec says {t.events}")
    out = work / f"sub{index}.sup"
    pgs.write_sup(cues, out, forced=t.forced)
    return out


# -- mux -------------------------------------------------------------------------------------------------------------


def flag(opt: str, value: bool) -> list[str]:
    return [f"--{opt}", f"0:{int(value)}"]


def titled(path: Path, title: str, work: Path) -> tuple[Path, list[str]]:
    """The input and the mkvmerge options that give its track `title`.

    On macOS mkvmerge turns every command-line string into NFD, option files included, so "Español" would be stored
    decomposed. Track names it copies from a Matroska source are left alone, so a non-ASCII title is set by wrapping
    the stream in a Matroska file with FFmpeg first. FFmpeg's bit-exact mode gives every such track UID 1, so
    mkvmerge generates fresh (seeded, see --deterministic) UIDs for them."""
    if title.isascii():
        return path, ["--track-name", f"0:{title}"]
    wrapped = work / f"{path.stem}.titled.mkv"
    run(["ffmpeg", "-v", "error", "-y", "-i", str(path), "-map", "0", "-c", "copy", "-metadata:s:0", f"title={title}",
         "-fflags", "+bitexact", "-f", "matroska", str(wrapped)])
    return wrapped, ["--regenerate-track-uids"]


def mux(clip: Clip, video: Path, levels: dict | None, audio: list[Path], subs: list[Path], work: Path, out: Path):
    v = clip.video
    # --deterministic seeds everything mkvmerge would otherwise randomise, so the same inputs give the same bytes.
    cmd = ["mkvmerge", "--quiet", "--deterministic", str(int(hashlib.sha256(clip.id.encode()).hexdigest()[:8], 16)),
           "--title", f"Plezy playback matrix: {clip.id}", "-o", str(out)]
    cmd += ["--default-duration", f"0:{FPS}p", *flag("default-track-flag", True)]
    if v.signal == "sdr":
        cmd += ["--color-matrix-coefficients", "0:1", "--color-range", "0:1", "--color-transfer-characteristics",
                "0:1", "--color-primaries", "0:1"]
    elif v.signal == "hdr10":
        m = MASTERING
        cmd += ["--color-matrix-coefficients", "0:9", "--color-range", "0:1", "--color-transfer-characteristics",
                "0:16", "--color-primaries", "0:9",
                "--max-content-light", f"0:{levels['maxCll']}", "--max-frame-light", f"0:{levels['maxFall']}",
                "--chromaticity-coordinates",
                f"0:{m['red'][0]},{m['red'][1]},{m['green'][0]},{m['green'][1]},{m['blue'][0]},{m['blue'][1]}",
                "--white-color-coordinates", f"0:{m['white'][0]},{m['white'][1]}",
                "--max-luminance", f"0:{m['maxLuminance']:g}", "--min-luminance", f"0:{m['minLuminance']:g}"]
    else:  # Dolby Vision profile 5: full range, no colour description
        cmd += ["--color-range", "0:2"]
    cmd.append(str(video))
    for a, path in zip(clip.audio, audio):
        path, name = titled(path, a.title, work)
        cmd += ["--language", f"0:{a.language}", *name,
                *flag("default-track-flag", a.default), *flag("forced-display-flag", False),
                *flag("commentary-flag", a.commentary), *flag("original-flag", a.original), str(path)]
    for t, path in zip(clip.subtitles, subs):
        path, name = titled(path, t.title, work)
        cmd += ["--language", f"0:{t.language}", *name,
                *flag("default-track-flag", t.default), *flag("forced-display-flag", t.forced),
                *flag("hearing-impaired-flag", t.hearing_impaired)]
        if path.suffix in (".ass", ".srt"):
            cmd += ["--sub-charset", "0:UTF-8"]
        cmd.append(str(path))
    if clip.chapters:
        chapters = work / "chapters.txt"
        lines = []
        for i, (start, name) in enumerate(clip.chapters, 1):
            h, rem = divmod(start, 3600)
            m_, s = divmod(rem, 60)
            lines += [f"CHAPTER{i:02d}={int(h):02d}:{int(m_):02d}:{s:06.3f}", f"CHAPTER{i:02d}NAME={name}"]
        chapters.write_text("\n".join(lines) + "\n", encoding="utf-8")
        cmd += ["--chapter-language", "en", "--chapter-charset", "UTF-8", "--chapters", str(chapters)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:  # 1 = warnings, 2 = errors: both mean the file isn't what the spec says
        raise SystemExit(f"mkvmerge exited {r.returncode}: {' '.join(cmd)}\n{r.stdout}\n{r.stderr}")


# -- per-clip build --------------------------------------------------------------------------------------------------


def fingerprint(clip: Clip, versions: dict) -> str:
    h = hashlib.sha256()
    h.update(json.dumps(dataclasses.asdict(clip), sort_keys=True).encode())
    h.update(json.dumps(versions, sort_keys=True).encode())
    for f in sorted(HERE.glob("*.py")):
        h.update(f.read_bytes())
    for t in clip.subtitles:
        h.update((SUBS / t.source).read_bytes())
    return h.hexdigest()


def build_clip(clip: Clip, out_dir: Path, work_root: Path, versions: dict, force: bool) -> dict:
    work = work_root / clip.id
    target = out_dir / clip.file
    stamp = work_root / f"{clip.id}.stamp.json"
    fp = fingerprint(clip, versions)
    state = json.loads(stamp.read_text()) if stamp.exists() else {}
    if (not force and target.exists() and state.get("fingerprint") == fp
            and state.get("sha256") == sha256(target)):
        log(f"{clip.id}: up to date, verifying")
        levels = state.get("levels")
    else:
        t0 = time.monotonic()
        log(f"{clip.id}: building ({clip.video.codec} {clip.video.width}x{clip.video.height}, {clip.frames} frames)")
        if work.exists():
            shutil.rmtree(work)
        work.mkdir(parents=True)
        video, levels = video_es(clip, work)
        audio = [audio_es(a, clip, i, work) for i, a in enumerate(clip.audio)]
        subs = [subtitle_file(t, i, work) for i, t in enumerate(clip.subtitles)]
        tmp = out_dir / f".{clip.file}.part"
        mux(clip, video, levels, audio, subs, work, tmp)
        os.replace(tmp, target)
        shutil.rmtree(work)
        state = {"fingerprint": fp, "sha256": sha256(target), "levels": levels}
        stamp.write_text(json.dumps(state, indent=2))
        log(f"{clip.id}: built in {time.monotonic() - t0:.0f}s")

    work.mkdir(parents=True, exist_ok=True)
    bad, measured = verify.check(clip, target, work, levels)
    shutil.rmtree(work)
    if bad:
        raise SystemExit(f"{clip.id}: {target} does not match its spec:\n  - " + "\n  - ".join(bad))
    log(verify.summary(target))
    return entry(clip, target, state["sha256"], levels, measured)


def entry(clip: Clip, path: Path, digest: str, levels: dict | None, measured: dict) -> dict:
    v = clip.video
    color = verify.COLOR[v.signal]
    video = {
        "codec": v.codec, "profile": v.profile, "width": v.width, "height": v.height, "fps": FPS,
        "bitDepth": v.bit_depth, "pixFmt": verify.PIX_FMT[v.bit_depth],
        "colorRange": color["color_range"], "colorSpace": color["color_space"],
        "colorTransfer": color["color_transfer"], "colorPrimaries": color["color_primaries"],
        "dynamicRange": v.dynamic_range,
        "doviProfile": int(v.dovi.split(".")[0]) if v.dovi else None,
    }
    if v.dovi:
        video["doviProfileFull"] = v.dovi
        video["doviLevel"] = measured.get("doviLevel")
        video["doviBlSignalCompatibilityId"] = 0 if v.dovi == "5" else 1
        video["hdr10Fallback"] = v.dovi != "5"
    if v.signal == "hdr10":
        m = MASTERING
        video["hdr10"] = {
            "mastering": {"primaries": m["primaries"], "maxLuminance": m["maxLuminance"],
                          "minLuminance": m["minLuminance"]},
            "maxCll": levels["maxCll"], "maxFall": levels["maxFall"],
        }
    audio = []
    for i, a in enumerate(clip.audio, 1):
        audio.append({
            "mpvId": i, "codec": a.codec, "profile": a.profile, "channels": a.channels, "channelLayout": a.layout,
            "sampleRate": a.sample_rate, "bitsPerSample": a.bits, "language": a.language,
            "languageLegacy": a.language_legacy, "title": a.title, "default": a.default, "forced": False,
            "commentary": a.commentary, "original": a.original,
            "tonesHz": list(a.tones) if a.tones else None,
        })
    subs = []
    for i, t in enumerate(clip.subtitles, 1):
        subs.append({
            "mpvId": i, "codec": t.codec, "language": t.language, "languageLegacy": t.language_legacy,
            "title": t.title, "default": t.default, "forced": t.forced, "hearingImpaired": t.hearing_impaired,
            "events": t.events,
        })
    source = None
    for a in clip.audio:
        if a.download:
            d = a.download
            source = {"track": "audio", "url": d.url, "sha256": d.sha256, "size": d.size, "origin": d.origin,
                      "terms": d.terms, "trimSeconds": round(a.trim_seconds, 3)}
    return {
        "id": clip.id, "file": clip.file, "path": f"matrix/{clip.file}", "exercises": clip.exercises,
        "size": path.stat().st_size, "sha256": digest, "durationSeconds": measured["durationSeconds"],
        "bitRate": measured["bitRate"], "video": video, "audio": audio, "subtitles": subs,
        "chapters": [{"title": name, "startSeconds": start} for start, name in clip.chapters],
        "source": source,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--out", type=Path, required=True, help="directory the media server serves as matrix/")
    ap.add_argument("--work", type=Path, required=True, help="scratch directory (downloads, build state)")
    ap.add_argument("--force", action="store_true", help="rebuild every file")
    ap.add_argument("--only", nargs="+", help="build and verify only these ids (matrix.json keeps the others)")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    args.work.mkdir(parents=True, exist_ok=True)

    versions = tool_versions() | encoder_versions(args.work)
    log("tools: " + ", ".join(f"{k} {v}" for k, v in versions.items()))
    previous = json.loads(MATRIX_JSON.read_text()) if MATRIX_JSON.exists() else {"files": []}
    old = {f["id"]: f for f in previous.get("files", [])}
    ids = set(args.only or [c.id for c in CLIPS])
    unknown = ids - {c.id for c in CLIPS}
    if unknown:
        raise SystemExit(f"unknown ids: {sorted(unknown)}")

    files = []
    for clip in CLIPS:
        if clip.id in ids:
            files.append(build_clip(clip, args.out, args.work, versions, args.force))
        elif clip.id in old:
            files.append(old[clip.id])
    changed = [f["id"] for f in files if f["id"] in old and old[f["id"]]["sha256"] != f["sha256"]]

    matrix = {
        "schema": 1,
        "about": "Plezy playback matrix. Generated by tools/media/make-matrix.sh; each "
                 "file was checked against these values with ffprobe after muxing. Languages: `language` is the "
                 "BCP 47 tag mpv reports (Matroska LanguageBCP47), `languageLegacy` the ISO 639-2 code FFmpeg "
                 "reports. `mpvId` is mpv's per-type track id. Generated clips beep (1 kHz, 125 ms) at every whole "
                 "second while the white A/V sync square is lit; the other tones identify the channels.",
        "generator": versions,
        "files": files,
    }
    MATRIX_JSON.write_text(json.dumps(matrix, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    log(f"wrote {MATRIX_JSON} ({len(files)} files)")
    if changed:
        log("note: bytes changed since the previous matrix.json for: " + ", ".join(changed))


if __name__ == "__main__":
    sys.exit(main())
