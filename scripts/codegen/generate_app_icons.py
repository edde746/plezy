#!/usr/bin/env python3
"""Generate the Supporter alternate app icons for iOS, tvOS, Android and the in-app picker.

Sources, one directory per icon under assets/app_icons/source/<id>/ (not bundled into the app):

* icon.svg, background.svg, foreground.svg: the approved designs from plezy-design/logos
  (L01-L23), copied verbatim. A 1024 canvas with the foreground inside Android's 61% safe circle,
  already optically centred.
* monochrome.svg: the visible mark as a silhouette, for Android 13 themed icons. Only its alpha is
  used. Derived once from the designer generator's measurement silhouettes (no glows, shadows or
  backdrops); edit it by hand like any other source.
* tv_background.svg (optional): a hand-composed wide back layer for designs whose backdrop has to
  line up with the mark (CRT's screen, VHS's stripes) or would be clipped by a mechanical crop
  (Pop's burst). Drawn in the foreground's 1024 coordinates and wide enough for 16:9. Without it
  the tvOS and Android TV backs are a centred cover crop of background.svg.

Outputs, all committed:

* ios/Runner/AlternateAppIcons.xcassets: one single-size 1024 AppIcon-<id>.appiconset per icon. The
  Runner target compiles every app icon set in it as an alternate
  (ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS); plezy.icon stays the primary.
* tvos/Runner/AlternateAppIcons.xcassets: one AppIcon-<id>.imagestack per icon, a Front (foreground)
  and Back layer at 400x240 and 800x480. tvOS wants CFBundleAlternateIcons as an array of names,
  but the asset catalog compiler only writes iOS's dictionary form (App Store Connect rejects it
  with ITMS-90471), so the Runner lists the names between the generated markers in
  tvos/Runner/Info.plist instead.
* android/app/src/main/res: an adaptive icon (background, foreground and monochrome layers), a
  legacy launcher icon for API 25 and an Android TV banner per icon, plus the matching
  <activity-alias> block in AndroidManifest.xml between the generated markers.
* assets/app_icons/previews/<id>.webp: the picker thumbnails, bundled as Flutter assets. Also
  default-tvos.webp and default-androidtv.webp: the shipping default as the TV launchers draw it,
  rendered from tvOS's App Icon image stack and the Android TV banner. Re-run after changing the
  default icon; phones need no default thumbnail, the picker draws their flat plate itself.

Wide formats (the tvOS tile and the Android TV banner) scale the foreground canvas to 1.25x the
tile height and centre it, so the mark sits at about the default icon's size; the back layer
fills the tile.

Icon ids are permanent. iOS and tvOS persist the chosen icon by name, and Android keeps the chosen
launcher component (.appicon.<id>) enabled across updates: removing or renaming an id would leave
those users with an icon the app no longer ships or, on Android, no launcher entry at all. The
Dart catalog (lib/services/app_icon/app_icon_catalog.dart) lists the same ids.

Needs rsvg-convert (librsvg), ImageMagick 7 (magick) and cwebp (libwebp):
    brew install librsvg imagemagick webp
Run from the repository root:
    python3 scripts/codegen/generate_app_icons.py
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/app_icons/source"
PREVIEWS = ROOT / "assets/app_icons/previews"
IOS_CATALOG = ROOT / "ios/Runner/AlternateAppIcons.xcassets"
TVOS_CATALOG = ROOT / "tvos/Runner/AlternateAppIcons.xcassets"
ANDROID_RES = ROOT / "android/app/src/main/res"
ANDROID_MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
TVOS_INFO_PLIST = ROOT / "tvos/Runner/Info.plist"
# The shipping default icon's TV artwork, which the default picker thumbnails are cut from.
TVOS_DEFAULT_STACK = ROOT / "tvos/Runner/Assets.xcassets/AppIcon.brandassets/App Icon.imagestack"
ANDROID_DEFAULT_BANNER = ANDROID_RES / "drawable-xxxhdpi/tv_banner.png"

# Picker order; the default icon is not part of this set.
ICONS = [
    "midnight",
    "ember",
    "paper",
    "oled",
    "line",
    "ocean",
    "ultraviolet",
    "matcha",
    "sunset",
    "gold",
    "titanium",
    "glass",
    "crt",
    "vhs",
    "synthwave",
    "pixel",
    "neon",
    "sticker",
    "ticket",
    "pop",
    "strata",
    "facet",
    "tilde",
]

CANVAS = 1024
# The foreground canvas spans 1.25x the height of a wide tile.
WIDE_HEIGHT = CANVAS / 1.25

# Adaptive icon layers are 108dp. Phones sit at xxhdpi/xxxhdpi and TVs at xhdpi; Android scales
# down from the nearest larger bucket for anything below, and Play's density splits ship one.
ANDROID_LAYER_DENSITIES = {"xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
# minSdk 25 predates adaptive icons; one high-density legacy icon covers those launchers.
ANDROID_LEGACY_DENSITY = ("xxxhdpi", 192)
# Leanback banners are 320x180dp; Android TV renders them at xhdpi.
ANDROID_BANNER_DENSITIES = {"xhdpi": (320, 180)}
PREVIEW_SIZE = 216
TVOS_SIZES = {"": (400, 240), "@2x": (800, 480)}

WEBP_QUALITY = "90"
MANIFEST_BEGIN = "<!-- BEGIN generated app icon aliases (scripts/codegen/generate_app_icons.py); do not edit -->"
MANIFEST_END = "<!-- END generated app icon aliases -->"
TVOS_PLIST_BEGIN = "<!-- BEGIN generated tvOS alternate icons (scripts/codegen/generate_app_icons.py); do not edit -->"
TVOS_PLIST_END = "<!-- END generated tvOS alternate icons -->"
XCASSETS_INFO = {"info": {"author": "xcode", "version": 1}}

_ROOT_SVG = re.compile(r"<svg\b[^>]*>")


def _tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        sys.exit(f"error: {name} not found; install with: brew install librsvg imagemagick webp")
    return path


def _run(*args: str) -> None:
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0 or result.stderr.strip():
        sys.exit(f"error: {' '.join(args)}\n{result.stderr.strip()}")


def _with_viewbox(svg: str, x: float, y: float, width: float, height: float) -> str:
    """Re-frames [svg]: the root element's viewBox picks the region that fills the output."""
    root = _ROOT_SVG.search(svg)
    if root is None:
        raise ValueError("not an SVG document")
    tag = re.sub(r'\s(?:viewBox|width|height)="[^"]*"', "", root.group(0))
    tag = tag[:-1] + f' viewBox="{x:g} {y:g} {width:g} {height:g}" width="{width:g}" height="{height:g}">'
    return svg[: root.start()] + tag + svg[root.end() :]


class Renderer:
    """Renders sources into scratch PNGs; each output step then encodes the final file."""

    def __init__(self, scratch: Path) -> None:
        self._scratch = scratch
        self._counter = 0
        self.rsvg = _tool("rsvg-convert")
        self.magick = _tool("magick")
        self.cwebp = _tool("cwebp")

    def temp(self, suffix: str) -> Path:
        self._counter += 1
        return self._scratch / f"{self._counter}{suffix}"

    def svg(self, svg: str, width: int, height: int) -> Path:
        source = self.temp(".svg")
        source.write_text(svg)
        out = self.temp(".png")
        _run(self.rsvg, "-w", str(width), "-h", str(height), "-o", str(out), str(source))
        return out

    def square(self, path: Path, size: int) -> Path:
        return self.svg(path.read_text(), size, size)

    def wide(self, icon: Path, layer: str, width: int, height: int) -> Path:
        """[layer] ("foreground" or "background") of [icon] framed for a [width]x[height] tile."""
        aspect = width / height
        if layer == "foreground":
            return self._frame_on_foreground(icon / "foreground.svg", aspect, width, height)
        bespoke = icon / "tv_background.svg"
        if bespoke.exists():
            return self._frame_on_foreground(bespoke, aspect, width, height)
        # Cover crop: the full canvas width, centred vertically.
        crop_height = CANVAS / aspect
        svg = _with_viewbox((icon / "background.svg").read_text(), 0, (CANVAS - crop_height) / 2, CANVAS, crop_height)
        return self.svg(svg, width, height)

    def _frame_on_foreground(self, path: Path, aspect: float, width: int, height: int) -> Path:
        crop_width = WIDE_HEIGHT * aspect
        svg = _with_viewbox(
            path.read_text(), (CANVAS - crop_width) / 2, (CANVAS - WIDE_HEIGHT) / 2, crop_width, WIDE_HEIGHT
        )
        return self.svg(svg, width, height)

    def composite(self, back: Path, front: Path) -> Path:
        out = self.temp(".png")
        _run(self.magick, str(back), str(front), "-compose", "over", "-composite", str(out))
        return out

    def cover_square(self, source: Path, size: int) -> Path:
        """The centred square of [source], scaled to [size]: how a wide TV tile reads as a thumbnail."""
        out = self.temp(".png")
        _run(
            self.magick,
            str(source),
            "-resize",
            f"{size}x{size}^",
            "-gravity",
            "center",
            "-extent",
            f"{size}x{size}",
            str(out),
        )
        return out

    def white_silhouette(self, source: Path, size: int) -> Path:
        """The alpha of [source] on white, which is all a themed-icon layer reads."""
        rendered = self.square(source, size)
        out = self.temp(".png")
        _run(
            self.magick,
            str(rendered),
            "-alpha",
            "extract",
            "(",
            "-size",
            f"{size}x{size}",
            "xc:white",
            ")",
            "+swap",
            "-alpha",
            "off",
            "-compose",
            "copy-opacity",
            "-composite",
            str(out),
        )
        return out

    def rounded(self, source: Path, size: int, radius: float) -> Path:
        out = self.temp(".png")
        _run(
            self.magick,
            str(source),
            "(",
            "-size",
            f"{size}x{size}",
            "xc:none",
            "-fill",
            "white",
            "-draw",
            f"roundrectangle 0,0,{size - 1},{size - 1},{radius:g},{radius:g}",
            ")",
            "-compose",
            "dst-in",
            "-composite",
            str(out),
        )
        return out

    def png(self, source: Path, out: Path, *, opaque: bool) -> None:
        """Writes a reproducible PNG: no timestamps, and no alpha channel when [opaque]."""
        out.parent.mkdir(parents=True, exist_ok=True)
        args = [self.magick, str(source), "-strip"]
        if opaque:
            args += ["-background", "black", "-alpha", "remove", "-alpha", "off"]
        _run(*args, "-define", "png:compression-level=9", str(out))

    def webp(self, source: Path, out: Path, *, lossless: bool = False) -> None:
        out.parent.mkdir(parents=True, exist_ok=True)
        quality = ["-lossless", "-z", "9"] if lossless else ["-q", WEBP_QUALITY, "-sharp_yuv", "-alpha_q", "100"]
        _run(self.cwebp, "-quiet", "-m", "6", "-metadata", "none", *quality, str(source), "-o", str(out))


def _write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def _replace_generated(path: Path, begin_marker: str, end_marker: str, body: str) -> None:
    """Replaces the whole lines between the [begin_marker] line and the [end_marker] line."""
    text = path.read_text()
    begin = text.find(begin_marker)
    end = text.find(end_marker)
    if begin < 0 or end < begin:
        sys.exit(f"error: {path} lacks the generated markers")
    body_start = text.index("\n", begin) + 1
    body_end = text.rindex("\n", 0, end) + 1
    path.write_text(text[:body_start] + body + text[body_end:])


def _reset_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)


def generate_ios(renderer: Renderer) -> None:
    _reset_dir(IOS_CATALOG)
    _write_json(IOS_CATALOG / "Contents.json", XCASSETS_INFO)
    for icon in ICONS:
        icon_set = IOS_CATALOG / f"AppIcon-{icon}.appiconset"
        renderer.png(renderer.square(SOURCE / icon / "icon.svg", CANVAS), icon_set / "icon.png", opaque=True)
        _write_json(
            icon_set / "Contents.json",
            {
                "images": [{"filename": "icon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
                **XCASSETS_INFO,
            },
        )


def generate_tvos(renderer: Renderer) -> None:
    _reset_dir(TVOS_CATALOG)
    _write_json(TVOS_CATALOG / "Contents.json", XCASSETS_INFO)
    layers = {"Front": "foreground", "Back": "background"}
    for icon in ICONS:
        stack = TVOS_CATALOG / f"AppIcon-{icon}.imagestack"
        _write_json(
            stack / "Contents.json",
            {"layers": [{"filename": f"{name}.imagestacklayer"} for name in layers], **XCASSETS_INFO},
        )
        for name, layer in layers.items():
            _write_json(stack / f"{name}.imagestacklayer/Contents.json", XCASSETS_INFO)
            imageset = stack / f"{name}.imagestacklayer/Content.imageset"
            images = []
            for suffix, (width, height) in TVOS_SIZES.items():
                filename = f"{name}{suffix}.png"
                renderer.png(renderer.wide(SOURCE / icon, layer, width, height), imageset / filename, opaque=name == "Back")
                images.append({"filename": filename, "idiom": "tv", "scale": "2x" if suffix else "1x"})
            _write_json(imageset / "Contents.json", {"images": images, **XCASSETS_INFO})
    names = "".join(f"\t\t\t<string>AppIcon-{icon}</string>\n" for icon in ICONS)
    _replace_generated(TVOS_INFO_PLIST, TVOS_PLIST_BEGIN, TVOS_PLIST_END, names)


def _adaptive_icon_xml(icon: str) -> str:
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated by scripts/codegen/generate_app_icons.py; do not edit. -->\n"
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        f'  <background android:drawable="@drawable/ic_launcher_{icon}_background" />\n'
        f'  <foreground android:drawable="@drawable/ic_launcher_{icon}_foreground" />\n'
        f'  <monochrome android:drawable="@drawable/ic_launcher_{icon}_monochrome" />\n'
        "</adaptive-icon>\n"
    )


def _alias_xml(icon: str) -> str:
    return f"""        <activity-alias
            android:name=".appicon.{icon}"
            android:enabled="false"
            android:exported="true"
            android:icon="@mipmap/ic_launcher_{icon}"
            android:banner="@drawable/tv_banner_{icon}"
            android:targetActivity=".PlezyActivity">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <meta-data
                android:name="flutter_deeplinking_enabled"
                android:value="false" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
                <category android:name="android.intent.category.LEANBACK_LAUNCHER"/>
            </intent-filter>
        </activity-alias>
"""


def _write_manifest_aliases() -> None:
    aliases = "".join(_alias_xml(icon) for icon in ICONS)
    _replace_generated(ANDROID_MANIFEST, MANIFEST_BEGIN, MANIFEST_END, aliases)


def generate_android(renderer: Renderer) -> None:
    for icon in ICONS:
        for pattern in (f"*/ic_launcher_{icon}.*", f"*/ic_launcher_{icon}_*.webp", f"*/tv_banner_{icon}.webp"):
            for stale in ANDROID_RES.glob(pattern):
                stale.unlink()
    for icon in ICONS:
        source = SOURCE / icon
        (ANDROID_RES / "mipmap-anydpi-v26" / f"ic_launcher_{icon}.xml").write_text(_adaptive_icon_xml(icon))
        for density, size in ANDROID_LAYER_DENSITIES.items():
            drawable = ANDROID_RES / f"drawable-{density}"
            renderer.webp(renderer.square(source / "background.svg", size), drawable / f"ic_launcher_{icon}_background.webp")
            renderer.webp(renderer.square(source / "foreground.svg", size), drawable / f"ic_launcher_{icon}_foreground.webp")
            renderer.webp(
                renderer.white_silhouette(source / "monochrome.svg", size),
                drawable / f"ic_launcher_{icon}_monochrome.webp",
                lossless=True,
            )
        legacy_density, legacy_size = ANDROID_LEGACY_DENSITY
        legacy = renderer.rounded(renderer.square(source / "icon.svg", legacy_size), legacy_size, legacy_size * 0.2)
        renderer.webp(legacy, ANDROID_RES / f"mipmap-{legacy_density}" / f"ic_launcher_{icon}.webp")
        for density, (width, height) in ANDROID_BANNER_DENSITIES.items():
            banner = renderer.composite(
                renderer.wide(source, "background", width, height), renderer.wide(source, "foreground", width, height)
            )
            renderer.webp(banner, ANDROID_RES / f"drawable-{density}" / f"tv_banner_{icon}.webp")
    _write_manifest_aliases()


def generate_previews(renderer: Renderer) -> None:
    _reset_dir(PREVIEWS)
    for icon in ICONS:
        renderer.webp(renderer.square(SOURCE / icon / "icon.svg", PREVIEW_SIZE), PREVIEWS / f"{icon}.webp")
    tvos = TVOS_DEFAULT_STACK
    stack = renderer.composite(
        renderer.composite(
            tvos / "Back.imagestacklayer/Content.imageset/Back@2x.png",
            tvos / "Middle.imagestacklayer/Content.imageset/Middle@2x.png",
        ),
        tvos / "Front.imagestacklayer/Content.imageset/Front@2x.png",
    )
    renderer.webp(renderer.cover_square(stack, PREVIEW_SIZE), PREVIEWS / "default-tvos.webp")
    renderer.webp(renderer.cover_square(ANDROID_DEFAULT_BANNER, PREVIEW_SIZE), PREVIEWS / "default-androidtv.webp")


def main() -> None:
    missing = [
        f"{icon}/{name}"
        for icon in ICONS
        for name in ("icon.svg", "background.svg", "foreground.svg", "monochrome.svg")
        if not (SOURCE / icon / name).exists()
    ]
    if missing:
        sys.exit("error: missing sources: " + ", ".join(missing))
    with tempfile.TemporaryDirectory(prefix="plezy-app-icons-") as scratch:
        renderer = Renderer(Path(scratch))
        generate_ios(renderer)
        generate_tvos(renderer)
        generate_android(renderer)
        generate_previews(renderer)
    print(f"Generated {len(ICONS)} alternate app icons.")


if __name__ == "__main__":
    main()
