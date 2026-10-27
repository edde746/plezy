#!/usr/bin/env python3
"""Normalize source-built webOS ELF metadata to the physically validated lock."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
import struct
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

from ndk_environment import verified_environment


ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = ROOT / "tools" / "webos" / "compatibility.json"
MAX_INPUT_BYTES = 128 * 1024 * 1024
SHT_NOBITS = 8
SHT_NOTE = 7
SHT_STRTAB = 3


class NormalizeError(ValueError):
    pass


@dataclass(frozen=True)
class ElfSection:
    index: int
    name: str
    name_offset: int
    section_type: int
    flags: int
    address: int
    offset: int
    size: int
    link: int
    info: int
    alignment: int
    entry_size: int
    header_offset: int


@dataclass(frozen=True)
class ElfFile:
    elf_class: int
    machine: int
    header_size: int
    section_header_offset: int
    section_header_size: int
    sections: tuple[ElfSection, ...]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_regular_file(path: Path, *, limit: int = MAX_INPUT_BYTES) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise NormalizeError(f"input must be a regular non-symlink file: {path}")
    try:
        with path.open("rb") as source:
            before = os.fstat(source.fileno())
            if not stat.S_ISREG(before.st_mode) or before.st_size > limit:
                raise NormalizeError(f"input exceeds the {limit}-byte safety limit: {path}")
            data = source.read(limit + 1)
            after = os.fstat(source.fileno())
    except OSError as exc:
        raise NormalizeError(f"cannot read input file: {path}") from exc
    if (before.st_dev, before.st_ino, before.st_size) != (after.st_dev, after.st_ino, after.st_size):
        raise NormalizeError(f"input changed while being read: {path}")
    if len(data) != before.st_size:
        raise NormalizeError(f"input size changed or exceeded the safety limit: {path}")
    return data


def parse_elf(data: bytes, label: str) -> ElfFile:
    if len(data) < 52 or data[:4] != b"\x7fELF" or data[5] != 1 or data[6] != 1:
        raise NormalizeError(f"{label} is not a current little-endian ELF file")
    elf_class = data[4]
    if elf_class == 1:
        header_size = 52
        section_header_offset = struct.unpack_from("<I", data, 32)[0]
        elf_header_size = struct.unpack_from("<H", data, 40)[0]
        section_header_entry_size, section_count, string_index = struct.unpack_from("<HHH", data, 46)
        expected_entry_size = 40
        section_format = "<IIIIIIIIII"
    elif elf_class == 2:
        if len(data) < 64:
            raise NormalizeError(f"{label} has a truncated ELF64 header")
        header_size = 64
        section_header_offset = struct.unpack_from("<Q", data, 40)[0]
        elf_header_size = struct.unpack_from("<H", data, 52)[0]
        section_header_entry_size, section_count, string_index = struct.unpack_from("<HHH", data, 58)
        expected_entry_size = 64
        section_format = "<IIQQQQIIQQ"
    else:
        raise NormalizeError(f"{label} has an unsupported ELF class")

    machine = struct.unpack_from("<H", data, 18)[0]
    if elf_header_size != header_size:
        raise NormalizeError(f"{label} has an unexpected ELF header size")
    if (
        section_count < 2
        or section_count > 4096
        or section_header_entry_size != expected_entry_size
        or string_index >= section_count
        or section_header_offset < header_size
        or section_header_offset + section_count * section_header_entry_size > len(data)
    ):
        raise NormalizeError(f"{label} has an invalid or unsupported section table")

    rows = []
    for index in range(section_count):
        offset = section_header_offset + index * section_header_entry_size
        rows.append(struct.unpack_from(section_format, data, offset))
    string_row = rows[string_index]
    string_offset, string_size = string_row[4], string_row[5]
    if string_row[1] != SHT_STRTAB or string_offset + string_size > len(data):
        raise NormalizeError(f"{label} has an invalid section-name string table")
    strings = data[string_offset : string_offset + string_size]
    sections = []
    for index, row in enumerate(rows):
        name_offset, section_type, flags, address, offset, size, link, info, alignment, entry_size = row
        if section_type != SHT_NOBITS and offset + size > len(data):
            raise NormalizeError(f"{label} section {index} exceeds the file bounds")
        if name_offset >= len(strings):
            raise NormalizeError(f"{label} section {index} has an invalid name offset")
        end = strings.find(b"\0", name_offset)
        if end < 0:
            raise NormalizeError(f"{label} section {index} has an unterminated name")
        try:
            name = strings[name_offset:end].decode("ascii")
        except UnicodeDecodeError as exc:
            raise NormalizeError(f"{label} has a non-ASCII section name") from exc
        sections.append(
            ElfSection(
                index=index,
                name=name,
                name_offset=name_offset,
                section_type=section_type,
                flags=flags,
                address=address,
                offset=offset,
                size=size,
                link=link,
                info=info,
                alignment=alignment,
                entry_size=entry_size,
                header_offset=section_header_offset + index * section_header_entry_size,
            )
        )
    return ElfFile(
        elf_class=elf_class,
        machine=machine,
        header_size=header_size,
        section_header_offset=section_header_offset,
        section_header_size=section_header_entry_size,
        sections=tuple(sections),
    )


def _unique_section(elf: ElfFile, name: str, label: str) -> ElfSection:
    matches = [section for section in elf.sections if section.name == name]
    if len(matches) != 1:
        raise NormalizeError(f"{label} must contain exactly one {name} section")
    return matches[0]


def _validate_build_id_note(data: bytes, label: str) -> None:
    if len(data) < 16:
        raise NormalizeError(f"{label} GNU build-ID note is truncated")
    name_size, description_size, note_type = struct.unpack_from("<III", data)
    name_padded = (name_size + 3) & ~3
    description_padded = (description_size + 3) & ~3
    if (
        name_size != 4
        or description_size != 20
        or note_type != 3
        or len(data) != 12 + name_padded + description_padded
        or data[12:16] != b"GNU\0"
    ):
        raise NormalizeError(f"{label} GNU build-ID note has an unexpected format")


def normalize_elf_bytes(
    candidate: bytes,
    metadata: dict[str, object],
    *,
    label: str,
    expected_hash: str,
    expected_class: int,
    expected_machine: int,
) -> bytes:
    elf = parse_elf(candidate, label)
    if elf.elf_class != expected_class or elf.machine != expected_machine:
        raise NormalizeError(f"{label} has the wrong ELF class or machine")
    if any(section.name == ".comment" for section in elf.sections):
        raise NormalizeError(f"{label} still contains the compiler .comment section")

    try:
        expected_names = metadata["sectionNames"]
        name_offsets = metadata["sectionNameOffsets"]
        name_table = bytes.fromhex(metadata["sectionNameTableHex"])
        build_id_note = bytes.fromhex(metadata["buildIdNoteHex"])
    except (KeyError, TypeError, ValueError) as exc:
        raise NormalizeError(f"{label} normalization metadata is malformed") from exc
    if (
        not isinstance(expected_names, list)
        or any(not isinstance(name, str) for name in expected_names)
        or not isinstance(name_offsets, list)
        or any(not isinstance(value, int) or isinstance(value, bool) or value < 0 for value in name_offsets)
        or len(expected_names) != len(elf.sections)
        or len(name_offsets) != len(elf.sections)
        or [section.name for section in elf.sections] != expected_names
    ):
        raise NormalizeError(f"{label} section names do not match the validated layout")

    note_section = _unique_section(elf, ".note.gnu.build-id", label)
    string_section = _unique_section(elf, ".shstrtab", label)
    if note_section.section_type != SHT_NOTE or string_section.section_type != SHT_STRTAB:
        raise NormalizeError(f"{label} normalization sections have unexpected types")
    if note_section.size != len(build_id_note) or string_section.size != len(name_table):
        raise NormalizeError(f"{label} normalization metadata has unexpected section sizes")
    _validate_build_id_note(build_id_note, label)

    for name, offset in zip(expected_names, name_offsets, strict=True):
        if offset >= len(name_table):
            raise NormalizeError(f"{label} locked section name offset is out of range")
        end = name_table.find(b"\0", offset)
        if end < 0:
            raise NormalizeError(f"{label} locked section name is unterminated")
        try:
            decoded = name_table[offset:end].decode("ascii")
        except UnicodeDecodeError as exc:
            raise NormalizeError(f"{label} locked section name is not ASCII") from exc
        if decoded != name:
            raise NormalizeError(f"{label} locked section-name table does not match its names")

    normalized = bytearray(candidate)
    for section, name_offset in zip(elf.sections, name_offsets, strict=True):
        struct.pack_into("<I", normalized, section.header_offset, name_offset)
    normalized[note_section.offset : note_section.offset + note_section.size] = build_id_note
    normalized[string_section.offset : string_section.offset + string_section.size] = name_table
    result = bytes(normalized)
    if sha256(result) != expected_hash:
        raise NormalizeError(
            f"{label} does not match the locked validated artifact after metadata normalization"
        )
    return result


def _load_lock() -> dict[str, object]:
    try:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise NormalizeError(f"cannot read the webOS compatibility lock: {exc}") from exc
    return lock


def _strip_engine_comment(engine_path: Path, ndk_root: Path, output_dir: Path, lock: dict[str, object]) -> tuple[bytes, str]:
    raw_engine = read_regular_file(engine_path)
    raw_elf = parse_elf(raw_engine, "source-built libflutter_engine.so")
    comment_sections = [section for section in raw_elf.sections if section.name == ".comment"]
    if len(comment_sections) != 1 or comment_sections[0].section_type == SHT_NOBITS:
        raise NormalizeError("source-built libflutter_engine.so must contain one file-backed .comment section")

    ndk_root = ndk_root.resolve(strict=True)
    tool = lock["engineBuild"]["ndkTools"]["objcopy"]
    objcopy_path = (ndk_root / tool["path"]).resolve(strict=True)
    ndk_real = ndk_root.resolve(strict=True)
    try:
        objcopy_path.relative_to(ndk_real)
    except ValueError as exc:
        raise NormalizeError("pinned NDK objcopy escapes the NDK root") from exc
    objcopy_hash = sha256(read_regular_file(objcopy_path))
    if objcopy_hash != tool["sha256"]:
        raise NormalizeError("pinned NDK objcopy hash differs from the compatibility lock")

    try:
        with tempfile.TemporaryDirectory(prefix=".engine-normalize-", dir=output_dir) as temporary:
            output = Path(temporary) / "libflutter_engine.so"
            result = subprocess.run(
                [
                    str(objcopy_path),
                    "--remove-section=.comment",
                    str(engine_path),
                    str(output),
                ],
                check=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=120,
            )
            if result.returncode != 0:
                detail = result.stderr.strip()[-2000:]
                raise NormalizeError(f"pinned NDK objcopy failed ({result.returncode}): {detail}")
            stripped = read_regular_file(output)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise NormalizeError("could not strip the compiler-only ELF .comment section") from exc

    stripped_elf = parse_elf(stripped, "stripped libflutter_engine.so")
    if any(section.name == ".comment" for section in stripped_elf.sections):
        raise NormalizeError("pinned NDK objcopy left the compiler .comment section in place")
    return stripped, objcopy_hash


def _write_new_file(path: Path, contents: bytes, mode: int) -> None:
    if path.is_symlink() or path.exists():
        raise NormalizeError(f"normalization output already exists or is a symlink: {path}")
    flags = os.O_CREAT | os.O_EXCL | os.O_WRONLY
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = None
    try:
        descriptor = os.open(path, flags, 0o600)
        os.fchmod(descriptor, mode)
        with os.fdopen(descriptor, "wb") as output:
            descriptor = None
            output.write(contents)
            output.flush()
            os.fsync(output.fileno())
    except OSError as exc:
        if descriptor is not None:
            os.close(descriptor)
        try:
            path.unlink()
        except FileNotFoundError:
            pass
        raise NormalizeError(f"cannot write normalization output: {path}") from exc


def normalize_artifacts(
    engine_path: Path,
    snapshot_path: Path,
    ndk_root_arg: Path,
    output_dir_arg: Path,
    lock: dict[str, object] | None = None,
) -> dict[str, object]:
    if output_dir_arg.is_symlink() or not output_dir_arg.is_dir():
        raise NormalizeError("normalization output directory must already exist and must not be a symlink")
    output_dir = output_dir_arg.resolve(strict=True)
    selected_lock = lock if lock is not None else _load_lock()
    artifacts = selected_lock["lgArtifacts"]
    build = selected_lock["engineBuild"]
    normalization = build["normalization"]
    if normalization["referenceArchiveSha256"] != artifacts["engineArchiveSha256"]:
        raise NormalizeError("normalization baseline is not the locked validated engine archive")

    ndk_root, _ = verified_environment(ndk_root_arg)
    stripped_engine, objcopy_hash = _strip_engine_comment(engine_path, ndk_root, output_dir, selected_lock)
    raw_engine = read_regular_file(engine_path)
    raw_snapshot = read_regular_file(snapshot_path)
    engine_output = normalize_elf_bytes(
        stripped_engine,
        normalization["engine"],
        label="libflutter_engine.so",
        expected_hash=artifacts["runtimeLibraries"]["libflutter_engine.so"],
        expected_class=1,
        expected_machine=40,
    )
    snapshot_output = normalize_elf_bytes(
        raw_snapshot,
        normalization["genSnapshot"],
        label="linux-x64/gen_snapshot",
        expected_hash=artifacts["genSnapshotSha256"],
        expected_class=2,
        expected_machine=62,
    )

    engine_destination = output_dir / "libflutter_engine.so"
    snapshot_destination = output_dir / "gen_snapshot"
    record_destination = output_dir / "webos-engine-normalization.json"
    if any(path.exists() or path.is_symlink() for path in (engine_destination, snapshot_destination, record_destination)):
        raise NormalizeError("normalization output path already exists")
    record: dict[str, object] = {
        "format": 1,
        "referenceArchiveSha256": normalization["referenceArchiveSha256"],
        "objcopySha256": objcopy_hash,
        "removedSections": ["libflutter_engine.so:.comment"],
        "rawEngineSha256": sha256(raw_engine),
        "rawGenSnapshotSha256": sha256(raw_snapshot),
        "normalizedEngineSha256": sha256(engine_output),
        "normalizedGenSnapshotSha256": sha256(snapshot_output),
    }
    _write_new_file(engine_destination, engine_output, 0o755)
    _write_new_file(snapshot_destination, snapshot_output, 0o755)
    _write_new_file(
        record_destination,
        (json.dumps(record, sort_keys=True, indent=2) + "\n").encode("utf-8"),
        0o644,
    )
    return {
        **record,
        "engine": str(engine_destination),
        "genSnapshot": str(snapshot_destination),
        "record": str(record_destination),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--gen-snapshot", type=Path, required=True)
    parser.add_argument("--ndk-root", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(normalize_artifacts(
            args.engine,
            args.gen_snapshot,
            args.ndk_root,
            args.output_dir,
        ), indent=2))
    except (OSError, KeyError, TypeError, NormalizeError) as exc:
        print(f"webOS engine normalization failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
