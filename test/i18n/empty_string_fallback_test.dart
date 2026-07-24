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
}
