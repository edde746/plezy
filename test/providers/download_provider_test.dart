import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/watch_state_notifier.dart';

/// Implements only [fetchPlayableDescendants] (the surface queueDownload
/// reaches via [collectEpisodesForShow] / [collectEpisodesForSeason]);
/// every other call falls through to noSuchMethod and trips a NoSuchMethodError.
class _ThrowingClient implements MediaServerClient {
  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    throw StateError('test: fetchPlayableDescendants intentionally fails');
  }

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScopedTestClient implements MediaServerClient, ScopedMediaServerClient {
  _ScopedTestClient({required this.serverId, required this.scopedServerId});

  @override
  final String serverId;

  @override
  final String scopedServerId;

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DownloadManagerService downloadManager;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // PlexApiCache is a singleton accessed eagerly inside DownloadManagerService's
    // constructor; reinitialize per test so each test sees the fresh in-memory DB.
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
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
      final ruleKey = p.syncRuleKeyFor('srv', '10');

      expect(p.hasSyncRule(ruleKey), isTrue);
      final rule = p.getSyncRule(ruleKey);
      expect(rule, isNotNull);
      expect(rule!.profileId, 'test-profile');
      expect(rule.targetType, 'show');
      expect(rule.episodeCount, 5);
      expect(rule.enabled, isTrue);
      expect(rule.downloadFilter, 'unwatched'); // default
      // Database state matches in-memory state.
      final dbRule = await db.getSyncRule(ruleKey);
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
      final ruleKey = p.syncRuleKeyFor('srv', '10');

      var notified = 0;
      p.addListener(() => notified++);

      await p.updateSyncRuleCount(ruleKey, 12);
      expect(p.getSyncRule(ruleKey)!.episodeCount, 12);
      expect((await db.getSyncRule(ruleKey))!.episodeCount, 12);
      expect(notified, 1);

      p.dispose();
    });

    test('updateSyncRuleFilter mutates filter and notifies', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: 'srv', ratingKey: '10', targetType: 'collection', episodeCount: 0);
      final ruleKey = p.syncRuleKeyFor('srv', '10');

      var notified = 0;
      p.addListener(() => notified++);

      await p.updateSyncRuleFilter(ruleKey, 'all');
      expect(p.getSyncRule(ruleKey)!.downloadFilter, 'all');
      expect(notified, 1);

      p.dispose();
    });

    test('setSyncRuleEnabled toggles enabled flag', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: 'srv', ratingKey: '10', targetType: 'show', episodeCount: 5);
      final ruleKey = p.syncRuleKeyFor('srv', '10');
      expect(p.getSyncRule(ruleKey)!.enabled, isTrue);

      await p.setSyncRuleEnabled(ruleKey, false);
      expect(p.getSyncRule(ruleKey)!.enabled, isFalse);
      expect((await db.getSyncRule(ruleKey))!.enabled, isFalse);

      await p.setSyncRuleEnabled(ruleKey, true);
      expect(p.getSyncRule(ruleKey)!.enabled, isTrue);

      p.dispose();
    });

    test('deleteSyncRule removes rule from db and memory and notifies', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: 'srv', ratingKey: '10', targetType: 'show', episodeCount: 5);
      await p.createSyncRule(serverId: 'srv', ratingKey: '11', targetType: 'show', episodeCount: 5);
      final ruleKey10 = p.syncRuleKeyFor('srv', '10');
      final ruleKey11 = p.syncRuleKeyFor('srv', '11');
      expect(p.syncRules, hasLength(2));

      var notified = 0;
      p.addListener(() => notified++);

      await p.deleteSyncRule(ruleKey10);
      expect(p.hasSyncRule(ruleKey10), isFalse);
      expect(p.hasSyncRule(ruleKey11), isTrue);
      expect(p.syncRules, hasLength(1));
      expect(await db.getSyncRule(ruleKey10), isNull);
      expect(notified, 1);

      p.dispose();
    });

    test('deleteSyncRule releases targetMetadata when no download holds it', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      // Collection rule with stashed metadata (the "no underlying episode
      // download to populate _metadata" case from createSyncRule's docs).
      final target = MediaItem(
        id: '20',
        backend: MediaBackend.plex,
        kind: MediaKind.collection,
        title: 'My Collection',
        serverId: 'srv',
      );
      await p.createSyncRule(
        serverId: 'srv',
        ratingKey: '20',
        targetType: 'collection',
        episodeCount: 0,
        targetMetadata: target,
      );
      expect(p.getMetadata('srv:20'), isNotNull, reason: 'targetMetadata should be stashed');

      await p.deleteSyncRule(p.syncRuleKeyFor('srv', '20'));
      expect(p.getMetadata('srv:20'), isNull, reason: 'orphan metadata should be released');

      p.dispose();
    });

    test('deleteSyncRule preserves metadata still referenced by a download', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final target = MediaItem(
        id: '30',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        title: 'A Show',
        serverId: 'srv',
      );
      await p.createSyncRule(
        serverId: 'srv',
        ratingKey: '30',
        targetType: 'show',
        episodeCount: 5,
        targetMetadata: target,
      );

      // Simulate an active/queued download under the same key — metadata is
      // still load-bearing and must not be evicted by deleteSyncRule.
      p.debugSeedState(
        downloads: {'srv:30': const DownloadProgress(globalKey: 'srv:30', status: DownloadStatus.queued)},
      );

      await p.deleteSyncRule(p.syncRuleKeyFor('srv', '30'));
      expect(p.getMetadata('srv:30'), isNotNull, reason: 'metadata is still in use by the download');

      p.dispose();
    });

    test('watch events target active-profile parent sync rules', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final keys = p.syncRuleKeysForWatchEvent(
        WatchStateEvent(
          itemId: 'episode-1',
          serverId: 'jf-machine',
          cacheServerId: 'jf-machine/user-a',
          changeType: WatchStateChangeType.watched,
          parentChain: const ['season-1', 'show-1'],
          mediaType: 'episode',
          isNowWatched: true,
        ),
      );

      expect(
        keys,
        containsAll(<String>{
          'test-profile|jf-machine:episode-1',
          'test-profile|jf-machine:season-1',
          'test-profile|jf-machine:show-1',
        }),
      );
      expect(keys, hasLength(3));

      p.dispose();
    });

    test('forTesting load reads pre-existing sync rules from database', () async {
      // Pre-seed the database with a rule before the provider exists.
      await db.insertSyncRule(
        profileId: 'test-profile',
        serverId: 'srv',
        ratingKey: '99',
        globalKey: 'test-profile|srv:99',
        targetType: 'show',
        episodeCount: 7,
      );

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      expect(p.hasSyncRule('test-profile|srv:99'), isTrue);
      expect(p.getSyncRule('test-profile|srv:99')!.episodeCount, 7);

      p.dispose();
    });
  });

  group('DownloadProvider — profile-scoped download ownership', () {
    final movie = MediaItem(
      id: '1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Owned Movie',
      serverId: 'srv',
    );

    test('download getters only expose active-profile owned physical rows', () async {
      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv:1');

      final p = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {
          'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.completed),
          'srv:2': const DownloadProgress(globalKey: 'srv:2', status: DownloadStatus.completed),
        },
        metadata: {
          'srv:1': movie,
          'srv:2': movie.copyWith(id: '2', title: 'Other Profile Movie'),
        },
        ownedDownloadKeys: const {},
      );

      expect(p.downloads.keys, ['srv:1']);
      expect(p.getProgress('srv:1'), isNotNull);
      expect(p.getProgress('srv:2'), isNull);
      expect(p.downloadedMovies.map((m) => m.id), ['1']);

      p.dispose();
    });

    test('queueDownload claims an existing physical download instead of duplicating it', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.completed)},
        metadata: {'srv:1': movie},
        ownedDownloadKeys: const {},
      );

      final count = await p.queueDownload(movie, _ThrowingClient());

      expect(count, 1);
      expect(p.downloads.keys, ['srv:1']);
      expect(await db.getDownloadOwnerKeysForProfile('test-profile'), {'srv:1'});

      p.dispose();
    });

    test('deleteDownload removes only active-profile ownership when another owner remains', () async {
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: 'srv:1');
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'srv:1');
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.completed)},
        metadata: {'srv:1': movie},
        ownedDownloadKeys: const {},
      );

      await p.deleteDownload('srv:1');

      expect(p.downloads, isEmpty);
      expect(await db.getDownloadOwnerKeysForProfile('test-profile'), isEmpty);
      expect(await db.getDownloadOwnerKeysForProfile('profile-b'), {'srv:1'});

      p.dispose();
    });

    test('deleteDownload is a no-op for unowned physical rows', () async {
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '1',
        globalKey: 'srv:1',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'srv:1');
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.completed)},
        metadata: {'srv:1': movie},
        ownedDownloadKeys: const {},
      );

      await p.deleteDownload('srv:1');

      expect(await db.getDownloadedMedia('srv:1'), isNotNull);
      expect(p.getProgress('srv:1'), isNull);

      p.dispose();
    });

    test('cancelDownload is a no-op for unowned physical rows', () async {
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: '1',
        globalKey: 'srv:1',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'srv:1');
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.queued)},
        metadata: {'srv:1': movie},
        ownedDownloadKeys: const {},
      );

      await p.cancelDownload('srv:1');

      expect(await db.getDownloadedMedia('srv:1'), isNotNull);
      expect(p.getProgress('srv:1'), isNull);

      p.dispose();
    });

    test('releaseDownloadsForProfileServers removes only downloads from the removed connection', () async {
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: 'srv:1');
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'srv:1');
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: 'other:2');
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {
          'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.completed),
          'other:2': const DownloadProgress(globalKey: 'other:2', status: DownloadStatus.completed),
        },
        metadata: {
          'srv:1': movie,
          'other:2': movie.copyWith(id: '2', serverId: 'other'),
        },
      );

      await p.releaseDownloadsForProfileServers('test-profile', {'srv'});

      expect(await db.getDownloadOwnerKeysForProfile('test-profile'), {'other:2'});
      expect(await db.getDownloadOwnerKeysForProfile('profile-b'), {'srv:1'});
      expect(p.downloads.keys, ['other:2']);

      p.dispose();
    });
  });

  group('DownloadProvider — scoped Jellyfin metadata', () {
    Future<void> insertJellyfinConnection(String userId) {
      return db
          .into(db.connections)
          .insert(
            ConnectionsCompanion.insert(
              id: 'jf-machine/$userId',
              kind: 'jellyfin',
              displayName: 'Shared JF',
              configJson: jsonEncode({
                'baseUrl': 'https://jf.example.com',
                'serverName': 'Shared JF',
                'serverMachineId': 'jf-machine',
                'userId': userId,
                'userName': userId,
                'accessToken': 'token-$userId',
                'deviceId': 'device',
              }),
              createdAt: 0,
            ),
          );
    }

    Future<void> putPinnedItem(String scopeId, String userId, String itemId, Map<String, Object?> data) async {
      await JellyfinApiCache.instance.put(scopeId, '/Users/$userId/Items/$itemId', data);
      await JellyfinApiCache.instance.pinForOffline(scopeId, itemId);
    }

    test('loads parent metadata from the downloaded Jellyfin user scope', () async {
      await insertJellyfinConnection('user-a');
      await insertJellyfinConnection('user-b');

      await putPinnedItem('jf-machine/user-a', 'user-a', 'show-1', {
        'Id': 'show-1',
        'Type': 'Series',
        'Name': 'Scoped Show A',
        'RecursiveItemCount': 1,
        'UserData': {'UnplayedItemCount': 1},
      });
      await putPinnedItem('jf-machine/user-a', 'user-a', 'season-1', {
        'Id': 'season-1',
        'Type': 'Season',
        'Name': 'Season A',
        'SeriesId': 'show-1',
        'SeriesName': 'Scoped Show A',
        'UserData': {'UnplayedItemCount': 1},
      });
      await putPinnedItem('jf-machine/user-a', 'user-a', 'ep-1', {
        'Id': 'ep-1',
        'Type': 'Episode',
        'Name': 'Episode A',
        'SeriesId': 'show-1',
        'SeriesName': 'Scoped Show A',
        'SeasonId': 'season-1',
        'SeasonName': 'Season A',
        'UserData': {'PlayCount': 0},
      });
      await putPinnedItem('jf-machine/user-b', 'user-b', 'show-1', {
        'Id': 'show-1',
        'Type': 'Series',
        'Name': 'Wrong User Show',
        'RecursiveItemCount': 1,
        'UserData': {'UnplayedItemCount': 0},
      });

      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'ep-1',
        globalKey: 'jf-machine:ep-1',
        type: 'episode',
        parentRatingKey: 'season-1',
        grandparentRatingKey: 'show-1',
        status: DownloadStatus.completed.index,
      );

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {
          'jf-machine:ep-1': const DownloadProgress(globalKey: 'jf-machine:ep-1', status: DownloadStatus.completed),
        },
      );
      await p.refreshMetadataFromCache();

      expect(p.getMetadata('jf-machine:ep-1')?.title, 'Episode A');
      expect(p.getMetadata('jf-machine:show-1')?.title, 'Scoped Show A');
      expect(p.getMetadata('jf-machine:season-1')?.title, 'Season A');

      p.dispose();
    });

    test('refreshMetadataFromCache prefers the active Jellyfin user scope', () async {
      await insertJellyfinConnection('user-a');
      await insertJellyfinConnection('user-b');
      await putPinnedItem('jf-machine/user-a', 'user-a', 'ep-1', {
        'Id': 'ep-1',
        'Type': 'Episode',
        'Name': 'Wrong User Episode',
        'SeriesId': 'show-1',
        'SeasonId': 'season-1',
        'UserData': {'PlayCount': 0},
      });
      await putPinnedItem('jf-machine/user-b', 'user-b', 'ep-1', {
        'Id': 'ep-1',
        'Type': 'Episode',
        'Name': 'Active User Episode',
        'SeriesId': 'show-1',
        'SeasonId': 'season-1',
        'UserData': {'PlayCount': 1},
      });
      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'ep-1',
        globalKey: 'jf-machine:ep-1',
        type: 'episode',
        parentRatingKey: 'season-1',
        grandparentRatingKey: 'show-1',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: 'jf-machine:ep-1');
      downloadManager.setClientResolver((serverId, {clientScopeId}) {
        if (serverId == 'jf-machine') {
          return _ScopedTestClient(serverId: 'jf-machine', scopedServerId: 'jf-machine/user-b');
        }
        return null;
      });

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {
          'jf-machine:ep-1': const DownloadProgress(globalKey: 'jf-machine:ep-1', status: DownloadStatus.completed),
        },
      );
      await p.refreshMetadataFromCache();

      expect(p.getMetadata('jf-machine:ep-1')?.title, 'Active User Episode');
      expect(p.getMetadata('jf-machine:ep-1')?.isWatched, isTrue);

      p.dispose();
    });

    test('refreshMetadataFromCache applies scoped Jellyfin offline watch overlay', () async {
      await insertJellyfinConnection('user-a');
      await insertJellyfinConnection('user-b');
      await putPinnedItem('jf-machine/user-b', 'user-b', 'ep-1', {
        'Id': 'ep-1',
        'Type': 'Episode',
        'Name': 'Active User Episode',
        'SeriesId': 'show-1',
        'SeasonId': 'season-1',
        'UserData': {'PlayCount': 0},
      });
      await db.insertDownload(
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'ep-1',
        globalKey: 'jf-machine:ep-1',
        type: 'episode',
        parentRatingKey: 'season-1',
        grandparentRatingKey: 'show-1',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: 'jf-machine:ep-1');
      await db.insertWatchAction(
        profileId: 'test-profile',
        serverId: 'jf-machine',
        clientScopeId: 'jf-machine/user-b',
        ratingKey: 'ep-1',
        actionType: 'watched',
      );
      downloadManager.setClientResolver((serverId, {clientScopeId}) {
        if (serverId == 'jf-machine') {
          return _ScopedTestClient(serverId: 'jf-machine', scopedServerId: 'jf-machine/user-b');
        }
        return null;
      });

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {
          'jf-machine:ep-1': const DownloadProgress(globalKey: 'jf-machine:ep-1', status: DownloadStatus.completed),
        },
      );

      await p.refreshMetadataFromCache();

      expect(p.getMetadata('jf-machine:ep-1')?.isWatched, isTrue);

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

  group('DownloadProvider — cancelDownload map symmetry', () {
    test('cancelDownload removes download, metadata, artwork, and episode count', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      const key = 'srv:42';
      p.debugSeedState(
        downloads: {key: const DownloadProgress(globalKey: key, status: DownloadStatus.queued)},
        metadata: {
          key: MediaItem(
            id: '42',
            backend: MediaBackend.plex,
            kind: MediaKind.episode,
            title: 'Ep 42',
            serverId: 'srv',
          ),
        },
        artwork: {key: const DownloadedArtwork(thumbPath: '/art/42.jpg')},
        episodeCounts: {key: 7},
      );

      await p.cancelDownload(key);

      expect(p.getProgress(key), isNull);
      expect(p.getMetadata(key), isNull);
      expect(p.getArtworkPaths(key), isNull, reason: 'artwork path must not orphan after cancel');
      expect(p.totalEpisodeCountFor(key), isNull, reason: 'episode count must not orphan after cancel');

      p.dispose();
    });

    test('cancelDownload is a no-op when download is absent', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      // Seed only artwork; no download → cancelDownload should not touch it.
      p.debugSeedState(artwork: {'srv:99': const DownloadedArtwork(thumbPath: '/art/99.jpg')});

      await p.cancelDownload('srv:99');
      expect(p.getArtworkPaths('srv:99'), isNotNull);

      p.dispose();
    });
  });

  group('DownloadProvider — refresh clears transient state', () {
    test('refresh evicts stale _queueing and _deletionProgress entries', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      const queueingKey = 'srv:queueing';
      const deletingKey = 'srv:deleting';
      p.debugSeedState(
        queueing: {queueingKey},
        deletionProgress: {
          deletingKey: const DeletionProgress(
            globalKey: deletingKey,
            itemTitle: 'Deleting',
            currentItem: 1,
            totalItems: 5,
          ),
        },
      );
      expect(p.isQueueing(queueingKey), isTrue);
      expect(p.getDeletionProgress(deletingKey), isNotNull);

      // refresh() calls _loadPersistedDownloads. Storage may or may not be
      // initialized in this test, but the clear-block runs before any storage
      // call (right after recoveryFuture resolves), so the assertions below
      // hold either way.
      await p.refresh();

      expect(p.isQueueing(queueingKey), isFalse);
      expect(p.getDeletionProgress(deletingKey), isNull);

      p.dispose();
    });
  });

  group('DownloadProvider — queueDownload exception safety', () {
    test('rolls back season metadata when expansion throws', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final season = MediaItem(
        id: '7',
        backend: MediaBackend.plex,
        kind: MediaKind.season,
        title: 'Season 7',
        serverId: 'srv',
      );
      expect(p.getMetadata('srv:7'), isNull);

      await expectLater(p.queueDownload(season, _ThrowingClient()), throwsA(isA<StateError>()));

      expect(p.getMetadata('srv:7'), isNull, reason: 'metadata stash must be rolled back when queue helper throws');
      expect(p.isQueueing('srv:7'), isFalse, reason: '_queueing must be cleared by the finally block');

      p.dispose();
    });

    test('preserves pre-existing metadata if queue throws (no clobber)', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      // Pre-existing metadata under the same key (e.g. from a prior sync rule's
      // targetMetadata). The rollback must not delete it on queue failure.
      final preexisting = MediaItem(
        id: '7',
        backend: MediaBackend.plex,
        kind: MediaKind.season,
        title: 'Original Title',
        serverId: 'srv',
      );
      p.debugSeedState(metadata: {'srv:7': preexisting});

      final season = MediaItem(
        id: '7',
        backend: MediaBackend.plex,
        kind: MediaKind.season,
        title: 'New Title',
        serverId: 'srv',
      );

      await expectLater(p.queueDownload(season, _ThrowingClient()), throwsA(isA<StateError>()));

      expect(p.getMetadata('srv:7'), isNotNull, reason: 'pre-existing metadata must survive rollback');

      p.dispose();
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
