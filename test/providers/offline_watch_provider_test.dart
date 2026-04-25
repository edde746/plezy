import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/offline_watch_provider.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/plex_api_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MultiServerManager serverManager;
  late OfflineWatchSyncService syncService;
  late DownloadManagerService downloadManager;
  late DownloadProvider downloadProvider;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    serverManager = MultiServerManager();
    syncService = OfflineWatchSyncService(database: db, serverManager: serverManager);

    downloadManager = DownloadManagerService(database: db, storageService: DownloadStorageService.instance);
    downloadManager.recoveryFuture = Future<void>.value();
    downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await downloadProvider.ensureInitialized();
  });

  tearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    syncService.dispose();
    serverManager.dispose();
    await db.close();
  });

  group('OfflineWatchProvider', () {
    test('initial isSyncing reflects sync service state', () {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);
      expect(p.isSyncing, isFalse);
      expect(syncService.isSyncing, isFalse);
      p.dispose();
    });

    test('getPendingSyncCount delegates to sync service (initially 0)', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);
      expect(await p.getPendingSyncCount(), 0);
      p.dispose();
    });

    test('isWatched returns false when no local action and no metadata', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);
      expect(await p.isWatched('srv:absent'), isFalse);
      p.dispose();
    });

    test('getViewOffset returns null when no local progress and no metadata', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);
      expect(await p.getViewOffset('srv:absent'), isNull);
      p.dispose();
    });

    test('getNextUnwatchedEpisode returns null for show with no downloads', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);
      expect(await p.getNextUnwatchedEpisode('show-123'), isNull);
      p.dispose();
    });

    test('getEpisodesWithWatchStatus returns empty list for show with no downloads', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);
      expect(await p.getEpisodesWithWatchStatus('show-123'), isEmpty);
      p.dispose();
    });

    test('forwards listener notifications from sync service', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);

      var notified = 0;
      p.addListener(() => notified++);

      // queueMarkWatched on the sync service notifies its listeners; the
      // provider's internal listener forwards via safeNotifyListeners.
      await syncService.queueMarkWatched(serverId: 'srv', ratingKey: '42');
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('markAsWatched queues an offline action and notifies', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);

      var notified = 0;
      p.addListener(() => notified++);

      await p.markAsWatched(serverId: 'srv', ratingKey: '50');

      // The local watch status now reads as true via the sync service.
      expect(await p.isWatched('srv:50'), isTrue);
      // At least one notification: from sync service forwarding + provider's
      // explicit safeNotifyListeners after queueing.
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('markAsUnwatched queues an offline action and notifies', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);

      await p.markAsUnwatched(serverId: 'srv', ratingKey: '60');
      expect(await p.isWatched('srv:60'), isFalse);

      p.dispose();
    });

    test('dispose removes the sync service listener', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);

      var notified = 0;
      p.addListener(() => notified++);

      // Sanity: listener is registered
      await syncService.queueMarkWatched(serverId: 'srv', ratingKey: '70');
      final preDisposeNotifies = notified;
      expect(preDisposeNotifies, greaterThanOrEqualTo(1));

      p.dispose();

      // After dispose, sync service notifications should not call our
      // listener (provider unsubscribed). Mutating the sync service post-
      // dispose must not throw on the provider side.
      await syncService.queueMarkUnwatched(serverId: 'srv', ratingKey: '70');
      expect(notified, preDisposeNotifies);
    });
  });
}
