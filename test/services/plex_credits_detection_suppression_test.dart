import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/services/cached_playback_metadata_service.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/active_client_scope.dart';

import '../test_helpers/backend_client_fixtures.dart';

/// Plex strips detected credits markers from its responses when the admin
/// disables credits detection for a show or movie
/// (`enableCreditsMarkerGeneration == 0`), but Plezy's chapter-title fallback
/// would resurrect a credits skip action from a "Credits"/"Ending" chapter,
/// showing "Next Episode" during credits the admin asked to leave alone
/// (#2137). These tests pin the suppression rule: explicit `0` on the owning
/// show/movie drops credits markers; absent (non-Plex-Pass servers) and `-1`
/// ("Library default") keep them.
void main() {
  const episodeKey = 'ep-1';
  const showKey = 'show-1';
  const episodeEndpoint = '/library/metadata/$episodeKey';
  const showEndpoint = '/library/metadata/$showKey';
  final serverId = ServerId('server-1');
  final scope = buildPlexProfileScopeId(serverId: serverId, profileId: 'profile-a');

  late AppDatabase database;
  late PlexApiCache cache;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    cache = PlexApiCache.instance;
  });

  tearDown(() => database.close());

  PlexClient clientRecording(List<Uri> requested, {required Map<String, Map<String, dynamic>?> responsesByPath}) {
    final client = testPlexClient(
      serverId: serverId,
      profileScopeId: scope,
      handler: (request) async {
        final probe = _failoverProbe(request, serverId);
        if (probe != null) return probe;
        requested.add(request.url);
        final body = responsesByPath[request.url.path];
        if (body == null) return http.Response('', 404);
        return _jsonResponse(body);
      },
    );
    addTearDown(client.close);
    return client;
  }

  group('online (PlexClient.getPlaybackExtras)', () {
    test('drops the chapter-derived credits marker when the show disables credits detection', () async {
      final requested = <Uri>[];
      final client = clientRecording(
        requested,
        responsesByPath: {
          episodeEndpoint: _episodeResponse(chapters: _reporterChapters),
          showEndpoint: _showResponse(enableCreditsMarkerGeneration: 0),
        },
      );

      final extras = await client.getPlaybackExtras(episodeKey);

      expect(extras.markers.where((m) => m.isCredits), isEmpty);
      // Only credits behavior is disabled; the intro chapter still maps.
      expect(extras.markers.map((m) => m.type), ['intro']);
      expect(extras.chapters, hasLength(3), reason: 'chapters themselves stay for the timeline');
      expect(requested.map((u) => u.path), [episodeEndpoint, showEndpoint]);
    });

    test('keeps the chapter-derived credits marker when the show has no preference attribute', () async {
      // Non-Plex-Pass servers never emit the attribute; the fallback is the
      // only credits source there and must keep working.
      final requested = <Uri>[];
      final client = clientRecording(
        requested,
        responsesByPath: {
          episodeEndpoint: _episodeResponse(chapters: _reporterChapters),
          showEndpoint: _showResponse(enableCreditsMarkerGeneration: null),
        },
      );

      final extras = await client.getPlaybackExtras(episodeKey);

      expect(extras.markers.map((m) => m.type), containsAll(['intro', 'credits']));
    });

    test('keeps credits markers when the show preference is -1 (library default)', () async {
      final client = clientRecording(
        <Uri>[],
        responsesByPath: {
          episodeEndpoint: _episodeResponse(chapters: _reporterChapters),
          showEndpoint: _showResponse(enableCreditsMarkerGeneration: -1),
        },
      );

      final extras = await client.getPlaybackExtras(episodeKey);

      expect(extras.markers.any((m) => m.isCredits), isTrue);
    });

    test('never requests the show row when the episode yields no credits marker', () async {
      final requested = <Uri>[];
      final client = clientRecording(
        requested,
        responsesByPath: {
          episodeEndpoint: _episodeResponse(chapters: [_chapter(id: 1, tag: 'Scene 1', start: 0, end: 351280)]),
        },
      );

      final extras = await client.getPlaybackExtras(episodeKey);

      expect(extras.markers, isEmpty);
      expect(requested.map((u) => u.path), [episodeEndpoint]);
    });

    test('serves the show preference from the shared cache row without network', () async {
      await cache.put(scope.cacheServerId, showEndpoint, _showResponse(enableCreditsMarkerGeneration: 0));
      final requested = <Uri>[];
      final client = clientRecording(
        requested,
        responsesByPath: {episodeEndpoint: _episodeResponse(chapters: _reporterChapters)},
      );

      final extras = await client.getPlaybackExtras(episodeKey);

      expect(extras.markers.where((m) => m.isCredits), isEmpty);
      expect(requested.map((u) => u.path), [episodeEndpoint], reason: 'show row must come from cache');
    });

    test('a movie reads its own attribute and needs no second request', () async {
      final requested = <Uri>[];
      final client = clientRecording(
        requested,
        responsesByPath: {
          episodeEndpoint: _movieResponse(
            enableCreditsMarkerGeneration: 0,
            chapters: [_chapter(id: 9, tag: 'End Credits', start: 300000, end: 351280)],
          ),
        },
      );

      final extras = await client.getPlaybackExtras(episodeKey);

      expect(extras.markers, isEmpty);
      expect(requested.map((u) => u.path), [episodeEndpoint]);
    });

    test('also drops detected credits markers from a stale row when the show disables detection', () async {
      // A cached episode row can predate the setting change and still contain
      // server-detected markers; "any skip credits behavior" must stay off.
      await cache.put(
        scope.cacheServerId,
        episodeEndpoint,
        _episodeResponse(
          chapters: const [],
          markers: [
            {'id': 5, 'type': 'credits', 'startTimeOffset': 311080, 'endTimeOffset': 351280, 'final': true},
          ],
        ),
      );
      final client = clientRecording(
        <Uri>[],
        responsesByPath: {showEndpoint: _showResponse(enableCreditsMarkerGeneration: 0)},
      );

      final extras = await client.getPlaybackExtras(episodeKey);

      expect(extras.markers, isEmpty);
    });

    test('fails open when the show lookup errors', () async {
      final client = clientRecording(
        <Uri>[],
        // showEndpoint missing -> 404 on the grandparent fetch.
        responsesByPath: {episodeEndpoint: _episodeResponse(chapters: _reporterChapters)},
      );

      final extras = await client.getPlaybackExtras(episodeKey);

      expect(extras.markers.any((m) => m.isCredits), isTrue);
    });
  });

  group('offline (CachedPlaybackMetadataService)', () {
    test('suppresses credits markers when the cached show row disables detection', () async {
      await cache.put(scope.cacheServerId, episodeEndpoint, _episodeResponse(chapters: _reporterChapters));
      await cache.put(scope.cacheServerId, showEndpoint, _showResponse(enableCreditsMarkerGeneration: 0));

      final extras = await CachedPlaybackMetadataService.fetchPlaybackExtras(
        backend: MediaBackend.plex,
        cacheServerId: scope.cacheServerId.value,
        itemId: episodeKey,
      );

      expect(extras!.markers.where((m) => m.isCredits), isEmpty);
      expect(extras.markers.map((m) => m.type), ['intro']);
    });

    test('keeps credits markers when the show row is not cached', () async {
      await cache.put(scope.cacheServerId, episodeEndpoint, _episodeResponse(chapters: _reporterChapters));

      final extras = await CachedPlaybackMetadataService.fetchPlaybackExtras(
        backend: MediaBackend.plex,
        cacheServerId: scope.cacheServerId.value,
        itemId: episodeKey,
      );

      expect(extras!.markers.any((m) => m.isCredits), isTrue);
    });
  });
}

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

http.Response _jsonResponse(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200, headers: const {'content-type': 'application/json'});

Map<String, dynamic> _chapter({required int id, required String tag, required int start, required int end}) => {
  'id': id,
  'tag': tag,
  'index': id,
  'startTimeOffset': start,
  'endTimeOffset': end,
};

/// Chapter layout from the #2137 report: the "Credits" chapter ends at EOF, so
/// the synthesized marker is what relabeled the skip button "Next Episode".
final _reporterChapters = [
  _chapter(id: 1, tag: 'Intro', start: 0, end: 52520),
  _chapter(id: 2, tag: 'Scene 1', start: 52520, end: 311080),
  _chapter(id: 3, tag: 'Credits', start: 311080, end: 351280),
];

Map<String, dynamic> _episodeResponse({
  required List<Map<String, dynamic>> chapters,
  List<Map<String, dynamic>> markers = const [],
}) => {
  'MediaContainer': {
    'Metadata': [
      {
        'ratingKey': 'ep-1',
        'grandparentRatingKey': 'show-1',
        'type': 'episode',
        'title': 'Episode',
        'duration': 351338,
        if (chapters.isNotEmpty) 'Chapter': chapters,
        if (markers.isNotEmpty) 'Marker': markers,
      },
    ],
  },
};

Map<String, dynamic> _showResponse({required int? enableCreditsMarkerGeneration}) => {
  'MediaContainer': {
    'Metadata': [
      {
        'ratingKey': 'show-1',
        'type': 'show',
        'title': 'Show',
        'enableCreditsMarkerGeneration': ?enableCreditsMarkerGeneration,
      },
    ],
  },
};

Map<String, dynamic> _movieResponse({
  required int? enableCreditsMarkerGeneration,
  required List<Map<String, dynamic>> chapters,
}) => {
  'MediaContainer': {
    'Metadata': [
      {
        'ratingKey': 'ep-1',
        'type': 'movie',
        'title': 'Movie',
        'duration': 351338,
        'enableCreditsMarkerGeneration': ?enableCreditsMarkerGeneration,
        if (chapters.isNotEmpty) 'Chapter': chapters,
      },
    ],
  },
};
