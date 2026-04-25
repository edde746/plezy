import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/models/download_models.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ============================================================
  // insertDownload
  // ============================================================

  group('insertDownload', () {
    test('inserts a movie row with defaults', () async {
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );

      final rows = await db.select(db.downloadedMedia).get();
      expect(rows, hasLength(1));
      final r = rows.first;
      expect(r.serverId, 'srv');
      expect(r.ratingKey, '100');
      expect(r.globalKey, 'srv:100');
      expect(r.type, 'movie');
      expect(r.status, DownloadStatus.queued.index);
      expect(r.parentRatingKey, isNull);
      expect(r.grandparentRatingKey, isNull);
      expect(r.mediaIndex, 0);
    });

    test('inserts an episode with parent and grandparent keys', () async {
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: 'ep1',
        globalKey: 'srv:ep1',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.queued.index,
        mediaIndex: 7,
      );

      final row = (await db.select(db.downloadedMedia).get()).single;
      expect(row.parentRatingKey, 'season1');
      expect(row.grandparentRatingKey, 'show1');
      expect(row.mediaIndex, 7);
    });

    test('insertDownload uses InsertMode.insertOrReplace (re-insert overwrites)', () async {
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      // Mark progress so we can detect a replace.
      await db.updateDownloadProgress('srv:100', 50, 500, 1000);

      // Re-insert with the same globalKey — should replace, resetting progress to default 0.
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        type: 'movie',
        status: DownloadStatus.failed.index,
      );

      final row = (await db.select(db.downloadedMedia).get()).single;
      expect(row.status, DownloadStatus.failed.index);
      expect(row.progress, 0);
      expect(row.downloadedBytes, 0);
    });
  });

  // ============================================================
  // Download queue + getNextQueueItem
  // ============================================================

  group('queue', () {
    test('addToQueue inserts a row with defaults', () async {
      await db.addToQueue(mediaGlobalKey: 'srv:100');

      final rows = await db.select(db.downloadQueue).get();
      expect(rows, hasLength(1));
      expect(rows.first.mediaGlobalKey, 'srv:100');
      expect(rows.first.priority, 0);
      expect(rows.first.downloadSubtitles, isTrue);
      expect(rows.first.downloadArtwork, isTrue);
    });

    test('addToQueue stores custom priority and toggles', () async {
      await db.addToQueue(mediaGlobalKey: 'srv:100', priority: 5, downloadSubtitles: false, downloadArtwork: false);

      final row = (await db.select(db.downloadQueue).get()).single;
      expect(row.priority, 5);
      expect(row.downloadSubtitles, isFalse);
      expect(row.downloadArtwork, isFalse);
    });

    test('addToQueue replaces row with same mediaGlobalKey (unique)', () async {
      await db.addToQueue(mediaGlobalKey: 'srv:100', priority: 1);
      await db.addToQueue(mediaGlobalKey: 'srv:100', priority: 9);

      final rows = await db.select(db.downloadQueue).get();
      expect(rows, hasLength(1));
      expect(rows.first.priority, 9);
    });

    test('removeFromQueue deletes the matching row', () async {
      await db.addToQueue(mediaGlobalKey: 'srv:1');
      await db.addToQueue(mediaGlobalKey: 'srv:2');

      await db.removeFromQueue('srv:1');

      final rows = await db.select(db.downloadQueue).get();
      expect(rows, hasLength(1));
      expect(rows.first.mediaGlobalKey, 'srv:2');
    });

    test('getNextQueueItem returns null when empty', () async {
      expect(await db.getNextQueueItem(), isNull);
    });

    test('getNextQueueItem only returns items whose media is queued', () async {
      // Two items in queue; one's media is still queued, the other is downloading.
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '1',
        globalKey: 'srv:1',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '2',
        globalKey: 'srv:2',
        type: 'movie',
        status: DownloadStatus.downloading.index,
      );

      await db.addToQueue(mediaGlobalKey: 'srv:1', priority: 1);
      await db.addToQueue(mediaGlobalKey: 'srv:2', priority: 10);

      final next = await db.getNextQueueItem();
      expect(next, isNotNull);
      // Should pick srv:1 since srv:2 is downloading (not queued).
      expect(next!.mediaGlobalKey, 'srv:1');
    });

    test('getNextQueueItem orders by priority desc, then addedAt asc', () async {
      // All have queued status
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '1',
        globalKey: 'srv:1',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '2',
        globalKey: 'srv:2',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '3',
        globalKey: 'srv:3',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );

      // Manually inject deterministic addedAt so the test isn't time-dependent.
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.downloadQueue)
          .insert(DownloadQueueCompanion.insert(mediaGlobalKey: 'srv:1', priority: const Value(1), addedAt: now));
      await db
          .into(db.downloadQueue)
          .insert(DownloadQueueCompanion.insert(mediaGlobalKey: 'srv:2', priority: const Value(5), addedAt: now + 100));
      await db
          .into(db.downloadQueue)
          .insert(DownloadQueueCompanion.insert(mediaGlobalKey: 'srv:3', priority: const Value(5), addedAt: now + 50));

      final next = await db.getNextQueueItem();
      // priority 5 wins; srv:3 added before srv:2.
      expect(next!.mediaGlobalKey, 'srv:3');
    });
  });

  // ============================================================
  // Update helpers
  // ============================================================

  group('update helpers', () {
    Future<void> seed({String key = 'srv:100'}) async {
      await db.insertDownload(
        serverId: key.split(':').first,
        ratingKey: key.split(':').last,
        globalKey: key,
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
    }

    test('updateDownloadStatus changes only status', () async {
      await seed();
      await db.updateDownloadStatus('srv:100', DownloadStatus.downloading.index);

      final r = (await db.select(db.downloadedMedia).get()).single;
      expect(r.status, DownloadStatus.downloading.index);
      expect(r.progress, 0); // untouched
    });

    test('updateDownloadProgress writes progress + bytes', () async {
      await seed();
      await db.updateDownloadProgress('srv:100', 42, 4242, 9999);

      final r = (await db.select(db.downloadedMedia).get()).single;
      expect(r.progress, 42);
      expect(r.downloadedBytes, 4242);
      expect(r.totalBytes, 9999);
    });

    test('updateVideoFilePath sets path and downloadedAt timestamp', () async {
      await seed();
      final before = DateTime.now().millisecondsSinceEpoch;
      await db.updateVideoFilePath('srv:100', '/tmp/file.mkv');
      final after = DateTime.now().millisecondsSinceEpoch;

      final r = (await db.select(db.downloadedMedia).get()).single;
      expect(r.videoFilePath, '/tmp/file.mkv');
      expect(r.downloadedAt, isNotNull);
      expect(r.downloadedAt! >= before, isTrue);
      expect(r.downloadedAt! <= after, isTrue);
    });

    test('updateArtworkPaths sets thumbPath; null clears it', () async {
      await seed();
      await db.updateArtworkPaths(globalKey: 'srv:100', thumbPath: '/tmp/thumb.jpg');
      expect((await db.select(db.downloadedMedia).get()).single.thumbPath, '/tmp/thumb.jpg');

      await db.updateArtworkPaths(globalKey: 'srv:100', thumbPath: null);
      expect((await db.select(db.downloadedMedia).get()).single.thumbPath, isNull);
    });

    test('updateDownloadError stores message and increments retryCount', () async {
      await seed();

      await db.updateDownloadError('srv:100', 'first');
      var r = (await db.select(db.downloadedMedia).get()).single;
      expect(r.errorMessage, 'first');
      expect(r.retryCount, 1);

      await db.updateDownloadError('srv:100', 'second');
      r = (await db.select(db.downloadedMedia).get()).single;
      expect(r.errorMessage, 'second');
      expect(r.retryCount, 2);
    });

    test('clearDownloadError nulls the message and resets retryCount to 0', () async {
      await seed();
      await db.updateDownloadError('srv:100', 'oops');

      await db.clearDownloadError('srv:100');
      final r = (await db.select(db.downloadedMedia).get()).single;
      expect(r.errorMessage, isNull);
      expect(r.retryCount, 0);
    });

    test('updateBgTaskId / getBgTaskId round-trip', () async {
      await seed();
      expect(await db.getBgTaskId('srv:100'), isNull);

      await db.updateBgTaskId('srv:100', 'task-abc');
      expect(await db.getBgTaskId('srv:100'), 'task-abc');

      await db.updateBgTaskId('srv:100', null);
      expect(await db.getBgTaskId('srv:100'), isNull);
    });

    test('getBgTaskId on missing globalKey returns null', () async {
      expect(await db.getBgTaskId('does:not-exist'), isNull);
    });
  });

  // ============================================================
  // Lookup helpers
  // ============================================================

  group('lookup helpers', () {
    Future<void> seedTree() async {
      await db.insertDownload(
        serverId: 'srvA',
        ratingKey: 'ep1',
        globalKey: 'srvA:ep1',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: 'srvA',
        ratingKey: 'ep2',
        globalKey: 'srvA:ep2',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: 'srvA',
        ratingKey: 'ep3',
        globalKey: 'srvA:ep3',
        type: 'episode',
        parentRatingKey: 'season2',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: 'srvB',
        ratingKey: 'movie1',
        globalKey: 'srvB:movie1',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
    }

    test('getDownloadedMedia returns the matching row or null', () async {
      await seedTree();

      final hit = await db.getDownloadedMedia('srvA:ep1');
      expect(hit, isNotNull);
      expect(hit!.ratingKey, 'ep1');

      expect(await db.getDownloadedMedia('nope:nope'), isNull);
    });

    test('getEpisodesBySeason filters by parentRatingKey', () async {
      await seedTree();

      final s1 = await db.getEpisodesBySeason('season1');
      expect(s1.map((e) => e.ratingKey).toSet(), {'ep1', 'ep2'});

      final s2 = await db.getEpisodesBySeason('season2');
      expect(s2.map((e) => e.ratingKey).toSet(), {'ep3'});

      expect(await db.getEpisodesBySeason('seasonZ'), isEmpty);
    });

    test('getEpisodesByShow filters by grandparentRatingKey', () async {
      await seedTree();

      final all = await db.getEpisodesByShow('show1');
      expect(all.map((e) => e.ratingKey).toSet(), {'ep1', 'ep2', 'ep3'});

      expect(await db.getEpisodesByShow('show-missing'), isEmpty);
    });

    test('getDownloadsByServerId filters by serverId', () async {
      await seedTree();

      final a = await db.getDownloadsByServerId('srvA');
      expect(a.map((e) => e.ratingKey).toSet(), {'ep1', 'ep2', 'ep3'});

      final b = await db.getDownloadsByServerId('srvB');
      expect(b.map((e) => e.ratingKey).toSet(), {'movie1'});

      expect(await db.getDownloadsByServerId('srvZ'), isEmpty);
    });
  });

  // ============================================================
  // deleteDownload — removes from both tables
  // ============================================================

  group('deleteDownload', () {
    test('removes the row from downloadedMedia AND its queue entry', () async {
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '100',
        globalKey: 'srv:100',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.addToQueue(mediaGlobalKey: 'srv:100');
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '200',
        globalKey: 'srv:200',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.addToQueue(mediaGlobalKey: 'srv:200');

      await db.deleteDownload('srv:100');

      final media = await db.select(db.downloadedMedia).get();
      expect(media.map((m) => m.globalKey).toList(), ['srv:200']);

      final queue = await db.select(db.downloadQueue).get();
      expect(queue.map((q) => q.mediaGlobalKey).toList(), ['srv:200']);
    });

    test('deleteDownload on a missing globalKey is a no-op', () async {
      // Should not throw.
      await db.deleteDownload('nope:nope');
      expect(await db.select(db.downloadedMedia).get(), isEmpty);
      expect(await db.select(db.downloadQueue).get(), isEmpty);
    });
  });
}
