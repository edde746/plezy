import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';

void main() {
  test('completed locale entries override the English fallback', () async {
    final english = await AppLocale.en.build();
    final englishValues = <String>[
      english.videoControls.showPlaybackControls,
      english.videoControls.hidePlaybackControls,
      english.settings.tvCornerSpotlightBackdrop,
      english.settings.tvCornerSpotlightBackdropDescription,
    ];

    expect(englishValues, everyElement(isNotEmpty));

    for (final locale in AppLocale.values.where((locale) => locale != AppLocale.en)) {
      final translations = await locale.build();
      final localizedValues = <String>[
        translations.videoControls.showPlaybackControls,
        translations.videoControls.hidePlaybackControls,
        translations.settings.tvCornerSpotlightBackdrop,
        translations.settings.tvCornerSpotlightBackdropDescription,
      ];

      for (var index = 0; index < localizedValues.length; index++) {
        expect(
          localizedValues[index],
          isNot(englishValues[index]),
          reason: '${locale.name} must provide its own completed translation at index $index',
        );
      }
    }
  });

  test('untranslated Steam experience labels use the English fallback', () async {
    final english = await AppLocale.en.build();

    for (final locale in AppLocale.values.where((locale) => locale != AppLocale.en)) {
      final translations = await locale.build();
      expect(
        translations.games.gameDetails,
        english.games.gameDetails,
        reason: '${locale.languageTag} must use the English fallback for untranslated Steam copy',
      );
      expect(
        translations.games.steamBetaTitle,
        english.games.steamBetaTitle,
        reason: '${locale.languageTag} must use English for revised Steam copy awaiting translation review',
      );
      expect(
        translations.games.remoteSessions,
        english.games.remoteSessions,
        reason: '${locale.languageTag} must use English for new Companion Remote copy awaiting translation review',
      );
    }
  });
}
