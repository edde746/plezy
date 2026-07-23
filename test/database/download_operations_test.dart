import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:plezy/media/ids.dart';
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
        serverId: ServerId('srv'),
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
        serverId: ServerId('srv'),
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

    test('atomically updates metadata and attempt state while preserving the row and physical fields', () async {
      await db.insertDownload(
        serverId: ServerId('srv'),
        clientScopeId: 'scope-old',
        ratingKey: '100',
        globalKey: 'srv:100',
        type: 'movie',
        status: DownloadStatus.queued.index,
        mediaIndex: 1,
        mediaSourceId: 'source-old',
      );
      final original = (await db.getDownloadedMedia('srv:100'))!;
      await (db.update(db.downloadedMedia)..where((row) => row.globalKey.equals('srv:100'))).write(
        const DownloadedMediaCompanion(
          progress: Value(50),
          downloadedBytes: Value(500),
          totalBytes: Value(1000),
          videoFilePath: Value('downloads/video.mkv'),
          safRootUri: Value('content://downloads'),
          thumbPath: Value('downloads/thumb.jpg'),
          downloadedAt: Value(1234),
          errorMessage: Value('old error'),
          retryCount: Value(2),
          bgTaskId: Value('current-task'),
        ),
      );

      await db.insertDownload(
        serverId: ServerId('srv-new'),
        clientScopeId: 'scope-new',
        ratingKey: '100-new',
        globalKey: 'srv:100',
        type: 'episode',
        parentRatingKey: 'season-new',
        grandparentRatingKey: 'show-new',
        status: DownloadStatus.failed.index,
        mediaIndex: 3,
        mediaSourceId: 'source-new',
      );

      final row = (await db.select(db.downloadedMedia).get()).single;
      expect(row.id, original.id);
      expect(row.serverId, 'srv-new');
      expect(row.clientScopeId, 'scope-new');
      expect(row.ratingKey, '100-new');
      expect(row.type, 'episode');
      expect(row.parentRatingKey, 'season-new');
      expect(row.grandparentRatingKey, 'show-new');
      expect(row.status, DownloadStatus.failed.index);
      expect(row.mediaIndex, 3);
      expect(row.mediaSourceId, 'source-new');
      expect(row.progress, 0);
      expect(row.downloadedBytes, 0);
      expect(row.totalBytes, isNull);
      expect(row.errorMessage, isNull);
      expect(row.retryCount, 0);
      expect(row.videoFilePath, 'downloads/video.mkv');
      expect(row.safRootUri, 'content://downloads');
      expect(row.thumbPath, 'downloads/thumb.jpg');
      expect(row.downloadedAt, 1234);
      expect(row.bgTaskId, 'current-task');
    });
  });

  group('insertQueuedDownload', () {
    test('atomically persists media identity, scope, policy, and queue state', () async {
      final tempDir = await Directory.systemTemp.createTemp('plezy_atomic_queue_');
      final databaseFile = File('${tempDir.path}/downloads.sqlite');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(databaseFile));
      final outcome = await db.insertQueuedDownload(
        serverId: ServerId('srv'),
        clientScopeId: 'srv/user-a',
        ratingKey: 'episode-1',
        globalKey: 'srv:episode-1',
        type: 'episode',
        parentRatingKey: 'season-1',
        grandparentRatingKey: 'show-1',
        mediaIndex: 3,
        mediaSourceId: 'source-3',
        priority: 7,
        downloadSubtitles: false,
        downloadArtwork: true,
      );
      expect(outcome, QueueDownloadOutcome.admitted);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(databaseFile));

      final media = (await db.select(db.downloadedMedia).get()).single;
      final queued = (await db.select(db.downloadQueue).get()).single;
      expect(media.serverId, 'srv');
      expect(media.clientScopeId, 'srv/user-a');
      expect(media.ratingKey, 'episode-1');
      expect(media.parentRatingKey, 'season-1');
      expect(media.grandparentRatingKey, 'show-1');
      expect(media.status, DownloadStatus.queued.index);
      expect(media.mediaIndex, 3);
      expect(media.mediaSourceId, 'source-3');
      expect(queued.mediaGlobalKey, media.globalKey);
      expect(queued.priority, 7);
      expect(queued.downloadSubtitles, isFalse);
      expect(queued.downloadArtwork, isTrue);
    });

    test('requeues retryable rows without replacing identity or physical fields', () async {
      await db.insertDownload(
        serverId: ServerId('srv'),
        clientScopeId: 'scope-original',
        ratingKey: 'existing',
        globalKey: 'srv:existing',
        type: 'movie',
        parentRatingKey: 'season-original',
        grandparentRatingKey: 'show-original',
        status: DownloadStatus.failed.index,
        mediaIndex: 2,
        mediaSourceId: 'source-original',
      );
      final original = (await db.getDownloadedMedia('srv:existing'))!;
      await (db.update(db.downloadedMedia)..where((row) => row.globalKey.equals('srv:existing'))).write(
        const DownloadedMediaCompanion(
          progress: Value(41),
          downloadedBytes: Value(410),
          totalBytes: Value(1000),
          videoFilePath: Value('downloads/video.mkv'),
          safRootUri: Value('content://downloads'),
          thumbPath: Value('downloads/thumb.jpg'),
          downloadedAt: Value(1234),
          errorMessage: Value('network error'),
          retryCount: Value(3),
          bgTaskId: Value('stale-task'),
        ),
      );

      final outcome = await db.insertQueuedDownload(
        serverId: ServerId('different-server'),
        clientScopeId: 'scope-new',
        ratingKey: 'different-rating-key',
        globalKey: 'srv:existing',
        type: 'episode',
        parentRatingKey: 'season-new',
        grandparentRatingKey: 'show-new',
        mediaIndex: 9,
        mediaSourceId: 'source-new',
        priority: 4,
        downloadSubtitles: false,
        downloadArtwork: false,
      );

      expect(outcome, QueueDownloadOutcome.admitted);
      final requeued = (await db.getDownloadedMedia('srv:existing'))!;
      expect(requeued.id, original.id);
      expect(requeued.serverId, 'different-server');
      expect(requeued.clientScopeId, 'scope-new');
      expect(requeued.ratingKey, 'different-rating-key');
      expect(requeued.type, 'episode');
      expect(requeued.parentRatingKey, 'season-new');
      expect(requeued.grandparentRatingKey, 'show-new');
      expect(requeued.mediaIndex, 9);
      expect(requeued.mediaSourceId, 'source-new');
      expect(requeued.status, DownloadStatus.queued.index);
      expect(requeued.progress, 0);
      expect(requeued.downloadedBytes, 0);
      expect(requeued.totalBytes, isNull);
      expect(requeued.errorMessage, isNull);
      expect(requeued.retryCount, 0);
      expect(requeued.bgTaskId, isNull);
      expect(requeued.videoFilePath, 'downloads/video.mkv');
      expect(requeued.safRootUri, 'content://downloads');
      expect(requeued.thumbPath, 'downloads/thumb.jpg');
      expect(requeued.downloadedAt, 1234);
      final queue = (await db.select(db.downloadQueue).get()).single;
      expect(queue.priority, 4);
      expect(queue.downloadSubtitles, isFalse);
      expect(queue.downloadArtwork, isFalse);
    });

    test('admits cancelled and partial rows for a fresh attempt', () async {
      for (final status in [DownloadStatus.cancelled, DownloadStatus.partial]) {
        final key = 'srv:${status.name}';
        await db.insertDownload(
          serverId: ServerId('srv'),
          ratingKey: status.name,
          globalKey: key,
          type: 'movie',
          status: status.index,
        );
        await db.updateDownloadProgress(key, 75, 750, 1000);
        await db.updateDownloadError(key, 'old failure');

        expect(
          await db.insertQueuedDownload(
            serverId: ServerId('srv'),
            ratingKey: status.name,
            globalKey: key,
            type: 'movie',
          ),
          QueueDownloadOutcome.admitted,
        );
        final row = (await db.getDownloadedMedia(key))!;
        expect(row.status, DownloadStatus.queued.index);
        expect(row.progress, 0);
        expect(row.downloadedBytes, 0);
        expect(row.totalBytes, isNull);
        expect(row.errorMessage, isNull);
        expect(row.retryCount, 0);
      }
      expect(await db.select(db.downloadQueue).get(), hasLength(2));
    });

    test('preserves active, paused, and completed rows without creating queue work', () async {
      for (final status in [DownloadStatus.downloading, DownloadStatus.paused, DownloadStatus.completed]) {
        final key = 'srv:${status.name}';
        await db.insertDownload(
          serverId: ServerId('srv'),
          ratingKey: status.name,
          globalKey: key,
          type: 'movie',
          status: status.index,
        );
        await db.updateDownloadProgress(key, 63, 630, 1000);
        final before = (await db.getDownloadedMedia(key))!;

        expect(
          await db.insertQueuedDownload(
            serverId: ServerId('other'),
            ratingKey: 'replacement',
            globalKey: key,
            type: 'episode',
            priority: 9,
          ),
          QueueDownloadOutcome.unchanged,
        );
        expect(await db.getDownloadedMedia(key), before);
      }
      expect(await db.select(db.downloadQueue).get(), isEmpty);
    });

    test('refreshes policy for an already queued row without rewriting media', () async {
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'queued',
        globalKey: 'srv:queued',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.updateDownloadProgress('srv:queued', 12, 120, 1000);
      await db.addToQueue(mediaGlobalKey: 'srv:queued', priority: 1);
      final before = (await db.getDownloadedMedia('srv:queued'))!;

      final outcome = await db.insertQueuedDownload(
        serverId: ServerId('other'),
        ratingKey: 'replacement',
        globalKey: 'srv:queued',
        type: 'episode',
        priority: 8,
        downloadSubtitles: false,
        downloadArtwork: false,
      );

      expect(outcome, QueueDownloadOutcome.alreadyQueued);
      expect(await db.getDownloadedMedia('srv:queued'), before);
      final queue = (await db.select(db.downloadQueue).get()).single;
      expect(queue.priority, 8);
      expect(queue.downloadSubtitles, isFalse);
      expect(queue.downloadArtwork, isFalse);
    });

    test('a state advance during retry admission wins over the stale requeue', () async {
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'race',
        globalKey: 'srv:race',
        type: 'movie',
        status: DownloadStatus.failed.index,
      );
      await db.customStatement('''
        CREATE TRIGGER advance_retry_state
        BEFORE UPDATE OF status ON downloaded_media
        WHEN OLD.global_key = 'srv:race'
          AND OLD.status = ${DownloadStatus.failed.index}
          AND NEW.status = ${DownloadStatus.queued.index}
        BEGIN
          UPDATE downloaded_media
          SET status = ${DownloadStatus.downloading.index}
          WHERE id = OLD.id;
          SELECT RAISE(IGNORE);
        END
      ''');

      final outcome = await db.insertQueuedDownload(
        serverId: ServerId('srv'),
        ratingKey: 'race',
        globalKey: 'srv:race',
        type: 'movie',
      );

      expect(outcome, QueueDownloadOutcome.unchanged);
      expect((await db.getDownloadedMedia('srv:race'))?.status, DownloadStatus.downloading.index);
      expect(await db.select(db.downloadQueue).get(), isEmpty);
    });

    test('rolls back both new and replacement media rows when queue insertion fails', () async {
      final tempDir = await Directory.systemTemp.createTemp('plezy_atomic_rollback_');
      final databaseFile = File('${tempDir.path}/downloads.sqlite');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(databaseFile));
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'existing',
        globalKey: 'srv:existing',
        type: 'movie',
        status: DownloadStatus.failed.index,
      );
      await db.updateDownloadProgress('srv:existing', 41, 410, 1000);
      await db.customStatement('''
        CREATE TRIGGER reject_download_queue_insert
        BEFORE INSERT ON download_queue
        BEGIN
          SELECT RAISE(ABORT, 'queue insert rejected');
        END
      ''');

      await expectLater(
        db.insertQueuedDownload(serverId: ServerId('srv'), ratingKey: 'new', globalKey: 'srv:new', type: 'movie'),
        throwsA(anything),
      );
      expect(await db.getDownloadedMedia('srv:new'), isNull);
      expect(await (db.select(db.downloadQueue)..where((row) => row.mediaGlobalKey.equals('srv:new'))).get(), isEmpty);

      await expectLater(
        db.insertQueuedDownload(
          serverId: ServerId('srv'),
          ratingKey: 'existing',
          globalKey: 'srv:existing',
          type: 'movie',
        ),
        throwsA(anything),
      );
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(databaseFile));
      expect(await db.getDownloadedMedia('srv:new'), isNull);
      expect(await (db.select(db.downloadQueue)..where((row) => row.mediaGlobalKey.equals('srv:new'))).get(), isEmpty);
      final preserved = await db.getDownloadedMedia('srv:existing');
      expect(preserved?.status, DownloadStatus.failed.index);
      expect(preserved?.progress, 41);
      expect(preserved?.downloadedBytes, 410);
      expect(
        await (db.select(db.downloadQueue)..where((row) => row.mediaGlobalKey.equals('srv:existing'))).get(),
        isEmpty,
      );
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
        serverId: ServerId('srv'),
        ratingKey: '1',
        globalKey: 'srv:1',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.insertDownload(
        serverId: ServerId('srv'),
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
        serverId: ServerId('srv'),
        ratingKey: '1',
        globalKey: 'srv:1',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: '2',
        globalKey: 'srv:2',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.insertDownload(
        serverId: ServerId('srv'),
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

    test('repairs only missing queued rows and preserves existing queue policy', () async {
      Future<void> seedMedia(String key, DownloadStatus status) {
        return db.insertDownload(
          serverId: ServerId('srv'),
          ratingKey: key.substring('srv:'.length),
          globalKey: key,
          type: 'movie',
          status: status.index,
        );
      }

      await seedMedia('srv:missing', DownloadStatus.queued);
      await seedMedia('srv:custom', DownloadStatus.queued);
      await seedMedia('srv:downloading', DownloadStatus.downloading);
      const customAddedAt = 123456;
      await db
          .into(db.downloadQueue)
          .insert(
            DownloadQueueCompanion.insert(
              mediaGlobalKey: 'srv:custom',
              priority: const Value(-1),
              addedAt: customAddedAt,
              downloadSubtitles: const Value(false),
              downloadArtwork: const Value(false),
            ),
          );
      await db.addToQueue(mediaGlobalKey: 'srv:orphan', priority: 9);

      expect(await db.repairMissingQueuedDownloadEntries(), 1);
      expect(await db.repairMissingQueuedDownloadEntries(), 0);

      final queueRows = {for (final row in await db.select(db.downloadQueue).get()) row.mediaGlobalKey: row};
      expect(queueRows.keys, {'srv:missing', 'srv:custom', 'srv:orphan'});
      final repaired = queueRows['srv:missing']!;
      expect(repaired.priority, 0);
      expect(repaired.downloadSubtitles, isTrue);
      expect(repaired.downloadArtwork, isTrue);
      final custom = queueRows['srv:custom']!;
      expect(custom.priority, -1);
      expect(custom.addedAt, customAddedAt);
      expect(custom.downloadSubtitles, isFalse);
      expect(custom.downloadArtwork, isFalse);
      expect(queueRows['srv:orphan']?.priority, 9);
      expect(await db.getNextQueueItem(), isNotNull);
      expect((await db.getNextQueueItem())?.mediaGlobalKey, 'srv:missing');
    });

    test('supplementary query returns only completed videos without making them primary work', () async {
      Future<void> seedMedia(String key, DownloadStatus status, {bool video = false}) async {
        await db.insertDownload(
          serverId: ServerId('srv'),
          ratingKey: key.substring('srv:'.length),
          globalKey: key,
          type: 'movie',
          status: status.index,
        );
        if (video) await db.updateVideoFilePath(key, 'downloads/${key.substring(4)}/video.mkv');
        await db.addToQueue(
          mediaGlobalKey: key,
          priority: key == 'srv:queued' ? 5 : 0,
          downloadSubtitles: key == 'srv:completed-video',
          downloadArtwork: false,
        );
      }

      await seedMedia('srv:queued', DownloadStatus.queued);
      await seedMedia('srv:downloading', DownloadStatus.downloading);
      await seedMedia('srv:completed-video', DownloadStatus.completed, video: true);
      await seedMedia('srv:completed-no-video', DownloadStatus.completed);

      final pending = await db.getPendingSupplementaryQueueItems();
      expect(pending, hasLength(1));
      expect(pending.single.mediaGlobalKey, 'srv:completed-video');
      expect(pending.single.downloadSubtitles, isTrue);
      expect(pending.single.downloadArtwork, isFalse);
      expect((await db.getNextQueueItem())?.mediaGlobalKey, 'srv:queued');

      await db.removeFromQueue('srv:completed-video');
      expect(await db.getPendingSupplementaryQueueItems(), isEmpty);
      await db.addToQueue(mediaGlobalKey: 'srv:completed-video');
      await db.deleteDownload('srv:completed-video');
      expect(
        await (db.select(db.downloadQueue)..where((row) => row.mediaGlobalKey.equals('srv:completed-video'))).get(),
        isEmpty,
      );
    });
  });

  // ============================================================
  // Update helpers
  // ============================================================

  group('update helpers', () {
    Future<void> seed({String key = 'srv:100'}) async {
      await db.insertDownload(
        serverId: ServerId(key.split(':').first),
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

    test('SAF root assignment and reference queries track physical rows', () async {
      await seed(key: 'srv:100');
      await seed(key: 'srv:200');

      await db.updateDownloadSafRoot('srv:100', 'content://root-a');
      await db.updateDownloadSafRoot('srv:200', 'content://root-a');
      expect(await db.countDownloadsReferencingSafRoot('content://root-a'), 2);
      expect(await db.getReferencedDownloadSafRoots(), {'content://root-a'});

      await db.updateDownloadSafRoot('srv:200', 'content://root-b');
      expect(await db.countDownloadsReferencingSafRoot('content://root-a'), 1);
      expect(await db.countDownloadsReferencingSafRoot('content://root-b'), 1);
      expect(await db.getReferencedDownloadSafRoots(), {'content://root-a', 'content://root-b'});

      await db.updateDownloadSafRoot('srv:100', null);
      expect(await db.countDownloadsReferencingSafRoot('content://root-a'), 0);
      expect(await db.getReferencedDownloadSafRoots(), {'content://root-b'});
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
        serverId: ServerId('srvA'),
        ratingKey: 'ep1',
        globalKey: 'srvA:ep1',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('srvA'),
        ratingKey: 'ep2',
        globalKey: 'srvA:ep2',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('srvA'),
        ratingKey: 'ep3',
        globalKey: 'srvA:ep3',
        type: 'episode',
        parentRatingKey: 'season2',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('srvB'),
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

    test('getEpisodesBySeason can filter by server and client scope', () async {
      await db.insertDownload(
        serverId: ServerId('jf'),
        clientScopeId: 'jf/user-a',
        ratingKey: 'ep-a',
        globalKey: 'jf:ep-a',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('jf'),
        clientScopeId: 'jf/user-b',
        ratingKey: 'ep-b',
        globalKey: 'jf:ep-b',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('other'),
        ratingKey: 'ep-other',
        globalKey: 'other:ep-other',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('other'),
        clientScopeId: 'other/user-a',
        ratingKey: 'ep-other-scoped',
        globalKey: 'other:ep-other-scoped',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );

      final userA = await db.getEpisodesBySeason('season1', serverId: ServerId('jf'), clientScopeId: 'jf/user-a');
      final unscoped = await db.getEpisodesBySeason('season1', serverId: ServerId('other'), filterClientScope: true);

      expect(userA.map((e) => e.ratingKey), ['ep-a']);
      expect(unscoped.map((e) => e.ratingKey), ['ep-other']);
    });

    test('getEpisodesByShow filters by grandparentRatingKey', () async {
      await seedTree();

      final all = await db.getEpisodesByShow('show1');
      expect(all.map((e) => e.ratingKey).toSet(), {'ep1', 'ep2', 'ep3'});

      expect(await db.getEpisodesByShow('show-missing'), isEmpty);
    });

    test('getEpisodesByShow can filter by server and client scope', () async {
      await db.insertDownload(
        serverId: ServerId('jf'),
        clientScopeId: 'jf/user-a',
        ratingKey: 'ep-a',
        globalKey: 'jf:ep-a',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('jf'),
        clientScopeId: 'jf/user-b',
        ratingKey: 'ep-b',
        globalKey: 'jf:ep-b',
        type: 'episode',
        parentRatingKey: 'season1',
        grandparentRatingKey: 'show1',
        status: DownloadStatus.completed.index,
      );

      final userB = await db.getEpisodesByShow('show1', serverId: ServerId('jf'), clientScopeId: 'jf/user-b');

      expect(userB.map((e) => e.ratingKey), ['ep-b']);
    });

    Future<void> seedMusic() async {
      await db.insertDownload(
        serverId: ServerId('srvA'),
        ratingKey: 'track1',
        globalKey: 'srvA:track1',
        type: 'track',
        parentRatingKey: 'album1',
        grandparentRatingKey: 'artist1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('srvA'),
        ratingKey: 'track2',
        globalKey: 'srvA:track2',
        type: 'track',
        parentRatingKey: 'album1',
        grandparentRatingKey: 'artist1',
        status: DownloadStatus.completed.index,
      );
      await db.insertDownload(
        serverId: ServerId('srvA'),
        ratingKey: 'track3',
        globalKey: 'srvA:track3',
        type: 'track',
        parentRatingKey: 'album2',
        grandparentRatingKey: 'artist1',
        status: DownloadStatus.completed.index,
      );
      // Episode sharing the album's parent key must not leak into track
      // queries (type filter).
      await db.insertDownload(
        serverId: ServerId('srvA'),
        ratingKey: 'ep-collide',
        globalKey: 'srvA:ep-collide',
        type: 'episode',
        parentRatingKey: 'album1',
        grandparentRatingKey: 'artist1',
        status: DownloadStatus.completed.index,
      );
      // Same album key on another server.
      await db.insertDownload(
        serverId: ServerId('srvB'),
        ratingKey: 'track-b',
        globalKey: 'srvB:track-b',
        type: 'track',
        parentRatingKey: 'album1',
        grandparentRatingKey: 'artist1',
        status: DownloadStatus.completed.index,
      );
    }

    test('getTracksByAlbum filters by parentRatingKey and type', () async {
      await seedMusic();

      final album1 = await db.getTracksByAlbum('album1');
      expect(album1.map((e) => e.globalKey).toSet(), {'srvA:track1', 'srvA:track2', 'srvB:track-b'});

      final album1SrvA = await db.getTracksByAlbum('album1', serverId: ServerId('srvA'));
      expect(album1SrvA.map((e) => e.ratingKey).toSet(), {'track1', 'track2'});

      expect(await db.getTracksByAlbum('albumZ'), isEmpty);
    });

    test('getTracksByArtist filters by grandparentRatingKey and type', () async {
      await seedMusic();

      final artist = await db.getTracksByArtist('artist1', serverId: ServerId('srvA'));
      expect(artist.map((e) => e.ratingKey).toSet(), {'track1', 'track2', 'track3'});

      expect(await db.getTracksByArtist('artist-missing'), isEmpty);
    });

    test('getDownloadsByServerId filters by serverId', () async {
      await seedTree();

      final a = await db.getDownloadsByServerId(ServerId('srvA'));
      expect(a.map((e) => e.ratingKey).toSet(), {'ep1', 'ep2', 'ep3'});

      final b = await db.getDownloadsByServerId(ServerId('srvB'));
      expect(b.map((e) => e.ratingKey).toSet(), {'movie1'});

      expect(await db.getDownloadsByServerId(ServerId('srvZ')), isEmpty);
    });
  });

  // ============================================================
  // Download owners
  // ============================================================

  group('download owners', () {
    Future<void> insertProfile(String id) async {
      await db
          .into(db.profiles)
          .insert(ProfilesCompanion.insert(id: id, kind: 'local', displayName: id, configJson: '{}', createdAt: 0));
    }

    Future<void> insertPlexConnection(String id) async {
      await db
          .into(db.connections)
          .insert(ConnectionsCompanion.insert(id: id, kind: 'plex', displayName: id, configJson: '{}', createdAt: 0));
    }

    test('repeated claims preserve creation time and omitted metadata', () async {
      await db
          .into(db.downloadOwners)
          .insert(
            DownloadOwnersCompanion.insert(
              profileId: 'profile-a',
              globalKey: 'srv:100',
              backend: const Value('plex'),
              clientScopeId: const Value('scope-a'),
              createdAt: 1234,
            ),
          );

      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv:100');
      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv:100');

      final owner = (await db.select(db.downloadOwners).get()).single;
      expect(owner.createdAt, 1234);
      expect(owner.backend, 'plex');
      expect(owner.clientScopeId, 'scope-a');
    });

    test('repeated claims upgrade each supplied non-null metadata field', () async {
      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv:100');
      final createdAt = (await db.select(db.downloadOwners).get()).single.createdAt;

      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv:100', backendId: 'jellyfin');
      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv:100', clientScopeId: 'srv/user-a');

      final owner = (await db.select(db.downloadOwners).get()).single;
      expect(owner.createdAt, createdAt);
      expect(owner.backend, 'jellyfin');
      expect(owner.clientScopeId, 'srv/user-a');
    });

    test('owner counts ignore orphan local profiles', () async {
      await insertProfile('profile-a');
      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv:100');
      await db.addDownloadOwner(profileId: 'profile-deleted', globalKey: 'srv:100');

      expect(await db.getDownloadOwnerCount('srv:100'), 1);
      expect(await db.hasDownloadOwner('srv:100', excludingProfileId: 'profile-a'), isFalse);
    });

    test('owner counts preserve virtual Plex Home profile ids', () async {
      const plexHomeProfileId = 'plex-home-account-1-00000000-0000-0000-0000-000000000001';
      await insertPlexConnection('account-1');
      await db.addDownloadOwner(profileId: plexHomeProfileId, globalKey: 'srv:100');

      expect(await db.getDownloadOwnerCount('srv:100'), 1);
      expect(await db.hasDownloadOwner('srv:100'), isTrue);
    });

    test('owner counts ignore Plex Home rows whose parent connection is gone', () async {
      const plexHomeProfileId = 'plex-home-missing-account-00000000-0000-0000-0000-000000000001';
      await db.addDownloadOwner(profileId: plexHomeProfileId, globalKey: 'srv:100');

      expect(await db.getDownloadOwnerCount('srv:100'), 0);
      expect(await db.hasDownloadOwner('srv:100'), isFalse);
    });
  });

  // ============================================================
  // deleteDownload — removes from both tables
  // ============================================================

  group('deleteDownload', () {
    test('removes the row from downloadedMedia AND its queue entry', () async {
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: '100',
        globalKey: 'srv:100',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.addToQueue(mediaGlobalKey: 'srv:100');
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: '200',
        globalKey: 'srv:200',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.addToQueue(mediaGlobalKey: 'srv:200');

      await db.updateDownloadSafRoot('srv:100', 'content://root-a');
      final removedRoot = await db.deleteDownload('srv:100');
      expect(removedRoot, 'content://root-a');

      final media = await db.select(db.downloadedMedia).get();
      expect(media.map((m) => m.globalKey).toList(), ['srv:200']);

      final queue = await db.select(db.downloadQueue).get();
      expect(queue.map((q) => q.mediaGlobalKey).toList(), ['srv:200']);
    });

    test('deleteDownload on a missing globalKey is a no-op', () async {
      // Should not throw.
      expect(await db.deleteDownload('nope:nope'), isNull);
      expect(await db.select(db.downloadedMedia).get(), isEmpty);
      expect(await db.select(db.downloadQueue).get(), isEmpty);
    });
  });
}
