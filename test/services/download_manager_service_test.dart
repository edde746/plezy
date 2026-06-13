import 'dart:convert';
import 'package:vibe_stream/media/ids.dart';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/database/download_operations.dart';
import 'package:vibe_stream/media/download_resolution.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/media/media_server_client.dart';
import 'package:vibe_stream/models/download_models.dart';
import 'package:vibe_stream/services/download_artwork_helpers.dart';
import 'package:vibe_stream/services/download_artwork_service.dart';
import 'package:vibe_stream/services/download_manager_service.dart';
import 'package:vibe_stream/services/download_storage_service.dart';
import 'package:vibe_stream/services/jellyfin_api_cache.dart';
import 'package:vibe_stream/services/plex_api_cache.dart';
import 'package:vibe_stream/services/settings_service.dart';
import 'package:vibe_stream/utils/media_server_http_client.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../test_helpers/prefs.dart';

void main() {
  group('downloadExtensionFromUrl', () {
    test('uses path extension when present', () {
      expect(downloadExtensionFromUrl('https://example.com/movie.mkv?Container=mp4'), 'mkv');
    });

    test('uses Jellyfin Container query parameter when path has no extension', () {
      expect(downloadExtensionFromUrl('https://example.com/Videos/item/stream?Static=true&Container=mkv'), 'mkv');
    });

    test('normalizes and sanitizes container extensions', () {
      expect(downloadExtensionFromUrl('https://example.com/Videos/item/stream?Container=MKV,MP4'), 'mkv');
      expect(downloadExtensionFromUrl('https://example.com/Videos/item/stream?Container=../bad'), isNull);
    });
  });

  group('artworkStorageKey', () {
    test('removes Jellyfin api_key from persisted artwork keys', () {
      final url = 'https://jf.example/Items/item-1/Images/Primary?tag=abc&api_key=secret-token';

      expect(artworkStorageKey(url), 'https://jf.example/Items/item-1/Images/Primary?tag=abc');
      expect(buildArtworkSpecs(_movie(thumbPath: url), (path) => path).single.localKey, isNot(contains('api_key')));
    });
  });

  group('lookupMetadata', () {
    test('falls back from active Jellyfin scope to the download row scope', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);

      await db
          .into(db.connections)
          .insert(
            ConnectionsCompanion.insert(
              id: 'jf-machine/user-a',
              kind: 'jellyfin',
              displayName: 'User A · Jellyfin',
              configJson: jsonEncode({
                'baseUrl': 'https://jf.example',
                'serverName': 'Jellyfin',
                'serverMachineId': 'jf-machine',
                'userId': 'user-a',
                'userName': 'User A',
                'accessToken': 'token-a',
                'deviceId': 'device-a',
              }),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      await db
          .into(db.downloadedMedia)
          .insert(
            DownloadedMediaCompanion.insert(
              serverId: ServerId('jf-machine'),
              clientScopeId: const Value('jf-machine/user-a'),
              ratingKey: 'item-1',
              globalKey: 'jf-machine:item-1',
              type: 'movie',
              status: DownloadStatus.completed.index,
            ),
          );
      await db
          .into(db.apiCache)
          .insert(
            ApiCacheCompanion.insert(
              cacheKey: 'jf-machine/user-a:/Users/user-a/Items/item-1',
              data: jsonEncode({'Id': 'item-1', 'Type': 'Movie', 'Name': 'Cached for User A'}),
              pinned: const Value(true),
            ),
          );

      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) {
          return _ScopedJellyfinClient(
            serverId: ServerId(serverId),
            scopedServerId: clientScopeId ?? 'jf-machine/user-b',
          );
        },
      );

      final item = await manager.lookupMetadata(ServerId('jf-machine'), 'item-1', preferActiveScope: true);

      expect(item?.title, 'Cached for User A');
      expect(item?.serverId, 'jf-machine');
    });

    test('SAF recovery resolves show year from cached show metadata', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);

      await PlexApiCache.instance.put(ServerId('srv-1'), '/library/metadata/show-1', {
        'MediaContainer': {
          'Metadata': [
            {'ratingKey': 'show-1', 'type': 'show', 'title': 'The Show', 'year': 2008},
          ],
        },
      });

      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
      );
      final year = await manager.debugResolveSafRecoveryShowYear(
        MediaItem(
          id: 'ep-1',
          backend: MediaBackend.plex,
          kind: MediaKind.episode,
          serverId: ServerId('srv-1'),
          title: 'Episode from 2010',
          year: 2010,
          grandparentId: 'show-1',
          grandparentTitle: 'The Show',
          parentIndex: 1,
          index: 1,
        ),
      );

      expect(year, 2008);
    });

    test('Jellyfin offline pinning keeps media segment cache rows with metadata', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);

      await JellyfinApiCache.instance.put(ServerId('jf-machine/user-a'), '/Users/user-a/Items/item-1', {
        'Id': 'item-1',
        'Type': 'Episode',
        'Name': 'Episode',
      });
      await JellyfinApiCache.instance.put(ServerId('jf-machine/user-a'), '/MediaSegments/item-1', {
        'Items': [
          {'Type': 'Intro', 'StartTicks': 10000000, 'EndTicks': 20000000},
        ],
      });

      await JellyfinApiCache.instance.pinForOffline(ServerId('jf-machine/user-a'), 'item-1');

      expect(await JellyfinApiCache.instance.isPinned(ServerId('jf-machine/user-a'), '/MediaSegments/item-1'), isTrue);

      await JellyfinApiCache.instance.deleteForItem(ServerId('jf-machine/user-a'), 'item-1');

      expect(await JellyfinApiCache.instance.get(ServerId('jf-machine/user-a'), '/Users/user-a/Items/item-1'), isNull);
      expect(await JellyfinApiCache.instance.get(ServerId('jf-machine/user-a'), '/MediaSegments/item-1'), isNull);
    });

    test('artwork repair fetches full parent metadata and backfills thumb path', () async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      DownloadStorageService.resetForTesting();
      final tmpRoot = await Directory.systemTemp.createTemp('download_manager_artwork_repair_test_');
      PathProviderPlatform.instance = _FakePathProvider(tmpRoot);
      addTearDown(() async {
        DownloadStorageService.resetForTesting();
        SettingsService.resetForTesting();
        if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
      });

      final settings = await SettingsService.getInstance();
      final storage = DownloadStorageService.instance;
      await storage.initialize(settings);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);

      await db
          .into(db.downloadedMedia)
          .insert(
            DownloadedMediaCompanion.insert(
              serverId: ServerId('srv'),
              ratingKey: 'ep-1',
              globalKey: 'srv:ep-1',
              type: 'episode',
              parentRatingKey: const Value('season-1'),
              grandparentRatingKey: const Value('show-1'),
              status: DownloadStatus.completed.index,
            ),
          );
      await PlexApiCache.instance.put(ServerId('srv'), '/library/metadata/ep-1', {
        'MediaContainer': {
          'Metadata': [
            {
              'ratingKey': 'ep-1',
              'type': 'episode',
              'title': 'Episode',
              'thumb': '/ep-thumb',
              'parentRatingKey': 'season-1',
              'parentTitle': 'Season 1',
              'parentIndex': 1,
              'grandparentRatingKey': 'show-1',
              'grandparentTitle': 'Show',
            },
          ],
        },
      });
      await PlexApiCache.instance.put(ServerId('srv'), '/library/metadata/show-1', {
        'MediaContainer': {
          'Metadata': [
            {'ratingKey': 'show-1', 'type': 'show', 'title': 'Show', 'thumb': '/show-thumb'},
          ],
        },
      });

      final client = _ArtworkRepairClient(
        serverId: ServerId('srv'),
        items: {
          'show-1': MediaItem(
            id: 'show-1',
            backend: MediaBackend.plex,
            kind: MediaKind.show,
            serverId: ServerId('srv'),
            title: 'Show',
            thumbPath: '/show-thumb',
            clearLogoPath: '/show-logo',
            artPath: '/show-art',
            backgroundSquarePath: '/show-square',
          ),
        },
      );
      final manager = DownloadManagerService(
        database: db,
        storageService: storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        http: MediaServerHttpClient(client: _FakeHttpClient(200, utf8.encode('image bytes'))),
      );

      await manager.repairMissingArtworkForDownloads();

      expect(client.fetchCounts['show-1'], isNotNull);
      expect(client.fetchCounts['show-1']!, greaterThan(0));
      final logoPath = DownloadArtworkService.localPathSync(storage, ServerId('srv'), '/show-logo');
      expect(logoPath, isNotNull);
      expect(File(logoPath!).existsSync(), isTrue);
      final row = await db.getDownloadedMedia('srv:ep-1');
      expect(row?.thumbPath, artworkStorageKey('/ep-thumb'));
    });
  });

  group('task session validation', () {
    test('ignores progress from stale native task ids', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const globalKey = 'srv:item-1';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.downloading.index,
      );
      await db.updateBgTaskId(globalKey, 'current-task');

      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);
      final events = <DownloadProgress>[];
      final sub = manager.progressStream.listen(events.add);
      addTearDown(sub.cancel);

      await manager.debugHandleTaskProgress(TaskProgressUpdate(_downloadTask('stale-task', globalKey), 0.5, 1000));
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);

      await manager.debugHandleTaskProgress(TaskProgressUpdate(_downloadTask('current-task', globalKey), 0.5, 1000));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.globalKey, globalKey);
      expect(events.single.progress, 50);
    });

    test('ignores terminal status from stale native task ids', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const globalKey = 'srv:item-1';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.downloading.index,
      );
      await db.updateBgTaskId(globalKey, 'current-task');

      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);

      await manager.debugHandleTaskStatus(TaskStatusUpdate(_downloadTask('stale-task', globalKey), TaskStatus.failed));

      final row = await db.getDownloadedMedia(globalKey);
      expect(row?.status, DownloadStatus.downloading.index);
      expect(row?.errorMessage, isNull);
      expect(row?.bgTaskId, 'current-task');
    });

    test('requeues current system cancel without in-memory context', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const globalKey = 'srv:item-1';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.downloading.index,
      );
      await db.updateBgTaskId(globalKey, 'current-task');

      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);

      await manager.debugHandleTaskStatus(
        TaskStatusUpdate(_downloadTask('current-task', globalKey), TaskStatus.canceled),
      );

      final row = await db.getDownloadedMedia(globalKey);
      expect(row?.status, DownloadStatus.queued.index);
      expect(row?.bgTaskId, isNull);
      expect((await db.getNextQueueItem())?.mediaGlobalKey, globalKey);
    });
  });

  group('resume handling', () {
    test('failed native resume leaves paused row paused', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const globalKey = 'srv:item-1';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.paused.index,
      );
      await db.updateBgTaskId(globalKey, 'current-task');

      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);

      final resumed = await manager.debugTryResumeNativeTask(
        globalKey,
        'current-task',
        taskForId: (_) async => _downloadTask('current-task', globalKey),
        resumeTask: (_) async => false,
      );

      final row = await db.getDownloadedMedia(globalKey);
      expect(resumed, isFalse);
      expect(row?.status, DownloadStatus.paused.index);
      expect(row?.bgTaskId, 'current-task');
    });

    test('successful native resume transitions to downloading', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const globalKey = 'srv:item-1';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.paused.index,
      );
      await db.updateBgTaskId(globalKey, 'current-task');

      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (serverId, {clientScopeId}) => null,
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);

      final resumed = await manager.debugTryResumeNativeTask(
        globalKey,
        'current-task',
        taskForId: (_) async => _downloadTask('current-task', globalKey),
        resumeTask: (_) async => true,
      );

      final row = await db.getDownloadedMedia(globalKey);
      expect(resumed, isTrue);
      expect(row?.status, DownloadStatus.downloading.index);
      expect(row?.bgTaskId, 'current-task');
    });
  });
}

DownloadTask _downloadTask(String taskId, String globalKey) {
  return DownloadTask(
    taskId: taskId,
    url: 'https://example.test/video.mp4',
    filename: 'video.mp4',
    directory: 'downloads',
    metaData: globalKey,
  );
}

MediaItem _movie({String? thumbPath}) {
  return MediaItem(
    id: 'item-1',
    backend: MediaBackend.jellyfin,
    kind: MediaKind.movie,
    serverId: ServerId('jf-machine'),
    thumbPath: thumbPath,
  );
}

class _ScopedJellyfinClient implements MediaServerClient, ScopedMediaServerClient {
  _ScopedJellyfinClient({required this.serverId, required this.scopedServerId});

  @override
  final ServerId serverId;

  @override
  final String scopedServerId;

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationDocumentsPath() async => _ensure('documents');

  @override
  Future<String?> getApplicationSupportPath() async => _ensure('support');

  @override
  Future<String?> getApplicationCachePath() async => _ensure('cache');

  @override
  Future<String?> getTemporaryPath() async => _ensure('temp');

  String _ensure(String name) {
    final path = p.join(root.path, name);
    Directory(path).createSync(recursive: true);
    return path;
  }
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this.statusCode, this.body);

  final int statusCode;
  final List<int> body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream<List<int>>.value(body), statusCode, request: request);
  }
}

class _ArtworkRepairClient implements MediaServerClient {
  _ArtworkRepairClient({required this.serverId, required this.items});

  @override
  final ServerId serverId;

  final Map<String, MediaItem> items;
  final fetchCounts = <String, int>{};

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<MediaItem?> fetchItem(String id) async {
    fetchCounts[id] = (fetchCounts[id] ?? 0) + 1;
    return items[id];
  }

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) {
    return buildArtworkSpecs(item, (path) => 'https://example.test$path');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
