import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/trailer_urls.dart';

void main() {
  group('youTubeVideoId', () {
    test('reads the id from every YouTube link shape providers send', () {
      for (final url in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtube.com/watch?v=dQw4w9WgXcQ&t=42',
        'https://m.youtube.com/watch?feature=share&v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?si=abc',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        ' https://www.youtube.com/shorts/dQw4w9WgXcQ ',
      ]) {
        expect(youTubeVideoId(url), 'dQw4w9WgXcQ', reason: url);
      }
    });

    test('rejects other sites, bare ids and malformed ids', () {
      for (final url in [
        null,
        '',
        'dQw4w9WgXcQ',
        'https://vimeo.com/123456789',
        'https://notyoutube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/watch',
        'https://www.youtube.com/watch?v=too-short',
        'https://www.youtube.com/channel/UC1234567890',
      ]) {
        expect(youTubeVideoId(url), isNull, reason: url);
      }
    });
  });

  test('youTubeAppUrl passes the id as the watch query under the app scheme', () {
    expect(youTubeAppUrl('https://youtu.be/dQw4w9WgXcQ').toString(), 'youtube://www.youtube.com/watch?v=dQw4w9WgXcQ');
    expect(youTubeAppUrl('https://vimeo.com/123456789'), isNull);
  });
}
