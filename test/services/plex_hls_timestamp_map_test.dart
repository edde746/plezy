import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_hls_timestamp_map.dart';

void main() {
  group('hlsSubtitleRenditionUri', () {
    test('finds the SUBTITLES rendition among other media lines', () {
      const master =
          '#EXTM3U\n'
          '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",NAME="English",URI="audio/index.m3u8"\n'
          '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",DEFAULT=YES,URI="subtitles/index.m3u8"\n'
          '#EXT-X-STREAM-INF:BANDWIDTH=3000000,SUBTITLES="subs"\n'
          'video/index.m3u8\n';
      expect(hlsSubtitleRenditionUri(master), 'subtitles/index.m3u8');
    });

    test('returns null without a subtitles rendition or for a non-playlist body', () {
      expect(hlsSubtitleRenditionUri('#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1\nvideo.m3u8\n'), isNull);
      expect(hlsSubtitleRenditionUri('<html>503 Service Unavailable</html>'), isNull);
    });
  });

  group('hlsSegmentUris', () {
    test('returns the non-tag lines in order', () {
      const playlist = '#EXTM3U\n#EXT-X-TARGETDURATION:6\n#EXTINF:6.0,\nseg-0.vtt\n#EXTINF:6.0,\nseg-1.vtt\n';
      expect(hlsSegmentUris(playlist), ['seg-0.vtt', 'seg-1.vtt']);
    });

    test('returns an empty list for a playlist with no segments', () {
      expect(hlsSegmentUris('#EXTM3U\n#EXT-X-TARGETDURATION:6\n'), isEmpty);
    });
  });

  group('webVttTimestampMapOffsetMs', () {
    test('parses the Plex-shaped header (LOCAL first, MM:SS.mmm)', () {
      const segment = 'WEBVTT\nX-TIMESTAMP-MAP=LOCAL:00:00.000,MPEGTS:900000\n\n00:00.500 --> 00:02.000\nHello\n';
      expect(webVttTimestampMapOffsetMs(segment), 10000);
    });

    test('parses the attribute order and HH:MM:SS.mmm form from the HLS spec', () {
      const segment = 'WEBVTT\nX-TIMESTAMP-MAP=MPEGTS:900000,LOCAL:00:00:00.000\n';
      expect(webVttTimestampMapOffsetMs(segment), 10000);
    });

    test('subtracts a non-zero LOCAL from the MPEG-TS clock', () {
      // 1350000 / 90 = 15000ms, LOCAL 2.5s → 12500ms.
      const segment = 'WEBVTT\nX-TIMESTAMP-MAP=LOCAL:00:00:02.500,MPEGTS:1350000\n';
      expect(webVttTimestampMapOffsetMs(segment), 12500);
    });

    test('a mapless segment is no evidence — Plex serves bare WEBVTT stubs for cue-less spans', () {
      expect(webVttTimestampMapOffsetMs('WEBVTT\n'), isNull);
      expect(webVttTimestampMapOffsetMs('WEBVTT\n\n00:00.500 --> 00:02.000\nHello\n'), isNull);
    });

    test('rejects non-WebVTT bodies and malformed maps', () {
      expect(webVttTimestampMapOffsetMs('<html>503 Service Unavailable</html>'), isNull);
      expect(webVttTimestampMapOffsetMs('WEBVTT\nX-TIMESTAMP-MAP=MPEGTS:900000\n'), isNull);
      expect(webVttTimestampMapOffsetMs('WEBVTT\nX-TIMESTAMP-MAP=LOCAL:bogus,MPEGTS:900000\n'), isNull);
      expect(webVttTimestampMapOffsetMs('WEBVTT\nX-TIMESTAMP-MAP=LOCAL:99:99.999,MPEGTS:900000\n'), isNull);
    });
  });
}
