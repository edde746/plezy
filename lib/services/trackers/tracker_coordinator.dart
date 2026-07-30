import 'dart:async';

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../media/playback_timeline.dart';
import '../../models/trackers/tracker_context.dart';
import '../../utils/app_logger.dart';
import '../../media/episode_collection.dart';
import 'anime_episode_progress_resolver.dart';
import 'anime_lists_mapping_store.dart';
import 'anilist/anilist_tracker.dart';
import 'fribb_mapping_store.dart';
import 'mal/mal_tracker.dart';
import 'simkl/simkl_tracker.dart';
import 'tracker.dart';
import 'tracker_constants.dart';
import 'tracker_id_resolver.dart';

/// A real-time tracker paired with the account binding it was captured against,
/// so a deferred write can tell whether it is still writing to the same account.
typedef _BoundScrobbleTarget = (RealtimeScrobbleTracker, Object?);

/// Fan-out for non-Trakt trackers (MAL, AniList, Simkl).
///
/// Two mechanisms, one per tracker kind:
///
/// * Threshold trackers (MAL, AniList) are notified exactly once when progress
///   crosses the watched threshold, with a safety-net fire on stop if the
///   crossing was missed (e.g. user stopped between ticks).
/// * [RealtimeScrobbleTracker]s (Simkl) instead receive the playback lifecycle
///   — start/resume, pause, stop — with the current progress, and decide
///   watched state themselves. They are excluded from the threshold fan-out so
///   a single watch never produces two writes.
///
/// Manual, container, offline-replay and external-player marks bypass all of
/// this and go straight to [Tracker.markWatched] on every tracker.
class TrackerCoordinator {
  static TrackerCoordinator? _instance;
  static TrackerCoordinator get instance => _instance ??= TrackerCoordinator._();

  TrackerCoordinator._();

  late final List<Tracker> _trackers = [MalTracker.instance, AnilistTracker.instance, SimklTracker.instance];

  /// Resolver persists across episode swaps so back-to-back episodes of the
  /// same show reuse the cached IDs. Cleared only on profile switch.
  TrackerIdResolver? _resolver;
  String? _resolverClientKey;
  String? _activeLibraryGlobalKey;
  FribbMappingLookup? _debugFribbStore;
  AnimeListsMappingLookup? _debugAnimeListsStore;
  AnimeEpisodeProgressLookup? _debugAnimeProgress;

  TrackerContext? _ctx;

  /// Seed used before [startPlayback] captures the server's threshold; never
  /// actually consulted (a crossing is only evaluated once `_ctx` is set,
  /// after the client value is assigned).
  static const double _fallbackWatchedThreshold = TrackerConstants.watchedThresholdPercent / 100.0;

  /// Captures position, duration, and the active client's watched threshold so
  /// tracker crossing semantics stay aligned with playback progress reporting.
  final PlaybackTimeline _timeline = PlaybackTimeline(watchedThreshold: _fallbackWatchedThreshold);
  bool _thresholdCrossed = false;
  int _playbackRevision = 0;

  /// Drop a duplicate state transition within this window — the player emits
  /// several playing-state events per seek.
  static const Duration _duplicateStateDebounce = Duration(seconds: 1);

  /// Drop a same-state re-send inside this window. Simkl serialises scrobble
  /// writes behind a 20-second per-user lock and fails queued requests with a
  /// 400, so rapid pause/play cycles must not each ship a `start`.
  static const Duration _startResendThrottle = Duration(seconds: 20);

  TrackerScrobbleState? _lastScrobbleState;
  DateTime? _lastScrobbleAt;
  bool _scrobbleStarted = false;

  /// Real-time targets pinned when the current playback began, each with the
  /// account binding it was pinned against. Every report for this playback goes
  /// to these and no others.
  List<_BoundScrobbleTarget> _playbackTargets = const [];

  /// Real-time services process one write per user at a time, so reports queue
  /// and go out in order. An episode swap stops the old item and starts the new
  /// one back to back, so both can be waiting behind one gated request.
  final List<_QueuedScrobble> _scrobbleQueue = [];
  Future<void>? _scrobbleDrain;

  /// Soft bound against a play/pause storm outrunning the remote lock: overflow
  /// sheds the oldest non-terminal report. Terminal stops are never shed, so the
  /// bound is deliberately soft — a burst of episode swaps behind one hung
  /// request queues one stop per item, and each carries that item's own watch
  /// and resume position.
  static const int _maxQueuedScrobbles = 4;

  DateTime Function() _clock = DateTime.now;

  /// Test seam: drive the debounce/throttle windows from a fake clock. Passing
  /// null restores the wall clock.
  void debugUseScrobbleClock(DateTime Function()? clock) => _clock = clock ?? DateTime.now;

  Future<void> initialize() async {
    await Future.wait(_trackers.map((t) => t.initialize()));
  }

  Future<void> startPlayback(MediaItem metadata, MediaServerClient client, {bool isLive = false}) async {
    final revision = ++_playbackRevision;
    if (isLive) {
      _reset();
      return;
    }
    final mediaType = metadata.kind;
    if (mediaType != MediaKind.movie && mediaType != MediaKind.episode) {
      _reset();
      return;
    }
    final libraryGlobalKey = metadata.libraryGlobalKey;
    if (!_hasActiveTrackerForLibrary(libraryGlobalKey)) {
      _reset();
      return;
    }

    _activeLibraryGlobalKey = libraryGlobalKey;
    final clientKey = client.cacheServerId;
    if (_resolver == null || _resolverClientKey != clientKey) {
      _resolver?.clearCache();
      _resolver = _newResolver(client, needsFribb: _anyTrackerNeedsFribb);
      _resolverClientKey = clientKey;
    }
    final ctx = await _buildContext(metadata, _resolver!);
    if (revision != _playbackRevision) return;
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for ${metadata.id}');
      _reset();
      return;
    }
    _reset();
    _ctx = ctx;
    // Seed from the server's resume offset so the first real-time report
    // carries the true position instead of 0%.
    _timeline.reset(
      position: Duration(milliseconds: metadata.viewOffsetMs ?? 0),
      duration: metadata.durationMs != null ? Duration(milliseconds: metadata.durationMs!) : null,
      watchedThreshold: client.watchedThreshold,
    );
    // A playback session belongs to the account bound when it began. Pinning the
    // targets here — rather than resolving them per report — keeps every later
    // report on that account even if the user rebinds mid-playback.
    _playbackTargets = _activeRealtimeTargets(ctx);
    unawaited(_scrobble(TrackerScrobbleState.start));
  }

  bool _anyTrackerNeedsFribb() => _anyTrackerNeedsFribbForLibrary(_activeLibraryGlobalKey);

  bool _hasActiveTrackerForLibrary(String? libraryGlobalKey) =>
      _trackers.any((t) => t.canScrobble && t.shouldScrobbleForLibrary(libraryGlobalKey));

  bool _anyTrackerNeedsFribbForLibrary(String? libraryGlobalKey) =>
      _trackers.any((t) => t.canScrobble && t.needsFribb && t.shouldScrobbleForLibrary(libraryGlobalKey));

  void debugUseResolverDependencies({
    FribbMappingLookup? store,
    AnimeListsMappingLookup? animeLists,
    AnimeEpisodeProgressLookup? animeProgress,
  }) {
    _debugFribbStore = store;
    _debugAnimeListsStore = animeLists;
    _debugAnimeProgress = animeProgress;
    invalidateResolverCache();
  }

  TrackerIdResolver _newResolver(MediaServerClient client, {required bool Function() needsFribb}) => TrackerIdResolver(
    client,
    needsFribb: needsFribb,
    store: _debugFribbStore,
    animeLists: _debugAnimeListsStore,
    animeProgress: _debugAnimeProgress,
  );

  Future<void> markWatched(MediaItem item, MediaServerClient client) => _markManual(item, client, watched: true);

  Future<void> markUnwatched(MediaItem item, MediaServerClient client) => _markManual(item, client, watched: false);

  Future<void> _markManual(MediaItem item, MediaServerClient client, {required bool watched}) async {
    try {
      await _applyManualMark(item, client, watched: watched);
    } catch (e) {
      appLogger.d('Trackers: manual ${watched ? 'markWatched' : 'markUnwatched'} failed for ${item.id}', error: e);
    }
  }

  Future<void> _applyManualMark(MediaItem item, MediaServerClient client, {required bool watched}) async {
    final kind = item.kind;
    if (kind != MediaKind.movie && kind != MediaKind.episode && kind != MediaKind.season && kind != MediaKind.show) {
      return;
    }

    final libraryGlobalKey = item.libraryGlobalKey;
    if (!_hasActiveTrackerForLibrary(libraryGlobalKey)) return;

    final resolver = _newResolver(client, needsFribb: () => _anyTrackerNeedsFribbForLibrary(libraryGlobalKey));

    if (kind == MediaKind.movie || kind == MediaKind.episode) {
      await (watched ? _markSingleWatched(item, resolver) : _markSingleUnwatched(item, resolver));
      return;
    }

    final episodes = <MediaItem>[];
    await collectEpisodes(client, item.id, unwatchedOnly: false, out: episodes, fallback: item);
    final expansion = watched ? 'expanded' : 'unwatched expanded';
    appLogger.d('Trackers: manual ${kind.name} ${item.id} $expansion to ${episodes.length} episodes');

    await (watched
        ? _markContainerEpisodesWatched(episodes, resolver)
        : _markContainerEpisodesUnwatched(episodes, resolver));
  }

  Future<void> _markContainerEpisodesWatched(List<MediaItem> episodes, TrackerIdResolver resolver) async {
    final animeGroups = <String, _ManualAnimeProgress>{};
    var resolved = 0;

    for (final episode in episodes) {
      final ctx = await _buildContext(episode, resolver, includeAnimeProgress: false);
      if (ctx == null) continue;
      resolved++;

      await _dispatch([SimklTracker.instance], ctx, watched: true);

      final key = _animeGroupKey(ctx);
      if (key == null) continue;
      (animeGroups[key] ??= _ManualAnimeProgress(ctx, fallbackToCount: true)).add(ctx);
    }

    appLogger.d('Trackers: manual container resolved $resolved/${episodes.length} episodes');

    for (final group in animeGroups.values) {
      final ctx = group.context;
      if (ctx != null) await _dispatch([MalTracker.instance, AnilistTracker.instance], ctx, watched: true);
    }
    appLogger.d('Trackers: manual container resolved ${animeGroups.length} anime entries');
  }

  Future<void> _markContainerEpisodesUnwatched(List<MediaItem> episodes, TrackerIdResolver resolver) async {
    final malEntries = <int, TrackerContext>{};
    final anilistEntries = <int, TrackerContext>{};
    var resolved = 0;

    for (final episode in episodes) {
      final ctx = await _buildContext(
        episode,
        resolver,
        includeAnimeProgress: false,
        fallbackToAnimeEpisodeNumber: false,
      );
      if (ctx == null) continue;
      resolved++;

      await _dispatch([SimklTracker.instance], ctx, watched: false);

      final anime = ctx.anime;
      if (anime == null) continue;
      final malId = anime.mal;
      if (malId != null && _isActive(MalTracker.instance, ctx.libraryGlobalKey)) {
        malEntries[malId] = ctx;
      }
      final anilistId = anime.anilist;
      if (anilistId != null && _isActive(AnilistTracker.instance, ctx.libraryGlobalKey)) {
        anilistEntries[anilistId] = ctx;
      }
    }

    appLogger.d('Trackers: manual container unwatched resolved $resolved/${episodes.length} episodes');

    await _removeAnimeEntriesFromLists(malEntries.values, anilistEntries.values);
    appLogger.d(
      'Trackers: manual container unwatched resolved ${malEntries.length} MAL and ${anilistEntries.length} AniList entries',
    );
  }

  Future<void> _removeAnimeEntriesFromLists(
    Iterable<TrackerContext> malEntries,
    Iterable<TrackerContext> anilistEntries,
  ) async {
    await Future.wait([
      ...malEntries.map((ctx) async {
        try {
          await MalTracker.instance.removeFromList(ctx);
        } catch (e) {
          appLogger.d('mal: removeFromList failed', error: e);
        }
      }),
      ...anilistEntries.map((ctx) async {
        try {
          await AnilistTracker.instance.removeFromList(ctx);
        } catch (e) {
          appLogger.d('anilist: removeFromList failed', error: e);
        }
      }),
    ]);
  }

  String? _animeGroupKey(TrackerContext ctx) {
    final anime = ctx.anime;
    if (anime == null) return null;
    final hasMal = anime.mal != null && _isActive(MalTracker.instance, ctx.libraryGlobalKey);
    final hasAnilist = anime.anilist != null && _isActive(AnilistTracker.instance, ctx.libraryGlobalKey);
    if (!hasMal && !hasAnilist) return null;
    return '${hasMal ? anime.mal : ''}:${hasAnilist ? anime.anilist : ''}';
  }

  Future<void> _markSingleWatched(MediaItem item, TrackerIdResolver resolver) async {
    final ctx = await _buildContext(item, resolver);
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for manually watched ${item.id}');
      return;
    }
    await _dispatch(_trackers, ctx, watched: true);
  }

  Future<void> _markSingleUnwatched(MediaItem item, TrackerIdResolver resolver) async {
    final ctx = await _buildContext(item, resolver, includeAnimeProgress: false, fallbackToAnimeEpisodeNumber: false);
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for manually unwatched ${item.id}');
      return;
    }
    if (ctx.isMovie) {
      await _dispatch(_trackers, ctx, watched: false);
    } else {
      await _dispatch([SimklTracker.instance], ctx, watched: false);
    }
  }

  /// Terminal report for the current playback.
  ///
  /// Threshold trackers get the safety-net watched mark. Real-time trackers get
  /// a `stop` carrying the true progress — which is also the user's resume
  /// position, so it is never inflated to force a watched state — followed by
  /// [RealtimeScrobbleTracker.reconcileWatchedAfterStop] when Plezy counts the
  /// playback as watched, because only the tracker knows whether its own stop
  /// already recorded that.
  Future<void> stopPlayback() async {
    ++_playbackRevision;
    final ctx = _ctx;
    final watched = _thresholdCrossed || _timeline.watchedThresholdReached;
    final missedThresholdMark = !_thresholdCrossed && _timeline.watchedThresholdReached;
    final progress = _timeline.progressPercent;
    final started = _scrobbleStarted;
    // Snapshotted before [_reset] clears them: the terminal report and the
    // reconciliation that follows belong to the account this playback began on.
    final targets = _playbackTargets;
    final reconcilers = watched && started ? targets : const <_BoundScrobbleTarget>[];
    _reset();
    if (ctx == null) return;

    await Future.wait([
      if (missedThresholdMark) _dispatch(_thresholdTrackers, ctx, watched: true),
      _sendScrobble(ctx, TrackerScrobbleState.stop, progress, sessionStarted: started, targets: targets),
    ]);
    await _drainScrobbles();
    await _reconcileWatchedAfterStop(reconcilers, ctx, progress);
  }

  /// The player paused, or the app was backgrounded. Saves resumable progress
  /// on real-time trackers; threshold trackers are unaffected.
  Future<void> pausePlayback() => _scrobble(TrackerScrobbleState.pause);

  Future<void> resumePlayback() => _scrobble(TrackerScrobbleState.start);

  void updatePosition(Duration position) {
    _timeline.updatePosition(position);
    final ctx = _ctx;
    if (ctx == null || _thresholdCrossed) return;
    if (!_timeline.watchedThresholdReached) return;
    _thresholdCrossed = true;
    unawaited(_dispatch(_thresholdTrackers, ctx, watched: true));
  }

  void updateDuration(Duration duration) {
    _timeline.updateDuration(duration);
  }

  /// Called on Plex profile switch — drops in-flight state across all
  /// trackers and invalidates the resolver so a fresh Plex client is used.
  void cancelInFlight() {
    ++_playbackRevision;
    // Queued reports belong to the profile being left; the client backing them
    // is about to be disposed.
    _scrobbleQueue.clear();
    _reset();
    _resolver?.clearCache();
    _resolver = null;
    _resolverClientKey = null;
  }

  /// Drop the resolver's ID cache without touching in-flight playback state.
  /// Called after a tracker is connected/disconnected so cached lookups
  /// re-evaluate the `needsFribb` predicate.
  void invalidateResolverCache() => _resolver?.clearCache();

  void _reset() {
    _ctx = null;
    _activeLibraryGlobalKey = null;
    _timeline.reset(watchedThreshold: _fallbackWatchedThreshold);
    _thresholdCrossed = false;
    _lastScrobbleState = null;
    _lastScrobbleAt = null;
    _scrobbleStarted = false;
    _playbackTargets = const [];
  }

  /// Trackers whose watch is recorded by the threshold crossing. Real-time
  /// trackers are excluded — their own playback lifecycle owns it, and one
  /// watch must never produce two writes.
  Iterable<Tracker> get _thresholdTrackers => _trackers.where((t) => t is! RealtimeScrobbleTracker);

  Iterable<RealtimeScrobbleTracker> get _realtimeTrackers => _trackers.whereType<RealtimeScrobbleTracker>();

  bool _isActive(Tracker tracker, String? libraryGlobalKey) =>
      tracker.canScrobble && tracker.shouldScrobbleForLibrary(libraryGlobalKey);

  Future<void> _dispatch(Iterable<Tracker> trackers, TrackerContext ctx, {required bool watched}) async {
    final active = trackers.where((t) => _isActive(t, ctx.libraryGlobalKey));
    await Future.wait(
      active.map((t) async {
        try {
          await (watched ? t.markWatched(ctx) : t.markUnwatched(ctx));
        } catch (e) {
          appLogger.d('${t.name}: ${watched ? 'markWatched' : 'markUnwatched'} failed', error: e);
        }
      }),
    );
  }

  Future<void> _scrobble(TrackerScrobbleState state) {
    final ctx = _ctx;
    if (ctx == null) return Future.value();
    return _sendScrobble(
      ctx,
      state,
      _timeline.progressPercent,
      sessionStarted: _scrobbleStarted,
      targets: _playbackTargets,
    );
  }

  /// [sessionStarted] and [targets] are passed in rather than read from the
  /// fields because the terminal report is sent after [_reset] has already
  /// cleared the per-playback state, on a snapshot of it.
  Future<void> _sendScrobble(
    TrackerContext ctx,
    TrackerScrobbleState state,
    double progressPercent, {
    required bool sessionStarted,
    required List<_BoundScrobbleTarget> targets,
  }) {
    // A pause/stop with no session behind it would only invent one — that is the
    // rolled-back player attempt, which never got as far as a start. Progress is
    // deliberately not floored here: a session that did start must be closed
    // even at 0%, or the service keeps showing the item as playing until its
    // runtime elapses.
    if (state != TrackerScrobbleState.start && !sessionStarted) return Future.value();

    final now = _clock();
    final last = _lastScrobbleAt;
    if (_lastScrobbleState == state && last != null) {
      final elapsed = now.difference(last);
      if (elapsed < _duplicateStateDebounce) return Future.value();
      if (state == TrackerScrobbleState.start && elapsed < _startResendThrottle) return Future.value();
    }

    // Still the same account, and still enabled for this library: the user can
    // turn a tracker off or filter the library out mid-playback.
    final sendable = [
      for (final target in targets)
        if (_bindingIntact(target, 'scrobble ${state.name}') && _isActive(target.$1, ctx.libraryGlobalKey)) target,
    ];
    if (sendable.isEmpty) return Future.value();

    _lastScrobbleState = state;
    _lastScrobbleAt = now;
    if (state == TrackerScrobbleState.start) _scrobbleStarted = true;

    return _enqueueScrobble(state, () => _fanOutScrobble(sendable, ctx, state, progressPercent));
  }

  /// Pins each active real-time tracker to the account binding it is being
  /// captured against, once per playback.
  List<_BoundScrobbleTarget> _activeRealtimeTargets(TrackerContext ctx) => [
    for (final t in _realtimeTrackers)
      if (_isActive(t, ctx.libraryGlobalKey)) (t, t.scrobbleBinding),
  ];

  /// False when the tracker was rebound since [target] was captured: the write
  /// belongs to an account that is no longer bound (and whose client has been
  /// disposed), so it is dropped rather than misfiled onto its replacement.
  bool _bindingIntact(_BoundScrobbleTarget target, String operation) {
    final (tracker, binding) = target;
    if (identical(tracker.scrobbleBinding, binding)) return true;
    appLogger.d('${tracker.name}: skipped $operation — account rebound');
    return false;
  }

  Future<void> _fanOutScrobble(
    List<_BoundScrobbleTarget> targets,
    TrackerContext ctx,
    TrackerScrobbleState state,
    double progressPercent,
  ) {
    return Future.wait(
      targets.map((target) async {
        if (!_bindingIntact(target, 'scrobble ${state.name}')) return;
        final (tracker, _) = target;
        try {
          await tracker.scrobble(ctx, state, progressPercent);
        } catch (e) {
          // A tracker write must never disrupt playback.
          appLogger.d('${tracker.name}: scrobble ${state.name} failed', error: e);
        }
      }),
    );
  }

  Future<void> _reconcileWatchedAfterStop(
    List<_BoundScrobbleTarget> reconcilers,
    TrackerContext ctx,
    double progressPercent,
  ) {
    return Future.wait(
      reconcilers.map((target) async {
        if (!_bindingIntact(target, 'watched reconciliation')) return;
        final (tracker, _) = target;
        try {
          await tracker.reconcileWatchedAfterStop(ctx, progressPercent);
        } catch (e) {
          appLogger.d('${tracker.name}: reconcileWatchedAfterStop failed', error: e);
        }
      }),
    );
  }

  /// Queue a report behind whatever is already going out. Overflow sheds the
  /// oldest non-terminal entry so a stop for an item the player has already
  /// swapped away from still reaches the service.
  Future<void> _enqueueScrobble(TrackerScrobbleState state, Future<void> Function() send) {
    _scrobbleQueue.add(_QueuedScrobble(state, send));
    if (_scrobbleQueue.length > _maxQueuedScrobbles) {
      final victim = _scrobbleQueue.indexWhere((q) => q.state != TrackerScrobbleState.stop);
      if (victim >= 0) _scrobbleQueue.removeAt(victim);
    }
    final draining = _scrobbleDrain;
    if (draining != null) return draining;
    final drain = _drainScrobbleQueue();
    _scrobbleDrain = drain;
    return drain;
  }

  Future<void> _drainScrobbleQueue() async {
    try {
      while (_scrobbleQueue.isNotEmpty) {
        await _scrobbleQueue.removeAt(0).send();
      }
    } finally {
      _scrobbleDrain = null;
    }
  }

  /// Await every queued report so a terminal stop is on the wire before the
  /// caller (screen teardown, app shutdown) moves on.
  Future<void> _drainScrobbles() async {
    var drain = _scrobbleDrain;
    while (drain != null) {
      await drain;
      final next = _scrobbleDrain;
      if (identical(next, drain)) break;
      drain = next;
    }
  }

  Future<TrackerContext?> _buildContext(
    MediaItem metadata,
    TrackerIdResolver resolver, {
    bool includeAnimeProgress = true,
    bool includeCurrentEpisode = true,
    bool fallbackToAnimeEpisodeNumber = true,
  }) async {
    final libraryKey = metadata.libraryGlobalKey;

    if (metadata.kind == MediaKind.movie) {
      final ids = await resolver.resolveForMovie(metadata.id);
      if (ids == null) return null;
      return TrackerContext.movie(
        external: ids.external,
        anime: ids.anime,
        ratingKey: metadata.id,
        libraryGlobalKey: libraryKey,
      );
    }

    final season = metadata.parentIndex;
    final number = metadata.index;
    if (season == null || number == null) return null;

    final ids = await resolver.resolveShowForEpisode(
      metadata,
      includeAnimeProgress: includeAnimeProgress,
      includeCurrentEpisode: includeCurrentEpisode,
    );
    if (ids == null) return null;
    final animeProgress = includeAnimeProgress
        ? ids.animeProgress ?? (fallbackToAnimeEpisodeNumber ? ids.animeEpisodeNumber : null)
        : fallbackToAnimeEpisodeNumber
        ? ids.animeEpisodeNumber
        : null;
    return TrackerContext.episode(
      external: ids.external,
      anime: ids.anime,
      ratingKey: metadata.id,
      libraryGlobalKey: libraryKey,
      season: season,
      episodeNumber: number,
      animeProgress: animeProgress,
    );
  }
}

/// One queued real-time report. [state] is kept so overflow can tell a terminal
/// stop apart from a droppable start/pause.
class _QueuedScrobble {
  final TrackerScrobbleState state;
  final Future<void> Function() send;

  const _QueuedScrobble(this.state, this.send);
}

class _ManualAnimeProgress {
  final TrackerContext _base;
  final bool _fallbackToCount;
  int _count = 0;
  int? _maxMappedProgress;

  _ManualAnimeProgress(this._base, {required this._fallbackToCount});

  void add(TrackerContext ctx) {
    _count++;
    final mapped = ctx.animeProgress;
    if (mapped != null && (_maxMappedProgress == null || mapped > _maxMappedProgress!)) {
      _maxMappedProgress = mapped;
    }
  }

  int? get progress => _maxMappedProgress ?? (_fallbackToCount ? _count : null);

  TrackerContext? get context {
    final progress = this.progress;
    if (progress == null) return null;
    return TrackerContext.episode(
      external: _base.external,
      anime: _base.anime,
      ratingKey: _base.ratingKey,
      libraryGlobalKey: _base.libraryGlobalKey,
      season: _base.season!,
      episodeNumber: progress,
      animeProgress: progress,
    );
  }
}
