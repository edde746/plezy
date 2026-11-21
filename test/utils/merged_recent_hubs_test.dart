import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/utils/merged_recent_hubs.dart';
import '../test_helpers/media_items.dart';

MediaItem _item(String id, String libraryId, int addedAt, {String serverId = 'server'}) =>
    testMediaItem(id: id, backend: MediaBackend.plex, libraryId: libraryId, serverId: serverId, addedAt: addedAt);

MediaHub _hub(String identifier, List<MediaItem> items, {String serverId = 'server', String? libraryId}) => MediaHub(
  id: identifier,
  identifier: identifier,
  title: identifier,
  type: 'movie',
  items: items,
  serverId: serverId,
  libraryId: libraryId,
);

void main() {
  group('isLibraryRecentlyAddedHub', () {
    test('matches Plex and Jellyfin per-library Recently Added identifiers', () {
      expect(isLibraryRecentlyAddedHub(_hub('movie.recentlyAdded.1', const [])), isTrue);
      expect(isLibraryRecentlyAddedHub(_hub('tv.recentlyadded', const [])), isTrue);
      expect(isLibraryRecentlyAddedHub(_hub('library.abc123.recent', const [])), isTrue);
    });

    test('ignores other rows and the server-merged Plex rows', () {
      expect(isLibraryRecentlyAddedHub(_hub('movie.recentlyreleased.1', const [])), isFalse);
      expect(isLibraryRecentlyAddedHub(_hub('home.movies.recent', const [])), isFalse);
      expect(isLibraryRecentlyAddedHub(_hub('library.abc123.continue', const [])), isFalse);
    });
  });

  group('mergeRecentlyAddedHubs', () {
    final movies = _hub('movie.recentlyAdded.1', [_item('m1', '1', 10), _item('m2', '1', 30)]);
    final shows = _hub('tv.recentlyAdded.2', [_item('s1', '2', 20)]);
    final cartoons = _hub('tv.recentlyAdded.3', [_item('c1', '3', 40)]);
    final released = _hub('movie.recentlyreleased.1', [_item('m1', '1', 10)]);
    final hubs = [released, movies, shows, cartoons];

    test('folds the selected libraries into one row at the first source position, newest first', () {
      final result = mergeRecentlyAddedHubs(hubs, {'server:1', 'server:2'}, title: 'Recently Added');

      expect(result.map((h) => h.id), ['movie.recentlyreleased.1', mergedRecentlyAddedHubId, 'tv.recentlyAdded.3']);
      final merged = result[1];
      expect(merged.title, 'Recently Added');
      expect(merged.items.map((i) => i.id), ['m2', 's1', 'm1']);
      expect(merged.serverId, 'server');
      expect(merged.more, isFalse);
    });

    test('leaves the rows alone when fewer than two selected rows are present', () {
      expect(mergeRecentlyAddedHubs(hubs, {'server:1'}, title: 'x'), same(hubs));
      expect(mergeRecentlyAddedHubs(hubs, {'server:1', 'server:9'}, title: 'x'), same(hubs));
    });

    test('uses the hub library id when items carry none (Jellyfin)', () {
      final a = _hub('library.a.recent', [_item('a1', 'a', 1)], libraryId: 'a');
      final b = _hub('library.b.recent', [_item('b1', 'b', 2)], libraryId: 'b');
      final result = mergeRecentlyAddedHubs([a, b], {'server:a', 'server:b'}, title: 'x');
      expect(result.single.items.map((i) => i.id), ['b1', 'a1']);
    });

    test('merges across servers and caps the row', () {
      final a = _hub('movie.recentlyAdded.1', [for (var i = 0; i < 5; i++) _item('a$i', '1', i)]);
      final b = _hub('movie.recentlyAdded.1', [
        for (var i = 0; i < 5; i++) _item('b$i', '1', 10 + i, serverId: 'other'),
      ], serverId: 'other');
      final result = mergeRecentlyAddedHubs([a, b], {'server:1', 'other:1'}, title: 'x', limit: 3);
      expect(result.single.items.map((i) => i.id), ['b4', 'b3', 'b2']);
      expect(result.single.serverId, isNull);
    });
  });
}
