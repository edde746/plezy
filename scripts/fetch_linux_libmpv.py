#!/usr/bin/env python3
"""Fetch the pinned Linux libmpv prefix named by mpv-build.lock.json.

Reads artifacts.linux for this machine's architecture, downloads the asset,
verifies its SHA-256 against the lock before a single byte is extracted, then
untars the self-relocating prefix tree into --dest. Shared by build.yml,
ci.yml, and local packaging builds so the contract lives in one place.
"""

import argparse
import hashlib
import json
import platform
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LOCK = ROOT / "mpv-build.lock.json"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Download and verify the locked Linux libmpv prefix."
    )
    parser.add_argument(
        "--lock",
        type=Path,
        default=DEFAULT_LOCK,
        help="path to mpv-build.lock.json (default: the repository lock)",
    )
    parser.add_argument(
        "--dest",
        type=Path,
        default=Path("libmpv-prefix"),
        help="directory to extract the prefix tree into (default: libmpv-prefix)",
    )
    args = parser.parse_args()

    if shutil.which("zstd") is None:
        print(
            "Error: zstd is required to extract the libmpv archive "
            "(install it, e.g. apt-get install zstd)",
            file=sys.stderr,
        )
        return 1

    lock = json.loads(args.lock.read_text(encoding="utf-8"))
    group = lock["artifacts"]["linux"]
    machine = platform.machine()
    entry = group["assets"].get(machine)
    if entry is None:
        print(
            f"Error: {args.lock}: no linux asset for {machine!r} "
            f"(locked: {', '.join(sorted(group['assets']))})",
            file=sys.stderr,
        )
        return 1

    url = f"{group['assetBase']}/{entry['asset']}"
    print(f"fetching {url}", flush=True)
    with urllib.request.urlopen(url) as response:
        data = response.read()
    digest = hashlib.sha256(data).hexdigest()
    if digest != entry["checksum"]:
        print(
            f"Error: {entry['asset']}: SHA-256 {digest} does not match "
            f"locked {entry['checksum']}",
            file=sys.stderr,
        )
        return 1

    args.dest.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".tar.zst") as archive:
        archive.write(data)
        archive.flush()
        subprocess.run(
            ["tar", "--zstd", "-xf", archive.name, "-C", str(args.dest)],
            check=True,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
