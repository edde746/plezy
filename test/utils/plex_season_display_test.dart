import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/utils/plex_season_display.dart';

void main() {
  group('shouldShowPlexEpisodesDirectly', () {
    test('per-show hide override shows episodes directly', () {
      final show = _show(raw: {'flattenSeasons': 1});

      expect(
        shouldShowPlexEpisodesDirectly(show: show, seasons: [_season('1'), _season('2')], libraryPrefs: {}),
        isTrue,
      );
    });

    test('per-show show override keeps seasons despite hidden library default', () {
      final show = _show(raw: {'flattenSeasons': 0});

      expect(
        shouldShowPlexEpisodesDirectly(
          show: show,
          seasons: [_season('1'), _season('2')],
          libraryPrefs: {'flattenSeasons': 1},
        ),
        isFalse,
      );
    });

    test('skipChildren hides seasons when no explicit show override exists', () {
      final show = _show(raw: {'skipChildren': true});

      expect(
        shouldShowPlexEpisodesDirectly(show: show, seasons: [_season('1'), _season('2')], libraryPrefs: {}),
        isTrue,
      );
    });

    test('falls back to library single-season mode', () {
      final show = _show();

      expect(
        shouldShowPlexEpisodesDirectly(show: show, seasons: [_season('1')], libraryPrefs: {'flattenSeasons': '2'}),
        isTrue,
      );
      expect(
        shouldShowPlexEpisodesDirectly(
          show: show,
          seasons: [_season('1'), _season('2')],
          libraryPrefs: {'flattenSeasons': '2'},
        ),
        isFalse,
      );
    });
  });
}

MediaItem _show({Map<String, Object?>? raw}) {
  return MediaItem(id: 'show', backend: MediaBackend.plex, kind: MediaKind.show, raw: raw);
}

MediaItem _season(String id) {
  return MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.season);
}
