import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/plex_url_helper.dart';

void main() {
  group('withPlexToken', () {
    test('appends with ? when no existing query', () {
      expect('/library/metadata/1'.withPlexToken('abc'), '/library/metadata/1?X-Plex-Token=abc');
    });

    test('appends with & when query already present', () {
      expect('/library/metadata/1?type=1'.withPlexToken('abc'), '/library/metadata/1?type=1&X-Plex-Token=abc');
    });

    test('returns original URL when token is null', () {
      expect('/library/metadata/1'.withPlexToken(null), '/library/metadata/1');
    });

    test('returns original URL when token is empty', () {
      expect('/library/metadata/1'.withPlexToken(''), '/library/metadata/1');
    });

    test('treats trailing ? (no params yet) as already having query', () {
      expect('/path?'.withPlexToken('tk'), '/path?&X-Plex-Token=tk');
    });
  });
}
