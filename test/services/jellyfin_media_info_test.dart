import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_media_info_mapper.dart';

/// Field-mapping pin for the Jellyfin → Plex `MediaInfo` translator. The
/// player's track picker and auto-track-selection both consume the
/// resulting [MediaAudioTrack] / [MediaSubtitleTrack] lists, so the field
/// shape needs to be stable across iterations.
void main() {
  group('jellyfinMediaSourceToMediaSourceInfo', () {
    test('maps audio + subtitle streams and preserves Jellyfin default selection hints', () {
      final source = {
        'Id': 'src-1',
        'Container': 'mkv',
        'MediaStreams': [
          {'Index': 0, 'Type': 'Video', 'Codec': 'h264', 'RealFrameRate': 23.976},
          {
            'Index': 1,
            'Type': 'Audio',
            'Codec': 'eac3',
            'Language': 'eng',
            'DisplayLanguage': 'English',
            'Title': 'Surround 5.1',
            'DisplayTitle': 'English (EAC3 5.1)',
            'Channels': 6,
            'IsDefault': true,
          },
          {
            'Index': 2,
            'Type': 'Audio',
            'Codec': 'aac',
            'Language': 'jpn',
            'DisplayLanguage': 'Japanese',
            'Channels': 2,
            'IsDefault': false,
          },
          {
            'Index': 3,
            'Type': 'Subtitle',
            'Codec': 'srt',
            'Language': 'eng',
            'DisplayLanguage': 'English',
            'IsDefault': false,
            'IsForced': true,
            'IsExternal': true,
            'DeliveryUrl': '/Videos/src-1/Subtitles/3/Stream.srt',
          },
        ],
      };

      final info = jellyfinMediaSourceToMediaSourceInfo(source);

      expect(info.audioTracks.length, 2);
      expect(info.subtitleTracks.length, 1);
      expect(info.frameRate, closeTo(23.976, 0.001));
      // Plex partId is null on Jellyfin because Jellyfin persists selected
      // stream indexes through playback progress reports instead.
      expect(info.getPartId(), isNull);

      // Jellyfin exposes the default server choice through IsDefault.
      final eng = info.audioTracks[0];
      expect(eng.id, 1);
      expect(eng.index, 1);
      expect(eng.codec, 'eac3');
      expect(eng.language, 'English');
      expect(eng.languageCode, 'eng');
      expect(eng.title, 'Surround 5.1');
      expect(eng.displayTitle, 'English (EAC3 5.1)');
      expect(eng.channels, 6);
      expect(eng.selected, isTrue);

      // Non-default audio
      final jpn = info.audioTracks[1];
      expect(jpn.id, 2);
      expect(jpn.languageCode, 'jpn');
      expect(jpn.selected, isFalse);

      // Subtitle, external + forced
      final sub = info.subtitleTracks.single;
      expect(sub.id, 3);
      expect(sub.codec, 'srt');
      expect(sub.languageCode, 'eng');
      expect(sub.forced, isTrue);
      expect(sub.selected, isTrue);
      expect(sub.isExternal, isTrue);
      expect(sub.key, '/Videos/src-1/Subtitles/3/Stream.srt');
    });

    test('handles missing MediaStreams gracefully', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({'Id': 'x'});
      expect(info.audioTracks, isEmpty);
      expect(info.subtitleTracks, isEmpty);
      expect(info.frameRate, isNull);
    });

    test('uses Jellyfin default stream indexes over per-stream default flags', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({
        'Id': 'src-1',
        'DefaultAudioStreamIndex': 2,
        'DefaultSubtitleStreamIndex': -1,
        'MediaStreams': [
          {'Index': 0, 'Type': 'Video'},
          {'Index': 1, 'Type': 'Audio', 'Language': 'eng', 'IsDefault': true},
          {'Index': 2, 'Type': 'Audio', 'Language': 'jpn', 'IsDefault': false},
          {'Index': 3, 'Type': 'Subtitle', 'Language': 'eng', 'IsDefault': true},
        ],
      });

      expect(info.audioTracks.map((t) => t.selected), [false, true]);
      expect(info.subtitleTracks.single.selected, isFalse);
      expect(info.defaultAudioStreamIndex, 2);
      expect(info.defaultSubtitleStreamIndex, -1);
    });

    test('selects subtitle matching Jellyfin default stream index', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({
        'Id': 'src-1',
        'DefaultSubtitleStreamIndex': 4,
        'MediaStreams': [
          {'Index': 3, 'Type': 'Subtitle', 'Language': 'eng', 'IsDefault': true},
          {'Index': 4, 'Type': 'Subtitle', 'Language': 'jpn', 'IsDefault': false},
        ],
      });

      expect(info.subtitleTracks.map((track) => track.selected), [false, true]);
      expect(info.defaultSubtitleStreamIndex, 4);
    });

    test('falls back to Language when DisplayLanguage absent', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({
        'MediaStreams': [
          {'Index': 0, 'Type': 'Audio', 'Language': 'fra'},
        ],
      });
      expect(info.audioTracks.single.language, 'fra');
      expect(info.audioTracks.single.languageCode, 'fra');
    });

    test('embedded subtitle (IsExternal=false) leaves key null', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({
        'MediaStreams': [
          {'Index': 0, 'Type': 'Subtitle', 'IsExternal': false, 'DeliveryUrl': '/should-be-ignored'},
        ],
      });
      expect(info.subtitleTracks.single.key, isNull);
      expect(info.subtitleTracks.single.isExternal, isFalse);
    });

    test('DeliveryMethod External marks negotiated subtitles as external', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({
        'MediaStreams': [
          {
            'Index': 2,
            'Type': 'Subtitle',
            'Codec': 'srt',
            'DeliveryMethod': 'External',
            'DeliveryUrl': '/Videos/item-1/src-1/Subtitles/2/Stream.srt',
          },
        ],
      });

      final sub = info.subtitleTracks.single;
      expect(sub.key, '/Videos/item-1/src-1/Subtitles/2/Stream.srt');
      expect(sub.isExternal, isTrue);
    });

    test('external subtitle without DeliveryUrl remains external for URL fallback', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({
        'MediaStreams': [
          {'Index': 3, 'Type': 'Subtitle', 'Codec': 'srt', 'IsExternal': true},
        ],
      });
      final sub = info.subtitleTracks.single;
      expect(sub.key, isNull);
      expect(sub.isExternal, isTrue);
    });

    test('captures mediaSourceId from source Id field', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({'Id': 'src-abc', 'MediaStreams': []});
      expect(info.mediaSourceId, 'src-abc');
    });

    test('parses flat trickplay manifest (per OpenAPI shape)', () {
      // BaseItemDto.Trickplay shape per Jellyfin OpenAPI: keys are resolution
      // widths (often strings in the JSON), values are TrickplayInfoDto.
      final info = jellyfinMediaSourceToMediaSourceInfo(
        {'Id': 'src-1', 'MediaStreams': []},
        trickplay: {
          '320': {
            'Width': 320,
            'Height': 180,
            'TileWidth': 10,
            'TileHeight': 10,
            'ThumbnailCount': 250,
            'Interval': 10000,
            'Bandwidth': 500000,
          },
        },
      );

      final t = info.trickplayByWidth?[320];
      expect(t, isNotNull);
      expect(t!.width, 320);
      expect(t.height, 180);
      expect(t.tileWidth, 10);
      expect(t.tileHeight, 10);
      expect(t.thumbnailCount, 250);
      expect(t.interval, 10000);
      expect(t.bandwidth, 500000);
    });

    test('parses nested-by-source trickplay manifest (Streamyfin shape)', () {
      // Some Jellyfin variants serialise Trickplay as
      // `{<sourceId>: {<resolution>: TrickplayInfoDto}}`. The mapper picks
      // the inner map matching the chosen source.
      final info = jellyfinMediaSourceToMediaSourceInfo(
        {'Id': 'src-2', 'MediaStreams': []},
        trickplay: {
          'src-1': {'160': _info(width: 160, height: 90, tw: 8, th: 8, count: 64, interval: 10000)},
          'src-2': {'320': _info(width: 320, height: 180, tw: 8, th: 8, count: 64, interval: 10000)},
        },
      );

      expect(info.trickplayByWidth?.keys.toList(), [320]);
      expect(info.trickplayByWidth![320]!.width, 320);
    });

    test('falls back to first nested entry when source id not present as key', () {
      final info = jellyfinMediaSourceToMediaSourceInfo(
        {'Id': 'unknown', 'MediaStreams': []},
        trickplay: {
          'src-1': {'160': _info(width: 160, height: 90, tw: 4, th: 4, count: 16, interval: 10000)},
        },
      );
      expect(info.trickplayByWidth?.keys.single, 160);
    });

    test('returns null trickplayByWidth when manifest missing', () {
      final info = jellyfinMediaSourceToMediaSourceInfo({'Id': 'x', 'MediaStreams': []});
      expect(info.trickplayByWidth, isNull);
    });

    test('skips malformed trickplay entries (missing required ints)', () {
      final info = jellyfinMediaSourceToMediaSourceInfo(
        {'Id': 'x', 'MediaStreams': []},
        trickplay: {
          '320': {
            // missing Height
            'Width': 320,
            'TileWidth': 10,
            'TileHeight': 10,
            'ThumbnailCount': 50,
            'Interval': 10000,
          },
          '160': _info(width: 160, height: 90, tw: 4, th: 4, count: 16, interval: 10000),
        },
      );
      expect(info.trickplayByWidth?.keys.toList(), [160]);
    });

    test('coerces numeric-string resolution keys', () {
      final info = jellyfinMediaSourceToMediaSourceInfo(
        {'Id': 'x', 'MediaStreams': []},
        trickplay: {'320': _info(width: 320, height: 180, tw: 4, th: 4, count: 16, interval: 10000)},
      );
      expect(info.trickplayByWidth?.containsKey(320), isTrue);
    });
  });

  group('jellyfinSourcesToVersions', () {
    test('reads resolution + codec from the video stream when source omits them', () {
      // The list endpoint returns Width/Height as null on MediaSource; the
      // detail endpoint may include them on the stream only. Either way the
      // version label needs a real number.
      final versions = jellyfinSourcesToVersions([
        {
          'Id': 'src-1',
          'Name': 'Movie (2024)',
          'Container': 'mkv',
          'Bitrate': 5000000,
          'MediaStreams': [
            {'Type': 'Video', 'Codec': 'hevc', 'Width': 3840, 'Height': 2160},
            {'Type': 'Audio', 'Codec': 'eac3'},
          ],
        },
      ]);
      expect(versions, hasLength(1));
      expect(versions.single.parts.single.streamPath, 'src-1');
      expect(versions.single.videoResolution, '4k');
      expect(versions.single.videoCodec, 'hevc');
      expect(versions.single.container, 'mkv');
      expect(versions.single.width, 3840);
      expect(versions.single.height, 2160);
      // Single-source items have Name == item title; suppress to avoid
      // redundant prefixes in the picker.
      expect(versions.single.name, isNull);
    });

    test('forwards distinct Names so the picker can disambiguate equal-spec versions', () {
      final versions = jellyfinSourcesToVersions([
        {
          'Id': 'src-theatrical',
          'Name': 'Theatrical Cut',
          'Container': 'mkv',
          'Bitrate': 8000000,
          'MediaStreams': [
            {'Type': 'Video', 'Codec': 'h264', 'Height': 1080, 'Width': 1920},
          ],
        },
        {
          'Id': 'src-directors',
          'Name': "Director's Cut",
          'Container': 'mkv',
          'Bitrate': 12000000,
          'MediaStreams': [
            {'Type': 'Video', 'Codec': 'h264', 'Height': 1080, 'Width': 1920},
          ],
        },
      ]);
      expect(versions, hasLength(2));
      expect(versions[0].name, 'Theatrical Cut');
      expect(versions[1].name, "Director's Cut");
      expect(versions[0].parts.single.streamPath, 'src-theatrical');
      expect(versions[1].parts.single.streamPath, 'src-directors');
      // displayLabel prefixes the name for disambiguation.
      expect(versions[0].displayLabel, contains('Theatrical Cut'));
      expect(versions[0].displayLabel, contains('1080'));
    });

    test('drops Name when all sources share it (typical single-version case)', () {
      final versions = jellyfinSourcesToVersions([
        {
          'Id': 'a',
          'Name': 'Movie (2024)',
          'Container': 'mkv',
          'MediaStreams': [
            {'Type': 'Video', 'Codec': 'h264', 'Height': 720, 'Width': 1280},
          ],
        },
        {
          'Id': 'b',
          'Name': 'Movie (2024)',
          'Container': 'mp4',
          'MediaStreams': [
            {'Type': 'Video', 'Codec': 'hevc', 'Height': 1080, 'Width': 1920},
          ],
        },
      ]);
      expect(versions[0].name, isNull);
      expect(versions[1].name, isNull);
      expect(versions[0].videoResolution, '720');
      expect(versions[1].videoResolution, '1080');
    });

    test('handles missing MediaStreams + missing Height gracefully', () {
      final versions = jellyfinSourcesToVersions([
        {'Id': 'x', 'Name': 'X', 'Container': 'mkv'},
      ]);
      expect(versions, hasLength(1));
      expect(versions.single.videoResolution, isNull);
      expect(versions.single.videoCodec, isNull);
      expect(versions.single.height, isNull);
    });
  });

  group('jellyfinPlaybackExtrasFromRaw', () {
    test('path-encodes chapter thumbnail item id and image tag', () {
      final extras = jellyfinPlaybackExtrasFromRaw({
        'Chapters': [
          {'StartPositionTicks': 0, 'ImageTag': 'chapter/tag ?x'},
        ],
      }, 'folder/item #1?x');

      expect(extras.chapters.single.thumb, '/Items/folder%2Fitem%20%231%3Fx/Images/Chapter/0?tag=chapter%2Ftag%20%3Fx');
    });

    test('uses default OP and ED chapter patterns for skip markers', () {
      final extras = jellyfinPlaybackExtrasFromRaw({
        'RunTimeTicks': _ticks(150000),
        'Chapters': [
          {'Name': 'Prologue', 'StartPositionTicks': _ticks(0)},
          {'Name': 'OP', 'StartPositionTicks': _ticks(10000)},
          {'Name': 'Part A', 'StartPositionTicks': _ticks(90000)},
          {'Name': 'ED', 'StartPositionTicks': _ticks(120000)},
        ],
      }, 'item-1');

      expect(extras.markers.map((m) => m.type), ['intro', 'credits']);
      expect(extras.markers[0].startTimeOffset, 10000);
      expect(extras.markers[0].endTimeOffset, 90000);
      expect(extras.markers[1].startTimeOffset, 120000);
      expect(extras.markers[1].endTimeOffset, 150000);
    });

    test('parses native Jellyfin media segments into skip markers', () {
      final markers = jellyfinMediaSegmentsToMarkers({
        'Items': [
          {'Type': 'Intro', 'StartTicks': _ticks(5000), 'EndTicks': _ticks(45000)},
          {'Type': 'Outro', 'StartTicks': _ticks(90000), 'EndTicks': _ticks(100000)},
          {'Type': 'Recap', 'StartTicks': _ticks(0), 'EndTicks': _ticks(4000)},
        ],
      });

      expect(markers.map((m) => m.type), ['intro', 'credits']);
      expect(markers[0].startTimeOffset, 5000);
      expect(markers[0].endTimeOffset, 45000);
      expect(markers[1].startTimeOffset, 90000);
      expect(markers[1].endTimeOffset, 100000);
    });

    test('keeps native segments and fills missing marker types from chapters', () {
      final extras = jellyfinPlaybackExtrasFromRaw(
        {
          'RunTimeTicks': _ticks(120000),
          'Chapters': [
            {'Name': 'Episode', 'StartPositionTicks': _ticks(0)},
            {'Name': 'ED', 'StartPositionTicks': _ticks(90000)},
          ],
        },
        'item-1',
        markers: jellyfinMediaSegmentsToMarkers({
          'Items': [
            {'Type': 'Intro', 'StartTicks': _ticks(10000), 'EndTicks': _ticks(30000)},
          ],
        }),
      );

      expect(extras.markers.map((m) => m.type), ['intro', 'credits']);
      expect(extras.markers[0].startTimeOffset, 10000);
      expect(extras.markers[0].endTimeOffset, 30000);
      expect(extras.markers[1].startTimeOffset, 90000);
      expect(extras.markers[1].endTimeOffset, 120000);
    });
  });
}

int _ticks(int ms) => ms * 10000;

/// Build a Jellyfin TrickplayInfoDto-shaped JSON map for a fixture.
Map<String, dynamic> _info({
  required int width,
  required int height,
  required int tw,
  required int th,
  required int count,
  required int interval,
}) => {
  'Width': width,
  'Height': height,
  'TileWidth': tw,
  'TileHeight': th,
  'ThumbnailCount': count,
  'Interval': interval,
  'Bandwidth': 0,
};
