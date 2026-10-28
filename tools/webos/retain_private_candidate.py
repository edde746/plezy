#!/usr/bin/env python3
"""Keep the verified webOS candidate on its job-specific private runner mount."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys


PRIVATE_OUTPUTS = Path("/mnt/private-outputs")
RECEIPT = "webos-private-receipt.json"


def preflight(env: dict[str, str]) -> tuple[Path, dict[str, str]]:
    destination = Path(env.get("GHA_JIT_OUTPUTS", ""))
    if destination != PRIVATE_OUTPUTS or destination.resolve() != destination:
        raise ValueError("The runner must provide the dedicated /mnt/private-outputs mount")
    if not destination.is_dir() or not destination.is_mount():
        raise ValueError("Private output storage is not mounted; refusing ephemeral-only retention")
    if any(destination.iterdir()):
        raise ValueError("Private output storage must be empty and scoped to this job")
    required = {
        "GITHUB_REPOSITORY": r"snapetech-org/PlezyNG",
        "GITHUB_JOB": r"build-webos",
        "GITHUB_RUN_ID": r"[1-9][0-9]*",
        "GITHUB_RUN_ATTEMPT": r"[1-9][0-9]*",
        "GITHUB_SHA": r"[0-9a-f]{40}",
    }
    for name, pattern in required.items():
        if not re.fullmatch(pattern, env.get(name, "")):
            raise ValueError(f"Missing or invalid trusted job identity: {name}")
    return destination, {name: env[name] for name in required}


def open_regular(path: Path, limit: int):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or not 0 < info.st_size <= limit:
            raise ValueError(f"Expected a nonempty regular file within the size limit: {path.name}")
        return os.fdopen(fd, "rb")
    except BaseException:
        os.close(fd)
        raise


def retain(source: Path, version: str, env: dict[str, str]) -> Path:
    destination, identity = preflight(env)
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:\+[0-9]+)?", version):
        raise ValueError("Expected the exact pubspec release version")
    version = version.split("+", 1)[0]
    source = source.absolute()
    if source.resolve() != source or not source.is_dir():
        raise ValueError("Candidate output must be a real directory without symlink parents")
    ipk = f"org.snapetech.plezyng_{version}_arm.ipk"
    files = {ipk, "webos-engine-provenance.json", "webos-compatibility.json"}
    checksum_name = "SHA256SUMS.txt"
    if {path.name for path in source.iterdir()} != files | {checksum_name}:
        raise ValueError("Expected exactly one version-matched IPK, provenance, compatibility, and checksums")
    with open_regular(source / checksum_name, 16384) as checksum_file:
        checksum_bytes = checksum_file.read()
    expected = {}
    for line in checksum_bytes.decode("ascii").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  ([A-Za-z0-9_.-]+)", line)
        if not match or match[2] not in files or match[2] in expected:
            raise ValueError("Invalid or duplicate candidate checksum entry")
        expected[match[2]] = match[1]
    if set(expected) != files:
        raise ValueError("Candidate checksums do not cover every retained file")
    expected[checksum_name] = hashlib.sha256(checksum_bytes).hexdigest()
    for name in sorted(expected):
        digest = hashlib.sha256()
        limit = 2 * 1024**3 if name == ipk else 8 * 1024**2
        with open_regular(source / name, limit) as original:
            before = os.fstat(original.fileno())
            with (destination / name).open("xb") as output:
                copied_bytes = 0
                while chunk := original.read(1024 * 1024):
                    copied_bytes += len(chunk)
                    if copied_bytes > limit:
                        raise ValueError(f"Candidate grew beyond its size limit: {name}")
                    output.write(chunk)
                    digest.update(chunk)
                output.flush()
                os.fsync(output.fileno())
            after = os.fstat(original.fileno())
        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
            raise ValueError(f"Candidate changed during retention: {name}")
        if digest.hexdigest() != expected[name]:
            raise ValueError(f"Candidate checksum mismatch: {name}")
        with open_regular(destination / name, limit) as copied:
            if hashlib.file_digest(copied, "sha256").hexdigest() != expected[name]:
                raise ValueError(f"Private output checksum mismatch: {name}")
    receipt = destination / RECEIPT
    with receipt.open("x", encoding="utf-8") as output:
        json.dump({"schema": 1, "identity": identity, "version": version,
                   "files": expected}, output, indent=2, sort_keys=True)
        output.write("\n")
        output.flush()
        os.fsync(output.fileno())
    return receipt


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preflight", action="store_true")
    parser.add_argument("--source-dir", type=Path)
    parser.add_argument("--version")
    args = parser.parse_args()
    try:
        if args.preflight:
            preflight(dict(os.environ))
            print("Job-specific private webOS output mount is ready.")
        else:
            if not args.source_dir or not args.version:
                parser.error("--source-dir and --version are required for retention")
            receipt = retain(args.source_dir, args.version, dict(os.environ))
            print(f"Verified private webOS candidate and receipt: {receipt}")
    except (OSError, ValueError, UnicodeError) as error:
        print(f"Private webOS retention failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
