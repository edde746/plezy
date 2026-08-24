import 'dart:async';

import 'dart:convert';
import 'package:plezy/media/ids.dart';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/download_resolution.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_source_info.dart';
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
import 'package:plezy/utils/active_client_scope.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

import '../test_helpers/download_fixtures.dart';
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

  group('isRelocatedRootTaskDirectory', () {
    const baseAppDir = '/mnt/expand/9f2a/user/0/com.edde746.plezy/app_flutter';
    // Task strips one leading separator from `directory`, so a root-anchored task is
    // rejoined against the downloader's own root base before it can be compared.
    const rootBase = '/';

    test('flags an absolute directory left behind by the previous app location', () {
      final task = _rootTask('t', 'srv:item-1', '/data/user/0/com.edde746.plezy/app_flutter/downloads/srv/item-1');

      expect(task.directory, 'data/user/0/com.edde746.plezy/app_flutter/downloads/srv/item-1');
      expect(isRelocatedRootTaskDirectory(task: task, rootBasePath: rootBase, baseAppDirPath: baseAppDir), isTrue);
    });

    test('accepts a directory inside the live app storage', () {
      final task = _rootTask('t', 'srv:item-1', '$baseAppDir/downloads/srv/item-1');

      expect(isRelocatedRootTaskDirectory(task: task, rootBasePath: rootBase, baseAppDirPath: baseAppDir), isFalse);
    });

    test('accepts a directory inside the configured custom download root', () {
      final task = _rootTask('t', 'srv:item-1', '/Volumes/External/Plezy/Movies/Arrival (2016)');

      expect(
        isRelocatedRootTaskDirectory(
          task: task,
          rootBasePath: rootBase,
          baseAppDirPath: baseAppDir,
          customRootPath: '/Volumes/External/Plezy',
        ),
        isFalse,
      );
    });

    test('ignores a SAF task, whose root-anchored directory is a content tree URI', () {
      final task = UriDownloadTask(
        taskId: 't',
        url: 'https://example.test/video.mp4',
        filename: 'video.mp4',
        directoryUri: Uri.parse('content://com.android.externalstorage.documents/tree/usb%3APlezy'),
        metaData: 'srv:item-1',
      );

      expect(task.baseDirectory, BaseDirectory.root);
      expect(isRelocatedRootTaskDirectory(task: task, rootBasePath: rootBase, baseAppDirPath: baseAppDir), isFalse);
    });

    test('ignores a task anchored to a base directory the downloader re-resolves itself', () {
      final task = _downloadTask('t', 'srv:item-1');

      expect(task.baseDirectory, isNot(BaseDirectory.root));
      expect(isRelocatedRootTaskDirectory(task: task, rootBasePath: rootBase, baseAppDirPath: baseAppDir), isFalse);
    });
  });

  group('relocated task recovery', () {
    late Directory tmpRoot;
    late PathProviderPlatform previousPathProvider;

    setUp(() async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      DownloadStorageService.resetForTesting();
      tmpRoot = await Directory.systemTemp.createTemp('dms_relocated_');
      previousPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = FakePathProvider(tmpRoot);
      await DownloadStorageService.instance.initialize(await SettingsService.getInstance());
    });

    tearDown(() async {
      DownloadStorageService.resetForTesting();
      SettingsService.resetForTesting();
      PathProviderPlatform.instance = previousPathProvider;
      if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
    });

    late List<String> cancelledIds;
    late List<String> deletedRecordIds;
    late List<String> callOrder;

    Future<DownloadManagerService> managerFor(
      AppDatabase db, {
      List<Task> nativeTasks = const [],
      List<TaskRecord> records = const [],
    }) async {
      cancelledIds = [];
      deletedRecordIds = [];
      callOrder = [];
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
        downloadsSupportedOverride: true,
        fileDownloaderInitializerOverride: () async => callOrder.add('initialize'),
        nativeOpsOverride: (
          allTasks: () async => nativeTasks,
          allRecords: () async {
            callOrder.add('allRecords');
            return records;
          },
          deleteRecord: (taskId) async {
            callOrder.add('deleteRecord:$taskId');
            deletedRecordIds.add(taskId);
          },
          cancelTaskIds: (taskIds) async {
            callOrder.add('cancel:${taskIds.join(",")}');
            cancelledIds.addAll(taskIds);
            return true;
          },
          cleanUpOrphanedTempFiles: () async => 0,
          rescheduleKilledTasks: () async {
            callOrder.add('reschedule');
            return (<Task>[], <Task>[]);
          },
        ),
      );
      addTearDown(manager.dispose);
      return manager;
    }

    Future<void> seedRow(AppDatabase db, DownloadStatus status, {String? taskId, String? videoFilePath}) async {
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: 'srv:item-1',
        type: 'movie',
        status: status.index,
      );
      if (taskId != null) await db.updateBgTaskId('srv:item-1', taskId);
      if (videoFilePath != null) await db.updateVideoFilePath('srv:item-1', videoFilePath);
    }

    test('cancels a still-live task targeting the previous app location and requeues it', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, DownloadStatus.downloading, taskId: 'task-a');
      final manager = await managerFor(
        db,
        nativeTasks: [_rootTask('task-a', 'srv:item-1', '$_previousAppDir/downloads/srv/item-1')],
      );

      await manager.debugRecoverRelocatedDownloads();

      expect(cancelledIds, ['task-a']);
      final row = await db.getDownloadedMedia('srv:item-1');
      expect(row?.status, DownloadStatus.queued.index);
      expect(row?.bgTaskId, isNull);
      expect((await db.getNextQueueItem())?.mediaGlobalKey, 'srv:item-1');
    });

    test('drops a relocated record before rescheduling can re-enqueue it', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, DownloadStatus.downloading, taskId: 'task-a');
      // A killed task survives only as a downloader record: rescheduleKilledTasks would
      // re-enqueue it against the old volume, so it must be gone before that runs.
      final manager = await managerFor(
        db,
        records: [
          TaskRecord(
            _rootTask('task-a', 'srv:item-1', '$_previousAppDir/downloads/srv/item-1'),
            TaskStatus.enqueued,
            0.4,
            1024,
          ),
        ],
      );

      await manager.debugRecoverRelocatedDownloads();

      expect(deletedRecordIds, ['task-a']);
      expect(cancelledIds, ['task-a']);
      final row = await db.getDownloadedMedia('srv:item-1');
      expect(row?.status, DownloadStatus.queued.index);
      expect(row?.bgTaskId, isNull);
      expect((await db.getNextQueueItem())?.mediaGlobalKey, 'srv:item-1');
    });

    test('keeps a record that still points inside the live app storage', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, DownloadStatus.downloading, taskId: 'task-a');
      final liveDir = p.join(
        await DownloadStorageService.instance.baseAppDirectoryPath(),
        'downloads',
        'srv',
        'item-1',
      );
      final task = _rootTask('task-a', 'srv:item-1', liveDir);
      final manager = await managerFor(
        db,
        nativeTasks: [task],
        records: [TaskRecord(task, TaskStatus.enqueued, 0.4, 1024)],
      );

      await manager.debugRecoverRelocatedDownloads();

      expect(deletedRecordIds, isEmpty);
      expect(cancelledIds, isEmpty);
      final row = await db.getDownloadedMedia('srv:item-1');
      expect(row?.status, DownloadStatus.downloading.index);
      expect(row?.bgTaskId, 'task-a');
      expect(await db.getNextQueueItem(), isNull);
    });

    test('cancels a stale task for a finished download without disturbing the row', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, DownloadStatus.completed, videoFilePath: 'downloads/srv/item-1/video.mkv');
      final manager = await managerFor(
        db,
        nativeTasks: [_rootTask('task-a', 'srv:item-1', '$_previousAppDir/downloads/srv/item-1')],
      );

      await manager.debugRecoverRelocatedDownloads();

      expect(cancelledIds, ['task-a']);
      final row = await db.getDownloadedMedia('srv:item-1');
      expect(row?.status, DownloadStatus.completed.index);
      expect(row?.videoFilePath, 'downloads/srv/item-1/video.mkv');
      expect(await db.getNextQueueItem(), isNull);
    });

    test('startup drops relocated records before wiring up the downloader', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, DownloadStatus.downloading, taskId: 'task-a');
      final manager = await managerFor(
        db,
        records: [
          TaskRecord(
            _rootTask('task-a', 'srv:item-1', '$_previousAppDir/downloads/srv/item-1'),
            TaskStatus.enqueued,
            0.4,
            1024,
          ),
        ],
      );

      await manager.recoverInterruptedDownloads();

      // Initialization delivers statuses accumulated while suspended, which can mark the
      // row failed and make it unrestartable; rescheduleKilledTasks then re-enqueues every
      // enqueued record it finds missing natively, stale absolute directory and all. The
      // record has to be gone before either.
      expect(callOrder, ['allRecords', 'deleteRecord:task-a', 'cancel:task-a', 'initialize', 'reschedule']);
      expect((await db.getNextQueueItem())?.mediaGlobalKey, 'srv:item-1');
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
    test('active Jellyfin lookup does not fall back to the downloaded foreign user scope', () async {
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

      expect(item, isNull);
    });

    test('cold Jellyfin hydration resolves the active profile binding instead of the shared download scope', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);

      for (final userId in ['user-a', 'user-b']) {
        final profileId = 'profile-${userId.substring(userId.length - 1)}';
        await db
            .into(db.connections)
            .insert(
              ConnectionsCompanion.insert(
                id: 'jf-machine/$userId',
                kind: 'jellyfin',
                displayName: userId,
                configJson: jsonEncode({
                  'baseUrl': 'https://jf.example',
                  'serverName': 'Jellyfin',
                  'serverMachineId': 'jf-machine',
                  'userId': userId,
                  'userName': userId,
                  'accessToken': 'token-$userId',
                  'deviceId': 'device',
                }),
                createdAt: 0,
              ),
            );
        await db
            .into(db.profileConnections)
            .insert(
              ProfileConnectionsCompanion.insert(
                profileId: profileId,
                connectionId: 'jf-machine/$userId',
                userIdentifier: userId,
              ),
            );
        await JellyfinApiCache.instance.put(ServerId('jf-machine/$userId'), '/Users/$userId/Items/item-1', {
          'Id': 'item-1',
          'Type': 'Movie',
          'Name': 'Cached for $userId',
        });
        await JellyfinApiCache.instance.pinForOffline(ServerId('jf-machine/$userId'), 'item-1');
      }
      await db.insertDownload(
        serverId: ServerId('jf-machine'),
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(profileId: 'profile-a', globalKey: 'jf-machine:item-1');
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'jf-machine:item-1');
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
      );

      final all = await manager.getAllPinnedMetadata(activeProfileId: 'profile-b');
      final item = await manager.lookupMetadata(
        ServerId('jf-machine'),
        'item-1',
        preferActiveScope: true,
        activeProfileId: 'profile-b',
      );

      expect(all.keys, ['jf-machine/user-b:item-1']);
      expect(all.values.single.title, 'Cached for user-b');
      expect(item?.title, 'Cached for user-b');
    });

    test('cold Plex hydration finds a server inside its persisted account configuration', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);
      final serverId = ServerId('plex-machine');
      final scope = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      await db
          .into(db.connections)
          .insert(
            ConnectionsCompanion.insert(
              id: 'plex-account-uuid',
              kind: 'plex',
              displayName: 'Plex account',
              configJson: jsonEncode({
                'servers': [
                  {'clientIdentifier': serverId},
                ],
              }),
              createdAt: 0,
            ),
          );
      await db.insertDownload(
        serverId: serverId,
        clientScopeId: serverId,
        ratingKey: 'item-1',
        globalKey: 'plex-machine:item-1',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(profileId: 'profile-b', globalKey: 'plex-machine:item-1');
      await PlexApiCache.instance.put(scope.cacheServerId, '/library/metadata/item-1', {
        'MediaContainer': {
          'Metadata': [
            {'ratingKey': 'item-1', 'type': 'movie', 'title': 'Offline Plex'},
          ],
        },
      });
      await PlexApiCache.instance.pinForOffline(scope.cacheServerId, 'item-1');
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
      );

      final all = await manager.getAllPinnedMetadata(activeProfileId: 'profile-b');
      final item = await manager.lookupMetadata(
        serverId,
        'item-1',
        preferActiveScope: true,
        activeProfileId: 'profile-b',
      );

      expect(all['plex-machine:item-1']?.title, 'Offline Plex');
      expect(item?.title, 'Offline Plex');
    });

    test('active Plex lookup selects the exact profile namespace without bare fallback', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);
      final serverId = ServerId('plex-machine');
      final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      Map<String, Object?> metadata(String title) => {
        'MediaContainer': {
          'Metadata': [
            {'ratingKey': 'item-1', 'type': 'movie', 'title': title},
          ],
        },
      };
      await PlexApiCache.instance.put(scopeA.cacheServerId, '/library/metadata/item-1', metadata('Profile A'));
      await PlexApiCache.instance.put(scopeB.cacheServerId, '/library/metadata/item-1', metadata('Profile B'));
      await PlexApiCache.instance.put(serverId, '/library/metadata/item-1', metadata('Legacy bare'));
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (resolvedServerId, {clientScopeId}) =>
            _ArtworkRepairClient(serverId: ServerId(resolvedServerId), items: const {}),
      );

      final item = await manager.lookupMetadata(
        serverId,
        'item-1',
        preferActiveScope: true,
        activeProfileId: 'profile-a',
      );
      final missing = await manager.lookupMetadata(
        serverId,
        'item-1',
        preferActiveScope: true,
        activeProfileId: 'profile-missing',
      );

      expect(item?.title, 'Profile A');
      expect(missing, isNull);
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

    test('interrupted Plex logout transfer recovers from the physical row transfer scope', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);
      final serverId = ServerId('plex-machine');
      final profileScope = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      final transferScope = buildPlexTransferScopeId(serverId);
      await db.insertDownload(
        serverId: serverId,
        clientScopeId: profileScope,
        ratingKey: 'item-1',
        globalKey: 'plex-machine:item-1',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      await db.addDownloadOwner(
        profileId: 'profile-a',
        globalKey: 'plex-machine:item-1',
        backendId: MediaBackend.plex.id,
        clientScopeId: profileScope,
      );
      await PlexApiCache.instance.put(profileScope.cacheServerId, '/library/metadata/item-1', {
        'MediaContainer': {
          'Metadata': [
            {'ratingKey': 'item-1', 'type': 'movie', 'title': 'Recovered transfer'},
          ],
        },
      });
      await PlexApiCache.instance.pinForOffline(profileScope.cacheServerId, 'item-1');
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
      );

      await manager.preparePlexMetadataForLogoutTransfer();

      expect((await db.getDownloadedMedia('plex-machine:item-1'))?.clientScopeId, transferScope);
      expect(
        (await db.getDownloadOwner(profileId: 'profile-a', globalKey: 'plex-machine:item-1'))?.clientScopeId,
        profileScope,
      );
      expect(
        (await PlexApiCache.instance.getMetadata(transferScope.cacheServerId, 'item-1'))?.title,
        'Recovered transfer',
      );

      await manager.adoptTransferredPlexMetadataForProfile('profile-a');

      final recoveredOwner = await db.getDownloadOwner(profileId: 'profile-a', globalKey: 'plex-machine:item-1');
      expect((await db.getDownloadedMedia('plex-machine:item-1'))?.clientScopeId, profileScope);
      expect(recoveredOwner?.backend, MediaBackend.plex.id);
      expect(recoveredOwner?.clientScopeId, profileScope);
      expect(await PlexApiCache.instance.getMetadata(transferScope.cacheServerId, 'item-1'), isNull);
      expect(
        (await PlexApiCache.instance.getMetadata(profileScope.cacheServerId, 'item-1'))?.title,
        'Recovered transfer',
      );
    });

    test('missing Plex leaf survives full logout and rehydrates after replacement adoption', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);
      final serverId = ServerId('plex-machine');
      const globalKey = 'plex-machine:item-1';
      final originalScope = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
      final transferScope = buildPlexTransferScopeId(serverId);
      final destinationScope = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');
      for (final profileId in const ['profile-a', 'profile-b']) {
        await db
            .into(db.profiles)
            .insert(
              ProfilesCompanion.insert(
                id: profileId,
                kind: 'local',
                displayName: profileId,
                configJson: '{}',
                createdAt: 0,
              ),
            );
      }
      await db.insertDownload(
        serverId: serverId,
        clientScopeId: originalScope,
        ratingKey: 'item-1',
        globalKey: globalKey,
        type: 'movie',
        status: DownloadStatus.completed.index,
        mediaIndex: 2,
        mediaSourceId: 'source-a',
      );
      await db.updateDownloadProgress(globalKey, 100, 900, 900);
      await db.updateVideoFilePath(globalKey, 'downloads/plex-machine/item-1/video.mp4');
      await db.addToQueue(mediaGlobalKey: globalKey, priority: 7, downloadSubtitles: false, downloadArtwork: true);
      await db.addDownloadOwner(
        profileId: 'profile-a',
        globalKey: globalKey,
        backendId: MediaBackend.plex.id,
        clientScopeId: originalScope,
      );
      final before = (await db.getDownloadedMedia(globalKey))!;
      final queueBefore = (await db.select(db.downloadQueue).get()).single;
      expect(await PlexApiCache.instance.getMetadata(originalScope.cacheServerId, 'item-1'), isNull);

      final transferManager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
      );
      await transferManager.preparePlexMetadataForLogoutTransfer();

      expect((await db.getDownloadedMedia(globalKey))?.clientScopeId, transferScope);
      expect((await db.getDownloadOwner(profileId: 'profile-a', globalKey: globalKey))?.clientScopeId, originalScope);
      expect(await PlexApiCache.instance.getMetadata(transferScope.cacheServerId, 'item-1'), isNull);

      await db.clearAllDownloadOwners();
      expect(await db.getValidDownloadOwnersForKey(globalKey), isEmpty);
      await db.adoptLegacyDownloadsForProfile('profile-b');
      await transferManager.adoptTransferredPlexMetadataForProfile('profile-b');

      final adopted = (await db.getDownloadedMedia(globalKey))!;
      final adoptedOwner = await db.getDownloadOwner(profileId: 'profile-b', globalKey: globalKey);
      final queueAfter = (await db.select(db.downloadQueue).get()).single;
      expect(adopted.clientScopeId, destinationScope);
      expect(adoptedOwner?.backend, MediaBackend.plex.id);
      expect(adoptedOwner?.clientScopeId, destinationScope);
      expect(adopted.status, before.status);
      expect(adopted.progress, before.progress);
      expect(adopted.downloadedBytes, before.downloadedBytes);
      expect(adopted.totalBytes, before.totalBytes);
      expect(adopted.videoFilePath, before.videoFilePath);
      expect(adopted.downloadedAt, before.downloadedAt);
      expect(adopted.mediaIndex, before.mediaIndex);
      expect(adopted.mediaSourceId, before.mediaSourceId);
      expect(queueAfter.mediaGlobalKey, queueBefore.mediaGlobalKey);
      expect(queueAfter.priority, queueBefore.priority);
      expect(queueAfter.addedAt, queueBefore.addedAt);
      expect(queueAfter.downloadSubtitles, queueBefore.downloadSubtitles);
      expect(queueAfter.downloadArtwork, queueBefore.downloadArtwork);
      expect(await PlexApiCache.instance.getMetadata(destinationScope.cacheServerId, 'item-1'), isNull);

      final hydratedMetadata = testMediaItem(
        id: 'item-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: serverId,
        title: 'Rehydrated for profile B',
      );
      final client = _DirectCachePlexClient(
        serverId: serverId,
        scopedServerId: destinationScope,
        metadata: hydratedMetadata,
      );
      final hydrationManager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (resolvedServerId, {clientScopeId}) {
          if (resolvedServerId != serverId.toString()) return null;
          if (clientScopeId != null && clientScopeId != destinationScope) return null;
          return client;
        },
      );

      final hydrated = await hydrationManager.fetchAndPinMetadata(
        serverId,
        'item-1',
        preferActiveScope: true,
        activeProfileId: 'profile-b',
      );

      expect(hydrated?.title, 'Rehydrated for profile B');
      expect(
        (await PlexApiCache.instance.getMetadata(destinationScope.cacheServerId, 'item-1'))?.title,
        'Rehydrated for profile B',
      );
      expect(
        (await PlexApiCache.instance.getAllPinnedMetadata(cacheServerIds: {destinationScope.cacheServerId})).keys,
        [globalKey],
      );
      expect(await PlexApiCache.instance.getMetadata(transferScope.cacheServerId, 'item-1'), isNull);
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

    test('adopted Jellyfin ownership cleans only the adopting user cache scope', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              id: 'profile-b',
              kind: 'local',
              displayName: 'Profile B',
              configJson: '{}',
              createdAt: now,
            ),
          );
      await db
          .into(db.connections)
          .insert(
            ConnectionsCompanion.insert(
              id: 'jf-machine/user-b',
              kind: 'jellyfin',
              displayName: 'User B',
              configJson: jsonEncode({'serverMachineId': 'jf-machine', 'userId': 'user-b'}),
              createdAt: now,
            ),
          );
      await db
          .into(db.profileConnections)
          .insert(
            ProfileConnectionsCompanion.insert(
              profileId: 'profile-b',
              connectionId: 'jf-machine/user-b',
              userIdentifier: 'user-b',
            ),
          );
      await db.insertDownload(
        serverId: ServerId('jf-machine'),
        clientScopeId: 'jf-machine/user-a',
        ratingKey: 'item-1',
        globalKey: 'jf-machine:item-1',
        type: 'movie',
        status: DownloadStatus.completed.index,
      );
      for (final userId in const ['user-a', 'user-b']) {
        await JellyfinApiCache.instance.put(ServerId('jf-machine/$userId'), '/Users/$userId/Items/item-1', {
          'Id': 'item-1',
          'Type': 'Movie',
          'Name': userId,
        });
      }
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
      );

      await db.adoptLegacyDownloadsForProfile('profile-b');
      final owner = await db.getDownloadOwner(profileId: 'profile-b', globalKey: 'jf-machine:item-1');
      expect((await db.getDownloadedMedia('jf-machine:item-1'))?.clientScopeId, 'jf-machine/user-b');
      expect(owner?.backend, MediaBackend.jellyfin.id);
      expect(owner?.clientScopeId, 'jf-machine/user-b');

      await db.removeDownloadOwner(profileId: 'profile-b', globalKey: 'jf-machine:item-1');
      await manager.deleteMetadataForOwner(
        globalKey: 'jf-machine:item-1',
        serverId: ServerId('jf-machine'),
        itemId: 'item-1',
        profileId: 'profile-b',
        backendId: owner?.backend,
        clientScopeId: owner?.clientScopeId,
      );

      expect(await JellyfinApiCache.instance.get(ServerId('jf-machine/user-b'), '/Users/user-b/Items/item-1'), isNull);
      expect(
        await JellyfinApiCache.instance.get(ServerId('jf-machine/user-a'), '/Users/user-a/Items/item-1'),
        isNotNull,
      );
    });

    test('artwork repair fetches full parent metadata and backfills thumb path', () async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      DownloadStorageService.resetForTesting();
      final tmpRoot = await Directory.systemTemp.createTemp('download_manager_artwork_repair_test_');
      final previousPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = FakePathProvider(tmpRoot);
      addTearDown(() async {
        DownloadStorageService.resetForTesting();
        SettingsService.resetForTesting();
        PathProviderPlatform.instance = previousPathProvider;
        expect(PathProviderPlatform.instance, same(previousPathProvider));
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

  group('download durability', () {
    test('pin failure occurs after durable queue creation and still starts processing', () async {
      final fixture = await _createSupplementaryFixture();
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => const DownloadResolution(videoUrl: 'https://example.test/video'),
      );
      await fixture.db.customStatement('''
        CREATE TRIGGER reject_cache_pin
        BEFORE UPDATE OF pinned ON api_cache
        BEGIN
          SELECT RAISE(ABORT, 'cache pin rejected');
        END
      ''');
      var processingAttempts = 0;
      var observedDurablePair = false;
      final processingStarted = Completer<void>();
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        downloadsSupportedOverride: true,
        queueProcessorOverride: (_) async {
          processingAttempts++;
          final media = await fixture.db.getDownloadedMedia(fixture.metadata.globalKey);
          final queue = await fixture.db.select(fixture.db.downloadQueue).get();
          observedDurablePair = media?.status == DownloadStatus.queued.index && queue.length == 1;
          if (!processingStarted.isCompleted) processingStarted.complete();
        },
      );
      addTearDown(manager.dispose);

      await manager.queueDownload(metadata: fixture.metadata, client: client);
      await processingStarted.future;

      expect(processingAttempts, 1);
      expect(observedDurablePair, isTrue);
      expect(await fixture.db.getDownloadedMedia(fixture.metadata.globalKey), isNotNull);
      expect(await fixture.db.select(fixture.db.downloadQueue).get(), hasLength(1));
    });

    test('an already queued request refreshes policy and restarts processing', () async {
      final fixture = await _createSupplementaryFixture();
      await fixture.db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: fixture.metadata.id,
        globalKey: fixture.metadata.globalKey,
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await fixture.db.addToQueue(mediaGlobalKey: fixture.metadata.globalKey, priority: 1);
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => const DownloadResolution(videoUrl: 'https://example.test/video'),
      );
      var processingAttempts = 0;
      var progressEvents = 0;
      final processingStarted = Completer<void>();
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        downloadsSupportedOverride: true,
        queueProcessorOverride: (_) async {
          processingAttempts++;
          if (!processingStarted.isCompleted) processingStarted.complete();
        },
      );
      final progressSubscription = manager.progressStream.listen((_) => progressEvents++);
      addTearDown(progressSubscription.cancel);
      addTearDown(manager.dispose);

      await manager.queueDownload(
        metadata: fixture.metadata,
        client: client,
        priority: 8,
        downloadSubtitles: false,
        downloadArtwork: false,
      );
      await processingStarted.future;

      final queue = (await fixture.db.select(fixture.db.downloadQueue).get()).single;
      expect(queue.priority, 8);
      expect(queue.downloadSubtitles, isFalse);
      expect(queue.downloadArtwork, isFalse);
      expect(processingAttempts, 1);
      expect(progressEvents, 1);
    });

    test('an active or completed request emits and starts no duplicate work', () async {
      final fixture = await _createSupplementaryFixture();
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => const DownloadResolution(videoUrl: 'https://example.test/video'),
      );
      for (final status in [DownloadStatus.downloading, DownloadStatus.paused, DownloadStatus.completed]) {
        await fixture.db.insertDownload(
          serverId: ServerId('srv'),
          ratingKey: fixture.metadata.id,
          globalKey: fixture.metadata.globalKey,
          type: 'movie',
          status: status.index,
        );
        var processingAttempts = 0;
        var progressEvents = 0;
        final manager = DownloadManagerService(
          database: fixture.db,
          storageService: fixture.storage,
          clientResolver: (serverId, {clientScopeId}) => client,
          downloadsSupportedOverride: true,
          queueProcessorOverride: (_) async {
            processingAttempts++;
          },
        );
        final progressSubscription = manager.progressStream.listen((_) => progressEvents++);

        await manager.queueDownload(metadata: fixture.metadata, client: client);
        await Future<void>.delayed(Duration.zero);

        expect((await fixture.db.getDownloadedMedia(fixture.metadata.globalKey))?.status, status.index);
        expect(await fixture.db.select(fixture.db.downloadQueue).get(), isEmpty);
        expect(processingAttempts, 0);
        expect(progressEvents, 0);
        await progressSubscription.cancel();
        manager.dispose();
        await fixture.db.deleteDownload(fixture.metadata.globalKey);
      }
    });

    test('transient preparation failure remains queued and starts an automatic retry', () async {
      final fixture = await _createSupplementaryFixture();
      var attempts = 0;
      final retryStarted = Completer<void>();
      final retryGate = Completer<DownloadResolution>();
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () {
          attempts++;
          if (attempts == 1) {
            throw MediaServerHttpException(
              type: MediaServerHttpErrorType.unknown,
              statusCode: 500,
              message: 'temporary PlaybackInfo failure',
            );
          }
          if (!retryStarted.isCompleted) retryStarted.complete();
          return retryGate.future;
        },
      );
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        downloadsSupportedOverride: true,
        fileDownloaderInitializerOverride: () async {},
        autoRetryDelay: Duration.zero,
      );
      addTearDown(manager.dispose);

      await manager.queueDownload(metadata: fixture.metadata, client: client);
      await retryStarted.future;

      final stored = await fixture.db.getDownloadedMedia(fixture.metadata.globalKey);
      expect(attempts, 2);
      expect(stored?.retryCount, 1);
      expect(await fixture.db.select(fixture.db.downloadQueue).get(), hasLength(1));

      await fixture.db.updateDownloadStatus(fixture.metadata.globalKey, DownloadStatus.cancelled.index);
      retryGate.complete(const DownloadResolution(videoUrl: 'https://example.test/video'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    });

    test('preparation retries exhaust the configured app retry budget', () async {
      final fixture = await _createSupplementaryFixture();
      var attempts = 0;
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () {
          attempts++;
          throw MediaServerHttpException(
            type: MediaServerHttpErrorType.unknown,
            statusCode: 500,
            message: 'temporary PlaybackInfo failure',
          );
        },
      );
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        downloadsSupportedOverride: true,
        fileDownloaderInitializerOverride: () async {},
        autoRetryDelay: Duration.zero,
      );
      addTearDown(manager.dispose);
      final exhausted = manager.progressStream.firstWhere(
        (event) => event.status == DownloadStatus.failed && attempts == 4,
      );

      await manager.queueDownload(metadata: fixture.metadata, client: client);
      await exhausted;

      final stored = await fixture.db.getDownloadedMedia(fixture.metadata.globalKey);
      expect(attempts, 4);
      expect(stored?.status, DownloadStatus.failed.index);
      expect(stored?.retryCount, 4);
    });

    test('cold recovery repairs a legacy queue gap once before native recovery', () async {
      final fixture = await _createSupplementaryFixture();
      await fixture.db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: fixture.metadata.id,
        globalKey: fixture.metadata.globalKey,
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await fixture.reopenDatabase();

      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => const DownloadResolution(videoUrl: 'https://example.test/video'),
      );
      var nativeRecoveryCalls = 0;
      var queueProcessingCalls = 0;
      final processingStarted = Completer<void>();
      final firstManager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        downloadsSupportedOverride: true,
        nativeRecoveryOverride: () async {
          nativeRecoveryCalls++;
        },
        queueProcessorOverride: (_) async {
          queueProcessingCalls++;
          await fixture.db.updateDownloadStatus(fixture.metadata.globalKey, DownloadStatus.downloading.index);
          if (!processingStarted.isCompleted) processingStarted.complete();
        },
      );

      await firstManager.recoverInterruptedDownloads();
      expect(nativeRecoveryCalls, 1);
      expect(await fixture.db.select(fixture.db.downloadQueue).get(), hasLength(1));
      firstManager.resumeQueuedDownloads(client);
      await processingStarted.future;
      expect(queueProcessingCalls, 1);
      firstManager.dispose();

      final secondManager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        downloadsSupportedOverride: true,
        nativeRecoveryOverride: () async {
          nativeRecoveryCalls++;
        },
        queueProcessorOverride: (_) async {
          queueProcessingCalls++;
        },
      );
      addTearDown(secondManager.dispose);
      await secondManager.recoverInterruptedDownloads();
      secondManager.resumeQueuedDownloads(client);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(nativeRecoveryCalls, 2);
      expect(queueProcessingCalls, 1);
      expect(await fixture.db.select(fixture.db.downloadQueue).get(), hasLength(1));
      expect(
        (await fixture.db.getDownloadedMedia(fixture.metadata.globalKey))?.status,
        DownloadStatus.downloading.index,
      );
    });

    test('isolates subtitle failures and repairs only missing tracks after restart', () async {
      final fixture = await _createSupplementaryFixture();
      final httpClient = _ScriptedSubtitleClient(failuresRemaining: {1: 1});
      final subtitles = [
        const DownloadSubtitleSpec(id: 1, url: 'https://example.test/subtitle/1', codec: 'srt'),
        const DownloadSubtitleSpec(id: 2, url: 'https://example.test/subtitle/2', codec: 'srt'),
      ];
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => DownloadResolution(videoUrl: 'https://example.test/video', externalSubtitles: subtitles),
      );
      await _seedCompletingDownload(fixture, downloadSubtitles: true);
      final firstManager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        http: MediaServerHttpClient(client: httpClient),
        downloadsSupportedOverride: false,
      );

      await firstManager.debugHandleTaskStatus(
        TaskStatusUpdate(_downloadTask('current-task', fixture.metadata.globalKey), TaskStatus.complete),
      );
      final firstPath = await fixture.storage.getMovieSubtitlePath(fixture.metadata, 1, 'srt');
      final secondPath = await fixture.storage.getMovieSubtitlePath(fixture.metadata, 2, 'srt');
      expect(httpClient.trackRequests, [1, 2]);
      expect(File(firstPath).existsSync(), isFalse);
      expect(File(secondPath).existsSync(), isTrue);
      expect((await fixture.db.getDownloadedMedia(fixture.metadata.globalKey))?.status, DownloadStatus.completed.index);
      expect(await fixture.db.getPendingSupplementaryQueueItems(), hasLength(1));
      firstManager.dispose();

      final storedVideoPath = (await fixture.db.getDownloadedMedia(fixture.metadata.globalKey))?.videoFilePath;
      final restartedManager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        http: MediaServerHttpClient(client: httpClient),
        downloadsSupportedOverride: false,
      );
      addTearDown(restartedManager.dispose);
      await restartedManager.repairPendingSupplementaryDownloads();

      expect(httpClient.trackRequests, [1, 2, 1]);
      expect(File(firstPath).existsSync(), isTrue);
      expect(File(secondPath).existsSync(), isTrue);
      expect(await fixture.db.getPendingSupplementaryQueueItems(), isEmpty);
      final completed = await fixture.db.getDownloadedMedia(fixture.metadata.globalKey);
      expect(completed?.status, DownloadStatus.completed.index);
      expect(completed?.videoFilePath, storedVideoPath);
      expect(await fixture.db.getNextQueueItem(), isNull);
    });

    test('retains unresolved subtitle enrichment and settles a later authoritative empty list', () async {
      final fixture = await _createSupplementaryFixture();
      var enrichmentResolved = false;
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () =>
            DownloadResolution(videoUrl: 'https://example.test/video', externalSubtitlesResolved: enrichmentResolved),
      );
      await _seedCompletedPendingDownload(fixture, downloadSubtitles: true);
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);

      await manager.repairPendingSupplementaryDownloads();
      expect(await fixture.db.getPendingSupplementaryQueueItems(), hasLength(1));

      enrichmentResolved = true;
      await manager.repairPendingSupplementaryDownloads();
      expect(await fixture.db.getPendingSupplementaryQueueItems(), isEmpty);
    });

    test('supplementary repair reuses the persisted media source', () async {
      final fixture = await _createSupplementaryFixture();
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () =>
            const DownloadResolution(videoUrl: 'https://example.test/video', externalSubtitlesResolved: true),
      );
      await _seedCompletedPendingDownload(fixture, downloadSubtitles: true);
      await fixture.db.updateDownloadMediaSource(fixture.metadata.globalKey, 'source-2');
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);

      await manager.repairPendingSupplementaryDownloads();

      expect(client.lastMediaSourceId, 'source-2');
      expect(await fixture.db.getPendingSupplementaryQueueItems(), isEmpty);
    });

    test('subtitle-disabled completion issues no sidecar request or retry marker', () async {
      final fixture = await _createSupplementaryFixture();
      final httpClient = _ScriptedSubtitleClient();
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => DownloadResolution(
          videoUrl: 'https://example.test/video',
          externalSubtitles: const [DownloadSubtitleSpec(id: 1, url: 'https://example.test/subtitle/1', codec: 'srt')],
        ),
      );
      await _seedCompletingDownload(fixture, downloadSubtitles: false);
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        http: MediaServerHttpClient(client: httpClient),
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);

      await manager.debugHandleTaskStatus(
        TaskStatusUpdate(_downloadTask('current-task', fixture.metadata.globalKey), TaskStatus.complete),
      );

      expect(httpClient.trackRequests, isEmpty);
      expect(await fixture.db.getPendingSupplementaryQueueItems(), isEmpty);
      expect(await fixture.db.select(fixture.db.downloadQueue).get(), isEmpty);
    });

    test('coalesces concurrent persisted supplementary repairs', () async {
      final fixture = await _createSupplementaryFixture();
      final gate = Completer<void>();
      final requestStarted = Completer<void>();
      final httpClient = _ScriptedSubtitleClient(gate: gate, requestStarted: requestStarted);
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => const DownloadResolution(
          videoUrl: 'https://example.test/video',
          externalSubtitles: [DownloadSubtitleSpec(id: 1, url: 'https://example.test/subtitle/1', codec: 'srt')],
        ),
      );
      await _seedCompletedPendingDownload(fixture, downloadSubtitles: true);
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        http: MediaServerHttpClient(client: httpClient),
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);

      final firstRepair = manager.repairPendingSupplementaryDownloads();
      await requestStarted.future;
      final secondRepair = manager.repairPendingSupplementaryDownloads();
      gate.complete();
      await Future.wait([firstRepair, secondRepair]);

      expect(httpClient.trackRequests, [1]);
      expect(await fixture.db.getPendingSupplementaryQueueItems(), isEmpty);
    });

    test('recovery completion preserves the base directory of a custom-root task path', () async {
      final fixture = await _createSupplementaryFixture();
      await _seedCompletingDownload(fixture, downloadSubtitles: false);
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => null,
        downloadsSupportedOverride: false,
      );
      addTearDown(manager.dispose);
      // A custom download path enqueues a BaseDirectory.root task; the Task
      // constructor strips the leading separator from `directory`, so only
      // Task.filePath() can rebuild the completed file's absolute location.
      final task = _rootTask('current-task', fixture.metadata.globalKey, '/home/u/Media/Movie (2020)');

      await manager.debugHandleTaskStatus(TaskStatusUpdate(task, TaskStatus.complete));

      final row = await fixture.db.getDownloadedMedia(fixture.metadata.globalKey);
      expect(row?.status, DownloadStatus.completed.index);
      expect(row?.videoFilePath, await task.filePath());
      expect(p.isAbsolute(row!.videoFilePath!), isTrue);
      // The old directory/filename join persisted this mangled relative path,
      // which later resolves inside app storage instead of the custom root.
      expect(row.videoFilePath, isNot('${task.directory}/${task.filename}'));
    });

    test('queue drain skips an unresolvable head and still reaches the next item', () async {
      final fixture = await _createSupplementaryFixture();
      // Stale head: highest priority, but its server has no resolvable client.
      await fixture.db.insertDownload(
        serverId: ServerId('gone'),
        ratingKey: 'stale-1',
        globalKey: 'gone:stale-1',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await fixture.db.addToQueue(mediaGlobalKey: 'gone:stale-1', priority: 9);
      await fixture.db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: fixture.metadata.id,
        globalKey: fixture.metadata.globalKey,
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await fixture.db.addToQueue(mediaGlobalKey: fixture.metadata.globalKey);

      var resolveAttempts = 0;
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () {
          resolveAttempts++;
          // Non-retryable: settles the second item in one pass without timers.
          throw MediaServerHttpException(type: MediaServerHttpErrorType.unknown, statusCode: 401, message: 'denied');
        },
      );
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => serverId == 'srv' ? client : null,
        downloadsSupportedOverride: true,
        fileDownloaderInitializerOverride: () async {},
      );
      addTearDown(manager.dispose);
      final secondItemAttempted = manager.progressStream.firstWhere(
        (event) => event.globalKey == fixture.metadata.globalKey && event.status == DownloadStatus.failed,
      );

      manager.resumeQueuedDownloads(client);
      await secondItemAttempted;
      // The failed item is dequeued just after its failure event; let the
      // drain settle before inspecting the queue.
      List<DownloadQueueItem> queueRows;
      do {
        await Future<void>.delayed(Duration.zero);
        queueRows = await fixture.db.select(fixture.db.downloadQueue).get();
      } while (queueRows.length != 1);

      expect(resolveAttempts, 1);
      // The unresolvable head is skipped, not consumed: it stays queued for a
      // later drain cycle once its server comes back.
      expect(queueRows.single.mediaGlobalKey, 'gone:stale-1');
      expect((await fixture.db.getDownloadedMedia('gone:stale-1'))?.status, DownloadStatus.queued.index);
    });

    test('a resume landing mid-drain replays the pass for a server that connected during it', () async {
      final fixture = await _createSupplementaryFixture();
      // Row for server 'late': offline when the drain starts, online mid-drain.
      await fixture.db.insertDownload(
        serverId: ServerId('late'),
        ratingKey: 'late-1',
        globalKey: 'late:late-1',
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await fixture.db.addToQueue(mediaGlobalKey: 'late:late-1', priority: 9);
      await fixture.db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: fixture.metadata.id,
        globalKey: fixture.metadata.globalKey,
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await fixture.db.addToQueue(mediaGlobalKey: fixture.metadata.globalKey);

      var lateOnline = false;
      late final DownloadManagerService manager;
      // Non-retryable: settles each item in one attempt without timers.
      Never denied() =>
          throw MediaServerHttpException(type: MediaServerHttpErrorType.unknown, statusCode: 401, message: 'denied');
      var lateResolveAttempts = 0;
      final lateClient = _SupplementaryClient(
        metadata: testMediaItem(
          id: 'late-1',
          backend: MediaBackend.plex,
          kind: MediaKind.movie,
          serverId: ServerId('late'),
          title: 'Late Movie',
        ),
        resolution: () {
          lateResolveAttempts++;
          denied();
        },
      );
      var srvResolveAttempts = 0;
      late final _SupplementaryClient srvClient;
      srvClient = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () async {
          srvResolveAttempts++;
          // Mid-drain: 'late' comes online and its status-stream resume
          // arrives while the drain guard is still held. Without the
          // coalesced rerun this call is dropped, and 'late-1' — already
          // skipped as offline earlier in this very pass — stays queued
          // until some unrelated trigger drives the queue again.
          lateOnline = true;
          manager.resumeQueuedDownloads(srvClient);
          // Same-isolate determinism: a few zero-delay turns let the resume's
          // getNextQueueItem chain reach _processQueue while resolveDownload
          // (and therefore the first pass) is still in flight.
          for (var i = 0; i < 8; i++) {
            await Future<void>.delayed(Duration.zero);
          }
          denied();
        },
      );
      manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) {
          if (serverId == 'srv') return srvClient;
          return serverId == 'late' && lateOnline ? lateClient : null;
        },
        downloadsSupportedOverride: true,
        fileDownloaderInitializerOverride: () async {},
      );
      addTearDown(manager.dispose);
      final lateItemAttempted = manager.progressStream.firstWhere(
        (event) => event.globalKey == 'late:late-1' && event.status == DownloadStatus.failed,
      );

      manager.resumeQueuedDownloads(srvClient);
      await lateItemAttempted;
      // Failed items are dequeued just after their failure event; let the
      // rerun pass settle before inspecting the queue.
      List<DownloadQueueItem> queueRows;
      do {
        await Future<void>.delayed(Duration.zero);
        queueRows = await fixture.db.select(fixture.db.downloadQueue).get();
      } while (queueRows.isNotEmpty);

      // One pass processed 'srv', the coalesced rerun processed 'late':
      // neither item was attempted twice.
      expect(srvResolveAttempts, 1);
      expect(lateResolveAttempts, 1);
      expect((await fixture.db.getDownloadedMedia('late:late-1'))?.status, DownloadStatus.failed.index);
    });
  });

  group('deferred supplementary repair', () {
    test('completed repair persists artwork without announcing downloading', () async {
      final fixture = await _createSupplementaryFixture(thumbPath: '/repair-thumb');
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => const DownloadResolution(videoUrl: 'https://example.test/video'),
      );
      await _seedCompletedPendingDownload(fixture, downloadSubtitles: false, downloadArtwork: true);
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        http: MediaServerHttpClient(client: FakeHttpClient(200, utf8.encode('image bytes'))),
        downloadsSupportedOverride: false,
      );
      final events = <DownloadProgress>[];
      final progressSubscription = manager.progressStream.listen(events.add);
      addTearDown(progressSubscription.cancel);
      addTearDown(manager.dispose);

      await manager.repairPendingSupplementaryDownloads();
      await Future<void>.delayed(Duration.zero);

      expect(
        events,
        isNot(contains(predicate<DownloadProgress>((event) => event.status == DownloadStatus.downloading))),
      );
      expect(
        events,
        contains(
          predicate<DownloadProgress>(
            (event) =>
                event.status == DownloadStatus.completed && event.thumbPath == artworkStorageKey('/repair-thumb'),
          ),
        ),
      );
      expect(
        (await fixture.db.getDownloadedMedia(fixture.metadata.globalKey))?.thumbPath,
        artworkStorageKey('/repair-thumb'),
      );
      expect(await fixture.db.getPendingSupplementaryQueueItems(), isEmpty);
    });

    test('normal completion still announces artwork and subtitle steps', () async {
      final fixture = await _createSupplementaryFixture(thumbPath: '/normal-thumb');
      final client = _SupplementaryClient(
        metadata: fixture.metadata,
        resolution: () => const DownloadResolution(
          videoUrl: 'https://example.test/video',
          externalSubtitles: [DownloadSubtitleSpec(id: 1, url: 'https://example.test/subtitle/1', codec: 'srt')],
        ),
      );
      await _seedCompletingDownload(fixture, downloadSubtitles: true, downloadArtwork: true);
      final manager = DownloadManagerService(
        database: fixture.db,
        storageService: fixture.storage,
        clientResolver: (serverId, {clientScopeId}) => client,
        http: MediaServerHttpClient(client: FakeHttpClient(200, utf8.encode('supplementary bytes'))),
        downloadsSupportedOverride: false,
      );
      final events = <DownloadProgress>[];
      final progressSubscription = manager.progressStream.listen(events.add);
      addTearDown(progressSubscription.cancel);
      addTearDown(manager.dispose);

      await manager.debugHandleTaskStatus(
        TaskStatusUpdate(_downloadTask('current-task', fixture.metadata.globalKey), TaskStatus.complete),
      );
      await Future<void>.delayed(Duration.zero);

      final downloadingFiles = events
          .where((event) => event.status == DownloadStatus.downloading)
          .map((event) => event.currentFile);
      expect(downloadingFiles, containsAll(<String?>['artwork', 'subtitles']));
      expect(await fixture.db.getPendingSupplementaryQueueItems(), isEmpty);
    });
  });

  group('deletion cleanup', () {
    test('missing video still removes partial and subtitle sidecars', () async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      DownloadStorageService.resetForTesting();
      final tmpRoot = await Directory.systemTemp.createTemp('download_manager_delete_test_');
      final previousPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = FakePathProvider(tmpRoot);
      addTearDown(() async {
        DownloadStorageService.resetForTesting();
        SettingsService.resetForTesting();
        PathProviderPlatform.instance = previousPathProvider;
        expect(PathProviderPlatform.instance, same(previousPathProvider));
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

    test('chapter thumbnails referenced by a cache-resolvable sibling are retained', () async {
      final result = await _runChapterThumbnailDeletion(withSibling: true, siblingCached: true);

      expect(result.thumbRetained, isTrue);
      expect(result.networkFetches, 0);
    });

    test('chapter thumbnails are retained when a sibling cannot be resolved from cache', () async {
      final result = await _runChapterThumbnailDeletion(withSibling: true, siblingCached: false);

      expect(result.thumbRetained, isTrue);
      expect(result.networkFetches, 0);
    });

    test('unreferenced chapter thumbnails are deleted without any network fetch', () async {
      final result = await _runChapterThumbnailDeletion(withSibling: false, siblingCached: false);

      expect(result.thumbRetained, isFalse);
      expect(result.networkFetches, 0);
    });

    test('a cache-resolvable sibling with different chapters does not block deletion', () async {
      final result = await _runChapterThumbnailDeletion(
        withSibling: true,
        siblingCached: true,
        siblingReferencesThumb: false,
      );

      expect(result.thumbRetained, isFalse);
      expect(result.networkFetches, 0);
    });

    test('batch deletion ignores same-batch siblings with missing caches when reference-counting', () async {
      final result = await _runSeasonBatchChapterThumbnailDeletion(withCacheMissSurvivor: false);

      expect(result.thumbRetained, isFalse, reason: 'a sibling scheduled for the same deletion must not retain');
      expect(result.networkFetches, 0);
    });

    test('batch deletion still retains chapter thumbnails for a surviving cache-miss row', () async {
      final result = await _runSeasonBatchChapterThumbnailDeletion(withCacheMissSurvivor: true);

      expect(result.thumbRetained, isTrue, reason: 'a surviving row with unknown references must retain');
      expect(result.networkFetches, 0);
    });
  });

  group('storage exhaustion', () {
    test('filesystem-full failure stops every active download and clears the queue', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const currentKey = 'srv:item-1';
      const queuedKey = 'srv:item-2';

      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-1',
        globalKey: currentKey,
        type: 'movie',
        status: DownloadStatus.downloading.index,
      );
      await db.updateBgTaskId(currentKey, 'current-task');
      await db.addToQueue(mediaGlobalKey: currentKey);
      await db.insertDownload(
        serverId: ServerId('srv'),
        ratingKey: 'item-2',
        globalKey: queuedKey,
        type: 'movie',
        status: DownloadStatus.queued.index,
      );
      await db.updateBgTaskId(queuedKey, 'queued-task');
      await db.addToQueue(mediaGlobalKey: queuedKey);

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

      await manager.debugHandleTaskStatus(
        TaskStatusUpdate(
          _downloadTask('current-task', currentKey),
          TaskStatus.failed,
          TaskFileSystemException('write failed: ENOSPC (No space left on device)'),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        events
            .where((event) => event.status == DownloadStatus.failed && event.errorMessage == t.downloads.storageFull)
            .map((event) => event.globalKey)
            .toSet(),
        {currentKey, queuedKey},
      );

      final current = await db.getDownloadedMedia(currentKey);
      final queued = await db.getDownloadedMedia(queuedKey);
      expect(current?.status, DownloadStatus.failed.index);
      expect(queued?.status, DownloadStatus.failed.index);
      expect(current?.bgTaskId, isNull);
      expect(queued?.bgTaskId, isNull);
      expect(current?.errorMessage, t.downloads.storageFull);
      expect(queued?.errorMessage, t.downloads.storageFull);
      expect(await db.select(db.downloadQueue).get(), isEmpty);
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
      await db.updateDownloadSafRoot(globalKey, 'content://downloads');
      await db.updateDownloadError(globalKey, 'transient failure');

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
      expect(row?.safRootUri, 'content://downloads');
      expect(row?.errorMessage, 'transient failure');
      expect(row?.retryCount, 1);
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

  group('SAF grant ownership', () {
    Future<void> seedRow(
      AppDatabase db,
      String key, {
      String? videoFilePath,
      String? taskId,
      DownloadStatus status = DownloadStatus.queued,
    }) async {
      final parts = key.split(':');
      await db.insertDownload(
        serverId: ServerId(parts.first),
        ratingKey: parts.last,
        globalKey: key,
        type: 'movie',
        status: status.index,
      );
      if (videoFilePath != null) {
        await db.updateVideoFilePath(key, videoFilePath);
      }
      if (taskId != null) await db.updateBgTaskId(key, taskId);
    }

    test('root switches retain references and release only the final owner', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, 'srv:first');
      await seedRow(db, 'srv:second');
      DownloadLocationSnapshot location = (path: 'content://picked-a', type: 'saf');
      final saf = _FakeSafStorage(
        canonicalRoots: const {
          'content://picked-a': 'content://root-a',
          'content://picked-b': 'content://root-b',
          'content://picked-b-alias': 'content://root-b',
          'content://root-a': 'content://root-a',
          'content://root-b': 'content://root-b',
        },
        persistedRoots: const {'content://root-a', 'content://root-b'},
      );
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
        safStorage: saf,
        downloadsSupportedOverride: false,
        downloadLocationReader: () => location,
        downloadPathWriter: (value) async {
          location = (path: value, type: location.type);
        },
        downloadPathTypeWriter: (value) async {
          location = (path: location.path, type: value);
        },
        downloadStorageRefresher: () async {},
      );
      addTearDown(manager.dispose);

      await manager.debugClaimDownloadSafRoot('srv:first', 'content://picked-a');
      await manager.debugClaimDownloadSafRoot('srv:second', 'content://picked-a');
      await manager.setDownloadLocation(path: 'content://picked-b', pathType: 'saf');
      expect(saf.releaseCalls, isEmpty);

      await manager.debugDeleteDownloadRowAndRelease('srv:first');
      expect(saf.releaseCalls, isEmpty);
      await manager.debugDeleteDownloadRowAndRelease('srv:second');
      expect(saf.releaseCalls, ['content://root-a']);

      await manager.setDownloadLocation(path: 'content://picked-b-alias', pathType: 'saf');
      expect(saf.releaseCalls, ['content://root-a']);
      await manager.resetDownloadLocation();
      expect(saf.releaseCalls, ['content://root-a', 'content://root-b']);
    });

    test('a paused claim serializes ahead of a root switch and retry move', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, 'srv:item');
      DownloadLocationSnapshot location = (path: 'content://picked-a', type: 'saf');
      final claimEntered = Completer<void>();
      final allowClaim = Completer<void>();
      final saf = _FakeSafStorage(
        persistedRoots: const {'content://root-a', 'content://root-b'},
        resolveOverride: (uri) async {
          if (uri == 'content://task-a') {
            claimEntered.complete();
            await allowClaim.future;
            return 'content://root-a';
          }
          return switch (uri) {
            'content://picked-a' || 'content://root-a' => 'content://root-a',
            'content://picked-b' || 'content://root-b' => 'content://root-b',
            _ => null,
          };
        },
      );
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
        safStorage: saf,
        downloadsSupportedOverride: false,
        downloadLocationReader: () => location,
        downloadPathWriter: (value) async {
          location = (path: value, type: location.type);
        },
        downloadPathTypeWriter: (value) async {
          location = (path: location.path, type: value);
        },
        downloadStorageRefresher: () async {},
      );
      addTearDown(manager.dispose);

      final claim = manager.debugClaimDownloadSafRoot('srv:item', 'content://task-a');
      await claimEntered.future;
      var switchCompleted = false;
      final rootSwitch = manager
          .setDownloadLocation(path: 'content://picked-b', pathType: 'saf')
          .whenComplete(() => switchCompleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(switchCompleted, isFalse);
      expect(saf.releaseCalls, isEmpty);

      allowClaim.complete();
      await claim;
      await rootSwitch;
      expect((await db.getDownloadedMedia('srv:item'))?.safRootUri, 'content://root-a');
      expect(saf.releaseCalls, isEmpty);

      await manager.debugClaimDownloadSafRoot('srv:item', 'content://picked-b');
      expect((await db.getDownloadedMedia('srv:item'))?.safRootUri, 'content://root-b');
      expect(saf.releaseCalls, ['content://root-a']);
    });

    test('startup backfills legacy row and task roots then releases only orphans', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, 'srv:legacy', videoFilePath: 'content://child-a', status: DownloadStatus.completed);
      await seedRow(db, 'srv:task', taskId: 'task-d', status: DownloadStatus.downloading);
      final saf = _FakeSafStorage(
        canonicalRoots: const {
          'content://picked-b': 'content://root-b',
          'content://child-a': 'content://root-a',
          'content://dir-d': 'content://root-d',
          'content://root-a': 'content://root-a',
          'content://root-b': 'content://root-b',
          'content://root-c': 'content://root-c',
          'content://root-d': 'content://root-d',
        },
        persistedRoots: const {'content://root-a', 'content://root-b', 'content://root-c', 'content://root-d'},
      );
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
        safStorage: saf,
        downloadsSupportedOverride: false,
        downloadLocationReader: () => (path: 'content://picked-b', type: 'saf'),
      );
      addTearDown(manager.dispose);
      final task = UriDownloadTask(
        taskId: 'task-d',
        url: 'https://example.test/video.mp4',
        filename: 'video.mp4',
        directoryUri: Uri.parse('content://dir-d'),
        metaData: 'srv:task',
      );

      await manager.debugReconcileSafGrantOwnership(nativeTasks: [task]);
      expect((await db.getDownloadedMedia('srv:legacy'))?.safRootUri, 'content://root-a');
      expect((await db.getDownloadedMedia('srv:task'))?.safRootUri, 'content://root-d');
      expect(saf.persistedRoots, {'content://root-a', 'content://root-b', 'content://root-d'});
      expect(saf.releaseCalls, ['content://root-c']);

      await manager.debugReconcileSafGrantOwnership(nativeTasks: [task]);
      expect(saf.releaseCalls, ['content://root-c']);
    });

    test('a failed legacy root resolution defers every orphan release', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, 'srv:legacy', videoFilePath: 'content://unresolved-child', status: DownloadStatus.completed);
      final saf = _FakeSafStorage(
        canonicalRoots: const {
          'content://picked-b': 'content://root-b',
          'content://root-b': 'content://root-b',
          'content://root-c': 'content://root-c',
        },
        persistedRoots: const {'content://root-b', 'content://root-c'},
      );
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
        safStorage: saf,
        downloadsSupportedOverride: false,
        downloadLocationReader: () => (path: 'content://picked-b', type: 'saf'),
      );
      addTearDown(manager.dispose);

      await manager.debugReconcileSafGrantOwnership();
      expect(saf.releaseCalls, isEmpty);
      expect(saf.persistedRoots, {'content://root-b', 'content://root-c'});
    });

    for (final failurePoint in ['second preference write', 'storage refresh']) {
      test('$failurePoint restores the old location without discarding a usable grant', () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        DownloadLocationSnapshot location = (path: 'content://picked-a', type: 'saf');
        var typeWrites = 0;
        var refreshes = 0;
        final saf = _FakeSafStorage(
          canonicalRoots: const {
            'content://picked-a': 'content://root-a',
            'content://picked-b': 'content://root-b',
            'content://root-a': 'content://root-a',
            'content://root-b': 'content://root-b',
          },
          persistedRoots: const {'content://root-a', 'content://root-b'},
        );
        final manager = DownloadManagerService(
          database: db,
          storageService: DownloadStorageService.instance,
          clientResolver: (_, {clientScopeId}) => null,
          safStorage: saf,
          downloadsSupportedOverride: false,
          downloadLocationReader: () => location,
          downloadPathWriter: (value) async {
            location = (path: value, type: location.type);
          },
          downloadPathTypeWriter: (value) async {
            typeWrites++;
            if (failurePoint == 'second preference write' && typeWrites == 1) {
              throw StateError('injected type write failure');
            }
            location = (path: location.path, type: value);
          },
          downloadStorageRefresher: () async {
            refreshes++;
            if (failurePoint == 'storage refresh' && refreshes == 1) {
              throw StateError('injected refresh failure');
            }
          },
        );
        addTearDown(manager.dispose);

        await expectLater(manager.setDownloadLocation(path: 'content://picked-b', pathType: 'saf'), throwsStateError);
        expect(location, (path: 'content://picked-a', type: 'saf'));
        if (failurePoint == 'second preference write') {
          expect(saf.releaseCalls, ['content://root-b']);
        } else {
          expect(saf.releaseCalls, isEmpty);
          expect(saf.persistedRoots, contains('content://root-b'));
        }
      });
    }

    test('rollback retains a newly selected root already claimed by a row', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedRow(db, 'srv:item');
      await db.updateDownloadSafRoot('srv:item', 'content://root-b');
      DownloadLocationSnapshot location = (path: 'content://picked-a', type: 'saf');
      final saf = _FakeSafStorage(
        canonicalRoots: const {
          'content://picked-a': 'content://root-a',
          'content://picked-b': 'content://root-b',
          'content://root-a': 'content://root-a',
          'content://root-b': 'content://root-b',
        },
        persistedRoots: const {'content://root-a', 'content://root-b'},
      );
      var refreshes = 0;
      final manager = DownloadManagerService(
        database: db,
        storageService: DownloadStorageService.instance,
        clientResolver: (_, {clientScopeId}) => null,
        safStorage: saf,
        downloadsSupportedOverride: false,
        downloadLocationReader: () => location,
        downloadPathWriter: (value) async {
          location = (path: value, type: location.type);
        },
        downloadPathTypeWriter: (value) async {
          location = (path: location.path, type: value);
        },
        downloadStorageRefresher: () async {
          refreshes++;
          if (refreshes == 1) throw StateError('injected refresh failure');
        },
      );
      addTearDown(manager.dispose);

      await expectLater(manager.setDownloadLocation(path: 'content://picked-b', pathType: 'saf'), throwsStateError);
      expect(location, (path: 'content://picked-a', type: 'saf'));
      expect(saf.releaseCalls, isEmpty);
      expect(saf.persistedRoots, contains('content://root-b'));
    });
  });
}

Future<_SupplementaryFixture> _createSupplementaryFixture({String? thumbPath}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  DownloadStorageService.resetForTesting();
  final tempDir = await Directory.systemTemp.createTemp('download_manager_supplementary_test_');
  final previousPathProvider = PathProviderPlatform.instance;
  PathProviderPlatform.instance = FakePathProvider(tempDir);
  final storage = DownloadStorageService.instance;
  await storage.initialize(await SettingsService.getInstance());
  final databaseFile = File(p.join(tempDir.path, 'downloads.sqlite'));
  final fixture = _SupplementaryFixture(
    tempDir: tempDir,
    previousPathProvider: previousPathProvider,
    databaseFile: databaseFile,
    db: AppDatabase.forTesting(NativeDatabase(databaseFile)),
    storage: storage,
    metadata: testMediaItem(
      id: 'item-1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      serverId: ServerId('srv'),
      title: 'Movie',
      thumbPath: thumbPath,
    ),
  );
  fixture.initializeCaches();
  await PlexApiCache.instance.put(ServerId('srv'), '/library/metadata/item-1', {
    'MediaContainer': {
      'Metadata': [
        {'ratingKey': 'item-1', 'type': 'movie', 'title': 'Movie', 'thumb': ?thumbPath},
      ],
    },
  });
  addTearDown(fixture.dispose);
  return fixture;
}

Future<void> _seedCompletingDownload(
  _SupplementaryFixture fixture, {
  required bool downloadSubtitles,
  bool downloadArtwork = false,
}) async {
  await fixture.db.insertDownload(
    serverId: ServerId('srv'),
    ratingKey: fixture.metadata.id,
    globalKey: fixture.metadata.globalKey,
    type: 'movie',
    status: DownloadStatus.downloading.index,
  );
  await fixture.db.updateBgTaskId(fixture.metadata.globalKey, 'current-task');
  await fixture.db.addToQueue(
    mediaGlobalKey: fixture.metadata.globalKey,
    downloadSubtitles: downloadSubtitles,
    downloadArtwork: downloadArtwork,
  );
}

Future<void> _seedCompletedPendingDownload(
  _SupplementaryFixture fixture, {
  required bool downloadSubtitles,
  bool downloadArtwork = false,
}) async {
  await fixture.db.insertDownload(
    serverId: ServerId('srv'),
    ratingKey: fixture.metadata.id,
    globalKey: fixture.metadata.globalKey,
    type: 'movie',
    status: DownloadStatus.completed.index,
  );
  await fixture.db.updateVideoFilePath(fixture.metadata.globalKey, 'downloads/srv/item-1/video.mp4');
  await fixture.db.addToQueue(
    mediaGlobalKey: fixture.metadata.globalKey,
    downloadSubtitles: downloadSubtitles,
    downloadArtwork: downloadArtwork,
  );
}

class _SupplementaryFixture {
  _SupplementaryFixture({
    required this.tempDir,
    required this.previousPathProvider,
    required this.databaseFile,
    required this.db,
    required this.storage,
    required this.metadata,
  });

  final Directory tempDir;
  final PathProviderPlatform previousPathProvider;
  final File databaseFile;
  AppDatabase db;
  final DownloadStorageService storage;
  final MediaItem metadata;

  void initializeCaches() {
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
  }

  Future<void> reopenDatabase() async {
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(databaseFile));
    initializeCaches();
  }

  Future<void> dispose() async {
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    expect(PathProviderPlatform.instance, same(previousPathProvider));
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  }
}

class _SupplementaryClient implements MediaServerClient {
  _SupplementaryClient({required this.metadata, required this.resolution});

  final MediaItem metadata;
  final FutureOr<DownloadResolution> Function() resolution;
  String? lastMediaSourceId;

  @override
  ServerId get serverId => ServerId('srv');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<MediaItem?> fetchItem(String id) async => id == metadata.id ? metadata : null;

  @override
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0, String? mediaSourceId}) async {
    lastMediaSourceId = mediaSourceId;
    return resolution();
  }

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) {
    return buildArtworkSpecs(item, (path) => 'https://example.test$path');
  }

  @override
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  }) async {
    return PlaybackExtras(chapters: const [], markers: const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScriptedSubtitleClient extends http.BaseClient {
  _ScriptedSubtitleClient({Map<int, int>? failuresRemaining, this.gate, this.requestStarted})
    : failuresRemaining = {...?failuresRemaining};

  final Map<int, int> failuresRemaining;
  final Completer<void>? gate;
  final Completer<void>? requestStarted;
  final List<int> trackRequests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final trackId = int.parse(request.url.pathSegments.last);
    trackRequests.add(trackId);
    if (requestStarted != null && !requestStarted!.isCompleted) requestStarted!.complete();
    if (gate != null) await gate!.future;
    final remainingFailures = failuresRemaining[trackId] ?? 0;
    final statusCode = remainingFailures > 0 ? 500 : 200;
    if (remainingFailures > 0) failuresRemaining[trackId] = remainingFailures - 1;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(statusCode == 200 ? 'subtitle' : 'failed')),
      statusCode,
      request: request,
    );
  }
}

Future<_DeletionResult> _runEpisodeDeletion({required bool saf, bool failVideoDeletion = false}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  DownloadStorageService.resetForTesting();
  final tmpRoot = await Directory.systemTemp.createTemp('download_manager_backend_delete_test_');
  final previousPathProvider = PathProviderPlatform.instance;
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
    PathProviderPlatform.instance = previousPathProvider;
    expect(PathProviderPlatform.instance, same(previousPathProvider));
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  }
}

Future<_ContainerDeletionResult> _runContainerDeletion({required MediaKind kind, required bool saf}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  DownloadStorageService.resetForTesting();
  final tmpRoot = await Directory.systemTemp.createTemp('download_manager_container_delete_test_');
  final previousPathProvider = PathProviderPlatform.instance;
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
    PathProviderPlatform.instance = previousPathProvider;
    expect(PathProviderPlatform.instance, same(previousPathProvider));
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  }
}

/// Deletes movie `srv:item-1` while `srv:item-2` (optionally) sits beside it,
/// with chapter extras scripted per rating key through a cache-only fake
/// client, and reports whether the shared chapter thumbnail survived.
Future<({bool thumbRetained, int networkFetches})> _runChapterThumbnailDeletion({
  required bool withSibling,
  required bool siblingCached,
  bool siblingReferencesThumb = true,
}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  DownloadStorageService.resetForTesting();
  final tmpRoot = await Directory.systemTemp.createTemp('download_manager_chapter_thumb_test_');
  final previousPathProvider = PathProviderPlatform.instance;
  PathProviderPlatform.instance = FakePathProvider(tmpRoot);
  final storage = DownloadStorageService.instance;
  await storage.initialize(await SettingsService.getInstance());
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  JellyfinApiCache.initialize(db);

  final serverId = ServerId('srv');
  const globalKey = 'srv:item-1';
  const sharedThumb = '/library/parts/1/indexes/sd/1000';

  await PlexApiCache.instance.put(serverId, '/library/metadata/item-1', {
    'MediaContainer': {
      'Metadata': [
        {'ratingKey': 'item-1', 'type': 'movie', 'title': 'Movie'},
      ],
    },
  });
  await db.insertDownload(
    serverId: serverId,
    ratingKey: 'item-1',
    globalKey: globalKey,
    type: 'movie',
    status: DownloadStatus.completed.index,
  );
  if (withSibling) {
    await db.insertDownload(
      serverId: serverId,
      ratingKey: 'item-2',
      globalKey: 'srv:item-2',
      type: 'movie',
      status: DownloadStatus.completed.index,
    );
  }

  final artworkFile = File(await storage.getArtworkPathFromThumb(serverId, sharedThumb));
  await artworkFile.create(recursive: true);
  await artworkFile.writeAsString('chapter thumb');

  final client = _ChapterExtrasClient(
    cachedExtras: {
      'item-1': PlaybackExtras(
        chapters: [MediaChapter(id: 1, thumb: sharedThumb)],
        markers: const [],
      ),
      if (withSibling && siblingCached)
        'item-2': PlaybackExtras(
          chapters: [
            MediaChapter(id: 2, thumb: siblingReferencesThumb ? sharedThumb : '/library/parts/2/indexes/sd/2000'),
          ],
          markers: const [],
        ),
    },
  );
  final manager = DownloadManagerService(
    database: db,
    storageService: storage,
    clientResolver: (serverId, {clientScopeId}) => client,
    downloadsSupportedOverride: false,
  )..recoveryFuture = Future<void>.value();

  try {
    await manager.deleteDownload(globalKey);
    return (thumbRetained: await artworkFile.exists(), networkFetches: client.networkFetchCount);
  } finally {
    manager.dispose();
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  }
}

/// Deletes season `srv:season-1`, fanning out to episodes `ep-1` then `ep-2`
/// where `ep-2`'s playback-extras cache is missing, and reports whether
/// `ep-1`'s unshared chapter thumbnail survived. Same-batch rows must not
/// trigger conservative retention (they are all about to disappear), so the
/// thumbnail must be deleted — unless [withCacheMissSurvivor] plants a
/// non-batch row with an unresolvable cache, which must still retain it.
Future<({bool thumbRetained, int networkFetches})> _runSeasonBatchChapterThumbnailDeletion({
  required bool withCacheMissSurvivor,
}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  DownloadStorageService.resetForTesting();
  final tmpRoot = await Directory.systemTemp.createTemp('download_manager_batch_chapter_thumb_test_');
  final previousPathProvider = PathProviderPlatform.instance;
  PathProviderPlatform.instance = FakePathProvider(tmpRoot);
  final storage = DownloadStorageService.instance;
  await storage.initialize(await SettingsService.getInstance());
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  JellyfinApiCache.initialize(db);

  final serverId = ServerId('srv');
  const thumb = '/library/parts/1/indexes/sd/1000';

  await PlexApiCache.instance.put(serverId, '/library/metadata/season-1', {
    'MediaContainer': {
      'Metadata': [
        {'ratingKey': 'season-1', 'type': 'season', 'title': 'Season 1', 'parentRatingKey': 'show-1', 'index': 1},
      ],
    },
  });
  await db.insertDownload(
    serverId: serverId,
    ratingKey: 'season-1',
    globalKey: 'srv:season-1',
    type: 'season',
    parentRatingKey: 'show-1',
    status: DownloadStatus.completed.index,
  );
  for (final episode in ['ep-1', 'ep-2']) {
    await db.insertDownload(
      serverId: serverId,
      ratingKey: episode,
      globalKey: 'srv:$episode',
      type: 'episode',
      parentRatingKey: 'season-1',
      grandparentRatingKey: 'show-1',
      status: DownloadStatus.completed.index,
    );
  }
  if (withCacheMissSurvivor) {
    await db.insertDownload(
      serverId: serverId,
      ratingKey: 'movie-1',
      globalKey: 'srv:movie-1',
      type: 'movie',
      status: DownloadStatus.completed.index,
    );
  }

  final artworkFile = File(await storage.getArtworkPathFromThumb(serverId, thumb));
  await artworkFile.create(recursive: true);
  await artworkFile.writeAsString('chapter thumb');

  // ep-2 (and the survivor when planted) are deliberately absent: cache misses.
  final client = _ChapterExtrasClient(
    cachedExtras: {
      'ep-1': PlaybackExtras(
        chapters: [MediaChapter(id: 1, thumb: thumb)],
        markers: const [],
      ),
    },
  );
  final manager = DownloadManagerService(
    database: db,
    storageService: storage,
    clientResolver: (serverId, {clientScopeId}) => client,
    downloadsSupportedOverride: false,
  )..recoveryFuture = Future<void>.value();

  try {
    await manager.deleteDownload('srv:season-1');
    return (thumbRetained: await artworkFile.exists(), networkFetches: client.networkFetchCount);
  } finally {
    manager.dispose();
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  }
}

/// Scripts cache-only playback extras per rating key; any network
/// `fetchPlaybackExtras` call is counted and rejected so tests can assert the
/// deletion reference scan never leaves the cache.
class _ChapterExtrasClient implements MediaServerClient {
  _ChapterExtrasClient({required this.cachedExtras});

  /// ratingKey → cache-only extras; a missing key models a cache miss.
  final Map<String, PlaybackExtras> cachedExtras;
  int networkFetchCount = 0;

  @override
  ServerId get serverId => ServerId('srv');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  }) async {
    networkFetchCount++;
    throw StateError('deletion reference scan must stay cache-only');
  }

  @override
  Future<PlaybackExtras?> fetchPlaybackExtrasFromCacheOnly(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) async => cachedExtras[itemId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  _FakeSafStorage({
    this.failDeletes = const {},
    Map<String, String> canonicalRoots = const {},
    Set<String> persistedRoots = const {},
    this.resolveOverride,
  }) : canonicalRoots = Map<String, String>.from(canonicalRoots),
       persistedRoots = Set<String>.from(persistedRoots);

  final Set<String> failDeletes;
  final Map<String, String> canonicalRoots;
  final Set<String> persistedRoots;
  final Future<String?> Function(String uri)? resolveOverride;
  final List<String> releaseCalls = [];
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
  Future<String?> createNestedDirectories(String parentUri, List<String> pathComponents) async {
    return _childrenByPath[_pathKey(parentUri, pathComponents)]?.uri;
  }

  @override
  Future<SafDocumentFile?> getChild(String parentUri, List<String> names) async {
    return _childrenByPath[_pathKey(parentUri, names)];
  }

  @override
  Future<List<SafDocumentFile>?> list(String uri) async {
    return List<SafDocumentFile>.from(_childrenByUri[uri] ?? const []);
  }

  @override
  Future<String?> resolvePersistedPermissionUri(String uri) async {
    final override = resolveOverride;
    if (override != null) return override(uri);
    return canonicalRoots[uri] ?? (_existing.contains(uri) ? uri : null);
  }

  @override
  Future<List<String>?> getPersistedPermissionUris() async {
    return persistedRoots.toList(growable: false);
  }

  @override
  Future<bool> releasePersistedPermission(String uri) async {
    releaseCalls.add(uri);
    persistedRoots.remove(uri);
    return true;
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

/// Where the app's private storage lived before it was moved to another volume.
const _previousAppDir = '/data/user/0/com.edde746.plezy/app_flutter';

DownloadTask _rootTask(String taskId, String globalKey, String directory) {
  return DownloadTask(
    taskId: taskId,
    url: 'https://example.test/video.mp4',
    filename: 'video.mp4',
    directory: directory,
    baseDirectory: BaseDirectory.root,
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

class _DirectCachePlexClient implements MediaServerClient, ScopedMediaServerClient {
  _DirectCachePlexClient({required this.serverId, required this.scopedServerId, required this.metadata});

  @override
  final ServerId serverId;

  @override
  final String scopedServerId;

  final MediaItem metadata;

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<MediaItem?> fetchItem(String id) async {
    if (id != metadata.id) return null;
    await PlexApiCache.instance.put(ServerId(scopedServerId), '/library/metadata/$id', {
      'MediaContainer': {
        'Metadata': [
          {'ratingKey': metadata.id, 'type': metadata.kind.id, 'title': metadata.title},
        ],
      },
    });
    return metadata;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
