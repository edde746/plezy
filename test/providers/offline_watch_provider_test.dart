import 'package:drift/native.dart';
import 'package:plezy/media/ids.dart';
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

    downloadManager = DownloadManagerService(
      database: db,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => null,
    );
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
    test('getNextUnwatchedEpisode returns null for show with no downloads', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);
      expect(await p.getNextUnwatchedEpisode('show-123'), isNull);
      p.dispose();
    });

    test('markAsWatched queues an offline action and notifies', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);

      var notified = 0;
      p.addListener(() => notified++);

      await p.markAsWatched(serverId: ServerId('srv'), itemId: '50');

      // The local watch status now reads as true via the sync service.
      expect(await syncService.getLocalWatchStatus('srv:50'), isTrue);
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('markAsUnwatched queues an offline action and notifies', () async {
      final p = OfflineWatchProvider(syncService: syncService, downloadProvider: downloadProvider);

      await p.markAsUnwatched(serverId: ServerId('srv'), itemId: '60');
      expect(await syncService.getLocalWatchStatus('srv:60'), isFalse);

      p.dispose();
    });
  });
}
