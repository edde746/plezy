import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_file_info.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/active_client_scope.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

/// `/library/metadata/{id}` is a shared cache row, and `getPlaybackExtras`
/// fills it from a request without `includeStreams` / `checkFiles`. File Info
/// must not serve that lean row: it would render with no stream table and no
/// file-presence flags.
void main() {
  const endpoint = '/library/metadata/movie-1';
  final serverId = ServerId('server-1');
  final scopeA = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');
  final scopeB = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-b');

  late AppDatabase database;
  late PlexApiCache cache;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    cache = PlexApiCache.instance;
  });

  tearDown(() => database.close());

  PlexClient clientRecording(List<Uri> requested, {Map<String, dynamic>? response, http.Response? failure}) {
    final client = testPlexClient(
      serverId: serverId,
      profileScopeId: scopeA,
      handler: (request) async {
        final probe = _failoverProbe(request, serverId);
        if (probe != null) return probe;
        requested.add(request.url);
        return failure ?? _jsonResponse(response ?? _fullMetadata);
      },
    );
    addTearDown(client.close);
    return client;
  }

  test('a lean cached metadata row is refetched with the full file-info shape', () async {
    await cache.put(scopeA.cacheServerId, endpoint, _leanMetadata);
    final requested = <Uri>[];
    final client = clientRecording(requested);

    final info = await client.getFileInfo(_movie());

    expect(requested, hasLength(1), reason: 'exactly one refetch, not one per part');
    expect(requested.single.queryParameters['includeStreams'], '1');
    expect(requested.single.queryParameters['checkFiles'], '1');

    final part = info!.versions.single.parts.single;
    expect(part.streamsOfKind(MediaStreamKind.video), hasLength(1));
    expect(part.exists, isTrue);
    expect(part.accessible, isTrue);
  });

  test('a complete cached row is served without touching the network', () async {
    await cache.put(scopeA.cacheServerId, endpoint, _fullMetadata);
    final requested = <Uri>[];
    final client = clientRecording(requested);

    final info = await client.getFileInfo(_movie());

    expect(requested, isEmpty);
    expect(info!.versions.single.parts.single.streamsOfKind(MediaStreamKind.video), hasLength(1));
  });

  test('a part probed as empty still counts as complete', () async {
    // `includeStreams=1` on a part with nothing probed yields `Stream: []`.
    // That is a complete answer, not a lean row, and must not trigger a
    // refetch every time the sheet opens.
    await cache.put(scopeA.cacheServerId, endpoint, _probedEmptyMetadata);
    final requested = <Uri>[];
    final client = clientRecording(requested);

    final info = await client.getFileInfo(_movie());

    expect(requested, isEmpty);
    expect(info!.versions.single.parts.single.streams, isEmpty);
  });

  test('one complete part does not excuse a lean sibling', () async {
    await cache.put(scopeA.cacheServerId, endpoint, _mixedPartsMetadata);
    final requested = <Uri>[];
    final client = clientRecording(requested);

    await client.getFileInfo(_movie());

    expect(requested, hasLength(1));
  });

  test('offline mode keeps the lean row rather than failing', () async {
    await cache.put(scopeA.cacheServerId, endpoint, _leanMetadata);
    final requested = <Uri>[];
    final client = clientRecording(requested);
    client.setOfflineMode(true);

    final info = await client.getFileInfo(_movie());

    expect(requested, isEmpty);
    expect(info!.versions.single.parts.single.filePath, '/media/movie.mkv');
    expect(info.versions.single.parts.single.streams, isEmpty);
  });

  test('a failed refetch falls back to the lean row instead of returning nothing', () async {
    await cache.put(scopeA.cacheServerId, endpoint, _leanMetadata);
    final requested = <Uri>[];
    final client = clientRecording(requested, failure: http.Response('boom', 500));

    final info = await client.getFileInfo(_movie());

    expect(requested, isNotEmpty);
    expect(info, isNotNull);
    expect(info!.versions.single.parts.single.filePath, '/media/movie.mkv');
  });

  test('the refetch keeps the profile identity captured before the cache read', () async {
    await cache.put(scopeA.cacheServerId, endpoint, _leanMetadata);

    final tokens = <String?>[];
    final client = testPlexClient(
      token: 'token-a',
      serverId: serverId,
      profileScopeId: scopeA,
      handler: (request) async {
        final probe = _failoverProbe(request, serverId);
        if (probe != null) return probe;
        tokens.add(_plexToken(request));
        return _jsonResponse(_fullMetadata);
      },
    );
    addTearDown(client.close);

    // Hold the cache read open so the profile switch lands between the
    // cache-first lookup and the refetch — the exact window the captured
    // request context exists to close.
    final releaseCacheRead = Completer<void>();
    final transactionStarted = Completer<void>();
    final heldTransaction = database.transaction(() async {
      transactionStarted.complete();
      await releaseCacheRead.future;
    });
    await transactionStarted.future;

    final infoFuture = client.getFileInfo(_movie());
    try {
      await client.applyProfileUpdate(newToken: 'token-b', newProfileScopeId: scopeB);
    } finally {
      releaseCacheRead.complete();
    }
    await heldTransaction;
    final info = await infoFuture;

    expect(tokens, ['token-a']);
    expect(info!.versions.single.parts.single.exists, isTrue);
    expect(await cache.get(scopeA.cacheServerId, endpoint), _fullMetadata);
    expect(await cache.get(scopeB.cacheServerId, endpoint), isNull);
  });
}

MediaItem _movie() => testMediaItem(id: 'movie-1', title: 'Movie', serverId: 'server-1');

/// The failover client probes server identity before the first real request.
http.Response? _failoverProbe(http.Request request, ServerId serverId) {
  if (request.url.path == '/') {
    return _jsonResponse({
      'MediaContainer': {'machineIdentifier': serverId.value},
    });
  }
  if (request.url.path == '/media/providers') {
    return _jsonResponse({
      'MediaContainer': {'MediaProvider': <Object>[]},
    });
  }
  return null;
}

String? _plexToken(http.Request request) {
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == 'x-plex-token') return entry.value;
  }
  return null;
}

http.Response _jsonResponse(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200, headers: const {'content-type': 'application/json'});

Map<String, dynamic> _metadata(List<Map<String, dynamic>> parts) => {
  'MediaContainer': {
    'Metadata': [
      {
        'ratingKey': 'movie-1',
        'title': 'Movie',
        'type': 'movie',
        'Media': [
          {'id': 1, 'container': 'mkv', 'videoCodec': 'h264', 'Part': parts},
        ],
      },
    ],
  },
};

/// What `getPlaybackExtras` caches: no `Stream`, no `exists`/`accessible`.
final _leanMetadata = _metadata([
  {'id': 10, 'file': '/media/movie.mkv', 'size': 100},
]);

final _fullMetadata = _metadata([
  {
    'id': 10,
    'file': '/media/movie.mkv',
    'size': 100,
    'exists': true,
    'accessible': true,
    'Stream': [
      {'id': 1, 'streamType': 1, 'codec': 'h264'},
    ],
  },
]);

final _probedEmptyMetadata = _metadata([
  {'id': 10, 'file': '/media/movie.mkv', 'size': 100, 'exists': true, 'accessible': true, 'Stream': <dynamic>[]},
]);

final _mixedPartsMetadata = _metadata([
  {
    'id': 10,
    'file': '/media/movie-cd1.mkv',
    'exists': true,
    'accessible': true,
    'Stream': [
      {'id': 1, 'streamType': 1, 'codec': 'h264'},
    ],
  },
  {'id': 11, 'file': '/media/movie-cd2.mkv'},
]);
