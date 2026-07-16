#!/usr/bin/env python3
"""
Normalize lib/i18n/*.i18n.json to match en.i18n.json's structure/order/formatting
and report en leaf keys that are never referenced from lib/**/*.dart.

  python3 scripts/clean_translations.py            # clean + unused report
  python3 scripts/clean_translations.py --check    # dry-run (no writes)
  python3 scripts/clean_translations.py --clean    # only normalize JSON
  python3 scripts/clean_translations.py --unused   # only unused-key scan
  python3 scripts/clean_translations.py --strict   # exit 1 if unused keys found

Caveat: usage detection is static. Aliased access like `final _t = t; _t.a.b`
would be missed. The repo does not currently use this pattern.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
I18N_DIR = ROOT / "lib" / "i18n"
LIB_DIR = ROOT / "lib"
SOURCE_LOCALE = "en"

USAGE_RES = (
    re.compile(r"\bt\s*\.\s*([A-Za-z_]\w*(?:\s*\.\s*[A-Za-z_]\w*)+)"),
    re.compile(
        r"\bTranslations\s*\.\s*of\s*\([^)]*\)\s*\.\s*"
        r"([A-Za-z_]\w*(?:\s*\.\s*[A-Za-z_]\w*)+)"
    ),
)
DOT_WS_RE = re.compile(r"\s*\.\s*")
PLURAL_CATEGORIES = ("zero", "one", "two", "few", "many", "other")


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def dump_json(obj: dict) -> str:
    return json.dumps(obj, ensure_ascii=False, indent=2) + "\n"

_MISSING = object()


def empty_shaped_like(node):
    if isinstance(node, dict):
        return {k: empty_shaped_like(v) for k, v in node.items()}
    return ""


def is_plural_map(node) -> bool:
    return (
        isinstance(node, dict)
        and "other" in node
        and bool(node)
        and set(node).issubset(PLURAL_CATEGORIES)
        and all(not isinstance(value, dict) for value in node.values())
    )


def locale_plural_categories(en_node, loc_node) -> tuple[str, ...]:
    found: set[str] = set()

    def visit(en_value, loc_value):
        if is_plural_map(en_value):
            if isinstance(loc_value, dict):
                found.update(key for key in loc_value if key in PLURAL_CATEGORIES)
            return
        if not isinstance(en_value, dict) or not isinstance(loc_value, dict):
            return
        for key, child in en_value.items():
            visit(child, loc_value.get(key, _MISSING))

    visit(en_node, loc_node)
    if not found:
        found.update(en_node.keys() if is_plural_map(en_node) else ("one", "other"))
    return tuple(category for category in PLURAL_CATEGORIES if category in found)


def normalize(en_node, loc_node, path: str, stats: dict, plural_categories: tuple[str, ...]):
    """Rebuild loc_node to match en_node while preserving locale plural categories."""
    if is_plural_map(en_node):
        if not isinstance(loc_node, dict):
            if loc_node is not _MISSING:
                stats["type_fixed"] += 1
                print(f"  WARN type mismatch at '{path}' — replacing with empty plural map")
            loc_node = {}
        result = {}
        for category in plural_categories:
            value = loc_node.get(category, _MISSING)
            if value is _MISSING or isinstance(value, dict):
                stats["added"] += 1
                result[category] = ""
            else:
                stats["unchanged"] += 1
                result[category] = value
        return result

    if isinstance(en_node, dict):
        if not isinstance(loc_node, dict):
            if loc_node is not _MISSING:
                stats["type_fixed"] += 1
                print(f"  WARN type mismatch at '{path}' — replacing with empty branch")
            loc_node = {}

        result = {}
        for key, value in en_node.items():
            sub_path = f"{path}.{key}" if path else key
            result[key] = normalize(
                value,
                loc_node.get(key, _MISSING),
                sub_path,
                stats,
                plural_categories,
            )
        for key in loc_node:
            if key not in en_node:
                sub_path = f"{path}.{key}" if path else key
                dropped = count_leaves(loc_node[key])
                stats["removed"] += dropped
                print(f"  INFO dropping orphan '{sub_path}' ({dropped} leaf key{'s' if dropped != 1 else ''})")
        return result

    if loc_node is _MISSING:
        stats["added"] += 1
        return ""
    if isinstance(loc_node, dict):
        stats["type_fixed"] += 1
        print(f"  WARN type mismatch at '{path}' — replacing branch with empty string")
        return ""
    stats["unchanged"] += 1
    return loc_node


def count_leaves(node) -> int:
    if isinstance(node, dict):
        return sum(count_leaves(v) for v in node.values())
    return 1


def flatten(node, prefix: str = "") -> list[str]:
    out: list[str] = []
    if isinstance(node, dict):
        for k, v in node.items():
            key = f"{prefix}.{k}" if prefix else k
            out.extend(flatten(v, key))
    else:
        out.append(prefix)
    return out


def clean_pass(check_only: bool) -> bool:
    """Returns True if any file was (or would be) changed."""
    en_path = I18N_DIR / f"{SOURCE_LOCALE}.i18n.json"
    en = load_json(en_path)
    changed_any = False

    locale_files = sorted(
        p for p in I18N_DIR.glob("*.i18n.json") if p.name != f"{SOURCE_LOCALE}.i18n.json"
    )
    for path in locale_files:
        locale = path.name.split(".")[0]
        print(f"[{locale}]")
        loc = load_json(path)
        stats = {"added": 0, "removed": 0, "type_fixed": 0, "unchanged": 0}
        plural_categories = locale_plural_categories(en, loc)
        normalized = normalize(en, loc, "", stats, plural_categories)
        new_text = dump_json(normalized)
        old_text = path.read_text(encoding="utf-8")
        file_changed = new_text != old_text
        if file_changed:
            changed_any = True
            if check_only:
                print(
                    f"  would rewrite — added={stats['added']} removed={stats['removed']} "
                    f"type_fixed={stats['type_fixed']} unchanged={stats['unchanged']}"
                )
            else:
                path.write_text(new_text, encoding="utf-8")
                print(
                    f"  rewrote — added={stats['added']} removed={stats['removed']} "
                    f"type_fixed={stats['type_fixed']} unchanged={stats['unchanged']}"
                )
        else:
            print(
                f"  ok — unchanged={stats['unchanged']} "
                f"(added={stats['added']} removed={stats['removed']} type_fixed={stats['type_fixed']})"
            )

    return changed_any


def collect_references() -> set[str]:
    refs: set[str] = set()
    for dart_file in LIB_DIR.rglob("*.dart"):
        # Skip i18n sources and generated files.
        try:
            rel = dart_file.relative_to(LIB_DIR)
        except ValueError:
            continue
        if rel.parts and rel.parts[0] == "i18n":
            continue
        text = dart_file.read_text(encoding="utf-8", errors="replace")
        for usage_re in USAGE_RES:
            for match in usage_re.finditer(text):
                chain = DOT_WS_RE.sub(".", match.group(1))
                refs.add(chain)
    return refs


def unused_pass(strict: bool) -> int:
    en = load_json(I18N_DIR / f"{SOURCE_LOCALE}.i18n.json")
    leaves = flatten(en)
    refs = collect_references()

    direct: set[str] = set()
    for leaf in leaves:
        if leaf in refs:
            direct.add(leaf)
            continue
        # Does any reference extend this leaf (e.g., deeper access that
        # would only be possible if en grows more depth under this key)?
        for r in refs:
            if r.startswith(leaf + "."):
                direct.add(leaf)
                break

    ambiguous: set[str] = set()
    remaining = [l for l in leaves if l not in direct]
    for leaf in remaining:
        # Parent-branch access: a reference is a strict prefix of the leaf.
        parts = leaf.split(".")
        for i in range(1, len(parts)):
            prefix = ".".join(parts[:i])
            if prefix in refs:
                ambiguous.add(leaf)
                break

    unused = [l for l in remaining if l not in ambiguous]
    ambiguous_sorted = sorted(ambiguous)

    print()
    print(f"=== Usage scan ({len(leaves)} leaf keys, {len(refs)} distinct reference chains) ===")
    print()

    if unused:
        print(f"Unused ({len(unused)}):")
        for k in sorted(unused):
            print(f"  {k}")
    else:
        print("Unused: none")

    print()
    if ambiguous_sorted:
        print(f"Only reachable via parent-branch access — review manually ({len(ambiguous_sorted)}):")
        for k in ambiguous_sorted:
            print(f"  {k}")
    else:
        print("Parent-branch-only: none")

    print()
    print(
        f"Summary: {len(direct)} used directly, {len(ambiguous_sorted)} ambiguous, "
        f"{len(unused)} unused (of {len(leaves)} total)"
    )

    if strict and unused:
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="dry-run; do not modify files")
    parser.add_argument("--clean", action="store_true", help="only run the cleanup pass")
    parser.add_argument("--unused", action="store_true", help="only run the unused-key scan")
    parser.add_argument("--strict", action="store_true", help="exit 1 if any unused keys are found")
    args = parser.parse_args()

    if args.clean and args.unused:
        print("--clean and --unused are mutually exclusive", file=sys.stderr)
        return 2

    run_clean = not args.unused
    run_unused = not args.clean

    en_path = I18N_DIR / f"{SOURCE_LOCALE}.i18n.json"
    if not en_path.exists():
        print(f"Source locale not found: {en_path}", file=sys.stderr)
        return 2

    if run_clean:
        print(f"=== Cleanup pass (source: {en_path.relative_to(ROOT)}) ===")
        changed = clean_pass(check_only=args.check)
        if args.check and changed:
            print("\n(--check) one or more files would be rewritten.")

    if run_unused:
        code = unused_pass(strict=args.strict)
        if code:
            return code

    if run_clean and args.check and changed:
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
