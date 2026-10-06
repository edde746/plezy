import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_collection_operations.dart';
import 'package:plezy/media/download_resolution.dart';
import 'package:plezy/media/ids.dart';
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
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/media_items.dart';

/// Answers collection lookups from [memberships] (or fails with [failure])
/// and serves the collections themselves from [fetchItem]. Every other call
/// reaches [noSuchMethod] and throws.
class _CollectionsClient implements MediaServerClient {
  _CollectionsClient(this.memberships);

  List<CollectionMembership> memberships;
  Object? failure;
  final lookups = <Set<String>>[];

  @override
  ServerId get serverId => ServerId('srv');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<List<CollectionMembership>> fetchCollectionMemberships(Set<String> itemIds, {AbortController? abort}) async {
    lookups.add(itemIds);
    if (failure case final failure?) throw failure;
    return memberships;
  }

  @override
  Future<MediaItem?> fetchItem(String id) async {
    for (final (:collection, memberIds: _) in memberships) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) => const [];

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _movie(String id) => testMediaItem(id: id, title: id, serverId: 'srv');

MediaItem _collection(String id) => testMediaItem(id: id, kind: MediaKind.collection, title: id, serverId: 'srv');

void main() {
  late AppDatabase db;
  late DownloadManagerService downloadManager;
  late DownloadProvider provider;
  late MultiServerManager serverManager;
  late _CollectionsClient client;

  void seedMovies(List<String> ids) {
    provider.debugSeedState(
      downloads: {
        for (final id in ids) 'srv:$id': DownloadProgress(globalKey: 'srv:$id', status: DownloadStatus.completed),
      },
      metadata: {for (final id in ids) 'srv:$id': _movie(id)},
    );
  }

  Future<void> sync() => provider.syncDownloadCollections(serverManager, ['srv']);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
    downloadManager = DownloadManagerService(
      database: db,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => null,
    )..recoveryFuture = Future<void>.value();
    provider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await provider.ensureInitialized();
    client = _CollectionsClient([
      (collection: _collection('dune'), memberIds: ['dune-1', 'dune-2']),
    ]);
    serverManager = MultiServerManager()..debugRegisterClientForTesting(client);
  });

  tearDown(() async {
    provider.dispose();
    serverManager.dispose();
    downloadManager.dispose();
    await db.close();
  });

  test('a refresh folds a collection\'s downloaded movies and stores the membership', () async {
    seedMovies(['dune-1', 'dune-2', 'other']);

    await sync();

    expect(client.lookups.single, {'dune-1', 'dune-2', 'other'});
    final grouped = provider.groupDownloadsByCollection(provider.downloadedMovies);
    expect([for (final item in grouped) item.id]..sort(), ['dune', 'other']);
    expect([for (final item in provider.downloadedCollectionItems('srv:dune')) item.id], ['dune-1', 'dune-2']);
    final stored = await db.getDownloadCollections('test-profile');
    expect(stored.single.collectionId, 'dune');
    expect(stored.single.memberIds, ['dune-1', 'dune-2']);
  });

  test('a fresh refresh is skipped until a title it did not cover is downloaded', () async {
    seedMovies(['dune-1', 'dune-2']);
    await sync();
    await sync();
    expect(client.lookups, hasLength(1));

    seedMovies(['dune-3']);
    await sync();

    expect(client.lookups, hasLength(2));
    expect(client.lookups.last, contains('dune-3'));
  });

  test('a failed refresh keeps the stored membership', () async {
    seedMovies(['dune-1', 'dune-2']);
    await sync();

    seedMovies(['dune-3']);
    client.failure = StateError('server went away');
    await sync();

    expect([for (final item in provider.downloadedCollectionItems('srv:dune')) item.id], ['dune-1', 'dune-2']);
    expect((await db.getDownloadCollections('test-profile')).single.memberIds, ['dune-1', 'dune-2']);
    // The failed pass recorded nothing, so the next connect looks up again.
    client.failure = null;
    await sync();
    expect(client.lookups, hasLength(3));
  });

  test('deleting a folder deletes every downloaded title in it', () async {
    seedMovies(['dune-1', 'dune-2', 'other']);
    await sync();

    await provider.deleteCollectionDownloads('srv:dune');

    expect([for (final item in provider.downloadedMovies) item.id], ['other']);
  });
}
