import json
import tempfile
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import clean_translations


class CollectReferencesTest(unittest.TestCase):
    def test_collects_global_and_explicit_translation_access(self):
        with tempfile.TemporaryDirectory() as directory:
            lib = Path(directory)
            (lib / "widget.dart").write_text(
                """
final first = t.common.home;
final second = Translations.of(context).navigation.liveTv;
final third = Translations . of ( context ) . libraries . hiddenLibrariesCount;
""",
                encoding="utf-8",
            )

            with patch.object(clean_translations, "LIB_DIR", lib):
                references = clean_translations.collect_references()

        self.assertEqual(
            references,
            {
                "common.home",
                "navigation.liveTv",
                "libraries.hiddenLibrariesCount",
            },
        )

    def test_skips_generated_i18n_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            lib = Path(directory)
            i18n = lib / "i18n"
            i18n.mkdir()
            (i18n / "strings.g.dart").write_text(
                "final generated = Translations.of(context).unused.generated;",
                encoding="utf-8",
            )

            with patch.object(clean_translations, "LIB_DIR", lib):
                references = clean_translations.collect_references()

        self.assertEqual(references, set())


class CleanTranslationIntegrationTest(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.i18n = self.root / "lib" / "i18n"
        self.i18n.mkdir(parents=True)
        self.enterContext(patch.object(clean_translations, "ROOT", self.root))
        self.enterContext(patch.object(clean_translations, "I18N_DIR", self.i18n))
        self.enterContext(patch.object(clean_translations, "LIB_DIR", self.root / "lib"))

    def _write_locale(self, locale, value):
        path = self.i18n / f"{locale}.i18n.json"
        path.write_text(clean_translations.dump_json(value), encoding="utf-8")
        return path

    def _run(self, *arguments):
        with patch.object(sys, "argv", ["clean_translations.py", *arguments]):
            return clean_translations.main()

    def test_clean_preserves_and_infers_locale_plural_categories(self):
        source = {
            "count": {"one": "${n} item", "other": "${n} items"},
            "newCount": {"one": "${n} thing", "other": "${n} things"},
        }
        source_path = self._write_locale("en", source)
        polish_path = self._write_locale(
            "pl",
            {
                "count": {
                    "one": "${n} element",
                    "few": "${n} elementy",
                    "many": "${n} elementów",
                    "other": "${n} elementu",
                }
            },
        )
        japanese_path = self._write_locale("ja", {"count": {"other": "${n} 個"}})
        source_text = source_path.read_text(encoding="utf-8")

        self.assertEqual(self._run("--clean"), 0)

        self.assertEqual(json.loads(polish_path.read_text(encoding="utf-8")), {
            "count": {
                "one": "${n} element",
                "few": "${n} elementy",
                "many": "${n} elementów",
                "other": "${n} elementu",
            },
            "newCount": {"one": "", "few": "", "many": "", "other": ""},
        })
        self.assertEqual(
            json.loads(japanese_path.read_text(encoding="utf-8")),
            {"count": {"other": "${n} 個"}, "newCount": {"other": ""}},
        )
        self.assertEqual(source_path.read_text(encoding="utf-8"), source_text)

    def test_check_mode_reports_normalization_without_writing_files(self):
        self._write_locale("en", {"common": {"title": "Hello"}})
        locale_path = self.i18n / "fr.i18n.json"
        locale_path.write_text('{"common":{"title":"Bonjour"}}\n', encoding="utf-8")
        original = locale_path.read_bytes()
        (self.root / "lib" / "widget.dart").write_text("final label = t.common.title;\n", encoding="utf-8")

        # The usage scan must succeed, so a default-mode failure can only come
        # from pending normalization rather than an unrelated unused key.
        self.assertEqual(self._run("--unused", "--strict"), 0)

        self.assertEqual(self._run("--check", "--strict"), 1)
        self.assertEqual(locale_path.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
