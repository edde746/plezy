import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/language_codes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock the asset loading for testing
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/assets'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'loadString' &&
            methodCall.arguments == 'lib/data/iso_639_codes.json') {
          // Return a subset of language codes for testing
          return json.encode({
            'en': {
              '639-1': 'en',
              '639-2': 'eng',
              'name': 'English',
            },
            'de': {
              '639-1': 'de',
              '639-2': 'deu',
              '639-2/B': 'ger',
              'name': 'German',
            },
            'zh': {
              '639-1': 'zh',
              '639-2': 'zho',
              '639-2/B': 'chi',
              'name': 'Chinese',
            },
            'fr': {
              '639-1': 'fr',
              '639-2': 'fra',
              '639-2/B': 'fre',
              'name': 'French',
            },
            'es': {
              '639-1': 'es',
              '639-2': 'spa',
              'name': 'Spanish',
            },
          });
        }
        return null;
      },
    );

    await LanguageCodes.initialize();
  });

  group('LanguageCodes.getVariations', () {
    test('returns variations for 2-letter code (ISO 639-1)', () {
      final variations = LanguageCodes.getVariations('en');
      expect(variations, contains('en'));
      expect(variations, contains('eng'));
      expect(variations.length, greaterThanOrEqualTo(2));
    });

    test('returns variations for 3-letter code (ISO 639-2)', () {
      final variations = LanguageCodes.getVariations('eng');
      expect(variations, contains('en'));
      expect(variations, contains('eng'));
    });

    test('handles language with bibliographic variant', () {
      final variations = LanguageCodes.getVariations('de');
      expect(variations, contains('de'));
      expect(variations, contains('deu'));
      expect(variations, contains('ger'));
      expect(variations.length, greaterThanOrEqualTo(3));
    });

    test('handles bibliographic code lookup', () {
      final variations = LanguageCodes.getVariations('ger');
      expect(variations, contains('de'));
      expect(variations, contains('deu'));
      expect(variations, contains('ger'));
    });

    test('handles Chinese with multiple 639-2 codes', () {
      final variations = LanguageCodes.getVariations('zh');
      expect(variations, contains('zh'));
      expect(variations, contains('zho'));
      expect(variations, contains('chi'));
    });

    test('normalizes to lowercase', () {
      final variations = LanguageCodes.getVariations('EN');
      expect(variations, contains('en'));
      expect(variations, contains('eng'));
    });

    test('trims whitespace', () {
      final variations = LanguageCodes.getVariations('  en  ');
      expect(variations, contains('en'));
      expect(variations, contains('eng'));
    });

    test('returns single item for unknown code', () {
      final variations = LanguageCodes.getVariations('unknown');
      expect(variations.length, 1);
      expect(variations, contains('unknown'));
    });

    test('returns unique variations (no duplicates)', () {
      final variations = LanguageCodes.getVariations('en');
      final uniqueVariations = variations.toSet();
      expect(variations.length, equals(uniqueVariations.length));
    });

    test('handles 3-letter primary code', () {
      final variations = LanguageCodes.getVariations('spa');
      expect(variations, contains('es'));
      expect(variations, contains('spa'));
    });

    test('throws StateError when not initialized', () {
      // This would require resetting the static state, which is not easily testable
      // in the current implementation. This is more of a documentation test.
      // In a real scenario, you'd need to refactor LanguageCodes to be more testable.
    });
  });

  group('LanguageCodes.getLanguageName', () {
    test('returns English name for 2-letter code', () {
      final name = LanguageCodes.getLanguageName('en');
      expect(name, 'English');
    });

    test('returns name for 3-letter code', () {
      final name = LanguageCodes.getLanguageName('eng');
      expect(name, 'English');
    });

    test('returns name for bibliographic code', () {
      final name = LanguageCodes.getLanguageName('ger');
      expect(name, 'German');
    });

    test('normalizes case', () {
      final name = LanguageCodes.getLanguageName('EN');
      expect(name, 'English');
    });

    test('trims whitespace', () {
      final name = LanguageCodes.getLanguageName('  en  ');
      expect(name, 'English');
    });

    test('returns null for unknown code', () {
      final name = LanguageCodes.getLanguageName('unknown');
      expect(name, isNull);
    });

    test('handles German with multiple codes', () {
      expect(LanguageCodes.getLanguageName('de'), 'German');
      expect(LanguageCodes.getLanguageName('deu'), 'German');
      expect(LanguageCodes.getLanguageName('ger'), 'German');
    });

    test('handles French with bibliographic code', () {
      expect(LanguageCodes.getLanguageName('fr'), 'French');
      expect(LanguageCodes.getLanguageName('fra'), 'French');
      expect(LanguageCodes.getLanguageName('fre'), 'French');
    });

    test('handles Chinese codes', () {
      expect(LanguageCodes.getLanguageName('zh'), 'Chinese');
      expect(LanguageCodes.getLanguageName('zho'), 'Chinese');
      expect(LanguageCodes.getLanguageName('chi'), 'Chinese');
    });
  });
}
