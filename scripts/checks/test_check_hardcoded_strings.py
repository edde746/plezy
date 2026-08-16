#!/usr/bin/env python3

import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import check_hardcoded_strings


class HardcodedStringsCheckerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.lib = self.root / "lib"
        self.lib.mkdir()
        self.allowlist_path = self.root / "allowlist.json"
        self.allowlist_path.write_text("{}\n", encoding="utf-8")
        self.enterContext(patch.object(check_hardcoded_strings, "ROOT", self.root))
        self.enterContext(patch.object(check_hardcoded_strings, "LIB_DIR", self.lib))
        self.enterContext(
            patch.object(check_hardcoded_strings, "ALLOWLIST_PATH", self.allowlist_path)
        )

    def _write_source(self, source: str, relative: str = "widgets/example.dart") -> None:
        path = self.lib / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source, encoding="utf-8")

    def _findings(self) -> list[check_hardcoded_strings.Finding]:
        findings, _ = check_hardcoded_strings.scan()
        return findings

    def test_text_literal_is_reported(self):
        self._write_source("Widget build() => const Text('Skip Intro');\n")

        findings = self._findings()

        self.assertEqual([(finding.literal, finding.rule) for finding in findings], [
            ("Skip Intro", "Text first argument")
        ])

    def test_phrase_bound_to_a_name_in_a_ui_file_is_reported(self):
        # The actual shape of issue #1856: the literal never touches Text()
        # directly, it is assigned to a local a few lines above the render.
        self._write_source(
            "Widget build() {\n"
            "  String label;\n"
            "  if (isCredits) {\n"
            "    label = 'Skip Credits';\n"
            "  } else {\n"
            "    label = t.videoControls.skipIntro;\n"
            "  }\n"
            "  return Text(label);\n"
            "}\n"
        )

        findings = self._findings()

        self.assertEqual([(finding.literal, finding.rule) for finding in findings], [
            ("Skip Credits", "display string bound to a name")
        ])

    def test_identifier_bound_to_a_name_is_not_reported(self):
        # Single-token identifiers are indistinguishable from copy by word
        # count alone, so the rule requires a whitespace-separated phrase.
        self._write_source(
            "Widget build() {\n"
            "  final section = 'cast_row';\n"
            "  final mode = 'HDR_UNSUPPORTED';\n"
            "  final tab = 'liveTv';\n"
            "  return Text(t.common.close);\n"
            "}\n"
        )

        self.assertEqual(self._findings(), [])

    def test_phrase_bound_behind_a_log_argument_is_not_reported(self):
        self._write_source(
            "void run() => promptAndCreate(\n"
            "  createdLog: (playlist) => 'Successfully created playlist: ${playlist.title}',\n"
            "  title: Text(t.playlists.create),\n"
            ");\n"
        )

        self.assertEqual(self._findings(), [])

    def test_phrase_bound_in_a_non_ui_file_is_not_reported(self):
        self._write_source(
            "String describe() => 'not name=value';\n",
            relative="services/plain_service.dart",
        )

        self.assertEqual(self._findings(), [])

    def test_translated_text_is_not_reported(self):
        self._write_source("Widget build() => Text(t.videoControls.skipIntro);\n")

        self.assertEqual(self._findings(), [])

    def test_tooltip_literal_is_reported(self):
        self._write_source("Widget build() => IconButton(tooltip: 'Close');\n")

        findings = self._findings()

        self.assertEqual([(finding.literal, finding.rule) for finding in findings], [
            ("Close", "UI named argument")
        ])

    def test_mixed_translation_interpolation_is_reported(self):
        self._write_source("final value = '${t.common.pause} auto-scroll';\n")

        findings = self._findings()

        self.assertEqual([(finding.literal, finding.rule) for finding in findings], [
            ("${t.common.pause} auto-scroll", "mixed translation interpolation")
        ])

    def test_t_lambda_parameter_is_not_mistaken_for_translation_accessor(self):
        self._write_source("final title = tracks.map((t) => 'Track ${t.id}');\n")

        self.assertEqual(self._findings(), [])

    def test_numeric_season_episode_pattern_is_not_reported(self):
        self._write_source(
            "Widget build() => Text("
            "\"${hasIndex ? 'S${season} E${episode}' : ''}\""
            ");\n"
        )

        self.assertEqual(self._findings(), [])

    def test_diagnostic_and_debug_label_literals_are_not_reported(self):
        self._write_source(
            "final widget = Thing(debugLabel: 'Developer controls');\n"
            "appLogger.i(Text('Developer details'));\n"
        )

        self.assertEqual(self._findings(), [])

    def test_allowlisted_literal_is_not_reported(self):
        self._write_source("Widget build() => const Text('Permanent English');\n")
        self.allowlist_path.write_text(
            json.dumps(
                {
                    "lib/widgets/example.dart": {
                        "Permanent English": "Deliberate product terminology"
                    }
                }
            ),
            encoding="utf-8",
        )

        self.assertEqual(self._findings(), [])

    def test_stale_allowlist_report_finds_literal_that_matches_nothing(self):
        self._write_source("Widget build() => Text(t.common.close);\n")
        self.allowlist_path.write_text(
            json.dumps(
                {
                    "lib/widgets/example.dart": {
                        "Removed English": "Former deliberate terminology"
                    }
                }
            ),
            encoding="utf-8",
        )
        output = io.StringIO()

        with contextlib.redirect_stdout(output):
            result = check_hardcoded_strings.main(["--allowlist-missing"])

        self.assertEqual(result, 1)
        self.assertIn("lib/widgets/example.dart: 'Removed English'", output.getvalue())

    def test_comments_directives_keys_units_and_generated_files_are_ignored(self):
        self._write_source(
            "// Text('Comment words')\n"
            "import 'Text(\\'Imported words\\')';\n"
            "final key = ValueKey('Stable widget identity');\n"
            "final duration = Text('min');\n"
        )
        self._write_source("const Text('Generated English');\n", "model.g.dart")
        self._write_source("const Text('Generated English');\n", "model.freezed.dart")
        self._write_source("const Text('Generated English');\n", "i18n/generated.dart")

        self.assertEqual(self._findings(), [])


if __name__ == "__main__":
    unittest.main()
