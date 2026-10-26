#!/usr/bin/env python3
"""Generate PlezyNG's primary app icons and launch artwork from its approved PNG."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets"
APP_ICON_SOURCE = ASSETS / "plezyng-app-icon.png"
ICON_BACKGROUND = "#131928"

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
ANDROID_ADAPTIVE_DENSITIES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}

TVOS_FRONT_ART = [
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack/Front.imagestacklayer/Content.imageset/Front.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack/Front.imagestacklayer/Content.imageset/Front@2x.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon - App Store.imagestack/Front.imagestacklayer/Content.imageset/Front.png",
]
TVOS_MIDDLE_ART = [
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack/Middle.imagestacklayer/Content.imageset/Middle.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack/Middle.imagestacklayer/Content.imageset/Middle@2x.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon - App Store.imagestack/Middle.imagestacklayer/Content.imageset/Middle.png",
]
TVOS_BACK_ART = [
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack/Back.imagestacklayer/Content.imageset/Back.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack/Back.imagestacklayer/Content.imageset/Back@2x.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon - App Store.imagestack/Back.imagestacklayer/Content.imageset/Back.png",
]
TVOS_TOP_SHELF = [
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/Top Shelf Image.imageset/top-shelf.png",
    ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/Top Shelf Image Wide.imageset/top-shelf-wide.png",
]
WINDOWS_MSIX_ASSETS = ROOT / "windows/msix/assets"
WINDOWS_RUNNER_ICON = ROOT / "windows/runner/resources/app_icon.ico"


def _tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"error: {name} is required to generate PlezyNG branding assets")
    return path


def _run(*args: str) -> None:
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"command failed: {' '.join(args)}\n{result.stderr.strip()}")


def _dimensions(magick: str, image: Path) -> tuple[int, int]:
    result = subprocess.run(
        [magick, "identify", "-format", "%w %h", str(image)],
        capture_output=True,
        text=True,
        check=True,
    )
    width, height = (int(value) for value in result.stdout.split())
    return width, height


def _clean_source(magick: str, scratch: Path) -> Path:
    """Clear the supplied artwork's faint red matting pixels around transparent edges."""
    cleaned = scratch / "plezyng-app-icon-clean.png"
    _run(
        magick,
        str(APP_ICON_SOURCE),
        "-channel",
        "A",
        "-fx",
        "a<0.125?0:a",
        "+channel",
        "-strip",
        str(cleaned),
    )
    return cleaned


def _fit_art(
    magick: str,
    source: Path,
    output: Path,
    width: int,
    height: int,
    *,
    scale: float = 1.0,
    background: str = "none",
) -> None:
    target_width = max(1, round(width * scale))
    target_height = max(1, round(height * scale))
    output.parent.mkdir(parents=True, exist_ok=True)
    command = [
        magick,
        str(source),
        "-resize",
        f"{target_width}x{target_height}",
        "-gravity",
        "center",
        "-background",
        background,
        "-extent",
        f"{width}x{height}",
    ]
    if background != "none":
        command.extend(["-background", background, "-alpha", "remove", "-alpha", "off"])
    command.extend(["-strip", str(output)])
    _run(*command)


def _generate_app_icon_composer_sources(magick: str, source: Path) -> None:
    for platform in ("ios", "macos"):
        icon_dir = ROOT / platform / "plezy.icon"
        image_name = "plezyng-app-icon.png"
        output = icon_dir / "Assets" / image_name
        _fit_art(magick, source, output, 1024, 1024, background=ICON_BACKGROUND)

        icon_json = icon_dir / "icon.json"
        contents = icon_json.read_text()
        contents = contents.replace('"image-name" : "plezy-cropped.svg"', f'"image-name" : "{image_name}"')
        contents = contents.replace('"glass" : true', '"glass" : false')
        icon_json.write_text(contents)


def _generate_android_icons(magick: str, source: Path) -> None:
    for output in ANDROID_DEFAULT_ICONS:
        size = _dimensions(magick, output)[0]
        _fit_art(magick, source, output, size, size, background=ICON_BACKGROUND)

    # Android's adaptive icon foreground must keep all of the artwork inside the
    # central 66dp safe circle of the 108dp canvas.
    for density, size in ANDROID_ADAPTIVE_DENSITIES.items():
        foreground = ROOT / f"android/app/src/main/res/drawable-{density}/plezyng_launcher_foreground.png"
        _fit_art(magick, source, foreground, size, size, scale=66 / 108)

    subprocess.run(["bash", str(ROOT / "scripts/codegen/generate_android_icons.sh")], check=True)

    for output in ANDROID_TV_BANNERS:
        width, height = _dimensions(magick, output)
        _fit_art(magick, source, output, width, height, scale=0.88, background=ICON_BACKGROUND)


def _generate_windows_icons(magick: str, source: Path, scratch: Path) -> None:
    altform_light = scratch / "plezyng-windows-altform-light.png"
    altform_dark = scratch / "plezyng-windows-altform-dark.png"
    for output, color in ((altform_light, "black"), (altform_dark, "white")):
        _run(
            magick,
            str(source),
            "-fuzz",
            "12%",
            "-transparent",
            ICON_BACKGROUND,
            "-fill",
            color,
            "-colorize",
            "100%",
            "-strip",
            str(output),
        )

    for output in WINDOWS_MSIX_ASSETS.glob("*.png"):
        width, height = _dimensions(magick, output)
        scale = 1.0 if width == height else 0.88
        if "_altform-lightunplated" in output.stem:
            _fit_art(magick, altform_light, output, width, height, scale=scale)
        elif "_altform-" in output.stem:
            _fit_art(magick, altform_dark, output, width, height, scale=scale)
        else:
            _fit_art(magick, source, output, width, height, scale=scale, background=ICON_BACKGROUND)

    _run(
        magick,
        str(source),
        "-background",
        ICON_BACKGROUND,
        "-alpha",
        "remove",
        "-resize",
        "256x256",
        "-define",
        "icon:auto-resize=16,24,32,48,64,128,256",
        str(WINDOWS_RUNNER_ICON),
    )


def _generate_tvos_icons(magick: str, source: Path) -> None:
    for output in TVOS_BACK_ART:
        width, height = _dimensions(magick, output)
        _run(magick, "-size", f"{width}x{height}", f"xc:{ICON_BACKGROUND}", str(output))
    for output in TVOS_MIDDLE_ART:
        width, height = _dimensions(magick, output)
        _run(magick, "-size", f"{width}x{height}", "xc:none", str(output))
    for output in TVOS_FRONT_ART:
        width, height = _dimensions(magick, output)
        _fit_art(magick, source, output, width, height, scale=0.9)


def _generate_top_shelf(magick: str, rsvg: str, scratch: Path) -> None:
    source = ASSETS / "plezyng_top_shelf.svg"
    for output in TVOS_TOP_SHELF:
        width, height = _dimensions(magick, output)
        rendered = scratch / f"{output.stem}-{width}x{height}.png"
        _run(rsvg, "-w", str(width), "-h", str(height), "-o", str(rendered), str(source))
        shutil.copyfile(rendered, output)


def main() -> None:
    magick = _tool("magick")
    rsvg = _tool("rsvg-convert")
    if not APP_ICON_SOURCE.exists():
        raise SystemExit(f"error: approved app icon not found: {APP_ICON_SOURCE}")

    with tempfile.TemporaryDirectory(prefix="plezyng-brand-assets-") as temporary:
        scratch = Path(temporary)
        source = _clean_source(magick, scratch)
        _fit_art(magick, source, ASSETS / "plezy.png", 1024, 1024)
        _generate_app_icon_composer_sources(magick, source)
        _generate_android_icons(magick, source)
        _generate_windows_icons(magick, source, scratch)
        _generate_tvos_icons(magick, source)
        _generate_top_shelf(magick, rsvg, scratch)
    print("Generated the PlezyNG primary icon for app targets, launchers, and store artwork.")


if __name__ == "__main__":
    main()
