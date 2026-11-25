"""Blu-ray PGS (HDMV presentation graphics, ``.sup``) writer for the matrix subtitles.

Renders each cue of an SRT file to a bitmap (white text, black outline, Pillow's built-in Aileron font, ASCII only)
and writes one epoch-start display set per cue plus an empty display set at its end time. A cue starting with
``{\\an8}`` sits at the top of the frame, anything else at the bottom. With ``forced`` every composition object
carries the "forced on" flag, the way forced-narrative Blu-ray tracks mark them.

Segment layout follows the HDMV PG stream syntax (as read by FFmpeg's ``pgssubdec`` and mkvmerge): "PG" magic,
90 kHz PTS and DTS, segment type, big-endian length; PCS 0x16, WDS 0x17, PDS 0x14, ODS 0x15, END 0x80. Palette
entries are limited-range BT.709 Y'CrCb plus alpha, index 0 is transparent and the objects are run-length coded.
"""

from __future__ import annotations

import dataclasses
import math
import re
import struct
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

PCS, WDS, PDS, ODS, END = 0x16, 0x17, 0x14, 0x15, 0x80
EPOCH_START, NORMAL = 0x80, 0x00
FORCED_ON = 0x40
MAX_SEGMENT = 0xFFFF


@dataclasses.dataclass(frozen=True)
class Cue:
    start: float
    end: float
    text: str
    top: bool


def parse_srt(path: Path) -> list[Cue]:
    stamp = r"(\d+):(\d\d):(\d\d)[,.](\d{3})"
    timing = re.compile(stamp + r"\s*-->\s*" + stamp)
    cues = []
    for block in re.split(r"\n\s*\n", path.read_text(encoding="utf-8").replace("\r\n", "\n").strip()):
        lines = block.split("\n")
        idx = next(i for i, line in enumerate(lines) if "-->" in line)
        m = timing.search(lines[idx])
        if not m:
            raise ValueError(f"{path}: bad timing line {lines[idx]!r}")
        g = [int(x) for x in m.groups()]
        start = g[0] * 3600 + g[1] * 60 + g[2] + g[3] / 1000
        end = g[4] * 3600 + g[5] * 60 + g[6] + g[7] / 1000
        text = "\n".join(lines[idx + 1:])
        top = text.startswith("{\\an8}")
        text = re.sub(r"\{[^}]*\}|<[^>]*>", "", text)
        if not text.isascii():
            raise ValueError(f"{path}: PGS cues are rendered with an ASCII-only font: {text!r}")
        cues.append(Cue(start, end, text, top))
    for a, b in zip(cues, cues[1:]):
        if b.start < a.end:
            raise ValueError(f"{path}: overlapping cues at {b.start}s (one display set at a time)")
    return cues


def _render(cue: Cue, width: int, height: int, font_size: int):
    """The cue as (x, y, palette indices, palette) with palette entries (Y, Cr, Cb, A)."""
    font = ImageFont.load_default(size=font_size)
    stroke = max(2, font_size // 16)
    probe = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    box = probe.multiline_textbbox((0, 0), cue.text, font=font, align="center", anchor="la",
                                   stroke_width=stroke, spacing=font_size // 4)
    l, t, r, b = math.floor(box[0]), math.floor(box[1]), math.ceil(box[2]), math.ceil(box[3])
    pad = 2
    w, h = r - l + 2 * pad, b - t + 2 * pad
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(img).multiline_text((pad - l, pad - t), cue.text, font=font, fill=(235, 235, 235, 255),
                                       align="center", anchor="la", stroke_width=stroke,
                                       stroke_fill=(16, 16, 16, 255), spacing=font_size // 4)
    rgba = np.asarray(img, dtype=np.int32)
    # 4 bits per channel keeps white-on-black anti-aliasing well under the 255 usable palette entries.
    q = (rgba + 8) // 17
    q[rgba[..., 3] == 0] = 0
    keys = ((q[..., 0] * 16 + q[..., 1]) * 16 + q[..., 2]) * 16 + q[..., 3]
    uniq, inverse = np.unique(keys, return_inverse=True)
    inverse = inverse.reshape(keys.shape)
    if uniq[0] != 0:  # index 0 must be the transparent entry
        uniq = np.concatenate([[0], uniq])
        inverse = inverse + 1
    if len(uniq) > 256:
        raise ValueError(f"cue {cue.text!r} needs {len(uniq)} palette entries")
    palette = []
    for i, key in enumerate(uniq):
        a = key % 16 * 17
        bl = key // 16 % 16 * 17
        g = key // 256 % 16 * 17
        rd = key // 4096 * 17
        palette.append((i, *_ycrcb709(rd, g, bl), a))
    x = (width - w) // 2
    y = int(height * 0.06) if cue.top else height - int(height * 0.08) - h
    return x, y, inverse.astype(np.uint8), palette


def _ycrcb709(r: int, g: int, b: int):
    rn, gn, bn = r / 255, g / 255, b / 255
    y = 0.2126 * rn + 0.7152 * gn + 0.0722 * bn
    cb = (bn - y) / 1.8556
    cr = (rn - y) / 1.5748
    return (round(16 + 219 * y), round(128 + 224 * cr), round(128 + 224 * cb))


def _rle(indices: np.ndarray) -> bytes:
    out = bytearray()
    for row in indices:
        edges = np.flatnonzero(np.diff(row)) + 1
        starts = np.concatenate([[0], edges])
        ends = np.concatenate([edges, [len(row)]])
        for s, e in zip(starts.tolist(), ends.tolist()):
            c = int(row[s])
            run = e - s
            while run > 0:
                n = min(run, 16383)
                if c == 0:
                    out += bytes([0, n]) if n < 64 else bytes([0, 0x40 | (n >> 8), n & 0xFF])
                elif n < 3:
                    out += bytes([c]) * n
                elif n < 64:
                    out += bytes([0, 0x80 | n, c])
                else:
                    out += bytes([0, 0xC0 | (n >> 8), n & 0xFF, c])
                run -= n
        out += b"\x00\x00"
    return bytes(out)


def _segment(kind: int, pts: int, payload: bytes) -> bytes:
    if len(payload) > MAX_SEGMENT:
        raise ValueError("PGS segment too large")
    return b"PG" + struct.pack(">IIBH", pts, 0, kind, len(payload)) + payload


def _pcs(width, height, number, state, objects) -> bytes:
    body = struct.pack(">HHBHBBBB", width, height, 0x10, number & 0xFFFF, state, 0, 0, len(objects))
    for obj_id, flags, x, y in objects:
        body += struct.pack(">HBBHH", obj_id, 0, flags, x, y)
    return body


def _ods(pts: int, w: int, h: int, data: bytes) -> bytes:
    """The object, split over several ODS segments when it doesn't fit one."""
    total = len(data) + 4
    first_room = MAX_SEGMENT - 11
    chunks = [data[:first_room]]
    rest = data[first_room:]
    while rest:
        chunks.append(rest[:MAX_SEGMENT - 4])
        rest = rest[MAX_SEGMENT - 4:]
    out = b""
    for i, chunk in enumerate(chunks):
        flag = (0x80 if i == 0 else 0) | (0x40 if i == len(chunks) - 1 else 0)
        head = struct.pack(">HBB", 0, 0, flag)
        if i == 0:
            head += total.to_bytes(3, "big") + struct.pack(">HH", w, h)
        out += _segment(ODS, pts, head + chunk)
    return out


def write_sup(cues: list[Cue], out: Path, *, width: int = 1920, height: int = 1080, forced: bool = False,
              font_size: int = 56) -> int:
    """Writes the cues as a .sup file; returns the number of display sets that show a cue."""
    data = bytearray()
    number = 0
    for cue in cues:
        x, y, idx, palette = _render(cue, width, height, font_size)
        h, w = idx.shape
        start, end = round(cue.start * 90000), round(cue.end * 90000)
        flags = FORCED_ON if forced else 0
        data += _segment(PCS, start, _pcs(width, height, number, EPOCH_START, [(0, flags, x, y)]))
        data += _segment(WDS, start, struct.pack(">BBHHHH", 1, 0, x, y, w, h))
        data += _segment(PDS, start, struct.pack(">BB", 0, 0) + b"".join(struct.pack(">BBBBB", *e) for e in palette))
        data += _ods(start, w, h, _rle(idx))
        data += _segment(END, start, b"")
        number += 1
        data += _segment(PCS, end, _pcs(width, height, number, NORMAL, []))
        data += _segment(WDS, end, struct.pack(">BBHHHH", 1, 0, x, y, w, h))
        data += _segment(END, end, b"")
        number += 1
    out.write_bytes(bytes(data))
    return len(cues)
