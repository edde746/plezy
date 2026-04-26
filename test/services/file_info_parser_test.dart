import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/file_info_parser.dart';

/// Unit tests for the backend-agnostic stream walker. Each backend is
/// represented by its own [FileInfoStreamReader] implementation, so the
/// tests fix two things:
///   1. The walker's accounting (single video pointer, every audio + sub
///      tracked, frame rate captured once).
///   2. Each reader's mapping from raw JSON to the neutral track classes.
void main() {
  group('walkStreams (Plex reader)', () {
    const reader = PlexFileInfoStreamReader();

    test('captures the first video stream and accumulates audio + subs', () {
      final streams = [
        // streamType 1=video, 2=audio, 3=subtitle
        {'streamType': 1, 'id': 100, 'frameRate': 23.976, 'colorSpace': 'bt709'},
        {
          'streamType': 2,
          'id': 101,
          'index': 1,
          'codec': 'eac3',
          'language': 'English',
          'channels': 6,
          'selected': true,
          'displayTitle': 'English (EAC3 5.1)',
        },
        {
          'streamType': 2,
          'id': 102,
          'index': 2,
          'codec': 'aac',
          'language': 'French',
          'channels': 2,
          'selected': false,
        },
        {
          'streamType': 3,
          'id': 200,
          'index': 3,
          'codec': 'srt',
          'language': 'English',
          'forced': false,
          'selected': false,
          'key': '/library/streams/200',
        },
      ];

      final out = walkStreams(streams, reader);

      expect(out.videoStream?['id'], 100);
      expect(out.audioStream?['id'], 101);
      expect(out.frameRate, closeTo(23.976, 1e-6));
      expect(out.audioTracks.map((t) => t.id), [101, 102]);
      expect(out.audioTracks[0].channels, 6);
      expect(out.audioTracks[0].selected, isTrue);
      expect(out.audioTracks[1].selected, isFalse);
      expect(out.subtitleTracks, hasLength(1));
      expect(out.subtitleTracks.first.key, '/library/streams/200');
    });

    test('null and empty inputs short-circuit to FileInfoStreams.empty', () {
      expect(identical(walkStreams(null, reader), FileInfoStreams.empty), isTrue);
      expect(identical(walkStreams(const [], reader), FileInfoStreams.empty), isTrue);
    });

    test('skips entries with unknown streamType', () {
      final streams = [
        {'streamType': 99, 'id': 1}, // unknown
        {'streamType': 'audio', 'id': 2}, // wrong type
        {'streamType': 1, 'id': 3, 'frameRate': 24},
      ];
      final out = walkStreams(streams, reader);
      expect(out.audioTracks, isEmpty);
      expect(out.subtitleTracks, isEmpty);
      expect(out.videoStream?['id'], 3);
      expect(out.frameRate, 24.0);
    });

    test('skips non-Map entries gracefully', () {
      final streams = ['not a map', 42, null];
      final out = walkStreams(streams, reader);
      expect(out.videoStream, isNull);
      expect(out.audioStream, isNull);
      expect(out.audioTracks, isEmpty);
      expect(out.subtitleTracks, isEmpty);
      expect(out.frameRate, isNull);
    });
  });

  group('walkStreams (Jellyfin reader)', () {
    const reader = JellyfinFileInfoStreamReader();

    test('captures the first video stream and accumulates audio + subs', () {
      final streams = [
        {'Type': 'Video', 'Index': 0, 'RealFrameRate': 23.976, 'ColorSpace': 'bt709'},
        {
          'Type': 'Audio',
          'Index': 1,
          'Codec': 'eac3',
          'Language': 'eng',
          'Channels': 6,
          'IsDefault': true,
          'DisplayTitle': 'English (EAC3 5.1)',
        },
        {'Type': 'Audio', 'Index': 2, 'Codec': 'aac', 'Language': 'fre', 'Channels': 2, 'IsDefault': false},
        {'Type': 'Subtitle', 'Index': 3, 'Codec': 'srt', 'Language': 'eng', 'IsDefault': false, 'IsForced': false},
      ];

      final out = walkStreams(streams, reader);

      expect(out.videoStream?['Index'], 0);
      expect(out.audioStream?['Index'], 1);
      expect(out.frameRate, closeTo(23.976, 1e-6));
      expect(out.audioTracks.map((t) => t.id), [1, 2]);
      expect(out.audioTracks[0].selected, isTrue);
      expect(out.audioTracks[0].languageCode, 'eng');
      expect(out.subtitleTracks, hasLength(1));
      expect(out.subtitleTracks.first.id, 3);
    });

    test('falls back to autoIndex when Index is null', () {
      final streams = [
        {'Type': 'Audio', 'Codec': 'aac'}, // no Index
        {'Type': 'Audio', 'Index': 7, 'Codec': 'eac3'},
        {'Type': 'Audio', 'Codec': 'opus'}, // no Index
      ];
      final out = walkStreams(streams, reader);
      // autoIndex is 1-based and increments per audio entry: 1, 2 (overridden by 7), 3.
      expect(out.audioTracks.map((t) => t.id), [1, 7, 3]);
    });

    test('frameRateOf falls back to AverageFrameRate when RealFrameRate is null', () {
      final streams = [
        {'Type': 'Video', 'AverageFrameRate': 25.0},
      ];
      final out = walkStreams(streams, reader);
      expect(out.frameRate, 25.0);
    });

    test('skips streams with unknown Type', () {
      final streams = [
        {'Type': 'EmbeddedImage', 'Index': 0}, // unsupported
        {'Type': 'audio', 'Codec': 'aac'}, // case-insensitive
      ];
      final out = walkStreams(streams, reader);
      expect(out.videoStream, isNull);
      expect(out.audioTracks, hasLength(1));
    });
  });

  group('cross-backend equivalence', () {
    test('both readers produce parallel track structures from analogous JSON', () {
      const plexReader = PlexFileInfoStreamReader();
      const jfReader = JellyfinFileInfoStreamReader();

      final plexStreams = [
        {'streamType': 1, 'id': 1, 'frameRate': 24.0},
        {'streamType': 2, 'id': 2, 'codec': 'aac', 'language': 'English', 'channels': 2, 'selected': true},
        {'streamType': 3, 'id': 3, 'codec': 'srt', 'language': 'English', 'selected': false, 'forced': false},
      ];
      final jfStreams = [
        {'Type': 'Video', 'Index': 0, 'RealFrameRate': 24.0},
        {'Type': 'Audio', 'Index': 1, 'Codec': 'aac', 'Language': 'eng', 'Channels': 2, 'IsDefault': true},
        {'Type': 'Subtitle', 'Index': 2, 'Codec': 'srt', 'Language': 'eng', 'IsDefault': false, 'IsForced': false},
      ];

      final plex = walkStreams(plexStreams, plexReader);
      final jf = walkStreams(jfStreams, jfReader);

      expect(plex.audioTracks, hasLength(1));
      expect(jf.audioTracks, hasLength(1));
      expect(plex.subtitleTracks, hasLength(1));
      expect(jf.subtitleTracks, hasLength(1));
      expect(plex.frameRate, jf.frameRate);
      expect(plex.audioTracks.first.codec, jf.audioTracks.first.codec);
      expect(plex.audioTracks.first.channels, jf.audioTracks.first.channels);
      expect(plex.audioTracks.first.selected, jf.audioTracks.first.selected);
    });
  });
}
