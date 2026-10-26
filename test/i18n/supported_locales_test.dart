import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/app_locale_utils.dart';
import 'package:plezy/i18n/locale_preferences.dart';
import 'package:plezy/i18n/presentation_formats.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/utils/language_codes.dart';

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('all catalog locales load Material controls, translated labels and text direction', (tester) async {
    for (final locale in AppLocale.values) {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      expect(
        GlobalMaterialLocalizations.delegate.isSupported(locale.localizationsLocale),
        isTrue,
        reason: locale.languageTag,
      );
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(locale),
          locale: locale.localizationsLocale,
          supportedLocales: supportedLocalizationsLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: Text(t.settings.languageAndRegion)),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.text(t.settings.languageAndRegion));
      expect(
        Directionality.of(context),
        locale.isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
        reason: locale.languageTag,
      );
      expect(t.platform.cameraPermission, isNotEmpty);
      expect(t.homeLayout.title, isNotEmpty);
      expect(LanguageCodes.getDisplayName('zh-Hant-TW'), isNotEmpty);
      expect(formatLocalizedUnit(2, 'hour', width: 'long'), isNotEmpty);
      expect(LocalePreferences.formattingLocaleName, isNotEmpty);
      expect(tester.takeException(), isNull, reason: locale.languageTag);
    }
  });

  test('regional variants resolve without losing script or region', () {
    expect(resolvePreferredAppLocale([const Locale('es', 'MX')]).languageTag, 'es-419');
    expect(resolvePreferredAppLocale([const Locale('pt', 'BR')]).languageTag, 'pt-BR');
    expect(resolvePreferredAppLocale([const Locale('pt', 'PT')]).languageTag, 'pt-PT');
    expect(
      resolvePreferredAppLocale([
        const Locale.fromSubtags(languageCode: 'fr', scriptCode: 'Latn', countryCode: 'CA'),
      ]).languageTag,
      'fr-CA',
    );
    expect(resolvePreferredAppLocale([const Locale('zh', 'HK')]), AppLocale.zhHant);
  });

  test('regional catalogs inherit untranslated override keys from their parent', () async {
    final french = await AppLocale.fr.build();
    final canada = await AppLocaleUtils.parse('fr-CA').build();
    expect(canada.settings.metadataLanguageDescription, french.settings.metadataLanguageDescription);
    final portuguese = await AppLocale.pt.build();
    final brazil = await AppLocaleUtils.parse('pt-BR').build();
    expect(brazil.homeLayout.tvWrapDescription, portuguese.homeLayout.tvWrapDescription);
  });
}
