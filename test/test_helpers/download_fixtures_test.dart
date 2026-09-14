import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/download_models.dart';

import 'download_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

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
}
