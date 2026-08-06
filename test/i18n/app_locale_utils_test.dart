import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/app_locale_utils.dart';
import 'package:plezy/i18n/strings.g.dart';

void main() {
  group('resolvePreferredAppLocale', () {
    test('uses explicit Chinese scripts before regions', () {
      expect(
        resolvePreferredAppLocale([
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
        ]),
        AppLocale.zhHant,
      );
      expect(
        resolvePreferredAppLocale([
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'TW'),
        ]),
        AppLocale.zh,
      );
    });

    test('maps region-only Chinese locales to the expected script', () {
      for (final region in const ['TW', 'HK', 'MO']) {
        expect(resolvePreferredAppLocale([Locale('zh', region)]), AppLocale.zhHant, reason: region);
      }
      for (final region in const ['CN', 'SG']) {
        expect(resolvePreferredAppLocale([Locale('zh', region)]), AppLocale.zh, reason: region);
      }
    });

    test('preserves device preference order', () {
      expect(
        resolvePreferredAppLocale(const [
          Locale('fr', 'FR'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ]),
        AppLocale.fr,
      );
      expect(
        resolvePreferredAppLocale(const [Locale('xx'), Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')]),
        AppLocale.zhHant,
      );
      expect(
        resolvePreferredAppLocale(const [Locale('zh'), Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')]),
        AppLocale.zh,
      );
    });
  });

}
