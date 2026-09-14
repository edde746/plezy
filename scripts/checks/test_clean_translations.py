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


class NormalizePluralTest(unittest.TestCase):
    def _normalize(self, en, locale):
        stats = {"added": 0, "removed": 0, "type_fixed": 0, "unchanged": 0}
        categories = clean_translations.locale_plural_categories(en, locale)
        return clean_translations.normalize(en, locale, "", stats, categories), stats

    def test_preserves_locale_specific_plural_categories(self):
        en = {"count": {"one": "${n} item", "other": "${n} items"}}
        locale = {
            "count": {
                "one": "${n} element",
                "few": "${n} elementy",
                "many": "${n} elementów",
                "other": "${n} elementu",
            }
        }

        normalized, stats = self._normalize(en, locale)

        self.assertEqual(normalized, locale)
        self.assertEqual(stats["removed"], 0)

    def test_does_not_inject_one_into_other_only_locales(self):
        en = {"count": {"one": "${n} item", "other": "${n} items"}}
        locale = {"count": {"other": "${n} 個"}}

        normalized, stats = self._normalize(en, locale)

        self.assertEqual(normalized, locale)
        self.assertEqual(stats["added"], 0)

    def test_new_plural_branches_use_categories_inferred_from_locale(self):
        en = {
            "existing": {"one": "one", "other": "other"},
            "new": {"one": "one", "other": "other"},
        }
        locale = {
            "existing": {
                "one": "one",
                "few": "few",
                "many": "many",
                "other": "other",
            }
        }

        normalized, _ = self._normalize(en, locale)

        self.assertEqual(set(normalized["new"]), {"one", "few", "many", "other"})


class MainExitStatusTest(unittest.TestCase):
    def test_check_fails_when_locale_normalization_would_change_files(self):
        with tempfile.TemporaryDirectory() as directory:
            i18n = Path(directory)
            (i18n / "en.i18n.json").write_text("{}\n", encoding="utf-8")
            with (
                patch.object(clean_translations, "I18N_DIR", i18n),
                patch.object(clean_translations, "ROOT", i18n),
                patch.object(clean_translations, "clean_pass", return_value=True),
                patch.object(clean_translations, "unused_pass", return_value=0),
                patch.object(sys, "argv", ["clean_translations.py", "--check", "--strict"]),
            ):
                result = clean_translations.main()

        self.assertEqual(result, 1)


if __name__ == "__main__":
    unittest.main()
