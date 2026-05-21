import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_hub.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/media_library.dart';
import 'package:vibe_stream/utils/media_hub_ordering.dart';

MediaLibrary _library(String id, {String serverId = 'server'}) {
  return MediaLibrary(
    id: id,
    backend: MediaBackend.plex,
    title: 'Library $id',
    kind: MediaKind.movie,
    serverId: serverId,
  );
}

MediaItem _item(String id, {String? libraryId, String? serverId = 'server'}) {
  return MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.movie, libraryId: libraryId, serverId: serverId);
}

MediaHub _hub(String id, {String? libraryId, String? serverId = 'server', List<MediaItem> items = const []}) {
  return MediaHub(id: id, title: id, type: 'movie', libraryId: libraryId, serverId: serverId, items: items);
}

void main() {
  group('sortMediaHubsByLibraryOrder', () {
    test('sorts explicit library hubs by library order', () {
      final hubs = [_hub('movies', libraryId: '1'), _hub('anime', libraryId: '3'), _hub('shows', libraryId: '2')];

      final changed = sortMediaHubsByLibraryOrder(hubs, [_library('3'), _library('1'), _library('2')]);

      expect(changed, isTrue);
      expect(hubs.map((hub) => hub.id), ['anime', 'movies', 'shows']);
    });

    test('uses item library ids for promoted hubs', () {
      final hubs = [
        _hub('recent-movies', items: [_item('movie', libraryId: '1')]),
        _hub('recent-tv', items: [_item('episode', libraryId: '2')]),
      ];

      final changed = sortMediaHubsByLibraryOrder(hubs, [_library('2'), _library('1')]);

      expect(changed, isTrue);
      expect(hubs.map((hub) => hub.id), ['recent-tv', 'recent-movies']);
    });

    test('uses the earliest ordered item library within mixed hubs', () {
      final hubs = [
        _hub('later', items: [_item('later', libraryId: '3')]),
        _hub(
          'mixed',
          items: [
            _item('last', libraryId: '4'),
            _item('first', libraryId: '1'),
          ],
        ),
      ];

      final changed = sortMediaHubsByLibraryOrder(hubs, [_library('1'), _library('3'), _library('4')]);

      expect(changed, isTrue);
      expect(hubs.map((hub) => hub.id), ['mixed', 'later']);
    });

    test('keeps equal and unknown hubs stable after known libraries', () {
      final hubs = [
        _hub('unknown-a'),
        _hub('second-a', libraryId: '2'),
        _hub('unknown-b', serverId: null, items: [_item('missing-server', libraryId: '1', serverId: null)]),
        _hub('first', libraryId: '1'),
        _hub('second-b', libraryId: '2'),
      ];

      final changed = sortMediaHubsByLibraryOrder(hubs, [_library('1'), _library('2')]);

      expect(changed, isTrue);
      expect(hubs.map((hub) => hub.id), ['first', 'second-a', 'second-b', 'unknown-a', 'unknown-b']);
    });

    test('returns false when the current order is already correct', () {
      final hubs = [_hub('first', libraryId: '1'), _hub('second', libraryId: '2')];

      final changed = sortMediaHubsByLibraryOrder(hubs, [_library('1'), _library('2')]);

      expect(changed, isFalse);
      expect(hubs.map((hub) => hub.id), ['first', 'second']);
    });
  });
}
