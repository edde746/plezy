#!/usr/bin/env python3
"""Retry Flatpak remote and install operations after transient network errors."""

from __future__ import annotations

import subprocess
import sys
import time
from collections.abc import Callable
from typing import TextIO


ALLOWED_OPERATIONS = {"remote-add", "install"}
MAX_ATTEMPTS = 3
INITIAL_DELAY_SECONDS = 15


def run_with_retries(
    operation: str,
    arguments: list[str],
    *,
    run: Callable[..., subprocess.CompletedProcess[bytes]] = subprocess.run,
    sleep: Callable[[float], None] = time.sleep,
    stderr: TextIO = sys.stderr,
) -> int:
    if operation not in ALLOWED_OPERATIONS:
        raise ValueError(f"unsupported Flatpak operation: {operation}")

    command = ["flatpak", operation, *arguments]
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            result = run(command, check=False)
        except OSError as error:
            print(f"Could not start Flatpak: {error}", file=stderr)
            return 127
        if result.returncode == 0:
            return 0
        if attempt == MAX_ATTEMPTS:
            return result.returncode
        delay = INITIAL_DELAY_SECONDS * attempt
        print(
            f"Flatpak {operation} failed with exit {result.returncode}; "
            f"retry {attempt + 1}/{MAX_ATTEMPTS} in {delay}s.",
            file=stderr,
        )
        sleep(delay)
    return 1


def main(arguments: list[str] | None = None) -> int:
    argv = sys.argv[1:] if arguments is None else arguments
    if not argv or argv[0] not in ALLOWED_OPERATIONS:
        print(
            "usage: retry_flatpak.py {remote-add|install} [flatpak arguments]",
            file=sys.stderr,
        )
        return 2
    return run_with_retries(argv[0], argv[1:])


if __name__ == "__main__":
    raise SystemExit(main())
