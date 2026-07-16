import 'dart:convert';
import 'package:plezy/media/ids.dart';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/media/download_resolution.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/services/download_artwork_helpers.dart';
import 'package:plezy/services/download_artwork_service.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/saf_storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

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

  group('partitionNativeTasks', () {
    test('separates the current task id from stale and duplicate tasks', () {
      final tasks = [
        _downloadTask('current', 'srv:item-1'),
        _downloadTask('stale', 'srv:item-1'),
        _downloadTask('current', 'srv:item-1'),
      ];

      final partition = partitionNativeTasks(tasks, 'current');

      expect(partition.current.map((task) => task.taskId), ['current', 'current']);
      expect(partition.stale.map((task) => task.taskId), ['stale']);
    });

    test('treats every native task as stale when the row has no task id', () {
      final tasks = [_downloadTask('first', 'srv:item-1'), _downloadTask('second', 'srv:item-1')];

      final partition = partitionNativeTasks(tasks, null);

      expect(partition.current, isEmpty);
      expect(partition.stale, tasks);
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
        testMediaItem(
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
      PathProviderPlatform.instance = FakePathProvider(tmpRoot);
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
          'show-1': testMediaItem(
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
        http: MediaServerHttpClient(client: FakeHttpClient(200, utf8.encode('image bytes'))),
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

  group('deletion cleanup', () {
    test('missing video still removes partial and subtitle sidecars', () async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      DownloadStorageService.resetForTesting();
      final tmpRoot = await Directory.systemTemp.createTemp('download_manager_delete_test_');
      PathProviderPlatform.instance = FakePathProvider(tmpRoot);
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

      final videoPath = p.join(tmpRoot.path, 'support', 'downloads', 'srv', 'item-1', 'video.mkv');
      final partial = File('$videoPath.part');
      final subtitles = Directory(videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs'));
      await partial.parent.create(recursive: true);
      await partial.writeAsString('partial');
      await subtitles.create(recursive: true);
      await File(p.join(subtitles.path, '1.srt')).writeAsString('subtitle');

      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: 'srv:item-1',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await db.updateVideoFilePath('srv:item-1', videoPath);
      final manager = DownloadManagerService(
        database: db,
        storageService: storage,
        clientResolver: (serverId, {clientScopeId}) => null,
      )..recoveryFuture = Future<void>.value();
      addTearDown(manager.dispose);

      await manager.deleteDownload('srv:item-1');

      expect(await partial.exists(), isFalse);
      expect(await subtitles.exists(), isFalse);
      expect(await db.getDownloadedMedia('srv:item-1'), isNull);
    });

    test('filesystem and SAF episode deletion apply the same cleanup policy', () async {
      final filesystem = await _runEpisodeDeletion(saf: false);
      final saf = await _runEpisodeDeletion(saf: true);

      expect(filesystem, saf);
      expect(
        filesystem,
        const _DeletionResult(
          rowDeleted: true,
          cacheDeleted: true,
          videoDeleted: true,
          thumbnailDeleted: true,
          subtitlesDeleted: true,
          progressItems: [0, 1],
        ),
      );
    });

    test('SAF deletion failure still cleans sidecars, cache, and database state', () async {
      final result = await _runEpisodeDeletion(saf: true, failVideoDeletion: true);

      expect(
        result,
        const _DeletionResult(
          rowDeleted: true,
          cacheDeleted: true,
          videoDeleted: false,
          thumbnailDeleted: true,
          subtitlesDeleted: true,
          progressItems: [0, 1],
        ),
      );
    });

    test('movie, season, and show deletion agree across filesystem and SAF', () async {
      for (final kind in [MediaKind.movie, MediaKind.season, MediaKind.show]) {
        final filesystem = await _runContainerDeletion(kind: kind, saf: false);
        final saf = await _runContainerDeletion(kind: kind, saf: true);

        expect(filesystem, saf, reason: '${kind.id} deletion differs by storage backend');
        expect(
          filesystem,
          const _ContainerDeletionResult(rowDeleted: true, cacheDeleted: true, directoryDeleted: true),
        );
      }
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

    test('ignores terminal status when the current row is no longer downloading', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const globalKey = 'srv:item-1';
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.completed.index,
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
      expect(row?.status, DownloadStatus.completed.index);
      expect(row?.bgTaskId, 'current-task');
      expect(await db.getNextQueueItem(), isNull);
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

Future<_DeletionResult> _runEpisodeDeletion({required bool saf, bool failVideoDeletion = false}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  DownloadStorageService.resetForTesting();
  final tmpRoot = await Directory.systemTemp.createTemp('download_manager_backend_delete_test_');
  PathProviderPlatform.instance = FakePathProvider(tmpRoot);

  final storage = saf ? DownloadStorageService.forTestingSaf('content://downloads') : DownloadStorageService.instance;
  if (!saf) {
    await storage.initialize(await SettingsService.getInstance());
  }

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  JellyfinApiCache.initialize(db);
  final serverId = ServerId('srv');
  const globalKey = 'srv:episode-1';
  final episode = testMediaItem(
    id: 'episode-1',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    serverId: serverId,
    title: 'Pilot',
    parentId: 'season-1',
    parentIndex: 1,
    grandparentId: 'show-1',
    grandparentTitle: 'Show',
    index: 1,
  );

  await PlexApiCache.instance.put(serverId, '/library/metadata/episode-1', {
    'MediaContainer': {
      'Metadata': [
        {
          'ratingKey': 'episode-1',
          'type': 'episode',
          'title': 'Pilot',
          'parentRatingKey': 'season-1',
          'parentIndex': 1,
          'grandparentRatingKey': 'show-1',
          'grandparentTitle': 'Show',
          'index': 1,
        },
      ],
    },
  });
  await PlexApiCache.instance.put(serverId, '/library/metadata/show-1', {
    'MediaContainer': {
      'Metadata': [
        {'ratingKey': 'show-1', 'type': 'show', 'title': 'Show', 'year': 2000},
      ],
    },
  });

  await db.insertDownload(
    serverId: serverId,
    ratingKey: 'episode-1',
    globalKey: globalKey,
    type: 'episode',
    parentRatingKey: 'season-1',
    grandparentRatingKey: 'show-1',
    status: DownloadStatus.completed.index,
  );

  const safVideoUri = 'content://episode-1.mkv';
  final filesystemVideoPath = await storage.getEpisodeVideoPath(episode, 'mkv', showYear: 2000);
  final storedVideoPath = saf ? safVideoUri : filesystemVideoPath;
  if (!saf) {
    await File(filesystemVideoPath).writeAsString('video');
  }
  await db.updateVideoFilePath(globalKey, storedVideoPath);

  final thumbnail = File(await storage.getEpisodeThumbnailPath(episode, showYear: 2000));
  await thumbnail.writeAsString('thumbnail');
  final subtitles = await storage.getEpisodeSubtitlesDirectory(episode, showYear: 2000);
  await File(p.join(subtitles.path, '1.srt')).writeAsString('subtitle');

  final safStorage = _FakeSafStorage(failDeletes: failVideoDeletion ? {safVideoUri} : const {});
  if (saf) {
    safStorage.addEpisode(storage, episode, videoUri: safVideoUri, showYear: 2000);
  }

  final manager = DownloadManagerService(
    database: db,
    storageService: storage,
    clientResolver: (serverId, {clientScopeId}) => null,
    safStorage: safStorage,
    downloadsSupportedOverride: false,
  )..recoveryFuture = Future<void>.value();
  final progress = <DeletionProgress>[];
  final subscription = manager.deletionProgressStream.listen(progress.add);

  try {
    await manager.deleteDownload(globalKey);
    await Future<void>.delayed(Duration.zero);
    return _DeletionResult(
      rowDeleted: await db.getDownloadedMedia(globalKey) == null,
      cacheDeleted: await PlexApiCache.instance.getMetadata(serverId, 'episode-1') == null,
      videoDeleted: saf ? !safStorage.existsSync(safVideoUri) : !await File(filesystemVideoPath).exists(),
      thumbnailDeleted: !await thumbnail.exists(),
      subtitlesDeleted: !await subtitles.exists(),
      progressItems: progress.map((event) => event.currentItem).toList(),
    );
  } finally {
    await subscription.cancel();
    manager.dispose();
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  }
}

Future<_ContainerDeletionResult> _runContainerDeletion({required MediaKind kind, required bool saf}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  DownloadStorageService.resetForTesting();
  final tmpRoot = await Directory.systemTemp.createTemp('download_manager_container_delete_test_');
  PathProviderPlatform.instance = FakePathProvider(tmpRoot);

  final storage = saf ? DownloadStorageService.forTestingSaf('content://downloads') : DownloadStorageService.instance;
  if (!saf) await storage.initialize(await SettingsService.getInstance());

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  JellyfinApiCache.initialize(db);
  final serverId = ServerId('srv');
  final id = '${kind.id}-1';
  final globalKey = 'srv:$id';
  final metadata = testMediaItem(
    id: id,
    backend: MediaBackend.plex,
    kind: kind,
    serverId: serverId,
    title: kind == MediaKind.movie ? 'Movie' : (kind == MediaKind.show ? 'Show' : 'Season 1'),
    year: 2000,
    parentId: kind == MediaKind.season ? 'show-1' : null,
    grandparentTitle: kind == MediaKind.season ? 'Show' : null,
    index: kind == MediaKind.season ? 1 : null,
  );
  await PlexApiCache.instance.put(serverId, '/library/metadata/$id', {
    'MediaContainer': {
      'Metadata': [
        {
          'ratingKey': id,
          'type': kind.id,
          'title': metadata.title,
          'year': 2000,
          if (kind == MediaKind.season) ...{'parentRatingKey': 'show-1', 'grandparentTitle': 'Show', 'index': 1},
        },
      ],
    },
  });
  await db.insertDownload(
    serverId: serverId,
    ratingKey: id,
    globalKey: globalKey,
    type: kind.id,
    status: DownloadStatus.completed.index,
  );

  final safStorage = _FakeSafStorage();
  Directory? filesystemDirectory;
  if (saf) {
    safStorage.addContainer(storage, metadata);
  } else {
    filesystemDirectory = switch (kind) {
      MediaKind.movie => await storage.getMovieDirectory(metadata),
      MediaKind.season => await storage.getSeasonDirectory(metadata),
      MediaKind.show => await storage.getShowDirectory(metadata),
      _ => throw StateError('Unsupported test kind: $kind'),
    };
    await File(p.join(filesystemDirectory.path, 'asset.bin')).writeAsString('asset');
  }

  final manager = DownloadManagerService(
    database: db,
    storageService: storage,
    clientResolver: (serverId, {clientScopeId}) => null,
    safStorage: safStorage,
    downloadsSupportedOverride: false,
  )..recoveryFuture = Future<void>.value();

  try {
    await manager.deleteDownload(globalKey);
    return _ContainerDeletionResult(
      rowDeleted: await db.getDownloadedMedia(globalKey) == null,
      cacheDeleted: await PlexApiCache.instance.getMetadata(serverId, id) == null,
      directoryDeleted: saf ? !safStorage.existsSync('content://target') : !await filesystemDirectory!.exists(),
    );
  } finally {
    manager.dispose();
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  }
}

class _DeletionResult {
  const _DeletionResult({
    required this.rowDeleted,
    required this.cacheDeleted,
    required this.videoDeleted,
    required this.thumbnailDeleted,
    required this.subtitlesDeleted,
    required this.progressItems,
  });

  final bool rowDeleted;
  final bool cacheDeleted;
  final bool videoDeleted;
  final bool thumbnailDeleted;
  final bool subtitlesDeleted;
  final List<int> progressItems;

  @override
  bool operator ==(Object other) =>
      other is _DeletionResult &&
      rowDeleted == other.rowDeleted &&
      cacheDeleted == other.cacheDeleted &&
      videoDeleted == other.videoDeleted &&
      thumbnailDeleted == other.thumbnailDeleted &&
      subtitlesDeleted == other.subtitlesDeleted &&
      _listEquals(progressItems, other.progressItems);

  @override
  int get hashCode => Object.hash(
    rowDeleted,
    cacheDeleted,
    videoDeleted,
    thumbnailDeleted,
    subtitlesDeleted,
    Object.hashAll(progressItems),
  );
}

class _ContainerDeletionResult {
  const _ContainerDeletionResult({
    required this.rowDeleted,
    required this.cacheDeleted,
    required this.directoryDeleted,
  });

  final bool rowDeleted;
  final bool cacheDeleted;
  final bool directoryDeleted;

  @override
  bool operator ==(Object other) =>
      other is _ContainerDeletionResult &&
      rowDeleted == other.rowDeleted &&
      cacheDeleted == other.cacheDeleted &&
      directoryDeleted == other.directoryDeleted;

  @override
  int get hashCode => Object.hash(rowDeleted, cacheDeleted, directoryDeleted);
}

bool _listEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

class _FakeSafStorage implements SafStorageOperations {
  _FakeSafStorage({this.failDeletes = const {}});

  final Set<String> failDeletes;
  final Map<String, SafDocumentFile> _childrenByPath = {};
  final Map<String, List<SafDocumentFile>> _childrenByUri = {};
  final Set<String> _existing = {};

  void addEpisode(
    DownloadStorageService storage,
    MediaItem episode, {
    required String videoUri,
    required int showYear,
  }) {
    const rootUri = 'content://downloads';
    const showUri = 'content://show';
    const seasonUri = 'content://season';
    final show = _document(showUri, 'Show (2000)', isDir: true);
    final season = _document(seasonUri, 'Season 01', isDir: true);
    final video = _document(videoUri, storage.getEpisodeSafFileName(episode, 'mkv'), isDir: false);

    _childrenByPath[_pathKey(rootUri, storage.getShowSafPathComponents(episode, showYear: showYear))] = show;
    _childrenByPath[_pathKey(rootUri, storage.getEpisodeSafPathComponents(episode, showYear: showYear))] = season;
    _childrenByUri[rootUri] = [show];
    _childrenByUri[showUri] = [season];
    _childrenByUri[seasonUri] = [video];
    _childrenByUri[videoUri] = [];
    _existing.addAll([rootUri, showUri, seasonUri, videoUri]);
  }

  void addContainer(DownloadStorageService storage, MediaItem metadata) {
    const rootUri = 'content://downloads';
    const targetUri = 'content://target';
    const assetUri = 'content://asset';
    final target = _document(targetUri, metadata.displayTitle, isDir: true);
    final asset = _document(assetUri, 'asset.bin', isDir: false);
    final components = switch (metadata.kind) {
      MediaKind.movie => storage.getMovieSafPathComponents(metadata),
      MediaKind.season => storage.getSeasonSafPathComponents(metadata),
      MediaKind.show => storage.getShowSafPathComponents(metadata),
      _ => throw StateError('Unsupported test kind: ${metadata.kind}'),
    };
    _childrenByPath[_pathKey(rootUri, components)] = target;
    _childrenByUri[targetUri] = [asset];
    _childrenByUri[assetUri] = [];
    _existing.addAll([rootUri, targetUri, assetUri]);

    if (metadata.kind == MediaKind.season) {
      const showUri = 'content://show';
      final show = _document(showUri, 'Show (2000)', isDir: true);
      _childrenByPath[_pathKey(rootUri, storage.getShowSafPathComponents(metadata))] = show;
      _childrenByUri[showUri] = [target];
      _existing.add(showUri);
    } else {
      _childrenByUri[rootUri] = [target];
    }
  }

  bool existsSync(String uri) => _existing.contains(uri);

  @override
  Future<SafDocumentFile?> getChild(String parentUri, List<String> names) async {
    return _childrenByPath[_pathKey(parentUri, names)];
  }

  @override
  Future<List<SafDocumentFile>?> list(String uri) async {
    return List<SafDocumentFile>.from(_childrenByUri[uri] ?? const []);
  }

  @override
  Future<bool> exists(String uri, {required bool isDir}) async => _existing.contains(uri);

  @override
  Future<bool> delete(String uri, {required bool isDir}) async {
    if (failDeletes.contains(uri)) return false;
    _existing.remove(uri);
    for (final children in _childrenByUri.values) {
      children.removeWhere((child) => child.uri == uri);
    }
    return true;
  }

  String _pathKey(String parentUri, List<String> names) => '$parentUri/${names.join('/')}';

  SafDocumentFile _document(String uri, String name, {required bool isDir}) {
    return SafDocumentFile(uri: uri, name: name, isDir: isDir, length: 0, lastModified: 0);
  }
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
  return testMediaItem(
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
