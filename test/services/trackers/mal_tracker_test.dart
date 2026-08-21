import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/trackers/anime_ids.dart';
import 'package:plezy/models/trackers/tracker_context.dart';
import 'package:plezy/services/trackers/mal/mal_tracker.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/utils/external_ids.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(accessToken: 'token', refreshToken: 'refresh', expiresAt: now + 86400, createdAt: now);
}

TrackerContext _episode({int malId = 21, int episodeNumber = 12, int? animeProgress = 12}) {
  return TrackerContext.episode(
    external: const ExternalIds(tvdb: 1),
    anime: AnimeIds(mal: malId),
    ratingKey: 'episode-1',
    libraryGlobalKey: null,
    season: 1,
    episodeNumber: episodeNumber,
    animeProgress: animeProgress,
  );
}

/// Mock answering the snapshot GET with [getResponse] and capturing every
/// request into [requests].
MockClient _listClient(Map<String, dynamic> getResponse, List<http.Request> requests) {
  return MockClient((request) async {
    requests.add(request);
    if (request.method == 'GET') return http.Response(json.encode(getResponse), 200);
    if (request.method == 'PUT') return http.Response('{}', 200);
    fail('Unexpected ${request.method} ${request.url}');
  });
}

void main() {
  group('MalTracker', () {
    final tracker = MalTracker.instance;

    tearDown(() {
      tracker.rebindSession(null, onSessionInvalidated: () {});
    });

    test('marks completed when scoped progress reaches MAL total', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          expect(request.url.path, '/v2/anime/21');
          expect(request.url.queryParameters['fields'], 'num_episodes,my_list_status');
          return http.Response(json.encode({'num_episodes': 12}), 200);
        }
        if (request.method == 'PUT') return http.Response('{}', 200);
        fail('Unexpected ${request.method} ${request.url}');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(animeProgress: 13));

      final put = requests.singleWhere((request) => request.method == 'PUT');
      expect(Uri.splitQueryString(put.body), {'status': 'completed', 'num_watched_episodes': '12'});
    });

    test('fallback local progress stays watching without using the anime total', () async {
      final requests = <http.Request>[];
      final client = _listClient({'num_episodes': 10}, requests);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      // Local episode numbers are not in the mapped anime's episode space, so
      // the known total (10) must neither clamp nor complete this write.
      await tracker.markWatched(_episode(animeProgress: null));

      final put = requests.singleWhere((request) => request.method == 'PUT');
      expect(Uri.splitQueryString(put.body), {'status': 'watching', 'num_watched_episodes': '12'});
    });

    test('keeps progress as watching when MAL total is unknown', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') return http.Response(json.encode({'num_episodes': 0}), 200);
        if (request.method == 'PUT') return http.Response('{}', 200);
        fail('Unexpected ${request.method} ${request.url}');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode());

      final put = requests.singleWhere((request) => request.method == 'PUT');
      expect(Uri.splitQueryString(put.body), {'status': 'watching', 'num_watched_episodes': '12'});
    });

    test('episode unwatch is a no-op', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        fail('Unexpected ${request.method} ${request.url}');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markUnwatched(_episode(animeProgress: 1));

      expect(requests, isEmpty);
    });

    test('removeFromList removes anime entry', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE') return http.Response('{}', 200);
        fail('Unexpected ${request.method} ${request.url}');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.removeFromList(_episode());

      final delete = requests.single;
      expect(delete.method, 'DELETE');
      expect(delete.url.path, '/v2/anime/21/my_list_status');
    });

    test('caches the episode count across repeated markWatched calls', () async {
      var counts = 0;
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          counts++;
          return http.Response(json.encode({'num_episodes': 12}), 200);
        }
        if (request.method == 'PUT') return http.Response('{}', 200);
        fail('Unexpected ${request.method} ${request.url}');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode());
      await tracker.markWatched(_episode());

      expect(counts, 1);
    });

    test('re-fetches the episode count after a failed lookup', () async {
      var counts = 0;
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          counts++;
          // First lookup fails transiently; the failure is evicted so the next
          // markWatched re-fetches rather than caching the miss forever.
          return counts == 1 ? http.Response('boom', 500) : http.Response(json.encode({'num_episodes': 12}), 200);
        }
        if (request.method == 'PUT') return http.Response('{}', 200);
        fail('Unexpected ${request.method} ${request.url}');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode());
      await tracker.markWatched(_episode());

      expect(counts, 2);
    });

    test('clears the cached episode count when the session is rebound', () async {
      var counts = 0;
      http.Client makeClient() => MockClient((request) async {
        if (request.method == 'GET') {
          counts++;
          return http.Response(json.encode({'num_episodes': 12}), 200);
        }
        if (request.method == 'PUT') return http.Response('{}', 200);
        fail('Unexpected ${request.method} ${request.url}');
      });

      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: makeClient());
      await tracker.markWatched(_episode());

      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: makeClient());
      await tracker.markWatched(_episode());

      expect(counts, 2);
    });

    test('keeps a rewatching entry rewatching mid-series without touching status', () async {
      final requests = <http.Request>[];
      final client = _listClient({
        'num_episodes': 12,
        'my_list_status': {'status': 'completed', 'is_rewatching': true, 'num_times_rewatched': 2},
      }, requests);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(episodeNumber: 5, animeProgress: 5));

      final put = requests.singleWhere((request) => request.method == 'PUT');
      expect(Uri.splitQueryString(put.body), {'num_watched_episodes': '5', 'is_rewatching': 'true'});
    });

    test('bumps the rewatch count when a rewatch completes', () async {
      final requests = <http.Request>[];
      final client = _listClient({
        'num_episodes': 12,
        'my_list_status': {'status': 'completed', 'is_rewatching': true, 'num_times_rewatched': 2},
      }, requests);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(animeProgress: 12));

      final put = requests.singleWhere((request) => request.method == 'PUT');
      expect(Uri.splitQueryString(put.body), {
        'status': 'completed',
        'num_watched_episodes': '12',
        'is_rewatching': 'false',
        'num_times_rewatched': '3',
      });
    });

    test('starts a rewatch when new progress lands on a completed entry', () async {
      final requests = <http.Request>[];
      final client = _listClient({
        'num_episodes': 12,
        'my_list_status': {'status': 'completed', 'is_rewatching': false, 'num_times_rewatched': 0},
      }, requests);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(episodeNumber: 1, animeProgress: 1));

      final put = requests.singleWhere((request) => request.method == 'PUT');
      expect(Uri.splitQueryString(put.body), {'num_watched_episodes': '1', 'is_rewatching': 'true'});
    });
  });
}
