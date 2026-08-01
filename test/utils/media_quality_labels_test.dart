import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_stream.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/services/jellyfin_mappers.dart';
import 'package:plezy/services/plex_mappers.dart';
import 'package:plezy/utils/media_quality_labels.dart';
import '../test_helpers/media_items.dart';

void main() {
  group('buildMediaQualityLabels', () {
    test('formats resolution, Dolby Vision, and Atmos audio', () {
      final item = _episodeWithVersion(
        MediaVersion(
          id: '1',
          videoResolution: '4k',
          parts: const [
            MediaPart(
              id: 'part-1',
              streams: [
                MediaStream(id: 'video', kind: MediaStreamKind.video, hdr: true, dolbyVision: true),
                MediaStream(
                  id: 'audio',
                  kind: MediaStreamKind.audio,
                  codec: 'truehd',
                  displayTitle: 'English (TrueHD Atmos 7.1)',
                  channels: 8,
                  selected: true,
                ),
              ],
            ),
          ],
        ),
      );

      expect(buildMediaQualityLabels(item), ['4K', 'DV', 'TrueHD Atmos']);
    });

    test('formats Dolby Vision profile when stream metadata includes it', () {
      final item = _episodeWithVersion(
        MediaVersion(
          id: '1',
          videoResolution: '4k',
          parts: const [
            MediaPart(
              id: 'part-1',
              streams: [
                MediaStream(
                  id: 'video',
                  kind: MediaStreamKind.video,
                  hdr: true,
                  dolbyVision: true,
                  dolbyVisionProfile: 8,
                ),
                MediaStream(id: 'audio', kind: MediaStreamKind.audio, codec: 'eac3', channels: 6),
              ],
            ),
          ],
        ),
      );

      expect(buildMediaQualityLabels(item), ['4K', 'DV P8', 'EAC3 5.1']);
    });

    test('formats HDR and surround channel count', () {
      final item = _episodeWithVersion(
        MediaVersion(
          id: '1',
          videoResolution: '1080',
          parts: const [
            MediaPart(
              id: 'part-1',
              streams: [
                MediaStream(id: 'video', kind: MediaStreamKind.video, hdr: true),
                MediaStream(id: 'audio', kind: MediaStreamKind.audio, codec: 'eac3', channels: 6),
              ],
            ),
          ],
        ),
      );

      expect(buildMediaQualityLabels(item), ['1080p', 'HDR', 'EAC3 5.1']);
    });

    test('formats Plex season child fallback metadata', () {
      final item = PlexMappers.mediaItemFromJson({
        'ratingKey': '6048',
        'type': 'episode',
        'title': 'Hello, Ms. Cobel',
        'Media': [
          {
            'id': '6136',
            'audioChannels': '6',
            'audioCodec': 'eac3',
            'videoCodec': 'hevc',
            'videoResolution': '4k',
            'width': '3840',
            'height': '1606',
            'Part': [
              {
                'id': '6154',
                'key': '/library/parts/6154/file.mkv',
                'file': '/tv/Severance.S02.Hybrid.MULTI.2160p.WEB-DL.DV.HDR.H265-AOC/S02/S02E01.mkv',
              },
            ],
          },
        ],
      }, serverId: ServerId('plex'));

      expect(buildMediaQualityLabels(item), ['4K', 'DV', 'EAC3 5.1']);
    });

    test('formats Plex movie full-detail stream metadata', () {
      final item = PlexMappers.mediaItemFromJson({
        'ratingKey': 'movie-1',
        'type': 'movie',
        'title': 'Movie',
        'Media': [
          {
            'id': 'media-1',
            'audioChannels': 6,
            'audioCodec': 'eac3',
            'videoCodec': 'hevc',
            'videoResolution': '4k',
            'Part': [
              {
                'id': 'part-1',
                'key': '/library/parts/part-1/file.mkv',
                'Stream': [
                  {
                    'id': 1,
                    'streamType': 1,
                    'codec': 'hevc',
                    'DOVIProfile': 8,
                    'DOVIPresent': 1,
                    'DOVIBLCompatID': 1,
                    'colorTrc': 'smpte2084',
                    'colorPrimaries': 'bt2020',
                    'colorSpace': 'bt2020nc',
                  },
                  {'id': 2, 'streamType': 2, 'codec': 'eac3', 'channels': 6, 'selected': 1},
                ],
              },
            ],
          },
        ],
      }, serverId: ServerId('plex'));

      expect(buildMediaQualityLabels(item), ['4K', 'DV P8', 'EAC3 5.1']);
    });

    test('formats Jellyfin stream metadata from MediaSources', () {
      final item = JellyfinMappers.mediaItem(
        {
          'Id': 'movie-1',
          'Name': 'Movie',
          'Type': 'Movie',
          'MediaSources': [
            {
              'Id': 'source-1',
              'DefaultAudioStreamIndex': 2,
              'MediaStreams': [
                {
                  'Index': 0,
                  'Type': 'Video',
                  'Codec': 'hevc',
                  'Width': 3840,
                  'Height': 2160,
                  'VideoRangeType': 'DOVI',
                  'VideoDoViTitle': 'Dolby Vision Profile 8',
                  'DvProfile': 8,
                  'DvBlSignalCompatibilityId': 1,
                },
                {'Index': 1, 'Type': 'Audio', 'Codec': 'eac3', 'Channels': 6, 'IsDefault': true},
                {'Index': 2, 'Type': 'Audio', 'Codec': 'aac', 'Channels': 2},
              ],
            },
          ],
        },
        serverId: ServerId('jellyfin'),
        absolutizer: null,
      )!;

      expect(buildMediaQualityLabels(item), ['4K', 'DV P8', 'AAC Stereo']);
    });

    test('uses selected audio stream and stereo label', () {
      final item = _episodeWithVersion(
        MediaVersion(
          id: '1',
          width: 1280,
          height: 720,
          parts: const [
            MediaPart(
              id: 'part-1',
              streams: [
                MediaStream(id: 'video', kind: MediaStreamKind.video),
                MediaStream(id: 'audio-1', kind: MediaStreamKind.audio, codec: 'ac3', channels: 6),
                MediaStream(id: 'audio-2', kind: MediaStreamKind.audio, codec: 'aac', channels: 2, selected: true),
              ],
            ),
          ],
        ),
      );

      expect(buildMediaQualityLabels(item), ['720p', 'AAC Stereo']);
    });

    test('returns empty labels when no media versions exist', () {
      expect(buildMediaQualityLabels(_episodeWithVersion(null)), isEmpty);
    });
  });
  group('buildMediaSizeLabel', () {
    test('formats the complete size of a multi-part version', () {
      final item = _episodeWithVersion(
        const MediaVersion(
          id: '1',
          parts: [
            MediaPart(id: 'part-1', sizeBytes: 512 * 1024 * 1024),
            MediaPart(id: 'part-2', sizeBytes: 1024 * 1024 * 1024),
          ],
        ),
      );

      expect(buildMediaSizeLabel(item), '1.50 GB');
    });

    test('omits the size when any part is missing a valid size', () {
      for (final invalidSize in <int?>[null, 0, -1]) {
        final item = _episodeWithVersion(
          MediaVersion(
            id: '1',
            parts: [
              const MediaPart(id: 'known', sizeBytes: 1024),
              MediaPart(id: 'unknown', sizeBytes: invalidSize),
            ],
          ),
        );

        expect(buildMediaSizeLabel(item), isNull);
      }
    });

    test('uses the same requested version index as quality labels', () {
      final item = testMediaItem(
        id: 'episode-1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Episode',
        mediaVersions: const [
          MediaVersion(
            id: 'small',
            parts: [MediaPart(id: 'small-part', sizeBytes: 1024 * 1024 * 1024)],
          ),
          MediaVersion(
            id: 'large',
            parts: [MediaPart(id: 'large-part', sizeBytes: 2 * 1024 * 1024 * 1024)],
          ),
        ],
      );

      expect(buildMediaSizeLabel(item), '1.00 GB');
      expect(buildMediaSizeLabel(item, versionIndex: 1), '2.00 GB');
    });
  });
}

MediaItem _episodeWithVersion(MediaVersion? version) {
  return testMediaItem(
    id: 'episode-1',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: 'Episode',
    mediaVersions: version == null ? null : [version],
  );
}
