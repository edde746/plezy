import 'dart:async';
import 'dart:convert';
import 'package:plezy/media/ids.dart';

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
import 'package:plezy/utils/deletion_notifier.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import '../test_helpers/media_items.dart';

/// Implements only [fetchPlayableDescendants], the surface [collectEpisodes]
/// uses. Every other call reaches [noSuchMethod] and throws.
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

/// Returns canned tracks from [fetchPlayableDescendants] (album/artist
/// expansion) and records the requested parent ids.
class _MusicExpansionClient implements MediaServerClient {
  _MusicExpansionClient(this.tracks, {this.gate, this.started});

  final List<MediaItem> tracks;
  final Future<void>? gate;
  final Completer<void>? started;
  final fetchPlayableDescendantsCalls = <String>[];

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    fetchPlayableDescendantsCalls.add(parentId);
    if (started != null && !started!.isCompleted) started!.complete();
    if (gate != null) await gate;
    return tracks;
  }

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerId get serverId => ServerId('srv');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScopedTestClient implements MediaServerClient, ScopedMediaServerClient {
  _ScopedTestClient({required this.serverId, required this.scopedServerId, this.fetchItemHandler});

  @override
  final ServerId serverId;

  @override
  final String scopedServerId;
  final Future<MediaItem?> Function(String id)? fetchItemHandler;

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  Future<MediaItem?> fetchItem(String id, {bool useCache = true}) async => fetchItemHandler?.call(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DownloadManagerService downloadManager;
  // Swappable per-test resolver behind the constructor-injected closure.
  MediaClientResolver? testClientResolver;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // PlexApiCache is a singleton accessed eagerly inside DownloadManagerService's
    // constructor; reinitialize per test so each test sees the fresh in-memory DB.
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
    testClientResolver = null;
    downloadManager = DownloadManagerService(
      database: db,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => testClientResolver?.call(serverId, clientScopeId: clientScopeId),
    );
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
        clientResolver: (serverId, {clientScopeId}) => null,
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

    test('logout detaches ownership without deleting physical downloads', () async {
      const globalKey = 'srv:preserved';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'preserved',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: globalKey);

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {globalKey: const DownloadProgress(globalKey: globalKey, status: DownloadStatus.completed)},
        ownedDownloadKeys: {globalKey},
      );
      expect(p.downloads, contains(globalKey));

      await p.detachDownloadsForLogout();

      expect(await db.getDownloadedMedia(globalKey), isNotNull);
      expect(await db.hasDownloadOwner(globalKey), isFalse);
      expect(p.downloads, isEmpty);

      p.dispose();
    });
  });

  group('DownloadProvider — local file selection', () {
    test('falls back to media index when caller has no source id', () async {
      const globalKey = 'srv:movie-1';
      await db.insertDownload(
        serverId: ServerId('srv'),
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

    test('getCompletedDownload exposes the downloaded version for owned completed rows', () async {
      const globalKey = 'srv:movie-1';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'movie-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.completed.index,
        mediaIndex: 1,
        mediaSourceId: 'source-b',
      );

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(ownedDownloadKeys: {globalKey});

      final row = await p.getCompletedDownload(globalKey);
      expect(row, isNotNull);
      expect(row!.mediaIndex, 1);
      expect(row.mediaSourceId, 'source-b');

      p.dispose();
    });

    test('getCompletedDownload returns null for unowned or incomplete rows', () async {
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'unowned',
        globalKey: 'srv:unowned',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      // Owned by another profile — otherwise legacy adoption claims fully
      // ownerless rows for the active profile during initialization.
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'srv:unowned');
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'partial',
        globalKey: 'srv:partial',
        type: 'movie',
        status: DownloadStatus.downloading.index,
      );

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(ownedDownloadKeys: {'srv:partial'});

      expect(await p.getCompletedDownload('srv:unowned'), isNull);
      expect(await p.getCompletedDownload('srv:partial'), isNull);

      p.dispose();
    });
  });

  group('DownloadProvider — sync rule CRUD', () {
    test('createSyncRule inserts into the database and updates the in-memory map', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      var notified = 0;
      p.addListener(() => notified++);

      await p.createSyncRule(
        serverId: ServerId('srv'),
        ratingKey: '10',
        targetType: 'show',
        episodeCount: 5,
        includeSpecials: false,
      );
      final ruleKey = p.syncRuleKeyFor(ServerId('srv'), '10');

      expect(p.hasSyncRule(ruleKey), isTrue);
      final rule = p.getSyncRule(ruleKey);
      expect(rule, isNotNull);
      expect(rule!.profileId, 'test-profile');
      expect(rule.targetType, 'show');
      expect(rule.episodeCount, 5);
      expect(rule.enabled, isTrue);
      expect(rule.downloadFilter, 'unwatched'); // default
      expect(rule.includeSpecials, isFalse);
      // Database state matches in-memory state.
      final dbRule = await db.getSyncRule(ruleKey);
      expect(dbRule, isNotNull);
      expect(dbRule!.targetType, 'show');
      expect(dbRule.includeSpecials, isFalse);

      // createSyncRule notifies once on success.
      expect(notified, 1);

      p.dispose();
    });

    test('updateSyncRuleCount mutates rule and notifies', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      await p.createSyncRule(serverId: ServerId('srv'), ratingKey: '10', targetType: 'show', episodeCount: 5);
      final ruleKey = p.syncRuleKeyFor(ServerId('srv'), '10');

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

      await p.createSyncRule(serverId: ServerId('srv'), ratingKey: '10', targetType: 'collection', episodeCount: 0);
      final ruleKey = p.syncRuleKeyFor(ServerId('srv'), '10');

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

      await p.createSyncRule(serverId: ServerId('srv'), ratingKey: '10', targetType: 'show', episodeCount: 5);
      final ruleKey = p.syncRuleKeyFor(ServerId('srv'), '10');
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

      await p.createSyncRule(serverId: ServerId('srv'), ratingKey: '10', targetType: 'show', episodeCount: 5);
      await p.createSyncRule(serverId: ServerId('srv'), ratingKey: '11', targetType: 'show', episodeCount: 5);
      final ruleKey10 = p.syncRuleKeyFor(ServerId('srv'), '10');
      final ruleKey11 = p.syncRuleKeyFor(ServerId('srv'), '11');
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
      final target = testMediaItem(
        id: '20',
        backend: MediaBackend.plex,
        kind: MediaKind.collection,
        title: 'My Collection',
        serverId: ServerId('srv'),
      );
      await p.createSyncRule(
        serverId: ServerId('srv'),
        ratingKey: '20',
        targetType: 'collection',
        episodeCount: 0,
        targetMetadata: target,
      );
      expect(p.getMetadata('srv:20'), isNotNull, reason: 'targetMetadata should be stashed');

      await p.deleteSyncRule(p.syncRuleKeyFor(ServerId('srv'), '20'));
      expect(p.getMetadata('srv:20'), isNull, reason: 'orphan metadata should be released');

      p.dispose();
    });

    test('deleteSyncRule preserves metadata still referenced by a download', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final target = testMediaItem(
        id: '30',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        title: 'A Show',
        serverId: ServerId('srv'),
      );
      await p.createSyncRule(
        serverId: ServerId('srv'),
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

      await p.deleteSyncRule(p.syncRuleKeyFor(ServerId('srv'), '30'));
      expect(p.getMetadata('srv:30'), isNotNull, reason: 'metadata is still in use by the download');

      p.dispose();
    });

    test('watch events target active-profile parent sync rules', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final keys = p.syncRuleKeysForWatchEvent(
        WatchStateEvent(
          itemId: 'episode-1',
          serverId: ServerId('jf-machine'),
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
        serverId: ServerId('srv'),
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
    final movie = testMediaItem(
      id: '1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Owned Movie',
      serverId: ServerId('srv'),
    );

    test('queueDownload is a no-op when downloads are unsupported', () async {
      final unsupportedManager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
        downloadsSupportedOverride: false,
      )..recoveryFuture = Future<void>.value();
      final p = DownloadProvider.forTesting(downloadManager: unsupportedManager, database: db);
      await p.ensureInitialized();

      final queued = await p.queueDownload(movie, _ScopedTestClient(serverId: ServerId('srv'), scopedServerId: 'srv'));

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

    test('queueDownload applies the client server id before checking existing downloads', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.completed)},
        metadata: {'srv:1': movie},
        ownedDownloadKeys: const {},
      );

      final count = await p.queueDownload(
        movie.copyWith(serverId: null),
        _ScopedTestClient(serverId: ServerId('srv'), scopedServerId: 'srv'),
      );

      expect(count, 1);
      expect(p.downloads.keys, ['srv:1']);
      expect(p.downloads, isNot(contains('1')));
      expect(await db.getDownloadOwnerKeysForProfile('test-profile'), {'srv:1'});

      p.dispose();
    });

    test('queueDownload expands an album into its tracks via fetchPlayableDescendants', () async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.plex,
        kind: MediaKind.album,
        title: 'Album',
        serverId: ServerId('srv'),
      );
      MediaItem track(String id) => testMediaItem(
        id: id,
        backend: MediaBackend.plex,
        kind: MediaKind.track,
        title: id,
        parentId: 'album-1',
        serverId: ServerId('srv'),
      );

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      // Physical rows already exist (shared/unowned) so each expanded track
      // takes the claim-existing early path — no manager/network needed.
      p.debugSeedState(
        downloads: {
          'srv:t1': const DownloadProgress(globalKey: 'srv:t1', status: DownloadStatus.completed),
          'srv:t2': const DownloadProgress(globalKey: 'srv:t2', status: DownloadStatus.completed),
        },
        metadata: {'srv:t1': track('t1'), 'srv:t2': track('t2')},
        ownedDownloadKeys: const {},
      );

      final client = _MusicExpansionClient([track('t1'), track('t2')]);
      final count = await p.queueDownload(album, client);

      expect(count, 2);
      expect(client.fetchPlayableDescendantsCalls, ['album-1']);
      expect(await db.getDownloadOwnerKeysForProfile('test-profile'), {'srv:t1', 'srv:t2'});

      p.dispose();
    });

    test('container queue ownership remains claimed until expansion finishes', () async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.plex,
        kind: MediaKind.album,
        title: 'Album',
        serverId: ServerId('srv'),
      );
      final track = testMediaItem(
        id: 't1',
        backend: MediaBackend.plex,
        kind: MediaKind.track,
        title: 'Track',
        parentId: album.id,
        serverId: ServerId('srv'),
      );
      final provider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {track.globalKey: DownloadProgress(globalKey: track.globalKey, status: DownloadStatus.completed)},
        metadata: {track.globalKey: track},
        ownedDownloadKeys: const {},
      );

      final started = Completer<void>();
      final release = Completer<void>();
      final client = _MusicExpansionClient([track], gate: release.future, started: started);
      final first = provider.queueDownload(album, client);
      await started.future;

      expect(await provider.queueDownload(album, client), 0);
      expect(client.fetchPlayableDescendantsCalls, ['album-1']);

      release.complete();
      expect(await first, 1);
      expect(client.fetchPlayableDescendantsCalls, ['album-1']);
      provider.dispose();
    });

    test('deleting an album emits one provider notification for all tracks', () async {
      MediaItem track(String id) => testMediaItem(
        id: id,
        backend: MediaBackend.plex,
        kind: MediaKind.track,
        title: id,
        parentId: 'album-1',
        serverId: ServerId('srv'),
      );
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.plex,
        kind: MediaKind.album,
        title: 'Album',
        serverId: ServerId('srv'),
      );
      for (final id in ['t1', 't2']) {
        await db.insertDownload(
          serverId: ServerId('srv'),
          ratingKey: id,
          globalKey: 'srv:$id',
          type: 'track',
          status: DownloadStatus.completed.index,
        );
        await db.addDownloadOwner(profileId: 'test-profile', globalKey: 'srv:$id');
      }
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {
          'srv:t1': const DownloadProgress(globalKey: 'srv:t1', status: DownloadStatus.completed),
          'srv:t2': const DownloadProgress(globalKey: 'srv:t2', status: DownloadStatus.completed),
        },
        metadata: {'srv:album-1': album, 'srv:t1': track('t1'), 'srv:t2': track('t2')},
        ownedDownloadKeys: {'srv:t1', 'srv:t2'},
      );
      var notifications = 0;
      p.addListener(() => notifications++);
      final deletionEvents = <DeletionEvent>[];
      final deletionSubscription = DeletionNotifier().stream.listen(deletionEvents.add);
      addTearDown(deletionSubscription.cancel);

      await p.deleteDownload(album.globalKey);
      await pumpEventQueue();

      expect(notifications, 1);
      expect(p.downloads, isEmpty);
      expect(deletionEvents.map((event) => event.itemId), unorderedEquals(['t1', 't2', 'album-1']));
      p.dispose();
    });

    test('album aggregates, downloadedAlbums, and per-album track order come from track downloads', () async {
      MediaItem track(String id, {required int disc, required int number}) => testMediaItem(
        id: id,
        backend: MediaBackend.plex,
        kind: MediaKind.track,
        title: id,
        parentId: 'album-1',
        parentTitle: 'Album',
        grandparentId: 'artist-1',
        grandparentTitle: 'Artist',
        parentIndex: disc,
        index: number,
        serverId: ServerId('srv'),
      );

      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {
          'srv:t1': const DownloadProgress(globalKey: 'srv:t1', status: DownloadStatus.completed),
          'srv:t2': const DownloadProgress(globalKey: 'srv:t2', status: DownloadStatus.completed),
        },
        // Seeded out of disc/track order on purpose.
        metadata: {
          'srv:t1': track('t1', disc: 2, number: 1),
          'srv:t2': track('t2', disc: 1, number: 2),
          'srv:album-1': testMediaItem(
            id: 'album-1',
            backend: MediaBackend.plex,
            kind: MediaKind.album,
            title: 'Album',
            parentId: 'artist-1',
            parentTitle: 'Artist',
            serverId: ServerId('srv'),
          ),
        },
      );

      expect(p.getProgress('srv:album-1')?.status, DownloadStatus.completed);
      expect(p.isDownloaded('srv:album-1'), isTrue);
      expect(p.downloadedAlbums.map((a) => a.id), ['album-1']);
      expect(p.getDownloadedTracksForAlbum('album-1').map((item) => item.id), ['t2', 't1']);

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
        serverId: ServerId('srv'),
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
        serverId: ServerId('srv'),
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
          'other:2': movie.copyWith(id: '2', serverId: ServerId('other')),
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
      await JellyfinApiCache.instance.put(ServerId(scopeId), '/Users/$userId/Items/$itemId', data);
      await JellyfinApiCache.instance.pinForOffline(ServerId(scopeId), itemId);
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
        serverId: ServerId('jf-machine'),
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
        serverId: ServerId('jf-machine'),
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'ep-1',
        globalKey: 'jf-machine:ep-1',
        type: 'episode',
        parentRatingKey: 'season-1',
        grandparentRatingKey: 'show-1',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: 'jf-machine:ep-1');
      testClientResolver = (serverId, {clientScopeId}) {
        if (serverId == 'jf-machine') {
          return _ScopedTestClient(serverId: ServerId('jf-machine'), scopedServerId: 'jf-machine/user-b');
        }
        return null;
      };

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
        serverId: ServerId('jf-machine'),
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
        serverId: ServerId('jf-machine'),
        clientScopeId: 'jf-machine/user-b',
        ratingKey: 'ep-1',
        actionType: 'watched',
      );
      testClientResolver = (serverId, {clientScopeId}) {
        if (serverId == 'jf-machine') {
          return _ScopedTestClient(serverId: ServerId('jf-machine'), scopedServerId: 'jf-machine/user-b');
        }
        return null;
      };

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

    test('offline watch hydration snapshots downloads before database awaits', () async {
      final provider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await provider.ensureInitialized();
      final item = testMediaItem(
        id: '1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: ServerId('srv'),
        viewCount: 0,
      );
      provider.debugSeedState(
        downloads: {
          'srv:1': const DownloadProgress(globalKey: 'srv:1', status: DownloadStatus.completed),
          'srv:2': const DownloadProgress(globalKey: 'srv:2', status: DownloadStatus.completed),
        },
        metadata: {item.globalKey: item},
      );
      await db.insertWatchAction(
        profileId: 'test-profile',
        serverId: ServerId('srv'),
        ratingKey: item.id,
        actionType: 'watched',
      );

      scheduleMicrotask(() {
        provider.debugSeedState(
          downloads: {'srv:3': const DownloadProgress(globalKey: 'srv:3', status: DownloadStatus.completed)},
        );
      });
      await provider.debugHydrateOfflineWatchOverlay();

      expect(provider.getMetadata(item.globalKey)?.isWatched, isTrue);
      provider.dispose();
    });

    test('profile switch discards an in-flight metadata refresh from the old scope', () async {
      await insertJellyfinConnection('user-a');
      await db.insertDownload(
        serverId: ServerId('jf-machine'),
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'movie-1',
        globalKey: 'jf-machine:movie-1',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );

      final fetchStarted = Completer<void>();
      final releaseFetch = Completer<void>();
      var activeClient = _ScopedTestClient(
        serverId: ServerId('jf-machine'),
        scopedServerId: 'jf-machine/user-a',
        fetchItemHandler: (id) async {
          fetchStarted.complete();
          await releaseFetch.future;
          return testMediaItem(
            id: id,
            backend: MediaBackend.jellyfin,
            kind: MediaKind.movie,
            title: 'Profile A',
            serverId: ServerId('jf-machine'),
          );
        },
      );
      testClientResolver = (serverId, {clientScopeId}) => serverId == 'jf-machine' ? activeClient : null;

      final p = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      await p.ensureInitialized();
      p.debugSeedState(
        downloads: {
          'jf-machine:movie-1': const DownloadProgress(
            globalKey: 'jf-machine:movie-1',
            status: DownloadStatus.completed,
          ),
        },
      );

      final staleRefresh = p.refreshMetadataFromCache();
      await fetchStarted.future;
      p.setActiveProfileId('profile-b');
      activeClient = _ScopedTestClient(
        serverId: ServerId('jf-machine'),
        scopedServerId: 'jf-machine/user-b',
        fetchItemHandler: (id) async => testMediaItem(
          id: id,
          backend: MediaBackend.jellyfin,
          kind: MediaKind.movie,
          title: 'Profile B',
          serverId: ServerId('jf-machine'),
        ),
      );
      releaseFetch.complete();
      await staleRefresh;

      expect(p.getMetadata('jf-machine:movie-1'), isNull);

      await p.refreshMetadataFromCache();
      expect(p.getMetadata('jf-machine:movie-1')?.title, 'Profile B');

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

      final item = testMediaItem(
        id: '42',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: ServerId('srv'),
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

      final item = testMediaItem(
        id: '42',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: ServerId('srv'),
        durationMs: 100000,
        viewOffsetMs: 0,
        viewCount: 1,
      );
      p.debugSeedState(metadata: {'srv:42': item});

      WatchStateNotifier().notifyProgress(item: item, viewOffset: 50000, duration: 100000, watchedThreshold: 0.9);
      await Future<void>.delayed(Duration.zero);

      final updated = p.getMetadata('srv:42');
      expect(updated?.isWatched, isTrue);
      expect(updated?.viewOffsetMs, 50000);

      p.dispose();
    });

    test('show, season, and episode events resolve by hierarchical freshness', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      final show = testMediaItem(
        id: 'show-1',
        backend: MediaBackend.plex,
        kind: MediaKind.show,
        serverId: ServerId('srv'),
        leafCount: 3,
        viewedLeafCount: 0,
      );
      final season1 = testMediaItem(
        id: 'season-1',
        backend: MediaBackend.plex,
        kind: MediaKind.season,
        parentId: 'show-1',
        serverId: ServerId('srv'),
        leafCount: 2,
        viewedLeafCount: 0,
      );
      final episode1 = testMediaItem(
        id: 'episode-1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        parentId: 'season-1',
        grandparentId: 'show-1',
        serverId: ServerId('srv'),
        viewCount: 0,
        viewOffsetMs: 40000,
      );
      final episode2 = episode1.copyWith(id: 'episode-2', viewOffsetMs: 50000);
      final episode3 = episode1.copyWith(id: 'episode-3', parentId: 'season-2', viewOffsetMs: 60000);
      p.debugSeedState(
        metadata: {
          show.globalKey: show,
          season1.globalKey: season1,
          episode1.globalKey: episode1,
          episode2.globalKey: episode2,
          episode3.globalKey: episode3,
        },
      );

      WatchStateNotifier().notifyWatched(item: show);
      await Future<void>.delayed(Duration.zero);
      expect(p.getMetadata(episode1.globalKey)?.isWatched, isTrue);
      expect(p.getMetadata(episode2.globalKey)?.viewOffsetMs, 0);
      expect(p.getMetadata(episode3.globalKey)?.isWatched, isTrue);

      WatchStateNotifier().notifyWatched(item: season1, isNowWatched: false);
      await Future<void>.delayed(Duration.zero);
      expect(p.getMetadata(episode1.globalKey)?.isWatched, isFalse);
      expect(p.getMetadata(episode2.globalKey)?.isWatched, isFalse);
      expect(p.getMetadata(episode3.globalKey)?.isWatched, isTrue);

      WatchStateNotifier().notifyWatched(item: episode1);
      await Future<void>.delayed(Duration.zero);
      expect(p.getMetadata(episode1.globalKey)?.isWatched, isTrue);
      expect(p.getMetadata(episode2.globalKey)?.isWatched, isFalse);

      WatchStateNotifier().notifyWatched(item: show, isNowWatched: false);
      await Future<void>.delayed(Duration.zero);
      expect(p.getMetadata(episode1.globalKey)?.isWatched, isFalse);
      expect(p.getMetadata(episode2.globalKey)?.isWatched, isFalse);
      expect(p.getMetadata(episode3.globalKey)?.isWatched, isFalse);
      expect(p.getMetadata(episode3.globalKey)?.viewOffsetMs, 0);

      p.dispose();
    });

    test('queued parent and episode overrides survive provider reload', () async {
      await db.insertWatchAction(
        profileId: 'profile-a',
        serverId: ServerId('srv'),
        ratingKey: 'show-1',
        actionType: 'watched',
      );
      await db.insertWatchAction(
        profileId: 'profile-a',
        serverId: ServerId('srv'),
        ratingKey: 'episode-1',
        actionType: 'unwatched',
      );

      final episode1 = testMediaItem(
        id: 'episode-1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        parentId: 'season-1',
        grandparentId: 'show-1',
        serverId: ServerId('srv'),
        viewCount: 0,
        viewOffsetMs: 45000,
      );
      final episode2 = episode1.copyWith(id: 'episode-2', viewOffsetMs: 55000);

      Future<DownloadProvider> hydrate() async {
        final provider = DownloadProvider.forTesting(
          downloadManager: downloadManager,
          database: db,
          activeProfileId: 'profile-a',
        );
        await provider.ensureInitialized();
        provider.debugSeedState(metadata: {episode1.globalKey: episode1, episode2.globalKey: episode2});
        await provider.refreshMetadataFromCache();
        return provider;
      }

      var p = await hydrate();
      expect(p.getMetadata(episode1.globalKey)?.isWatched, isFalse);
      expect(p.getMetadata(episode1.globalKey)?.viewOffsetMs, 0);
      expect(p.getMetadata(episode2.globalKey)?.isWatched, isTrue);
      expect(p.getMetadata(episode2.globalKey)?.viewOffsetMs, 0);
      p.dispose();

      p = await hydrate();
      expect(p.getMetadata(episode1.globalKey)?.isWatched, isFalse);
      expect(p.getMetadata(episode2.globalKey)?.isWatched, isTrue);
      p.dispose();
    });

    test('queued overlays are isolated to the active profile', () async {
      await db.insertWatchAction(
        profileId: 'profile-a',
        serverId: ServerId('srv'),
        ratingKey: 'show-1',
        actionType: 'watched',
      );
      await db.insertWatchAction(
        profileId: 'profile-b',
        serverId: ServerId('srv'),
        ratingKey: 'show-1',
        actionType: 'unwatched',
      );
      final episode = testMediaItem(
        id: 'episode-1',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        parentId: 'season-1',
        grandparentId: 'show-1',
        serverId: ServerId('srv'),
        viewCount: 0,
      );
      final p = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      await p.ensureInitialized();
      p.debugSeedState(metadata: {episode.globalKey: episode});

      await p.refreshMetadataFromCache();
      expect(p.getMetadata(episode.globalKey)?.isWatched, isTrue);

      p.setActiveProfileId('profile-b');
      await p.refreshMetadataFromCache();
      expect(p.getMetadata(episode.globalKey)?.isWatched, isFalse);

      p.dispose();
    });

    test('queued overlays are isolated to the active Jellyfin client scope', () async {
      await db.insertWatchAction(
        profileId: 'test-profile',
        serverId: ServerId('jf-machine'),
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'show-1',
        actionType: 'watched',
      );
      await db.insertWatchAction(
        profileId: 'test-profile',
        serverId: ServerId('jf-machine'),
        clientScopeId: 'jf-machine/user-b',
        ratingKey: 'show-1',
        actionType: 'unwatched',
      );
      final episode = testMediaItem(
        id: 'episode-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.episode,
        parentId: 'season-1',
        grandparentId: 'show-1',
        serverId: ServerId('jf-machine'),
        viewCount: 0,
      );
      var activeScope = 'jf-machine/user-a';
      testClientResolver = (serverId, {clientScopeId}) => serverId == 'jf-machine'
          ? _ScopedTestClient(serverId: ServerId('jf-machine'), scopedServerId: activeScope)
          : null;
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      p.debugSeedState(metadata: {episode.globalKey: episode});

      await p.refreshMetadataFromCache();
      expect(p.getMetadata(episode.globalKey)?.isWatched, isTrue);

      activeScope = 'jf-machine/user-b';
      await p.refreshMetadataFromCache();
      expect(p.getMetadata(episode.globalKey)?.isWatched, isFalse);

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
    test('cancelDownload removes download, metadata, and artwork', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();

      const key = 'srv:42';
      p.debugSeedState(
        downloads: {key: const DownloadProgress(globalKey: key, status: DownloadStatus.queued)},
        metadata: {
          key: testMediaItem(
            id: '42',
            backend: MediaBackend.plex,
            kind: MediaKind.episode,
            title: 'Ep 42',
            serverId: ServerId('srv'),
          ),
        },
        artwork: {key: const DownloadedArtwork(thumbPath: '/art/42.jpg')},
      );

      await p.cancelDownload(key);

      expect(p.getProgress(key), isNull);
      expect(p.getMetadata(key), isNull);
      expect(p.getArtworkPaths(key), isNull, reason: 'artwork path must not orphan after cancel');

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

      final season = testMediaItem(
        id: '7',
        backend: MediaBackend.plex,
        kind: MediaKind.season,
        title: 'Season 7',
        serverId: ServerId('srv'),
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
      final preexisting = testMediaItem(
        id: '7',
        backend: MediaBackend.plex,
        kind: MediaKind.season,
        title: 'Original Title',
        serverId: ServerId('srv'),
      );
      p.debugSeedState(metadata: {'srv:7': preexisting});

      final season = testMediaItem(
        id: '7',
        backend: MediaBackend.plex,
        kind: MediaKind.season,
        title: 'New Title',
        serverId: ServerId('srv'),
      );

      await expectLater(p.queueDownload(season, _ThrowingClient()), throwsA(isA<StateError>()));

      expect(
        p.getMetadata('srv:7')?.title,
        'Original Title',
        reason: 'queue rollback must restore the previous value, not leave the temporary stash',
      );

      p.dispose();
    });
  });

  group('DownloadProvider — dispose hygiene', () {
    test('isDisposed flips from false to true on dispose', () async {
      final p = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await p.ensureInitialized();
      expect(p.isDisposed, isFalse);
      p.dispose();
      expect(p.isDisposed, isTrue);
    });
  });
}
