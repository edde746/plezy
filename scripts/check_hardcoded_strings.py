#!/usr/bin/env python3
"""Reject common user-facing English string literals that bypass Slang.

This is deliberately a structural check rather than a Dart/dataflow analyzer. It
cannot see English inside a ``throw`` that a screen later renders, nor a literal
assigned to a provider field that a widget later renders, because neither is
distinguishable from a log message without dataflow analysis.

Bare ``label:`` and ``actionLabel:`` are deliberately NOT scanned. In this
codebase they overwhelmingly name a diagnostic operation rather than UI text
(``_broadcastToDvrs(actionLabel: 'Reload guide', successMessage: t....)``,
``raceEndpointCandidates(label: ...)``, ``systemShelf(label: 'Failed to ...')``),
so scanning them yields only false positives, and a check that is chronically
red is a check that gets switched off. Widget ``label:`` text is still covered
when it reaches a ``Text`` (rule 1) or mixes with ``t.`` (rule 3).
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB_DIR = ROOT / "lib"
ALLOWLIST_PATH = Path(__file__).with_name("hardcoded_strings_allowlist.json")

_UI_ARGUMENTS = (
    "tooltip",
    "semanticLabel",
    "labelText",
    "hintText",
    "helperText",
    "errorText",
    "dialogTitle",
)
_UI_ARGUMENT_RE = re.compile(r"(?<![A-Za-z0-9_])(?:" + "|".join(_UI_ARGUMENTS) + r")\s*:\s*$")
_TEXT_RE = re.compile(r"(?:\bText|\bSelectableText)\s*\(\s*$")
_EXCLUDED_ARGUMENT_RE = re.compile(r"(?:debugLabel|fontFamily)\s*:\s*$")
_KEY_RE = re.compile(r"(?:\bKey|\bValueKey)\s*\(\s*$")
# `log:`/`createdLog:` are diagnostic sinks, including inside lambdas.
_DIAGNOSTIC_RE = re.compile(
    r"(?:\bappLogger\.|\bSentry\.|\bassert\s*\(|\bthrow\b|(?:\blog|[a-z]Log)\s*:)"
)
_TRANSLATION_INTERPOLATION_RE = re.compile(
    r"\$\{\s*(?:t\.|context\.t\b|Translations\.of\s*\()"
)
_T_PARAMETER_RE = re.compile(r"(?:\(\s*t\s*\)|\bt)\s*=>[^;]*$")
# Rule 4 catches phrases assigned or returned before a widget renders them.
# Restrict it to multi-word phrases to avoid confusing identifiers with UI copy;
# single-word labels remain indistinguishable without dataflow analysis.
_PHRASE_RE = re.compile(r"[A-Za-z]\s+[A-Za-z]")
_BOUND_LITERAL_RE = re.compile(r"(?:\breturn|=>|(?<![=!<>+\-*/%&|^~])=)\s*$")
_RENDERS_UI_RE = re.compile(
    r"(?:\bText|\bSelectableText)\s*\(|(?<![A-Za-z0-9_])(?:"
    + "|".join(_UI_ARGUMENTS)
    + r")\s*:"
)
_WORD_RE = re.compile(r"[A-Za-z]{3,}")
_UNITS = {
    "bit",
    "bits",
    "bps",
    "dp",
    "fps",
    "gb",
    "gbps",
    "hz",
    "kb",
    "kbps",
    "khz",
    "mb",
    "mbps",
    "mhz",
    "min",
    "mins",
    "ms",
    "px",
    "sec",
    "secs",
    "sp",
    "tb",
}


@dataclass(frozen=True)
class Literal:
    line: int
    value: str
    start: int
    end: int
    raw: bool


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    literal: str
    rule: str


def _interpolation_end(source: str, start: int) -> int:
    """Return the first offset after a balanced ``${...}`` expression."""
    cursor = start + 2
    depth = 1
    while cursor < len(source) and depth:
        if source.startswith("//", cursor):
            newline = source.find("\n", cursor + 2)
            cursor = len(source) if newline < 0 else newline + 1
            continue
        if source.startswith("/*", cursor):
            end = source.find("*/", cursor + 2)
            cursor = len(source) if end < 0 else end + 2
            continue
        raw = (
            source[cursor] in "rR"
            and cursor + 1 < len(source)
            and source[cursor + 1] in "'\""
        )
        quote_start = cursor + 1 if raw else cursor
        if source[quote_start] in "'\"":
            quote_char = source[quote_start]
            quote = (
                quote_char * 3
                if source.startswith(quote_char * 3, quote_start)
                else quote_char
            )
            cursor = quote_start + len(quote)
            while cursor < len(source):
                if not raw and source[cursor] == "\\":
                    cursor += 2
                elif source.startswith(quote, cursor):
                    cursor += len(quote)
                    break
                else:
                    cursor += 1
            continue
        if source[cursor] == "{":
            depth += 1
        elif source[cursor] == "}":
            depth -= 1
        cursor += 1
    return cursor


def _string_literals(source: str) -> list[Literal]:
    """Return Dart string literals while ignoring line and block comments."""
    literals: list[Literal] = []
    index = 0
    length = len(source)
    while index < length:
        if source.startswith("//", index):
            newline = source.find("\n", index + 2)
            index = length if newline < 0 else newline + 1
            continue
        if source.startswith("/*", index):
            depth = 1
            index += 2
            while index < length and depth:
                if source.startswith("/*", index):
                    depth += 1
                    index += 2
                elif source.startswith("*/", index):
                    depth -= 1
                    index += 2
                else:
                    index += 1
            continue

        raw = False
        token_start = index
        if (
            source[index] in "rR"
            and index + 1 < length
            and source[index + 1] in "'\""
            and (index == 0 or not (source[index - 1].isalnum() or source[index - 1] == "_"))
        ):
            raw = True
            index += 1
        if source[index] not in "'\"":
            index += 1
            continue

        quote_char = source[index]
        quote = quote_char * 3 if source.startswith(quote_char * 3, index) else quote_char
        body_start = index + len(quote)
        cursor = body_start
        while cursor < length:
            if not raw and source[cursor] == "\\":
                cursor += 2
                continue
            if not raw and source.startswith("${", cursor):
                cursor = _interpolation_end(source, cursor)
                continue
            if source.startswith(quote, cursor):
                end = cursor + len(quote)
                literals.append(
                    Literal(
                        line=source.count("\n", 0, token_start) + 1,
                        value=source[body_start:cursor],
                        start=token_start,
                        end=end,
                        raw=raw,
                    )
                )
                index = end
                break
            if len(quote) == 1 and source[cursor] == "\n":
                index = cursor + 1
                break
            cursor += 1
        else:
            index = length
    return literals


def _literal_text(value: str) -> str:
    """Return the literal with every interpolation replaced by whitespace."""
    literal_parts: list[str] = []
    cursor = 0
    while cursor < len(value):
        if value.startswith("${", cursor):
            literal_parts.append(" ")
            cursor = _interpolation_end(value, cursor)
        elif value[cursor] == "$" and cursor + 1 < len(value) and (
            value[cursor + 1].isalpha() or value[cursor + 1] == "_"
        ):
            cursor += 2
            while cursor < len(value) and (value[cursor].isalnum() or value[cursor] == "_"):
                cursor += 1
        else:
            literal_parts.append(value[cursor])
            cursor += 1
    return "".join(literal_parts)


def _literal_words(value: str) -> list[str]:
    return [word.lower() for word in _WORD_RE.findall(_literal_text(value))]


def _contains_english(value: str) -> bool:
    words = _literal_words(value)
    return bool(words) and not all(word in _UNITS for word in words)


def _statement_prefix(source: str, start: int) -> str:
    boundary = source.rfind(";", 0, start)
    return source[boundary + 1 : start]


def _is_excluded_context(source: str, literal: Literal) -> bool:
    statement_prefix = _statement_prefix(source, literal.start)
    if re.match(r"\s*(?:import|part)\b", statement_prefix):
        return True

    prefix = source[max(0, literal.start - 300) : literal.start]
    if _EXCLUDED_ARGUMENT_RE.search(prefix) or _KEY_RE.search(prefix):
        return True
    return bool(_DIAGNOSTIC_RE.search(statement_prefix))


def _rule_for_literal(source: str, literal: Literal, renders_ui: bool = False) -> str | None:
    if not _contains_english(literal.value) or _is_excluded_context(source, literal):
        return None

    prefix = source[max(0, literal.start - 300) : literal.start]
    if not literal.raw and _TRANSLATION_INTERPOLATION_RE.search(literal.value):
        if not (re.search(r"\$\{\s*t\.", literal.value) and _T_PARAMETER_RE.search(prefix)):
            return "mixed translation interpolation"
    if _TEXT_RE.search(prefix):
        return "Text first argument"
    if _UI_ARGUMENT_RE.search(prefix):
        return "UI named argument"
    if (
        renders_ui
        and _PHRASE_RE.search(_literal_text(literal.value))
        and _BOUND_LITERAL_RE.search(_statement_prefix(source, literal.start))
    ):
        return "display string bound to a name"
    return None


def load_allowlist(path: Path | None = None) -> dict[str, dict[str, str]]:
    path = ALLOWLIST_PATH if path is None else path
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("allowlist root must be an object")
    for relative_path, entries in data.items():
        if not isinstance(relative_path, str) or not isinstance(entries, dict):
            raise ValueError("allowlist entries must map paths to objects")
        for literal, reason in entries.items():
            if not isinstance(literal, str) or not isinstance(reason, str) or not reason.strip():
                raise ValueError(f"allowlist entry {relative_path!r} / {literal!r} needs a reason")
    return data


def _is_allowlisted(path: str, literal: str, allowlist: dict[str, dict[str, str]]) -> bool:
    return literal in allowlist.get(path, {}) or literal in allowlist.get("*", {})


def scan(
    lib_dir: Path | None = None,
    allowlist: dict[str, dict[str, str]] | None = None,
    root: Path | None = None,
) -> tuple[list[Finding], dict[str, set[str]]]:
    lib_dir = LIB_DIR if lib_dir is None else lib_dir
    root = ROOT if root is None else root
    if allowlist is None:
        allowlist = load_allowlist()
    findings: list[Finding] = []
    seen_literals: dict[str, set[str]] = {}
    for path in sorted(lib_dir.rglob("*.dart")):
        relative = path.relative_to(root).as_posix()
        # lib/dev is a separate, non-app measurement entrypoint.
        if (
            relative.startswith(("lib/i18n/", "lib/dev/"))
            or path.name.endswith((".g.dart", ".freezed.dart"))
        ):
            continue
        source = path.read_text(encoding="utf-8")
        literals = _string_literals(source)
        renders_ui = bool(_RENDERS_UI_RE.search(source))
        seen_literals[relative] = {literal.value for literal in literals}
        for literal in literals:
            rule = _rule_for_literal(source, literal, renders_ui)
            if rule is None or _is_allowlisted(relative, literal.value, allowlist):
                continue
            findings.append(Finding(relative, literal.line, literal.value, rule))
    return findings, seen_literals


def stale_allowlist_entries(
    allowlist: dict[str, dict[str, str]], seen_literals: dict[str, set[str]]
) -> list[tuple[str, str]]:
    all_literals = set().union(*seen_literals.values()) if seen_literals else set()
    stale: list[tuple[str, str]] = []
    for path, entries in allowlist.items():
        present = all_literals if path == "*" else seen_literals.get(path, set())
        stale.extend((path, literal) for literal in entries if literal not in present)
    return sorted(stale)


def _print_findings(findings: list[Finding]) -> None:
    current_path = None
    for finding in findings:
        if finding.path != current_path:
            if current_path is not None:
                print()
            current_path = finding.path
            print(f"{finding.path}:")
        print(f"  {finding.line}: [{finding.rule}] {finding.literal!r}")
    print(f"\nFound {len(findings)} hardcoded user-facing string(s).")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument(
        "--allowlist", type=Path, default=ALLOWLIST_PATH, help="path to the JSON allowlist"
    )
    parser.add_argument(
        "--allowlist-missing",
        action="store_true",
        help="report allowlist entries whose literal no longer exists",
    )
    args = parser.parse_args(argv)

    try:
        allowlist = load_allowlist(args.allowlist)
        findings, seen_literals = scan(args.root / "lib", allowlist, args.root)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"error: {error}")
        return 1

    if args.allowlist_missing:
        stale = stale_allowlist_entries(allowlist, seen_literals)
        if stale:
            print("Allowlist entries that no longer match a source literal:")
            for path, literal in stale:
                print(f"  {path}: {literal!r}")
            return 1
        print("All hardcoded-string allowlist entries still match source literals.")
        return 0

    if findings:
        _print_findings(findings)
        return 1
    print("No hardcoded user-facing English strings found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
