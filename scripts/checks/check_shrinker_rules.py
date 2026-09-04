#!/usr/bin/env python3
"""Validate that name-reached Android classes and members survive R8.

Flutter minifies every release build, so anything the app reaches only by name is
invisible to R8 and gets shrunk or renamed away. Four such surfaces exist:

* app-module classes placed in a library namespace so that library discovers them with
  ``Class.forName`` (the bundled ``androidx.media3.decoder.ffmpeg`` audio decoder);
* classes resolved from native code with ``FindClass``;
* members resolved from native code with ``Get*MethodID``/``Get*FieldID``, including
  every type named in the descriptor those lookups pass;
* classes and members resolved by name from Kotlin/Java itself with ``Class.forName``
  and ``getDeclaredField``/``getDeclaredMethod`` (the Matroska extractor wrappers reach
  private ``MatroskaExtractor`` fields this way), in every ``android/**/src/main``
  source root including the ``libass`` module.

None of these lookups leaves a reference R8 can see, so only the keep rules R8
actually receives — ``android/app/proguard-rules.pro`` plus each library module's
``consumer-rules.pro`` — protect their targets, and losing a keep surfaces solely
as broken behaviour in a release build. Both the native and JVM checks cover every
module under ``android/``.
"""

from __future__ import annotations

import argparse
import os
import re
from pathlib import Path

PROGUARD_RULES = Path("android/app/proguard-rules.pro")
ANDROID_ROOT = Path("android")
NATIVE_SUFFIXES = {".c", ".cc", ".cpp", ".h", ".hpp"}
JVM_SUFFIXES = {".kt", ".java"}
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
_JVM_PACKAGE = re.compile(r"^\s*package\s+([\w.]+)", re.MULTILINE)
_JVM_IMPORT = re.compile(r"^\s*import\s+(?:static\s+)?([\w.]+)(?:\s+as\s+(\w+))?\s*;?\s*$", re.MULTILINE)
# The closing paren keeps a concatenated argument ("pkg." + name) from being
# half-claimed as a bare literal prefix; such calls fall through to the sweep.
_JVM_CLASS_FOR_NAME = re.compile(r"\bClass\s*\.\s*forName\s*\(\s*" + _STRING_LITERAL.pattern + r"\s*\)")
# Receiver forms this check can resolve statically: Type::class.java (Kotlin) and
# Type.class (Java). Anything else (javaClass, a variable) leaves group 1 empty.
_JVM_MEMBER_LOOKUP = re.compile(
    r"(?:\b([\w.]+)(?:::class(?:\s*\.\s*java)?|\.class)\s*)?"
    r"\.\s*getDeclared(?:Field|Method)\s*\(\s*" + _STRING_LITERAL.pattern
)

# Every reflective-lookup shape this check can see at all. The literal-matching
# patterns above must claim each occurrence; anything left over is a lookup the
# check cannot trace, and the sweep in [_check_jvm_reflection] fails loud on it
# instead of silently passing a release build that R8 may shrink into breaking.
_JVM_CLASS_FOR_NAME_ANY = re.compile(r"\bClass\s*\.\s*forName\s*\(")
_JVM_MEMBER_LOOKUP_ANY = re.compile(r"\.\s*getDeclared(?:Field|Method)\s*\(")

# Only -keep variants without allowshrinking/allowobfuscation keep names.
_KEEP = re.compile(
    r"^-(keepclasseswithmembernames|keepclasseswithmembers|keepclassmembernames|keepclassmembers|keepnames|keep)"
    r"((?:\s*,\s*\w+)*)\s+(?:class|interface|enum)\s+(\S+)"
    r"(?:\s*\{(.*?)\})?",
    re.MULTILINE | re.DOTALL,
)
_UNSAFE_MODIFIERS = ("allowshrinking", "allowobfuscation")
# Directives that keep the class itself alive and un-renamed — what a name-only class
# lookup (Class.forName / FindClass) needs.
_CLASS_KEEP_DIRECTIVES = frozenset({"keep", "keepclasseswithmembers"})
# Directives that keep matched members alive and un-renamed — what a member with no
# compile-time reference at all (JNI Get*MethodID/Get*FieldID) needs. The ...names
# variants allow shrinking, which would delete a natively-reached member outright.
_MEMBER_KEEP_DIRECTIVES = frozenset({"keep", "keepclassmembers", "keepclasseswithmembers"})


class Keep:
    """One parsed ``-keep`` rule: directive, class-name pattern, and member block."""

    def __init__(self, directive: str, pattern: str, modifiers: str, members: str) -> None:
        self.directive = directive
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
    def keeps_class_name(self) -> bool:
        return self.directive in _CLASS_KEEP_DIRECTIVES

    @property
    def keeps_member_alive(self) -> bool:
        return self.directive in _MEMBER_KEEP_DIRECTIVES

    @property
    def includes_descriptor_classes(self) -> bool:
        return "includedescriptorclasses" in self.modifiers


def _parse_keeps(rules: str) -> list[Keep]:
    keeps = []
    for match in _KEEP.finditer(rules):
        modifiers = match.group(2) or ""
        if any(modifier in modifiers for modifier in _UNSAFE_MODIFIERS):
            continue
        keeps.append(Keep(match.group(1), match.group(3).replace("$", "."), modifiers, match.group(4) or ""))
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
    """Native sources in every module's ``src/main/cpp`` under ``android/``."""
    return sorted(
        path
        for main in _main_source_dirs(root)
        if (main / "cpp").is_dir()
        for path in (main / "cpp").rglob("*")
        if path.suffix in NATIVE_SUFFIXES
    )


def _main_source_dirs(root: Path) -> list[Path]:
    """Every ``src/main`` directory in every module under ``android/``."""
    android = root / ANDROID_ROOT
    if not android.is_dir():
        return []
    mains = []
    for current, dirnames, _ in os.walk(android):
        dirnames[:] = [name for name in dirnames if name not in ("build", ".gradle", ".cxx")]
        path = Path(current)
        if path.name == "main" and path.parent.name == "src":
            mains.append(path)
            dirnames[:] = []
    return sorted(mains)


def _jvm_language_roots(root: Path) -> list[Path]:
    return sorted(
        language_root
        for main in _main_source_dirs(root)
        for language_root in (main / "java", main / "kotlin")
        if language_root.is_dir()
    )


def _jvm_sources(root: Path) -> list[Path]:
    return sorted(
        {
            path
            for language_root in _jvm_language_roots(root)
            for path in language_root.rglob("*")
            if path.suffix in JVM_SUFFIXES
        }
    )


def _reflected_classes(root: Path) -> list[str]:
    classes = set()
    for language_root in _jvm_language_roots(root):
        for source in language_root.rglob("*"):
            if source.suffix not in JVM_SUFFIXES:
                continue
            relative = source.relative_to(language_root).as_posix()
            if relative.startswith(REFLECTED_NAMESPACES):
                classes.add(_binary_name(relative[: -len(source.suffix)]))
    return sorted(classes)


def _check_native_lookups(root: Path, keeps: list[Keep], errors: list[str]) -> None:
    for source in _native_sources(root):
        text = _collapse_adjacent_literals(source.read_text(encoding="utf-8"))
        owners = {match.group(1): _binary_name(match.group(2)) for match in _JCLASS_ASSIGNMENT.finditer(text)}
        label = source.relative_to(root).as_posix()

        for owner in sorted(set(owners.values())):
            if owner.startswith(PLATFORM_PREFIXES):
                # Bootclasspath classes are not in the app dex; R8 cannot touch them.
                continue
            if not any(keep.keeps_class_name and keep.matches_class(owner) for keep in keeps):
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
            if owner.startswith(PLATFORM_PREFIXES):
                continue
            matching = [keep for keep in keeps if keep.matches_class(owner)]
            if not any(keep.keeps_member_alive and keep.keeps_member(member) for keep in matching):
                errors.append(f"{label} resolves {owner}.{member} from native code but no -keep retains that member")
            for referenced in _DESCRIPTOR_CLASS.findall(descriptor):
                name = _binary_name(referenced)
                if name.startswith(PLATFORM_PREFIXES):
                    continue
                if any(keep.includes_descriptor_classes for keep in matching):
                    continue
                if not any(keep.keeps_class_name and keep.matches_class(name) for keep in keeps):
                    errors.append(
                        f"{label} names {name} in the descriptor of {owner}.{member}, so renaming it breaks the "
                        f"lookup, but no -keep covers it (or mark the owner -keep,includedescriptorclasses)"
                    )


def _jvm_imports(text: str) -> dict[str, str]:
    imports = {}
    for match in _JVM_IMPORT.finditer(text):
        qualified, alias = match.group(1), match.group(2)
        imports[alias or qualified.rpartition(".")[2]] = qualified
    return imports


def _resolve_receiver(receiver: str, package: str, imports: dict[str, str]) -> str:
    head, _, rest = receiver.partition(".")
    qualified = imports.get(head)
    if qualified is not None:
        return f"{qualified}.{rest}" if rest else qualified
    if rest:
        # No matching import and already dotted: written package-qualified inline.
        return receiver
    return f"{package}.{receiver}" if package else receiver


def _check_jvm_reflection(root: Path, keeps: list[Keep], errors: list[str]) -> None:
    for source in _jvm_sources(root):
        text = source.read_text(encoding="utf-8")
        label = source.relative_to(root).as_posix()
        package_match = _JVM_PACKAGE.search(text)
        package = package_match.group(1) if package_match else ""
        imports = _jvm_imports(text)

        claimed = [match.span() for match in _JVM_CLASS_FOR_NAME.finditer(text)]
        claimed += [match.span() for match in _JVM_MEMBER_LOOKUP.finditer(text)]

        def _unclaimed(pattern: re.Pattern[str]) -> list[re.Match[str]]:
            return [
                match
                for match in pattern.finditer(text)
                if not any(start <= match.start() and match.end() <= end for start, end in claimed)
            ]

        for match in _JVM_CLASS_FOR_NAME.finditer(text):
            name = _binary_name(match.group(1))
            if name.startswith(PLATFORM_PREFIXES):
                continue
            if not any(keep.keeps_class_name and keep.matches_class(name) for keep in keeps):
                errors.append(f"{label} resolves {name} with Class.forName but no -keep covers it")

        for match in _JVM_MEMBER_LOOKUP.finditer(text):
            receiver, member = match.group(1), match.group(2)
            if receiver is None:
                errors.append(
                    f"{label} looks up member '{member}' reflectively on a receiver this check cannot "
                    f"resolve to a class; name the type (Type::class.java / Type.class) or extend "
                    f"{Path(__file__).name}"
                )
                continue
            owner = _resolve_receiver(receiver, package, imports)
            if owner.startswith(PLATFORM_PREFIXES):
                continue
            # The receiver names the owner in code, so the class survives on its own;
            # only the member *name* is invisible to R8. Any keep flavour that pins the
            # name — including -keepclassmembernames, which deliberately lets genuinely
            # unused members shrink — satisfies the lookup.
            if not any(keep.matches_class(owner) and keep.keeps_member(member) for keep in keeps):
                errors.append(
                    f"{label} resolves {owner}.{member} with getDeclaredField/getDeclaredMethod "
                    f"but no -keep rule pins that member name"
                )

        # Fail loud on reflective lookups the literal patterns cannot claim: a
        # constant, variable, or concatenated name is invisible to this check,
        # so staying silent would green-light a release build R8 may break.
        for _ in _unclaimed(_JVM_CLASS_FOR_NAME_ANY):
            errors.append(
                f"{label} calls Class.forName with a name this check cannot trace to a single string "
                f"literal; inline the name or extend {Path(__file__).name}"
            )
        for _ in _unclaimed(_JVM_MEMBER_LOOKUP_ANY):
            errors.append(
                f"{label} looks up a member with getDeclaredField/getDeclaredMethod under a name this "
                f"check cannot trace to a single string literal; inline the name or extend "
                f"{Path(__file__).name}"
            )


def validate(root: Path) -> list[str]:
    root = root.resolve()
    reflected = _reflected_classes(root)
    has_native = bool(_native_sources(root))
    has_jvm = bool(_jvm_sources(root))
    if not reflected and not has_native and not has_jvm:
        return []

    rules_path = root / PROGUARD_RULES
    if not rules_path.is_file():
        return [
            f"{PROGUARD_RULES.as_posix()} is missing, so R8 will shrink name-reached classes out of release "
            f"builds{': ' + ', '.join(reflected) if reflected else ''}"
        ]

    rules_text = rules_path.read_text(encoding="utf-8")
    # AGP feeds every library module's consumer rules into the app's R8
    # invocation, so keeps there are as effective as the app's own.
    for consumer_rules in sorted((root / ANDROID_ROOT).glob("*/consumer-rules.pro")):
        rules_text += "\n" + consumer_rules.read_text(encoding="utf-8")
    keeps = _parse_keeps(rules_text)
    errors = []
    for binary_name in reflected:
        if not any(keep.keeps_class_name and keep.matches_class(binary_name) for keep in keeps):
            errors.append(
                f"{binary_name} lives in a reflected namespace but no -keep in {PROGUARD_RULES.as_posix()} covers it"
            )
    _check_native_lookups(root, keeps, errors)
    _check_jvm_reflection(root, keeps, errors)
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
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
