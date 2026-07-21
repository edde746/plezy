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
      expect(result.mediaInfo?.displayCriteria?.fps, 23.976);
      expect(result.mediaInfo?.audioTracks.single.languageCode, 'eng');
      expect(result.selectedMediaIndex, 1);
      expect(result.selectedPartIndex, 0);
    });

    test('falls back when first Plex media has unavailable part flags', () {
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 9773,
              'videoResolution': '1080',
              'Part': [
                {'id': 9815, 'key': '/library/parts/9815/1774877382/file.mp4', 'accessible': false, 'exists': false},
              ],
            },
            {
              'id': 9766,
              'videoResolution': '720',
              'Part': [
                {'id': 9808, 'key': '/library/parts/9808/1775431760/file.mp4', 'accessible': true, 'exists': true},
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: 'tok',
      );

      expect(result.videoUrl, 'http://plex:32400/library/parts/9808/1775431760/file.mp4?X-Plex-Token=tok');
      expect(result.selectedMediaIndex, 1);
      expect(result.selectedPartIndex, 0);
      expect(result.availableVersions.first.isPlayable, isFalse);
      expect(result.availableVersions.last.isPlayable, isTrue);
    });

    test('uses playable part when the first part is unavailable', () {
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 1,
              'videoResolution': '1080',
              'Part': [
                {'id': 10, 'key': '/library/parts/10/file.mkv', 'accessible': 0, 'exists': 1},
                {
                  'id': 20,
                  'key': '/library/parts/20/file.mkv',
                  'accessible': 1,
                  'exists': 1,
                  'Stream': [
                    {'streamType': 1, 'frameRate': 24},
                    {'streamType': 2, 'id': 201, 'index': 0, 'languageCode': 'eng', 'selected': 1},
                  ],
                },
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: 'tok',
      );

      expect(result.videoUrl, 'http://plex:32400/library/parts/20/file.mkv?X-Plex-Token=tok');
      expect(result.selectedMediaIndex, 0);
      expect(result.selectedPartIndex, 1);
      expect(result.mediaInfo?.partId, 20);
      expect(result.mediaInfo?.displayCriteria?.fps, 24);
      expect(result.availableVersions.single.parts, hasLength(2));
      expect(result.availableVersions.single.parts.first.isPlayable, isFalse);
      expect(result.availableVersions.single.parts.last.isPlayable, isTrue);
    });

    test('selects version by media source id over the requested index', () {
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 101,
              'videoResolution': '1080',
              'videoCodec': 'h264',
              'container': 'mkv',
              'Part': [
                {'id': 10, 'key': '/library/parts/10/file.mkv', 'accessible': 1, 'exists': 1},
              ],
            },
            {
              'id': 102,
              'videoResolution': '4k',
              'videoCodec': 'hevc',
              'container': 'mkv',
              'Part': [
                {'id': 20, 'key': '/library/parts/20/file.mkv', 'accessible': 1, 'exists': 1},
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: 'tok',
        mediaIndex: 0,
        selectedMediaSourceId: '102',
      );

      expect(result.selectedMediaIndex, 1);
      expect(result.videoUrl, 'http://plex:32400/library/parts/20/file.mkv?X-Plex-Token=tok');
    });

    test('selects version by preferred signature when the id misses', () {
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 201,
              'videoResolution': '1080',
              'videoCodec': 'h264',
              'container': 'mkv',
              'Part': [
                {'id': 10, 'key': '/library/parts/10/file.mkv', 'accessible': 1, 'exists': 1},
              ],
            },
            {
              'id': 202,
              'videoResolution': '4k',
              'videoCodec': 'hevc',
              'container': 'mkv',
              'Part': [
                {'id': 20, 'key': '/library/parts/20/file.mkv', 'accessible': 1, 'exists': 1},
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: 'tok',
        mediaIndex: 0,
        // Sibling episode's id — meaningless here; the signature must decide.
        selectedMediaSourceId: '999',
        preferredVersionSignature: '4k:hevc:mkv',
      );

      expect(result.selectedMediaIndex, 1);
    });

    test('keeps the requested index when id and signature both miss', () {
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 301,
              'videoResolution': '1080',
              'Part': [
                {'id': 10, 'key': '/library/parts/10/file.mkv', 'accessible': 1, 'exists': 1},
              ],
            },
            {
              'id': 302,
              'videoResolution': '720',
              'Part': [
                {'id': 20, 'key': '/library/parts/20/file.mkv', 'accessible': 1, 'exists': 1},
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: 'tok',
        mediaIndex: 1,
        preferredVersionSignature: '4k:av1:mp4',
      );

      expect(result.selectedMediaIndex, 1);
    });

    test('signature-resolved version still falls back when unplayable', () {
      late (int, int) fallback;
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 401,
              'videoResolution': '1080',
              'videoCodec': 'h264',
              'container': 'mkv',
              'Part': [
                {'id': 10, 'key': '/library/parts/10/file.mkv', 'accessible': 1, 'exists': 1},
              ],
            },
            {
              'id': 402,
              'videoResolution': '4k',
              'videoCodec': 'hevc',
              'container': 'mkv',
              'Part': [
                {'id': 20, 'key': '/library/parts/20/file.mkv', 'accessible': 0, 'exists': 0},
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: 'tok',
        mediaIndex: 0,
        preferredVersionSignature: '4k:hevc:mkv',
        onVersionFallback: (requested, selected) => fallback = (requested, selected),
      );

      expect(fallback, (1, 0));
      expect(result.selectedMediaIndex, 0);
    });

    test('maps server display criteria from selected video stream', () {
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 1,
              'width': 3840,
              'height': 2160,
              'videoResolution': '4k',
              'Part': [
                {
                  'id': 10,
                  'key': '/library/parts/10/file.mkv',
                  'accessible': 1,
                  'exists': 1,
                  'Stream': [
                    {
                      'streamType': 1,
                      'frameRate': '23.976',
                      'DOVIProfile': '7',
                      'DOVILevel': '6',
                      'DOVIBLCompatID': '6',
                      'colorTrc': 'smpte2084',
                      'colorPrimaries': 'bt2020',
                      'colorSpace': 'bt2020nc',
                    },
                  ],
                },
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: null,
      );

      final criteria = result.mediaInfo?.displayCriteria;
      expect(criteria, isNotNull);
      expect(criteria!.fps, closeTo(23.976, 0.001));
      expect(criteria.width, 3840);
      expect(criteria.height, 2160);
      expect(criteria.doviProfile, 7);
      expect(criteria.doviLevel, 6);
      expect(criteria.doviCompatibilityId, 6);
      expect(criteria.transfer, 'smpte2084');
      expect(criteria.primaries, 'bt2020');
      expect(criteria.matrix, 'bt2020nc');
    });

    test('fills missing HDR color tags from partial Plex transfer metadata', () {
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 1,
              'width': 3840,
              'height': 2160,
              'Part': [
                {
                  'id': 10,
                  'key': '/library/parts/10/file.mkv',
                  'accessible': 1,
                  'exists': 1,
                  'Stream': [
                    {'streamType': 1, 'frameRate': 23.976, 'colorTrc': 'smpte2084'},
                  ],
                },
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: null,
      );

      final criteria = result.mediaInfo?.displayCriteria;
      expect(criteria, isNotNull);
      expect(criteria!.transfer, 'smpte2084');
      expect(criteria.primaries, 'bt2020');
      expect(criteria.matrix, 'bt2020nc');
    });

    test('skips unidentifiable subtitle streams without blocking playback', () {
      final result = parsePlexVideoPlaybackDataFromJson(
        {
          'Media': [
            {
              'id': 1,
              'Part': [
                {
                  'id': 10,
                  'key': '/library/parts/10/file.mp4',
                  'accessible': 1,
                  'exists': 1,
                  'Stream': [
                    {'streamType': 1, 'id': 100},
                    {'streamType': 2, 'id': 301, 'selected': true},
                    {'streamType': 3, 'languageCode': 'eng'},
                    {'streamType': 3, 'id': 'cc1', 'languageCode': 'eng'},
                    {'streamType': 3, 'id': '401', 'languageCode': 'spa', 'selected': true},
                  ],
                },
              ],
            },
          ],
        },
        baseUrl: 'http://plex:32400',
        token: 'token',
      );

      expect(result.videoUrl, 'http://plex:32400/library/parts/10/file.mp4?X-Plex-Token=token');
      expect(result.mediaInfo, isNotNull);
      expect(result.mediaInfo!.audioTracks.map((track) => track.id), [301]);
      expect(result.mediaInfo!.subtitleTracks.map((track) => track.id), [401]);
      expect(result.mediaInfo!.subtitleTracks.single.selected, isTrue);
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
            'width': '1920',
            'height': '1080',
            'aspectRatio': '1.78',
            'bitrate': '8000',
            'duration': '120000',
            'audioCodec': 'aac',
            'audioChannels': '2',
            'optimizedForStreaming': '1',
            'has64bitOffsets': 0,
            'Part': [
              {
                'file': '/media/movie.mkv',
                'size': '123456',
                'Stream': [
                  {'streamType': '1', 'frameRate': '24', 'colorSpace': 'bt709', 'bitDepth': '8', 'bitrate': '7000'},
                  {
                    'streamType': '2',
                    'id': '301',
                    'index': '0',
                    'language': 'English',
                    'languageCode': 'eng',
                    'channels': '2',
                    'selected': true,
                    'audioChannelLayout': 'stereo',
                  },
                  {
                    'streamType': '3',
                    'id': '401',
                    'index': '0',
                    'languageCode': 'eng',
                    'forced': 0,
                    'key': '/subtitles/401',
                  },
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

    test('skips unidentifiable subtitle streams in file info', () {
      final info = parsePlexFileInfoFromJson({
        'Media': [
          {
            'container': 'mp4',
            'Part': [
              {
                'file': '/media/movie.mp4',
                'Stream': [
                  {'streamType': 1, 'id': 100},
                  {'streamType': 3, 'id': null, 'languageCode': 'eng'},
                  {'streamType': 3, 'id': 'cea-608', 'languageCode': 'eng'},
                  {'streamType': 3, 'id': 402, 'languageCode': 'spa'},
                ],
              },
            ],
          },
        ],
      });

      expect(info, isNotNull);
      expect(info!.filePath, '/media/movie.mp4');
      expect(info.subtitleTracks.map((track) => track.id), [402]);
    });
  });
}
