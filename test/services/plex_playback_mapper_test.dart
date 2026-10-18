import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_file_info.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/services/plex_playback_mapper.dart';
import 'package:plezy/services/plex_mappers.dart';

void main() {
  group('parsePlexVideoPlaybackDataFromJson', () {
    test('cache prediction resolves the same id, signature, playable version and part as playback', () {
      Map<String, dynamic> part(int id, String language, {bool accessible = true}) => {
        'id': id,
        'key': '/library/parts/$id/file.mkv',
        'accessible': accessible,
        'Stream': [
          {'id': id * 10, 'streamType': 2, 'languageCode': language, 'selected': true},
        ],
      };
      final first = {
        'id': 1,
        'videoResolution': '1080',
        'videoCodec': 'h264',
        'container': 'mkv',
        'Part': [part(10, 'eng')],
      };
      final alternate = {
        'id': 2,
        'videoResolution': '4k',
        'videoCodec': 'hevc',
        'container': 'mkv',
        'Part': [part(20, 'fre', accessible: false), part(21, 'jpn')],
      };
      void expectSelection(
        List<Map<String, dynamic>> media, {
        String? id,
        String? signature,
        required String language,
        required int index,
      }) {
        final raw = <String, dynamic>{'Media': media};
        final cached = plexMediaSourceInfoFromCacheJson(raw, mediaSourceId: id, preferredVersionSignature: signature)!;
        final playback = parsePlexVideoPlaybackDataFromJson(
          raw,
          baseUrl: 'http://plex',
          token: null,
          selectedMediaSourceId: id,
          preferredVersionSignature: signature,
        );
        expect(cached.audioTracks.single.languageCode, language);
        expect(playback.mediaInfo!.audioTracks.single.languageCode, language);
        expect(cached.mediaIndex, index);
        expect(cached.partId, playback.mediaInfo!.partId);
        expect(cached.partIndex, playback.selectedPartIndex);
        expect(cached.mediaSourceId, playback.mediaInfo!.mediaSourceId);
      }

      expectSelection([first, alternate], id: '2', signature: '1080:h264:mkv', language: 'jpn', index: 1);
      expectSelection([alternate, first], id: '2', language: 'jpn', index: 0);
      expectSelection([first, alternate], id: 'sibling-source', signature: '4k:hevc:mkv', language: 'jpn', index: 1);
      final unavailable = {
        ...alternate,
        'Part': [part(20, 'jpn', accessible: false)],
      };
      expectSelection([first, unavailable], id: '2', language: 'eng', index: 0);
      expectSelection([unavailable, first], language: 'eng', index: 1);
      expectSelection([first], id: '2', signature: '4k:hevc:mkv', language: 'eng', index: 0);
      // Offline source metadata stays pinned even when the server says the
      // downloaded version is no longer remotely accessible.
      final raw = <String, dynamic>{
        'Media': [first, unavailable],
      };
      final downloaded = resolvePlexPlaybackSelection(raw, mediaIndex: 1, preferPlayable: false)!;
      expect(plexMediaSourceInfoForSelection(raw, downloaded)!.audioTracks.single.languageCode, 'jpn');
    });

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
      expect(result.mediaInfo?.mediaSourceId, '102');
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
      expect(result.mediaInfo?.mediaSourceId, '202');
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
      expect(result.mediaInfo?.mediaSourceId, '302');
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

      final version = info!.versions.single;
      final part = version.parts.single;
      expect(version.container, 'mkv');
      expect(version.videoCodec, 'h264');
      expect(part.filePath, '/media/movie.mkv');
      expect(part.fileSize, 123456);
      expect(version.optimizedForStreaming, isTrue);
      expect(version.has64bitOffsets, isFalse);

      final video = part.streamsOfKind(MediaStreamKind.video).single;
      expect(video.frameRate, 24);
      expect(video.bitDepth, 8);
      expect(video.colorSpace, 'bt709');

      final audio = part.streamsOfKind(MediaStreamKind.audio).single;
      expect(audio.id, '301');
      expect(audio.isSelected, isTrue);
      expect(audio.channelLayout, 'stereo');

      expect(part.streamsOfKind(MediaStreamKind.subtitle).single.id, '401');
    });

    test('keeps subtitle streams that the playback reader would reject', () {
      // The playback path needs a numeric stream id and drops the rest; the
      // file-info view is purely descriptive, so embedded caption tracks with
      // no usable id still belong in the table.
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
      final part = info!.versions.single.parts.single;
      expect(part.filePath, '/media/movie.mp4');
      final subtitles = part.streamsOfKind(MediaStreamKind.subtitle).toList();
      expect(subtitles.map((stream) => stream.id), [null, 'cea-608', '402']);
      expect(subtitles.map((stream) => stream.ordinal), [1, 2, 3]);
    });
  });

  group('stacked parts', () {
    // `Movie - Part 1/2/3`: 50, 40 and 30 minutes, each with its own
    // external subtitle stream.
    Map<String, dynamic> stacked({bool secondExists = true, bool thirdHasDuration = true}) => {
      'duration': 7200000,
      'Media': [
        {
          'id': 1,
          'duration': 7200000,
          'Part': [
            for (final (index, durationMs) in [(1, 3000000), (2, 2400000), (3, 1800000)])
              {
                'id': 10 + index,
                'key': '/library/parts/${10 + index}/file.mkv',
                if (index != 3 || thirdHasDuration) 'duration': durationMs,
                'exists': index == 2 && !secondExists ? 0 : 1,
                'Stream': [
                  {'streamType': 1, 'id': 100 + index},
                  {
                    'streamType': 3,
                    'id': 300 + index,
                    'key': '/library/streams/${300 + index}',
                    'codec': 'srt',
                    'languageCode': 'eng',
                  },
                ],
              },
          ],
        },
      ],
    };

    _OpenedPart open(Map<String, dynamic> raw, {Duration? position}) {
      final data = parsePlexVideoPlaybackDataFromJson(raw, baseUrl: 'http://plex', token: null, position: position);
      return (url: data.videoUrl, partIndex: data.selectedPartIndex, info: data.mediaInfo!);
    }

    test('opens the file holding the start position, placed on the item timeline', () {
      final first = open(stacked());
      expect(first.url, 'http://plex/library/parts/11/file.mkv');
      final timeline = first.info.partTimeline!;
      expect(timeline.currentIndex, 0);
      expect(timeline.duration, const Duration(minutes: 120));
      expect(timeline.parts.map((part) => part.start), const [
        Duration.zero,
        Duration(minutes: 50),
        Duration(minutes: 90),
      ]);

      // A boundary belongs to the file that starts there, and that file's own
      // streams describe the source.
      final second = open(stacked(), position: const Duration(minutes: 50));
      expect(second.url, 'http://plex/library/parts/12/file.mkv');
      expect(second.partIndex, 1);
      expect(second.info.partId, 12);
      expect(second.info.partTimeline!.current.start, const Duration(minutes: 50));
      expect(second.info.subtitleTracks.single.id, 302);

      expect(open(stacked(), position: const Duration(minutes: 89, seconds: 59)).partIndex, 1);
      // Past the end is still the last file.
      expect(open(stacked(), position: const Duration(hours: 3)).partIndex, 2);
    });

    test('a file that is gone plays on from the next one that is there', () {
      final opened = open(stacked(secondExists: false), position: const Duration(minutes: 60));
      expect(opened.url, 'http://plex/library/parts/13/file.mkv');
      expect(opened.info.partTimeline!.currentIndex, 2);

      // A downloaded copy is on disk whatever the server says.
      final cached = resolvePlexPlaybackSelection(
        stacked(secondExists: false),
        preferPlayable: false,
        position: const Duration(minutes: 60),
      )!;
      expect(cached.partIndex, 1);
    });

    test('a part without a duration leaves the version unstacked', () {
      final opened = open(stacked(thirdHasDuration: false), position: const Duration(minutes: 60));
      expect(opened.url, 'http://plex/library/parts/11/file.mkv');
      expect(opened.info.partTimeline, isNull);
    });
  });
}

typedef _OpenedPart = ({String? url, int partIndex, MediaSourceInfo info});
