import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/models/home_section_config.dart';
import 'package:plezy/utils/home_section_builder.dart';
import '../test_helpers/media_items.dart';

MediaHub _hub(String identifier, List<MediaItem> items) => MediaHub(
  id: identifier,
  identifier: identifier,
  title: identifier,
  type: 'movie',
  serverId: 'srv',
  libraryId: identifier,
  items: items,
);

HomeSectionConfig _section(HomeSectionKind kind) =>
    HomeSectionConfig(id: 'merged', title: 'Merged', kind: kind, showOnHome: true);

void main() {
  group('buildConfiguredHomeSections merged-row ordering', () {
    test('recently added interleaves items across libraries by addedAt, newest first', () {
      final hubs = [
        _hub('library.1.recentlyAdded', [
          testMediaItem(id: 'movie-old', addedAt: 100),
          testMediaItem(id: 'movie-newest', addedAt: 400),
        ]),
        _hub('library.2.recentlyAdded', [
          testMediaItem(id: 'show-mid', addedAt: 300),
          testMediaItem(id: 'show-oldest', addedAt: 50),
        ]),
      ];

      final result = buildConfiguredHomeSections(
        sourceHubs: hubs,
        collections: const [],
        sections: [_section(HomeSectionKind.recentlyAdded)],
        rowOrder: const ['custom:merged'],
      );

      expect(result, hasLength(1));
      expect(
        result.single.items.map((item) => item.id),
        ['movie-newest', 'show-mid', 'movie-old', 'show-oldest'],
      );
    });

    test('recently released interleaves items across libraries by originallyAvailableAt, newest first', () {
      final hubs = [
        _hub('library.1.recentlyReleased', [
          testMediaItem(id: 'movie-2020', originallyAvailableAt: '2020-01-01'),
          testMediaItem(id: 'movie-2024', originallyAvailableAt: '2024-06-15'),
        ]),
        _hub('library.2.recentlyReleased', [
          testMediaItem(id: 'show-2023', originallyAvailableAt: '2023-03-10'),
        ]),
      ];

      final result = buildConfiguredHomeSections(
        sourceHubs: hubs,
        collections: const [],
        sections: [_section(HomeSectionKind.recentlyReleased)],
        rowOrder: const ['custom:merged'],
      );

      expect(result, hasLength(1));
      expect(
        result.single.items.map((item) => item.id),
        ['movie-2024', 'show-2023', 'movie-2020'],
      );
    });

    test('items missing the sort field sort after items that have it', () {
      final hubs = [
        _hub('library.1.recentlyAdded', [
          testMediaItem(id: 'no-date'),
          testMediaItem(id: 'has-date', addedAt: 10),
        ]),
      ];

      final result = buildConfiguredHomeSections(
        sourceHubs: hubs,
        collections: const [],
        sections: [_section(HomeSectionKind.recentlyAdded)],
        rowOrder: const ['custom:merged'],
      );

      expect(result.single.items.map((item) => item.id), ['has-date', 'no-date']);
    });
  });

  group('buildConfiguredHomeSections row order is the single source of truth', () {
    test('an empty rowOrder shows everything unfiltered: the merge plus every raw hub', () {
      final matchedHub = _hub('library.1.recentlyAdded', [testMediaItem(id: 'merged-item', addedAt: 10)]);
      final unrelatedHub = MediaHub(
        id: 'genre-hub',
        identifier: 'custom.genre.horror',
        title: 'Horror Collection',
        type: 'collection',
        items: [testMediaItem(id: 'horror-item')],
      );

      final result = buildConfiguredHomeSections(
        sourceHubs: [matchedHub, unrelatedHub],
        collections: const [],
        sections: [_section(HomeSectionKind.recentlyAdded)],
      );

      expect(result.map((h) => h.identifier), ['configured.recently_added', 'library.1.recentlyAdded', 'custom.genre.horror']);
    });

    test('a merged row and the specific raw hub it draws from can both show, each by its own token', () {
      // Both are legitimate, independently-ordered rows once the Organizer
      // lists both tokens -- there is no separate content-matching heuristic
      // deciding to hide one of them behind the scenes.
      final matchedHub = MediaHub(
        id: 'library.1.recentlyAdded',
        identifier: 'library.1.recentlyAdded',
        title: 'library.1.recentlyAdded',
        type: 'movie',
        serverId: 'srv',
        libraryId: 'lib1',
        items: [testMediaItem(id: 'merged-item', addedAt: 10)],
      );

      final result = buildConfiguredHomeSections(
        sourceHubs: [matchedHub],
        collections: const [],
        sections: [_section(HomeSectionKind.recentlyAdded)],
        rowOrder: const ['plex:srv:lib1:library.1.recentlyAdded', 'custom:merged'],
      );

      expect(result.map((h) => h.identifier), ['library.1.recentlyAdded', 'configured.recently_added']);
    });

    test('a token removed from rowOrder is genuinely gone, not re-added as "new" content', () {
      final matchedHub = MediaHub(
        id: 'library.1.recentlyAdded',
        identifier: 'library.1.recentlyAdded',
        title: 'library.1.recentlyAdded',
        type: 'movie',
        serverId: 'srv',
        libraryId: 'lib1',
        items: [testMediaItem(id: 'merged-item', addedAt: 10)],
      );

      final result = buildConfiguredHomeSections(
        sourceHubs: [matchedHub],
        collections: const [],
        sections: [_section(HomeSectionKind.recentlyAdded)],
        // Only the merged row's own token is listed -- the raw hub's token
        // was removed (e.g. via the Organizer's own remove button) and must
        // not silently reappear.
        rowOrder: const ['custom:merged'],
      );

      expect(result.map((h) => h.identifier), ['configured.recently_added']);
    });

    test('a hub with no libraryId can never get a token, so it always shows regardless of rowOrder', () {
      final untrackable = MediaHub(
        id: 'synthetic',
        identifier: 'synthetic.hub',
        title: 'Synthetic',
        type: 'mixed',
        items: const [],
      );

      final result = buildConfiguredHomeSections(
        sourceHubs: [untrackable],
        collections: const [],
        sections: const [],
        rowOrder: const ['custom:something-else'],
      );

      expect(result.map((h) => h.identifier), ['synthetic.hub']);
    });

    test('a hub with no libraryId of its own borrows one from its items, matching its Organizer token', () {
      // Live root cause (#1652 follow-up): the Plex client never sets
      // MediaHub.libraryId itself -- the section id it computes per hub only
      // gets pushed down onto that hub's own items. Without this fallback,
      // every real hub was "untrackable" and the Organizer could never
      // filter or order anything.
      final hubWithNoOwnLibraryId = MediaHub(
        id: 'movie.recentlyreleased.7',
        identifier: 'movie.recentlyreleased.7',
        title: 'Recently Released Movies',
        type: 'movie',
        serverId: 'srv',
        items: [testMediaItem(id: 'item-1', libraryId: '7')],
      );

      final result = buildConfiguredHomeSections(
        sourceHubs: [hubWithNoOwnLibraryId],
        collections: const [],
        sections: const [],
        rowOrder: const ['plex:srv:7:movie.recentlyreleased.7'],
      );

      expect(result.map((h) => h.identifier), ['movie.recentlyreleased.7']);
    });

    test('two fetch legs returning the same hub collapse into one row, not a duplicate', () {
      // Live root cause: additionalLibraryHubKinds' per-library fetch can
      // return the exact same hub the global/promoted fetch already did,
      // producing a literal duplicate entry in sourceHubs.
      MediaHub sameHub() => MediaHub(
        id: 'movie.recentlyreleased.7',
        identifier: 'movie.recentlyreleased.7',
        title: 'Recently Released Movies',
        type: 'movie',
        serverId: 'srv',
        items: [testMediaItem(id: 'item-1', libraryId: '7')],
      );

      final result = buildConfiguredHomeSections(
        sourceHubs: [sameHub(), sameHub()],
        collections: const [],
        sections: const [],
        rowOrder: const ['plex:srv:7:movie.recentlyreleased.7'],
      );

      expect(result, hasLength(1));
    });

    test('the Organizer\'s saved identifier matches a differently-suffixed content identifier', () {
      // Live root cause: Plex's hub-management API (what the Organizer's
      // saved token is built from) and its hub-content API (what actually
      // renders on Home) return DIFFERENT identifier strings for the same
      // conceptual hub -- e.g. "movie.recentlyreleased" (managed) vs.
      // "movie.recentlyreleased.7" (content), confirmed live. Matching must
      // tolerate the content identifier extending the managed one, not
      // require exact equality.
      final contentHub = MediaHub(
        id: 'movie.recentlyreleased.7',
        identifier: 'movie.recentlyreleased.7',
        title: 'Recently Released Movies',
        type: 'movie',
        serverId: 'srv',
        items: [testMediaItem(id: 'item-1', libraryId: '7')],
      );

      final result = buildConfiguredHomeSections(
        sourceHubs: [contentHub],
        collections: const [],
        sections: const [],
        // The Organizer saved the shorter, managed-API identifier.
        rowOrder: const ['plex:srv:7:movie.recentlyreleased'],
      );

      expect(result.map((h) => h.identifier), ['movie.recentlyreleased.7']);
    });

    test('a managed identifier does not cross-match a same-named hub from a different library', () {
      final library1Hub = MediaHub(
        id: 'movie.recentlyreleased.1',
        identifier: 'movie.recentlyreleased.1',
        title: 'Recently Released Movies',
        type: 'movie',
        serverId: 'srv',
        items: [testMediaItem(id: 'item-1', libraryId: '1')],
      );
      final library7Hub = MediaHub(
        id: 'movie.recentlyreleased.7',
        identifier: 'movie.recentlyreleased.7',
        title: 'Recently Released Movies',
        type: 'movie',
        serverId: 'srv',
        items: [testMediaItem(id: 'item-2', libraryId: '7')],
      );

      final result = buildConfiguredHomeSections(
        sourceHubs: [library1Hub, library7Hub],
        collections: const [],
        sections: const [],
        rowOrder: const ['plex:srv:7:movie.recentlyreleased'],
      );

      // Only library 7's hub is in the Organizer's saved order -- library
      // 1's same-titled hub must not be pulled in by mistake.
      expect(result.map((h) => h.identifier), ['movie.recentlyreleased.7']);
    });
  });
}
