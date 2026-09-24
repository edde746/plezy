import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/utils/track_payload.dart';

void main() {
  group('isSafeTrackId', () {
    test('accepts plain mpv ids', () {
      expect(isSafeTrackId('1'), isTrue);
      expect(isSafeTrackId('no'), isTrue);
      expect(isSafeTrackId('auto'), isTrue);
    });

    test('rejects ids that embed a credentialed URL', () {
      // plex_client.dart builds '...?encoding=utf-8&X-Plex-Token=<token>' and
      // the Jellyfin client appends 'api_key=<accessToken>'; SubtitleTrack.uri
      // then makes that the track id.
      expect(isSafeTrackId('external:https://host:32400/x.srt?X-Plex-Token=abc'), isFalse);
      expect(isSafeTrackId('external:/mnt/media/sub.srt'), isFalse);
      expect(isSafeTrackId('https://host/sub.srt?api_key=abc'), isFalse);
    });
  });

  group('indexOfTrackId', () {
    test('finds the position of the selected id', () {
      expect(indexOfTrackId(['1', '2', '3'], '2'), 1);
    });

    test('returns null when absent or unselected', () {
      expect(indexOfTrackId(['1', '2'], '9'), isNull);
      expect(indexOfTrackId(['1', '2'], null), isNull);
    });
  });

  group('audioTracksPayload', () {
    test('serializes id, title, language, codec and channels', () {
      final payload = audioTracksPayload(const [
        AudioTrack(id: '1', title: 'English DTS 5.1', language: 'eng', codec: 'dca', channels: 6),
      ]);

      expect(payload, [
        {'id': '1', 'title': 'English DTS 5.1', 'language': 'eng', 'codec': 'dca', 'channels': 6},
      ]);
    });

    test('omits absent fields rather than sending nulls', () {
      expect(audioTracksPayload(const [AudioTrack(id: '2')]), [
        {'id': '2'},
      ]);
    });
  });

  group('subtitleTracksPayload', () {
    test('serializes id, title, language, codec and the external flag', () {
      final payload = subtitleTracksPayload(const [
        SubtitleTrack(id: '3', title: 'English', language: 'eng', codec: 'subrip'),
      ]);

      expect(payload, [
        {'id': '3', 'title': 'English', 'language': 'eng', 'codec': 'subrip', 'external': false},
      ]);
    });

    test('never leaks a credentialed subtitle URL, in the uri OR the id', () {
      final payload = subtitleTracksPayload([
        SubtitleTrack.uri(
          'https://host:32400/library/streams/1.srt?encoding=utf-8&X-Plex-Token=SUPERSECRET',
          title: 'Hebrew',
          language: 'heb',
        ),
      ]);

      final serialized = payload.single.entries.map((e) => '${e.key}=${e.value}').join('&');
      expect(serialized, isNot(contains('SUPERSECRET')));
      expect(serialized, isNot(contains('X-Plex-Token')));
      expect(serialized, isNot(contains('://')));
      expect(payload.single.containsKey('uri'), isFalse);
      expect(payload.single.containsKey('id'), isFalse, reason: 'external ids embed the credentialed URL');
    });

    test('still describes an external track well enough to select it', () {
      final payload = subtitleTracksPayload([
        SubtitleTrack.uri('https://host/x.srt?X-Plex-Token=abc', title: 'Hebrew', language: 'heb', codec: 'subrip'),
      ]);

      expect(payload.single['language'], 'heb');
      expect(payload.single['codec'], 'subrip');
      expect(payload.single['external'], isTrue);
    });
  });
}
