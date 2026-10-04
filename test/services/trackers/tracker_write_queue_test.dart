import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/trackers/tracker_context.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_write_queue.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

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

/// Drains one row per send, as for services that do not batch.
Future<void> _flushEach(
  TrackerWriteQueue queue,
  String userUuid,
  Future<TrackerWriteDisposition> Function(TrackerWriteQueueItem item) send,
) => queue.flush(userUuid, batches: (_) => false, send: (rows) async => [await send(rows.single)]);

String _historyKey(TrackerService service, TrackerContext ctx) =>
    trackerItemCoalesceKey(service, ctx, trackerExternalRowIdentity(ctx.external))!;

void main() {
  setUp(resetSharedPreferencesForTest);

  test('done flush sends and removes the queued write', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(ctx.external))!;
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key));

    final sent = <TrackerWriteQueueItem>[];
    await _flushEach(queue, 'user-a', (item) async {
      sent.add(item);
      return TrackerWriteDisposition.done;
    });

    expect(sent, hasLength(1));
    expect(sent.single.ctx.ratingKey, 'episode-1');
    expect(sent.single.watched, isTrue);
    expect(await queue.load('user-a'), isEmpty);
  });

  test('a drain spaces Trakt writes by its one-write-per-second limit', () async {
    final pauses = <Duration>[];
    final queue = TrackerWriteQueue(pause: (duration) async => pauses.add(duration));
    for (final (number, service) in [(1, TrackerService.trakt), (2, TrackerService.trakt), (3, TrackerService.simkl)]) {
      final ctx = _episode(ratingKey: 'episode-$number', episodeNumber: number);
      final key = trackerItemCoalesceKey(service, ctx, trackerExternalRowIdentity(ctx.external))!;
      await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key, service: service));
    }

    await _flushEach(queue, 'user-a', (item) async => TrackerWriteDisposition.done);

    expect(pauses, [const Duration(seconds: 1), const Duration(seconds: 1), const Duration(milliseconds: 50)]);
  });

  test('failed flush increments attempts and a later flush drops an exhausted write without sending', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(ctx.external))!;
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key, attempts: TrackerWriteQueue.maxAttempts - 1));

    var sendCalls = 0;
    await _flushEach(queue, 'user-a', (item) async {
      sendCalls++;
      return TrackerWriteDisposition.failed;
    });
    final exhausted = await queue.load('user-a');
    expect(sendCalls, 1);
    expect(exhausted.single.attempts, TrackerWriteQueue.maxAttempts);

    await _flushEach(queue, 'user-a', (item) async {
      sendCalls++;
      return TrackerWriteDisposition.done;
    });
    expect(sendCalls, 1);
    expect(await queue.load('user-a'), isEmpty);
  });

  test('skipped flush keeps the write without burning an attempt', () async {
    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(ctx.external))!;
    await queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key, attempts: 2));

    await _flushEach(queue, 'user-a', (item) async => TrackerWriteDisposition.skipped);

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
    await queue.invalidate('user-a', {key: null});
    expect(await queue.load('user-a'), isEmpty);

    await queue.enqueue('user-a', claim(5));
    await queue.invalidate('user-a', {key: 6});
    expect(await queue.load('user-a'), isEmpty);

    await queue.enqueue('user-a', claim(7));
    await queue.invalidate('user-a', {key: 6});
    final remaining = await queue.load('user-a');
    expect(remaining, hasLength(1));
    expect(remaining.single.progressClaim, 7);
  });

  group('batched drain', () {
    test('groups history rows by service and direction, capped per request, and sends other rows alone', () async {
      final pauses = <Duration>[];
      final queue = TrackerWriteQueue(pause: (duration) async => pauses.add(duration));
      TrackerWriteQueueItem added(int number) => _item(
        ctx: _episode(ratingKey: 'simkl-$number', episodeNumber: number),
        coalesceKey: _historyKey(TrackerService.simkl, _episode(episodeNumber: number)),
        service: TrackerService.simkl,
      );
      const half = TrackerConstants.historyBatchSize ~/ 2;
      final rows = <TrackerWriteQueueItem>[
        for (var number = 1; number <= half; number++) added(number),
        _item(
          ctx: _episode(ratingKey: 'simkl-removed', episodeNumber: 500),
          coalesceKey: _historyKey(TrackerService.simkl, _episode(episodeNumber: 500)),
          service: TrackerService.simkl,
          watched: false,
        ),
        for (var number = half + 1; number <= TrackerConstants.historyBatchSize + 1; number++) added(number),
        for (final entry in [42, 43])
          _item(
            ctx: _episode(ratingKey: 'mal-$entry'),
            coalesceKey: trackerSeriesCoalesceKey(TrackerService.mal, entry),
            service: TrackerService.mal,
            progressClaim: 5,
          ),
      ];
      await queue.enqueueAll('user-a', rows);

      final units = <List<String>>[];
      await queue.flush(
        'user-a',
        batches: (service) => service == TrackerService.simkl,
        send: (unit) async {
          units.add([for (final row in unit) row.ctx.ratingKey]);
          return List.filled(unit.length, TrackerWriteDisposition.done);
        },
      );

      expect(units, [
        [for (var number = 1; number <= TrackerConstants.historyBatchSize; number++) 'simkl-$number'],
        ['simkl-removed'],
        ['simkl-${TrackerConstants.historyBatchSize + 1}'],
        ['mal-42'],
        ['mal-43'],
      ], reason: 'additions batch around a removal, overflow starts a new request, other services go alone');
      expect(pauses, hasLength(units.length), reason: 'every request is followed by the service spacing');
      expect(await queue.load('user-a'), isEmpty);
    });

    test('applies each row its own disposition and keeps the survivors in queue order', () async {
      final queue = TrackerWriteQueue(pause: (_) async {});
      final rows = [
        for (var number = 1; number <= 3; number++)
          _item(
            ctx: _episode(ratingKey: 'episode-$number', episodeNumber: number),
            coalesceKey: _historyKey(TrackerService.trakt, _episode(episodeNumber: number)),
            attempts: 1,
          ),
      ];
      await queue.enqueueAll('user-a', rows);

      await queue.flush(
        'user-a',
        batches: (_) => true,
        send: (unit) async => const [
          TrackerWriteDisposition.skipped,
          TrackerWriteDisposition.done,
          TrackerWriteDisposition.failed,
        ],
      );

      final remaining = await queue.load('user-a');
      expect(remaining.map((row) => row.ctx.ratingKey), ['episode-1', 'episode-3']);
      expect(remaining.map((row) => row.attempts), [1, 2], reason: 'only the failed row spends an attempt');
    });

    test('a deferred batch leaves the rest of that service for a later drain', () async {
      final queue = TrackerWriteQueue(pause: (_) async {});
      await queue.enqueueAll('user-a', [
        for (var number = 1; number <= TrackerConstants.historyBatchSize + 1; number++)
          _item(
            ctx: _episode(ratingKey: 'episode-$number', episodeNumber: number),
            coalesceKey: _historyKey(TrackerService.simkl, _episode(episodeNumber: number)),
            service: TrackerService.simkl,
          ),
      ]);

      var requests = 0;
      await queue.flush(
        'user-a',
        batches: (_) => true,
        send: (unit) async {
          requests++;
          return List.filled(unit.length, TrackerWriteDisposition.deferredService);
        },
      );

      expect(requests, 1, reason: 'a service that asked for quiet gets no second request in the same drain');
      final remaining = await queue.load('user-a');
      expect(remaining, hasLength(TrackerConstants.historyBatchSize + 1));
      expect(remaining.map((row) => row.attempts), everyElement(0));
    });
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
    await _flushEach(queue, 'user-a', (item) async {
      sent.add(item.ctx.ratingKey);
      return TrackerWriteDisposition.done;
    });

    expect(sent, ['first']);
    expect(await queue.load('user-a'), isEmpty);
    expect((await queue.load('user-b')).single.ctx.ratingKey, 'second');
  });

  test('disconnect purge drops one service rows so nothing replays, leaving other services queued', () async {
    final queue = TrackerWriteQueue();
    final traktCtx = _episode(ratingKey: 'trakt-episode', external: const ExternalIds(tvdb: 100));
    final traktKey = trackerItemCoalesceKey(
      TrackerService.trakt,
      traktCtx,
      trackerExternalRowIdentity(traktCtx.external),
    )!;
    final malCtx = _episode(ratingKey: 'mal-episode', external: const ExternalIds(tvdb: 200));
    await queue.enqueue('user-a', _item(ctx: traktCtx, coalesceKey: traktKey));
    await queue.enqueue(
      'user-a',
      _item(
        ctx: malCtx,
        coalesceKey: trackerSeriesCoalesceKey(TrackerService.mal, 42),
        service: TrackerService.mal,
        progressClaim: 5,
      ),
    );

    await queue.removeService('user-a', TrackerService.trakt);

    final survivors = await queue.load('user-a');
    expect(survivors.map((item) => item.service), [TrackerService.mal], reason: 'other services keep their rows');

    final sent = <TrackerWriteQueueItem>[];
    await _flushEach(queue, 'user-a', (item) async {
      sent.add(item);
      return TrackerWriteDisposition.done;
    });

    expect(sent.map((item) => item.service), [TrackerService.mal], reason: 'the purged service must not dispatch');
  });

  test('a persist-failure enqueue racing the disconnect purge cannot resurrect the row', () async {
    final platform = _FailingQueuePreferences();
    SharedPreferencesAsyncPlatform.instance = platform;
    BaseSharedPreferencesService.resetForTesting();

    final queue = TrackerWriteQueue();
    final ctx = _episode();
    final key = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(ctx.external))!;

    // The enqueue claims its lock slot synchronously, then its persist fails
    // and the row can only be buffered in memory. The purge claims the next
    // slot in the same synchronous segment — the interleaving of a write
    // failing while the user disconnects the service.
    platform.failQueueWrites = true;
    final enqueue = queue.enqueue('user-a', _item(ctx: ctx, coalesceKey: key));
    final purge = queue.removeService('user-a', TrackerService.trakt);
    await enqueue;
    await purge;
    platform.failQueueWrites = false;

    final sent = <TrackerWriteQueueItem>[];
    await _flushEach(queue, 'user-a', (item) async {
      sent.add(item);
      return TrackerWriteDisposition.done;
    });

    expect(sent, isEmpty, reason: 'the buffered row was created under the disconnected account');
    expect(await queue.load('user-a'), isEmpty);
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
    await _flushEach(queue, user, (item) async {
      sent.add(item);
      return TrackerWriteDisposition.done;
    });

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

/// Fails writes to the tracker queue key while armed, simulating the disk
/// full/revoked-storage case that feeds the in-memory fallback.
/// `SharedPreferencesWithCache` sits above the platform and is not
/// subclassable, so the failure is injected here.
final class _FailingQueuePreferences extends InMemorySharedPreferencesAsync {
  _FailingQueuePreferences() : super.empty();

  bool failQueueWrites = false;

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    if (failQueueWrites && key.contains('tracker_write_queue')) {
      throw StateError('simulated persist failure');
    }
    return super.setString(key, value, options);
  }
}
