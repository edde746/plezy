#!/usr/bin/env python3
"""Fill untranslated locale leaves from English before Slang generation.

Plezy's locale normalizer represents newly added translations as empty strings.
For parameterized strings, that changes the generated Dart member signature and
breaks compilation. Labs uses the English source text as a safe fallback until
a locale supplies a real translation.
"""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
import sys


# Upstream 2.16 grouped repository checks under scripts/checks. Add that
# directory explicitly because this Labs helper remains in scripts/.
sys.path.insert(0, str(Path(__file__).resolve().parent / "checks"))
import clean_translations  # noqa: E402


ROOT = Path(__file__).resolve().parent.parent
I18N_DIR = ROOT / "lib" / "i18n"
MISSING = object()
LABS_OWNED_PATHS = (
    ("app", "title"),
    ("update", "chooseChannelTitle"),
    ("update", "chooseChannelDescription"),
    ("update", "useLabs"),
    ("update", "returnToOfficial"),
    ("update", "returnToOfficialTitle"),
    ("update", "returnToOfficialWarning"),
    ("update", "openOfficialRelease"),
    ("update", "releaseNotes"),
    ("settings", "officialPlezy"),
    ("settings", "plezyLabs"),
    ("settings", "labsNotAvailable"),
    ("settings", "latestLabsRelease"),
    ("settings", "latestOfficialRelease"),
    ("settings", "releaseStatusUnavailable"),
    ("about", "labsDescription"),
    ("about", "labsModifiedNotice"),
    ("about", "labsSource"),
)


def add_fallbacks(source: object, locale: object = MISSING) -> object:
    if isinstance(source, dict):
        existing = locale if isinstance(locale, dict) else {}
        result = {
            key: add_fallbacks(value, existing.get(key, MISSING))
            for key, value in source.items()
        }
        result.update({key: value for key, value in existing.items() if key not in source})
        return result

    if locale is MISSING or locale == "" or isinstance(locale, dict):
        return copy.deepcopy(source)
    return locale


def apply_labs_owned_values(source: dict[str, object], locale: dict[str, object]) -> None:
    """Keep Labs branding and channel copy identical in every locale."""
    for path in LABS_OWNED_PATHS:
        source_parent: object = source
        locale_parent: object = locale
        for key in path[:-1]:
            if not isinstance(source_parent, dict) or key not in source_parent:
                break
            source_parent = source_parent[key]
            if not isinstance(locale_parent, dict) or key not in locale_parent:
                break
            locale_parent = locale_parent[key]
        else:
            leaf = path[-1]
            if isinstance(source_parent, dict) and isinstance(locale_parent, dict) and leaf in source_parent:
                locale_parent[leaf] = copy.deepcopy(source_parent[leaf])


def prepare(*, check: bool = False, directory: Path = I18N_DIR) -> list[Path]:
    source_path = directory / "en.i18n.json"
    source = json.loads(source_path.read_text(encoding="utf-8"))
    changed: list[Path] = []

    for path in sorted(directory.glob("*.i18n.json")):
        if path == source_path:
            continue
        locale = json.loads(path.read_text(encoding="utf-8"))
        prepared = add_fallbacks(source, locale)
        apply_labs_owned_values(source, prepared)
        stats = {"added": 0, "removed": 0, "type_fixed": 0, "unchanged": 0}
        categories = clean_translations.locale_plural_categories(source, prepared)
        normalized = clean_translations.normalize(source, prepared, "", stats, categories)
        new_text = json.dumps(normalized, ensure_ascii=False, indent=2) + "\n"
        if new_text == path.read_text(encoding="utf-8"):
            continue
        changed.append(path)
        if not check:
            path.write_text(new_text, encoding="utf-8")

    return changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    changed = prepare(check=args.check)

    if args.check and changed:
        print("Labs translation fallbacks are stale:")
        for path in changed:
            print(f"  {path.relative_to(ROOT)}")
        return 1

    action = "Would prepare" if args.check else "Prepared"
    print(f"{action} {len(changed)} locale file(s) with English fallbacks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
