#!/usr/bin/env python3
"""Generate assets/go-noto-kurrent-hangul.ttf, the Hangul companion of the
subtitle font assets/go-noto-current-regular.ttf.

Why a companion file exists
---------------------------
Go Noto Current-Regular (satbyy/go-noto-universal v7.0, GoNotoCurrent-Regular)
covers every living script except Korean: it has 0 of the 11172 precomposed
Hangul syllables. Adding them is impossible because a TrueType font holds at
most 65535 glyphs and the primary already has ~60600. The syllables therefore
ship as a second file, subset from the sibling GoNotoKurrent-Regular of the
same release, and both files are extracted into one directory that mpv gets
as ``sub-fonts-dir`` (see lib/mpv/font_loader.dart).

Upstream: https://github.com/satbyy/go-noto-universal release v7.0,
GoNotoKurrent-Regular.ttf (64750 glyphs, sha256
2f2cee5fbb2403df352ca2005247f6c4faa70f3086ebd31b6c62308b5f2f9865).

Why the companion masquerades as the primary's family
-----------------------------------------------------
libass resolves glyphs with ``find_font``: it only scores fonts whose
Microsoft-platform name-ID-1 family equals the requested family
(``sub-font`` = ``SubtitleFontLoader.fontName`` = ``Go Noto Current-Regular``)
and then runs ``check_glyph`` per codepoint on those candidates. The
fonts-dir provider has no ``get_fallback``, and the Android libmpv build has no
fontconfig either, so a file whose family is ``Go Noto Kurrent-Regular`` is
never even a candidate: Korean subtitles rendered as decomposed jamo pulled
from the primary. Giving the companion the *same* family name makes libass'
same-family coverage search reach it for every syllable.

Complement rule
---------------
The companion's cmap is ``cmap(source) ∩ Hangul blocks − cmap(primary)``. Two
files of one family must never compete for a codepoint: ``find_font`` breaks
attribute ties by scan order, which for a directory provider is readdir order.
With disjoint cmaps ``check_glyph`` leaves exactly one candidate per codepoint.

Attributes (OS/2 usWeightClass 400, fsSelection REGULAR, head.macStyle 0,
usWidthClass 5) are forced equal to the primary so ``font_attributes_similarity``
ties and neither file is ever preferred over the other by style.

Usage
-----
    /tmp/ftenv/bin/python scripts/codegen/generate_hangul_subtitle_font.py
    /tmp/ftenv/bin/python scripts/codegen/generate_hangul_subtitle_font.py --check

Requires fontTools (``python3 -m venv /tmp/ftenv && /tmp/ftenv/bin/pip install
fonttools``). The default ``--source`` is the committed companion itself, so
regeneration is offline and byte-for-byte reproducible; pass the upstream
GoNotoKurrent-Regular.ttf to rebuild from scratch (same glyph set and
outlines, plus the ``.notdef`` outline an earlier subset had dropped).
"""

from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path

from fontTools.subset import Options, Subsetter
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[2]
PRIMARY_PATH = ROOT / "assets/go-noto-current-regular.ttf"
HANGUL_PATH = ROOT / "assets/go-noto-kurrent-hangul.ttf"

# Byte-identical to SubtitleFontLoader.fontName (lib/mpv/font_loader.dart);
# test/mpv/font_loader_test.dart pins the extracted files to that constant.
FAMILY = "Go Noto Current-Regular"
SUBFAMILY = "Regular"
FULL_NAME = "Go Noto Current-Regular Hangul"
POSTSCRIPT_NAME = "GoNotoCurrent-Regular-Hangul"

NAME_ID_FAMILY = 1
NAME_ID_SUBFAMILY = 2
NAME_ID_UNIQUE = 3
NAME_ID_FULL = 4
NAME_ID_POSTSCRIPT = 6
NAME_ID_TYPO_FAMILY = 16
NAME_ID_TYPO_SUBFAMILY = 17
PLATFORM_MICROSOFT = 3

HANGUL_BLOCKS = (
    (0xAC00, 0xD7A3),  # Hangul Syllables
    (0x1100, 0x11FF),  # Hangul Jamo
    (0xA960, 0xA97F),  # Hangul Jamo Extended-A
    (0xD7B0, 0xD7FF),  # Hangul Jamo Extended-B
    (0x3130, 0x318F),  # Hangul Compatibility Jamo
    (0xFFA0, 0xFFDC),  # Halfwidth Hangul Jamo
)
SYLLABLES = frozenset(range(0xAC00, 0xD7A3 + 1))
MAX_GLYPHS = 65535

OS2_WEIGHT_REGULAR = 400
OS2_WIDTH_MEDIUM = 5
FS_SELECTION_ITALIC = 1 << 0
FS_SELECTION_BOLD = 1 << 5
FS_SELECTION_REGULAR = 1 << 6
FS_SELECTION_OBLIQUE = 1 << 9


def load(path: Path) -> TTFont:
    # Fully buffered so --output may overwrite --source; the head.modified
    # timestamp is kept so a regeneration from the committed file is a no-op.
    return TTFont(io.BytesIO(path.read_bytes()), recalcTimestamp=False)


def in_hangul_blocks(codepoint: int) -> bool:
    return any(lo <= codepoint <= hi for lo, hi in HANGUL_BLOCKS)


def name_records(font: TTFont, name_id: int) -> dict[tuple[int, int, int], str]:
    return {
        (r.platformID, r.platEncID, r.langID): r.toUnicode()
        for r in font["name"].names
        if r.nameID == name_id
    }


def describe(label: str, font: TTFont) -> None:
    cmap = font.getBestCmap()
    print(f"{label}: {len(font.getGlyphOrder())} glyphs, {len(cmap)} codepoints, "
          f"{len(SYLLABLES & cmap.keys())} Hangul syllables")
    for name_id in (NAME_ID_FAMILY, NAME_ID_SUBFAMILY, NAME_ID_FULL, NAME_ID_POSTSCRIPT,
                    NAME_ID_TYPO_FAMILY, NAME_ID_TYPO_SUBFAMILY):
        for key, value in sorted(name_records(font, name_id).items()):
            print(f"  name {name_id:2d} {key}: {value!r}")
    os2 = font["OS/2"]
    print(f"  OS/2 weight={os2.usWeightClass} width={os2.usWidthClass} "
          f"fsSelection=0x{os2.fsSelection:04x} macStyle={font['head'].macStyle}")


def rewrite_names(font: TTFont) -> None:
    table = font["name"]
    keys = {(r.platformID, r.platEncID, r.langID) for r in table.names}
    table.names = [r for r in table.names
                   if r.nameID not in (NAME_ID_TYPO_FAMILY, NAME_ID_TYPO_SUBFAMILY)]
    unique = name_records(font, NAME_ID_UNIQUE)
    for platform_id, enc_id, lang_id in sorted(keys):
        table.setName(FAMILY, NAME_ID_FAMILY, platform_id, enc_id, lang_id)
        table.setName(SUBFAMILY, NAME_ID_SUBFAMILY, platform_id, enc_id, lang_id)
        table.setName(FULL_NAME, NAME_ID_FULL, platform_id, enc_id, lang_id)
        table.setName(POSTSCRIPT_NAME, NAME_ID_POSTSCRIPT, platform_id, enc_id, lang_id)
        # Unique ID is conventionally "<version>;<vendor>;<postscript name>".
        old_unique = unique.get((platform_id, enc_id, lang_id))
        if old_unique is not None and ";" in old_unique:
            prefix = old_unique.rsplit(";", 1)[0]
            table.setName(f"{prefix};{POSTSCRIPT_NAME}", NAME_ID_UNIQUE, platform_id, enc_id, lang_id)


def force_regular_attributes(font: TTFont) -> None:
    os2 = font["OS/2"]
    os2.usWeightClass = OS2_WEIGHT_REGULAR
    os2.usWidthClass = OS2_WIDTH_MEDIUM
    os2.fsSelection &= ~(FS_SELECTION_ITALIC | FS_SELECTION_BOLD | FS_SELECTION_OBLIQUE)
    os2.fsSelection |= FS_SELECTION_REGULAR
    font["head"].macStyle = 0


def generate(source: Path, primary: Path, output: Path) -> None:
    font = load(source)
    primary_cmap = load(primary).getBestCmap().keys()
    describe(f"source {source}", font)

    unicodes = sorted(
        cp for cp in font.getBestCmap() if in_hangul_blocks(cp) and cp not in primary_cmap
    )
    missing = SYLLABLES.difference(unicodes)
    if missing:
        sys.exit(f"source lacks {len(missing)} Hangul syllables (e.g. U+{min(missing):04X}); "
                 "it is not GoNotoKurrent-Regular or a full Hangul subset of it")

    options = Options()
    options.layout_features = ["*"]
    options.notdef_outline = True
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.name_legacy = True
    subsetter = Subsetter(options=options)
    subsetter.populate(unicodes=unicodes)
    subsetter.subset(font)

    rewrite_names(font)
    force_regular_attributes(font)
    font.save(output)
    print(f"wrote {output} ({output.stat().st_size} bytes)")
    describe(f"output {output}", load(output))


def check(hangul: Path, primary: Path) -> int:
    hangul_font = load(hangul)
    primary_font = load(primary)
    describe(f"primary {primary}", primary_font)
    describe(f"hangul {hangul}", hangul_font)

    failures: list[str] = []

    def require(ok: bool, message: str) -> None:
        print(f"  [{'ok' if ok else 'FAIL'}] {message}")
        if not ok:
            failures.append(message)

    print("invariants:")
    primary_families = name_records(primary_font, NAME_ID_FAMILY)
    hangul_families = name_records(hangul_font, NAME_ID_FAMILY)
    microsoft = {k: v for k, v in hangul_families.items() if k[0] == PLATFORM_MICROSOFT}
    require(bool(microsoft), "hangul has a Microsoft-platform family name (the only ones libass reads)")
    for key, family in sorted(hangul_families.items()):
        require(family == FAMILY, f"hangul family {key} == {FAMILY!r} (got {family!r})")
        require(primary_families.get(key) == family,
                f"primary family {key} == hangul family (got {primary_families.get(key)!r})")

    primary_cmap = primary_font.getBestCmap().keys()
    hangul_cmap = hangul_font.getBestCmap().keys()
    overlap = sorted(primary_cmap & hangul_cmap)
    require(not overlap, f"cmaps disjoint (overlap {len(overlap)}"
            + (f", e.g. U+{overlap[0]:04X}" if overlap else "") + ")")
    missing = SYLLABLES.difference(hangul_cmap)
    require(not missing, f"hangul covers all {len(SYLLABLES)} syllables (missing {len(missing)})")
    for label, font in (("primary", primary_font), ("hangul", hangul_font)):
        count = len(font.getGlyphOrder())
        require(count <= MAX_GLYPHS, f"{label} glyph count {count} <= {MAX_GLYPHS}")

    p_os2, h_os2 = primary_font["OS/2"], hangul_font["OS/2"]
    require(h_os2.usWeightClass == p_os2.usWeightClass == OS2_WEIGHT_REGULAR,
            f"usWeightClass ties at {OS2_WEIGHT_REGULAR}")
    require(h_os2.usWidthClass == p_os2.usWidthClass, "usWidthClass ties")
    style_mask = FS_SELECTION_ITALIC | FS_SELECTION_BOLD | FS_SELECTION_REGULAR | FS_SELECTION_OBLIQUE
    require((h_os2.fsSelection & style_mask) == (p_os2.fsSelection & style_mask) == FS_SELECTION_REGULAR,
            "fsSelection style bits are REGULAR on both")
    require(hangul_font["head"].macStyle == primary_font["head"].macStyle == 0, "head.macStyle 0 on both")

    if failures:
        print(f"{len(failures)} invariant(s) violated", file=sys.stderr)
        return 1
    print("all invariants hold")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--source", type=Path, default=HANGUL_PATH,
                        help="GoNotoKurrent-Regular.ttf or an existing Hangul subset of it")
    parser.add_argument("--primary", type=Path, default=PRIMARY_PATH)
    parser.add_argument("--output", type=Path, default=HANGUL_PATH)
    parser.add_argument("--check", action="store_true",
                        help="verify --output against --primary instead of generating")
    args = parser.parse_args()
    if args.check:
        return check(args.output, args.primary)
    generate(args.source, args.primary, args.output)
    return check(args.output, args.primary)


if __name__ == "__main__":
    sys.exit(main())
