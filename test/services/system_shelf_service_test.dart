import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/system_shelf_service.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

class _ShelfClient implements MediaServerClient {
  _ShelfClient({this.throwOnThumbnail = false});

  final bool throwOnThumbnail;
  final List<({String? path, int? width, int? height})> thumbnailRequests = [];

  @override
  ServerId get serverId => ServerId('server-a');

  @override
  String get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) {
    if (throwOnThumbnail) throw StateError('conversion failed');
    thumbnailRequests.add((path: path, width: width, height: height));
    return 'https://media.invalid$path?token=transient';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/system_shelf');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // The real Plex/Jellyfin client fixtures used by the updateSources tests
  // construct their API caches at creation time.
  setUpAll(() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
    addTearDown(db.close);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('live shelf tap acknowledges only an attached consumer', () async {
    final service = SystemShelfService.forTesting(channel: channel);
    const call = MethodCall('onShelfItemTap', {'contentId': 'server:item'});

    expect(await service.handleMethodCallForTesting(call), isFalse);

    final received = <String>[];
    service.onShelfItemTap = received.add;
    expect(await service.handleMethodCallForTesting(call), isTrue);
    expect(received, ['server:item']);
  });

  test('delayed support result is dropped after synchronous owner invalidation', () async {
    final support = Completer<bool>();
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () => support.future);
    service.beginProfileSession('owner-a');

    final delayed = service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient());
    final ended = service.endProfileSession('owner-a');
    support.complete(true);

    expect(await delayed, isFalse);
    await ended;
    expect(calls.map((call) => call.method), ['clear']);
    expect(calls.single.arguments, {
      'schemaVersion': SystemShelfService.schemaVersion,
      'ownerId': 'owner-a',
      'generation': 2,
    });
    expect(await service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient()), isFalse);
  });

  test('dispatched old sync settles before clear and new owner sync', () async {
    final syncDispatched = Completer<void>();
    final releaseOldSync = Completer<void>();
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'sync' && !syncDispatched.isCompleted) {
        syncDispatched.complete();
        await releaseOldSync.future;
      }
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    service.beginProfileSession('owner-a');
    final oldSync = service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient());
    await syncDispatched.future;

    final oldEnd = service.endProfileSession('owner-a');
    service.beginProfileSession('owner-b');
    final newSync = service.syncFromContinueWatching('owner-b', const [], (_) => _ShelfClient());
    await Future<void>.delayed(Duration.zero);
    expect(calls.map((call) => call.method), ['sync']);

    releaseOldSync.complete();
    expect(await oldSync, isTrue);
    await oldEnd;
    expect(await newSync, isTrue);
    expect(calls.map((call) => call.method), ['sync', 'clear', 'sync']);
    expect((calls.last.arguments as Map)['ownerId'], 'owner-b');
  });

  test('native failure is contained and the ordered tail accepts a later sync', () async {
    var syncCount = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'sync' && syncCount++ == 0) {
        throw PlatformException(code: 'first-failed');
      }
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    service.beginProfileSession('owner-a');

    expect(await service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient()), isFalse);
    expect(await service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient()), isTrue);
    expect(syncCount, 2);
  });

  test('versioned payload carries transient source only and conversion failure keeps metadata', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    service.beginProfileSession('owner-a');
    final item = testMediaItem(
      id: 'item-a',
      backend: MediaBackend.plex,
      title: 'Private title',
      summary: 'Private summary',
      thumbPath: '/poster',
      serverId: 'server-a',
      serverName: 'Server',
    );

    final client = _ShelfClient();
    expect(await service.syncFromContinueWatching('owner-a', [item], (_) => client), isTrue);
    final envelope = calls.single.arguments as Map;
    expect(envelope['schemaVersion'], 3);
    expect(envelope['schemaVersion'], SystemShelfService.schemaVersion);
    expect(envelope['ownerId'], 'owner-a');
    final sent = (envelope['items'] as List).single as Map;
    expect(sent['posterSourceUri'], startsWith('https://media.invalid/'));
    expect(sent, isNot(contains('posterUri')));
    expect(client.thumbnailRequests.single, (path: '/poster', width: 640, height: 360));

    calls.clear();
    expect(
      await service.syncFromContinueWatching('owner-a', [item], (_) => _ShelfClient(throwOnThumbnail: true)),
      isTrue,
    );
    final fallback = (((calls.single.arguments as Map)['items'] as List).single as Map);
    expect(fallback['title'], 'Private title');
    expect(fallback['posterSourceUri'], isNull);
  });

  test('unsupported integration completes without native mutation', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls++;
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => false);
    service.beginProfileSession('owner-a');
    expect(await service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient()), isFalse);
    expect(nativeCalls, 0);
  });

  MediaItem shelfEpisode({String? parentThumbPath, String? grandparentThumbPath}) => testMediaItem(
    id: 'ep-1',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: 'Finale',
    grandparentTitle: 'Show',
    parentThumbPath: parentThumbPath,
    grandparentThumbPath: grandparentThumbPath,
    grandparentArtPath: '/spoiler-safe-art',
    thumbPath: '/episode-still',
    serverId: 'server-a',
    serverName: 'Server',
  );

  test('tvOS target walks the season/series/own poster chain at 600x900 and skips the spoiler override', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => true);
    final client = _ShelfClient();
    final service = SystemShelfService.forTesting(
      channel: channel,
      isSupported: () async => true,
      isTvosTarget: () => true,
    );
    service.beginProfileSession('owner-a');

    expect(
      await service.syncFromContinueWatching(
        'owner-a',
        [
          shelfEpisode(parentThumbPath: '/season-poster', grandparentThumbPath: '/series-poster'),
          shelfEpisode(grandparentThumbPath: '/series-poster'),
          shelfEpisode(),
        ],
        (_) => client,
        // Unwatched episodes would take the spoiler-safe art on Android;
        // posters cannot spoil, so tvOS must ignore the flag entirely.
        hideSpoilers: true,
      ),
      isTrue,
    );

    expect(client.thumbnailRequests.map((request) => request.path), [
      '/season-poster',
      '/series-poster',
      '/episode-still',
    ]);
    for (final request in client.thumbnailRequests) {
      expect((request.width, request.height), (600, 900));
    }
  });

  test('non-tvOS target keeps 640x360 episode thumbnails and the spoiler-safe override', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => true);
    final client = _ShelfClient();
    final service = SystemShelfService.forTesting(
      channel: channel,
      isSupported: () async => true,
      isTvosTarget: () => false,
    );
    service.beginProfileSession('owner-a');
    final episode = shelfEpisode(parentThumbPath: '/season-poster', grandparentThumbPath: '/series-poster');

    expect(await service.syncFromContinueWatching('owner-a', [episode], (_) => client, hideSpoilers: true), isTrue);
    expect(await service.syncFromContinueWatching('owner-a', [episode], (_) => client), isTrue);

    expect(client.thumbnailRequests.map((request) => request.path), ['/spoiler-safe-art', '/episode-still']);
    for (final request in client.thumbnailRequests) {
      expect((request.width, request.height), (640, 360));
    }
  });

  test('updateSources publishes per-kind descriptors and skips unusable clients', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isTvosTarget: () => true);
    service.beginProfileSession('owner-a');

    final plex = testPlexClient(
      serverId: ServerId('plex-1'),
      serverName: 'Plex Server',
      baseUrl: 'https://plex.example.com',
      token: 'plex-token',
    );
    final jellyfin = testJellyfinClient(
      connection: testJellyfinConnection(
        machineId: 'jf-1',
        userId: 'user-7',
        serverName: 'Jellyfin Server',
        baseUrl: 'https://jf.example.com',
        accessToken: 'jf-token',
      ),
    );
    final emby = testEmbyClient(
      connection: testEmbyConnection(machineId: 'emby-1', userId: 'emby-user', accessToken: 'emby-token'),
    );
    final tokenlessPlex = testPlexClient(serverId: ServerId('plex-2'), token: null);
    final tokenlessJellyfin = testJellyfinClient(
      connection: testJellyfinConnection(machineId: 'jf-2', accessToken: ''),
    );
    final unknownBackend = _ShelfClient();

    expect(
      await service.syncServerSources('owner-a', [
        plex,
        jellyfin,
        emby,
        tokenlessPlex,
        tokenlessJellyfin,
        unknownBackend,
      ]),
      isTrue,
    );

    expect(calls.single.method, 'updateSources');
    final envelope = calls.single.arguments as Map;
    expect(envelope['schemaVersion'], 3);
    expect(envelope['ownerId'], 'owner-a');
    expect(envelope['generation'], 1);
    expect(envelope['maxItems'], 20);
    final servers = (envelope['servers'] as List).cast<Map>();
    expect(servers, hasLength(3));
    expect(servers[0], {
      'serverId': 'plex-1',
      'kind': 'plex',
      'name': 'Plex Server',
      'baseUrl': 'https://plex.example.com',
      'token': 'plex-token',
    });
    expect(servers[1], {
      'serverId': 'jf-1',
      'kind': 'jellyfin',
      'name': 'Jellyfin Server',
      'baseUrl': 'https://jf.example.com',
      'token': 'jf-token',
      'userId': 'user-7',
    });
    expect(servers[2]['kind'], 'emby');
    expect(servers[2]['userId'], 'emby-user');
    expect(servers[2]['token'], 'emby-token');
  });

  test('syncServerSources is a no-op off tvOS', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls++;
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isTvosTarget: () => false);
    service.beginProfileSession('owner-a');

    expect(await service.syncServerSources('owner-a', [testPlexClient()]), isFalse);
    expect(nativeCalls, 0);
  });

  test('sources built for an invalidated owner are never dispatched', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isTvosTarget: () => true);
    service.beginProfileSession('owner-a');

    final pending = service.syncServerSources('owner-a', [testPlexClient()]);
    final ended = service.endProfileSession('owner-a');

    expect(await pending, isFalse);
    await ended;
    expect(calls.map((call) => call.method), ['clear']);
  });
}
