import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/data/iso_639_data.dart';
import 'package:plezy/utils/language_codes.dart';

void main() {
  test('catalog preserves 184 canonical entries and globally unique codes', () {
    final primaryCodes = languageEntries.keys.toList();
    final sortedPrimaryCodes = [...primaryCodes]..sort();
    final allCodes = <String>{};

    expect(languageEntries, hasLength(184));
    expect(primaryCodes, sortedPrimaryCodes);
    for (final mapEntry in languageEntries.entries) {
      final entry = mapEntry.value;
      expect(entry.code1, mapEntry.key);
      expect(entry.code1, matches(RegExp(r'^[a-z]{2}$')));
      expect(entry.code2, matches(RegExp(r'^[a-z]{3}$')));
      expect(entry.name.trim(), isNotEmpty);
      expect(allCodes.add(entry.code1), isTrue);
      expect(allCodes.add(entry.code2), isTrue);
      if (entry.code2B case final bibliographic?) {
        expect(bibliographic, matches(RegExp(r'^[a-z]{3}$')));
        expect(allCodes.add(bibliographic), isTrue);
      }
    }
  });

  test('reverse maps are derived completely from terminology and bibliographic aliases', () {
    expect(code2ToCode1, hasLength(184));
    expect(code2BToCode1, hasLength(20));

    for (final entry in languageEntries.values) {
      expect(code2ToCode1[entry.code2], entry.code1);
      if (entry.code2B case final bibliographic?) {
        expect(code2BToCode1[bibliographic], entry.code1);
      }
    }
  });

  test('representative terminology and bibliographic aliases preserve behavior', () {
    final german = languageEntries['de']!;
    expect(german.code2, 'deu');
    expect(german.code2B, 'ger');
    expect(german.name, 'German');
    expect(languageEntries['bn']!.name, 'Bengali, Bangla');
    expect(languageEntries['mi']!.name, 'Māori');

    expect(LanguageCodes.getIso6391Code(' DEU '), 'de');
    expect(LanguageCodes.getIso6391Code('ger'), 'de');
    expect(LanguageCodes.getLanguageName('GER'), 'German');
    expect(LanguageCodes.getVariations('ger'), unorderedEquals(<String>['ger', 'de', 'deu']));
    expect(LanguageCodes.getLanguageName('zzz'), isNull);
  });
}
