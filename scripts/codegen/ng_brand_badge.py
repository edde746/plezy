"""Shared PlezyNG corner-badge geometry for rendered artwork and icon codegen."""

from __future__ import annotations

import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BADGE_SOURCE = ROOT / "assets/plezy_ng_badge.svg"
BADGE_MARKER = 'data-ng-brand-badge="true"'
REFERENCE_CANVAS = 96.0


@dataclass(frozen=True)
class Bounds:
    left: float
    top: float
    width: float
    height: float


def _badge_contents() -> str:
    svg = BADGE_SOURCE.read_text()
    opening = svg.find(">")
    closing = svg.rfind("</svg>")
    if opening < 0 or closing < opening:
        raise ValueError(f"{BADGE_SOURCE} is not an SVG document")
    return svg[opening + 1 : closing].strip()


def badge_group(bounds: Bounds) -> str:
    """Place the 44x26 NG badge at the lower-right of an artwork bounding box."""
    scale = bounds.width / REFERENCE_CANVAS
    x = bounds.left + (49.0 / REFERENCE_CANVAS) * bounds.width
    margin = (3.0 / REFERENCE_CANVAS) * bounds.height
    badge_height = 26.0 * scale
    y = bounds.top + bounds.height - margin - badge_height
    return (
        f'<g {BADGE_MARKER} transform="translate({x:.5f} {y:.5f}) scale({scale:.7f})">'
        f"{_badge_contents()}</g>"
    )


def svg_with_badge(svg: str, bounds: Bounds) -> str:
    """Return [svg] with the branded badge appended as the topmost artwork layer."""
    if BADGE_MARKER in svg:
        return svg
    closing = svg.rfind("</svg>")
    if closing < 0:
        raise ValueError("not an SVG document")
    return f"{svg[:closing]}{badge_group(bounds)}{svg[closing:]}"


def _image_size(magick: str, image: Path) -> tuple[int, int]:
    result = subprocess.run(
        [magick, "identify", "-format", "%w %h", str(image)],
        capture_output=True,
        text=True,
        check=True,
    )
    match = re.fullmatch(r"\s*(\d+)\s+(\d+)\s*", result.stdout)
    if match is None:
        raise ValueError(f"could not read dimensions for {image}: {result.stdout!r}")
    return int(match.group(1)), int(match.group(2))


def alpha_bounds(magick: str, image: Path) -> Bounds:
    """Find the nontransparent artwork bounds without requiring a Python imaging package."""
    width, height = _image_size(magick, image)
    result = subprocess.run(
        [magick, str(image), "-alpha", "extract", "-depth", "8", "gray:-"],
        capture_output=True,
        check=True,
    )
    pixels = result.stdout
    if len(pixels) != width * height:
        raise ValueError(f"unexpected alpha plane size for {image}: {len(pixels)} bytes")

    left, top = width, height
    right = bottom = -1
    for y in range(height):
        row_start = y * width
        row = pixels[row_start : row_start + width]
        first = next((x for x, value in enumerate(row) if value), None)
        if first is None:
            continue
        last = width - 1 - next(x for x, value in enumerate(reversed(row)) if value)
        left = min(left, first)
        right = max(right, last)
        top = min(top, y)
        bottom = max(bottom, y)

    if right < left or bottom < top:
        raise ValueError(f"{image} has no visible artwork")
    return Bounds(left, top, right - left + 1, bottom - top + 1)


def orange_bounds(magick: str, image: Path) -> Bounds:
    """Find Plezy's orange mark in an opaque banner using its brand-color range."""
    width, height = _image_size(magick, image)
    result = subprocess.run(
        [magick, str(image), "-alpha", "off", "-colorspace", "sRGB", "-depth", "8", "RGB:-"],
        capture_output=True,
        check=True,
    )
    pixels = result.stdout
    if len(pixels) != width * height * 3:
        raise ValueError(f"unexpected RGB plane size for {image}: {len(pixels)} bytes")

    left, top = width, height
    right = bottom = -1
    for y in range(height):
        row_start = y * width * 3
        row = pixels[row_start : row_start + width * 3]
        for x in range(width):
            offset = x * 3
            red, green, blue = row[offset : offset + 3]
            if red > 100 and green > 45 and red - green > 35 and blue < 140:
                left = min(left, x)
                right = max(right, x)
                top = min(top, y)
                bottom = max(bottom, y)

    if right < left or bottom < top:
        raise ValueError(f"could not find the orange Plezy mark in {image}")
    return Bounds(left, top, right - left + 1, bottom - top + 1)


def overlay_badge(
    magick: str,
    rsvg_convert: str,
    source: Path,
    output: Path,
    scratch: Path,
    *,
    bounds: Bounds | None = None,
    bounds_from: Path | None = None,
    use_orange_bounds: bool = False,
) -> None:
    """Composite the badge over [source], using [bounds_from] as its logo geometry."""
    output.parent.mkdir(parents=True, exist_ok=True)
    source_width, source_height = _image_size(magick, source)
    reference = bounds_from or source
    art = bounds or (orange_bounds(magick, reference) if use_orange_bounds else alpha_bounds(magick, reference))

    scale = art.width / REFERENCE_CANVAS
    badge_width = max(1, round(44.0 * scale))
    badge_height = max(1, round(26.0 * scale))
    left = round(art.left + (49.0 / REFERENCE_CANVAS) * art.width)
    margin = round((3.0 / REFERENCE_CANVAS) * art.height)
    top = round(art.top + art.height - margin - badge_height)
    left = max(0, min(left, source_width - badge_width))
    top = max(0, min(top, source_height - badge_height))

    badge = scratch / f"badge-{source.stem}-{badge_width}x{badge_height}.png"
    composited = scratch / f"branded-{source.name}"
    rendered = subprocess.run(
        [rsvg_convert, "-w", str(badge_width), "-h", str(badge_height), "-o", str(badge), str(BADGE_SOURCE)],
        capture_output=True,
        text=True,
    )
    if rendered.returncode != 0:
        raise RuntimeError(f"could not render NG badge: {rendered.stderr.strip()}")

    command = [
        magick,
        str(source),
        str(badge),
        "-geometry",
        f"+{left}+{top}",
        "-compose",
        "over",
        "-composite",
        "-strip",
    ]
    if output.suffix.lower() == ".ico":
        command += ["-define", "icon:auto-resize=48"]
    result = subprocess.run(command + [str(composited)], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"could not badge {source}: {result.stderr.strip()}")
    shutil.copyfile(composited, output)
