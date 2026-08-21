import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/trackers/tracker_context.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_tracker.dart';
import 'package:plezy/services/trackers/tracker.dart';
import 'package:plezy/services/trackers/tracker_id_resolver.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/utils/external_ids.dart';

typedef _Call = ({String path, Map<String, dynamic> body});

class _Recorder {
  final List<_Call> calls = [];

  http.Client client() => MockClient((req) async {
    calls.add((path: req.url.path, body: json.decode(req.body) as Map<String, dynamic>));
    return http.Response('{}', 200);
  });
}

/// Far-future expiry: a session that looks stale would send the tracker down
/// the refresh path and out to the real network.
TrackerSession _session() =>
    TrackerSession(accessToken: 'at', refreshToken: 'rt', expiresAt: 4000000000, createdAt: 1900000000);

TrackerContext _episode({ExternalIds external = const ExternalIds(imdb: 'tt0903747', tmdb: 1396)}) =>
    TrackerContext.episode(
      external: external,
      anime: null,
      ratingKey: 'episode-1',
      libraryGlobalKey: null,
      season: 2,
      episodeNumber: 5,
    );

TrackerContext _movie({ExternalIds external = const ExternalIds(imdb: 'tt0372784', tmdb: 272)}) =>
    TrackerContext.movie(external: external, anime: null, ratingKey: 'movie-1', libraryGlobalKey: null);

void main() {
  late _Recorder recorder;

  setUp(() async {
    recorder = _Recorder();
    MdblistTracker.instance.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client());
    await MdblistTracker.instance.setEnabled(true);
  });

  tearDown(() async {
    MdblistTracker.instance.rebindSession(null, onSessionInvalidated: () {});
    await MdblistTracker.instance.setEnabled(false);
  });

  group('scrobble', () {
    test('nests the episode inside the show as season.episode', () async {
      await MdblistTracker.instance.scrobble(_episode(), TrackerScrobbleState.start, 42.755);

      expect(recorder.calls.single.path, '/scrobble/start');
      expect(recorder.calls.single.body, {
        'show': {
          'ids': {'imdb': 'tt0903747', 'tmdb': 1396},
          'season': {
            'number': 2,
            'episode': {'number': 5},
          },
        },
        'progress': 42.76,
      });
    });

    test('sends a movie as a flat ids block', () async {
      await MdblistTracker.instance.scrobble(_movie(), TrackerScrobbleState.stop, 91.0);

      expect(recorder.calls.single.path, '/scrobble/stop');
      expect(recorder.calls.single.body, {
        'movie': {
          'ids': {'imdb': 'tt0372784', 'tmdb': 272},
        },
        'progress': 91.0,
      });
    });

    test('checkpoints a seek through start, the endpoint that upserts progress', () async {
      await MdblistTracker.instance.scrobble(_movie(), TrackerScrobbleState.seek, 30.0);

      expect(recorder.calls.single.path, '/scrobble/start');
    });

    test('clamps an overshooting progress into the accepted range', () async {
      await MdblistTracker.instance.scrobble(_movie(), TrackerScrobbleState.stop, 100.4);

      expect(recorder.calls.single.body['progress'], 100.0);
    });
  });

  group('watched history', () {
    test('records an episode with the replayed timestamp', () async {
      await MdblistTracker.instance.markWatched(_episode(), watchedAt: DateTime.utc(2026, 3, 1, 12, 30));

      expect(recorder.calls.single.path, '/sync/watched');
      expect(recorder.calls.single.body, {
        'shows': [
          {
            'ids': {'imdb': 'tt0903747', 'tmdb': 1396},
            'seasons': [
              {
                'number': 2,
                'episodes': [
                  {'number': 5, 'watched_at': '2026-03-01T12:30:00.000Z'},
                ],
              },
            ],
          },
        ],
      });
    });

    test('omits the timestamp on a live mark', () async {
      await MdblistTracker.instance.markWatched(_movie());

      expect(recorder.calls.single.body, {
        'movies': [
          {
            'ids': {'imdb': 'tt0372784', 'tmdb': 272},
          },
        ],
      });
    });

    test('removes through the dedicated endpoint without a timestamp', () async {
      await MdblistTracker.instance.markUnwatched(_episode());

      expect(recorder.calls.single.path, '/sync/watched/remove');
      final season = (recorder.calls.single.body['shows'] as List).single as Map<String, dynamic>;
      final episode = ((season['seasons'] as List).single as Map<String, dynamic>)['episodes'] as List;
      expect((episode.single as Map<String, dynamic>).containsKey('watched_at'), isFalse);
    });

    test('stays silent when the tracker is disabled', () async {
      await MdblistTracker.instance.setEnabled(false);

      await MdblistTracker.instance.markWatched(_movie());

      expect(recorder.calls, isEmpty);
    });
  });

  // MDBList's id block has no `tvdb` field, so an item the media server only
  // identifies by TVDB must be skipped rather than written under a partial or
  // wrong identity.
  group('unusable ids', () {
    test('writes nothing for a TVDB-only episode', () async {
      await MdblistTracker.instance.markWatched(_episode(external: const ExternalIds(tvdb: 81189)));
      await MdblistTracker.instance.scrobble(
        _episode(external: const ExternalIds(tvdb: 81189)),
        TrackerScrobbleState.start,
        10,
      );

      expect(recorder.calls, isEmpty);
    });

    test('still writes when only one supported id is present', () async {
      await MdblistTracker.instance.markWatched(_movie(external: const ExternalIds(tmdb: 272)));

      expect((recorder.calls.single.body['movies'] as List).single, {
        'ids': {'tmdb': 272},
      });
    });
  });

  group('reconcileWatchedAfterStop', () {
    test('leaves the watch to MDBList at or above its own 80% rule', () async {
      await MdblistTracker.instance.reconcileWatchedAfterStop(_movie(), 80.0);

      expect(recorder.calls, isEmpty);
    });

    test('records the watch explicitly below the rule', () async {
      await MdblistTracker.instance.reconcileWatchedAfterStop(_movie(), 79.9);

      expect(recorder.calls.single.path, '/sync/watched');
    });
  });

  group('ratings', () {
    test('rates a season through the nested show shape', () async {
      await MdblistTracker.instance.rate(
        TrackerRatingContext(
          ids: const TrackerIds(external: ExternalIds(imdb: 'tt0903747'), anime: null),
          kind: MediaKind.season,
          season: 2,
        ),
        9,
      );

      expect(recorder.calls.single.path, '/sync/ratings');
      expect(recorder.calls.single.body, {
        'shows': [
          {
            'ids': {'imdb': 'tt0903747'},
            'seasons': [
              {'number': 2, 'rating': 9},
            ],
          },
        ],
      });
    });

    test('clears a movie rating without sending a score', () async {
      await MdblistTracker.instance.clearRating(
        TrackerRatingContext(
          ids: const TrackerIds(external: ExternalIds(imdb: 'tt0372784'), anime: null),
          kind: MediaKind.movie,
        ),
      );

      expect(recorder.calls.single.path, '/sync/ratings/remove');
      expect((recorder.calls.single.body['movies'] as List).single, {
        'ids': {'imdb': 'tt0372784'},
      });
    });

    test('reports unavailable when no supported id is present', () async {
      await expectLater(
        MdblistTracker.instance.rate(
          TrackerRatingContext(
            ids: const TrackerIds(external: ExternalIds(tvdb: 81189), anime: null),
            kind: MediaKind.movie,
          ),
          7,
        ),
        throwsA(isA<TrackerRatingUnavailableException>()),
      );
    });
  });
}
