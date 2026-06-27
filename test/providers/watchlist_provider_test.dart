import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/watchlist_operations.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/watchlist_provider.dart';

MediaItem _makeMediaItem({
  required String id,
  required MediaKind kind,
  String serverId = 'srv',
  String title = 'Test Title',
  String? thumbPath,
  int? year,
  int? index,
  String? parentTitle,
}) {
  return MediaItem(
    id: id,
    backend: MediaBackend.plex,
    kind: kind,
    serverId: serverId,
    title: title,
    thumbPath: thumbPath,
    year: year,
    index: index,
    parentTitle: parentTitle,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WatchlistProvider provider;
  StreamSubscription<void>? _listenSub;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    provider = WatchlistProvider(database: db);
    // Attach a listener so we can verify safeNotifyListeners fires
    provider.addListener(() {});
  });

  tearDown(() async {
    _listenSub?.cancel();
    await db.close();
    if (!provider.isDisposed) {
      provider.dispose();
    }
  });

  // ============================================================
  // toggleBookmark
  // ============================================================

  group('toggleBookmark', () {
    test('delegates insert to database and updates _items map', () async {
      provider.setActiveProfileId('profile-a');
      // Allow stream subscription to settle
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final movie = _makeMediaItem(id: '100', kind: MediaKind.movie, serverId: 'srv', title: 'Star Wars', year: 1977);

      await provider.toggleBookmark(movie);

      // After toggle, the item should be bookmarked
      expect(provider.isBookmarked(movie.globalKey), isTrue);
      expect(provider.items, contains(movie.globalKey));
      expect(provider.items[movie.globalKey]!.title, 'Star Wars');
    });

    test('delegates delete on re-toggle and removes from _items', () async {
      provider.setActiveProfileId('profile-a');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final movie = _makeMediaItem(id: '100', kind: MediaKind.movie, serverId: 'srv', title: 'Star Wars', year: 1977);

      await provider.toggleBookmark(movie);
      expect(provider.isBookmarked(movie.globalKey), isTrue);

      // Re-toggle removes
      await provider.toggleBookmark(movie);
      expect(provider.isBookmarked(movie.globalKey), isFalse);
      expect(provider.items, isNot(contains(movie.globalKey)));
    });

    test('maps all MediaItem fields to DB columns', () async {
      provider.setActiveProfileId('profile-a');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final episode = MediaItem(
        id: '200',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        serverId: 'srv',
        title: 'Pilot',
        thumbPath: '/thumb/200',
        year: 2024,
        index: 1,
        parentTitle: 'Best Show',
      );

      await provider.toggleBookmark(episode);

      final item = provider.items[episode.globalKey]!;
      expect(item.profileId, 'profile-a');
      expect(item.globalKey, 'srv:200');
      expect(item.serverId, 'srv');
      expect(item.ratingKey, '200');
      expect(item.kind, 'episode');
      expect(item.title, 'Pilot');
      expect(item.thumbPath, '/thumb/200');
      expect(item.year, 2024);
      expect(item.index, 1);
      expect(item.parentTitle, 'Best Show');
    });

    test('preserves profile isolation (profile A items not in profile B)', () async {
      provider.setActiveProfileId('profile-a');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final movieForA = _makeMediaItem(id: '101', kind: MediaKind.movie, serverId: 'srv', title: 'Avatar');
      await provider.toggleBookmark(movieForA);
      expect(provider.isBookmarked(movieForA.globalKey), isTrue);

      // Switch profile
      provider.setActiveProfileId('profile-b');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Profile B has no items
      expect(provider.items, isEmpty);
      expect(provider.isBookmarked(movieForA.globalKey), isFalse);
    });
  });

  // ============================================================
  // clearAll
  // ============================================================

  group('clearAll', () {
    test('delegates to database and empties _items map', () async {
      provider.setActiveProfileId('profile-a');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await provider.toggleBookmark(_makeMediaItem(id: '300', kind: MediaKind.movie, serverId: 'srv', title: 'M1'));
      await provider.toggleBookmark(_makeMediaItem(id: '301', kind: MediaKind.show, serverId: 'srv', title: 'S1'));
      expect(provider.items.length, 2);

      await provider.clearAll();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // _items should be empty after stream re-emits
      expect(provider.items, isEmpty);
    });
  });

  // ============================================================
  // isBookmarked
  // ============================================================

  group('isBookmarked', () {
    test('returns true when item is in _items', () async {
      provider.setActiveProfileId('profile-a');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final movie = _makeMediaItem(id: '400', kind: MediaKind.movie, serverId: 'srv', title: 'Test');
      expect(provider.isBookmarked(movie.globalKey), isFalse);

      await provider.toggleBookmark(movie);
      expect(provider.isBookmarked(movie.globalKey), isTrue);
    });

    test('returns false for unknown globalKey', () async {
      provider.setActiveProfileId('profile-a');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.isBookmarked('srv:nonexistent'), isFalse);
    });
  });

  // ============================================================
  // setActiveProfileId
  // ============================================================

  group('setActiveProfileId', () {
    test('populates _items from watchWatchlist stream', () async {
      // Seed the database directly
      await db.toggleBookmark(
        profileId: 'profile-x',
        serverId: 'srv',
        ratingKey: '500',
        globalKey: 'srv:500',
        kind: 'movie',
        title: 'Inception',
        year: 2010,
      );

      provider.setActiveProfileId('profile-x');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.items, isNotEmpty);
      expect(provider.items['srv:500']!.title, 'Inception');
    });

    test('cancels old subscription and starts new one on profile change', () async {
      // Seed profile-a
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '501',
        globalKey: 'srv:501',
        kind: 'movie',
        title: 'Movie A',
      );
      // Seed profile-b
      await db.toggleBookmark(
        profileId: 'profile-b',
        serverId: 'srv',
        ratingKey: '502',
        globalKey: 'srv:502',
        kind: 'show',
        title: 'Show B',
      );

      // Start with profile-a
      provider.setActiveProfileId('profile-a');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.items.length, 1);
      expect(provider.items['srv:501']!.title, 'Movie A');
      expect(provider.isBookmarked('srv:502'), isFalse);

      // Switch to profile-b
      provider.setActiveProfileId('profile-b');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.items.length, 1);
      expect(provider.items['srv:502']!.title, 'Show B');
      expect(provider.isBookmarked('srv:501'), isFalse);
    });

    test('cancels subscription when profileId is null', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '503',
        globalKey: 'srv:503',
        kind: 'movie',
        title: 'Movie C',
      );

      provider.setActiveProfileId('profile-a');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.items, isNotEmpty);

      provider.setActiveProfileId(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Items should be cleared when no active profile
      expect(provider.items, isEmpty);
    });

    test('no-ops when same profileId is set', () async {
      await db.toggleBookmark(
        profileId: 'profile-x',
        serverId: 'srv',
        ratingKey: '504',
        globalKey: 'srv:504',
        kind: 'movie',
        title: 'Same Profile',
      );

      provider.setActiveProfileId('profile-x');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.items.length, 1);

      // Setting the same profile again should not reset state
      provider.setActiveProfileId('profile-x');
      expect(provider.items.length, 1);
    });
  });

  // ============================================================
  // items by kind getters
  // ============================================================

  group('filtered kind getters', () {
    setUp(() async {
      provider.setActiveProfileId('profile-k');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await provider.toggleBookmark(_makeMediaItem(id: 'm1', kind: MediaKind.movie, title: 'Movie 1'));
      await provider.toggleBookmark(_makeMediaItem(id: 'm2', kind: MediaKind.movie, title: 'Movie 2'));
      await provider.toggleBookmark(_makeMediaItem(id: 's1', kind: MediaKind.show, title: 'Show 1'));
      await provider.toggleBookmark(
        _makeMediaItem(id: 'se1', kind: MediaKind.season, title: 'Season 1', index: 1),
      );
      await provider.toggleBookmark(
        _makeMediaItem(id: 'e1', kind: MediaKind.episode, title: 'Episode 1', index: 1),
      );
    });

    test('movies returns only movie kind items', () {
      final movies = provider.movies;
      expect(movies.length, 2);
      expect(movies.every((i) => i.kind == 'movie'), isTrue);
    });

    test('shows returns only show kind items', () {
      final shows = provider.shows;
      expect(shows.length, 1);
      expect(shows.single.kind, 'show');
    });

    test('seasons returns only season kind items', () {
      final seasons = provider.seasons;
      expect(seasons.length, 1);
      expect(seasons.single.kind, 'season');
    });

    test('episodes returns only episode kind items', () {
      final episodes = provider.episodes;
      expect(episodes.length, 1);
      expect(episodes.single.kind, 'episode');
    });

    test('bookmarkedKeys matches items keys', () {
      expect(provider.bookmarkedKeys, provider.items.keys.toSet());
    });
  });

  // ============================================================
  // dispose
  // ============================================================

  group('dispose', () {
    test('cancels stream subscription on dispose', () async {
      provider.setActiveProfileId('profile-d');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.items, isEmpty);

      // Dispose should not throw
      provider.dispose();
      expect(provider.isDisposed, isTrue);
    });
  });

  // ============================================================
  // safeNotifyListeners
  // ============================================================

  group('safeNotifyListeners', () {
    test('does not throw when called after dispose', () async {
      provider.dispose();
      // safeNotifyListeners should return false without throwing
      final result = provider.safeNotifyListeners();
      expect(result, isFalse);
    });
  });
}
