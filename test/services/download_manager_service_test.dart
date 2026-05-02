import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/services/download_artwork_helpers.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';

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
              serverId: 'jf-machine',
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

      final manager = DownloadManagerService(database: db, storageService: DownloadStorageService.instance)
        ..setClientResolver((serverId, {clientScopeId}) {
          return _ScopedJellyfinClient(serverId: serverId, scopedServerId: clientScopeId ?? 'jf-machine/user-b');
        });

      final item = await manager.lookupMetadata('jf-machine', 'item-1', preferActiveScope: true);

      expect(item?.title, 'Cached for User A');
      expect(item?.serverId, 'jf-machine');
    });

    test('SAF recovery resolves show year from cached show metadata', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      addTearDown(db.close);

      await PlexApiCache.instance.put('srv-1', '/library/metadata/show-1', {
        'MediaContainer': {
          'Metadata': [
            {'ratingKey': 'show-1', 'type': 'show', 'title': 'The Show', 'year': 2008},
          ],
        },
      });

      final manager = DownloadManagerService(database: db, storageService: DownloadStorageService.instance);
      final year = await manager.debugResolveSafRecoveryShowYear(
        MediaItem(
          id: 'ep-1',
          backend: MediaBackend.plex,
          kind: MediaKind.episode,
          serverId: 'srv-1',
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

      await JellyfinApiCache.instance.put('jf-machine/user-a', '/Users/user-a/Items/item-1', {
        'Id': 'item-1',
        'Type': 'Episode',
        'Name': 'Episode',
      });
      await JellyfinApiCache.instance.put('jf-machine/user-a', '/MediaSegments/item-1', {
        'Items': [
          {'Type': 'Intro', 'StartTicks': 10000000, 'EndTicks': 20000000},
        ],
      });

      await JellyfinApiCache.instance.pinForOffline('jf-machine/user-a', 'item-1');

      expect(await JellyfinApiCache.instance.isPinned('jf-machine/user-a', '/MediaSegments/item-1'), isTrue);

      await JellyfinApiCache.instance.deleteForItem('jf-machine/user-a', 'item-1');

      expect(await JellyfinApiCache.instance.get('jf-machine/user-a', '/Users/user-a/Items/item-1'), isNull);
      expect(await JellyfinApiCache.instance.get('jf-machine/user-a', '/MediaSegments/item-1'), isNull);
    });
  });
}

MediaItem _movie({String? thumbPath}) {
  return MediaItem(
    id: 'item-1',
    backend: MediaBackend.jellyfin,
    kind: MediaKind.movie,
    serverId: 'jf-machine',
    thumbPath: thumbPath,
  );
}

class _ScopedJellyfinClient implements MediaServerClient, ScopedMediaServerClient {
  _ScopedJellyfinClient({required this.serverId, required this.scopedServerId});

  @override
  final String serverId;

  @override
  final String scopedServerId;

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
