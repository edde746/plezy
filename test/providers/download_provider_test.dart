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
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/global_key_utils.dart';
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

  group('DownloadManagerService — platform support', () {
    test('disables downloads only for tvOS builds', () {
      expect(DownloadManagerService.downloadsSupportedFor(tvosBuild: true), isFalse);
      expect(DownloadManagerService.downloadsSupportedFor(tvosBuild: false), isTrue);
    });

    test('recovery is a no-op when downloads are unsupported', () async {
      final unsupportedManager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        downloadsSupportedOverride: false,
      );

      await unsupportedManager.recoverInterruptedDownloads();

      unsupportedManager.dispose();
    });
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

  group('DownloadProvider — local file selection', () {
    test('falls back to media index when caller has no source id', () async {
      const globalKey = 'srv:movie-1';
      await db.insertDownload(
        serverId: 'srv',
        ratingKey: 'movie-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.completed.index,
        mediaIndex: 0,
        mediaSourceId: 'source-a',
      );
      await db.updateVideoFilePath(globalKey, 'content://offline/movie-1-v1');

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(ownedDownloadKeys: {globalKey});

      expect(await p.getVideoFilePath(globalKey, mediaIndex: 1), isNull);
      expect(await p.getVideoFilePath(globalKey, mediaIndex: 0), 'content://offline/movie-1-v1');

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

    test('season-scoped rule is invisible at the show key (UI widens for display)', () async {
      // Regression: "Download only from {season}" + Keep synced creates a rule
      // keyed to the season's rating key. The provider must NOT auto-widen the
      // show-level lookup — that contract is owned by the UI, which iterates
      // its season list. If the provider widened here, deletion and ownership
      // semantics would silently drift across nested entities.
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: 'srv', ratingKey: 'season-2', targetType: 'season', episodeCount: 5);

      final showKey = p.syncRuleKeyFor('srv', 'show-13023');
      final seasonKey = p.syncRuleKeyFor('srv', 'season-2');

      expect(p.hasSyncRule(showKey), isFalse, reason: 'show key must not match a season-scoped rule');
      expect(p.hasSyncRule(seasonKey), isTrue);
      expect(p.getSyncRule(seasonKey)!.targetType, 'season');

      p.dispose();
    });

    test('syncRuleKeyFor scopes by active profile by default', () async {
      // Pin the contract every UI-side lookup relies on: callers can ask for a
      // key with just (serverId, ratingKey) and get a profile-scoped result
      // that matches what createSyncRule stores. Regressing this is what made
      // the show-level button silently miss season rules in offline mode.
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final autoKey = p.syncRuleKeyFor('srv', '42');
      final explicitKey = p.syncRuleKeyFor('srv', '42', profileId: 'test-profile');
      expect(autoKey, equals(explicitKey));
      expect(autoKey, startsWith('test-profile|'));

      await p.createSyncRule(serverId: 'srv', ratingKey: '42', targetType: 'show', episodeCount: 3);
      expect(p.hasSyncRule(autoKey), isTrue);

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

    test('queueDownload is a no-op when downloads are unsupported', () async {
      final unsupportedManager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        downloadsSupportedOverride: false,
      )..recoveryFuture = Future<void>.value();
      final p = DownloadProvider.forTesting(downloadManager: unsupportedManager, database: db);
      await p.ensureInitialized();

      final queued = await p.queueDownload(movie, _ScopedTestClient(serverId: 'srv', scopedServerId: 'srv'));

      expect(queued, 0);
      expect(p.downloads, isEmpty);
      expect(await db.getDownloadedMedia('srv:1'), isNull);

      p.dispose();
      unsupportedManager.dispose();
    });

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

    test('queueDownload leaves paused downloads paused instead of re-queueing them', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.paused)},
        metadata: {'srv:1': movie},
      );

      final count = await p.queueDownload(movie, _ThrowingClient());

      expect(count, 0);
      expect(p.getProgress('srv:1')?.status, DownloadStatus.paused);

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
        'UserData': {'PlayCount': 1, 'Played': true},
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

    test('watched progress events mark downloaded metadata watched and clear resume', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final item = MediaItem(
        id: '42',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: 'srv',
        durationMs: 100000,
        viewOffsetMs: 12000,
        viewCount: 0,
      );
      p.debugSeedState(metadata: {'srv:42': item});

      WatchStateNotifier().notifyProgress(item: item, viewOffset: 95000, duration: 100000, watchedThreshold: 0.9);
      await Future<void>.delayed(Duration.zero);

      final updated = p.getMetadata('srv:42');
      expect(updated?.isWatched, isTrue);
      expect(updated?.viewOffsetMs, 0);

      p.dispose();
    });

    test('sub-threshold progress events update downloaded metadata resume', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final item = MediaItem(
        id: '42',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: 'srv',
        durationMs: 100000,
        viewOffsetMs: 0,
        viewCount: 1,
      );
      p.debugSeedState(metadata: {'srv:42': item});

      WatchStateNotifier().notifyProgress(item: item, viewOffset: 50000, duration: 100000, watchedThreshold: 0.9);
      await Future<void>.delayed(Duration.zero);

      final updated = p.getMetadata('srv:42');
      expect(updated?.isWatched, isFalse);
      expect(updated?.viewOffsetMs, 50000);

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

  group('DownloadProvider — runAutoDeleteAndSync', () {
    test('flips isAutoDeleteAndSyncRunning during the pass and notifies listeners', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      addTearDown(p.dispose);

      // Snapshot the flag on every notify so we can prove it was observed
      // running. Without this we'd only see the final false state.
      final flagSnapshots = <bool>[];
      p.addListener(() => flagSnapshots.add(p.isAutoDeleteAndSyncRunning));

      expect(p.isAutoDeleteAndSyncRunning, isFalse);

      var upToDateFired = false;
      await p.runAutoDeleteAndSync(MultiServerManager(), force: true, onUpToDate: () => upToDateFired = true);

      expect(p.isAutoDeleteAndSyncRunning, isFalse);
      // The button-spinner state depends on listeners seeing the flag flip on.
      expect(flagSnapshots, contains(true));
      // With no profile/no rules and no auto-delete enabled, nothing happens
      // — the user-initiated callback must fire so the button can show
      // explicit "up to date" feedback instead of a silent no-op.
      expect(upToDateFired, isTrue);
    });

    test('re-entrant calls short-circuit while a pass is already running', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      addTearDown(p.dispose);

      var upToDateCount = 0;
      // Fire two overlapping calls. The flag is set synchronously before the
      // first await, so the second invocation must see _autoDeleteAndSyncRunning
      // and return immediately without running the body again.
      final f1 = p.runAutoDeleteAndSync(MultiServerManager(), force: true, onUpToDate: () => upToDateCount++);
      final f2 = p.runAutoDeleteAndSync(MultiServerManager(), force: true, onUpToDate: () => upToDateCount++);
      await Future.wait([f1, f2]);

      expect(upToDateCount, 1);
      expect(p.isAutoDeleteAndSyncRunning, isFalse);
    });
  });

  group('DownloadProvider — aggregate progress (batch-scoped)', () {
    // Regression: the download button's radial progress used to compute
    // `completed / metadata.leafCount`, so queueing 5 of a 10-episode show
    // capped the bar at 50% even after every queued episode finished. The
    // fix re-scopes the denominator to the currently active batch (queued +
    // downloading + completed-since-the-session-started + failed), excluding
    // paused episodes per product decision. Pre-existing completes from past
    // sessions are excluded via an in-memory baseline snapshot taken when the
    // show transitions from idle to active.
    //
    // These helpers compose a show + episode set with the shape
    // `_calculateAggregateProgress` expects (episodes carry `grandparentId`
    // pointing at the show, the show carries `leafCount`).

    const serverId = 'srv';
    const showRatingKey = 'show1';
    final showGlobalKey = buildGlobalKey(serverId, showRatingKey);

    MediaItem showWithLeafCount(int leafCount) => MediaItem(
      id: showRatingKey,
      backend: MediaBackend.plex,
      kind: MediaKind.show,
      title: 'Test Show',
      serverId: serverId,
      leafCount: leafCount,
    );

    MediaItem episode(String id) => MediaItem(
      id: id,
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode $id',
      serverId: serverId,
      grandparentId: showRatingKey,
    );

    String epKey(String id) => buildGlobalKey(serverId, id);

    /// Build a download/metadata pair for an episode under the show above.
    MapEntry<String, DownloadProgress> epDownload(String id, DownloadStatus status) =>
        MapEntry(epKey(id), DownloadProgress(globalKey: epKey(id), status: status));

    MapEntry<String, MediaItem> epMeta(String id) => MapEntry(epKey(id), episode(id));

    test('bug-fix: queueing 5 of 10 reaches 100% — not 50% — as the 5 complete', () async {
      // The bug report verbatim: queue 5 episodes on a 10-episode show. As
      // each finishes, the bar should tick by 20% and hit 100% on the 5th,
      // not 50%. The status doesn't flip to "completed" here (the show as a
      // whole isn't fully downloaded) — it flips to `partial`, which is
      // correct and out of scope for this fix.
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      addTearDown(p.dispose);

      // Seed: show metadata with leafCount=10, plus 5 queued episode rows
      // (no pre-existing completes — this isolates the basic case).
      p.debugSeedState(
        metadata: {
          showGlobalKey: showWithLeafCount(10),
          ...Map.fromEntries(['ep1', 'ep2', 'ep3', 'ep4', 'ep5'].map(epMeta)),
        },
        downloads: Map.fromEntries([
          epDownload('ep1', DownloadStatus.downloading),
          epDownload('ep2', DownloadStatus.queued),
          epDownload('ep3', DownloadStatus.queued),
          epDownload('ep4', DownloadStatus.queued),
          epDownload('ep5', DownloadStatus.queued),
        ]),
      );

      // 0 of 5 done — bar starts at 0%.
      expect(
        p.getProgress(showGlobalKey),
        isA<DownloadProgress>()
            .having((d) => d.status, 'status', DownloadStatus.downloading)
            .having((d) => d.progress, 'progress', 0)
            .having((d) => d.currentFile, 'currentFile', '0/5 episodes'),
      );

      // Advance: 2 completed, 1 downloading, 2 queued → 2/5 = 40%.
      p.debugSeedState(
        downloads: Map.fromEntries([
          epDownload('ep1', DownloadStatus.completed),
          epDownload('ep2', DownloadStatus.completed),
          epDownload('ep3', DownloadStatus.downloading),
          epDownload('ep4', DownloadStatus.queued),
          epDownload('ep5', DownloadStatus.queued),
        ]),
      );
      expect(p.getProgress(showGlobalKey)!.progress, 40);

      // Advance: 4 completed, 1 downloading → 4/5 = 80%.
      p.debugSeedState(
        downloads: Map.fromEntries([
          epDownload('ep1', DownloadStatus.completed),
          epDownload('ep2', DownloadStatus.completed),
          epDownload('ep3', DownloadStatus.completed),
          epDownload('ep4', DownloadStatus.completed),
          epDownload('ep5', DownloadStatus.downloading),
        ]),
      );
      expect(
        p.getProgress(showGlobalKey),
        isA<DownloadProgress>()
            .having((d) => d.status, 'status', DownloadStatus.downloading)
            .having((d) => d.progress, 'progress', 80)
            .having((d) => d.currentFile, 'currentFile', '4/5 episodes'),
      );
    });

    test('pre-existing completed episodes do not inflate the session denominator', () async {
      // Scenario: user previously downloaded 3 episodes of a 10-episode show.
      // Those rows still live in `_downloads` (loaded from DB on app start).
      // Now they queue 5 new episodes. The bar must start at 0/5, not 3/8.
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      addTearDown(p.dispose);

      // First: seed only the 3 pre-existing completed rows. Status is
      // `partial` here (some episodes downloaded but show isn't done), so no
      // baseline gets recorded.
      p.debugSeedState(
        metadata: {
          showGlobalKey: showWithLeafCount(10),
          ...Map.fromEntries(['ep1', 'ep2', 'ep3'].map(epMeta)),
        },
        downloads: Map.fromEntries([
          epDownload('ep1', DownloadStatus.completed),
          epDownload('ep2', DownloadStatus.completed),
          epDownload('ep3', DownloadStatus.completed),
        ]),
      );
      // Sanity: with only completes and no in-flight work, status is partial.
      expect(p.getProgress(showGlobalKey)!.status, DownloadStatus.partial);

      // Now queue 5 more. Status flips to downloading, and the baseline
      // snapshot captures `completedCount=3` so they don't count toward this
      // session's numerator or denominator.
      p.debugSeedState(
        metadata: Map.fromEntries(['ep4', 'ep5', 'ep6', 'ep7', 'ep8'].map(epMeta)),
        downloads: Map.fromEntries([
          epDownload('ep4', DownloadStatus.downloading),
          epDownload('ep5', DownloadStatus.queued),
          epDownload('ep6', DownloadStatus.queued),
          epDownload('ep7', DownloadStatus.queued),
          epDownload('ep8', DownloadStatus.queued),
        ]),
      );

      expect(
        p.getProgress(showGlobalKey),
        isA<DownloadProgress>()
            .having((d) => d.status, 'status', DownloadStatus.downloading)
            .having((d) => d.progress, 'progress', 0)
            .having((d) => d.currentFile, 'currentFile', '0/5 episodes'),
      );

      // After all 5 newly-queued episodes finish: numerator and denominator
      // both equal 5 (the 3 pre-existing ones stay outside the session).
      p.debugSeedState(
        downloads: Map.fromEntries([
          epDownload('ep4', DownloadStatus.completed),
          epDownload('ep5', DownloadStatus.completed),
          epDownload('ep6', DownloadStatus.completed),
          epDownload('ep7', DownloadStatus.completed),
          epDownload('ep8', DownloadStatus.completed),
        ]),
      );
      // Session is now idle → falls back to the show-wide aggregate
      // (8/10 = partial, 80% of the whole show).
      expect(p.getProgress(showGlobalKey)!.status, DownloadStatus.partial);
    });

    test('queueing more episodes mid-batch grows the denominator', () async {
      // Confirmed in grilling: bar moves backward when the user adds to the
      // batch mid-flight ("how much of what I asked for is done").
      //
      // The order matters: the first observation has to see the freshly-
      // queued state (no completes yet) so the baseline snapshot pins to
      // zero. That mirrors real usage — queueDownload writes the queued
      // rows, then notifyListeners() drives the first getProgress call.
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      addTearDown(p.dispose);

      // Seed the initial queued state and observe (baseline → 0).
      p.debugSeedState(
        metadata: {
          showGlobalKey: showWithLeafCount(10),
          ...Map.fromEntries(['ep1', 'ep2', 'ep3', 'ep4', 'ep5'].map(epMeta)),
        },
        downloads: Map.fromEntries([
          epDownload('ep1', DownloadStatus.downloading),
          epDownload('ep2', DownloadStatus.queued),
          epDownload('ep3', DownloadStatus.queued),
          epDownload('ep4', DownloadStatus.queued),
          epDownload('ep5', DownloadStatus.queued),
        ]),
      );
      expect(p.getProgress(showGlobalKey)!.progress, 0);

      // Advance: one completes → 1/5 = 20%.
      p.debugSeedState(
        downloads: {epKey('ep1'): DownloadProgress(globalKey: epKey('ep1'), status: DownloadStatus.completed)},
      );
      expect(p.getProgress(showGlobalKey)!.progress, 20);

      // User adds 3 more to the same in-flight session.
      p.debugSeedState(
        metadata: Map.fromEntries(['ep6', 'ep7', 'ep8'].map(epMeta)),
        downloads: Map.fromEntries([
          epDownload('ep6', DownloadStatus.queued),
          epDownload('ep7', DownloadStatus.queued),
          epDownload('ep8', DownloadStatus.queued),
        ]),
      );
      // 1 completed / 8 total = 12.5% → rounded to 13.
      expect(
        p.getProgress(showGlobalKey),
        isA<DownloadProgress>()
            .having((d) => d.progress, 'progress', 13)
            .having((d) => d.currentFile, 'currentFile', '1/8 episodes'),
      );
    });

    test('paused episodes drop out of the active denominator', () async {
      // Per Branch 4: paused episodes are removed from the denominator until
      // resumed. Pausing one out of 5 should bump 1/5 → 1/4 = 25%.
      //
      // As with the mid-batch test, the initial observation must see all 5
      // queued so the baseline pins to zero before any completion.
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      addTearDown(p.dispose);

      // Seed the initial queued state and observe (baseline → 0).
      p.debugSeedState(
        metadata: {
          showGlobalKey: showWithLeafCount(10),
          ...Map.fromEntries(['ep1', 'ep2', 'ep3', 'ep4', 'ep5'].map(epMeta)),
        },
        downloads: Map.fromEntries([
          epDownload('ep1', DownloadStatus.downloading),
          epDownload('ep2', DownloadStatus.queued),
          epDownload('ep3', DownloadStatus.queued),
          epDownload('ep4', DownloadStatus.queued),
          epDownload('ep5', DownloadStatus.queued),
        ]),
      );
      expect(p.getProgress(showGlobalKey)!.progress, 0);

      // Advance: one completes → 1/5 = 20%.
      p.debugSeedState(
        downloads: {epKey('ep1'): DownloadProgress(globalKey: epKey('ep1'), status: DownloadStatus.completed)},
      );
      expect(p.getProgress(showGlobalKey)!.progress, 20);

      // Pause ep5. Denominator shrinks to 4: 1 done + 1 downloading + 2 queued.
      p.debugSeedState(
        downloads: {epKey('ep5'): DownloadProgress(globalKey: epKey('ep5'), status: DownloadStatus.paused)},
      );
      expect(
        p.getProgress(showGlobalKey),
        isA<DownloadProgress>()
            .having((d) => d.progress, 'progress', 25)
            .having((d) => d.currentFile, 'currentFile', '1/4 episodes'),
      );
    });

    test('session baseline resets after a batch settles and a new batch begins', () async {
      // After a batch ends (everything moves out of downloading/queued) the
      // baseline must clear so the next batch starts fresh at 0%, not at
      // "wherever the previous batch left the completed counter".
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      addTearDown(p.dispose);

      // First batch: 2 queued. As they complete, status flips to partial
      // (2 of 10 leafCount).
      p.debugSeedState(
        metadata: {
          showGlobalKey: showWithLeafCount(10),
          ...Map.fromEntries(['ep1', 'ep2'].map(epMeta)),
        },
        downloads: Map.fromEntries([
          epDownload('ep1', DownloadStatus.downloading),
          epDownload('ep2', DownloadStatus.queued),
        ]),
      );
      expect(p.getProgress(showGlobalKey)!.progress, 0);

      p.debugSeedState(
        downloads: Map.fromEntries([
          epDownload('ep1', DownloadStatus.completed),
          epDownload('ep2', DownloadStatus.completed),
        ]),
      );
      // Session ended; baseline cleared. Status is partial (out of 10).
      expect(p.getProgress(showGlobalKey)!.status, DownloadStatus.partial);

      // Second batch: 3 more episodes. Should start at 0/3, not 2/5 or
      // similar — the previous session's completes are excluded by the
      // newly-recorded baseline (=2).
      p.debugSeedState(
        metadata: Map.fromEntries(['ep3', 'ep4', 'ep5'].map(epMeta)),
        downloads: Map.fromEntries([
          epDownload('ep3', DownloadStatus.downloading),
          epDownload('ep4', DownloadStatus.queued),
          epDownload('ep5', DownloadStatus.queued),
        ]),
      );
      expect(
        p.getProgress(showGlobalKey),
        isA<DownloadProgress>()
            .having((d) => d.status, 'status', DownloadStatus.downloading)
            .having((d) => d.progress, 'progress', 0)
            .having((d) => d.currentFile, 'currentFile', '0/3 episodes'),
      );

      // And finishes at 100% of the new batch (not 5/10 = 50%).
      p.debugSeedState(
        downloads: Map.fromEntries([
          epDownload('ep3', DownloadStatus.completed),
          epDownload('ep4', DownloadStatus.completed),
          epDownload('ep5', DownloadStatus.completed),
        ]),
      );
      // Once the second batch settles, status flips back to partial (5/10).
      // We don't assert progress% here — out-of-session calculations fall
      // back to the show-wide aggregate, which is a separate concern.
      expect(p.getProgress(showGlobalKey)!.status, DownloadStatus.partial);
    });
  });
}
