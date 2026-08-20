import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/models/trackers/anime_ids.dart';
import 'package:plezy/models/trackers/tracker_context.dart';
import 'package:plezy/services/trackers/anilist/anilist_tracker.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/utils/external_ids.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(accessToken: 'token', expiresAt: now + 86400, createdAt: now);
}

TrackerContext _episode({int anilistId = 21, int episodeNumber = 12, int? animeProgress = 12}) {
  return TrackerContext.episode(
    external: const ExternalIds(tvdb: 1),
    anime: AnimeIds(anilist: anilistId),
    ratingKey: 'episode-1',
    libraryGlobalKey: null,
    season: 1,
    episodeNumber: episodeNumber,
    animeProgress: animeProgress,
  );
}

TrackerContext _movie({int anilistId = 21}) {
  return TrackerContext.movie(
    external: const ExternalIds(tmdb: 1),
    anime: AnimeIds(anilist: anilistId),
    ratingKey: 'movie-1',
    libraryGlobalKey: null,
  );
}

/// Mock answering the snapshot query with [media] and capturing every
/// SaveMediaListEntry variable map into [saved].
MockClient _mediaClient(Map<String, dynamic> media, List<Map<String, dynamic>> saved) {
  return MockClient((request) async {
    final body = json.decode(request.body) as Map<String, dynamic>;
    final query = body['query'] as String;
    if (query.contains('Media(id:')) {
      return http.Response(
        json.encode({
          'data': {'Media': media},
        }),
        200,
      );
    }
    if (query.contains('SaveMediaListEntry')) {
      saved.add((body['variables'] as Map).cast<String, dynamic>());
      return http.Response(
        json.encode({
          'data': {
            'SaveMediaListEntry': {'id': 1},
          },
        }),
        200,
      );
    }
    fail('Unexpected AniList query: $query');
  });
}

void main() {
  group('AnilistTracker', () {
    final tracker = AnilistTracker.instance;

    tearDown(() {
      tracker.rebindSession(null, onSessionInvalidated: () {});
    });

    test('marks completed when scoped progress reaches AniList total', () async {
      final saved = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        if (query.contains('Media(id:')) {
          return http.Response(
            json.encode({
              'data': {
                'Media': {'episodes': 12},
              },
            }),
            200,
          );
        }
        if (query.contains('SaveMediaListEntry')) {
          saved.add((body['variables'] as Map).cast<String, dynamic>());
          return http.Response(
            json.encode({
              'data': {
                'SaveMediaListEntry': {'id': 1},
              },
            }),
            200,
          );
        }
        fail('Unexpected AniList query: $query');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(animeProgress: 13));

      expect(saved.single, {'mediaId': 21, 'progress': 12, 'status': 'COMPLETED'});
    });

    test('fallback local progress stays current without using the anime total', () async {
      final saved = <Map<String, dynamic>>[];
      final client = _mediaClient({'episodes': 10}, saved);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      // Local episode numbers are not in the mapped anime's episode space, so
      // the known total (10) must neither clamp nor complete this write.
      await tracker.markWatched(_episode(animeProgress: null));

      expect(saved.single, {'mediaId': 21, 'progress': 12, 'status': 'CURRENT'});
    });

    test('keeps progress current when AniList total is unknown', () async {
      final saved = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        if (query.contains('Media(id:')) {
          return http.Response(
            json.encode({
              'data': {
                'Media': {'episodes': null},
              },
            }),
            200,
          );
        }
        if (query.contains('SaveMediaListEntry')) {
          saved.add((body['variables'] as Map).cast<String, dynamic>());
          return http.Response(
            json.encode({
              'data': {
                'SaveMediaListEntry': {'id': 1},
              },
            }),
            200,
          );
        }
        fail('Unexpected AniList query: $query');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode());

      expect(saved.single, {'mediaId': 21, 'progress': 12, 'status': 'CURRENT'});
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
      final variables = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        variables.add((body['variables'] as Map).cast<String, dynamic>());
        if (query.contains('mediaListEntry')) {
          return http.Response(
            json.encode({
              'data': {
                'Media': {
                  'mediaListEntry': {'id': 99},
                },
              },
            }),
            200,
          );
        }
        if (query.contains('DeleteMediaListEntry')) {
          return http.Response(
            json.encode({
              'data': {
                'DeleteMediaListEntry': {'deleted': true},
              },
            }),
            200,
          );
        }
        fail('Unexpected AniList query: $query');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.removeFromList(_episode());

      expect(variables, [
        {'mediaId': 21},
        {'id': 99},
      ]);
    });

    test('keeps the snapshot cached when the write fails', () async {
      var counts = 0;
      var saves = 0;
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        if (query.contains('Media(id:')) {
          counts++;
          return http.Response(
            json.encode({
              'data': {
                'Media': {'episodes': 12},
              },
            }),
            200,
          );
        }
        if (query.contains('SaveMediaListEntry')) {
          saves++;
          return saves == 1
              ? http.Response('boom', 500)
              : http.Response(
                  json.encode({
                    'data': {
                      'SaveMediaListEntry': {'id': 1},
                    },
                  }),
                  200,
                );
        }
        fail('Unexpected AniList query: $query');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await expectLater(tracker.markWatched(_episode()), throwsA(isA<TrackerApiException>()));
      await tracker.markWatched(_episode());

      expect(counts, 1, reason: 'a failed write must not evict the snapshot the retry needs');
      expect(saves, 2);
    });

    test('re-fetches the episode count after a failed lookup', () async {
      var counts = 0;
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        if (query.contains('Media(id:')) {
          counts++;
          return counts == 1
              ? http.Response('boom', 500)
              : http.Response(
                  json.encode({
                    'data': {
                      'Media': {'episodes': 12},
                    },
                  }),
                  200,
                );
        }
        if (query.contains('SaveMediaListEntry')) {
          return http.Response(
            json.encode({
              'data': {
                'SaveMediaListEntry': {'id': 1},
              },
            }),
            200,
          );
        }
        fail('Unexpected AniList query: $query');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode());
      await tracker.markWatched(_episode());

      expect(counts, 2);
    });

    test('keeps a rewatching entry repeating mid-series', () async {
      final saved = <Map<String, dynamic>>[];
      final client = _mediaClient({
        'episodes': 12,
        'mediaListEntry': {'status': 'REPEATING', 'repeat': 2},
      }, saved);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(episodeNumber: 5, animeProgress: 5));

      expect(saved.single, {'mediaId': 21, 'progress': 5, 'status': 'REPEATING'});
    });

    test('bumps the rewatch count when a rewatch completes', () async {
      final saved = <Map<String, dynamic>>[];
      final client = _mediaClient({
        'episodes': 12,
        'mediaListEntry': {'status': 'REPEATING', 'repeat': 2},
      }, saved);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(animeProgress: 12));

      expect(saved.single, {'mediaId': 21, 'progress': 12, 'status': 'COMPLETED', 'repeat': 3});
    });

    test('starts a rewatch when new progress lands on a completed entry', () async {
      final saved = <Map<String, dynamic>>[];
      final client = _mediaClient({
        'episodes': 12,
        'mediaListEntry': {'status': 'COMPLETED', 'repeat': 1},
      }, saved);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(episodeNumber: 1, animeProgress: 1));

      expect(saved.single, {'mediaId': 21, 'progress': 1, 'status': 'REPEATING'});
    });

    test('movie rewatch completes with a bumped rewatch count', () async {
      final saved = <Map<String, dynamic>>[];
      final client = _mediaClient({
        'episodes': 1,
        'mediaListEntry': {'status': 'REPEATING', 'repeat': 0},
      }, saved);
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_movie());

      expect(saved.single, {'mediaId': 21, 'progress': 1, 'status': 'COMPLETED', 'repeat': 1});
    });

    test('sequential rewatch writes observe the post-write snapshot, not the pre-write one', () async {
      final saved = <Map<String, dynamic>>[];
      var snapshotFetches = 0;
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        if (query.contains('Media(id:')) {
          snapshotFetches++;
          // First write completes a rewatch (repeat 2 -> 3). The second fetch
          // returns the post-write entry; replaying the stale pre-write
          // snapshot would write repeat 3 again.
          final entry = snapshotFetches == 1
              ? {'status': 'REPEATING', 'repeat': 2}
              : {'status': 'COMPLETED', 'repeat': 3};
          return http.Response(
            json.encode({
              'data': {
                'Media': {'episodes': 12, 'mediaListEntry': entry},
              },
            }),
            200,
          );
        }
        if (query.contains('SaveMediaListEntry')) {
          saved.add((body['variables'] as Map).cast<String, dynamic>());
          return http.Response(
            json.encode({
              'data': {
                'SaveMediaListEntry': {'id': 1},
              },
            }),
            200,
          );
        }
        fail('Unexpected AniList query: $query');
      });
      tracker.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: client);

      await tracker.markWatched(_episode(animeProgress: 12));
      await tracker.markWatched(_episode(animeProgress: 12));

      expect(snapshotFetches, 2, reason: 'a successful write must evict the memoized snapshot');
      expect(saved, [
        {'mediaId': 21, 'progress': 12, 'status': 'COMPLETED', 'repeat': 3},
        {'mediaId': 21, 'progress': 12, 'status': 'COMPLETED'},
      ]);
    });
  });
}
