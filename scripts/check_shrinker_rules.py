#!/usr/bin/env python3
"""Validate that name-reached Android classes and members survive R8.

Flutter minifies every release build, so anything the app reaches only by name is
invisible to R8 and gets shrunk or renamed away. Three such surfaces exist:

* app-module classes placed in a library namespace so that library discovers them with
  ``Class.forName`` (the bundled ``androidx.media3.decoder.ffmpeg`` audio decoder);
* classes resolved from native code with ``FindClass``;
* members resolved from native code with ``Get*MethodID``/``Get*FieldID``, including
  every type named in the descriptor those lookups pass.

None of them has a compile-time reference, so only ``android/app/proguard-rules.pro``
keeps them, and losing a keep surfaces solely as broken behaviour in a release build.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

PROGUARD_RULES = Path("android/app/proguard-rules.pro")
APP_JAVA_ROOT = Path("android/app/src/main/java")
CPP_ROOT = Path("android/app/src/main/cpp")
NATIVE_SUFFIXES = {".c", ".cc", ".cpp", ".h", ".hpp"}
# Dependency namespaces reached only through reflection have no direct callers.
REFLECTED_NAMESPACES = ("androidx/media3/",)
# Bootclasspath framework types are not in the app dex and need no keep rule.
PLATFORM_PREFIXES = ("java.", "javax.", "android.")

_STRING_LITERAL = re.compile(r'"((?:[^"\\]|\\.)*)"')
_ADJACENT_LITERALS = re.compile(r'"((?:[^"\\]|\\.)*)"\s*"((?:[^"\\]|\\.)*)"')
_JCLASS_ASSIGNMENT = re.compile(r"(\w+)\s*=\s*[\w:>.\-]*?FindClass\(\s*" + _STRING_LITERAL.pattern + r"\s*\)")
_MEMBER_LOOKUP = re.compile(
    r"Get(?:Static)?(?:Method|Field)ID\(\s*(\w+)\s*,\s*"
    + _STRING_LITERAL.pattern
    + r"\s*,\s*"
    + _STRING_LITERAL.pattern
    + r"\s*\)"
)
_DESCRIPTOR_CLASS = re.compile(r"L([\w/$]+);")
# Only -keep variants without allowshrinking/allowobfuscation keep classes and names.
_KEEP = re.compile(
    r"^-(?:keep|keepclasseswithmembers)((?:\s*,\s*\w+)*)\s+(?:class|interface|enum)\s+(\S+)"
    r"(?:\s*\{(.*?)\})?",
    re.MULTILINE | re.DOTALL,
)
_UNSAFE_MODIFIERS = ("allowshrinking", "allowobfuscation")


class Keep:
    """One parsed ``-keep`` rule: a class-name pattern plus its member block."""

    def __init__(self, pattern: str, modifiers: str, members: str) -> None:
        self.pattern = pattern
        self.modifiers = modifiers
        self.members = members
        self._regex = re.compile(
            "".join(
                # ** crosses package separators; * and ? match within a segment.
                {"**": r".*", "*": r"[^.]*", "?": r"."}.get(token, re.escape(token))
                for token in re.findall(r"\*\*|[*?]|[^*?]+", pattern)
            )
        )

    def matches_class(self, binary_name: str) -> bool:
        return self._regex.fullmatch(binary_name) is not None

    def keeps_member(self, member: str) -> bool:
        return "*" in self.members or member in self.members

    @property
    def includes_descriptor_classes(self) -> bool:
        return "includedescriptorclasses" in self.modifiers


def _parse_keeps(rules: str) -> list[Keep]:
    keeps = []
    for match in _KEEP.finditer(rules):
        modifiers = match.group(1) or ""
        if any(modifier in modifiers for modifier in _UNSAFE_MODIFIERS):
            continue
        keeps.append(Keep(match.group(2).replace("$", "."), modifiers, match.group(3) or ""))
    return keeps


def _collapse_adjacent_literals(source: str) -> str:
    """Join C string-literal concatenation so descriptors read as one token."""
    previous = None
    while previous != source:
        previous = source
        source = _ADJACENT_LITERALS.sub(lambda m: f'"{m.group(1)}{m.group(2)}"', source)
    return source


def _binary_name(jni_name: str) -> str:
    return jni_name.replace("/", ".").replace("$", ".")


def _native_sources(root: Path) -> list[Path]:
    cpp_root = root / CPP_ROOT
    if not cpp_root.is_dir():
        return []
    return sorted(path for path in cpp_root.rglob("*") if path.suffix in NATIVE_SUFFIXES)


def _reflected_classes(root: Path) -> list[str]:
    java_root = root / APP_JAVA_ROOT
    if not java_root.is_dir():
        return []
    classes = []
    for source in sorted(java_root.rglob("*.java")):
        relative = source.relative_to(java_root).as_posix()
        if relative.startswith(REFLECTED_NAMESPACES):
            classes.append(_binary_name(relative[: -len(".java")]))
    return classes


def _check_native_lookups(root: Path, keeps: list[Keep], errors: list[str]) -> None:
    for source in _native_sources(root):
        text = _collapse_adjacent_literals(source.read_text(encoding="utf-8"))
        owners = {match.group(1): _binary_name(match.group(2)) for match in _JCLASS_ASSIGNMENT.finditer(text)}
        label = source.relative_to(root).as_posix()

        for owner in sorted(set(owners.values())):
            if not any(keep.matches_class(owner) for keep in keeps):
                errors.append(f"{label} resolves {owner} with FindClass but no -keep covers it")

        for match in _MEMBER_LOOKUP.finditer(text):
            variable, member, descriptor = match.group(1), match.group(2), match.group(3)
            owner = owners.get(variable)
            if owner is None:
                errors.append(
                    f"{label} looks up member '{member}' on '{variable}', which this check cannot trace "
                    f"back to a FindClass call; assign the jclass from FindClass or extend {Path(__file__).name}"
                )
                continue
            matching = [keep for keep in keeps if keep.matches_class(owner)]
            if not any(keep.keeps_member(member) for keep in matching):
                errors.append(f"{label} resolves {owner}.{member} from native code but no -keep retains that member")
            for referenced in _DESCRIPTOR_CLASS.findall(descriptor):
                name = _binary_name(referenced)
                if name.startswith(PLATFORM_PREFIXES):
                    continue
                if any(keep.includes_descriptor_classes for keep in matching):
                    continue
                if not any(keep.matches_class(name) for keep in keeps):
                    errors.append(
                        f"{label} names {name} in the descriptor of {owner}.{member}, so renaming it breaks the "
                        f"lookup, but no -keep covers it (or mark the owner -keep,includedescriptorclasses)"
                    )


def validate(root: Path) -> list[str]:
    root = root.resolve()
    reflected = _reflected_classes(root)
    has_native = bool(_native_sources(root))
    if not reflected and not has_native:
        return []

    rules_path = root / PROGUARD_RULES
    if not rules_path.is_file():
        return [
            f"{PROGUARD_RULES} is missing, so R8 will shrink name-reached classes out of release "
            f"builds{': ' + ', '.join(reflected) if reflected else ''}"
        ]

    keeps = _parse_keeps(rules_path.read_text(encoding="utf-8"))
    errors = []
    for binary_name in reflected:
        if not any(keep.matches_class(binary_name) for keep in keeps):
            errors.append(
                f"{binary_name} lives in a reflected namespace but no -keep in {PROGUARD_RULES} covers it"
            )
    _check_native_lookups(root, keeps, errors)
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args(argv)
    errors = validate(args.root)
    if errors:
        for error in errors:
            print(f"error: {error}")
        return 1
    print("Name-reached Android classes and members are covered by shrinker keep rules.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
