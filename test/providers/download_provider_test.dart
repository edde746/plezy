import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show ApplyInterceptor, QueryExecutor, QueryInterceptor;
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
import 'package:plezy/services/api_cache.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/deletion_notifier.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import 'package:plezy/utils/active_client_scope.dart';
import '../test_helpers/download_fixtures.dart';
import '../test_helpers/media_items.dart';

/// Implements only [fetchPlayableDescendants], the surface [collectEpisodes]
/// uses. Every other call reaches [noSuchMethod] and throws.
class _ThrowingClient implements MediaServerClient {
  @override
  ServerId get serverId => ServerId('srv');

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
  _ScopedTestClient({
    required this.serverId,
    required this.scopedServerId,
    this.fetchItemHandler,
    this.clientBackend = MediaBackend.jellyfin,
  });

  @override
  final ServerId serverId;

  @override
  final String scopedServerId;
  final Future<MediaItem?> Function(String id)? fetchItemHandler;
  final MediaBackend clientBackend;

  @override
  MediaBackend get backend => clientBackend;

  @override
  ApiCache get cache => ApiCache.forBackend(clientBackend);

  @override
  Future<MediaItem?> fetchItem(String id, {bool useCache = true}) async => fetchItemHandler?.call(id);

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DownloadOwnerSelectGate extends QueryInterceptor {
  Completer<void>? _started;
  Completer<void>? _release;
  String? _globalKey;

  Future<void> get started => _started!.future;

  void arm(String globalKey) {
    _globalKey = globalKey;
    _started = Completer<void>();
    _release = Completer<void>();
  }

  void release() => _release!.complete();

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryExecutor executor, String statement, List<Object?> args) async {
    final started = _started;
    final release = _release;
    if (started != null && !started.isCompleted && statement.contains('download_owners') && args.contains(_globalKey)) {
      started.complete();
      await release!.future;
    }
    return executor.runSelect(statement, args);
  }
}

class _GatedPhysicalDeletionManager extends DownloadManagerService {
  _GatedPhysicalDeletionManager(AppDatabase database)
    : super(
        database: database,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
      ) {
    recoveryFuture = Future<void>.value();
  }

  final started = Completer<void>();
  final release = Completer<void>();

  Future<void> _completePhysicalDeletion() async {
    if (!started.isCompleted) started.complete();
    await release.future;
  }

  @override
  Future<void> cancelAndRemoveDownload(String globalKey) => _completePhysicalDeletion();

  @override
  Future<void> deleteDownload(String globalKey) => _completePhysicalDeletion();
}

Future<void> _insertProfile(AppDatabase db, String id) => db
    .into(db.profiles)
    .insert(ProfilesCompanion.insert(id: id, kind: 'local', displayName: id, configJson: '{}', createdAt: 0));

Future<void> _insertPlexConnection(AppDatabase db, ServerId serverId) => db
    .into(db.connections)
    .insert(
      ConnectionsCompanion.insert(id: serverId, kind: 'plex', displayName: serverId, configJson: '{}', createdAt: 0),
    );

Map<String, dynamic> _plexMetadata({
  required String id,
  required String title,
  required int viewCount,
  required int viewOffset,
}) => {
  'MediaContainer': {
    'Metadata': [
      {'ratingKey': id, 'title': title, 'type': 'movie', 'viewCount': viewCount, 'viewOffset': viewOffset},
    ],
  },
};

Future<void> _putPinnedPlexMetadata(
  PlexProfileScopeId scope, {
  required String id,
  required String title,
  required int viewCount,
  required int viewOffset,
}) async {
  await PlexApiCache.instance.put(
    scope.cacheServerId,
    '/library/metadata/$id',
    _plexMetadata(id: id, title: title, viewCount: viewCount, viewOffset: viewOffset),
  );
  await PlexApiCache.instance.pinForOffline(scope.cacheServerId, id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DownloadManagerService downloadManager;
  late _DownloadOwnerSelectGate downloadOwnerSelectGate;
  // Swappable per-test resolver behind the constructor-injected closure.
  MediaClientResolver? testClientResolver;

  setUp(() {
    downloadOwnerSelectGate = _DownloadOwnerSelectGate();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(downloadOwnerSelectGate));
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

  group('DownloadProvider — download location coordinator', () {
    test('set and reset delegate to the manager-owned ordered transition', () async {
      DownloadLocationSnapshot location = (path: null, type: null);
      final events = <String>[];
      final coordinator = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
        downloadsSupportedOverride: false,
        downloadLocationReader: () => location,
        downloadPathWriter: (value) async {
          events.add('path:$value');
          location = (path: value, type: location.type);
        },
        downloadPathTypeWriter: (value) async {
          events.add('type:$value');
          location = (path: location.path, type: value);
        },
        downloadStorageRefresher: () async {
          events.add('refresh');
        },
      )..recoveryFuture = Future<void>.value();
      final provider = DownloadProvider.forTesting(downloadManager: coordinator, database: db);
      await provider.ensureInitialized();

      await provider.setDownloadLocation(path: '/downloads', pathType: 'file');
      await provider.resetDownloadLocation();

      expect(events, ['path:/downloads', 'type:file', 'refresh', 'path:null', 'type:null', 'refresh']);
      expect(location, (path: null, type: null));
      provider.dispose();
      coordinator.dispose();
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

    test('profile switch clears visible ownership and rules before starting the reload', () async {
      const globalKey = 'srv:owned-a';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'owned-a',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: globalKey);
      await db.insertSyncRule(
        profileId: 'test-profile',
        serverId: ServerId('srv'),
        ratingKey: 'show-a',
        globalKey: 'test-profile|srv:show-a',
        targetType: 'show',
        episodeCount: 1,
      );
      final provider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {globalKey: const DownloadProgress(globalKey: globalKey, status: DownloadStatus.completed)},
        ownedDownloadKeys: {globalKey},
      );
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.setActiveProfileId('profile-b');

      expect(provider.downloads, isEmpty);
      expect(provider.syncRules, isEmpty);
      expect(notifications, 1);
      await provider.debugWaitForProfileScopedReload();
      provider.dispose();
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

    test('profile switch invalidates container expansion before it can claim the new profile', () async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.plex,
        kind: MediaKind.album,
        title: 'Profile A Album',
        serverId: ServerId('srv'),
      );
      final track = testMediaItem(
        id: 'track-1',
        backend: MediaBackend.plex,
        kind: MediaKind.track,
        title: 'Profile A Track',
        parentId: album.id,
        serverId: ServerId('srv'),
      );
      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {track.globalKey: DownloadProgress(globalKey: track.globalKey, status: DownloadStatus.completed)},
        metadata: {track.globalKey: track},
        ownedDownloadKeys: const {},
      );

      final expansionStarted = Completer<void>();
      final releaseExpansion = Completer<void>();
      final queueFuture = provider.queueDownload(
        album,
        _MusicExpansionClient([track], gate: releaseExpansion.future, started: expansionStarted),
      );
      await expansionStarted.future;

      provider.setActiveProfileId('profile-b');
      expect(provider.isQueueing(album.globalKey), isFalse);
      releaseExpansion.complete();

      expect(await queueFuture, 0);
      expect(await db.getDownloadOwnerKeysForProfile('profile-a'), isEmpty);
      expect(await db.getDownloadOwnerKeysForProfile('profile-b'), isEmpty);
      expect(await db.getAllDownloadedMetadata(), isEmpty);
      expect(provider.getMetadata(album.globalKey), isNull);
      expect(provider.getMetadata(track.globalKey), isNull);
      expect(provider.downloads, isEmpty);
      expect(provider.isQueueing(album.globalKey), isFalse);
      expect(await db.getSyncRules(profileId: 'profile-b'), isEmpty);
    });

    test('stale queue cleanup does not remove the new profile generation key', () async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.plex,
        kind: MediaKind.album,
        title: 'Album',
        serverId: ServerId('srv'),
      );
      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();

      final firstStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final firstQueue = provider.queueDownload(
        album,
        _MusicExpansionClient(const [], gate: releaseFirst.future, started: firstStarted),
      );
      await firstStarted.future;

      provider.setActiveProfileId('profile-b');
      final secondStarted = Completer<void>();
      final releaseSecond = Completer<void>();
      final secondQueue = provider.queueDownload(
        album,
        _MusicExpansionClient(const [], gate: releaseSecond.future, started: secondStarted),
      );
      await secondStarted.future;
      expect(provider.isQueueing(album.globalKey), isTrue);

      releaseFirst.complete();
      expect(await firstQueue, 0);
      expect(provider.isQueueing(album.globalKey), isTrue);

      releaseSecond.complete();
      expect(await secondQueue, 0);
      expect(provider.isQueueing(album.globalKey), isFalse);
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

    void registerProfileSwitchSharedOwnerTest(
      String operationName,
      Future<void> Function(DownloadProvider provider, String globalKey) operation,
      DownloadStatus status,
    ) {
      test(
        '$operationName releases the initiating owner when the active profile switches during owner lookup',
        () async {
          const globalKey = 'srv:profile-switch';
          const itemId = 'profile-switch';
          final serverId = ServerId('srv');
          final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
          final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
          await _insertPlexConnection(db, serverId);
          await _insertProfile(db, 'profile-a');
          await _insertProfile(db, 'profile-b');
          await db.insertDownload(
            serverId: serverId,
            clientScopeId: scopeA,
            ratingKey: itemId,
            globalKey: globalKey,
            type: 'movie',
            status: status.index,
          );
          await db.addDownloadOwner(
            profileId: 'profile-a',
            globalKey: globalKey,
            backendId: MediaBackend.plex.id,
            clientScopeId: scopeA,
          );
          await db.addDownloadOwner(
            profileId: 'profile-b',
            globalKey: globalKey,
            backendId: MediaBackend.plex.id,
            clientScopeId: scopeB,
          );
          await _putPinnedPlexMetadata(scopeA, id: itemId, title: 'Profile A cache', viewCount: 0, viewOffset: 1000);
          await _putPinnedPlexMetadata(scopeB, id: itemId, title: 'Profile B cache', viewCount: 1, viewOffset: 0);
          final provider = DownloadProvider.forTesting(
            downloadManager: downloadManager,
            database: db,
            activeProfileId: 'profile-a',
          );
          addTearDown(provider.dispose);
          await provider.ensureInitialized();
          provider.debugSeedState(
            downloads: {globalKey: DownloadProgress(globalKey: globalKey, status: status)},
            metadata: {globalKey: movie.copyWith(id: itemId, title: 'Profile A cache')},
          );

          downloadOwnerSelectGate.arm(globalKey);
          final deletion = operation(provider, globalKey);
          await downloadOwnerSelectGate.started;

          provider.setActiveProfileId('profile-b');
          await provider.debugWaitForProfileScopedReload();
          downloadOwnerSelectGate.release();
          await deletion;

          expect(await db.getDownloadOwnerKeysForProfile('profile-a'), isEmpty);
          expect(await db.getDownloadOwnerKeysForProfile('profile-b'), {globalKey});
          expect(provider.downloads.keys, [globalKey]);
          expect(provider.getMetadata(globalKey)?.title, 'Profile B cache');
          expect((await PlexApiCache.instance.getMetadata(scopeB.cacheServerId, itemId))?.title, 'Profile B cache');
          expect(await PlexApiCache.instance.isPinnedRatingKey(scopeB.cacheServerId, itemId), isTrue);
        },
      );
    }

    registerProfileSwitchSharedOwnerTest(
      'deleteDownload',
      (provider, globalKey) => provider.deleteDownload(globalKey),
      DownloadStatus.completed,
    );
    registerProfileSwitchSharedOwnerTest(
      'cancelDownload',
      (provider, globalKey) => provider.cancelDownload(globalKey),
      DownloadStatus.queued,
    );

    void registerProfileSwitchFinalOwnerTest(
      String operationName,
      Future<void> Function(DownloadProvider provider, String globalKey) operation,
      DownloadStatus status,
    ) {
      test('$operationName releases its final owner after a profile switch during physical deletion', () async {
        const deletingKey = 'srv:final-owner';
        const profileBKey = 'srv:profile-b';
        await db.addDownloadOwner(profileId: 'profile-a', globalKey: deletingKey);
        await db.addDownloadOwner(profileId: 'profile-b', globalKey: profileBKey);
        final gatedManager = _GatedPhysicalDeletionManager(db);
        addTearDown(gatedManager.dispose);
        final provider = DownloadProvider.forTesting(
          downloadManager: gatedManager,
          database: db,
          activeProfileId: 'profile-a',
        );
        addTearDown(provider.dispose);
        await provider.ensureInitialized();
        provider.debugSeedState(
          downloads: {
            deletingKey: DownloadProgress(globalKey: deletingKey, status: status),
            profileBKey: const DownloadProgress(globalKey: profileBKey, status: DownloadStatus.completed),
          },
          metadata: {
            deletingKey: movie.copyWith(id: 'final-owner', title: 'Profile A cache'),
            profileBKey: movie.copyWith(id: 'profile-b', title: 'Profile B cache'),
          },
          ownedDownloadKeys: {deletingKey},
        );

        final deletion = operation(provider, deletingKey);
        await gatedManager.started.future;

        provider.setActiveProfileId('profile-b');
        await provider.debugWaitForProfileScopedReload();
        provider.debugSeedState(
          metadata: {profileBKey: movie.copyWith(id: 'profile-b', title: 'Profile B cache')},
        );
        gatedManager.release.complete();
        await deletion;

        expect(await db.getDownloadOwnerKeysForProfile('profile-a'), isEmpty);
        expect(await db.getDownloadOwnerKeysForProfile('profile-b'), {profileBKey});
        expect(provider.downloads.keys, [profileBKey]);
        expect(provider.getMetadata(profileBKey)?.title, 'Profile B cache');
      });
    }

    registerProfileSwitchFinalOwnerTest(
      'deleteDownload',
      (provider, globalKey) => provider.deleteDownload(globalKey),
      DownloadStatus.completed,
    );
    registerProfileSwitchFinalOwnerTest(
      'cancelDownload',
      (provider, globalKey) => provider.cancelDownload(globalKey),
      DownloadStatus.queued,
    );

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

    test(
      'releasing a queued shared owner rebinds the physical row and preserves its queue intent for the survivor',
      () async {
        const globalKey = 'srv:shared-queued';
        const itemId = 'shared-queued';
        final serverId = ServerId('srv');
        final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
        final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
        await _insertPlexConnection(db, serverId);
        await _insertProfile(db, 'profile-a');
        await _insertProfile(db, 'profile-b');
        await db.insertDownload(
          serverId: serverId,
          clientScopeId: scopeA,
          ratingKey: itemId,
          globalKey: globalKey,
          type: 'movie',
          status: DownloadStatus.queued.index,
        );
        await db.addToQueue(mediaGlobalKey: globalKey, priority: 37);
        await db.addDownloadOwner(
          profileId: 'profile-a',
          globalKey: globalKey,
          backendId: MediaBackend.plex.id,
          clientScopeId: scopeA,
        );
        await db.addDownloadOwner(
          profileId: 'profile-b',
          globalKey: globalKey,
          backendId: MediaBackend.plex.id,
          clientScopeId: scopeB,
        );
        await _putPinnedPlexMetadata(scopeB, id: itemId, title: 'Profile B snapshot', viewCount: 0, viewOffset: 0);

        final itemB = movie.copyWith(id: itemId, title: 'Profile B snapshot');
        final clientB = _ScopedTestClient(
          serverId: serverId,
          scopedServerId: scopeB,
          clientBackend: MediaBackend.plex,
          fetchItemHandler: (_) async => itemB,
        );
        final resolvedScopes = <String?>[];
        final queueResumed = Completer<MediaServerClient>();
        final scopedManager = DownloadManagerService(
          database: db,
          storageService: DownloadStorageService.instance,
          clientResolver: (resolvedServerId, {clientScopeId}) {
            resolvedScopes.add(clientScopeId);
            return resolvedServerId == serverId && clientScopeId == scopeB ? clientB : null;
          },
          downloadsSupportedOverride: true,
          queueProcessorOverride: (client) async {
            if (!queueResumed.isCompleted) queueResumed.complete(client);
          },
        )..recoveryFuture = Future<void>.value();
        addTearDown(scopedManager.dispose);
        final provider = DownloadProvider.forTesting(
          downloadManager: scopedManager,
          database: db,
          activeProfileId: 'profile-b',
        );
        addTearDown(provider.dispose);
        await provider.ensureInitialized();
        provider.debugSeedState(
          downloads: {globalKey: const DownloadProgress(globalKey: globalKey, status: DownloadStatus.queued)},
          metadata: {globalKey: itemB},
          ownedDownloadKeys: {globalKey},
        );

        await provider.releaseDownloadsForProfileServers('profile-a', {'srv'});

        final rebound = await db.getDownloadedMedia(globalKey);
        expect(rebound?.clientScopeId, scopeB);
        expect(await db.getDownloadOwnerKeysForProfile('profile-a'), isEmpty);
        expect(await db.getDownloadOwnerKeysForProfile('profile-b'), {globalKey});
        expect(provider.isQueued(globalKey), isTrue);

        resolvedScopes.clear();
        expect((await scopedManager.lookupMetadata(serverId, itemId))?.title, 'Profile B snapshot');
        expect(resolvedScopes, contains(scopeB));
        expect(resolvedScopes, isNot(contains(scopeA)));

        expect(
          await provider.queueDownload(itemB, clientB),
          0,
          reason: 'the surviving owner must not duplicate the row',
        );
        var queueRows = await db.select(db.downloadQueue).get();
        expect(queueRows, hasLength(1));
        expect(queueRows.single.mediaGlobalKey, globalKey);
        expect(queueRows.single.priority, 37);
        expect((await db.getNextQueueItem())?.mediaGlobalKey, globalKey);

        scopedManager.resumeQueuedDownloads(clientB);
        expect(await queueResumed.future.timeout(const Duration(seconds: 2)), same(clientB));
        queueRows = await db.select(db.downloadQueue).get();
        expect(queueRows, hasLength(1));
        expect(queueRows.single.priority, 37);
      },
    );

    test('deleting one owner does not migrate a completed shared physical row', () async {
      const globalKey = 'srv:shared-completed';
      final serverId = ServerId('srv');
      final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      await _insertPlexConnection(db, serverId);
      await _insertProfile(db, 'profile-a');
      await _insertProfile(db, 'profile-b');
      await db.insertDownload(
        serverId: serverId,
        clientScopeId: scopeA,
        ratingKey: 'shared-completed',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(
        profileId: 'profile-a',
        globalKey: globalKey,
        backendId: MediaBackend.plex.id,
        clientScopeId: scopeA,
      );
      await db.addDownloadOwner(
        profileId: 'profile-b',
        globalKey: globalKey,
        backendId: MediaBackend.plex.id,
        clientScopeId: scopeB,
      );
      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-b',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();

      await provider.deleteDownloadsForProfile('profile-a');

      final completed = await db.getDownloadedMedia(globalKey);
      expect(completed, isNotNull);
      expect(completed?.clientScopeId, scopeA);
      expect(await db.getDownloadOwnerKeysForProfile('profile-a'), isEmpty);
      expect(await db.getDownloadOwnerKeysForProfile('profile-b'), {globalKey});
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

    test('loads parent metadata from the exact active Jellyfin user scope', () async {
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
      await db.addDownloadOwner(profileId: 'test-profile', globalKey: 'jf-machine:ep-1');
      testClientResolver = (serverId, {clientScopeId}) => serverId == 'jf-machine'
          ? _ScopedTestClient(serverId: ServerId('jf-machine'), scopedServerId: 'jf-machine/user-a')
          : null;

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

    test('cold Jellyfin profile restores its persisted scoped queued watch action', () async {
      await insertJellyfinConnection('user-a');
      await insertJellyfinConnection('user-b');
      await db
          .into(db.profileConnections)
          .insert(
            ProfileConnectionsCompanion.insert(
              profileId: 'test-profile',
              connectionId: 'jf-machine/user-b',
              userIdentifier: 'user-b',
            ),
          );
      await putPinnedItem('jf-machine/user-b', 'user-b', 'ep-1', {
        'Id': 'ep-1',
        'Type': 'Episode',
        'Name': 'Offline User B Episode',
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

      final provider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {
          'jf-machine:ep-1': const DownloadProgress(globalKey: 'jf-machine:ep-1', status: DownloadStatus.completed),
        },
      );
      await provider.refreshMetadataFromCache();

      expect(provider.getMetadata('jf-machine:ep-1')?.title, 'Offline User B Episode');
      expect(provider.getMetadata('jf-machine:ep-1')?.isWatched, isTrue);
      provider.dispose();
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
      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'jf-machine:movie-1');
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'jf-machine:movie-1');

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

      if (p.getMetadata('jf-machine:movie-1')?.title != 'Profile B') {
        final reloaded = Completer<void>();
        void onReload() {
          if (p.getMetadata('jf-machine:movie-1')?.title == 'Profile B' && !reloaded.isCompleted) {
            reloaded.complete();
          }
        }

        p.addListener(onReload);
        await reloaded.future.timeout(const Duration(seconds: 2));
        p.removeListener(onReload);
      }
      expect(p.getMetadata('jf-machine:movie-1')?.title, 'Profile B');

      p.dispose();
    });

    test('shared Jellyfin cache scope survives until its final download owner is released', () async {
      const globalKey = 'jf-machine:movie-1';
      const scopeId = 'jf-machine/user-a';
      await insertJellyfinConnection('user-a');
      await _insertProfile(db, 'profile-a');
      await _insertProfile(db, 'profile-b');
      await db.insertDownload(
        serverId: ServerId('jf-machine'),
        clientScopeId: scopeId,
        ratingKey: 'movie-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      for (final profileId in ['profile-a', 'profile-b']) {
        await db.addDownloadOwner(
          profileId: profileId,
          globalKey: globalKey,
          backendId: MediaBackend.jellyfin.id,
          clientScopeId: scopeId,
        );
      }
      await putPinnedItem(scopeId, 'user-a', 'movie-1', {
        'Id': 'movie-1',
        'Type': 'Movie',
        'Name': 'Shared offline movie',
      });
      final segmentsEndpoint = JellyfinApiCache.mediaSegmentsEndpoint('movie-1');
      await JellyfinApiCache.instance.put(ServerId(scopeId), segmentsEndpoint, {'Items': <Object?>[]});
      await JellyfinApiCache.instance.pinForOffline(ServerId(scopeId), 'movie-1');

      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();

      await provider.deleteDownloadsForProfile('profile-a');

      expect(await db.getDownloadOwnerKeysForProfile('profile-b'), {globalKey});
      expect(
        (await JellyfinApiCache.instance.getMetadata(ServerId(scopeId), 'movie-1'))?.title,
        'Shared offline movie',
      );
      expect(await JellyfinApiCache.instance.get(ServerId(scopeId), segmentsEndpoint), isNotNull);

      await provider.deleteDownloadsForProfile('profile-b');

      expect(await JellyfinApiCache.instance.getMetadata(ServerId(scopeId), 'movie-1'), isNull);
      expect(await JellyfinApiCache.instance.get(ServerId(scopeId), segmentsEndpoint), isNull);
    });
  });

  group('DownloadProvider — scoped Plex metadata ownership', () {
    const key = 'srv:123';
    final serverId = ServerId('srv');

    Future<void> seedPhysicalDownload({required Iterable<String> owners}) async {
      await _insertPlexConnection(db, serverId);
      for (final owner in owners) {
        await _insertProfile(db, owner);
      }
      await db.insertDownload(
        serverId: serverId,
        clientScopeId: buildPlexProfileScopeId(serverId: serverId, profileId: owners.first),
        ratingKey: '123',
        globalKey: key,
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      for (final owner in owners) {
        await db.addDownloadOwner(profileId: owner, globalKey: key);
      }
    }

    Future<void> waitForProfileReload(DownloadProvider provider, String profileId, bool Function() isSettled) async {
      final settled = Completer<void>();
      void listener() {
        if (isSettled() && !settled.isCompleted) settled.complete();
      }

      provider.addListener(listener);
      provider.setActiveProfileId(profileId);
      await settled.future.timeout(const Duration(seconds: 2));
      provider.removeListener(listener);
    }

    test('offline profile switches select only exact Plex owner snapshots and preserve one physical row', () async {
      await seedPhysicalDownload(owners: const ['profile-a', 'profile-b']);
      final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      await _putPinnedPlexMetadata(scopeA, id: '123', title: 'Profile A snapshot', viewCount: 0, viewOffset: 12000);
      await _putPinnedPlexMetadata(scopeB, id: '123', title: 'Profile B snapshot', viewCount: 1, viewOffset: 0);

      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {key: const DownloadProgress(globalKey: key, status: DownloadStatus.completed)},
        ownedDownloadKeys: {key},
      );
      await provider.refreshMetadataFromCache();

      expect(provider.getMetadata(key)?.title, 'Profile A snapshot');
      expect(provider.getMetadata(key)?.viewOffsetMs, 12000);

      await waitForProfileReload(provider, 'profile-b', () => provider.getMetadata(key)?.title == 'Profile B snapshot');
      expect(provider.getMetadata(key)?.isWatched, isTrue);

      await waitForProfileReload(provider, 'profile-a', () => provider.getMetadata(key)?.title == 'Profile A snapshot');
      expect(provider.getMetadata(key)?.isWatched, isFalse);
      expect(await db.getDownloadedMedia(key), isNotNull);
      expect(await db.getDownloadOwnerCount(key), 2);
      expect(await PlexApiCache.instance.isPinnedRatingKey(scopeA.cacheServerId, '123'), isTrue);
      expect(await PlexApiCache.instance.isPinnedRatingKey(scopeB.cacheServerId, '123'), isTrue);
      expect((await PlexApiCache.instance.getMetadata(scopeA.cacheServerId, '123'))?.title, 'Profile A snapshot');
      expect((await PlexApiCache.instance.getMetadata(scopeB.cacheServerId, '123'))?.title, 'Profile B snapshot');
    });

    test('full logout transfers Plex metadata to the next profile without carrying private state', () async {
      await seedPhysicalDownload(owners: const ['profile-a', 'profile-old-co-owner']);
      final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      final transferScope = buildPlexTransferScopeId(serverId);
      final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      final oldCoOwnerScope = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-old-co-owner');
      await _putPinnedPlexMetadata(
        oldCoOwnerScope,
        id: '123',
        title: 'Preserved download',
        viewCount: 1,
        viewOffset: 12000,
      );

      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();

      await provider.detachDownloadsForLogout();

      expect((await db.getDownloadedMedia(key))?.clientScopeId, transferScope);
      expect(await db.hasDownloadOwner(key), isFalse);
      expect(await PlexApiCache.instance.getMetadata(scopeA.cacheServerId, '123'), isNull);
      expect(await PlexApiCache.instance.getMetadata(oldCoOwnerScope.cacheServerId, '123'), isNull);
      final transferred = await PlexApiCache.instance.getMetadata(transferScope.cacheServerId, '123');
      expect(transferred?.title, 'Preserved download');
      expect(transferred?.viewCount, isNull);
      expect(transferred?.viewOffsetMs, isNull);

      await db.delete(db.profiles).go();
      await db.delete(db.connections).go();
      await _insertProfile(db, 'profile-b');
      await _insertPlexConnection(db, serverId);

      final adoptedProvider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-b',
      );
      addTearDown(adoptedProvider.dispose);
      await adoptedProvider.ensureInitialized();

      final adoptedRow = await db.getDownloadedMedia(key);
      final adoptedOwner = await db.getDownloadOwner(profileId: 'profile-b', globalKey: key);
      expect(adoptedRow?.clientScopeId, scopeB);
      expect(adoptedOwner?.clientScopeId, scopeB);
      expect(adoptedOwner?.backend, MediaBackend.plex.id);
      expect(await PlexApiCache.instance.getMetadata(transferScope.cacheServerId, '123'), isNull);
      expect((await PlexApiCache.instance.getMetadata(scopeB.cacheServerId, '123'))?.title, 'Preserved download');
      expect(adoptedProvider.getMetadata(key)?.viewCount, isNull);
      expect(adoptedProvider.getMetadata(key)?.viewOffsetMs, isNull);
    });

    test('logout recovers legacy Plex ownership when row and owner scopes are absent', () async {
      await seedPhysicalDownload(owners: const ['profile-a', 'profile-b']);
      await db.updateDownloadedMediaClientScope(key, null);
      final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      final transferScope = buildPlexTransferScopeId(serverId);
      await _putPinnedPlexMetadata(scopeB, id: '123', title: 'Legacy owner snapshot', viewCount: 1, viewOffset: 4000);

      await downloadManager.preparePlexMetadataForLogoutTransfer();
      expect(await db.hasDownloadOwner(key), isTrue);
      expect((await db.getDownloadedMedia(key))?.clientScopeId, transferScope);
      final transferred = await PlexApiCache.instance.getMetadata(transferScope.cacheServerId, '123');
      expect(transferred?.title, 'Legacy owner snapshot');
      expect(transferred?.viewCount, isNull);
      expect(transferred?.viewOffsetMs, isNull);
    });

    test('missing active Plex owner scope clears the prior profile snapshot without bare fallback', () async {
      await seedPhysicalDownload(owners: const ['profile-a', 'profile-b']);
      final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      await _putPinnedPlexMetadata(scopeA, id: '123', title: 'Profile A snapshot', viewCount: 0, viewOffset: 12000);
      await PlexApiCache.instance.put(
        serverId,
        '/library/metadata/123',
        _plexMetadata(id: '123', title: 'Legacy bare snapshot', viewCount: 1, viewOffset: 0),
      );
      await PlexApiCache.instance.pinForOffline(serverId, '123');

      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {key: const DownloadProgress(globalKey: key, status: DownloadStatus.completed)},
        ownedDownloadKeys: {key},
      );
      await provider.refreshMetadataFromCache();
      expect(provider.getMetadata(key)?.title, 'Profile A snapshot');

      await waitForProfileReload(provider, 'profile-b', () => provider.getMetadata(key) == null);
      await provider.refreshMetadataFromCache();

      expect(provider.getMetadata(key), isNull);
      expect(await db.getDownloadedMedia(key), isNotNull);
    });

    test('a missing episode leaf does not evict parents loaded for a downloaded sibling', () async {
      await _insertPlexConnection(db, serverId);
      await _insertProfile(db, 'profile-a');
      final scope = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      for (final id in ['ep-1', 'ep-2']) {
        await db.insertDownload(
          serverId: serverId,
          clientScopeId: scope,
          ratingKey: id,
          globalKey: 'srv:$id',
          type: 'episode',
          parentRatingKey: 'season-1',
          grandparentRatingKey: 'show-1',
          status: DownloadStatus.completed.index,
        );
        await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'srv:$id');
      }

      Future<void> putPinned(String id, Map<String, Object?> metadata) async {
        await PlexApiCache.instance.put(scope.cacheServerId, '/library/metadata/$id', {
          'MediaContainer': {
            'Metadata': [metadata],
          },
        });
        await PlexApiCache.instance.pinForOffline(scope.cacheServerId, id);
      }

      await putPinned('show-1', {'ratingKey': 'show-1', 'type': 'show', 'title': 'Shared Show'});
      await putPinned('season-1', {
        'ratingKey': 'season-1',
        'type': 'season',
        'title': 'Season 1',
        'parentRatingKey': 'show-1',
      });
      await putPinned('ep-1', {
        'ratingKey': 'ep-1',
        'type': 'episode',
        'title': 'Available Episode',
        'parentRatingKey': 'season-1',
        'grandparentRatingKey': 'show-1',
      });
      final missingEpisode = testMediaItem(
        id: 'ep-2',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        title: 'Missing Episode',
        serverId: serverId,
        parentId: 'season-1',
        grandparentId: 'show-1',
      );
      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {
          'srv:ep-1': const DownloadProgress(globalKey: 'srv:ep-1', status: DownloadStatus.completed),
          'srv:ep-2': const DownloadProgress(globalKey: 'srv:ep-2', status: DownloadStatus.completed),
        },
        metadata: {'srv:ep-2': missingEpisode},
        ownedDownloadKeys: {'srv:ep-1', 'srv:ep-2'},
      );

      await provider.refreshMetadataFromCache();

      expect(provider.getMetadata('srv:ep-1')?.title, 'Available Episode');
      expect(provider.getMetadata('srv:ep-2'), isNull);
      expect(provider.getMetadata('srv:show-1')?.title, 'Shared Show');
      expect(provider.getMetadata('srv:season-1')?.title, 'Season 1');
    });
    test('scoped watch writeback mutates only the active Plex owner row despite co-ownership', () async {
      await seedPhysicalDownload(owners: const ['profile-a', 'profile-b']);
      final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      await _putPinnedPlexMetadata(scopeA, id: '123', title: 'Profile A snapshot', viewCount: 0, viewOffset: 12000);
      await _putPinnedPlexMetadata(scopeB, id: '123', title: 'Profile B snapshot', viewCount: 0, viewOffset: 34000);
      final activeClient = _ScopedTestClient(
        serverId: serverId,
        scopedServerId: scopeA,
        clientBackend: MediaBackend.plex,
      );
      testClientResolver = (resolvedServerId, {clientScopeId}) => resolvedServerId == serverId ? activeClient : null;

      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {key: const DownloadProgress(globalKey: key, status: DownloadStatus.completed)},
        ownedDownloadKeys: {key},
      );
      await provider.refreshMetadataFromCache();
      final item = provider.getMetadata(key)!;

      WatchStateNotifier().notifyWatched(item: item, cacheServerId: scopeA);
      await provider.debugWaitForWatchStateWrites();

      expect((await PlexApiCache.instance.getMetadata(scopeA.cacheServerId, '123'))?.isWatched, isTrue);
      expect((await PlexApiCache.instance.getMetadata(scopeB.cacheServerId, '123'))?.isWatched, isFalse);

      WatchStateNotifier().notifyWatched(item: item, cacheServerId: scopeB);
      await provider.debugWaitForWatchStateWrites();

      expect((await PlexApiCache.instance.getMetadata(scopeA.cacheServerId, '123'))?.isWatched, isTrue);
      expect((await PlexApiCache.instance.getMetadata(scopeB.cacheServerId, '123'))?.isWatched, isFalse);
    });

    test('claim and owner release pin and delete metadata per Plex owner reference', () async {
      await seedPhysicalDownload(owners: const ['profile-a', 'profile-b']);
      await db.removeDownloadOwner(profileId: 'profile-b', globalKey: key);
      final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      await _putPinnedPlexMetadata(scopeA, id: '123', title: 'Profile A snapshot', viewCount: 0, viewOffset: 12000);
      final profileBItem = testMediaItem(
        id: '123',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Profile B snapshot',
        serverId: serverId,
        viewCount: 1,
      );
      final clientB = _ScopedTestClient(
        serverId: serverId,
        scopedServerId: scopeB,
        clientBackend: MediaBackend.plex,
        fetchItemHandler: (id) async {
          await PlexApiCache.instance.put(
            scopeB.cacheServerId,
            '/library/metadata/$id',
            _plexMetadata(id: id, title: 'Profile B snapshot', viewCount: 1, viewOffset: 0),
          );
          return profileBItem;
        },
      );
      testClientResolver = (resolvedServerId, {clientScopeId}) =>
          resolvedServerId == serverId && (clientScopeId == null || clientScopeId == scopeB) ? clientB : null;

      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-b',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {key: const DownloadProgress(globalKey: key, status: DownloadStatus.completed)},
        ownedDownloadKeys: const {},
      );

      expect(await provider.queueDownload(profileBItem, clientB), 1);
      expect(await db.getDownloadOwnerCount(key), 2);
      expect(await db.getAllDownloadedMetadata(), hasLength(1));
      expect(await PlexApiCache.instance.isPinnedRatingKey(scopeA.cacheServerId, '123'), isTrue);
      expect(await PlexApiCache.instance.isPinnedRatingKey(scopeB.cacheServerId, '123'), isTrue);

      await provider.deleteDownloadsForProfile('profile-a');
      expect(await db.getDownloadOwnerCount(key), 1);
      expect(await db.getDownloadedMedia(key), isNotNull);
      expect(await PlexApiCache.instance.getMetadata(scopeA.cacheServerId, '123'), isNull);
      expect((await PlexApiCache.instance.getMetadata(scopeB.cacheServerId, '123'))?.title, 'Profile B snapshot');

      await provider.deleteDownload(key);
      expect(await db.getDownloadOwnerCount(key), 0);
      expect(await db.getDownloadedMedia(key), isNull);
      expect(await PlexApiCache.instance.getMetadata(scopeB.cacheServerId, '123'), isNull);
    });

    test('auto-delete protects only the exact active global key', () async {
      await _insertProfile(db, 'profile-a');
      for (final server in ['A', 'B']) {
        await db.insertDownload(
          serverId: ServerId(server),
          ratingKey: '123',
          globalKey: '$server:123',
          type: 'movie',
          status: DownloadStatus.completed.index,
        );
        await db.addDownloadOwner(profileId: 'profile-a', globalKey: '$server:123');
      }
      final itemA = testMediaItem(
        id: '123',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'A watched',
        serverId: 'A',
        viewCount: 1,
      );
      final itemB = itemA.copyWith(serverId: 'B', title: 'B watched');
      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {
          itemA.globalKey: DownloadProgress(globalKey: itemA.globalKey, status: DownloadStatus.completed),
          itemB.globalKey: DownloadProgress(globalKey: itemB.globalKey, status: DownloadStatus.completed),
        },
        metadata: {itemA.globalKey: itemA, itemB.globalKey: itemB},
        ownedDownloadKeys: {itemA.globalKey, itemB.globalKey},
      );

      expect(await provider.autoDeleteWatchedDownloads(activeGlobalKey: itemA.globalKey), ['B watched']);
      expect(provider.downloads.keys, [itemA.globalKey]);
      expect(await db.getDownloadedMedia(itemA.globalKey), isNotNull);
      expect(await db.getDownloadedMedia(itemB.globalKey), isNull);
    });

    test('auto-delete removes both same-id downloads when there is no active key', () async {
      await _insertProfile(db, 'profile-a');
      for (final server in ['A', 'B']) {
        await db.insertDownload(
          serverId: ServerId(server),
          ratingKey: '123',
          globalKey: '$server:123',
          type: 'movie',
          status: DownloadStatus.completed.index,
        );
        await db.addDownloadOwner(profileId: 'profile-a', globalKey: '$server:123');
      }
      final itemA = testMediaItem(
        id: '123',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'A watched',
        serverId: 'A',
        viewCount: 1,
      );
      final itemB = itemA.copyWith(serverId: 'B', title: 'B watched');
      final provider = DownloadProvider.forTesting(
        downloadManager: downloadManager,
        database: db,
        activeProfileId: 'profile-a',
      );
      addTearDown(provider.dispose);
      await provider.ensureInitialized();
      provider.debugSeedState(
        downloads: {
          itemA.globalKey: DownloadProgress(globalKey: itemA.globalKey, status: DownloadStatus.completed),
          itemB.globalKey: DownloadProgress(globalKey: itemB.globalKey, status: DownloadStatus.completed),
        },
        metadata: {itemA.globalKey: itemA, itemB.globalKey: itemB},
        ownedDownloadKeys: {itemA.globalKey, itemB.globalKey},
      );

      expect((await provider.autoDeleteWatchedDownloads()).toSet(), {'A watched', 'B watched'});
      expect(provider.downloads, isEmpty);
      expect(await db.getDownloadedMedia(itemA.globalKey), isNull);
      expect(await db.getDownloadedMedia(itemB.globalKey), isNull);
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
      expect(p.getMetadata(episode.globalKey), isNull);

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
