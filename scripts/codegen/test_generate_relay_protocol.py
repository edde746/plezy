import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_relay_protocol as generator


class RelayProtocolGeneratorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.spec = json.loads(generator.SPEC_PATH.read_text(encoding="utf-8"))

    def test_supported_pattern_renders_go_validator(self) -> None:
        go_output = generator.go_source(copy.deepcopy(self.spec))

        self.assertIn("func validRelayID(value string, maxLength int) bool", go_output)

    def test_main_writes_go_output(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            spec_path = root / "relay_protocol.json"
            go_path = root / "relay_protocol_gen.go"
            spec_path.write_text(json.dumps(self.spec), encoding="utf-8")

            with (
                mock.patch.object(generator, "SPEC_PATH", spec_path),
                mock.patch.object(generator, "GO_PATH", go_path),
            ):
                generator.main()

            self.assertEqual(
                go_path.read_text(encoding="utf-8"),
                generator.go_source(copy.deepcopy(self.spec)),
            )

    def test_changed_pattern_fails_before_writing(self) -> None:
        changed_spec = copy.deepcopy(self.spec)
        changed_spec["idPattern"] = r"^[A-Za-z0-9_.-]+$"

        with self.assertRaisesRegex(ValueError, "idPattern"):
            generator.go_source(changed_spec)

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            spec_path = root / "relay_protocol.json"
            go_path = root / "relay_protocol_gen.go"
            spec_path.write_text(json.dumps(changed_spec), encoding="utf-8")
            go_path.write_text("go sentinel\n", encoding="utf-8")

            with (
                mock.patch.object(generator, "SPEC_PATH", spec_path),
                mock.patch.object(generator, "GO_PATH", go_path),
            ):
                with self.assertRaisesRegex(ValueError, "idPattern"):
                    generator.main()

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

    def test_reconnect_token_bytes_render_go_symbols(self) -> None:
        spec = copy.deepcopy(self.spec)
        spec["reconnectTokenBytes"] = 24

        go_output = generator.go_source(spec)

        self.assertIn("reconnectTokenSize = 24", go_output)
        self.assertIn("func supportedRelayProtocolVersion(version int) bool", go_output)

    def test_missing_reconnect_token_bytes_fails_before_writing(self) -> None:
        spec = copy.deepcopy(self.spec)
        del spec["reconnectTokenBytes"]

        with self.assertRaisesRegex(ValueError, "reconnectTokenBytes is required"):
            generator.go_source(spec)

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            spec_path = root / "relay_protocol.json"
            go_path = root / "relay_protocol_gen.go"
            spec_path.write_text(json.dumps(spec), encoding="utf-8")
            go_path.write_text("go sentinel\n", encoding="utf-8")

            with (
                mock.patch.object(generator, "SPEC_PATH", spec_path),
                mock.patch.object(generator, "GO_PATH", go_path),
            ):
                with self.assertRaisesRegex(ValueError, "reconnectTokenBytes"):
                    generator.main()

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
