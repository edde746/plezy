#!/usr/bin/env python3
"""Export all PlezyNG branding from the approved raster, without redrawing it.

Install scripts/codegen/requirements-branding.txt, then run this script from
any directory. --check renders in memory and reports stale / missing exports.
Permanent alternate launcher ids stay intact. Large marks retain the ribbon
and NG; compact and monochrome exports use the approved simplified ribbon.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import io
import json
import math
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "assets/branding/brand.json"
ICONS = [
    "midnight", "ember", "paper", "oled", "line", "ocean", "ultraviolet",
    "matcha", "sunset", "gold", "titanium", "glass", "crt", "vhs",
    "synthwave", "pixel", "neon", "sticker", "ticket", "pop", "strata",
    "facet", "tilde",
]
RETIRED = [
    "android/app/src/main/res/drawable/ic_launcher_foreground.xml",
    "android/app/src/main/res/drawable/ic_launcher_monochrome.xml",
    "ios/plezy.icon/Assets/plezy-cropped.svg",
    "macos/plezy.icon/Assets/plezy-cropped.svg",
    "ios/plezy.icon/Assets/plezy-cropped.png",
    "macos/plezy.icon/Assets/plezy-cropped.png",
    "assets/plezy_ng_badge.svg",
    "scripts/codegen/ng_brand_badge.py",
]
RETIRED += [
    f"android/app/src/main/res/drawable-{density}/ic_launcher_{layer}.png"
    for density in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi")
    for layer in ("foreground", "monochrome")
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def png(image: Image.Image) -> bytes:
    out = io.BytesIO()
    image.save(out, format="PNG", compress_level=9, optimize=False)
    return out.getvalue()


class BrandRenderer:
    def __init__(self, config: dict) -> None:
        self.config = config
        self.source_bytes = (ROOT / config["source"]).read_bytes()
        if sha256(self.source_bytes) != config["source_sha256"]:
            raise ValueError("Approved source checksum changed; update brand.json only after design approval")
        self.source = self.load_image(self.source_bytes)
        self.sources = {"mark_dark": self.source}
        for name, source in config["sources"].items():
            data = (ROOT / source["path"]).read_bytes()
            if sha256(data) != source["sha256"]:
                raise ValueError(f"Approved source checksum changed: {name}")
            self.sources[name] = self.load_image(data)
        self.mono = self.monochrome()
        self.adaptive_fit = min(self.safe_fit(image) for image in
                                (self.source, self.sources["mark_light"], self.sources["compact"]))
        self.cache: dict[str, bytes] = {}

    @staticmethod
    def load_image(data: bytes) -> Image.Image:
        image = Image.open(io.BytesIO(data)).convert("RGBA")
        # Preserve the approved masters; suppress only near-zero-alpha matte
        # residue in the derived exports, as the previous exporter did.
        image.putalpha(image.getchannel("A").point(lambda a: 0 if a <= 4 else a))
        return image

    def monochrome(self) -> Image.Image:
        """Use the compact ribbon's open silhouette for system-tinted icons."""
        compact = self.sources["compact"]
        image = Image.new("RGBA", compact.size, "white")
        image.putalpha(compact.getchannel("A"))
        return image

    def safe_fit(self, image: Image.Image) -> float:
        """Fit every visible pixel, including NG, inside Android's safe circle."""
        width, height = image.size
        alpha = image.getchannel("A").point(lambda a: 255 if a > 16 else 0).tobytes()
        radius = 0.0
        for y in range(height):
            row = alpha[y * width : (y + 1) * width]
            first, last = row.find(b"\xff"), row.rfind(b"\xff")
            if first < 0:
                continue
            radius = max(radius, math.hypot(first - width / 2, y - height / 2),
                         math.hypot(last - width / 2, y - height / 2))
        # 29% radius, slightly inside the 66/108 dp (30.56%) safe circle.
        return .29 * max(width, height) / radius

    def frame(self, size: tuple[int, int], fit: float, *, mono: bool = False,
              background: str | None = None, appearance: str = "dark",
              compact: bool | None = None) -> Image.Image:
        canvas = Image.new("RGBA", size, background or (0, 0, 0, 0))
        edge = max(1, round(min(size) * fit))
        use_compact = min(size) <= 64 if compact is None else compact
        source = self.mono if mono else self.sources["compact" if use_compact else f"mark_{appearance}"]
        logo = ImageOps.contain(source, (edge, edge), Image.Resampling.LANCZOS)
        canvas.alpha_composite(logo, ((size[0] - logo.width) // 2, (size[1] - logo.height) // 2))
        return canvas

    def render(self, target: dict) -> bytes:
        size = tuple(target["size"])
        role = target["role"]
        background = self.config["themes"].get(target.get("theme"), self.config["default_background"])
        key = json.dumps({**target, "path": Path(target["path"]).suffix}, sort_keys=True)
        if key in self.cache:
            return self.cache[key]
        fit = target.get("fit", .76)
        rgb = tuple(int(background.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
        appearance = target.get("appearance", "light" if sum(c * w for c, w in zip(rgb, (.2126, .7152, .0722))) > 160 else "dark")
        if role == "empty":
            image = Image.new("RGBA", size)
        elif role == "background":
            image = Image.new("RGB", size, background)
        elif role in ("plate", "banner"):
            image = self.frame(size, fit, background=background, appearance=appearance).convert("RGB")
        elif role in ("adaptive", "adaptive_mono"):
            image = self.frame(size, self.adaptive_fit, mono=role == "adaptive_mono", appearance=appearance)
        elif role in ("logo", "monochrome", "ico"):
            image = self.frame(size, fit, mono=role == "monochrome", appearance=appearance, compact=target.get("compact"))
        elif role == "wordmark":
            source = self.sources[f"wordmark_{appearance}"]
            bounds = source.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
            wordmark = ImageOps.contain(source.crop(bounds), size, Image.Resampling.LANCZOS)
            image = Image.new("RGBA", size)
            image.alpha_composite(wordmark, ((size[0] - wordmark.width) // 2, (size[1] - wordmark.height) // 2))
        elif role == "artwork":
            image = ImageOps.fit(self.sources[f"artwork_{appearance}"], size, Image.Resampling.LANCZOS).convert("RGB")
        elif role == "feature":
            image = Image.open(ROOT / "assets/branding/feature-graphic-base.png").convert("RGBA")
            image.alpha_composite(self.frame((128, 128), 1), (62, 47))
            image = image.convert("RGB")
        elif role == "server_options":
            image = Image.open(ROOT / "assets/branding/server-options-base.png").convert("RGBA")
            image.alpha_composite(self.frame((315, 315), 1), (382, 173))
            image = image.convert("RGB")
        elif role == "iphone_server_options":
            image = Image.open(ROOT / "assets/branding/iphone-server-options-base.png").convert("RGBA")
            image.alpha_composite(self.frame((424, 424), 1), (376, 229))
            image = image.convert("RGB")
        else:
            raise ValueError(f"Unknown brand asset role: {role}")
        if image.size != size:
            raise ValueError(f"Unexpected dimensions for {target['path']}: {image.size}")
        suffix = Path(target["path"]).suffix
        if suffix == ".png":
            data = png(image)
        else:
            out = io.BytesIO()
            if suffix == ".webp":
                image.save(out, format="WEBP", lossless=True, method=6, exact=True)
            elif suffix == ".ico":
                sizes = [(n, n) for n in (16, 24, 32, 48, 64, 128, 256)]
                frames = [self.frame(s, fit, appearance=appearance, compact=target.get("compact")) for s in sizes]
                frames[-1].save(out, format="ICO", sizes=sizes, append_images=frames[:-1])
            else:
                raise ValueError(f"Unsupported export: {suffix}")
            data = out.getvalue()
        self.cache[key] = data
        return data

    @staticmethod
    def svg(href: str, *, fit: float = 1, background: str | None = None,
            width: int = 1024, height: int = 1024) -> bytes:
        edge = min(width, height) * fit
        back = f'<rect width="{width}" height="{height}" fill="{background}"/>' if background else ""
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
                f'viewBox="0 0 {width} {height}">\n'
                '<!-- Generated from the approved PlezyNG PNG; this is a raster-backed SVG, not a vector redraw. -->\n'
                f'{back}<image href="{href}" x="{(width-edge)/2:g}" y="{(height-edge)/2:g}" '
                f'width="{edge:g}" height="{edge:g}"/>\n</svg>\n').encode()

    def text_exports(self) -> dict[str, bytes]:
        # Public compatibility exports are self-contained. Theme source wrappers
        # reference the single approved source, avoiding 70 embedded PNG copies.
        data_uri = "data:image/png;base64," + base64.b64encode(png(self.source)).decode()
        result = {
            "assets/plezy.svg": self.svg(data_uri),
            "assets/plezy_adaptive_foreground.svg": self.svg(data_uri, fit=self.adaptive_fit),
            "assets/plezyng_top_shelf.svg": self.svg(data_uri, fit=.54, background=self.config["default_background"], width=1920, height=1080),
        }
        for theme in ICONS:
            prefix = f"assets/app_icons/source/{theme}"
            color = self.config["themes"][theme]
            light = sum(int(color.lstrip("#")[i:i + 2], 16) * w for i, w in zip((0, 2, 4), (.2126, .7152, .0722))) > 160
            href = "../../../branding/source/mark-light.png" if light else "../../../branding/plezyng-approved.png"
            result[f"{prefix}/icon.svg"] = self.svg(href, fit=.76, background=color)
            result[f"{prefix}/foreground.svg"] = self.svg(href, fit=self.adaptive_fit)
            result[f"{prefix}/monochrome.svg"] = self.svg("../../../branding/plezyng-monochrome.png", fit=self.adaptive_fit)
            for filename in ("background.svg", "tv_background.svg"):
                if filename == "tv_background.svg" and not (ROOT / prefix / filename).exists():
                    continue
                result[f"{prefix}/{filename}"] = (
                    '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'
                    f'<rect width="1024" height="1024" fill="{color}"/></svg>\n').encode()
        for platform in ("ios", "macos"):
            path = f"{platform}/plezy.icon/icon.json"
            definition = json.loads((ROOT / path).read_text())
            group = definition["groups"][0]
            layer = group["layers"][0]
            layer["image-name"] = "plezyng-app-icon.png"
            layer["position"]["scale"] = .75
            layer["glass"] = False
            group["specular"] = False
            group["shadow"]["opacity"] = 0
            result[path] = (json.dumps(definition, indent=2) + "\n").encode()
        return result


def generate(*, check: bool = False) -> list[str]:
    config = json.loads(CONFIG.read_text())
    if set(config["themes"]) != set(ICONS):
        raise ValueError("Permanent alternate icon ids must match the platform catalog")
    paths = [target["path"] for target in config["targets"]]
    if len(paths) != len(set(paths)):
        raise ValueError("Duplicate brand export targets")
    renderer = BrandRenderer(config)
    exports = {target["path"]: renderer.render(target) for target in config["targets"]}
    exports.update(renderer.text_exports())
    manifest = {
        "schema": 1,
        "source": config["source"],
        "source_sha256": config["source_sha256"],
        "sources": config["sources"],
        "config_sha256": sha256(CONFIG.read_bytes()),
        "generator_sha256": sha256(Path(__file__).read_bytes()),
        "exports": {path: sha256(data) for path, data in sorted(exports.items())},
    }
    exports["assets/branding/asset-manifest.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    stale = []
    for relative, data in exports.items():
        path = ROOT / relative
        if not path.is_file() or path.read_bytes() != data:
            stale.append(relative)
            if not check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
    for relative in RETIRED:
        path = ROOT / relative
        if path.exists():
            stale.append(relative + " (retired)")
            if not check:
                path.unlink()
    if check and stale:
        print("Stale branding exports:\n" + "\n".join(stale))
    else:
        print(f"{'Verified' if check else 'Generated'} {len(exports)} branding exports from the approved logo.")
    return stale


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify every export without changing files")
    args = parser.parse_args()
    stale = generate(check=args.check)
    return 1 if args.check and stale else 0


if __name__ == "__main__":
    raise SystemExit(main())
