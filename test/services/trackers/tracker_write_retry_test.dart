import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/trackers/anime_lists_mapping.dart';
import 'package:plezy/models/trackers/fribb_mapping_row.dart';
import 'package:plezy/models/trackers/tracker_context.dart';
import 'package:plezy/services/trackers/anilist/anilist_tracker.dart';
import 'package:plezy/services/trackers/anime_episode_progress_resolver.dart';
import 'package:plezy/services/trackers/anime_lists_mapping_store.dart';
import 'package:plezy/services/trackers/fribb_mapping_store.dart';
import 'package:plezy/services/trackers/mal/mal_tracker.dart';
import 'package:plezy/services/trackers/simkl/simkl_tracker.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_coordinator.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/tracker_write_queue.dart';
import 'package:plezy/services/trackers/trakt/trakt_tracker.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';

/// Media server that only answers what the tracker resolver asks for.
class _FakeMediaServerClient implements MediaServerClient {
  @override
  final ServerId serverId;
  @override
  String? get serverName => null;

  final Map<String, ExternalIds> externalIdsByItem;

  @override
  final double watchedThreshold;

  _FakeMediaServerClient({required this.externalIdsByItem, this.watchedThreshold = 0.9})
    : serverId = ServerId('server-1');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async => externalIdsByItem[itemId] ?? const ExternalIds();

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async => const [];

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFribbLookup implements FribbMappingLookup {
  const _FakeFribbLookup(this.rows);

  final List<FribbMappingRow> rows;

  /// Filters by tvdb id so distinct shows map to distinct anime entries, which is
  /// what makes their queued rows distinct.
  @override
  Future<List<FribbMappingRow>> lookup({int? anidbId, int? tvdbId, int? tmdbId, String? imdbId}) async =>
      rows.where((row) => tvdbId == null || row.tvdbId == tvdbId).toList();

  @override
  Future<FribbMappingRow?> lookupByMal(int malId) async => rows.where((row) => row.malId == malId).firstOrNull;
}

/// Rollup resolution has its own suite; here the episode's own number is the claim.
class _FakeAnimeProgressLookup implements AnimeEpisodeProgressLookup {
  const _FakeAnimeProgressLookup();

  @override
  Future<ResolvedAnimeProgress?> resolve(
    MediaItem episode, {
    required AnimeProgressScope scope,
    AnimeEpisodeMatch? animeMatch,
    Future<AnimeEpisodeMatch?> Function(MediaItem episode)? episodeMatcher,
    bool includeCurrentEpisode = true,
  }) async => null;

  @override
  void clearCache() {}
}

class _FakeAnimeListsLookup implements AnimeListsMappingLookup {
  const _FakeAnimeListsLookup();

  @override
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber}) async => null;

  @override
  Future<Set<int>> lookupAnimeIdsForSeason({int? tvdbId, int? tmdbId, required int season}) async => const <int>{};

  @override
  Future<Set<int>> lookupAnimeIdsForShow({int? tvdbId, int? tmdbId}) async => const <int>{};
}

/// MAL posts form-encoded list updates; every other service posts JSON.
Map<String, dynamic> _decodeBody(String body) {
  if (body.isEmpty) return <String, dynamic>{};
  if (body.startsWith('{') || body.startsWith('[')) {
    final decoded = json.decode(body);
    return decoded is Map ? decoded.cast<String, dynamic>() : <String, dynamic>{'body': decoded};
  }
  return Uri.splitQueryString(body);
}

/// Records every request and can hold one write in flight, which is how
/// request ordering is driven without leaning on wall-clock timing. Reads
/// (the MAL list-snapshot GET) pass through ungated so the gate always lands
/// on the write whose ordering the test drives.
class _Recorder {
  final List<String> paths = [];
  final List<Map<String, dynamic>> bodies = [];
  Completer<void>? gate;
  int status = 200;

  http.Client get client => MockClient((request) async {
    paths.add(request.url.path);
    bodies.add(_decodeBody(request.body));
    if (request.method != 'GET') {
      final pending = gate;
      if (pending != null) await pending.future;
    }
    return http.Response('{}', status);
  });
}

/// Stands in for an endpoint that cannot be reached at all, as opposed to one
/// that answers with an error.
http.Client _unreachableClient() => MockClient((_) async => throw http.ClientException('no route to host'));

MediaItem _episodeItem(int number) => testMediaItem(
  id: 'episode-1-$number',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $number',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  parentIndex: 1,
  index: number,
  grandparentId: 'show-1',
);

MediaItem _episodeItemOfShow(String showId, int number) => testMediaItem(
  id: '$showId-episode-$number',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $number',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  parentIndex: 1,
  index: number,
  grandparentId: showId,
);

MediaItem _movieItem({int? viewOffsetMs, int? durationMs}) => testMediaItem(
  id: 'movie-1',
  backend: MediaBackend.plex,
  kind: MediaKind.movie,
  title: 'Movie 1',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  viewOffsetMs: viewOffsetMs,
  durationMs: durationMs,
);

/// Shows with their own tvdb id, each mapping to its own anime entry below.
const _showTvdbIds = {'show-a': 20001, 'show-b': 20002, 'show-c': 20003};

_FakeMediaServerClient _client({double watchedThreshold = 0.9}) => _FakeMediaServerClient(
  externalIdsByItem: {
    'show-1': const ExternalIds(tvdb: 12345),
    'movie-1': const ExternalIds(tmdb: 603),
    for (final show in _showTvdbIds.entries) show.key: ExternalIds(tvdb: show.value),
  },
  watchedThreshold: watchedThreshold,
);

TrackerSession _session() =>
    TrackerSession(accessToken: 'token', createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);

/// The list-status writes MAL received, newest last.
List<int> _malProgressWrites(_Recorder recorder) => [
  for (var i = 0; i < recorder.paths.length; i++)
    if (recorder.paths[i].contains('my_list_status')) int.parse(recorder.bodies[i]['num_watched_episodes'].toString()),
];

void main() {
  final coordinator = TrackerCoordinator.instance;
  final mal = MalTracker.instance;
  final anilist = AnilistTracker.instance;
  final simkl = SimklTracker.instance;
  final trakt = TraktTracker.instance;

  setUp(() async {
    resetSharedPreferencesForTest();
    coordinator.onActiveProfileChanged('user-a');
    coordinator.debugUseResolverDependencies(
      store: const _FakeFribbLookup([
        FribbMappingRow(tvdbId: 12345, malId: 101, anilistId: 201, type: 'TV'),
        FribbMappingRow(tvdbId: 20001, malId: 301, anilistId: 401, type: 'TV'),
        FribbMappingRow(tvdbId: 20002, malId: 302, anilistId: 402, type: 'TV'),
        FribbMappingRow(tvdbId: 20003, malId: 303, anilistId: 403, type: 'TV'),
      ]),
      animeLists: const _FakeAnimeListsLookup(),
      animeProgress: const _FakeAnimeProgressLookup(),
    );
    await anilist.setEnabled(false);
    await simkl.setEnabled(false);
    await trakt.setEnabled(false);
    await trakt.setWatchedSyncEnabled(false);
    await mal.setEnabled(true);
  });

  tearDown(() async {
    coordinator.cancelInFlight();
    coordinator.debugUseResolverDependencies();
    coordinator.onActiveProfileChanged('');
    mal.rebindSession(null, onSessionInvalidated: () {});
    anilist.rebindSession(null, onSessionInvalidated: () {});
    simkl.rebindSession(null, onSessionInvalidated: () {});
    trakt.rebindSession(null, onSessionInvalidated: () {});
    await mal.setEnabled(false);
    await trakt.setWatchedSyncEnabled(false);
  });

  group('failed watched writes are retried', () {
    test('a failed series-progress write is replayed on the next flush', () async {
      final recorder = _Recorder()..status = 500;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      await coordinator.markWatched(_episodeItem(5), _client());
      expect(_malProgressWrites(recorder), [5], reason: 'the first attempt goes out and fails');

      recorder.status = 200;
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recorder), [5, 5], reason: 'the queued claim is replayed once the service recovers');
    });

    test('a replayed write that already succeeded is not sent twice', () async {
      final recorder = _Recorder();
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      await coordinator.markWatched(_episodeItem(5), _client());
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recorder), [5]);
    });

    test('a newer completed claim drops the stale queued one', () async {
      final recorder = _Recorder()..status = 500;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      // Episode 5 fails and is queued as a claim of 5.
      await coordinator.markWatched(_episodeItem(5), _client());
      recorder.status = 200;
      // Episode 6 lands directly: the queued claim is now behind the counter.
      await coordinator.markWatched(_episodeItem(6), _client());
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recorder), [
        5,
        6,
      ], reason: 'replaying the claim of 5 after 6 landed would walk the list backwards');
    });

    test('a queued claim still ahead of the applied progress survives', () async {
      final recorder = _Recorder()..status = 500;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      await coordinator.markWatched(_episodeItem(6), _client());
      recorder.status = 200;
      await coordinator.markWatched(_episodeItem(5), _client());
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recorder), [6, 5, 6], reason: 'the queued 6 is a pending advance, not a stale claim');
    });
  });

  group('a failure racing a newer write is not persisted', () {
    test('an older history failure never replaces a newer one', () async {
      await mal.setEnabled(false);
      await trakt.setEnabled(true);
      await trakt.setWatchedSyncEnabled(true);
      final recorder = _Recorder()..status = 500;
      trakt.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      final client = _client();
      // Both fail, newest last: the queue must end up holding the un-watch.
      await coordinator.markWatched(_movieItem(), client);
      await coordinator.markUnwatched(_movieItem(), client);

      recorder
        ..status = 200
        ..paths.clear();
      await coordinator.flushWriteQueue();

      expect(recorder.paths, ['/sync/history/remove'], reason: 'the newest intent for the row is the only one queued');
    });

    test('a queued higher claim survives a newer lower one', () async {
      final recorder = _Recorder()..status = 500;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      // Episode 6 first, then 5: progress claims are monotonic, so the queue must
      // keep the higher one whichever order the failures arrive in.
      await coordinator.markWatched(_episodeItem(6), _client());
      await coordinator.markWatched(_episodeItem(5), _client());

      recorder.status = 200;
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recorder).last, 6);
    });
  });

  group('a rate-limited service', () {
    test('one back-off answer stops the drain asking again for that service', () async {
      final recorder = _Recorder()..status = 429;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      // Three separate shows, so three queued rows for one service.
      for (final show in ['show-a', 'show-b', 'show-c']) {
        await coordinator.markWatched(_episodeItemOfShow(show, 5), _client());
      }
      expect(_malProgressWrites(recorder), hasLength(3), reason: 'each live write tried once');

      recorder.paths.clear();
      await coordinator.flushWriteQueue();

      expect(
        _malProgressWrites(recorder),
        hasLength(1),
        reason: 'after the first 429 the drain leaves the rest of the service alone',
      );

      // Once it recovers, every row still drains.
      final recovered = _Recorder();
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recovered.client);
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recovered), hasLength(3));
    });

    test('a coalesced second flush does not re-ask during the same burst', () async {
      final recorder = _Recorder()..status = 429;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);
      for (final show in ['show-a', 'show-b']) {
        await coordinator.markWatched(_episodeItemOfShow(show, 5), _client());
      }

      recorder
        ..paths.clear()
        ..gate = Completer<void>();
      // Two triggers landing together — network restore and app resume can — so
      // the second coalesces onto the running drain and re-enters its loop.
      final first = coordinator.flushWriteQueue();
      await pumpEventQueue();
      final second = coordinator.flushWriteQueue();
      recorder.gate!.complete();
      await first;
      await second;

      expect(_malProgressWrites(recorder), hasLength(1), reason: 'the deferral spans the whole burst');
    });
  });

  group('isTrackerFailureTransient', () {
    test('separates non-verdicts from an answer about the write', () {
      // Never reached the service.
      expect(isTrackerFailureTransient(TimeoutException('timed out')), isTrue);
      expect(isTrackerFailureTransient(const SocketException('no route')), isTrue);
      expect(isTrackerFailureTransient(http.ClientException('closed')), isTrue);

      // The service asked us to come back.
      expect(
        isTrackerFailureTransient(
          const TrackerRateLimitException(service: TrackerService.trakt, retryAfterSeconds: 60),
        ),
        isTrue,
      );
      expect(
        isTrackerFailureTransient(const TrackerApiException(service: TrackerService.mal, statusCode: 429)),
        isTrue,
        reason: 'MAL and Simkl surface a 429 untyped',
      );

      // The service broke on its own side.
      expect(
        isTrackerFailureTransient(const TrackerApiException(service: TrackerService.simkl, statusCode: 500)),
        isTrue,
      );
      expect(
        isTrackerFailureTransient(const TrackerApiException(service: TrackerService.simkl, statusCode: 503)),
        isTrue,
      );

      // A refresh that can still succeed, versus a session that is really gone.
      expect(
        isTrackerFailureTransient(
          const TrackerAuthException(service: TrackerService.mal, message: 'Refresh failed: HTTP 503', statusCode: 503),
        ),
        isTrue,
      );
      expect(
        isTrackerFailureTransient(
          const TrackerAuthException(
            service: TrackerService.mal,
            message: 'Session invalidated (401)',
            statusCode: 401,
            isPermanent: true,
          ),
        ),
        isFalse,
      );

      // Answers about the write itself.
      for (final status in [400, 401, 403, 404, 409, 422]) {
        expect(
          isTrackerFailureTransient(TrackerApiException(service: TrackerService.trakt, statusCode: status)),
          isFalse,
          reason: 'HTTP $status is the service answering about this write',
        );
      }
    });
  });

  group('a service that cannot answer for the write', () {
    test('a rate limit never spends the retry budget', () async {
      final recorder = _Recorder()..status = 429;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);
      await coordinator.markWatched(_episodeItem(5), _client());

      for (var i = 0; i < TrackerWriteQueue.maxAttempts + 2; i++) {
        await coordinator.flushWriteQueue();
      }

      final recovered = _Recorder();
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recovered.client);
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recovered), [5], reason: 'a 429 is explicitly retryable, not a verdict on the write');
    });

    test('a server-side failure never spends the retry budget', () async {
      final recorder = _Recorder()..status = 503;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);
      await coordinator.markWatched(_episodeItem(5), _client());

      for (var i = 0; i < TrackerWriteQueue.maxAttempts + 2; i++) {
        await coordinator.flushWriteQueue();
      }

      final recovered = _Recorder();
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recovered.client);
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recovered), [5], reason: 'a bad hour for the service is not a bad watch');
    });

    test('a rejected write is dropped once its attempts are spent', () async {
      // 422 is the service answering about this write: asking again cannot help,
      // so the item must not be retried forever.
      final recorder = _Recorder()..status = 422;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);
      await coordinator.markWatched(_episodeItem(5), _client());

      for (var i = 0; i < TrackerWriteQueue.maxAttempts + 1; i++) {
        await coordinator.flushWriteQueue();
      }

      final recovered = _Recorder();
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recovered.client);
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recovered), isEmpty, reason: 'the answered rejection exhausted the budget');
    });

    test('an unreachable service never spends the retry budget', () async {
      final recorder = _Recorder()..status = 500;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);
      await coordinator.markWatched(_episodeItem(5), _client());
      expect(_malProgressWrites(recorder), [5], reason: 'the first attempt is answered and fails');

      // Now the endpoint is unreachable rather than answering. A connectivity flap
      // can drive many flushes; none of them may exhaust the item's attempts,
      // because nothing was learned about the write.
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: _unreachableClient());
      for (var i = 0; i < TrackerWriteQueue.maxAttempts + 2; i++) {
        await coordinator.flushWriteQueue();
      }

      // The service answers again: the watch is still queued and still lands.
      final recovered = _Recorder();
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recovered.client);
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recovered), [5], reason: 'the queued claim survived every unreachable flush');
    });
  });

  group('writes to one remote row are serialised', () {
    test('a replay already in flight cannot land after a newer direct write', () async {
      final recorder = _Recorder()..status = 500;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);
      await coordinator.markWatched(_episodeItem(5), _client());
      expect(_malProgressWrites(recorder), [5]);

      // Hold the replay's request open, then let a direct write for the same
      // entry arrive while it is still on the wire.
      recorder
        ..status = 200
        ..gate = Completer<void>();
      final flush = coordinator.flushWriteQueue();
      await pumpEventQueue();
      expect(_malProgressWrites(recorder), [5, 5], reason: 'the replay is in flight');

      final live = coordinator.markWatched(_episodeItem(6), _client());
      await pumpEventQueue();
      expect(_malProgressWrites(recorder), [5, 5], reason: 'the direct write waits for the row to be free');

      recorder.gate!.complete();
      await flush;
      await live;

      expect(_malProgressWrites(recorder).last, 6, reason: 'the newest write is the last one to reach the service');
    });
  });

  group('queued rows a completed write already covers', () {
    final ctx = TrackerContext.episode(
      external: const ExternalIds(tvdb: 12345),
      anime: null,
      ratingKey: 'episode-1-5',
      libraryGlobalKey: 'server-1:lib-1',
      season: 1,
      episodeNumber: 5,
    );

    TrackerWriteQueueItem item(String key) => TrackerWriteQueueItem(
      service: TrackerService.mal,
      watched: true,
      ctx: ctx,
      coalesceKey: key,
      progressClaim: 5,
      watchedAtIso: '2026-05-12T00:00:00.000Z',
    );

    test('a marked row is reported superseded until its marker is cleared', () async {
      final queue = TrackerWriteQueue();
      final key = trackerSeriesCoalesceKey(TrackerService.mal, 101);
      final queued = item(key);

      expect(queue.isSuperseded('user-a', queued), isFalse);

      final token = queue.noteDirectWrite('user-a', key, appliedProgress: 6);
      expect(queue.isSuperseded('user-a', queued), isTrue, reason: 'progress 6 covers a claim of 5');

      queue.clearDirectWrite('user-a', key, token);
      expect(queue.isSuperseded('user-a', queued), isFalse);
    });

    test('a marker only covers claims at or below the progress it applied', () async {
      final queue = TrackerWriteQueue();
      final key = trackerSeriesCoalesceKey(TrackerService.mal, 101);
      queue.noteDirectWrite('user-a', key, appliedProgress: 4);

      expect(queue.isSuperseded('user-a', item(key)), isFalse, reason: 'a claim of 5 is still a pending advance');
    });

    test('one profile\'s marker never covers another profile\'s queued row', () async {
      final queue = TrackerWriteQueue();
      final key = trackerSeriesCoalesceKey(TrackerService.mal, 101);
      queue.noteDirectWrite('user-a', key, appliedProgress: 6);

      expect(queue.isSuperseded('user-b', item(key)), isFalse);
      expect(queue.isSuperseded('user-a', item(key)), isTrue);
    });

    test('a stale marker cannot be cleared by an older write finishing', () async {
      final queue = TrackerWriteQueue();
      final key = trackerSeriesCoalesceKey(TrackerService.mal, 101);
      final first = queue.noteDirectWrite('user-a', key, appliedProgress: 6);
      queue.noteDirectWrite('user-a', key, appliedProgress: 7);

      queue.clearDirectWrite('user-a', key, first);

      expect(queue.isSuperseded('user-a', item(key)), isTrue, reason: 'the newer marker must survive');
    });
  });

  group('scrobbling turned off mid-playback', () {
    test('the watch still reaches history when the owner can no longer report', () async {
      await mal.setEnabled(false);
      await trakt.setEnabled(true);
      await trakt.setWatchedSyncEnabled(true);
      final recorder = _Recorder();
      trakt.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      final client = _client(watchedThreshold: 0.5);
      await coordinator.startPlayback(_movieItem(durationMs: 100000), client);
      coordinator.updateDuration(const Duration(milliseconds: 100000));
      // Crossing the threshold hands the watch to Trakt's own stop...
      coordinator.updatePosition(const Duration(milliseconds: 60000));
      await pumpEventQueue();
      // ...and then the user turns scrobbling off, so that stop never goes out.
      await trakt.setEnabled(false);
      recorder.paths.clear();
      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.paths, isNot(contains('/scrobble/stop')));
      expect(
        recorder.paths,
        contains('/sync/history'),
        reason: 'neither the crossing nor the stop recorded it, so the fallback must',
      );
    });
  });

  group('a terminal stop the service never acknowledged', () {
    test('Simkl records the watch through history when the stop fails', () async {
      await mal.setEnabled(false);
      await simkl.setEnabled(true);
      final recorder = _Recorder();
      simkl.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      final client = _client();
      await coordinator.startPlayback(_movieItem(durationMs: 100000), client);
      // Past the server threshold, and past Simkl's own 80% completion rule, so a
      // confirmed stop would have recorded the watch by itself.
      coordinator.updateDuration(const Duration(milliseconds: 100000));
      coordinator.updatePosition(const Duration(milliseconds: 95000));
      recorder.status = 500;
      await coordinator.stopPlayback();
      recorder.status = 200;
      await pumpEventQueue();

      expect(recorder.paths, contains('/scrobble/stop'));
      expect(
        recorder.paths.where((path) => path == '/sync/history'),
        hasLength(1),
        reason: 'nothing on Simkl saw the item finish, so the watch falls back to history',
      );
    });

    test('a confirmed stop above the completion rule writes no history', () async {
      await mal.setEnabled(false);
      await simkl.setEnabled(true);
      final recorder = _Recorder();
      simkl.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      final client = _client();
      await coordinator.startPlayback(_movieItem(durationMs: 100000), client);
      coordinator.updateDuration(const Duration(milliseconds: 100000));
      coordinator.updatePosition(const Duration(milliseconds: 95000));
      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.paths, contains('/scrobble/stop'));
      expect(recorder.paths, isNot(contains('/sync/history')), reason: 'the stop already recorded the watch');
    });
  });

  group('an account rebound while its write was in flight', () {
    test('a markWatched failure completing after a disconnect is not queued', () async {
      final recorder = _Recorder()..status = 500;
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      // Hold the write on the wire, then disconnect the account underneath it.
      recorder.gate = Completer<void>();
      final write = coordinator.markWatched(_episodeItem(5), _client());
      await pumpEventQueue();
      expect(_malProgressWrites(recorder), [5], reason: 'the write is in flight');

      mal.rebindSession(null, onSessionInvalidated: () {});
      recorder.gate!.complete();
      recorder.gate = null;
      await write;

      // Account B connects: A's late failure must not have left a row behind,
      // because the disconnect purge that would remove it has already run.
      final recovered = _Recorder();
      mal.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recovered.client);
      await coordinator.flushWriteQueue();

      expect(_malProgressWrites(recovered), isEmpty, reason: "account A's late failure must not replay through B");
    });

    test('a reconcile failure completing after a disconnect is not queued', () async {
      await mal.setEnabled(false);
      await simkl.setEnabled(true);
      final recorder = _Recorder();
      simkl.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

      // Watched by the server's rule but below Simkl's own 80% completion rule,
      // so a confirmed stop leaves the watch to reconciliation's history write.
      final client = _client(watchedThreshold: 0.5);
      await coordinator.startPlayback(_movieItem(durationMs: 100000), client);
      coordinator.updateDuration(const Duration(milliseconds: 100000));
      coordinator.updatePosition(const Duration(milliseconds: 60000));
      // The unawaited start report must settle before the gate arms, or the
      // gate would catch it instead of the stop.
      await pumpEventQueue();

      recorder.gate = Completer<void>();
      final stopping = coordinator.stopPlayback();
      await pumpEventQueue();
      expect(recorder.paths, contains('/scrobble/stop'), reason: 'the stop is in flight');
      // Let the stop through confirmed, then hold reconciliation's history
      // write on the wire.
      final stopGate = recorder.gate!;
      recorder.gate = Completer<void>();
      stopGate.complete();
      await pumpEventQueue();
      expect(recorder.paths, contains('/sync/history'), reason: 'the reconcile write is in flight');

      // Disconnect while the reconcile write is on the wire, then fail it.
      simkl.rebindSession(null, onSessionInvalidated: () {});
      recorder.status = 500;
      recorder.gate!.complete();
      recorder.gate = null;
      await stopping;
      await pumpEventQueue();

      final recovered = _Recorder();
      simkl.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recovered.client);
      await coordinator.flushWriteQueue();

      expect(recovered.paths, isEmpty, reason: "account A's late failure must not replay through B");
    });
  });
}
