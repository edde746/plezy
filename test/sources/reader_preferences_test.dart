import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/reader_preferences.dart';
import 'package:plezy/sources/source_models.dart';

void main() {
  test('comic preferences reset fully and reject corrupted values', () {
    final defaults = normalizeReaderPreferences({});
    expect(defaults['comicMode'], 'paged');
    expect(defaults['coverAlone'], isTrue);
    expect(defaults['splitWide'], isFalse);
    expect(normalizeReaderPreferences({'comicMode': 'unknown', 'zoom': double.nan}), defaults);
    final custom = normalizeReaderPreferences({
      'comicMode': 'webtoon',
      'zoom': 'fit-height',
      'coverAlone': false,
      'splitWide': true,
      'direction': 'rtl',
    });
    expect(custom['comicMode'], 'webtoon');
    expect(custom['zoom'], 'fit-height');
    expect(custom['coverAlone'], isFalse);
    expect(custom['splitWide'], isTrue);
    expect(custom['direction'], 'rtl');
    expect(normalizeReaderPreferences(custom), custom);
  });

  test('stream-only editions survive persistence without changing edition identity', () {
    const streamed = PublicationFile(
      id: 'book',
      name: 'Comic.cbz',
      mimeType: 'application/vnd.comicbook+zip',
      revision: 'v1',
      streamOnly: true,
    );
    final restored = PublicationFile.fromJson(streamed.toJson());
    expect(restored.streamOnly, isTrue);
    expect(restored.fingerprint, streamed.fingerprint);
    final old = Map<String, dynamic>.from(streamed.toJson())..remove('streamOnly');
    final downloadable = PublicationFile.fromJson(old);
    expect(downloadable.streamOnly, isFalse);
    expect(downloadable.fingerprint, streamed.fingerprint);
  });
}
