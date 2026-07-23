#!/usr/bin/env python3
"""Require immutable commit pins for remote GitHub Actions dependencies."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORKFLOWS = ROOT / ".github" / "workflows"
MAPPING_RE = re.compile(
    r"""^\s*(?:-\s*)?(?P<key>uses|'(?:''|[^'])*'|"(?:\\.|[^"\\])*")\s*:\s*(?P<value>.*?)\s*$"""
)
EXPLICIT_KEY_RE = re.compile(
    r"""^\s*(?:-\s*)?\?\s*(?P<key>uses|'(?:''|[^'])*'|"(?:\\.|[^"\\])*")\s*$"""
)
EXPLICIT_VALUE_RE = re.compile(r"^\s*:\s*(?P<value>.*?)\s*$")
REMOTE_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_./-]+)?@[0-9a-fA-F]{40}$")
BLOCK_SCALAR_RE = re.compile(r":\s*[|>](?:[1-9][+-]?|[+-][1-9]?)?\s*(?:#.*)?$")
BLOCK_SCALAR_VALUE_RE = re.compile(r"^[|>](?:[1-9][+-]?|[+-][1-9]?)?$")
YAML_DOUBLE_ESCAPES = {
    "0": "\0",
    "a": "\a",
    "b": "\b",
    "t": "\t",
    "\t": "\t",
    "n": "\n",
    "v": "\v",
    "f": "\f",
    "r": "\r",
    "e": "\x1b",
    " ": " ",
    '"': '"',
    "/": "/",
    "\\": "\\",
    "N": "\u0085",
    "_": "\u00a0",
    "L": "\u2028",
    "P": "\u2029",
}


def iter_workflow_files(directory: Path = WORKFLOWS):
    yield from sorted((*directory.glob("*.yml"), *directory.glob("*.yaml")))


def _strip_yaml_comment(value: str) -> str:
    quote = None
    escaped = False
    for index, char in enumerate(value):
        if escaped:
            escaped = False
            continue
        if char == "\\" and quote == '"':
            escaped = True
            continue
        if char in ("'", '"'):
            if quote is None:
                quote = char
            elif quote == char:
                quote = None
            continue
        if char == "#" and quote is None and (index == 0 or value[index - 1].isspace()):
            return value[:index].rstrip()
    return value.rstrip()


def _decode_quoted_yaml_string(value: str) -> str | None:
    if len(value) < 2 or value[0] != value[-1] or value[0] not in ("'", '"'):
        return None
    if value[0] == "'":
        return value[1:-1].replace("''", "'")

    decoded = []
    index = 1
    end = len(value) - 1
    while index < end:
        char = value[index]
        if char != "\\":
            decoded.append(char)
            index += 1
            continue
        index += 1
        if index >= end:
            return None
        escape = value[index]
        if escape in YAML_DOUBLE_ESCAPES:
            decoded.append(YAML_DOUBLE_ESCAPES[escape])
            index += 1
            continue
        width = {"x": 2, "u": 4, "U": 8}.get(escape)
        if width is None or index + width >= end:
            return None
        digits = value[index + 1 : index + 1 + width]
        if not re.fullmatch(rf"[0-9a-fA-F]{{{width}}}", digits):
            return None
        try:
            decoded.append(chr(int(digits, 16)))
        except ValueError:
            return None
        index += width + 1
    return "".join(decoded)


def _unquote(value: str) -> str:
    decoded = _decode_quoted_yaml_string(value)
    return value if decoded is None else decoded


def _flow_value(line: str, start: int, mapping_depth: int) -> str:
    index = start
    quote = None
    escaped = False
    depth = mapping_depth
    while index < len(line):
        char = line[index]
        if escaped:
            escaped = False
        elif char == "\\" and quote == '"':
            escaped = True
        elif quote is not None:
            if char == quote:
                quote = None
        elif char in ("'", '"'):
            quote = char
        elif char in ("{", "["):
            depth += 1
        elif char in ("}", "]"):
            if depth == mapping_depth:
                break
            depth -= 1
        elif char == "," and depth == mapping_depth:
            break
        index += 1
    return _unquote(line[start:index].strip())


def _has_unsupported_block_mapping_key(line: str) -> bool:
    candidate = line.lstrip()
    if candidate.startswith("-") and not candidate.startswith("---"):
        candidate = candidate[1:].lstrip()
    if not candidate:
        return False
    if candidate[0] in "!&*":
        return True
    if candidate[0] not in ("'", '"'):
        return False

    quote = candidate[0]
    escaped = False
    index = 1
    while index < len(candidate):
        char = candidate[index]
        if quote == "'" and char == "'" and index + 1 < len(candidate) and candidate[index + 1] == "'":
            index += 2
            continue
        if escaped:
            escaped = False
        elif quote == '"' and char == "\\":
            escaped = True
        elif char == quote:
            return False
        index += 1
    return True


def _flow_uses_references(line: str, initial_depth: int) -> tuple[list[str], int]:
    references = []
    depth = initial_depth
    index = 0
    while index < len(line):
        char = line[index]
        if char in ("'", '"'):
            quote = char
            escaped = False
            end = index + 1
            while end < len(line):
                quoted_char = line[end]
                if escaped:
                    escaped = False
                elif quoted_char == "\\" and quote == '"':
                    escaped = True
                elif quoted_char == quote:
                    break
                end += 1
            if end >= len(line):
                if depth > 0:
                    references.append("<unsupported multiline flow scalar>")
                return references, depth
            key = _decode_quoted_yaml_string(line[index : end + 1])
            after_key = end + 1
            while after_key < len(line) and line[after_key].isspace():
                after_key += 1
            if depth > 0 and after_key < len(line) and line[after_key] == ":":
                if key == "uses":
                    references.append(_flow_value(line, after_key + 1, depth))
                elif key is None:
                    references.append("<unsupported quoted flow mapping key>")
            index = end + 1
            continue
        if line.startswith("${{", index):
            expression_end = line.find("}}", index + 3)
            if expression_end < 0:
                references.append("<unterminated GitHub expression>")
                return references, depth
            index = expression_end + 2
            continue
        if char in ("{", "["):
            depth += 1
            index += 1
            continue
        if char in ("}", "]"):
            depth = max(0, depth - 1)
            index += 1
            continue
        if depth > 0 and char == "?":
            references.append("<unsupported explicit flow mapping>")
            index += 1
            continue
        if depth > 0 and char in "!&*":
            references.append("<unsupported tagged, anchored, or aliased flow mapping>")
            index += 1
            continue
        if depth > 0 and (char.isalpha() or char == "_"):
            end = index + 1
            while end < len(line) and (line[end].isalnum() or line[end] in "_-"):
                end += 1
            after_key = end
            while after_key < len(line) and line[after_key].isspace():
                after_key += 1
            if line[index:end] == "uses" and after_key < len(line) and line[after_key] == ":":
                references.append(_flow_value(line, after_key + 1, depth))
            index = end
            continue
        index += 1
    return references, depth


def iter_uses_references(path: Path):
    block_parent_indent = None
    block_content_indent = None
    block_uses_line = None
    block_uses_content: list[str] = []
    explicit_uses_line = None
    flow_start_line = None
    flow_depth = 0
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = raw_line.lstrip()
        indent = len(raw_line) - len(stripped)
        if block_parent_indent is not None:
            if not stripped:
                if block_uses_line is not None:
                    block_uses_content.append("")
                continue
            if indent <= block_parent_indent:
                if block_uses_line is not None:
                    yield block_uses_line, "\n".join(block_uses_content).strip()
                block_parent_indent = None
                block_content_indent = None
                block_uses_line = None
                block_uses_content = []
            elif block_content_indent is None:
                block_content_indent = indent
                if block_uses_line is not None:
                    block_uses_content.append(raw_line[block_content_indent:])
                continue
            elif indent >= block_content_indent:
                if block_uses_line is not None:
                    block_uses_content.append(raw_line[block_content_indent:])
                continue
            else:
                if block_uses_line is not None:
                    yield block_uses_line, "\n".join(block_uses_content).strip()
                block_parent_indent = None
                block_content_indent = None
                block_uses_line = None
                block_uses_content = []
        if stripped.startswith("#") or not stripped:
            continue
        active_line = _strip_yaml_comment(raw_line)
        if explicit_uses_line is not None:
            explicit_value = EXPLICIT_VALUE_RE.match(active_line)
            if explicit_value is None:
                yield explicit_uses_line, "<missing explicit mapping value>"
            else:
                value = explicit_value.group("value").strip()
                if BLOCK_SCALAR_VALUE_RE.fullmatch(value):
                    block_parent_indent = indent
                    block_content_indent = None
                    block_uses_line = explicit_uses_line
                    block_uses_content = []
                else:
                    yield explicit_uses_line, _unquote(value)
                explicit_uses_line = None
                continue
            explicit_uses_line = None
        explicit_key = EXPLICIT_KEY_RE.match(active_line)
        if explicit_key:
            if _unquote(explicit_key.group("key")) == "uses":
                explicit_uses_line = line_number
            continue
        if re.match(r"^\s*(?:-\s*)?\?", active_line):
            yield line_number, "<unsupported explicit mapping key>"
            continue
        if _has_unsupported_block_mapping_key(active_line):
            yield line_number, "<unsupported multiline, tagged, anchored, or aliased mapping key>"
            continue
        match = MAPPING_RE.match(active_line) if flow_depth == 0 else None
        if match:
            key = _unquote(match.group("key"))
            value = match.group("value").strip()
            if BLOCK_SCALAR_VALUE_RE.fullmatch(value):
                block_parent_indent = indent
                block_content_indent = None
                if key == "uses":
                    block_uses_line = line_number
                    block_uses_content = []
                continue
            if key == "uses":
                yield line_number, _unquote(value)
        if BLOCK_SCALAR_RE.search(raw_line):
            block_parent_indent = indent
            block_content_indent = None
            continue
        previous_flow_depth = flow_depth
        flow_references, flow_depth = _flow_uses_references(active_line, flow_depth)
        for reference in flow_references:
            yield line_number, reference
        if previous_flow_depth == 0 and flow_depth > 0:
            flow_start_line = line_number
        elif flow_depth == 0:
            flow_start_line = None
    if explicit_uses_line is not None:
        yield explicit_uses_line, "<missing explicit mapping value>"
    if flow_depth > 0:
        yield flow_start_line or 1, "<unterminated flow collection>"
    if block_uses_line is not None:
        yield block_uses_line, "\n".join(block_uses_content).strip()


def validate_reference(reference: str) -> str | None:
    if reference.startswith("./"):
        return None
    if REMOTE_RE.fullmatch(reference):
        return None
    return "remote actions must use a full 40-character commit SHA"


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    paths = [Path(value) for value in args] if args else list(iter_workflow_files())
    violations = []
    for path in paths:
        for line_number, reference in iter_uses_references(path):
            reason = validate_reference(reference)
            if reason:
                try:
                    display_path = path.resolve().relative_to(ROOT)
                except ValueError:
                    display_path = path
                violations.append(f"{display_path}:{line_number}: {reference!r}: {reason}")
    if violations:
        print("Mutable or malformed GitHub Actions references:", file=sys.stderr)
        for violation in violations:
            print(f"  {violation}", file=sys.stderr)
        return 1
    print(f"Workflow action pins verified ({len(paths)} files).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
