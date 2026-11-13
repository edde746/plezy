import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

    test('maps European Portuguese regions to pt-PT and the rest to Brazilian Portuguese', () {
      for (final region in const ['PT', 'AO', 'MZ', 'CV', 'GW', 'ST', 'TL', 'MO', 'GQ', 'LU', 'CH']) {
        expect(resolvePreferredAppLocale([Locale('pt', region)]), AppLocale.ptPt, reason: region);
      }
      expect(resolvePreferredAppLocale(const [Locale('pt', 'BR')]), AppLocale.pt);
      expect(resolvePreferredAppLocale(const [Locale('pt')]), AppLocale.pt);
      expect(resolvePreferredAppLocale(const [Locale('pt', 'US')]), AppLocale.pt);
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
      expect(resolvePreferredAppLocale(const [Locale('xx'), Locale('pt', 'PT')]), AppLocale.ptPt);
      expect(resolvePreferredAppLocale(const [Locale('pt', 'BR'), Locale('pt', 'PT')]), AppLocale.pt);
    });
  });

  group('languagePickerLocales', () {
    test('lists every locale once with variants after their base language', () {
      expect(languagePickerLocales.toSet(), AppLocale.values.toSet());
      expect(languagePickerLocales, hasLength(AppLocale.values.length));
      expect(languagePickerLocales.indexOf(AppLocale.ptPt), languagePickerLocales.indexOf(AppLocale.pt) + 1);
      expect(languagePickerLocales.indexOf(AppLocale.zhHant), languagePickerLocales.indexOf(AppLocale.zh) + 1);
      expect(languagePickerLocales.first, AppLocale.en);
    });
  });

  group('localizationsLocale', () {
    // Every Text inherits this locale, and platform font fallback picks Han
    // glyph forms from it. DirectWrite resolves a bare `zh` to a Japanese font.
    test('Chinese names the script and region that pick Chinese glyph forms', () {
      expect(
        AppLocale.zh.localizationsLocale,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
      );
      expect(
        AppLocale.zhHant.localizationsLocale,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
      );
    });

    test('European Portuguese names its region', () {
      expect(AppLocale.pt.localizationsLocale, const Locale('pt'));
      expect(AppLocale.ptPt.localizationsLocale, const Locale('pt', 'PT'));
    });

    // The app hands this locale to MaterialApp; a language no delegate
    // supports would leave MaterialLocalizations.of without a value.
    test('every app language loads every global localizations delegate', () async {
      expect(supportedLocalizationsLocales, hasLength(AppLocale.values.length));
      for (final appLocale in AppLocale.values) {
        final locale = appLocale.localizationsLocale;
        expect(supportedLocalizationsLocales, contains(locale));
        for (final delegate in GlobalMaterialLocalizations.delegates) {
          expect(delegate.isSupported(locale), isTrue, reason: '${delegate.type} for $locale');
          await delegate.load(locale);
        }
      }
    });
  });
}
