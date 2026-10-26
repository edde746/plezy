#!/usr/bin/env python3
"""Generate PlezyNG-branded default icons and update the vector icon sources."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

from ng_brand_badge import Bounds, overlay_badge, svg_with_badge

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets"
DEFAULT_ART_BOUNDS = Bounds(0, 38.14, 335.65, 387.58)

ANDROID_DEFAULT_ICONS = [
    ROOT / "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
    ROOT / "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
    ROOT / "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
    ROOT / "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
    ROOT / "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
]
ANDROID_TV_BANNERS = [
    ROOT / "android/app/src/main/res/drawable-xhdpi/tv_banner.png",
    ROOT / "android/app/src/main/res/drawable-xxhdpi/tv_banner.png",
    ROOT / "android/app/src/main/res/drawable-xxxhdpi/tv_banner.png",
]
TVOS_FRONT_ART = [
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack/Front.imagestacklayer/Content.imageset/Front.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack/Front.imagestacklayer/Content.imageset/Front@2x.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon - App Store.imagestack/Front.imagestacklayer/Content.imageset/Front.png",
]
TVOS_TOP_SHELF = [
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/Top Shelf Image.imageset/top-shelf.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/Top Shelf Image Wide.imageset/top-shelf-wide.png",
]
ANDROID_VECTOR_BADGE = """        <!-- PlezyNG lower-right brand badge. -->
        <group android:translateX="171.18" android:translateY="323.04" android:scaleX="3.4964" android:scaleY="3.4964">
            <path android:fillColor="#FF131928" android:pathData="M8,0H36A8,8 0,0 1,44 8V18A8,8 0,0 1,36 26H8A8,8 0,0 1,0 18V8A8,8 0,0 1,8 0Z" />
            <path android:fillColor="#00131928" android:strokeColor="#38FFFFFF" android:strokeWidth="2" android:pathData="M8,1H36A7,7 0,0 1,43 8V18A7,7 0,0 1,36 25H8A7,7 0,0 1,1 18V8A7,7 0,0 1,8 1Z" />
            <group android:translateX="6" android:translateY="20" android:scaleY="-1">
                <path android:fillColor="#FFFFFFFF" android:pathData="M14.459,0 L10.619,0 L4.4,10.8 L4.319,10.8 Q4.359,9.781 4.409,8.759 Q4.459,7.741 4.5,6.719 L4.5,0 L1.8,0 L1.8,14.281 L5.619,14.281 L11.819,3.581 L11.881,3.581 Q11.859,4.581 11.819,5.559 Q11.781,6.541 11.741,7.519 L11.741,14.281 L14.459,14.281 Z M23.479,8.019 L29.141,8.019 L29.141,0.619 Q28.019,0.241 26.81,0.019 Q25.601,-0.2 24.06,-0.2 Q20.86,-0.2 19.138,1.678 Q17.419,3.559 17.419,7.159 Q17.419,9.4 18.288,11.041 Q19.16,12.681 20.819,13.581 Q22.479,14.481 24.879,14.481 Q26.019,14.481 27.119,14.241 Q28.219,14 29.119,13.6 L28.119,11.181 Q27.46,11.519 26.619,11.738 Q25.779,11.959 24.86,11.959 Q23.541,11.959 22.569,11.359 Q21.601,10.759 21.069,9.669 Q20.541,8.581 20.541,7.1 Q20.541,5.7 20.919,4.619 Q21.301,3.541 22.119,2.928 Q22.941,2.319 24.26,2.319 Q24.901,2.319 25.351,2.378 Q25.801,2.441 26.179,2.519 L26.179,5.5 L23.479,5.5 L23.479,8.019 Z" />
            </group>
        </group>
"""


def _tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"error: {name} is required to generate PlezyNG branding assets")
    return path


def _run(*args: str) -> None:
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"command failed: {' '.join(args)}\n{result.stderr.strip()}")


def _ensure_svg_badge(path: Path, bounds: Bounds) -> None:
    original = path.read_text()
    branded = svg_with_badge(original, bounds)
    if branded != original:
        path.write_text(branded)


def _ensure_android_vector_badge(path: Path) -> None:
    original = path.read_text()
    if "PlezyNG lower-right brand badge" in original:
        return
    marker = "</path>\n    </group>\n</vector>"
    if marker not in original:
        raise ValueError(f"cannot find the main icon group in {path}")
    path.write_text(original.replace(marker, f"</path>\n{ANDROID_VECTOR_BADGE}    </group>\n</vector>", 1))


def _generate_default_png(magick: str, rsvg: str, scratch: Path) -> None:
    source = ASSETS / "plezy.svg"
    svg = svg_with_badge(source.read_text(), DEFAULT_ART_BOUNDS)
    svg_path = scratch / "plezyng-default.svg"
    output = scratch / "plezyng-default.png"
    svg_path.write_text(svg)
    _run(rsvg, "-w", "1024", "-h", "1024", "-o", str(output), str(svg_path))
    _run(magick, str(output), "-strip", "-define", "png:compression-level=9", str(ASSETS / "plezy.png"))


def _generate_top_shelf(magick: str, rsvg: str, scratch: Path) -> None:
    source = ASSETS / "plezyng_top_shelf.svg"
    for output in TVOS_TOP_SHELF:
        result = subprocess.run(
            [magick, "identify", "-format", "%w %h", str(output)],
            capture_output=True,
            text=True,
            check=True,
        )
        width, height = (int(value) for value in result.stdout.split())
        rendered = scratch / f"{output.stem}-{width}x{height}.png"
        _run(rsvg, "-w", str(width), "-h", str(height), "-o", str(rendered), str(source))
        shutil.copyfile(rendered, output)


def main() -> None:
    magick = _tool("magick")
    rsvg = _tool("rsvg-convert")
    with tempfile.TemporaryDirectory(prefix="plezyng-brand-assets-") as temporary:
        scratch = Path(temporary)
        _ensure_svg_badge(ASSETS / "plezy_adaptive_foreground.svg", DEFAULT_ART_BOUNDS)
        _ensure_svg_badge(ROOT / "ios/plezy.icon/Assets/plezy-cropped.svg", DEFAULT_ART_BOUNDS)
        _ensure_svg_badge(ROOT / "macos/plezy.icon/Assets/plezy-cropped.svg", DEFAULT_ART_BOUNDS)
        _ensure_android_vector_badge(ROOT / "android/app/src/main/res/drawable/ic_launcher_foreground.xml")

        _generate_default_png(magick, rsvg, scratch)

        bitmap_targets = [
            *ANDROID_DEFAULT_ICONS,
            *TVOS_FRONT_ART,
            *(ROOT / "windows/msix/assets").glob("*.png"),
            ROOT / "windows/runner/resources/app_icon.ico",
        ]
        for target in sorted(bitmap_targets):
            overlay_badge(magick, rsvg, target, target, scratch)

        for target in ANDROID_TV_BANNERS:
            overlay_badge(magick, rsvg, target, target, scratch, use_orange_bounds=True)

        _generate_top_shelf(magick, rsvg, scratch)
    print("Generated branded default icon, splash, store and TV launch artwork.")


if __name__ == "__main__":
    main()
