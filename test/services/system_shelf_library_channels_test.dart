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

      final merged = SystemShelfLibraryChannels.recentlyAdded(
        hubs,
        kind: SystemShelfLibraryKind.movies,
      );
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

      final merged = SystemShelfLibraryChannels.recentlyAdded(
        hubs,
        kind: SystemShelfLibraryKind.movies,
      );
      expect(merged, hasLength(1));
      expect(merged.single.id, 'j1'); // higher addedAt wins
    });

    test('splits recently added movies from tv/episodes', () {
      final hubs = [
        _hub(
          id: 'home.recent',
          identifier: 'home.recent',
          items: [
            testMediaItem(id: 'm1', title: 'Film', kind: MediaKind.movie, addedAt: 30),
            testMediaItem(id: 's1', title: 'Series', kind: MediaKind.show, addedAt: 40),
            testMediaItem(id: 'e1', title: 'Ep', kind: MediaKind.episode, addedAt: 50),
          ],
        ),
      ];

      expect(
        SystemShelfLibraryChannels.recentlyAdded(
          hubs,
          kind: SystemShelfLibraryKind.movies,
        ).map((item) => item.id),
        ['m1'],
      );
      expect(
        SystemShelfLibraryChannels.recentlyAdded(
          hubs,
          kind: SystemShelfLibraryKind.tv,
        ).map((item) => item.id),
        ['e1', 's1'],
      );
    });

    test('new releases prefer premiere date over addedAt', () {
      final olderPremiere = testMediaItem(
        id: 'old',
        title: 'Old Prem',
        year: 2024,
        kind: MediaKind.movie,
        addedAt: 999,
        originallyAvailableAt: '2024-01-01',
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

      final releases = SystemShelfLibraryChannels.newReleases(
        hubs,
        kind: SystemShelfLibraryKind.movies,
        now: DateTime.utc(2025, 6, 1),
      );
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

      final releases = SystemShelfLibraryChannels.newReleases(
        hubs,
        kind: SystemShelfLibraryKind.movies,
        now: DateTime.utc(2025, 6, 1),
      );
      expect(releases.map((item) => item.id), ['rel']);
    });

    test('recently added ranks by addedAt and keeps hub items without it', () {
      final hubs = [
        _hub(
          id: 'home.movies.recent',
          identifier: 'home.movies.recent',
          items: [
            testMediaItem(
              id: 'no-added',
              title: 'Hub Says Recent',
              year: 2015,
              kind: MediaKind.movie,
              updatedAt: 9999,
            ),
            testMediaItem(
              id: 'fresh',
              title: 'Actually Added',
              year: 2024,
              kind: MediaKind.movie,
              addedAt: 100,
            ),
          ],
        ),
      ];

      final merged = SystemShelfLibraryChannels.recentlyAdded(
        hubs,
        kind: SystemShelfLibraryKind.movies,
      );
      expect(merged.map((item) => item.id), ['fresh', 'no-added']);
    });

    test('new releases rank by premiere only, ignoring add date', () {
      final hubs = [
        _hub(
          id: 'home.movies.recent',
          identifier: 'home.movies.recent',
          items: [
            testMediaItem(
              id: 'just-added-old',
              title: 'Rise of Skywalker',
              year: 2019,
              kind: MediaKind.movie,
              originallyAvailableAt: '2019-12-20',
              addedAt: 9000,
            ),
            testMediaItem(
              id: 'older-add-newer-film',
              title: 'Newer Film',
              year: 2024,
              kind: MediaKind.movie,
              originallyAvailableAt: '2024-11-01',
              addedAt: 10,
            ),
          ],
        ),
      ];

      final releases = SystemShelfLibraryChannels.newReleases(
        hubs,
        kind: SystemShelfLibraryKind.movies,
        now: DateTime.utc(2025, 6, 1),
      );
      expect(releases.map((item) => item.id), ['older-add-newer-film']);
    });

    test('year-only new release outranks older dated premiere', () {
      final hubs = [
        _hub(
          id: 'home.movies.recent',
          identifier: 'home.movies.recent',
          items: [
            testMediaItem(
              id: 'skywalker',
              title: 'Rise of Skywalker',
              year: 2019,
              kind: MediaKind.movie,
              originallyAvailableAt: '2019-12-20',
              addedAt: 500,
            ),
            testMediaItem(
              id: 'newer',
              title: 'Newer Film',
              year: 2024,
              kind: MediaKind.movie,
              addedAt: 400,
            ),
          ],
        ),
      ];

      final releases = SystemShelfLibraryChannels.newReleases(
        hubs,
        kind: SystemShelfLibraryKind.movies,
        now: DateTime.utc(2025, 6, 1),
      );
      expect(releases.map((item) => item.id), ['newer']);
    });

    test('new releases drop premieres older than the freshness window', () {
      final hubs = [
        _hub(
          id: 'movie.recentlyreleased',
          identifier: 'movie.recentlyreleased',
          items: [
            testMediaItem(
              id: 'skywalker',
              title: 'Rise of Skywalker',
              year: 2019,
              kind: MediaKind.movie,
              originallyAvailableAt: '2019-12-20',
            ),
            testMediaItem(
              id: 'fresh',
              title: 'Fresh Film',
              year: 2024,
              kind: MediaKind.movie,
              originallyAvailableAt: '2024-11-01',
            ),
          ],
        ),
      ];

      final releases = SystemShelfLibraryChannels.newReleases(
        hubs,
        kind: SystemShelfLibraryKind.movies,
        now: DateTime.utc(2025, 6, 1),
      );
      expect(releases.map((item) => item.id), ['fresh']);
    });

    test('new movie releases skip episodes and shows', () {
      final hubs = [
        _hub(
          id: 'home.recent',
          identifier: 'home.recent',
          items: [
            testMediaItem(
              id: 'ep',
              title: 'Pilot',
              year: 2025,
              kind: MediaKind.episode,
              originallyAvailableAt: '2025-05-01',
              addedAt: 50,
            ),
            testMediaItem(
              id: 'show',
              title: 'Series',
              year: 2025,
              kind: MediaKind.show,
              originallyAvailableAt: '2025-05-15',
              addedAt: 45,
            ),
            testMediaItem(
              id: 'movie',
              title: 'Feature',
              year: 2025,
              kind: MediaKind.movie,
              originallyAvailableAt: '2025-04-01',
              addedAt: 40,
            ),
          ],
        ),
      ];

      expect(
        SystemShelfLibraryChannels.newReleases(
          hubs,
          kind: SystemShelfLibraryKind.movies,
          now: DateTime.utc(2025, 6, 1),
        ).map((item) => item.id),
        ['movie'],
      );
    });

    test('new tv releases prefer recent episodes over shows', () {
      final hubs = [
        _hub(
          id: 'home.recent',
          identifier: 'home.recent',
          items: [
            testMediaItem(
              id: 'old-ep',
              title: 'Old Ep',
              year: 2024,
              kind: MediaKind.episode,
              originallyAvailableAt: '2024-01-01',
              addedAt: 90,
            ),
            testMediaItem(
              id: 'new-ep',
              title: 'New Ep',
              year: 2025,
              kind: MediaKind.episode,
              originallyAvailableAt: '2025-05-20',
              addedAt: 10,
            ),
            testMediaItem(
              id: 'show',
              title: 'Series',
              year: 2025,
              kind: MediaKind.show,
              originallyAvailableAt: '2025-05-15',
              addedAt: 80,
            ),
          ],
        ),
      ];

      expect(
        SystemShelfLibraryChannels.newReleases(
          hubs,
          kind: SystemShelfLibraryKind.tv,
          now: DateTime.utc(2025, 6, 1),
        ).map((item) => item.id),
        ['new-ep'],
      );
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
