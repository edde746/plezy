#!/usr/bin/env python3
"""Fail when a raw exception reaches a user-facing snackbar.

`MediaServerException.toString()` renders the Dart runtime type, the English
log message, and for `MediaServerHttpException` the request host and path.
None of that belongs in the UI: `lib/utils/error_message_utils.dart` exists to
turn a failure into localized, user-safe text, and every exception already
carries an optional `display` field for the same purpose.

Use `localizedErrorReason(e)` for the `${error}` slot of a message that already
names the operation, or `localizedLoadErrorText(e, context: ...)` for a whole
message. This check is deliberately narrow: it only fires when an exception
expression is interpolated into a snackbar call, not on logging, which is
redacted separately by `LogRedactionManager`.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

LIB = Path(__file__).resolve().parents[2] / "lib"

SNACKBAR = re.compile(r"\bshow(?:Error|Success|App)SnackBar\s*\(")
# `e.toString()`, `$e`, `${e}`, `error.toString()` — an exception-shaped name
# reaching the message argument.
RAW = re.compile(
    r"""(?<![\w.])(?:e|err|error|ex|exception|failure)\s*\.\s*toString\s*\(\s*\)"""
    r"""|\$\{?(?:e|err|error|ex|exception|failure)\}?(?![\w(])""",
    re.IGNORECASE,
)


def call_span(text: str, start: int) -> str:
    """Return the source of the snackbar call beginning at `start`."""
    depth = 0
    for i in range(start, min(len(text), start + 4000)):
        c = text[i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
    return text[start : start + 4000]


def main() -> int:
    offenders: list[str] = []
    for path in sorted(LIB.rglob("*.dart")):
        if path.name.endswith((".g.dart", ".freezed.dart")):
            continue
        text = path.read_text(encoding="utf-8")
        if "SnackBar" not in text:
            continue
        for match in SNACKBAR.finditer(text):
            span = call_span(text, match.end() - 1)
            hit = RAW.search(span)
            if not hit:
                continue
            line = text.count("\n", 0, match.start()) + 1
            rel = path.relative_to(LIB.parents[0])
            offenders.append(f"{rel}:{line}: raw `{hit.group(0)}` in a snackbar message")

    if offenders:
        print("Raw exception text reaching the UI:\n")
        for entry in offenders:
            print(f"  {entry}")
        print(
            "\nUse localizedErrorReason(e) for an ${error} slot, or "
            "localizedLoadErrorText(e, context: ...) for a whole message.\n"
            "See lib/utils/error_message_utils.dart."
        )
        return 1

    print("No raw exception text in user-facing messages.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
