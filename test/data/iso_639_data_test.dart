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

  group('regional languages', () {
    test('regional language codes and aliases normalize correctly', () {
      expect(LanguageCodes.normalizeCode('pt-BR'), 'pt-BR');
      expect(LanguageCodes.normalizeCode('pt_BR'), 'pt-BR');
      expect(LanguageCodes.normalizeCode('pt-br'), 'pt-BR');
      expect(LanguageCodes.normalizeCode('pob'), 'pt-BR');
      expect(LanguageCodes.normalizeCode('pt-PT'), 'pt-PT');
      expect(LanguageCodes.normalizeCode('es-419'), 'es-419');
      expect(LanguageCodes.normalizeCode('zh-Hans'), 'zh-Hans');
      expect(LanguageCodes.normalizeCode('zh-Hant'), 'zh-Hant');
      expect(LanguageCodes.normalizeCode('fr-CA'), 'fr-CA');
      expect(LanguageCodes.normalizeCode('eng'), 'en');
      expect(LanguageCodes.normalizeCode('deu'), 'de');
      expect(LanguageCodes.normalizeCode('en-US'), 'en');
      expect(LanguageCodes.normalizeCode(''), isNull);
      expect(LanguageCodes.normalizeCode(null), isNull);
      expect(LanguageCodes.normalizeCode('zz'), isNull);
    });

    test('display names include regional disambiguation and script descriptions', () {
      expect(LanguageCodes.getDisplayName('pt-BR'), 'Portuguese (Brazil)');
      expect(LanguageCodes.getDisplayName('pt_BR'), 'Portuguese (Brazil)');
      expect(LanguageCodes.getDisplayName('pob'), 'Portuguese (Brazil)');
      expect(LanguageCodes.getDisplayName('pt-PT'), 'Portuguese (Portugal)');
      expect(LanguageCodes.getDisplayName('es-419'), 'Spanish (Latin America)');
      expect(LanguageCodes.getDisplayName('zh-Hans'), 'Chinese (Simplified)');
      expect(LanguageCodes.getDisplayName('zh-Hant'), 'Chinese (Traditional)');
      expect(LanguageCodes.getDisplayName('en'), 'English');
      expect(LanguageCodes.getDisplayName('pt'), 'Portuguese');
    });

    test('getAllLanguages includes regional variants alongside base codes', () {
      final all = LanguageCodes.getAllLanguages();
      final codes = all.map((l) => l.code).toSet();
      expect(codes.contains('pt'), isTrue);
      expect(codes.contains('pt-BR'), isTrue);
      expect(codes.contains('pt-PT'), isTrue);
      expect(codes.contains('es-419'), isTrue);
      expect(codes.contains('zh-Hans'), isTrue);
      expect(codes.contains('zh-Hant'), isTrue);

      final ptBr = all.firstWhere((l) => l.code == 'pt-BR');
      expect(ptBr.name, 'Portuguese (Brazil)');
      final ptPt = all.firstWhere((l) => l.code == 'pt-PT');
      expect(ptPt.name, 'Portuguese (Portugal)');
    });

    test('getVariations bridges regional codes and 3-letter aliases', () {
      expect(LanguageCodes.getVariations('pt-BR'), containsAll(<String>['pt-br', 'pob', 'pt', 'por']));
      expect(LanguageCodes.getVariations('pob'), containsAll(<String>['pob', 'pt-br', 'pt', 'por']));
    });
  });
}
