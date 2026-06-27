import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/watchlist_operations.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ============================================================
  // toggleBookmark
  // ============================================================

  group('toggleBookmark', () {
    test('inserts a row on first toggle', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
        year: 2024,
      );

      final rows = await db.select(db.watchlistItems).get();
      expect(rows, hasLength(1));
      final r = rows.first;
      expect(r.profileId, 'profile-a');
      expect(r.globalKey, 'srv:100');
      expect(r.serverId, 'srv');
      expect(r.ratingKey, '100');
      expect(r.kind, 'movie');
      expect(r.title, 'Test Movie');
      expect(r.year, 2024);
      expect(r.thumbPath, isNull);
      expect(r.backdropPath, isNull);
      expect(r.index, isNull);
      expect(r.parentTitle, isNull);
      expect(r.clientScopeId, isNull);
      expect(r.addedAt, isNotNull);
    });

    test('re-toggle removes the row', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );
      expect(await db.select(db.watchlistItems).get(), hasLength(1));

      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );
      expect(await db.select(db.watchlistItems).get(), isEmpty);
    });

    test('re-toggling after remove inserts again', () async {
      // First toggle → insert
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );
      // Second toggle → remove
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );
      // Third toggle → insert again
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Re-added Movie',
      );

      final rows = await db.select(db.watchlistItems).get();
      expect(rows, hasLength(1));
      expect(rows.first.title, 'Re-added Movie');
    });

    test('stores optional display metadata', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: 'ep1',
        globalKey: 'srv:ep1',
        kind: 'episode',
        title: 'Pilot',
        thumbPath: '/thumb/pilot.jpg',
        backdropPath: '/backdrop/pilot.jpg',
        year: 2023,
        index: 1,
        parentTitle: 'My Show',
        clientScopeId: 'srv/user-a',
      );

      final row = (await db.select(db.watchlistItems).get()).single;
      expect(row.kind, 'episode');
      expect(row.thumbPath, '/thumb/pilot.jpg');
      expect(row.backdropPath, '/backdrop/pilot.jpg');
      expect(row.index, 1);
      expect(row.parentTitle, 'My Show');
      expect(row.clientScopeId, 'srv/user-a');
    });
  });

  // ============================================================
  // isBookmarked
  // ============================================================

  group('isBookmarked', () {
    test('returns false when no row exists', () async {
      expect(await db.isBookmarked('profile-a', 'srv:100'), isFalse);
    });

    test('returns true after toggleBookmark, false after second toggle', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );
      expect(await db.isBookmarked('profile-a', 'srv:100'), isTrue);

      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );
      expect(await db.isBookmarked('profile-a', 'srv:100'), isFalse);
    });
  });

  // ============================================================
  // profile isolation
  // ============================================================

  group('profile isolation', () {
    test('add to profile A, query B via select returns empty', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'A Movie',
      );
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '200',
        globalKey: 'srv:200',
        kind: 'show',
        title: 'A Show',
      );

      // Profile A has 2 items
      final aRows = await (db.select(db.watchlistItems)
            ..where((t) => t.profileId.equals('profile-a')))
          .get();
      expect(aRows, hasLength(2));

      // Profile B has 0 items — same server items, different profile
      final bRows = await (db.select(db.watchlistItems)
            ..where((t) => t.profileId.equals('profile-b')))
          .get();
      expect(bRows, isEmpty);
    });

    test('same globalKey on different profiles are independent bookmarks', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'A sees this',
      );
      await db.toggleBookmark(
        profileId: 'profile-b',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'B sees this',
      );

      final aRows = await (db.select(db.watchlistItems)
            ..where((t) => t.profileId.equals('profile-a')))
          .get();
      expect(aRows, hasLength(1));
      expect(aRows.first.title, 'A sees this');

      final bRows = await (db.select(db.watchlistItems)
            ..where((t) => t.profileId.equals('profile-b')))
          .get();
      expect(bRows, hasLength(1));
      expect(bRows.first.title, 'B sees this');
    });
  });

  // ============================================================
  // clearAll
  // ============================================================

  group('clearAll', () {
    test('deletes only the given profile rows', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '1',
        globalKey: 'srv:1',
        kind: 'movie',
        title: 'A1',
      );
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '2',
        globalKey: 'srv:2',
        kind: 'show',
        title: 'A2',
      );
      await db.toggleBookmark(
        profileId: 'profile-b',
        serverId: 'srv',
        ratingKey: '3',
        globalKey: 'srv:3',
        kind: 'movie',
        title: 'B1',
      );

      await db.clearAll('profile-a');

      // Profile A rows gone
      expect(
        await (db.select(db.watchlistItems)..where((t) => t.profileId.equals('profile-a'))).get(),
        isEmpty,
      );
      // Profile B rows still present
      final bRows = await (db.select(db.watchlistItems)
            ..where((t) => t.profileId.equals('profile-b')))
          .get();
      expect(bRows, hasLength(1));
      expect(bRows.first.title, 'B1');
    });

    test('clearAll with empty profile is a no-op', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '1',
        globalKey: 'srv:1',
        kind: 'movie',
        title: 'A1',
      );

      await db.clearAll('profile-z-empty');
      expect(await db.select(db.watchlistItems).get(), hasLength(1));
    });
  });

  // ============================================================
  // watchWatchlist
  // ============================================================

  group('watchWatchlist', () {
    test('stream emits current items on subscribe', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );

      final stream = db.watchWatchlist('profile-a');
      final items = await stream.first;
      expect(items, hasLength(1));
      expect(items.first.title, 'Test Movie');
    });

    test('stream emits on insert', () async {
      final stream = db.watchWatchlist('profile-a');

      // Start listening, check initial state is empty
      final emitted = <List<WatchlistItem>>[];
      final sub = stream.listen((items) {
        emitted.add(items);
      });

      // Give it a moment to emit the initial empty list
      await Future.delayed(const Duration(milliseconds: 50));

      // Insert an item
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );

      // Give the stream time to emit
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      // Should have at least the initial empty + the insert emission
      expect(emitted.length, greaterThanOrEqualTo(2));
      // The last emission should contain our inserted item
      final lastEmission = emitted.last;
      expect(lastEmission.map((i) => i.title), contains('Test Movie'));
    });

    test('stream emits empty when all items removed', () async {
      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );

      final stream = db.watchWatchlist('profile-a');
      final emitted = <List<WatchlistItem>>[];
      final sub = stream.listen(emitted.add);

      await Future.delayed(const Duration(milliseconds: 50));

      await db.toggleBookmark(
        profileId: 'profile-a',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'Test Movie',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      final lastEmission = emitted.last;
      expect(lastEmission, isEmpty);
    });

    test('stream only emits for the watched profile', () async {
      final stream = db.watchWatchlist('profile-a');
      final emitted = <List<WatchlistItem>>[];
      final sub = stream.listen(emitted.add);

      await Future.delayed(const Duration(milliseconds: 50));

      // Insert into profile-b — should NOT trigger emission
      await db.toggleBookmark(
        profileId: 'profile-b',
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        kind: 'movie',
        title: 'B Movie',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      // The only emission should be the initial one (empty or not)
      // Profile B insertion should not appear in profile A's stream
      for (final items in emitted) {
        expect(items.where((i) => i.profileId == 'profile-b'), isEmpty);
      }
    });
  });
}
