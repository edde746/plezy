import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../../models/trackers/tracker_context.dart';
import '../../profiles/profile.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import '../../utils/serial_future_queue.dart';
import '../base_shared_preferences_service.dart';
import 'tracker_constants.dart';

/// One watched/unwatched write that failed and is waiting for a retry.
///
/// The full [TrackerContext] is stored, so a replay writes exactly the item the
/// original attempt was built for — no second metadata fetch, no re-resolution
/// against a library whose mapping may have moved on.
class TrackerWriteQueueItem {
  final TrackerService service;

  /// True for a watched write, false for its removal.
  final bool watched;

  final TrackerContext ctx;

  /// Identity this write coalesces on — the remote thing it changes. Two items
  /// sharing a key are two statements about one remote value, and only the
  /// surviving intent is kept (see [TrackerWriteQueue]).
  final String coalesceKey;

  /// For a tracker that stores absolute progress: the value this write claims.
  /// Null for per-item history writes and for removals, which are not claims.
  final int? progressClaim;

  /// When the watch actually happened, so a replay days later is still filed
  /// under the right date on services that accept a timestamp.
  final String watchedAtIso;

  final int attempts;

  const TrackerWriteQueueItem({
    required this.service,
    required this.watched,
    required this.ctx,
    required this.coalesceKey,
    required this.watchedAtIso,
    this.progressClaim,
    this.attempts = 0,
  });

  DateTime? get watchedAt => DateTime.tryParse(watchedAtIso);

  TrackerWriteQueueItem incrementAttempts() => TrackerWriteQueueItem(
    service: service,
    watched: watched,
    ctx: ctx,
    coalesceKey: coalesceKey,
    progressClaim: progressClaim,
    watchedAtIso: watchedAtIso,
    attempts: attempts + 1,
  );

  Map<String, dynamic> toJson() => {
    'service': service.name,
    'watched': watched,
    'ctx': ctx.toJson(),
    'coalesceKey': coalesceKey,
    if (progressClaim != null) 'progressClaim': progressClaim,
    'watchedAtIso': watchedAtIso,
    'attempts': attempts,
  };

  factory TrackerWriteQueueItem.fromJson(Map<String, dynamic> json) => TrackerWriteQueueItem(
    service: TrackerService.values.firstWhere(
      (s) => s.name == json['service'],
      orElse: () => throw ArgumentError('Unknown TrackerService: ${json['service']}'),
    ),
    watched: json['watched'] as bool,
    ctx: TrackerContext.fromJson((json['ctx'] as Map).cast<String, Object?>()),
    coalesceKey: json['coalesceKey'] as String,
    progressClaim: (json['progressClaim'] as num?)?.toInt(),
    watchedAtIso: json['watchedAtIso'] as String,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
  );
}

/// What the drain should do with an item after the sender looked at it.
enum TrackerWriteDisposition {
  /// Written, or no longer applicable (library filtered out) — drop it.
  done,

  /// The write was attempted and failed; keep it and count the attempt.
  failed,

  /// Attempted, and the service is not taking writes right now — it rate-limited
  /// us, failed on its own side, or could not be reached. The item is kept
  /// untouched and every remaining row for that service is left for a later
  /// drain, so one back-off answer cannot turn a full queue into a burst of
  /// requests at a service already asking for quiet.
  deferredService,

  /// Not attempted at all — the service has no session, or the active profile
  /// moved while the drain was running. Kept untouched so nothing burns an item's
  /// retries and no row is written through the wrong account.
  skipped,
}

/// Per-profile persisted retry queue for failed tracker watched writes, shared
/// by every service.
///
/// Ordering here is intent-based, not temporal, because a tracker write is not
/// an increment:
///
/// * A per-item history write (Simkl, Trakt) states "this item is watched" or
///   "is not". The newest statement about an item replaces any queued one, so a
///   failed watched write can never replay on top of a later successful
///   un-watch.
/// * A series-progress write (MAL, AniList) claims "this entry is at least at
///   progress N". Claims are monotonic: two queued claims for one entry coalesce
///   to the higher, and [invalidate] drops any claim a completed write already
///   covers. Without that a queued episode 5 could land after episode 6
///   succeeded and walk the list backwards.
///
/// Items carry their own [TrackerWriteQueueItem.service], so one disconnected
/// tracker never blocks another's replay, and are dropped after [maxAttempts]
/// tries — matching `OfflineWatchSyncService.maxSyncAttempts`.
///
/// All state changes run through one [SerialFutureQueue], so concurrent
/// enqueues never interleave read-modify-write and lose items.
class TrackerWriteQueue {
  static const String _baseKey = 'tracker_write_queue';

  /// Pre-consolidation key holding Trakt-only items. Converted once per profile
  /// so pushes queued by an older build are not silently dropped.
  static const String _legacyTraktKey = 'trakt_sync_queue';

  static const int maxAttempts = 5;

  /// Inter-request delay during a drain, to stay under Trakt's
  /// 1000 requests / 5 minutes budget.
  static const Duration _requestSpacing = Duration(milliseconds: 50);

  /// Bound for items whose disk write threw (disk full, revoked SAF
  /// permission). Keyed by profile so a profile switch cannot replay one user's
  /// failed writes through another user's account; oldest drop first.
  static const int _maxInMemoryFallback = 100;

  final Map<String, Queue<TrackerWriteQueueItem>> _inMemoryFallbackByUser = {};
  final Set<String> _migratedUsers = {};

  /// Coalesce keys known to be queued per profile, so the common "nothing
  /// pending for this item" case costs a set lookup instead of a disk read. A
  /// profile with no entry here has not been loaded yet and is never assumed
  /// empty.
  final Map<String, Set<String>> _pendingKeysByUser = {};

  /// Rows a direct write has landed on whose queued rows are not cleaned up yet,
  /// keyed by coalesce key. A marker lives only for the interval between a
  /// successful direct write and its [invalidate] finishing — precisely the
  /// window in which a drain can already be holding a row that write covers.
  final Map<String, _AppliedWrite> _appliedByKey = {};
  int _appliedToken = 0;

  final SerialFutureQueue _writeQueue = SerialFutureQueue();
  Future<void>? _flushFuture;
  String? _flushUserUuid;
  bool _flushRequested = false;

  Future<T> _locked<T>(Future<T> Function() action) => _writeQueue.run(action);

  Future<List<TrackerWriteQueueItem>> load(String userUuid) async {
    await _migrateLegacyTraktQueue(userUuid);
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final key = profileScopedPrefsKey(userUuid, _baseKey);
    final raw = prefs.getString(key);
    if (raw == null) {
      _trackPending(userUuid, const []);
      return [];
    }
    try {
      final list = json.decode(raw) as List<dynamic>;
      final items = list.map((e) => TrackerWriteQueueItem.fromJson(e as Map<String, dynamic>)).toList();
      _trackPending(userUuid, items);
      return items;
    } catch (e, st) {
      appLogger.e('Tracker write queue parse failed, discarding', error: e, stackTrace: st);
      await prefs.setString(profileScopedPrefsKey(userUuid, '${_baseKey}_corrupt'), raw);
      await prefs.remove(key);
      _trackPending(userUuid, const []);
      return [];
    }
  }

  void _trackPending(String userUuid, List<TrackerWriteQueueItem> items) {
    _pendingKeysByUser[userUuid] = {for (final item in items) item.coalesceKey};
  }

  Future<void> _save(String userUuid, List<TrackerWriteQueueItem> items) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final key = profileScopedPrefsKey(userUuid, _baseKey);
    _trackPending(userUuid, items);
    if (items.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, json.encode(items.map((e) => e.toJson()).toList()));
    }
  }

  /// Persist [item] as the surviving intent for its coalesce key; fall back to a
  /// bounded in-memory buffer when the disk write throws. Buffered items are
  /// retried at the start of the next [flush].
  ///
  /// The fallback add runs inside the queue lock so it is ordered against
  /// [removeService]: a purge whose slot is claimed after this enqueue's is
  /// guaranteed to also sweep a row that could only be buffered, not persisted.
  Future<void> enqueue(String userUuid, TrackerWriteQueueItem item) {
    return _locked(() async {
      try {
        final items = await load(userUuid);
        final claim = item.progressClaim;
        if (claim != null &&
            items.any((queued) => queued.coalesceKey == item.coalesceKey && (queued.progressClaim ?? -1) > claim)) {
          // A higher claim for the same entry is already waiting; this one would
          // only walk it backwards.
          return;
        }
        items.removeWhere((queued) => queued.coalesceKey == item.coalesceKey);
        items.add(item);
        await _save(userUuid, items);
      } catch (e, st) {
        appLogger.e(
          'Tracker write queue: persist failed for ${item.service.name} ${item.ctx.ratingKey}, buffering in memory',
          error: e,
          stackTrace: st,
        );
        final fallback = _inMemoryFallbackByUser.putIfAbsent(userUuid, Queue<TrackerWriteQueueItem>.new);
        if (fallback.length >= _maxInMemoryFallback) {
          final dropped = fallback.removeFirst();
          appLogger.w('Tracker write queue: in-memory buffer full, dropping ${dropped.service.name}');
        }
        fallback.addLast(item);
      }
    });
  }

  /// Drop queued writes a completed direct write has superseded.
  ///
  /// [appliedProgress] null means the write superseded the key outright (a
  /// history add/remove, or a removed series entry). Otherwise only claims at or
  /// below the applied progress are covered; a queued higher claim is still a
  /// pending advance and survives.
  Future<void> invalidate(String userUuid, String coalesceKey, {int? appliedProgress}) async {
    // A profile whose queue has never been loaded is not assumed empty.
    if (_pendingKeysByUser[userUuid]?.contains(coalesceKey) == false) return;
    await _locked(() async {
      final items = await load(userUuid);
      final before = items.length;
      items.removeWhere(
        (queued) => queued.coalesceKey == coalesceKey && covers(appliedProgress: appliedProgress, item: queued),
      );
      if (items.length == before) return;
      appLogger.d('Tracker write queue: dropped superseded $coalesceKey');
      await _save(userUuid, items);
    });
  }

  /// Drop every queued row for [service] under [userUuid] — persisted and
  /// in-memory fallback alike.
  ///
  /// Called on explicit disconnect and on session invalidation: items carry no
  /// tracker-account identity, so a row queued under the departing account
  /// would otherwise replay through whichever account connects to this service
  /// next. The fallback sweep runs inside the lock so it is ordered after any
  /// racing [enqueue] whose failed persist buffered its row.
  Future<void> removeService(String userUuid, TrackerService service) async {
    await _locked(() async {
      _inMemoryFallbackByUser[userUuid]?.removeWhere((item) => item.service == service);
      final items = await load(userUuid);
      final before = items.length;
      items.removeWhere((item) => item.service == service);
      if (items.length == before) return;
      appLogger.i('Tracker write queue: dropped ${before - items.length} ${service.name} rows on disconnect');
      await _save(userUuid, items);
    });
  }

  /// Whether a completed write that applied [appliedProgress] covers [item].
  static bool covers({required int? appliedProgress, required TrackerWriteQueueItem item}) =>
      coversClaim(appliedProgress: appliedProgress, claim: item.progressClaim);

  /// Whether a completed write that applied [appliedProgress] covers a write
  /// claiming [claim].
  ///
  /// A null [appliedProgress] is not a progress claim — a history add/remove or
  /// an entry removal — and covers the row outright. A null [claim] is likewise
  /// not monotonic, so anything completing after it covers it.
  static bool coversClaim({required int? appliedProgress, required int? claim}) {
    if (appliedProgress == null) return true;
    return claim == null || claim <= appliedProgress;
  }

  /// Record a direct write that just landed for [userUuid], returning a token
  /// that identifies this marker.
  ///
  /// [invalidate] alone cannot close the race it guards: a drain that has already
  /// read a row calls its sender regardless, and the newer write's invalidation
  /// may still be waiting for the queue lock the drain holds. The marker makes
  /// that row visibly covered for exactly the interval between the write landing
  /// and its invalidation finishing — [clearDirectWrite] ends it.
  int noteDirectWrite(String userUuid, String coalesceKey, {int? appliedProgress}) {
    final token = ++_appliedToken;
    _appliedByKey[_markerKey(userUuid, coalesceKey)] = _AppliedWrite(token, appliedProgress);
    return token;
  }

  /// Drop the marker [token] created for [coalesceKey]. A newer overlapping
  /// write's marker holds a different token and survives.
  void clearDirectWrite(String userUuid, String coalesceKey, int token) {
    final key = _markerKey(userUuid, coalesceKey);
    if (_appliedByKey[key]?.token == token) _appliedByKey.remove(key);
  }

  /// True when a direct write for this profile already covers [item], so
  /// replaying it would undo newer state.
  ///
  /// Scoped per profile: the same film watched under two profiles is two
  /// independent remote rows, and one profile's pending write must never make the
  /// other's queued row look redundant.
  bool isSuperseded(String userUuid, TrackerWriteQueueItem item) {
    final applied = _appliedByKey[_markerKey(userUuid, item.coalesceKey)];
    return applied != null && covers(appliedProgress: applied.progress, item: item);
  }

  static String _markerKey(String userUuid, String coalesceKey) => '$userUuid|$coalesceKey';

  /// Drain [userUuid]'s queue through [send].
  ///
  /// Concurrent calls for the same profile coalesce: a flush requested while one
  /// runs re-runs the loop once instead of interleaving two drains over the same
  /// items. A call for a different profile waits its turn instead, so two
  /// profiles' drains never merge.
  Future<void> flush(String userUuid, {required Future<TrackerWriteDisposition> Function(TrackerWriteQueueItem) send}) {
    final active = _flushFuture;
    if (active != null) {
      if (_flushUserUuid == userUuid) {
        _flushRequested = true;
        return active;
      }
      return active.then((_) => flush(userUuid, send: send));
    }
    final future = _runFlushLoop(userUuid, send);
    _flushFuture = future;
    _flushUserUuid = userUuid;
    return future;
  }

  Future<void> _runFlushLoop(
    String userUuid,
    Future<TrackerWriteDisposition> Function(TrackerWriteQueueItem) send,
  ) async {
    // Spans every pass of this loop, not just one: a flush requested while the
    // first pass ran re-enters immediately, and a service that just asked us to
    // back off must not be asked again in that same burst.
    final deferredServices = <TrackerService>{};
    try {
      do {
        _flushRequested = false;
        await _flushOnce(userUuid, send, deferredServices);
      } while (_flushRequested);
    } finally {
      _flushFuture = null;
      _flushUserUuid = null;
      if (_flushRequested) {
        scheduleMicrotask(() {
          unawaited(
            flush(userUuid, send: send).catchError((Object e, StackTrace st) {
              appLogger.w('Tracker write queue: follow-up flush failed', error: e, stackTrace: st);
            }),
          );
        });
      }
    }
  }

  /// Holds the write lock for the whole cycle so concurrent enqueues wait until
  /// the drain has saved its remainder (no lost items). Items are attempted in
  /// insertion order, which is the order the surviving intents were expressed.
  ///
  /// Once a service answers [TrackerWriteDisposition.deferredService], the rest of
  /// its rows are left untouched without a request. A queue holding many rows for
  /// one service would otherwise fire all of them at a service that has just told
  /// us to back off, deepening a rate limit. Other services keep draining.
  ///
  /// [deferredServices] is owned by the caller so the deferral spans a coalesced
  /// flush burst, not one pass. That is enough because drains are driven by
  /// user-scale events — profile bind, connect, foreground, network restore — not
  /// a timer; a timer-driven flush would need the advertised retry-after window
  /// persisted instead.
  Future<void> _flushOnce(
    String userUuid,
    Future<TrackerWriteDisposition> Function(TrackerWriteQueueItem) send,
    Set<TrackerService> deferredServices,
  ) async {
    await _recoverInMemoryFallback(userUuid);
    await _locked(() async {
      final items = await load(userUuid);
      if (items.isEmpty) return;
      final remaining = <TrackerWriteQueueItem>[];
      for (final item in items) {
        if (item.attempts >= maxAttempts) {
          appLogger.w(
            'Tracker write queue: dropping ${item.service.name} ${item.ctx.ratingKey} after ${item.attempts} attempts',
          );
          continue;
        }
        if (deferredServices.contains(item.service)) {
          remaining.add(item);
          continue;
        }
        final disposition = await send(item);
        switch (disposition) {
          case TrackerWriteDisposition.done:
            await Future<void>.delayed(_requestSpacing);
          case TrackerWriteDisposition.failed:
            remaining.add(item.incrementAttempts());
            await Future<void>.delayed(_requestSpacing);
          case TrackerWriteDisposition.deferredService:
            deferredServices.add(item.service);
            remaining.add(item);
          case TrackerWriteDisposition.skipped:
            remaining.add(item);
        }
      }
      await _save(userUuid, remaining);
    });
  }

  /// Move items buffered because a prior disk write failed back onto the
  /// persistent queue. Best-effort: anything that still won't persist stays
  /// buffered for the next flush.
  Future<void> _recoverInMemoryFallback(String userUuid) async {
    final fallback = _inMemoryFallbackByUser[userUuid];
    if (fallback == null || fallback.isEmpty) return;
    final snapshot = List<TrackerWriteQueueItem>.from(fallback);
    fallback.clear();
    _inMemoryFallbackByUser.remove(userUuid);
    for (final item in snapshot) {
      await enqueue(userUuid, item);
    }
  }

  /// Convert the pre-consolidation Trakt-only queue into shared items.
  ///
  /// The converted payload is written before the legacy key is dropped, so a
  /// failed write leaves the pending writes where they are for the next attempt
  /// rather than losing them. That ordering means a re-run is possible, so the
  /// merge replaces rows sharing a converted row's coalesce key instead of
  /// appending duplicates.
  Future<void> _migrateLegacyTraktQueue(String userUuid) async {
    if (_migratedUsers.contains(userUuid)) return;
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final legacyKey = profileScopedPrefsKey(userUuid, _legacyTraktKey);
    final raw = prefs.getString(legacyKey);
    if (raw == null) {
      _migratedUsers.add(userUuid);
      return;
    }

    final List<TrackerWriteQueueItem> converted;
    try {
      converted = [
        for (final entry in json.decode(raw) as List<dynamic>)
          ?_legacyTraktItem((entry as Map).cast<String, dynamic>()),
      ];
    } catch (e, st) {
      // Unreadable: drop it, or every later load would retry the same failure.
      appLogger.e('Tracker write queue: legacy Trakt queue unreadable, discarding', error: e, stackTrace: st);
      await prefs.remove(legacyKey);
      _migratedUsers.add(userUuid);
      return;
    }

    try {
      if (converted.isNotEmpty) {
        // A corrupt payload already under the shared key must not sink the
        // migration: archive it the way [load] would and merge into a clean list.
        final key = profileScopedPrefsKey(userUuid, _baseKey);
        final existingRaw = prefs.getString(key);
        var existing = const <dynamic>[];
        if (existingRaw != null) {
          try {
            existing = json.decode(existingRaw) as List<dynamic>;
          } catch (e, st) {
            appLogger.e(
              'Tracker write queue: unreadable payload during migration, archiving',
              error: e,
              stackTrace: st,
            );
            await prefs.setString(profileScopedPrefsKey(userUuid, '${_baseKey}_corrupt'), existingRaw);
          }
        }
        final convertedKeys = {for (final item in converted) item.coalesceKey};
        final merged = [
          for (final row in existing)
            if (!(row is Map && convertedKeys.contains(row['coalesceKey']))) row,
          ...converted.map((e) => e.toJson()),
        ];
        await prefs.setString(key, json.encode(merged));
      }
      // Only once the converted rows are durable.
      await prefs.remove(legacyKey);
      _migratedUsers.add(userUuid);
      appLogger.i('Tracker write queue: migrated ${converted.length} legacy Trakt writes');
    } catch (e, st) {
      appLogger.e(
        'Tracker write queue: legacy Trakt migration could not be persisted, keeping it for the next attempt',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Null when the row names no remote media — nothing could have been written
  /// for it, so there is nothing to retry.
  static TrackerWriteQueueItem? _legacyTraktItem(Map<String, dynamic> json) {
    final external = ExternalIds.fromJson((json['ids'] as Map).cast<String, Object?>());
    final ratingKey = json['ratingKey'] as String;
    final libraryGlobalKey = json['libraryGlobalKey'] as String?;
    final ctx = json['kind'] == 'movie'
        ? TrackerContext.movie(
            external: external,
            anime: null,
            ratingKey: ratingKey,
            libraryGlobalKey: libraryGlobalKey,
          )
        : TrackerContext.episode(
            external: external,
            anime: null,
            ratingKey: ratingKey,
            libraryGlobalKey: libraryGlobalKey,
            season: (json['season'] as num).toInt(),
            episodeNumber: (json['number'] as num).toInt(),
          );
    // The legacy queue was Trakt-only, and Trakt identifies a row by the media
    // server's external ids.
    final coalesceKey = trackerItemCoalesceKey(TrackerService.trakt, ctx, trackerExternalRowIdentity(external));
    if (coalesceKey == null) return null;
    return TrackerWriteQueueItem(
      service: TrackerService.trakt,
      watched: json['op'] == 'add',
      ctx: ctx,
      coalesceKey: coalesceKey,
      watchedAtIso: json['watchedAtIso'] as String,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Coalesce key for a per-item history write: the remote media row it changes, on
/// that service.
///
/// [rowIdentity] comes from [EpisodeHistoryTracker.historyRowIdentity]; null means
/// the service cannot name a row, so no write could have applied either.
String? trackerItemCoalesceKey(TrackerService service, TrackerContext ctx, String? rowIdentity) {
  if (rowIdentity == null) return null;
  final coordinate = ctx.isMovie ? 'movie' : 's${ctx.season}e${ctx.episodeNumber}';
  return '${service.name}|$coordinate|$rowIdentity';
}

/// The media server's external ids in a fixed preference order, as one stable
/// identifier.
///
/// One id rather than all of them: which ids an item exposes varies by server and
/// by whether an anime mapping has been downloaded, and a key that moved with that
/// would stop matching rows already queued.
String? trackerExternalRowIdentity(ExternalIds ids) {
  if (ids.imdb case final imdb?) return 'imdb=$imdb';
  if (ids.tmdb case final tmdb?) return 'tmdb=$tmdb';
  if (ids.tvdb case final tvdb?) return 'tvdb=$tvdb';
  return null;
}

/// Coalesce key for a series-progress write: the remote list entry on that
/// service, because every episode of one show restates the same counter.
String trackerSeriesCoalesceKey(TrackerService service, Object entryId) => '${service.name}|series|$entryId';

/// A direct write whose queued rows have not been cleaned up yet.
class _AppliedWrite {
  /// Identifies this marker so a newer overlapping write's marker is not cleared
  /// by an older write finishing its invalidation.
  final int token;

  /// Progress the write applied, or null when it was not a progress claim and so
  /// covers the row outright.
  final int? progress;

  const _AppliedWrite(this.token, this.progress);
}
