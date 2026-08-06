import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/language_codes.dart';

void main() {
  test('bibliographic aliases resolve via trim, case, and variation expansion', () {
    expect(LanguageCodes.getIso6391Code(' DEU '), 'de');
    expect(LanguageCodes.getIso6391Code('ger'), 'de');
    expect(LanguageCodes.getLanguageName('GER'), 'German');
    expect(LanguageCodes.getVariations('ger'), unorderedEquals(<String>['ger', 'de', 'deu']));
    expect(LanguageCodes.getLanguageName('zzz'), isNull);
  });
}
