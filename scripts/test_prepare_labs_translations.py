import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("prepare-labs-translations.py")
SPEC = importlib.util.spec_from_file_location("prepare_labs_translations", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
prepare_labs_translations = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(prepare_labs_translations)


class PrepareLabsTranslationsTest(unittest.TestCase):
    def test_fills_missing_and_empty_values_without_replacing_translations(self):
        source = {
            "plain": "English",
            "parameterized": "Version ${version}",
            "nested": {"new": "New", "translated": "English value"},
        }
        locale = {
            "parameterized": "",
            "nested": {"translated": "Translated value"},
        }

        self.assertEqual(
            prepare_labs_translations.add_fallbacks(source, locale),
            {
                "plain": "English",
                "parameterized": "Version ${version}",
                "nested": {"new": "New", "translated": "Translated value"},
            },
        )

    def test_check_reports_files_that_need_preparation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "en.i18n.json").write_text(json.dumps({"label": "Label"}) + "\n", encoding="utf-8")
            locale_path = root / "de.i18n.json"
            locale_path.write_text("{}\n", encoding="utf-8")

            changed = prepare_labs_translations.prepare(check=True, directory=root)

        self.assertEqual(changed, [locale_path])

    def test_labs_owned_values_override_stale_locale_branding(self):
        source = {
            "app": {"title": "Plezy Labs"},
            "about": {"labsDescription": "Labs description", "ordinary": "English"},
        }
        locale = {
            "app": {"title": "Plezy"},
            "about": {"labsDescription": "Old Labs text", "ordinary": "Translated"},
        }

        prepared = prepare_labs_translations.add_fallbacks(source, locale)
        prepare_labs_translations.apply_labs_owned_values(source, prepared)

        self.assertEqual(prepared["app"]["title"], "Plezy Labs")
        self.assertEqual(prepared["about"]["labsDescription"], "Labs description")
        self.assertEqual(prepared["about"]["ordinary"], "Translated")


if __name__ == "__main__":
    unittest.main()
