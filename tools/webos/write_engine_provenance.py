#!/usr/bin/env python3
"""Write deterministic provenance for a source-built webOS engine archive."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = ROOT / "tools" / "webos" / "compatibility.json"


class ProvenanceError(ValueError):
    pass


def sha256(path: Path) -> str:
    if path.is_symlink() or not path.is_file():
        raise ProvenanceError(f"provenance input must be a regular file: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write(archive: Path, engine: Path, snapshot: Path, destination: Path, epoch: int) -> dict[str, object]:
    try:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProvenanceError(f"cannot read compatibility lock: {exc}") from exc
    artifacts = lock["lgArtifacts"]
    hashes = {
        "engineArchiveSha256": sha256(archive),
        "engineLibrarySha256": sha256(engine),
        "genSnapshotSha256": sha256(snapshot),
    }
    expected = {
        "engineArchiveSha256": artifacts["engineArchiveSha256"],
        "engineLibrarySha256": artifacts["runtimeLibraries"]["libflutter_engine.so"],
        "genSnapshotSha256": artifacts["genSnapshotSha256"],
    }
    if hashes != expected:
        raise ProvenanceError("built engine outputs do not match the reviewed artifact hashes")
    record = {
        "format": 1,
        "sourceDateEpoch": epoch,
        "flutterWebOSRevision": lock["sdk"]["revision"],
        "flutterFrameworkRevision": lock["sdk"]["frameworkRevision"],
        "engineRevision": lock["sdk"]["engineRevision"],
        "dartRevision": lock["sdk"]["dartRevision"],
        "skiaRevision": lock["sdk"]["skiaRevision"],
        "ndkMetadataRevision": lock["engineBuild"]["ndkMetadataRevision"],
        **hashes,
    }
    if destination.is_symlink() or destination.exists():
        raise ProvenanceError(f"provenance output already exists: {destination}")
    if not destination.parent.is_dir():
        raise ProvenanceError("provenance output directory does not exist")
    payload = (json.dumps(record, sort_keys=True, indent=2) + "\n").encode("utf-8")
    try:
        with destination.open("xb") as output:
            output.write(payload)
            output.flush()
            os.fsync(output.fileno())
    except OSError as exc:
        raise ProvenanceError(f"cannot write provenance output: {exc}") from exc
    return record


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--snapshot", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--source-date-epoch", type=int, required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(write(args.archive, args.engine, args.snapshot, args.output, args.source_date_epoch), indent=2))
    except (OSError, KeyError, TypeError, ProvenanceError) as exc:
        print(f"webOS engine provenance failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
