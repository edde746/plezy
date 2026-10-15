import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_part_timeline.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/services/jellyfin_media_info_mapper.dart';
import 'package:plezy/services/scrub_preview_source.dart';

MediaSourceInfo _jellyfinSource(String id) => jellyfinMediaSourceToMediaSourceInfo(
  {'Id': id, 'MediaStreams': const []},
  trickplay: const {
    '320': {'Width': 320, 'Height': 180, 'TileWidth': 10, 'TileHeight': 10, 'ThumbnailCount': 100, 'Interval': 10000},
  },
);

MediaSourceInfo _plexSource({required int partId, String version = 'v1', MediaPartTimeline? timeline}) =>
    MediaSourceInfo(
      videoUrl: '',
      audioTracks: const [],
      subtitleTracks: const [],
      chapters: const [],
      partId: partId,
      mediaSourceId: version,
      partTimeline: timeline,
    );

void main() {
  group('scrubPreviewServes', () {
    test('a Jellyfin/Emby preview serves the source it was built for', () {
      // Regression (#2682): MediaBrowser sources carry no part id, and the
      // guard discarded every trickplay/BIF preview as stale.
      expect(scrubPreviewServes(_jellyfinSource('a'), _jellyfinSource('a')), isTrue);
      expect(scrubPreviewServes(_jellyfinSource('a'), _jellyfinSource('b')), isFalse);
    });

    test('a Plex preview serves its own part only', () {
      expect(scrubPreviewServes(_plexSource(partId: 1), _plexSource(partId: 1)), isTrue);
      expect(scrubPreviewServes(_plexSource(partId: 1), _plexSource(partId: 2)), isFalse);
    });

    test('a stacked Plex preview serves every file of its version', () {
      const parts = [MediaPart(id: '1', durationMs: 3000000), MediaPart(id: '2', durationMs: 2400000)];
      MediaSourceInfo file(int index, {String version = 'v1'}) => _plexSource(
        partId: index + 1,
        version: version,
        timeline: MediaPartTimeline.fromParts(parts, currentIndex: index),
      );

      expect(scrubPreviewServes(file(0), file(1)), isTrue);
      expect(scrubPreviewServes(file(0), file(1, version: 'v2')), isFalse);
    });
  });
}
