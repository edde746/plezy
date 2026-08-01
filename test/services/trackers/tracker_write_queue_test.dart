import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/trackers/tracker_context.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_write_queue.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/prefs.dart';

const _watchedAt = '2026-05-12T00:00:00.000Z';

TrackerContext _episode({
  String ratingKey = 'episode-1',
  String? libraryGlobalKey = 'server-1:7',
  ExternalIds external = const ExternalIds(tvdb: 123),
  int season = 1,
  int episodeNumber = 2,
}) => TrackerContext.episode(
  external: external,
  anime: null,
  ratingKey: ratingKey,
  libraryGlobalKey: libraryGlobalKey,
  season: season,
  episodeNumber: episodeNumber,
);

TrackerContext _movie({
  String ratingKey = 'movie-1',
  String? libraryGlobalKey = 'server-1:8',
  ExternalIds external = const ExternalIds(tmdb: 456),
}) => TrackerContext.movie(external: external, anime: null, ratingKey: ratingKey, libraryGlobalKey: libraryGlobalKey);

TrackerWriteQueueItem _item({
  required TrackerContext ctx,
  required String coalesceKey,
  TrackerService service = TrackerService.trakt,
  bool watched = true,
  int? progressClaim,
  String watchedAtIso = _watchedAt,
  int attempts = 0,
}) => TrackerWriteQueueItem(
  service: service,
  watched: watched,
  ctx: ctx,
  coalesceKey: coalesceKey,
  progressClaim: progressClaim,
  watchedAtIso: watchedAtIso,
  attempts: attempts,
);

void main() {
  setUp(resetSharedPreferencesForTest);

  test('done flush sends and removes the queued write', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(ctx.external))!;
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key));

    final sent = <TrackerWriteQueueItem>[];
    await queue.flush(
      'user-a',
      send: (item) async {
        sent.add(item);
        return TrackerWriteDisposition.done;
      },
    );

    expect(sent, hasLength(1));
    expect(sent.single.ctx.ratingKey, 'episode-1');
    expect(sent.single.watched, isTrue);
    expect(await queue.load('user-a'), isEmpty);
  });

  test('failed flush increments attempts and a later flush drops an exhausted write without sending', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(ctx.external))!;
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key, attempts: TrackerWriteQueue.maxAttempts - 1));

    var sendCalls = 0;
    await queue.flush(
      'user-a',
      send: (item) async {
        sendCalls++;
        return TrackerWriteDisposition.failed;
      },
    );
    final exhausted = await queue.load('user-a');
    expect(sendCalls, 1);
    expect(exhausted.single.attempts, TrackerWriteQueue.maxAttempts);

    await queue.flush(
      'user-a',
      send: (item) async {
        sendCalls++;
        return TrackerWriteDisposition.done;
      },
    );
    expect(sendCalls, 1);
    expect(await queue.load('user-a'), isEmpty);
  });

  test('skipped flush keeps the write without burning an attempt', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(ctx.external))!;
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key, attempts: 2));

    await queue.flush('user-a', send: (item) async => TrackerWriteDisposition.skipped);

    final remaining = await queue.load('user-a');
    expect(remaining, hasLength(1));
    expect(remaining.single.attempts, 2);
  });

  test('newer per-item history intent replaces the older intent for its coalesce key', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(ctx.external))!;
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key));
    await queue.enqueue(
      'user-a',
      _item(ctx: ctx, coalesceKey: key, watched: false, watchedAtIso: '2026-05-13T00:00:00.000Z'),
    );

    final remaining = await queue.load('user-a');
    expect(remaining, hasLength(1));
    expect(remaining.single.watched, isFalse);
    expect(remaining.single.watchedAtIso, '2026-05-13T00:00:00.000Z');
  });

  test('series progress coalescing retains the greatest monotonic claim', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerSeriesCoalesceKey(TrackerService.mal, 42);
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key, service: TrackerService.mal, progressClaim: 5));
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key, service: TrackerService.mal, progressClaim: 6));
    expect((await queue.load('user-a')).single.progressClaim, 6);

    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key, service: TrackerService.mal, progressClaim: 5));
    final remaining = await queue.load('user-a');
    expect(remaining, hasLength(1));
    expect(remaining.single.progressClaim, 6);
  });

  test('invalidate drops outright or only claims covered by applied progress', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerSeriesCoalesceKey(TrackerService.anilist, 42);
    TrackerWriteQueueItem claim(int progress) =>
        _item(ctx: ctx, coalesceKey: key, service: TrackerService.anilist, progressClaim: progress);

    await queue.enqueue('user-a', claim(5));
    await queue.invalidate('user-a', key);
    expect(await queue.load('user-a'), isEmpty);

    await queue.enqueue('user-a', claim(5));
    await queue.invalidate('user-a', key, appliedProgress: 6);
    expect(await queue.load('user-a'), isEmpty);

    await queue.enqueue('user-a', claim(7));
    await queue.invalidate('user-a', key, appliedProgress: 6);
    final remaining = await queue.load('user-a');
    expect(remaining, hasLength(1));
    expect(remaining.single.progressClaim, 7);
  });

  test('external identity and media coordinates prevent server-local rating-key collisions', () async {
    final queue = TrackerWriteQueue();
    final first = _episode(ratingKey: 'shared-rating-key', external: const ExternalIds(tvdb: 100));
    final second = _episode(ratingKey: 'shared-rating-key', external: const ExternalIds(tvdb: 200));
    final sameRemoteEpisode = _episode(ratingKey: 'different-local-key', external: const ExternalIds(tvdb: 100));
    final movie = _movie(ratingKey: 'shared-rating-key', external: const ExternalIds(tvdb: 100));

    final firstKey = trackerItemCoalesceKey(TrackerService.trakt, first, trackerExternalRowIdentity(first.external))!;
    final secondKey = trackerItemCoalesceKey(
      TrackerService.trakt,
      second,
      trackerExternalRowIdentity(second.external),
    )!;
    expect(firstKey, isNot(secondKey));
    expect(
      trackerItemCoalesceKey(
        TrackerService.trakt,
        sameRemoteEpisode,
        trackerExternalRowIdentity(sameRemoteEpisode.external),
      ),
      firstKey,
    );
    expect(
      trackerItemCoalesceKey(TrackerService.trakt, movie, trackerExternalRowIdentity(movie.external)),
      isNot(firstKey),
    );

    await queue.enqueue('user-a', _item(ctx: first, coalesceKey: firstKey));
    await queue.enqueue('user-a', _item(ctx: second, coalesceKey: secondKey));
    expect(await queue.load('user-a'), hasLength(2));
  });

  test('profile queues are isolated and flushing one never sends another profile writes', () async {
    final queue = TrackerWriteQueue();
    final first = _episode(ratingKey: 'first', external: const ExternalIds(tvdb: 100));
    final second = _episode(ratingKey: 'second', external: const ExternalIds(tvdb: 200));
    await queue.enqueue(
      'user-a',
      _item(
        ctx: first,
        coalesceKey: trackerItemCoalesceKey(TrackerService.trakt, first, trackerExternalRowIdentity(first.external))!,
      ),
    );
    await queue.enqueue(
      'user-b',
      _item(
        ctx: second,
        coalesceKey: trackerItemCoalesceKey(TrackerService.trakt, second, trackerExternalRowIdentity(second.external))!,
      ),
    );

    expect(await queue.load('user-a'), hasLength(1));
    expect(await queue.load('user-b'), hasLength(1));
    final sent = <String>[];
    await queue.flush(
      'user-a',
      send: (item) async {
        sent.add(item.ctx.ratingKey);
        return TrackerWriteDisposition.done;
      },
    );

    expect(sent, ['first']);
    expect(await queue.load('user-a'), isEmpty);
    expect((await queue.load('user-b')).single.ctx.ratingKey, 'second');
  });

  test('legacy Trakt rows migrate once with their intent and episode metadata intact', () async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    const user = 'legacy-user';
    final legacyKey = profileScopedPrefsKey(user, 'trakt_sync_queue');
    await prefs.setString(
      legacyKey,
      json.encode([
        {
          'op': 'add',
          'ratingKey': 'legacy-episode',
          'serverId': 'server-1',
          'libraryGlobalKey': 'server-1:7',
          'kind': 'episode',
          'ids': {'tvdb': 123, 'tmdb': 456, 'imdb': 'tt789'},
          'season': 3,
          'number': 4,
          'watchedAtIso': '2026-05-12T00:00:00.000Z',
          'attempts': 2,
        },
        {
          'op': 'remove',
          'ratingKey': 'legacy-movie',
          'serverId': 'server-2',
          'libraryGlobalKey': 'server-2:8',
          'kind': 'movie',
          'ids': {'tmdb': 999},
          'watchedAtIso': '2026-05-13T00:00:00.000Z',
          'attempts': 0,
        },
      ]),
    );

    final queue = TrackerWriteQueue();
    final sent = <TrackerWriteQueueItem>[];
    await queue.flush(
      user,
      send: (item) async {
        sent.add(item);
        return TrackerWriteDisposition.done;
      },
    );

    expect(sent, hasLength(2));
    expect(sent.map((item) => item.service), everyElement(TrackerService.trakt));
    expect(sent[0].watched, isTrue);
    expect(sent[0].ctx.season, 3);
    expect(sent[0].ctx.episodeNumber, 4);
    expect(sent[0].watchedAtIso, '2026-05-12T00:00:00.000Z');
    expect(sent[0].attempts, 2);
    expect(sent[1].watched, isFalse);
    expect(sent[1].ctx.isMovie, isTrue);
    expect(sent[1].watchedAtIso, '2026-05-13T00:00:00.000Z');
    expect(prefs.getString(legacyKey), isNull);
    expect(await queue.load(user), isEmpty);

    const malformedUser = 'malformed-legacy-user';
    final malformedKey = profileScopedPrefsKey(malformedUser, 'trakt_sync_queue');
    await prefs.setString(malformedKey, '{not valid json');
    expect(await queue.load(malformedUser), isEmpty);
    expect(prefs.getString(malformedKey), isNull);
    expect(await queue.load(malformedUser), isEmpty);
  });

  test('a legacy queue left behind by an interrupted migration does not duplicate rows', () async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    const user = 'interrupted-user';
    final legacyRow = {
      'op': 'add',
      'ratingKey': 'legacy-episode',
      'serverId': 'server-1',
      'libraryGlobalKey': 'server-1:7',
      'kind': 'episode',
      'ids': {'tvdb': 123},
      'season': 3,
      'number': 4,
      'watchedAtIso': '2026-05-12T00:00:00.000Z',
      'attempts': 0,
    };
    await prefs.setString(profileScopedPrefsKey(user, 'trakt_sync_queue'), json.encode([legacyRow]));

    // First pass converts the row. A fresh queue instance then finds the legacy
    // key again, as it would after a crash between the write and the removal.
    expect(await TrackerWriteQueue().load(user), hasLength(1));
    await prefs.setString(profileScopedPrefsKey(user, 'trakt_sync_queue'), json.encode([legacyRow]));

    final migrated = await TrackerWriteQueue().load(user);

    expect(migrated, hasLength(1), reason: 'the row is replaced, not appended a second time');
    expect(migrated.single.ctx.episodeNumber, 4);
  });

  test('corrupt tracker queue payload is archived and discarded without throwing', () async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    const user = 'corrupt-user';
    const corruptPayload = '{not valid json';
    final queueKey = profileScopedPrefsKey(user, 'tracker_write_queue');
    final archiveKey = profileScopedPrefsKey(user, 'tracker_write_queue_corrupt');
    await prefs.setString(queueKey, corruptPayload);

    final queue = TrackerWriteQueue();
    expect(await queue.load(user), isEmpty);
    expect(prefs.getString(queueKey), isNull);
    expect(prefs.getString(archiveKey), corruptPayload);
  });
}
