import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/sync_rule_executor.dart';

import '../test_helpers/prefs.dart';

JellyfinConnection _jellyfinConnection(String userId) => JellyfinConnection(
  id: 'jf-machine/$userId',
  baseUrl: 'https://jf.example.com',
  serverName: 'Shared JF',
  serverMachineId: 'jf-machine',
  userId: userId,
  userName: userId,
  accessToken: 'token-$userId',
  deviceId: 'device',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

void main() {
  setUp(resetSharedPreferencesForTest);

  test('profile-scoped Jellyfin sync rule executes through active client', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });

    final pathsByUser = <String, List<String>>{'user-a': [], 'user-b': []};

    JellyfinClient clientFor(String userId) {
      return JellyfinClient.forTesting(
        connection: _jellyfinConnection(userId),
        httpClient: MockClient((request) async {
          pathsByUser[userId]!.add('${request.method} ${request.url.path}?${request.url.query}');
          if (request.method == 'GET' && request.url.path == '/Users/$userId/Items/show-1') {
            return http.Response(
              '{"Id":"show-1","Type":"Series","Name":"Show $userId","RecursiveItemCount":1}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET' && request.url.path == '/Items') {
            return http.Response(
              '{"Items":[{"Id":"ep-1","Type":"Episode","Name":"Episode $userId","SeriesId":"show-1","UserData":{"PlayCount":0}}]}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        }),
      );
    }

    final userA = clientFor('user-a');
    final userB = clientFor('user-b');
    addTearDown(userA.close);
    addTearDown(userB.close);

    manager.debugRegisterJellyfinClientForTesting(userB, online: false);
    manager.debugRegisterJellyfinClientForTesting(userA);

    await db.insertSyncRule(
      profileId: 'profile-a',
      serverId: 'jf-machine',
      ratingKey: 'show-1',
      globalKey: 'profile-a|jf-machine:show-1',
      targetType: 'show',
      episodeCount: 1,
    );
    await db.insertWatchAction(
      serverId: 'jf-machine',
      clientScopeId: 'jf-machine/user-b',
      ratingKey: 'ep-1',
      actionType: OfflineActionType.watched.id,
    );
    await db.insertWatchAction(
      profileId: 'profile-b',
      serverId: 'jf-machine',
      clientScopeId: 'jf-machine/user-a',
      ratingKey: 'ep-1',
      actionType: OfflineActionType.watched.id,
    );

    final queued = <({MediaItem item, MediaServerClient client})>[];
    final executor = SyncRuleExecutor(database: db);
    final results = await executor.executeSyncRules(
      profileId: 'profile-a',
      serverManager: manager,
      downloads: const {},
      metadata: const {},
      queueSingleDownload: (item, client, {int mediaIndex = 0}) async {
        queued.add((item: item, client: client));
        return true;
      },
      force: true,
    );

    expect(results.single.queuedCount, 1);
    expect(queued.single.client, same(userA));
    expect(pathsByUser['user-a']!.where((p) => p.startsWith('GET /Items?')), isNotEmpty);
    expect(pathsByUser['user-b'], isEmpty);
  });

  test('profile-scoped sync rule excludes only the active profile local watched actions', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });

    final paths = <String>[];
    final userA = JellyfinClient.forTesting(
      connection: _jellyfinConnection('user-a'),
      httpClient: MockClient((request) async {
        paths.add('${request.method} ${request.url.path}?${request.url.query}');
        if (request.method == 'GET' && request.url.path == '/Users/user-a/Items/show-1') {
          return http.Response(
            '{"Id":"show-1","Type":"Series","Name":"Show","RecursiveItemCount":1}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && request.url.path == '/Items') {
          return http.Response(
            '{"Items":[{"Id":"ep-1","Type":"Episode","Name":"Episode","SeriesId":"show-1","UserData":{"PlayCount":0}}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      }),
    );
    addTearDown(userA.close);
    manager.debugRegisterJellyfinClientForTesting(userA);

    await db.insertSyncRule(
      profileId: 'profile-a',
      serverId: 'jf-machine',
      ratingKey: 'show-1',
      globalKey: 'profile-a|jf-machine:show-1',
      targetType: 'show',
      episodeCount: 1,
    );
    await db.insertWatchAction(
      profileId: 'profile-a',
      serverId: 'jf-machine',
      clientScopeId: 'jf-machine/user-a',
      ratingKey: 'ep-1',
      actionType: OfflineActionType.watched.id,
    );

    final queued = <MediaItem>[];
    final executor = SyncRuleExecutor(database: db);
    final results = await executor.executeSyncRules(
      profileId: 'profile-a',
      serverManager: manager,
      downloads: const {},
      metadata: const {},
      queueSingleDownload: (item, client, {int mediaIndex = 0}) async {
        queued.add(item);
        return true;
      },
      force: true,
    );

    expect(results, isEmpty);
    expect(queued, isEmpty);
    expect(paths.where((p) => p.startsWith('GET /Items?')), isNotEmpty);
  });

  test('profile-scoped Jellyfin sync rule does not execute for another profile', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });

    final paths = <String>[];
    final userB = JellyfinClient.forTesting(
      connection: _jellyfinConnection('user-b'),
      httpClient: MockClient((request) async {
        paths.add('${request.method} ${request.url.path}?${request.url.query}');
        return http.Response('not found', 404);
      }),
    );
    addTearDown(userB.close);
    manager.debugRegisterJellyfinClientForTesting(userB);

    await db.insertSyncRule(
      profileId: 'profile-a',
      serverId: 'jf-machine',
      ratingKey: 'show-1',
      globalKey: 'profile-a|jf-machine:show-1',
      targetType: 'show',
      episodeCount: 1,
    );

    final executor = SyncRuleExecutor(database: db);
    final results = await executor.executeSyncRules(
      profileId: 'profile-b',
      serverManager: manager,
      downloads: const {},
      metadata: const {},
      queueSingleDownload: (item, client, {int mediaIndex = 0}) async => true,
      force: true,
    );

    expect(results, isEmpty);
    expect(paths, isEmpty);
  });

  test('profile-scoped Jellyfin sync rule counts shared public downloads as already present', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });

    final paths = <String>[];
    final userB = JellyfinClient.forTesting(
      connection: _jellyfinConnection('user-b'),
      httpClient: MockClient((request) async {
        paths.add('${request.method} ${request.url.path}?${request.url.query}');
        if (request.method == 'GET' && request.url.path == '/Users/user-b/Items/show-1') {
          return http.Response(
            '{"Id":"show-1","Type":"Series","Name":"Show","RecursiveItemCount":1}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && request.url.path == '/Items') {
          return http.Response(
            '{"Items":[{"Id":"ep-1","Type":"Episode","Name":"Episode","SeriesId":"show-1","UserData":{"PlayCount":0}}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      }),
    );
    addTearDown(userB.close);
    manager.debugRegisterJellyfinClientForTesting(userB);

    await db.insertSyncRule(
      profileId: 'profile-b',
      serverId: 'jf-machine',
      ratingKey: 'show-1',
      globalKey: 'profile-b|jf-machine:show-1',
      targetType: 'show',
      episodeCount: 1,
    );

    final queued = <MediaItem>[];
    final executor = SyncRuleExecutor(database: db);
    final results = await executor.executeSyncRules(
      profileId: 'profile-b',
      serverManager: manager,
      downloads: const {
        'jf-machine:ep-1': DownloadProgress(globalKey: 'jf-machine:ep-1', status: DownloadStatus.completed),
      },
      metadata: const {},
      queueSingleDownload: (item, client, {int mediaIndex = 0}) async {
        queued.add(item);
        return true;
      },
      force: true,
    );

    expect(results, isEmpty);
    expect(queued, isEmpty);
    expect(paths.where((p) => p.startsWith('GET /Items?')), isNotEmpty);
  });

  test('collection sync rule pages through collection API instead of metadata children', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final manager = MultiServerManager();
    addTearDown(() async {
      manager.dispose();
      await db.close();
    });

    final client = _CollectionPagingClient();
    manager.debugRegisterClientForTesting(client);

    const ruleKey = 'profile-a|plex-machine:collection-1';
    final collection = MediaItem(
      id: 'collection-1',
      backend: MediaBackend.plex,
      kind: MediaKind.collection,
      title: 'Collection',
      serverId: 'plex-machine',
    );

    await db.insertSyncRule(
      profileId: 'profile-a',
      serverId: 'plex-machine',
      ratingKey: 'collection-1',
      globalKey: ruleKey,
      targetType: 'collection',
      episodeCount: 0,
      downloadFilter: SyncRuleFilter.all,
    );

    final queued = <MediaItem>[];
    final executor = SyncRuleExecutor(database: db);
    final results = await executor.executeSyncRules(
      profileId: 'profile-a',
      serverManager: manager,
      downloads: const {},
      metadata: {ruleKey: collection},
      queueSingleDownload: (item, client, {int mediaIndex = 0}) async {
        queued.add(item);
        return true;
      },
      force: true,
    );

    expect(results.single.queuedCount, 1);
    expect(queued.single.id, 'movie-1');
    expect(client.collectionPageCalls, [(start: 0, size: 100)]);
    expect(client.fetchChildrenCalled, isFalse);
  });
}

class _CollectionPagingClient implements MediaServerClient {
  bool fetchChildrenCalled = false;
  final collectionPageCalls = <({int? start, int? size})>[];

  @override
  String get serverId => 'plex-machine';

  @override
  String? get serverName => 'Plex';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  bool get isOfflineMode => false;

  @override
  void close() {}

  @override
  Future<MediaItem?> fetchItem(String id) async => null;

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    fetchChildrenCalled = true;
    throw StateError('collection rules must not use fetchChildren');
  }

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(String collectionId, {int? start, int? size, abort}) async {
    collectionPageCalls.add((start: start, size: size));
    expect(collectionId, 'collection-1');
    return LibraryPage(
      items: [MediaItem(id: 'movie-1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie')],
      totalCount: 1,
      offset: start ?? 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
