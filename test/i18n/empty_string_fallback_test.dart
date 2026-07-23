import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';

void main() {
  test('empty overrides fall back in every affected locale', () async {
    final english = await AppLocale.en.build();
    final commonEnglishValues = <String>[
      english.videoControls.showPlaybackControls,
      english.videoControls.hidePlaybackControls,
    ];
    final spotlightEnglishValues = <String>[
      english.settings.tvCornerSpotlightBackdrop,
      english.settings.tvCornerSpotlightBackdropDescription,
    ];

    expect([...commonEnglishValues, ...spotlightEnglishValues], everyElement(isNotEmpty));

    const commonFallbackLocales = <AppLocale>[
      AppLocale.bg,
      AppLocale.da,
      AppLocale.de,
      AppLocale.es,
      AppLocale.fr,
      AppLocale.it,
      AppLocale.ja,
      AppLocale.ko,
      AppLocale.nb,
      AppLocale.nl,
      AppLocale.pl,
      AppLocale.pt,
      AppLocale.ru,
      AppLocale.sv,
      AppLocale.zh,
    ];
    const spotlightFallbackLocales = <AppLocale>[
      AppLocale.bg,
      AppLocale.da,
      AppLocale.es,
      AppLocale.fr,
      AppLocale.it,
      AppLocale.ja,
      AppLocale.ko,
      AppLocale.nb,
      AppLocale.nl,
      AppLocale.pl,
      AppLocale.pt,
      AppLocale.ru,
      AppLocale.sv,
      AppLocale.zh,
    ];

    for (final locale in commonFallbackLocales) {
      final translations = await locale.build();
      expect(
        <String>[translations.videoControls.showPlaybackControls, translations.videoControls.hidePlaybackControls],
        commonEnglishValues,
        reason: '${locale.languageCode} must inherit the common English values',
      );
    }

    for (final locale in spotlightFallbackLocales) {
      final translations = await locale.build();
      expect(
        <String>[
          translations.settings.tvCornerSpotlightBackdrop,
          translations.settings.tvCornerSpotlightBackdropDescription,
        ],
        spotlightEnglishValues,
        reason: '${locale.languageCode} must inherit the English spotlight values',
      );
    }
  });
}
