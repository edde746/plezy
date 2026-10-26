import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('localizations', Path(__file__).with_name('check_localizations.py'))
checks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)

class LocalizationChecksTest(unittest.TestCase):
    def test_reordered_placeholders_are_valid(self):
        self.assertEqual(checks.validate_message('ar', '${title}: ${count}', '${count}: ${title}'), [])

    def test_changed_or_duplicated_placeholder_is_rejected(self):
        self.assertTrue(checks.validate_message('x', '${name}', '${nombre}'))
        self.assertTrue(checks.validate_message('x', '${name}', '${name} ${name}'))

    def test_arabic_dual_can_omit_number_but_not_title(self):
        source = {'one': '${n} file in ${title}', 'other': '${n} files in ${title}'}
        target = {'two': 'ملفان في ${title}', 'other': '${n} ملف في ${title}'}
        self.assertEqual(checks.validate_message('ar', source, target), [])
        target['two'] = 'ملفان'
        self.assertTrue(checks.validate_message('ar', source, target))

    def test_regional_override_preserves_unmodified_parent_fields(self):
        parent = {'settings': {'language': 'Langue', 'save': 'Enregistrer'}}
        variant = {'settings': {'save': 'Sauvegarder'}}
        self.assertEqual(checks.merge(parent, variant)['settings'], {'language': 'Langue', 'save': 'Sauvegarder'})
        self.assertEqual(parent['settings']['save'], 'Enregistrer')

    def test_empty_text_and_bidi_override_fail(self):
        self.assertTrue(checks.validate_message('ar', 'Hello', ''))
        self.assertTrue(checks.validate_message('ar', 'Hello', '\u202eمرحبا'))

    def test_source_changes_are_sensitive_to_copy_and_plural_forms(self):
        self.assertNotEqual(checks.digest('Delete'), checks.digest('Remove'))
        self.assertNotEqual(checks.digest({'other':'${n} files'}), checks.digest({'one':'One file','other':'${n} files'}))

if __name__ == '__main__':
    unittest.main()
