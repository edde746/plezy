"""Test-pattern video for the playback matrix, rendered straight into the signal an encoder expects.

Every clip shows the same layout: a title naming the file, colour bars, primaries, a grey-step row, a ramp, a box
sweeping across the frame every four seconds, an A/V sync square that lights for the first 125 ms of each second
(the audio beeps at the same time) and a running timecode with the frame number. A clip given its chapters also
names the chapter playing at the top right, with its number and span.

Three signal kinds:
- ``sdr``: BT.709 primaries, gamma 2.4, limited-range BT.709 Y'CbCr (8- or 10-bit).
- ``hdr10``: BT.2020 primaries, PQ, limited-range BT.2020 non-constant-luminance Y'CbCr (10-bit). Graphics white
  sits at 203 cd/m² (ITU-R BT.2408); the grey steps and the ramp reach 1000 cd/m².
- ``dvp5``: Dolby Vision profile 5 base layer: full-range IPTPQc2 (10-bit) matching the default profile 5 RPU that
  ``dovi_tool generate -p 5`` writes (identity reshaping, the RPU's ``ycc_to_rgb`` and ``rgb_to_lms`` matrices).
  A player that applies the RPU shows the same picture as the ``hdr10`` clip; one that treats the base layer as
  ordinary Y'CbCr shows it green and purple.

Frames are written as raw planar 4:2:0 (``yuv420p`` or ``yuv420p10le``).
"""

from __future__ import annotations

import bisect
import dataclasses
import math
from typing import BinaryIO

import numpy as np
from PIL import Image, ImageDraw, ImageFont

FPS_NUM, FPS_DEN = 24000, 1001
SDR_WHITE_NITS = 100.0
HDR_WHITE_NITS = 203.0
HDR_PEAK_NITS = 1000.0

# SMPTE ST 2084 (PQ) constants.
_M1, _M2 = 2610 / 16384, 2523 / 4096 * 128
_C1, _C2, _C3 = 3424 / 4096, 2413 / 4096 * 32, 2392 / 4096 * 32


def pq_oetf(nits):
    """Absolute luminance (cd/m²) to the PQ signal in [0, 1]."""
    y = np.clip(np.asarray(nits, dtype=np.float64) / 10000.0, 0.0, 1.0) ** _M1
    return ((_C1 + _C2 * y) / (1.0 + _C3 * y)) ** _M2


def pq_eotf(signal):
    """PQ signal in [0, 1] to absolute luminance (cd/m²)."""
    e = np.clip(np.asarray(signal, dtype=np.float64), 0.0, 1.0) ** (1.0 / _M2)
    return 10000.0 * (np.maximum(e - _C1, 0.0) / (_C2 - _C3 * e)) ** (1.0 / _M1)


def _rgb_to_xyz(primaries, white):
    """RGB → XYZ matrix for the given xy chromaticities."""
    def xyz(x, y):
        return np.array([x / y, 1.0, (1.0 - x - y) / y])

    m = np.stack([xyz(*p) for p in primaries], axis=1)
    s = np.linalg.solve(m, xyz(*white))
    return m * s


D65 = (0.3127, 0.3290)
BT709 = ((0.640, 0.330), (0.300, 0.600), (0.150, 0.060))
P3 = ((0.680, 0.320), (0.265, 0.690), (0.150, 0.060))
BT2020 = ((0.708, 0.292), (0.170, 0.797), (0.131, 0.046))
_XYZ_TO_2020 = np.linalg.inv(_rgb_to_xyz(BT2020, D65))
GAMUT_TO_2020 = {
    "bt709": _XYZ_TO_2020 @ _rgb_to_xyz(BT709, D65),
    "p3": _XYZ_TO_2020 @ _rgb_to_xyz(P3, D65),
    "bt2020": np.eye(3),
}

# Dolby Vision profile 5 colour metadata, exactly as `dovi_tool generate -p 5` writes it (and as the RPU of real
# profile 5 encodes carries it): ycc_to_rgb coefficients / 2^13, offsets / 2^28, rgb_to_lms coefficients / 2^14.
DV_YCC_TO_RGB = np.array([[8192, 799, 1681], [8192, -933, 1091], [8192, 267, -5545]], dtype=np.float64) / 8192
DV_YCC_TO_RGB_OFFSET = np.array([0.0, 134217728, 134217728]) / (1 << 28)
DV_RGB_TO_LMS = np.array([[17081, -349, -349], [-349, 17081, -349], [-349, -349, 17081]], dtype=np.float64) / 16384
# Players (libplacebo) convert the RPU's LMS back to RGB through the BT.2020 Hunt-Pointer-Estevez LMS matrix.
DV_HPE_LMS_TO_2020 = np.array([
    [3.06441879, -2.16597676, 0.10155818],
    [-0.65612108, 1.78554118, -0.12943749],
    [0.01736321, -0.04725154, 1.03004253],
])
_DV_2020_TO_LMS = np.linalg.inv(DV_HPE_LMS_TO_2020 @ DV_RGB_TO_LMS)
_DV_LMS_TO_IPT = np.linalg.inv(DV_YCC_TO_RGB)

KIND_GAMUT = {"sdr": "bt709", "hdr10": "bt2020", "dvp5": "bt2020"}


@dataclasses.dataclass(frozen=True)
class Signal:
    kind: str  # sdr | hdr10 | dvp5
    bit_depth: int

    def __post_init__(self):
        if self.kind not in KIND_GAMUT:
            raise ValueError(f"unknown signal kind {self.kind}")
        if self.kind != "sdr" and self.bit_depth != 10:
            raise ValueError(f"{self.kind} is 10-bit only")

    @property
    def white_nits(self) -> float:
        return SDR_WHITE_NITS if self.kind == "sdr" else HDR_WHITE_NITS

    @property
    def pix_fmt(self) -> str:
        return "yuv420p" if self.bit_depth == 8 else "yuv420p10le"

    def encode(self, lin):
        """Linear light (cd/m², container primaries) → code values (…, 3) normalised so that 1.0 is the top code
        (2^n − 1); `quantize` rounds them to integers."""
        lin = np.asarray(lin, dtype=np.float64)
        if self.kind == "sdr":
            rgb = np.clip(lin / SDR_WHITE_NITS, 0.0, 1.0) ** (1 / 2.4)
            return self._limited(*_ycbcr(rgb, 0.2126, 0.0722))
        if self.kind == "hdr10":
            return self._limited(*_ycbcr(pq_oetf(lin), 0.2627, 0.0593))
        # Full range: libplacebo reads the base layer as code / (2^n − 1).
        lms = pq_oetf(np.maximum(lin @ _DV_2020_TO_LMS.T, 0.0))
        ipt = lms @ _DV_LMS_TO_IPT.T + DV_YCC_TO_RGB_OFFSET
        return np.clip(ipt, 0.0, 1.0)

    def _limited(self, y, cb, cr):
        # Limited ("TV") range: Y 16..235, C 16..240 at 8 bits, shifted left for deeper samples (64..940 at 10).
        scale = (1 << (self.bit_depth - 8)) / ((1 << self.bit_depth) - 1)
        return np.stack([16 + 219 * y, 128 + 224 * cb, 128 + 224 * cr], axis=-1) * scale

    def quantize(self, code):
        top = (1 << self.bit_depth) - 1
        return np.clip(np.rint(code * top), 0, top).astype(np.uint8 if self.bit_depth == 8 else "<u2")


def _ycbcr(rgb, kr, kb):
    kg = 1.0 - kr - kb
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    y = kr * r + kg * g + kb * b
    return y, (b - y) / (2 * (1 - kb)), (r - y) / (2 * (1 - kr))


@dataclasses.dataclass(frozen=True)
class Layout:
    """The pattern's geometry, designed on a 1920×1080 grid and scaled to the output size."""

    width: int
    height: int

    @property
    def s(self) -> float:
        return self.width / 1920

    def px(self, v: float) -> int:
        return int(round(v * self.s))

    def even(self, v: float) -> int:
        return 2 * int(round(v * self.s / 2))


class Pattern:
    """Renders one clip's frames. ``title`` and ``lines`` label the picture (ASCII only; the built-in font is
    Pillow's Aileron subset); ``chapters`` (start seconds and name, in order), if given, add the chapter label."""

    def __init__(self, signal: Signal, width: int, height: int, frames: int, title: str, lines: list[str],
                 chapters: tuple[tuple[float, str], ...] = ()):
        self.signal = signal
        self.lay = Layout(width, height)
        self.frames = frames
        self.width, self.height = width, height
        self._font_cache: dict[int, ImageFont.FreeTypeFont] = {}
        self.chapters = chapters
        self.gamut_to_container = (
            GAMUT_TO_2020 if signal.kind != "sdr" else {"bt709": np.eye(3)}
        )
        self.bg = self._rel(0.02)
        self.strip_bg = self._rel(0.06)
        self.white = self._rel(1.0)
        self.grey = self._rel(0.45)
        self._build_static(title, lines)
        self._dynamic_setup()

    # -- colours ---------------------------------------------------------------------------------------------

    def _rel(self, level, rgb=(1.0, 1.0, 1.0), gamut="bt709"):
        """A colour at `level` × reference white, in linear cd/m² of the container primaries."""
        lin = np.asarray(rgb, dtype=np.float64) * level * self.signal.white_nits
        return self.gamut_to_container[gamut] @ lin

    def _font(self, size_ref: float) -> ImageFont.FreeTypeFont:
        size = max(8, self.lay.px(size_ref))
        if size not in self._font_cache:
            self._font_cache[size] = ImageFont.load_default(size=size)
        return self._font_cache[size]

    # -- static layer ----------------------------------------------------------------------------------------

    def _build_static(self, title: str, lines: list[str]):
        if len(lines) > 3:
            raise ValueError("at most three description lines fit above the bars")
        lay, sig = self.lay, self.signal
        lin = np.empty((self.height, self.width, 3), dtype=np.float64)
        lin[:] = self.bg
        # One text mask per text colour, composited over the drawn layer at the end.
        masks = {"white": Image.new("L", (self.width, self.height)), "grey": Image.new("L", (self.width, self.height))}
        draws = {k: ImageDraw.Draw(v) for k, v in masks.items()}

        def rect(x0, y0, x1, y1, color):
            lin[lay.px(y0):lay.px(y1), lay.px(x0):lay.px(x1)] = color

        def text(x, y, s, size, color="grey", anchor="la"):
            draws[color].text((lay.px(x), lay.px(y)), s, font=self._font(size), fill=255, anchor=anchor)

        # The pattern keeps to y = 118..850 (of 1080): the bands above and below stay free for subtitles.
        text(80, 124, title, 40, "white")
        for i, line in enumerate(lines):
            text(80, 172 + 28 * i, line, 24)

        # 75 % colour bars (75 % signal on an SDR display, i.e. linear 0.75^2.4 of reference white), each named
        # underneath so that a wrong colour conversion is visible without a reference picture.
        bars = [("white", (1, 1, 1)), ("yellow", (1, 1, 0)), ("cyan", (0, 1, 1)), ("green", (0, 1, 0)),
                ("magenta", (1, 0, 1)), ("red", (1, 0, 0)), ("blue", (0, 0, 1))]
        x0, x1, y0, y1 = 80, 1840, 264, 348
        w = (x1 - x0) / len(bars)
        for i, (label, c) in enumerate(bars):
            rect(x0 + i * w, y0, x0 + (i + 1) * w, y1, self._rel(0.75 ** 2.4, c))
            text(x0 + (i + 0.5) * w, y1 + 6, label, 20, anchor="ma")

        # Primaries at reference white: BT.709 always, Display P3 in the HDR clips (outside BT.709).
        if sig.kind == "sdr":
            patches = [("709 R", (1, 0, 0), "bt709"), ("709 G", (0, 1, 0), "bt709"), ("709 B", (0, 0, 1), "bt709"),
                       ("709 C", (0, 1, 1), "bt709"), ("709 M", (1, 0, 1), "bt709"), ("709 Y", (1, 1, 0), "bt709")]
        else:
            patches = [("709 R", (1, 0, 0), "bt709"), ("709 G", (0, 1, 0), "bt709"), ("709 B", (0, 0, 1), "bt709"),
                       ("P3 R", (1, 0, 0), "p3"), ("P3 G", (0, 1, 0), "p3"), ("P3 B", (0, 0, 1), "p3")]
        y0, y1 = 388, 456
        w = (x1 - x0) / len(patches)
        for i, (label, c, gamut) in enumerate(patches):
            rect(x0 + i * w + 6, y0, x0 + (i + 1) * w - 6, y1, self._rel(1.0, c, gamut))
            text(x0 + (i + 0.5) * w, y1 + 6, label, 20, anchor="ma")

        # Grey steps: cd/m² in HDR, percent of signal in SDR.
        if sig.kind == "sdr":
            steps = [(f"{p}%", SDR_WHITE_NITS * (p / 100) ** 2.4) for p in range(0, 101, 10)]
        else:
            steps = [(f"{n:g}", float(n)) for n in (0, 0.1, 1, 10, 50, 100, 203, 400, 600)] + [("1000 cd/m2", 1000.0)]
        y0, y1 = 498, 570
        w = (x1 - x0) / len(steps)
        for i, (label, nits) in enumerate(steps):
            rect(x0 + i * w, y0, x0 + (i + 1) * w, y1, np.full(3, nits))
            text(x0 + (i + 0.5) * w, y1 + 6, label, 20, anchor="ma")

        # Ramp, uniform in signal: 0..100 % (SDR) or PQ 0..1000 cd/m² (HDR).
        y0, y1 = 610, 644
        cols = np.arange(lay.px(x0), lay.px(x1))
        t = (cols - cols[0]) / max(1, len(cols) - 1)
        if sig.kind == "sdr":
            nits = SDR_WHITE_NITS * t ** 2.4
        else:
            nits = pq_eotf(t * pq_oetf(HDR_PEAK_NITS))
        lin[lay.px(y0):lay.px(y1), cols[0]:cols[-1] + 1] = nits[None, :, None]
        text(x0, y1 + 6, "0", 20)
        text(x1, y1 + 6, "100%" if sig.kind == "sdr" else "1000 cd/m2", 20, anchor="ra")

        # Motion strip background and the A/V sync label.
        rect(x0, 690, x1, 730, self.strip_bg)
        text(1716, 796, "A/V sync", 22, anchor="rm")

        for key, color in (("white", self.white), ("grey", self.grey)):
            a = np.asarray(masks[key], dtype=np.float64)[..., None] / 255.0
            lin = lin * (1 - a) + color * a
        self.static_lin = lin
        self.static_code = signal_encode_image(self.signal, lin)
        self.static_planes = _subsample(self.signal, self.static_code)
        self.static_maxrgb = lin.max(axis=-1)

    # -- dynamic elements ------------------------------------------------------------------------------------

    def _dynamic_setup(self):
        lay = self.lay
        # Regions are even-aligned so that they map onto whole chroma samples.
        self.strip = (lay.even(80), lay.even(690), lay.even(1840), lay.even(730))
        self.box = lay.even(36)
        self.flash = (lay.even(1740), lay.even(756), lay.even(1840), lay.even(836))
        self.clock = (lay.even(80), lay.even(752), lay.even(1200), lay.even(840))
        self.clock_font = self._font(40)
        self.white_code = signal_encode_image(self.signal, self.white[None, None, :])[0, 0]
        # The chapter label, beside the title: one mask per chapter, drawn once.
        self.chapter = (lay.even(1000), lay.even(118), lay.even(1840), lay.even(258))
        self.chapter_starts = [start for start, _ in self.chapters]
        self.chapter_masks = [self._chapter_mask(i) for i in range(len(self.chapters))]

    def _chapter_mask(self, i: int) -> np.ndarray:
        """Chapter i's label, right-aligned: its name, and under it its number and span (mm:ss to mm:ss)."""
        x0, y0, x1, y1 = self.chapter
        start, name = self.chapters[i]
        end = self.chapters[i + 1][0] if i + 1 < len(self.chapters) else self.frames * FPS_DEN / FPS_NUM
        img = Image.new("L", (x1 - x0, y1 - y0))
        draw = ImageDraw.Draw(img)
        draw.text((x1 - x0, self.lay.px(6)), name, font=self._font(72), fill=255, anchor="ra")
        span = f"Chapter {i + 1} of {len(self.chapters)}  ·  {mmss(start)} to {mmss(end)}"
        draw.text((x1 - x0, self.lay.px(100)), span, font=self._font(28), fill=255, anchor="ra")
        return np.asarray(img, dtype=np.float64) / 255.0

    def _masks(self, n: int):
        """Per-region alpha masks (region, mask) for frame n."""
        period = 4 * FPS_NUM / FPS_DEN
        x0, y0, x1, y1 = self.strip
        strip = np.zeros((y1 - y0, x1 - x0))
        travel = (x1 - x0) - self.box
        pos = int(round(travel * ((n % period) / period)))
        pad = (y1 - y0 - self.box) // 2
        strip[pad:pad + self.box, pos:pos + self.box] = 1.0

        fx0, fy0, fx1, fy1 = self.flash
        t = n * FPS_DEN / FPS_NUM
        lit = (t - math.floor(t)) < 0.125
        flash = np.full((fy1 - fy0, fx1 - fx0), 1.0 if lit else 0.0)

        cx0, cy0, cx1, cy1 = self.clock
        img = Image.new("L", (cx1 - cx0, cy1 - cy0))
        ImageDraw.Draw(img).text((0, (cy1 - cy0) // 2), clock_text(n, self.frames), font=self.clock_font,
                                 fill=255, anchor="lm")
        clock = np.asarray(img, dtype=np.float64) / 255.0
        regions = [(self.strip, strip), (self.flash, flash), (self.clock, clock)]
        playing = bisect.bisect_right(self.chapter_starts, t) - 1
        if playing >= 0:
            regions.append((self.chapter, self.chapter_masks[playing]))
        return regions

    def write_frame(self, n: int, out: BinaryIO):
        y, u, v = (p.copy() for p in self.static_planes)
        for (x0, y0, x1, y1), mask in self._masks(n):
            base = self.static_code[y0:y1, x0:x1]
            code = base * (1 - mask[..., None]) + self.white_code * mask[..., None]
            ry, ru, rv = _subsample(self.signal, code)
            y[y0:y1, x0:x1] = ry
            u[y0 // 2:y1 // 2, x0 // 2:x1 // 2] = ru
            v[y0 // 2:y1 // 2, x0 // 2:x1 // 2] = rv
        out.write(y.tobytes())
        out.write(u.tobytes())
        out.write(v.tobytes())

    def light_levels(self):
        """MaxCLL and MaxFALL (cd/m², CTA-861.3: per-pixel max(R,G,B)) and the Dolby Vision L1 values
        (12-bit PQ min / max / mean of max(R,G,B)) over all frames."""
        n_px = self.width * self.height
        base_sum = self.static_maxrgb.sum()
        base_pq = pq_oetf(self.static_maxrgb)
        base_pq_sum = base_pq.sum()
        max_cll = self.static_maxrgb.max()
        min_nits = self.static_maxrgb.min()
        max_fall = 0.0
        max_avg_pq = 0.0
        for n in range(self.frames):
            s, spq = base_sum, base_pq_sum
            for (x0, y0, x1, y1), mask in self._masks(n):
                lin = self.static_lin[y0:y1, x0:x1] * (1 - mask[..., None]) + self.white * mask[..., None]
                m = lin.max(axis=-1)
                s += m.sum() - self.static_maxrgb[y0:y1, x0:x1].sum()
                spq += pq_oetf(m).sum() - base_pq[y0:y1, x0:x1].sum()
                max_cll = max(max_cll, m.max())
                min_nits = min(min_nits, m.min())
            max_fall = max(max_fall, s / n_px)
            max_avg_pq = max(max_avg_pq, spq / n_px)
        return {
            "maxCll": int(math.ceil(max_cll - 1e-6)),
            "maxFall": int(math.ceil(max_fall)),
            "l1": {
                "min_pq": int(round(float(pq_oetf(min_nits)) * 4095)),
                "max_pq": int(round(float(pq_oetf(max_cll)) * 4095)),
                "avg_pq": int(round(max_avg_pq * 4095)),
            },
        }


def clock_text(n: int, frames: int) -> str:
    ms = n * FPS_DEN * 1000 // FPS_NUM
    h, rem = divmod(ms, 3_600_000)
    m, rem = divmod(rem, 60_000)
    s, ms = divmod(rem, 1000)
    return f"{h:02d}:{m:02d}:{s:02d}.{ms:03d}  ·  frame {n + 1:04d} / {frames:04d}"


def mmss(seconds: float) -> str:
    s = int(seconds)
    return f"{s // 60:02d}:{s % 60:02d}"


def signal_encode_image(signal: Signal, lin: np.ndarray) -> np.ndarray:
    return signal.encode(lin).astype(np.float32)


def _subsample(signal: Signal, code: np.ndarray):
    """Full-resolution normalised code values → quantised Y plane and 2×2-averaged chroma planes."""
    y = signal.quantize(code[..., 0])
    h, w = code.shape[0] // 2 * 2, code.shape[1] // 2 * 2
    c = code[:h, :w, 1:].reshape(h // 2, 2, w // 2, 2, 2).mean(axis=(1, 3))
    return y, signal.quantize(c[..., 0]), signal.quantize(c[..., 1])
