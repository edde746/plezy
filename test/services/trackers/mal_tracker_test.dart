import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/models/trackers/anime_ids.dart';
import 'package:vibe_stream/models/trackers/tracker_context.dart';
import 'package:vibe_stream/services/trackers/mal/mal_session.dart';
import 'package:vibe_stream/services/trackers/mal/mal_tracker.dart';
import 'package:vibe_stream/utils/external_ids.dart';

MalSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return MalSession(accessToken: 'token', refreshToken: 'refresh', expiresAt: now + 86400, createdAt: now);
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
          expect(request.url.queryParameters['fields'], 'num_episodes');
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

    test('keeps fallback local progress as watching without total lookup', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'PUT') return http.Response('{}', 200);
        fail('Unexpected ${request.method} ${request.url}');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

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
  });
}
