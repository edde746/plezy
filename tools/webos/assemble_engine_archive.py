#!/usr/bin/env python3
"""Assemble a version-matched Flutter/webOS ARM engine archive."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
import struct
import tempfile
import zipfile
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = ROOT / "tools" / "webos" / "compatibility.json"
MAX_ARCHIVE_BYTES = 128 * 1024 * 1024
BASE_ARCHIVE_MEMBERS = {
    "embedder.version",
    "engine.version",
    "libflutter_common.so",
    "libflutter_engine.so",
    "libflutter_webos_media.so",
    "linux-x64/",
    "linux-x64/gen_snapshot",
}
OUTPUT_MEMBERS = (
    "embedder.version",
    "engine.version",
    "libflutter_common.so",
    "libflutter_engine.so",
    "libflutter_webos_media.so",
    "linux-x64/gen_snapshot",
)


class ArchiveError(ValueError):
    pass


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _read_regular_file(path: Path) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise ArchiveError(f"input must be a regular file: {path}")
    try:
        with path.open("rb") as source:
            before = os.fstat(source.fileno())
            if not stat.S_ISREG(before.st_mode) or before.st_size > MAX_ARCHIVE_BYTES:
                raise ArchiveError(f"input exceeds the {MAX_ARCHIVE_BYTES}-byte safety limit: {path}")
            data = source.read(MAX_ARCHIVE_BYTES + 1)
            after = os.fstat(source.fileno())
    except OSError as exc:
        raise ArchiveError(f"cannot read {path}: {exc}") from exc
    if (before.st_dev, before.st_ino, before.st_size) != (after.st_dev, after.st_ino, after.st_size):
        raise ArchiveError(f"input changed while being read: {path}")
    if len(data) != before.st_size:
        raise ArchiveError(f"input size changed or exceeded the safety limit: {path}")
    return data


def _read_base_archive(path: Path, lock: dict[str, object]) -> dict[str, bytes]:
    contents = _read_regular_file(path)
    expected_hash = lock["lgArtifacts"]["baseEngineArchiveSha256"]
    if _sha256(contents) != expected_hash:
        raise ArchiveError("LG ARM engine archive differs from the pinned webOS SDK release")
    try:
        with zipfile.ZipFile(path) as archive:
            infos = archive.infolist()
            names = [info.filename for info in infos]
            if len(names) != len(set(names)) or set(names) != BASE_ARCHIVE_MEMBERS:
                raise ArchiveError("LG ARM engine archive has unexpected or duplicate members")
            members: dict[str, bytes] = {}
            total_size = 0
            for info in infos:
                path_name = PurePosixPath(info.filename)
                if (
                    "\\" in info.filename
                    or path_name.is_absolute()
                    or path_name.as_posix() != info.filename.rstrip("/")
                    or any(part in ("", ".", "..") for part in path_name.parts)
                ):
                    raise ArchiveError(f"unsafe LG archive member path: {info.filename!r}")
                mode = info.external_attr >> 16
                if info.is_dir():
                    if info.filename != "linux-x64/" or not stat.S_ISDIR(mode):
                        raise ArchiveError(f"unexpected directory in LG archive: {info.filename!r}")
                    continue
                if not stat.S_ISREG(mode):
                    raise ArchiveError(f"unsupported file type in LG archive: {info.filename!r}")
                total_size += info.file_size
                if info.file_size < 0 or total_size > MAX_ARCHIVE_BYTES:
                    raise ArchiveError("LG ARM engine archive exceeds the expanded-size safety limit")
                members[info.filename] = archive.read(info)
            if set(members) != BASE_ARCHIVE_MEMBERS - {"linux-x64/"}:
                raise ArchiveError("LG ARM engine archive is missing a required file")
            return members
    except (OSError, zipfile.BadZipFile, RuntimeError) as exc:
        raise ArchiveError(f"cannot read LG ARM engine archive: {exc}") from exc


def _verify_elf(data: bytes, name: str, *, elf_class: int, machine: int) -> None:
    if len(data) < 20 or data[:4] != b"\x7fELF" or data[4] != elf_class or data[5] != 1:
        raise ArchiveError(f"{name} has an unexpected ELF class or endianness")
    actual_machine = struct.unpack_from("<H", data, 18)[0]
    if actual_machine != machine:
        raise ArchiveError(f"{name} has ELF machine {actual_machine}; expected {machine}")


def _write_archive(destination: Path, members: dict[str, bytes]) -> None:
    if destination.is_symlink() or destination.exists():
        raise ArchiveError(f"engine archive output already exists or is a symlink: {destination}")
    if not destination.parent.is_dir():
        raise ArchiveError("engine archive output parent directory must already exist")
    fd, temporary_name = tempfile.mkstemp(prefix=f".{destination.name}.", suffix=".tmp", dir=destination.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "w+b") as output:
            with zipfile.ZipFile(output, mode="w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
                for name in OUTPUT_MEMBERS:
                    info = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
                    info.create_system = 3
                    info.compress_type = zipfile.ZIP_DEFLATED
                    info.external_attr = (stat.S_IFREG | (0o755 if name.endswith(".so") or name.endswith("gen_snapshot") else 0o644)) << 16
                    archive.writestr(info, members[name], compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, destination)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def assemble(
    base_archive: Path,
    engine_library: Path,
    gen_snapshot: Path,
    engine_version_file: Path,
    common_archive: Path,
    destination: Path,
    lock: dict[str, object],
) -> dict[str, object]:
    artifacts = lock["lgArtifacts"]
    if _sha256(_read_regular_file(common_archive)) != artifacts["commonArchiveSha256"]:
        raise ArchiveError("webOS common runtime archive differs from the pinned SDK release")

    members = _read_base_archive(base_archive, lock)
    runtime_hashes = artifacts["runtimeLibraries"]
    for name in ("libflutter_common.so", "libflutter_webos_media.so"):
        if _sha256(members[name]) != runtime_hashes[name]:
            raise ArchiveError(f"{name} in the LG base archive does not match the pinned runtime")

    engine_data = _read_regular_file(engine_library)
    _verify_elf(engine_data, "libflutter_engine.so", elf_class=1, machine=40)
    if _sha256(engine_data) != runtime_hashes["libflutter_engine.so"]:
        raise ArchiveError("source-built ARM Flutter engine does not match the validated engine hash")

    snapshot_data = _read_regular_file(gen_snapshot)
    _verify_elf(snapshot_data, "linux-x64/gen_snapshot", elf_class=2, machine=62)
    if _sha256(snapshot_data) != artifacts["genSnapshotSha256"]:
        raise ArchiveError("host gen_snapshot does not match the validated Flutter/Dart toolchain")

    engine_revision = lock["sdk"]["engineRevision"]
    engine_version = _read_regular_file(engine_version_file)
    if engine_version.decode("ascii", errors="strict").strip() != engine_revision:
        raise ArchiveError("engine.version does not match the pinned Flutter engine source revision")

    members["engine.version"] = engine_version
    members["libflutter_engine.so"] = engine_data
    members["linux-x64/gen_snapshot"] = snapshot_data
    _write_archive(destination, members)

    result_hash = _sha256(_read_regular_file(destination))
    expected_hash = artifacts["engineArchiveSha256"]
    if result_hash != expected_hash:
        raise ArchiveError(f"assembled engine archive hash {result_hash} differs from pinned {expected_hash}")
    return {"archiveSha256": result_hash, "archiveBytes": destination.stat().st_size}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-archive", type=Path, required=True)
    parser.add_argument("--engine-library", type=Path, required=True)
    parser.add_argument("--gen-snapshot", type=Path, required=True)
    parser.add_argument("--engine-version", type=Path, required=True)
    parser.add_argument("--common-archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
        print(json.dumps(assemble(
            args.base_archive,
            args.engine_library,
            args.gen_snapshot,
            args.engine_version,
            args.common_archive,
            args.output,
            lock,
        ), indent=2))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError, KeyError, TypeError, ArchiveError) as exc:
        print(f"webOS engine archive assembly failed: {exc}", file=__import__("sys").stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
