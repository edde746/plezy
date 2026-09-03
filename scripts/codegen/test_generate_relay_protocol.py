import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import generate_relay_protocol as generator


class RelayProtocolGeneratorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.spec = json.loads(generator.SPEC_PATH.read_text(encoding="utf-8"))

    def test_supported_pattern_renders_both_targets(self) -> None:
        dart_output = generator.dart_source(copy.deepcopy(self.spec))
        go_output = generator.go_source(copy.deepcopy(self.spec))

        self.assertIn(
            f"RegExp(r{generator.SUPPORTED_ID_PATTERN!r})",
            dart_output,
        )
        self.assertIn("func validRelayID(value string, maxLength int) bool", go_output)

    def test_main_writes_canonical_lf_dart_output(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            spec_path = root / "relay_protocol.json"
            dart_path = root / "relay_protocol.g.dart"
            go_path = root / "relay_protocol_gen.go"
            spec_path.write_text(json.dumps(self.spec), encoding="utf-8")

            with (
                mock.patch.object(generator, "SPEC_PATH", spec_path),
                mock.patch.object(generator, "DART_PATH", dart_path),
                mock.patch.object(generator, "GO_PATH", go_path),
            ):
                generator.main()

            dart_bytes = dart_path.read_bytes()
            self.assertIn(b"\n", dart_bytes)
            self.assertNotIn(b"\r\n", dart_bytes)

    def test_changed_pattern_fails_before_writing_either_target(self) -> None:
        changed_spec = copy.deepcopy(self.spec)
        changed_spec["idPattern"] = r"^[A-Za-z0-9_.-]+$"

        for renderer in (generator.dart_source, generator.go_source):
            with self.subTest(renderer=renderer.__name__):
                with self.assertRaisesRegex(ValueError, "idPattern"):
                    renderer(changed_spec)

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            spec_path = root / "relay_protocol.json"
            dart_path = root / "relay_protocol.g.dart"
            go_path = root / "relay_protocol_gen.go"
            spec_path.write_text(json.dumps(changed_spec), encoding="utf-8")
            dart_path.write_text("dart sentinel\n", encoding="utf-8")
            go_path.write_text("go sentinel\n", encoding="utf-8")

            with (
                mock.patch.object(generator, "SPEC_PATH", spec_path),
                mock.patch.object(generator, "DART_PATH", dart_path),
                mock.patch.object(generator, "GO_PATH", go_path),
            ):
                with self.assertRaisesRegex(ValueError, "idPattern"):
                    generator.main()

            self.assertEqual(dart_path.read_text(encoding="utf-8"), "dart sentinel\n")
            self.assertEqual(go_path.read_text(encoding="utf-8"), "go sentinel\n")

    def test_missing_pattern_is_rejected(self) -> None:
        spec = copy.deepcopy(self.spec)
        del spec["idPattern"]

        with self.assertRaisesRegex(ValueError, "idPattern is required"):
            generator.validated_id_pattern(spec)

    def test_non_string_pattern_is_rejected(self) -> None:
        for value in (None, 42, [generator.SUPPORTED_ID_PATTERN]):
            with self.subTest(value=value):
                spec = copy.deepcopy(self.spec)
                spec["idPattern"] = value

                with self.assertRaisesRegex(ValueError, "idPattern must be a string"):
                    generator.validated_id_pattern(spec)

    def test_reconnect_token_length_is_unpadded_base64url_length(self) -> None:
        for token_bytes, expected in ((1, 2), (2, 3), (3, 4), (32, 43), (33, 44)):
            with self.subTest(token_bytes=token_bytes):
                self.assertEqual(generator.reconnect_token_length(token_bytes), expected)

    def test_reconnect_token_bytes_render_derived_symbols(self) -> None:
        spec = copy.deepcopy(self.spec)
        spec["reconnectTokenBytes"] = 24

        dart_output = generator.dart_source(spec)
        go_output = generator.go_source(spec)

        self.assertIn("static const int reconnectTokenBytes = 24;", dart_output)
        self.assertIn("static const int reconnectTokenLength = 32;", dart_output)
        self.assertIn("RegExp(r'^[A-Za-z0-9_-]{32}$')", dart_output)
        self.assertIn("static bool isValidReconnectToken(String value)", dart_output)
        self.assertIn("reconnectTokenSize = 24", go_output)
        self.assertIn("func supportedRelayProtocolVersion(version int) bool", go_output)

    def test_missing_reconnect_token_bytes_fails_before_writing_either_target(self) -> None:
        spec = copy.deepcopy(self.spec)
        del spec["reconnectTokenBytes"]

        for renderer in (generator.dart_source, generator.go_source):
            with self.subTest(renderer=renderer.__name__):
                with self.assertRaisesRegex(ValueError, "reconnectTokenBytes is required"):
                    renderer(spec)

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            spec_path = root / "relay_protocol.json"
            dart_path = root / "relay_protocol.g.dart"
            go_path = root / "relay_protocol_gen.go"
            spec_path.write_text(json.dumps(spec), encoding="utf-8")
            dart_path.write_text("dart sentinel\n", encoding="utf-8")
            go_path.write_text("go sentinel\n", encoding="utf-8")

            with (
                mock.patch.object(generator, "SPEC_PATH", spec_path),
                mock.patch.object(generator, "DART_PATH", dart_path),
                mock.patch.object(generator, "GO_PATH", go_path),
            ):
                with self.assertRaisesRegex(ValueError, "reconnectTokenBytes"):
                    generator.main()

            self.assertEqual(dart_path.read_text(encoding="utf-8"), "dart sentinel\n")
            self.assertEqual(go_path.read_text(encoding="utf-8"), "go sentinel\n")

    def test_invalid_reconnect_token_bytes_is_rejected(self) -> None:
        for value in (None, "32", 32.0, True, 0, -1):
            with self.subTest(value=value):
                spec = copy.deepcopy(self.spec)
                spec["reconnectTokenBytes"] = value

                with self.assertRaisesRegex(
                    ValueError, "reconnectTokenBytes must be a positive integer"
                ):
                    generator.validated_reconnect_token_bytes(spec)


if __name__ == "__main__":
    unittest.main()
