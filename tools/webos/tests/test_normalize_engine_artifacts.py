from __future__ import annotations

import hashlib
import struct
import sys
import unittest
from pathlib import Path


TOOLS_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS_ROOT))

import normalize_engine_artifacts as normalizer  # noqa: E402


def make_note(seed: int) -> bytes:
    return struct.pack("<III", 4, 20, 3) + b"GNU\0" + bytes((seed + index) & 0xFF for index in range(20))


def make_elf(
    elf_class: int,
    machine: int,
    *,
    string_order: tuple[str, ...],
    build_id_seed: int,
    text: bytes = b"code",
    include_comment: bool = False,
) -> tuple[bytes, dict[str, object]]:
    expected_names = ["", ".note.gnu.build-id", ".text", ".shstrtab"]
    if include_comment:
        expected_names.append(".comment")
    name_table = bytearray(b"\0")
    name_offsets = {"": 0}
    for name in string_order:
        name_offsets[name] = len(name_table)
        name_table.extend(name.encode("ascii") + b"\0")

    if elf_class == 1:
        header_size, section_header_size = 52, 40
        section_format = "<IIIIIIIIII"
        section_offset_format = "<I"
        align = 4
    else:
        header_size, section_header_size = 64, 64
        section_format = "<IIQQQQIIQQ"
        section_offset_format = "<Q"
        align = 8

    note = make_note(build_id_seed)
    note_offset = header_size
    text_offset = note_offset + len(note)
    strings_offset = text_offset + len(text)
    comment_offset = strings_offset + len(name_table)
    comment = b"GCC: test\0" if include_comment else b""
    section_table_offset = comment_offset + len(comment)
    section_table_offset = (section_table_offset + align - 1) & ~(align - 1)
    section_count = len(expected_names)
    output = bytearray(section_table_offset + section_count * section_header_size)
    output[:16] = b"\x7fELF" + bytes((elf_class, 1, 1, 0, 0)) + bytes(8)
    if elf_class == 1:
        struct.pack_into(
            "<HHIIIIIHHHHHH",
            output,
            16,
            3,
            machine,
            1,
            0,
            0,
            section_table_offset,
            0,
            header_size,
            0,
            0,
            section_header_size,
            section_count,
            3,
        )
    else:
        struct.pack_into(
            "<HHIQQQIHHHHHH",
            output,
            16,
            3,
            machine,
            1,
            0,
            0,
            section_table_offset,
            0,
            header_size,
            0,
            0,
            section_header_size,
            section_count,
            3,
        )
    output[note_offset : note_offset + len(note)] = note
    output[text_offset : text_offset + len(text)] = text
    output[strings_offset : strings_offset + len(name_table)] = name_table
    if comment:
        output[comment_offset : comment_offset + len(comment)] = comment

    sections = [
        ("", 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (".note.gnu.build-id", 7, 2, 0, note_offset, len(note), 0, 0, 4, 0),
        (".text", 1, 6, 0, text_offset, len(text), 0, 0, 4, 0),
        (".shstrtab", 3, 0, 0, strings_offset, len(name_table), 0, 0, 1, 0),
    ]
    if include_comment:
        sections.append((".comment", 1, 48, 0, comment_offset, len(comment), 0, 0, 1, 0))
    for index, (name, *fields) in enumerate(sections):
        header_offset = section_table_offset + index * section_header_size
        row = (name_offsets[name], *fields)
        struct.pack_into(section_format, output, header_offset, *row)

    metadata: dict[str, object] = {
        "sectionNames": expected_names,
        "sectionNameOffsets": [
            name_offsets[name] for name in expected_names
        ],
        "sectionNameTableHex": bytes(name_table).hex(),
        "buildIdNoteHex": note.hex(),
    }
    return bytes(output), metadata


class NormalizeEngineArtifactTests(unittest.TestCase):
    def test_normalizes_arm_engine_comment_metadata_and_name_table(self) -> None:
        reference, metadata = make_elf(
            1,
            40,
            string_order=(".note.gnu.build-id", ".text", ".shstrtab"),
            build_id_seed=10,
        )
        candidate, _ = make_elf(
            1,
            40,
            string_order=(".text", ".shstrtab", ".note.gnu.build-id"),
            build_id_seed=80,
        )

        normalized = normalizer.normalize_elf_bytes(
            candidate,
            metadata,
            label="libflutter_engine.so",
            expected_hash=hashlib.sha256(reference).hexdigest(),
            expected_class=1,
            expected_machine=40,
        )

        self.assertEqual(normalized, reference)

    def test_normalizes_host_snapshot_build_id(self) -> None:
        reference, metadata = make_elf(
            2,
            62,
            string_order=(".note.gnu.build-id", ".text", ".shstrtab"),
            build_id_seed=12,
        )
        candidate, _ = make_elf(
            2,
            62,
            string_order=(".note.gnu.build-id", ".text", ".shstrtab"),
            build_id_seed=90,
        )

        normalized = normalizer.normalize_elf_bytes(
            candidate,
            metadata,
            label="linux-x64/gen_snapshot",
            expected_hash=hashlib.sha256(reference).hexdigest(),
            expected_class=2,
            expected_machine=62,
        )

        self.assertEqual(normalized, reference)

    def test_rejects_code_changes_after_metadata_normalization(self) -> None:
        reference, metadata = make_elf(
            1,
            40,
            string_order=(".note.gnu.build-id", ".text", ".shstrtab"),
            build_id_seed=10,
        )
        candidate, _ = make_elf(
            1,
            40,
            string_order=(".text", ".shstrtab", ".note.gnu.build-id"),
            build_id_seed=80,
            text=b"evil",
        )

        with self.assertRaisesRegex(normalizer.NormalizeError, "validated artifact"):
            normalizer.normalize_elf_bytes(
                candidate,
                metadata,
                label="libflutter_engine.so",
                expected_hash=hashlib.sha256(reference).hexdigest(),
                expected_class=1,
                expected_machine=40,
            )

    def test_rejects_unstripped_compiler_comment(self) -> None:
        candidate, metadata = make_elf(
            1,
            40,
            string_order=(".note.gnu.build-id", ".text", ".shstrtab", ".comment"),
            build_id_seed=10,
            include_comment=True,
        )

        with self.assertRaisesRegex(normalizer.NormalizeError, "compiler .comment"):
            normalizer.normalize_elf_bytes(
                candidate,
                metadata,
                label="libflutter_engine.so",
                expected_hash="0" * 64,
                expected_class=1,
                expected_machine=40,
            )

    def test_rejects_wrong_architecture(self) -> None:
        candidate, metadata = make_elf(
            1,
            40,
            string_order=(".note.gnu.build-id", ".text", ".shstrtab"),
            build_id_seed=10,
        )

        with self.assertRaisesRegex(normalizer.NormalizeError, "wrong ELF class or machine"):
            normalizer.normalize_elf_bytes(
                candidate,
                metadata,
                label="linux-x64/gen_snapshot",
                expected_hash="0" * 64,
                expected_class=2,
                expected_machine=62,
            )

    def test_rejects_truncated_section_table(self) -> None:
        candidate, _ = make_elf(
            1,
            40,
            string_order=(".note.gnu.build-id", ".text", ".shstrtab"),
            build_id_seed=10,
        )

        with self.assertRaisesRegex(normalizer.NormalizeError, "section table"):
            normalizer.parse_elf(candidate[:64], "truncated")


if __name__ == "__main__":
    unittest.main()
