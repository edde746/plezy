import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/utils/download_utils.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('episode count validation returns a localized message for invalid input', () {
    expect(validateEpisodeCountInput('', allowZero: false), t.downloads.invalidEpisodeCount);
    expect(validateEpisodeCountInput('0', allowZero: false), t.downloads.invalidEpisodeCount);
    expect(validateEpisodeCountInput('not-a-number', allowZero: true), t.downloads.invalidEpisodeCount);
  });

  test('episode count validation accepts zero only when requested', () {
    expect(validateEpisodeCountInput('0', allowZero: true), isNull);
    expect(validateEpisodeCountInput('12', allowZero: false), isNull);
  });
}
