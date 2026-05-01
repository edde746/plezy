import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/services/plex_mappers.dart';

Map<String, dynamic> _media({
  int id = 1,
  String videoCodec = 'h264',
  String container = 'mkv',
  Map<String, Object?> partExtras = const {},
}) {
  return {
    'id': id,
    'videoResolution': '1080',
    'videoCodec': videoCodec,
    'container': container,
    'bitrate': 5000,
    'Part': [
      {'id': 100 + id, 'key': '/library/parts/$id/file.mkv', ...partExtras},
    ],
  };
}

void main() {
  group('Plex media version accessibility parsing', () {
    test('accessible/exists are null when Plex did not include them', () {
      final v = PlexMappers.mediaVersionFromJson(_media());
      expect(v.parts.single.accessible, isNull);
      expect(v.parts.single.exists, isNull);
      expect(
        v.isPlayable,
        isTrue,
        reason: 'absent fields must default to playable so older PMS / no-checkFiles servers still work',
      );
    });

    test('parses int 0/1 from Plex JSON output', () {
      final notExists = PlexMappers.mediaVersionFromJson(_media(partExtras: {'exists': 0, 'accessible': 1}));
      expect(notExists.parts.single.exists, isFalse);
      expect(notExists.parts.single.accessible, isTrue);
      expect(notExists.isPlayable, isFalse);

      final notAccessible = PlexMappers.mediaVersionFromJson(_media(partExtras: {'exists': 1, 'accessible': 0}));
      expect(notAccessible.parts.single.exists, isTrue);
      expect(notAccessible.parts.single.accessible, isFalse);
      expect(notAccessible.isPlayable, isFalse);

      final ok = PlexMappers.mediaVersionFromJson(_media(partExtras: {'exists': 1, 'accessible': 1}));
      expect(ok.isPlayable, isTrue);
    });

    test('parses native bool', () {
      final v = PlexMappers.mediaVersionFromJson(_media(partExtras: {'exists': false, 'accessible': true}));
      expect(v.parts.single.exists, isFalse);
      expect(v.parts.single.accessible, isTrue);
      expect(v.isPlayable, isFalse);
    });

    test('parses string "0"/"1" forms (XML-to-JSON conversion)', () {
      final v = PlexMappers.mediaVersionFromJson(_media(partExtras: {'exists': '0', 'accessible': '1'}));
      expect(v.parts.single.exists, isFalse);
      expect(v.parts.single.accessible, isTrue);
    });

    test('isPlayable truth table mirrors Plex web semantics', () {
      // Mirrors plex-web.js:28926: !1 !== e.exists && !1 !== e.accessible
      // Anything but explicit `false` for both fields → playable.
      bool playable({bool? acc, bool? ex}) {
        return MediaVersion(
          id: '1',
          parts: [MediaPart(id: '1', streamPath: '/k', accessible: acc, exists: ex)],
        ).isPlayable;
      }

      expect(playable(acc: null, ex: null), isTrue);
      expect(playable(acc: true, ex: true), isTrue);
      expect(playable(acc: true, ex: null), isTrue);
      expect(playable(acc: null, ex: true), isTrue);

      expect(playable(acc: false, ex: true), isFalse);
      expect(playable(acc: true, ex: false), isFalse);
      expect(playable(acc: false, ex: false), isFalse);
      expect(playable(acc: false, ex: null), isFalse);
      expect(playable(acc: null, ex: false), isFalse);
    });

    test('handles single-Part-as-object (Plex sometimes returns a Map instead of List)', () {
      final json = {
        'id': 1,
        'videoResolution': '1080',
        'videoCodec': 'h264',
        'container': 'mkv',
        'Part': {'id': 101, 'key': '/library/parts/1/file.mkv', 'exists': 0},
      };
      final v = PlexMappers.mediaVersionFromJson(json);
      expect(v.parts.single.exists, isFalse);
      expect(v.isPlayable, isFalse);
    });

    test('missing Part array leaves accessibility fields null', () {
      final json = {'id': 1, 'videoResolution': '1080', 'videoCodec': 'h264', 'container': 'mkv'};
      final v = PlexMappers.mediaVersionFromJson(json);
      expect(v.parts.single.accessible, isNull);
      expect(v.parts.single.exists, isNull);
      expect(v.isPlayable, isTrue);
    });
  });

  group('MediaVersion displayLabel', () {
    test('formats Plex videoResolution for display', () {
      String displayLabel(String resolution) =>
          MediaVersion(id: '1', videoResolution: resolution, videoCodec: 'h264').displayLabel;

      expect(displayLabel('1080'), startsWith('1080p '));
      for (final resolution in ['4k', '4K']) {
        expect(displayLabel(resolution), startsWith('4K '));
      }
      for (final resolution in ['8k', '8K']) {
        expect(displayLabel(resolution), startsWith('8K '));
      }
      expect(displayLabel('sd'), startsWith('SD '));
    });
  });
}
