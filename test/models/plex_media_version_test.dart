import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_media_version.dart';

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
  group('PlexMediaVersion accessibility parsing', () {
    test('accessible/exists are null when Plex did not include them', () {
      final v = PlexMediaVersion.fromJson(_media());
      expect(v.accessible, isNull);
      expect(v.exists, isNull);
      expect(
        v.isPlayable,
        isTrue,
        reason: 'absent fields must default to playable so older PMS / no-checkFiles servers still work',
      );
    });

    test('parses int 0/1 from Plex JSON output', () {
      final notExists = PlexMediaVersion.fromJson(_media(partExtras: {'exists': 0, 'accessible': 1}));
      expect(notExists.exists, isFalse);
      expect(notExists.accessible, isTrue);
      expect(notExists.isPlayable, isFalse);

      final notAccessible = PlexMediaVersion.fromJson(_media(partExtras: {'exists': 1, 'accessible': 0}));
      expect(notAccessible.exists, isTrue);
      expect(notAccessible.accessible, isFalse);
      expect(notAccessible.isPlayable, isFalse);

      final ok = PlexMediaVersion.fromJson(_media(partExtras: {'exists': 1, 'accessible': 1}));
      expect(ok.isPlayable, isTrue);
    });

    test('parses native bool', () {
      final v = PlexMediaVersion.fromJson(_media(partExtras: {'exists': false, 'accessible': true}));
      expect(v.exists, isFalse);
      expect(v.accessible, isTrue);
      expect(v.isPlayable, isFalse);
    });

    test('parses string "0"/"1" forms (XML-to-JSON conversion)', () {
      final v = PlexMediaVersion.fromJson(_media(partExtras: {'exists': '0', 'accessible': '1'}));
      expect(v.exists, isFalse);
      expect(v.accessible, isTrue);
    });

    test('isPlayable truth table mirrors Plex web semantics', () {
      // Mirrors plex-web.js:28926: !1 !== e.exists && !1 !== e.accessible
      // Anything but explicit `false` for both fields → playable.
      bool playable({bool? acc, bool? ex}) {
        return PlexMediaVersion(id: 1, partKey: '/k', accessible: acc, exists: ex).isPlayable;
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
      final v = PlexMediaVersion.fromJson(json);
      expect(v.exists, isFalse);
      expect(v.isPlayable, isFalse);
    });

    test('missing Part array leaves accessibility fields null', () {
      final json = {'id': 1, 'videoResolution': '1080', 'videoCodec': 'h264', 'container': 'mkv'};
      final v = PlexMediaVersion.fromJson(json);
      expect(v.accessible, isNull);
      expect(v.exists, isNull);
      expect(v.isPlayable, isTrue);
    });
  });

  group('PlexMediaVersion displayLabel', () {
    test('formats Plex videoResolution for display', () {
      expect(PlexMediaVersion(id: 1, partKey: '/k', videoResolution: '1080').displayLabel, startsWith('1080p '));
      for (final resolution in ['4k', '4K']) {
        expect(PlexMediaVersion(id: 1, partKey: '/k', videoResolution: resolution).displayLabel, startsWith('4K '));
      }
      for (final resolution in ['8k', '8K']) {
        expect(PlexMediaVersion(id: 1, partKey: '/k', videoResolution: resolution).displayLabel, startsWith('8K '));
      }
      expect(PlexMediaVersion(id: 1, partKey: '/k', videoResolution: 'sd').displayLabel, startsWith('sd '));
    });
  });
}
