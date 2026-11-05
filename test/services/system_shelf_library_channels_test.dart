import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/system_shelf_library_channels.dart';

import '../test_helpers/media_items.dart';

void main() {
  group('SystemShelfLibraryChannels', () {
    test('recognizes plex and jellyfin recently-added hub keys', () {
      expect(
        SystemShelfLibraryChannels.isRecentlyAddedHub(
          _hub(id: 'home.movies.recent', identifier: 'home.movies.recent'),
        ),
        isTrue,
      );
      expect(
        SystemShelfLibraryChannels.isRecentlyAddedHub(
          _hub(id: 'library.lib-1.recent', identifier: 'library.lib-1.recent'),
        ),
        isTrue,
      );
      expect(
        SystemShelfLibraryChannels.isRecentlyAddedHub(
          _hub(id: 'movie.recentlyadded', identifier: 'movie.recentlyadded'),
        ),
        isTrue,
      );
      expect(
        SystemShelfLibraryChannels.isRecentlyAddedHub(
          _hub(id: 'home.continue', identifier: 'home.continue'),
        ),
        isFalse,
      );
      expect(
        SystemShelfLibraryChannels.isRecentlyAddedHub(
          _hub(id: 'library.music.recentlyplayed', identifier: 'library.music.recentlyplayed'),
        ),
        isFalse,
      );
    });

    test('merges plex+jellyfin recently added by addedAt with title dedupe', () {
      final plex = testMediaItem(
        id: 'p1',
        serverId: 'plex',
        title: 'Dune',
        year: 2021,
        kind: MediaKind.movie,
        addedAt: 200,
      );
      final jelly = testMediaItem(
        id: 'j1',
        serverId: 'jelly',
        title: 'Dune',
        year: 2021,
        kind: MediaKind.movie,
        addedAt: 150,
      );
      final other = testMediaItem(
        id: 'p2',
        serverId: 'plex',
        title: 'Arrival',
        year: 2016,
        kind: MediaKind.movie,
        addedAt: 180,
      );
      final hubs = [
        _hub(id: 'home.movies.recent', identifier: 'home.movies.recent', items: [plex, other]),
        _hub(id: 'home.recent', identifier: 'home.recent', items: [jelly]),
      ];

      final merged = SystemShelfLibraryChannels.recentlyAdded(hubs);
      expect(merged.map((item) => item.id), ['p1', 'p2']);
    });

    test('dedupes on imdb when raw Guid is present', () {
      final plex = MediaItem.plex(
        id: 'p1',
        kind: MediaKind.movie,
        title: 'One Title',
        year: 2020,
        addedAt: 10,
        serverId: 'plex',
        raw: {
          'Guid': [
            {'id': 'imdb://tt123'},
          ],
        },
      );
      final jelly = MediaItem.jellyfin(
        id: 'j1',
        kind: MediaKind.movie,
        title: 'Different Title Same Film',
        year: 2020,
        addedAt: 99,
        serverId: 'jelly',
        raw: {
          'ProviderIds': {'Imdb': 'tt123'},
        },
      );
      final hubs = [
        _hub(id: 'home.recent', identifier: 'home.recent', items: [plex, jelly]),
      ];

      final merged = SystemShelfLibraryChannels.recentlyAdded(hubs);
      expect(merged, hasLength(1));
      expect(merged.single.id, 'j1'); // higher addedAt wins
    });

    test('new releases prefer premiere date over addedAt', () {
      final olderPremiere = testMediaItem(
        id: 'old',
        title: 'Old Prem',
        year: 2020,
        kind: MediaKind.movie,
        addedAt: 999,
        originallyAvailableAt: '2020-01-01',
      );
      final newerPremiere = testMediaItem(
        id: 'new',
        title: 'New Prem',
        year: 2024,
        kind: MediaKind.movie,
        addedAt: 1,
        originallyAvailableAt: '2024-06-01',
      );
      final hubs = [
        _hub(
          id: 'home.movies.recent',
          identifier: 'home.movies.recent',
          items: [olderPremiere, newerPremiere],
        ),
      ];

      final releases = SystemShelfLibraryChannels.newReleases(hubs);
      expect(releases.map((item) => item.id), ['new', 'old']);
    });

    test('dedicated recentlyreleased hub feeds new releases first', () {
      final fromReleaseHub = testMediaItem(
        id: 'rel',
        title: 'Just Released',
        year: 2025,
        kind: MediaKind.movie,
        originallyAvailableAt: '2025-01-01',
      );
      final hubs = [
        _hub(
          id: 'movie.recentlyreleased',
          identifier: 'movie.recentlyreleased',
          items: [fromReleaseHub],
        ),
        _hub(
          id: 'home.movies.recent',
          identifier: 'home.movies.recent',
          items: [
            testMediaItem(
              id: 'recent',
              title: 'Library Add',
              year: 2024,
              kind: MediaKind.movie,
              originallyAvailableAt: '2024-01-01',
              addedAt: 500,
            ),
          ],
        ),
      ];

      final releases = SystemShelfLibraryChannels.newReleases(hubs);
      expect(releases.map((item) => item.id), ['rel']);
    });
  });
}

MediaHub _hub({
  required String id,
  String? identifier,
  List<MediaItem> items = const [],
}) {
  return MediaHub(
    id: id,
    identifier: identifier,
    title: id,
    type: 'mixed',
    items: items,
  );
}
