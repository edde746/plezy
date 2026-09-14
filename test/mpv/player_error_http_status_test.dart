import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';

void main() {
  group('PlayerError.httpStatusFromLog', () {
    test('reads the status out of the ffmpeg warn line that precedes a failed open', () {
      // Verbatim from the #1750 report: the only line in the whole failure that
      // names the status. The error-level "Failed to open ..." that follows
      // omits it.
      expect(PlayerError.httpStatusFromLog('http: HTTP error 404 Not Found'), 404);
      expect(PlayerError.httpStatusFromLog('http: HTTP error 500 Internal Server Error'), 500);
      expect(PlayerError.httpStatusFromLog('http: HTTP error 503 Service Unavailable'), 503);
    });

    test('reads the status media3 stringifies into its exception chain', () {
      expect(
        PlayerError.httpStatusFromLog(
          'androidx.media3.datasource.HttpDataSource\$InvalidResponseCodeException: Response code: 404',
        ),
        404,
      );
      expect(PlayerError.httpStatusFromLog('Response code: 500'), 500);
    });

    test('returns null for player logs that name no status', () {
      expect(PlayerError.httpStatusFromLog('Failed to open https://jf.example.com/Videos/item-1/stream.'), isNull);
      expect(PlayerError.httpStatusFromLog('loading failed'), isNull);
      expect(PlayerError.httpStatusFromLog(''), isNull);
    });

    test('does not mistake an unrelated number for a status', () {
      expect(PlayerError.httpStatusFromLog('Set property: stream-buffer-size="404"'), isNull);
      expect(PlayerError.httpStatusFromLog('audio/aac 500 kbps'), isNull);
      // Adjacent digits are not a 3-digit status.
      expect(PlayerError.httpStatusFromLog('http: HTTP error 4040 Nope'), isNull);
    });

    test('reports the first status when a line names several', () {
      expect(PlayerError.httpStatusFromLog('HTTP error 404 after HTTP error 500'), 404);
    });
  });

  group('fatalPlaybackHttpStatuses', () {
    test('excludes the 503 the reconnect path deliberately retries', () {
      // stream-lavf-o sets reconnect_on_http_error=503, so a 503 is expected
      // mid-playback and must not latch as fatal. At open time the player
      // screen's OpenHttp503Watchdog bounds the loop instead — only its
      // synthesized cause tag, never a raw latched status, ends playback.
      expect(fatalPlaybackHttpStatuses.contains(503), isFalse);
      expect(PlayerError.httpStatusFromLog('http: HTTP error 503 Service Unavailable'), 503);
    });
  });
}
