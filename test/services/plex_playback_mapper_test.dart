import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_playback_mapper.dart';

void main() {
  group('parsePlexVideoPlaybackDataFromJson', () {
    test('falls back from inaccessible selected version to playable version', () {
      late (int, int) fallback;

      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 1,
              'videoResolution': '2160',
              'Part': [
                {'id': 10, 'key': '/library/parts/10/file.mkv', 'accessible': 0, 'exists': 1},
              ],
            },
            {
              'id': 2,
              'videoResolution': '1080',
              'Part': [
                {
                  'id': 20,
                  'key': '/library/parts/20/file.mkv',
                  'accessible': 1,
                  'exists': 1,
                  'Stream': [
                    {'streamType': 1, 'frameRate': 23.976},
                    {'streamType': 2, 'id': 201, 'index': 0, 'languageCode': 'eng', 'selected': 1},
                  ],
                },
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: 'tok',
        onVersionFallback: (requested, selected) => fallback = (requested, selected),
      );

      expect(fallback, (0, 1));
      expect(result.videoUrl, 'http://plex:32400/library/parts/20/file.mkv?X-Plex-Token=tok');
      expect(result.availableVersions, hasLength(2));
      expect(result.availableVersions.first.isPlayable, isFalse);
      expect(result.mediaInfo?.partId, 20);
      expect(result.mediaInfo?.frameRate, 23.976);
      expect(result.mediaInfo?.audioTracks.single.languageCode, 'eng');
    });
  });

  group('parsePlexFileInfoFromJson', () {
    test('maps media, part, and stream fields', () {
      final info = parsePlexFileInfoFromJson({
        'Media': [
          {
            'container': 'mkv',
            'videoCodec': 'h264',
            'videoResolution': '1080',
            'width': 1920,
            'height': 1080,
            'aspectRatio': 1.78,
            'bitrate': 8000,
            'duration': 120000,
            'audioCodec': 'aac',
            'audioChannels': 2,
            'optimizedForStreaming': '1',
            'has64bitOffsets': 0,
            'Part': [
              {
                'file': '/media/movie.mkv',
                'size': 123456,
                'Stream': [
                  {'streamType': 1, 'frameRate': 24, 'colorSpace': 'bt709', 'bitDepth': 8, 'bitrate': 7000},
                  {
                    'streamType': 2,
                    'id': 301,
                    'index': 0,
                    'language': 'English',
                    'languageCode': 'eng',
                    'channels': 2,
                    'selected': true,
                    'audioChannelLayout': 'stereo',
                  },
                  {'streamType': 3, 'id': 401, 'index': 0, 'languageCode': 'eng', 'forced': 0, 'key': '/subtitles/401'},
                ],
              },
            ],
          },
        ],
      });

      expect(info?.container, 'mkv');
      expect(info?.videoCodec, 'h264');
      expect(info?.filePath, '/media/movie.mkv');
      expect(info?.fileSize, 123456);
      expect(info?.optimizedForStreaming, isTrue);
      expect(info?.has64bitOffsets, isFalse);
      expect(info?.frameRate, 24);
      expect(info?.bitDepth, 8);
      expect(info?.audioTracks.single.id, 301);
      expect(info?.audioTracks.single.selected, isTrue);
      expect(info?.subtitleTracks.single.key, '/subtitles/401');
    });
  });
}
