import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/plex_api_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DownloadManagerService downloadManager;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // PlexApiCache is a singleton accessed eagerly inside DownloadManagerService's
    // constructor; reinitialize per test so each test sees the fresh in-memory DB.
    PlexApiCache.initialize(db);
    downloadManager = DownloadManagerService(database: db, storageService: DownloadStorageService.instance);
    // recoveryFuture is `late final` and would otherwise be unset; we never
    // exercise the recovery path in these tests but the field must be safe
    // to await. Set to a completed future.
    downloadManager.recoveryFuture = Future<void>.value();
  });

  tearDown(() async {
    downloadManager.dispose();
    await db.close();
  });

  group('DownloadProvider — initial state', () {
    test('starts with empty downloads/metadata maps and no sync rules', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      expect(p.downloads, isEmpty);
      expect(p.metadata, isEmpty);
      expect(p.syncRules, isEmpty);
      expect(p.downloadedShows, isEmpty);
      expect(p.downloadedMovies, isEmpty);
      expect(p.getMetadata('srv:none'), isNull);
      expect(p.getProgress('srv:none'), isNull);
      expect(p.isDownloaded('srv:none'), isFalse);
      expect(p.isDownloading('srv:none'), isFalse);
      expect(p.isQueued('srv:none'), isFalse);
      expect(p.isQueueing('srv:none'), isFalse);
      expect(p.hasSyncRule('srv:none'), isFalse);
      expect(p.getSyncRule('srv:none'), isNull);

      p.dispose();
    });

    test('downloads / metadata getters return unmodifiable views', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      expect(() => p.downloads.clear(), throwsUnsupportedError);
      expect(() => p.metadata.clear(), throwsUnsupportedError);
      expect(() => p.syncRules.clear(), throwsUnsupportedError);

      p.dispose();
    });
  });

  group('DownloadProvider — sync rule CRUD', () {
    test('createSyncRule inserts into the database and updates the in-memory map', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      var notified = 0;
      p.addListener(() => notified++);

      await p.createSyncRule(serverId: 'srv', ratingKey: '10', targetType: 'show', episodeCount: 5);

      expect(p.hasSyncRule('srv:10'), isTrue);
      final rule = p.getSyncRule('srv:10');
      expect(rule, isNotNull);
      expect(rule!.targetType, 'show');
      expect(rule.episodeCount, 5);
      expect(rule.enabled, isTrue);
      expect(rule.downloadFilter, 'unwatched'); // default
      // Database state matches in-memory state.
      final dbRule = await db.getSyncRule('srv:10');
      expect(dbRule, isNotNull);
      expect(dbRule!.targetType, 'show');

      // createSyncRule notifies once on success.
      expect(notified, 1);

      p.dispose();
    });

    test('updateSyncRuleCount mutates rule and notifies', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: 'srv', ratingKey: '10', targetType: 'show', episodeCount: 5);

      var notified = 0;
      p.addListener(() => notified++);

      await p.updateSyncRuleCount('srv:10', 12);
      expect(p.getSyncRule('srv:10')!.episodeCount, 12);
      expect((await db.getSyncRule('srv:10'))!.episodeCount, 12);
      expect(notified, 1);

      p.dispose();
    });

    test('updateSyncRuleFilter mutates filter and notifies', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: 'srv', ratingKey: '10', targetType: 'collection', episodeCount: 0);

      var notified = 0;
      p.addListener(() => notified++);

      await p.updateSyncRuleFilter('srv:10', 'all');
      expect(p.getSyncRule('srv:10')!.downloadFilter, 'all');
      expect(notified, 1);

      p.dispose();
    });

    test('setSyncRuleEnabled toggles enabled flag', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: 'srv', ratingKey: '10', targetType: 'show', episodeCount: 5);
      expect(p.getSyncRule('srv:10')!.enabled, isTrue);

      await p.setSyncRuleEnabled('srv:10', false);
      expect(p.getSyncRule('srv:10')!.enabled, isFalse);
      expect((await db.getSyncRule('srv:10'))!.enabled, isFalse);

      await p.setSyncRuleEnabled('srv:10', true);
      expect(p.getSyncRule('srv:10')!.enabled, isTrue);

      p.dispose();
    });

    test('deleteSyncRule removes rule from db and memory and notifies', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: 'srv', ratingKey: '10', targetType: 'show', episodeCount: 5);
      await p.createSyncRule(serverId: 'srv', ratingKey: '11', targetType: 'show', episodeCount: 5);
      expect(p.syncRules, hasLength(2));

      var notified = 0;
      p.addListener(() => notified++);

      await p.deleteSyncRule('srv:10');
      expect(p.hasSyncRule('srv:10'), isFalse);
      expect(p.hasSyncRule('srv:11'), isTrue);
      expect(p.syncRules, hasLength(1));
      expect(await db.getSyncRule('srv:10'), isNull);
      expect(notified, 1);

      p.dispose();
    });

    test('forTesting load reads pre-existing sync rules from database', () async {
      // Pre-seed the database with a rule before the provider exists.
      await db.insertSyncRule(
        serverId: 'srv',
        ratingKey: '99',
        globalKey: 'srv:99',
        targetType: 'show',
        episodeCount: 7,
      );

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      expect(p.hasSyncRule('srv:99'), isTrue);
      expect(p.getSyncRule('srv:99')!.episodeCount, 7);

      p.dispose();
    });
  });

  group('DownloadProvider — getMetadata', () {
    test('getMetadata returns null for keys never observed', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      expect(p.getMetadata('srv:absent'), isNull);
      p.dispose();
    });
  });

  group('DownloadProvider — progress stream', () {
    test('exposes broadcast progress and deletion-progress streams', () async {
      // These streams are broadcast so the provider's subscription can co-
      // exist with other listeners (UI widgets, sync rule executor, etc.).
      expect(downloadManager.progressStream.isBroadcast, isTrue);
      expect(downloadManager.deletionProgressStream.isBroadcast, isTrue);
    });
  });

  group('DownloadProvider — dispose hygiene', () {
    test('dispose cancels stream subscriptions and is safe to call once', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      expect(p.dispose, returnsNormally);
    });

    test('isDisposed flips from false to true on dispose', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      expect(p.isDisposed, isFalse);
      p.dispose();
      expect(p.isDisposed, isTrue);
    });
  });

  group('DownloadProvider — DownloadFilter enum', () {
    test('DownloadFilter has all/unwatched values', () {
      expect(DownloadFilter.values, contains(DownloadFilter.all));
      expect(DownloadFilter.values, contains(DownloadFilter.unwatched));
    });
  });
}
