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
import 'mdblist/mdblist_tracker.dart';
import 'simkl/simkl_tracker.dart';
import 'tracker.dart';
import 'tracker_constants.dart';
import 'tracker_exceptions.dart';
import 'tracker_id_resolver.dart';
import 'tracker_write_queue.dart';
import 'trakt/trakt_tracker.dart';

/// The single seam through which every tracker write leaves the app.
///
/// Three mechanisms, chosen per tracker kind:
///
/// * [RealtimeScrobbleTracker]s (Simkl, Trakt, MDBList) receive the playback
///   lifecycle — start/resume, pause, seek, stop — with the current progress,
///   and decide watched state themselves. They are excluded from the threshold
///   fan-out so a single watch never produces two writes.
/// * Threshold trackers (MAL, AniList) are notified exactly once when progress
///   crosses the watched threshold, with a safety-net fire on stop if the
///   crossing was missed (e.g. the user stopped between ticks).
/// * Manual, container, offline-replay, external-player and server-observed
///   marks bypass playback entirely and go straight to [Tracker.markWatched] on
///   every tracker that can write.
///
/// A failed per-item history write is persisted in [TrackerWriteQueue] and
/// replayed by [flushWriteQueue], so a transient error does not silently drop a
/// watch.
class TrackerCoordinator {
  static TrackerCoordinator? _instance;
  static TrackerCoordinator get instance => _instance ??= TrackerCoordinator._();

  TrackerCoordinator._();

  /// The registry. Everything below partitions this list by capability rather
  /// than naming services, so adding one means adding it here and nowhere else.
  late final List<Tracker> _trackers = [
    MalTracker.instance,
    AnilistTracker.instance,
    SimklTracker.instance,
    TraktTracker.instance,
    MdblistTracker.instance,
  ];

  /// One transport per real-time tracker, created once and outliving individual
  /// playbacks: an episode swap stops the old item and starts the new one back
  /// to back, and both belong in the same per-service order.
  late final List<_ScrobbleChannel> _channels = [
    for (final tracker in _trackers.whereType<RealtimeScrobbleTracker>()) _ScrobbleChannel(tracker),
  ];

  final TrackerWriteQueue _writeQueue = TrackerWriteQueue();
  String _activeUserUuid = '';
  int _profileGeneration = 0;

  /// In-flight write chains, one per remote row per profile (see
  /// [_sequencedByKey]). Entries are removed as soon as nothing is queued behind
  /// them, so this never grows past the writes currently in flight.
  final Map<String, Completer<void>> _writeChains = {};

  /// Intent numbering for the same rows, so a failing write can tell whether a
  /// newer one has already succeeded. Same lifetime as [_writeChains].
  final Map<String, _RowIntents> _rowIntents = {};

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
  /// several playing-state events per seek. This one is a player-side artifact,
  /// so unlike [ScrobblePolicy] it is the same for every service.
  static const Duration _duplicateStateDebounce = Duration(seconds: 1);

  /// Real-time targets pinned when the current playback began. Every report for
  /// this playback goes to these and no others.
  List<_PlaybackTarget> _playbackTargets = const [];

  DateTime Function() _clock = DateTime.now;

  /// Test seam: drive the debounce/throttle windows from a fake clock. Passing
  /// null restores the wall clock.
  void debugUseScrobbleClock(DateTime Function()? clock) => _clock = clock ?? DateTime.now;

  Future<void> initialize() async {
    await Future.wait(_trackers.map((t) => t.initialize()));
  }

  /// Rebind to a profile: drops in-flight playback state and the resolver (which
  /// holds a media client), and points the retry queue at the new profile's
  /// items. Called before the per-service sessions are pushed to the trackers.
  void onActiveProfileChanged(String userUuid) {
    _activeUserUuid = userUuid;
    ++_profileGeneration;
    cancelInFlight();
  }

  /// The profile a write belongs to, captured before its first await. Every
  /// deferred step re-checks it, so a switch mid-write can neither file one
  /// profile's retry under another nor replay a leftover row through the account
  /// that replaced it.
  _WriteScope get _currentScope => _WriteScope(_activeUserUuid, _profileGeneration);

  bool _isCurrent(_WriteScope scope) => scope.generation == _profileGeneration;

  /// Replay watched writes that failed earlier. Safe to call repeatedly —
  /// concurrent calls coalesce, and an item whose service has no session, or
  /// whose write the service will not take right now, is left untouched rather
  /// than counted as a failed attempt.
  ///
  /// Driven from profile bind, a successful connect, app foreground, and network
  /// restore. Never throws: a retry pass is best-effort, its callers are
  /// fire-and-forget, and a queue that cannot be read or written this time simply
  /// waits for the next trigger.
  Future<void> flushWriteQueue() async {
    final scope = _currentScope;
    try {
      await _writeQueue.flush(scope.userUuid, send: (item) => _replayQueuedWrite(item, scope));
    } catch (e, st) {
      appLogger.w('Trackers: write queue flush failed', error: e, stackTrace: st);
    }
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
    if (!_hasPlaybackInterest(libraryGlobalKey)) {
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
    _playbackTargets = [
      for (final channel in _channels)
        if (_canReport(channel.tracker, ctx.libraryGlobalKey))
          _PlaybackTarget(channel, channel.tracker.scrobbleBinding),
    ];
    unawaited(_scrobble(TrackerScrobbleState.start));
  }

  bool _anyTrackerNeedsFribb() => _anyTrackerNeedsFribbForLibrary(_activeLibraryGlobalKey);

  /// True when at least one tracker would act on this playback — either by
  /// receiving reports or by recording the watch when progress crosses over.
  /// Trakt can be in the second group without being in the first: its scrobble
  /// and watched-sync settings are independent.
  bool _hasPlaybackInterest(String? libraryGlobalKey) => _trackers.any(
    (t) => _canWrite(t, libraryGlobalKey) || (t is RealtimeScrobbleTracker && _canReport(t, libraryGlobalKey)),
  );

  bool _hasWatchedInterest(String? libraryGlobalKey) => _trackers.any((t) => _canWrite(t, libraryGlobalKey));

  bool _anyTrackerNeedsFribbForLibrary(String? libraryGlobalKey) =>
      _trackers.any((t) => t.needsFribb && _canWrite(t, libraryGlobalKey));

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
    if (!_hasWatchedInterest(libraryGlobalKey)) return;

    final resolver = _newResolver(client, needsFribb: () => _anyTrackerNeedsFribbForLibrary(libraryGlobalKey));

    final scope = _currentScope;
    if (kind == MediaKind.movie || kind == MediaKind.episode) {
      await (watched ? _markSingleWatched(item, resolver, scope) : _markSingleUnwatched(item, resolver, scope));
      return;
    }

    final episodes = <MediaItem>[];
    await collectEpisodes(client, item.id, unwatchedOnly: false, out: episodes, fallback: item);
    if (!_isCurrent(scope)) return;
    final expansion = watched ? 'expanded' : 'unwatched expanded';
    appLogger.d('Trackers: manual ${kind.name} ${item.id} $expansion to ${episodes.length} episodes');

    await (watched
        ? _markContainerEpisodesWatched(episodes, resolver, scope)
        : _markContainerEpisodesUnwatched(episodes, resolver, scope));
  }

  Future<void> _markContainerEpisodesWatched(
    List<MediaItem> episodes,
    TrackerIdResolver resolver,
    _WriteScope scope,
  ) async {
    final seriesGroups = <String, _ManualSeriesProgress>{};
    var resolved = 0;

    for (final episode in episodes) {
      final ctx = await _buildContext(episode, resolver, includeAnimeProgress: false);
      if (!_isCurrent(scope)) return;
      if (ctx == null) continue;
      resolved++;

      await _dispatch(_episodeHistoryTrackers, ctx, scope, watched: true);

      final key = _seriesGroupKey(ctx);
      if (key == null) continue;
      (seriesGroups[key] ??= _ManualSeriesProgress(ctx, fallbackToCount: true)).add(ctx);
    }

    appLogger.d('Trackers: manual container resolved $resolved/${episodes.length} episodes');

    for (final group in seriesGroups.values) {
      final ctx = group.context;
      if (ctx != null) await _dispatch(_seriesProgressTrackers, ctx, scope, watched: true);
    }
    appLogger.d('Trackers: manual container resolved ${seriesGroups.length} series entries');
  }

  Future<void> _markContainerEpisodesUnwatched(
    List<MediaItem> episodes,
    TrackerIdResolver resolver,
    _WriteScope scope,
  ) async {
    // One context per series entry per tracker: a show maps to a single list
    // entry, so all of its episodes collapse into one removal.
    final entriesByTracker = <SeriesProgressTracker, Map<Object, TrackerContext>>{};
    var resolved = 0;

    for (final episode in episodes) {
      final ctx = await _buildContext(
        episode,
        resolver,
        includeAnimeProgress: false,
        fallbackToAnimeEpisodeNumber: false,
      );
      if (!_isCurrent(scope)) return;
      if (ctx == null) continue;
      resolved++;

      await _dispatch(_episodeHistoryTrackers, ctx, scope, watched: false);

      for (final tracker in _seriesProgressTrackers) {
        if (!_canWrite(tracker, ctx.libraryGlobalKey)) continue;
        final entryId = tracker.seriesEntryId(ctx);
        if (entryId == null) continue;
        (entriesByTracker[tracker] ??= {})[entryId] = ctx;
      }
    }

    appLogger.d('Trackers: manual container unwatched resolved $resolved/${episodes.length} episodes');
    await _removeSeriesEntries(entriesByTracker, scope);
  }

  /// Dropping a whole series entry has no queued-retry form — the queue replays
  /// [Tracker] writes, and this is not one — so a failure here is logged and
  /// dropped. A success invalidates any queued progress claim for that entry,
  /// which would otherwise replay and resurrect the list entry the user just
  /// cleared.
  Future<void> _removeSeriesEntries(
    Map<SeriesProgressTracker, Map<Object, TrackerContext>> entriesByTracker,
    _WriteScope scope,
  ) async {
    await Future.wait([
      for (final entry in entriesByTracker.entries)
        ...entry.value.values.map((ctx) => _removeSeriesEntry(entry.key, ctx, scope)),
    ]);
    for (final entry in entriesByTracker.entries) {
      appLogger.d('Trackers: manual container unwatched removed ${entry.value.length} ${entry.key.name} entries');
    }
  }

  Future<void> _removeSeriesEntry(SeriesProgressTracker tracker, TrackerContext ctx, _WriteScope scope) async {
    final key = _coalesceKeyFor(tracker, ctx);
    int? marker;
    try {
      await _sequencedByKey(scope, key, () async {
        await tracker.removeFromList(ctx);
        if (key != null) marker = _writeQueue.noteDirectWrite(scope.userUuid, key);
      });
    } catch (e) {
      appLogger.d('${tracker.name}: removeFromList failed', error: e);
      return;
    }
    // The entry is gone; a queued progress claim for it would resurrect it.
    await _settleQueueAfterWrite(key, marker, scope);
  }

  /// Group key over the series entries a container's episodes would touch, so
  /// one entry receives one write however many episodes map to it. Null when no
  /// active series tracker can map the item.
  String? _seriesGroupKey(TrackerContext ctx) {
    final parts = <String>[];
    for (final tracker in _seriesProgressTrackers) {
      if (!_canWrite(tracker, ctx.libraryGlobalKey)) continue;
      final entryId = tracker.seriesEntryId(ctx);
      if (entryId == null) continue;
      parts.add('${tracker.service.name}=$entryId');
    }
    return parts.isEmpty ? null : parts.join('|');
  }

  Future<void> _markSingleWatched(MediaItem item, TrackerIdResolver resolver, _WriteScope scope) async {
    final ctx = await _buildContext(item, resolver);
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for manually watched ${item.id}');
      return;
    }
    await _dispatch(_trackers, ctx, scope, watched: true);
  }

  Future<void> _markSingleUnwatched(MediaItem item, TrackerIdResolver resolver, _WriteScope scope) async {
    final ctx = await _buildContext(item, resolver, includeAnimeProgress: false, fallbackToAnimeEpisodeNumber: false);
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for manually unwatched ${item.id}');
      return;
    }
    // A single episode cannot be unwatched on a series-progress tracker: its
    // entry counts episodes, so only whole-entry removal (the container path)
    // means anything there.
    await _dispatch(ctx.isMovie ? _trackers : _episodeHistoryTrackers, ctx, scope, watched: false);
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
    // Snapshotted before [_reset] clears the field: the terminal report and the
    // reconciliation that follows belong to the account this playback began on.
    final targets = _playbackTargets;
    _reset();
    if (ctx == null) return;

    final scope = _currentScope;
    // Ownership is decided here, once, so the two ways of recording a watch stay
    // mutually exclusive: whoever owns its own stop is not told about the
    // crossing, and whoever was told is not reconciled.
    final owners = _watchOwners(targets);
    await Future.wait([
      if (missedThresholdMark) _dispatch(_thresholdTrackers(owners), ctx, scope, watched: true),
      _sendScrobble(ctx, TrackerScrobbleState.stop, progress, targets),
    ]);
    await _settleScrobbles();
    if (!watched) return;

    // An owner only owns the watch if its terminal report actually landed. When
    // the stop failed, nothing on that service recorded anything — its own
    // completion rule never ran — so the watch falls back to a history write,
    // queued for retry if that fails too.
    final reconcilable = <_PlaybackTarget>[];
    final unreported = <Tracker>[];
    for (final owner in owners) {
      if (!_bindingIntact(owner, 'watched reconciliation')) continue;
      if (owner.stopConfirmed) {
        reconcilable.add(owner);
      } else {
        unreported.add(owner.tracker);
      }
    }
    await Future.wait([
      _reconcileWatchedAfterStop(reconcilable, ctx, progress, scope),
      if (unreported.isNotEmpty) _dispatch(unreported, ctx, scope, watched: true),
    ]);
  }

  /// The player paused, or the app was backgrounded. Saves resumable progress
  /// on real-time trackers; threshold trackers are unaffected.
  Future<void> pausePlayback() => _scrobble(TrackerScrobbleState.pause);

  Future<void> resumePlayback() => _scrobble(TrackerScrobbleState.start);

  void updatePosition(Duration position) {
    final isSeek = _timeline.updatePosition(position);
    final ctx = _ctx;
    if (ctx == null) return;
    // A seek is a checkpoint, not a transition: services that expose no seek
    // event opt out through their [ScrobblePolicy] and never see one.
    if (isSeek) unawaited(_scrobble(TrackerScrobbleState.seek));
    if (_thresholdCrossed) return;
    if (!_timeline.watchedThresholdReached) return;
    _thresholdCrossed = true;
    unawaited(_dispatch(_thresholdTrackers(_watchOwners(_playbackTargets)), ctx, _currentScope, watched: true));
  }

  void updateDuration(Duration duration) {
    _timeline.updateDuration(duration);
  }

  /// Called on profile switch — drops in-flight state across all trackers and
  /// invalidates the resolver so a fresh media client is used.
  void cancelInFlight() {
    ++_playbackRevision;
    // Queued reports belong to the profile being left; the client backing them
    // is about to be disposed.
    for (final channel in _channels) {
      channel.clear();
    }
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
    // Per-playback report bookkeeping lives on the targets, so dropping them
    // clears the debounce/throttle state with it.
    _playbackTargets = const [];
  }

  /// The real-time targets that own the watched state of this playback: their own
  /// terminal stop — plus [RealtimeScrobbleTracker.reconcileWatchedAfterStop] —
  /// records the watch, so the threshold crossing must leave them alone.
  ///
  /// Ownership follows the session, not the current settings. A target that never
  /// got a session open is not an owner: no stop will be sent for it, so the
  /// crossing is the only thing that would record its watch. One whose scrobbling
  /// the user turned off mid-playback stays an owner — its stop simply never goes
  /// out, and the unconfirmed-stop path then falls back to a history write. Were
  /// ownership re-evaluated at stop time instead, a toggle flipped after the
  /// crossing would leave the watch recorded by neither route.
  List<_PlaybackTarget> _watchOwners(List<_PlaybackTarget> targets) => [
    for (final target in targets)
      if (target.sessionStarted) target,
  ];

  /// Trackers that must be told about the threshold crossing: everyone that does
  /// not own this playback's watched state. One watch, one write.
  Iterable<Tracker> _thresholdTrackers(List<_PlaybackTarget> owners) =>
      _trackers.where((tracker) => !owners.any((owner) => identical(owner.tracker, tracker)));

  Iterable<EpisodeHistoryTracker> get _episodeHistoryTrackers => _trackers.whereType<EpisodeHistoryTracker>();

  Iterable<SeriesProgressTracker> get _seriesProgressTrackers => _trackers.whereType<SeriesProgressTracker>();

  bool _canWrite(Tracker tracker, String? libraryGlobalKey) =>
      tracker.canWriteWatched && tracker.shouldScrobbleForLibrary(libraryGlobalKey);

  bool _canReport(RealtimeScrobbleTracker tracker, String? libraryGlobalKey) =>
      tracker.canReportPlayback && tracker.shouldScrobbleForLibrary(libraryGlobalKey);

  Tracker? _trackerFor(TrackerService service) {
    for (final tracker in _trackers) {
      if (tracker.service == service) return tracker;
    }
    return null;
  }

  Future<void> _dispatch(
    Iterable<Tracker> trackers,
    TrackerContext ctx,
    _WriteScope scope, {
    required bool watched,
  }) async {
    if (!_isCurrent(scope)) return;
    final active = [
      for (final tracker in trackers)
        if (_canWrite(tracker, ctx.libraryGlobalKey)) tracker,
    ];
    if (active.isEmpty) return;
    await Future.wait(active.map((tracker) => _applyWrite(tracker, ctx, scope, watched: watched)));
  }

  /// One watched/unwatched write plus the bookkeeping that keeps it consistent
  /// with everything else targeting the same remote row.
  ///
  /// The write is serialised against other writes for that row, and carries an
  /// intent number claimed inside the row's channel — so writes are numbered in
  /// the order they actually go out. A failure only becomes a queued retry if no
  /// later intent for the row has succeeded meanwhile: without that check, a slow
  /// failure could persist stale state moments after a newer write cleaned the
  /// queue and moved the service on.
  Future<void> _applyWrite(Tracker tracker, TrackerContext ctx, _WriteScope scope, {required bool watched}) async {
    final key = _coalesceKeyFor(tracker, ctx);
    final appliedProgress = watched ? _progressClaim(tracker, ctx) : null;
    int? marker;
    var intent = 0;
    try {
      await _sequencedByKey(scope, key, () async {
        if (key != null) intent = _beginIntent(scope, key);
        await (watched ? tracker.markWatched(ctx) : tracker.markUnwatched(ctx));
        if (key != null) {
          _intentSucceeded(scope, key, intent, appliedProgress: appliedProgress);
          // Marked inside the row's channel, so a replay waiting behind this
          // write sees it before deciding whether it is still needed.
          marker = _writeQueue.noteDirectWrite(scope.userUuid, key, appliedProgress: appliedProgress);
        }
      });
      await _settleQueueAfterWrite(key, marker, scope, appliedProgress: appliedProgress);
    } catch (e) {
      final operation = watched ? 'markWatched' : 'markUnwatched';
      if (key != null && _shouldDropFailedWrite(scope, key, intent, progressClaim: appliedProgress)) {
        appLogger.d('${tracker.name}: $operation failed, superseded by a newer write', error: e);
        return;
      }
      appLogger.d('${tracker.name}: $operation failed, queued for retry', error: e);
      await _enqueueWrite(tracker, ctx, scope, watched: watched);
    } finally {
      if (key != null && intent != 0) _endIntent(scope, key);
    }
  }

  String _rowKey(_WriteScope scope, String key) => '${scope.userUuid}|$key';

  /// Claim the next intent number for a row. Called inside the row's channel, so
  /// intents are numbered in the order the writes reach the service.
  int _beginIntent(_WriteScope scope, String key) {
    final state = _rowIntents.putIfAbsent(_rowKey(scope, key), _RowIntents.new);
    state.pending++;
    return ++state.lastIntent;
  }

  void _intentSucceeded(_WriteScope scope, String key, int intent, {int? appliedProgress}) {
    final state = _rowIntents[_rowKey(scope, key)];
    if (state == null || intent < state.lastAppliedIntent) return;
    state.lastAppliedIntent = intent;
    state.lastAppliedProgress = appliedProgress;
    state.hasApplied = true;
  }

  /// Whether a failed write should be dropped rather than queued for retry.
  ///
  /// A history write states the current truth about an item, so any newer intent
  /// for that row — however it ends — owns it and this one is stale. A series
  /// claim is monotonic instead: only a completed write that already covers the
  /// claim makes it pointless, and two queued claims coalesce to the higher, so
  /// the outcome does not depend on which failure is persisted first.
  bool _shouldDropFailedWrite(_WriteScope scope, String key, int intent, {required int? progressClaim}) {
    final state = _rowIntents[_rowKey(scope, key)];
    if (state == null) return false;
    if (progressClaim == null) return state.lastIntent > intent;
    if (!state.hasApplied) return false;
    return TrackerWriteQueue.coversClaim(appliedProgress: state.lastAppliedProgress, claim: progressClaim);
  }

  /// Release an intent. The row's bookkeeping is dropped once nothing holds it,
  /// so this only ever tracks writes in flight.
  void _endIntent(_WriteScope scope, String key) {
    final stateKey = _rowKey(scope, key);
    final state = _rowIntents[stateKey];
    if (state == null) return;
    if (--state.pending <= 0) _rowIntents.remove(stateKey);
  }

  /// Drop the queued rows a landed write covers, and hold its marker until that
  /// is done: a drain may already be holding one of those rows, and its sender
  /// runs whether or not the row is still on disk.
  ///
  /// Best-effort by construction. The write already landed, so a failure here
  /// must never surface as a failed write — that would queue a retry and
  /// duplicate it.
  Future<void> _settleQueueAfterWrite(String? key, int? marker, _WriteScope scope, {int? appliedProgress}) async {
    if (key == null) return;
    try {
      await _writeQueue.invalidate(scope.userUuid, key, appliedProgress: appliedProgress);
    } catch (e) {
      appLogger.d('Trackers: write queue cleanup failed for $key', error: e);
    } finally {
      if (marker != null) _writeQueue.clearDirectWrite(scope.userUuid, key, marker);
    }
  }

  /// Serialises every write that targets the same remote row of the same profile
  /// — live writes and queued replays alike.
  ///
  /// Coalescing the queue is not enough on its own: a stale replay that is
  /// already on the wire cannot be recalled, so it could land after a newer
  /// direct write and undo it (walking a series counter backwards, or
  /// resurrecting an item the user just un-watched). Chaining by row means the
  /// newest write for it is always the last one to reach the service.
  ///
  /// Scoped per profile: two profiles write to two accounts, so one must never
  /// wait on — or be mistaken for — the other.
  Future<T> _sequencedByKey<T>(_WriteScope scope, String? key, Future<T> Function() write) {
    if (key == null) return write();
    final chainKey = _rowKey(scope, key);
    final previous = _writeChains[chainKey];
    final link = Completer<void>();
    _writeChains[chainKey] = link;
    Future<T> run() async {
      try {
        return await write();
      } finally {
        link.complete();
        if (identical(_writeChains[chainKey], link)) _writeChains.remove(chainKey);
      }
    }

    return previous == null ? run() : previous.future.then((_) => run());
  }

  /// Identity a queued write coalesces on. A per-item history tracker keys on the
  /// remote media row; a series-progress tracker keys on the remote list entry,
  /// because every episode of one show restates the same counter. Both are
  /// server-independent — a rating key is not, and would let two items on two
  /// servers replace each other. Null when the tracker cannot name a remote
  /// target, in which case the write could not have applied either.
  String? _coalesceKeyFor(Tracker tracker, TrackerContext ctx) {
    if (tracker is SeriesProgressTracker) {
      final entryId = tracker.seriesEntryId(ctx);
      return entryId == null ? null : trackerSeriesCoalesceKey(tracker.service, entryId);
    }
    if (tracker is EpisodeHistoryTracker) {
      return trackerItemCoalesceKey(tracker.service, ctx, tracker.historyRowIdentity(ctx));
    }
    return null;
  }

  /// The absolute progress a watched write would claim, for the trackers that
  /// store one. Null everywhere else: a history write is a statement about an
  /// item, not a monotonic claim.
  int? _progressClaim(Tracker tracker, TrackerContext ctx) =>
      tracker is SeriesProgressTracker ? tracker.seriesProgress(ctx) : null;

  Future<void> _enqueueWrite(Tracker tracker, TrackerContext ctx, _WriteScope scope, {required bool watched}) async {
    final key = _coalesceKeyFor(tracker, ctx);
    if (key == null) return;
    await _writeQueue.enqueue(
      scope.userUuid,
      TrackerWriteQueueItem(
        service: tracker.service,
        watched: watched,
        ctx: ctx,
        coalesceKey: key,
        progressClaim: watched ? _progressClaim(tracker, ctx) : null,
        watchedAtIso: _clock().toUtc().toIso8601String(),
      ),
    );
  }

  Future<TrackerWriteDisposition> _replayQueuedWrite(TrackerWriteQueueItem item, _WriteScope scope) async {
    // The trackers now hold another profile's sessions; leave the rest of this
    // profile's rows for its own flush rather than writing them to that account.
    if (!_isCurrent(scope)) return TrackerWriteDisposition.skipped;
    final tracker = _trackerFor(item.service);
    if (tracker == null) return TrackerWriteDisposition.done;
    if (!tracker.canWriteWatched) return TrackerWriteDisposition.skipped;
    if (!tracker.shouldScrobbleForLibrary(item.ctx.libraryGlobalKey)) {
      appLogger.d('${tracker.name}: queued write dropped — library filtered out');
      return TrackerWriteDisposition.done;
    }
    try {
      // Inside the row's channel: a direct write for the same row may have landed
      // while this replay waited its turn, in which case replaying would undo it.
      final replayed = await _sequencedByKey(scope, item.coalesceKey, () async {
        if (_writeQueue.isSuperseded(scope.userUuid, item)) return false;
        await (item.watched
            ? tracker.markWatched(item.ctx, watchedAt: item.watchedAt)
            : tracker.markUnwatched(item.ctx));
        return true;
      });
      appLogger.d(
        replayed
            ? '${tracker.name}: replayed queued write for ${item.ctx.ratingKey}'
            : '${tracker.name}: queued write for ${item.ctx.ratingKey} already covered by a newer write',
      );
      return TrackerWriteDisposition.done;
    } catch (e) {
      // Only an answer about this write may spend an attempt. A link that came
      // back without reaching the endpoint, a rate limit, or the service failing
      // on its own side are all reasons to ask again later — counting them would
      // let a bad hour, or a few connectivity flaps, drop the watch for good. The
      // drain also stops asking this service for the rest of the pass.
      if (isTrackerFailureTransient(e)) {
        appLogger.d('${tracker.name}: queued write deferred, service not taking writes', error: e);
        return TrackerWriteDisposition.deferredService;
      }
      appLogger.d('${tracker.name}: queued write failed, will retry', error: e);
      return TrackerWriteDisposition.failed;
    }
  }

  Future<void> _scrobble(TrackerScrobbleState state) {
    final ctx = _ctx;
    if (ctx == null) return Future.value();
    return _sendScrobble(ctx, state, _timeline.progressPercent, _playbackTargets);
  }

  /// [targets] is passed in rather than read from the field because the terminal
  /// report is sent after [_reset] has already cleared the per-playback state,
  /// on a snapshot of it.
  ///
  /// Progress is deliberately not floored: a session that did start must be
  /// closed even at 0%, or the service keeps showing the item as playing until
  /// its runtime elapses.
  Future<void> _sendScrobble(
    TrackerContext ctx,
    TrackerScrobbleState state,
    double progressPercent,
    List<_PlaybackTarget> targets,
  ) {
    if (targets.isEmpty) return Future.value();
    final now = _clock();
    final sends = <Future<void>>[];
    for (final target in targets) {
      // Still the same account, and still enabled for this library: the user can
      // turn a tracker off or filter the library out mid-playback.
      if (!_bindingIntact(target, 'scrobble ${state.name}')) continue;
      if (!_canReport(target.tracker, ctx.libraryGlobalKey)) continue;
      if (!target.accepts(state, now, debounce: _duplicateStateDebounce)) continue;
      target.record(state, now);
      sends.add(target.channel.enqueue(state, () => _report(target, ctx, state, progressPercent)));
    }
    return sends.isEmpty ? Future.value() : Future.wait(sends);
  }

  Future<void> _report(
    _PlaybackTarget target,
    TrackerContext ctx,
    TrackerScrobbleState state,
    double progressPercent,
  ) async {
    if (!_bindingIntact(target, 'scrobble ${state.name}')) return;
    try {
      await target.tracker.scrobble(ctx, state, progressPercent);
      target.confirmReported(state);
    } catch (e) {
      // A tracker write must never disrupt playback.
      appLogger.d('${target.tracker.name}: scrobble ${state.name} failed', error: e);
    }
  }

  /// False when the tracker was rebound since [target] was pinned: the write
  /// belongs to an account that is no longer bound (and whose client has been
  /// disposed), so it is dropped rather than misfiled onto its replacement.
  bool _bindingIntact(_PlaybackTarget target, String operation) {
    if (!target.bindingChanged) return true;
    appLogger.d('${target.tracker.name}: skipped $operation — account rebound');
    return false;
  }

  Future<void> _reconcileWatchedAfterStop(
    List<_PlaybackTarget> targets,
    TrackerContext ctx,
    double progressPercent,
    _WriteScope scope,
  ) async {
    if (targets.isEmpty) return;
    await Future.wait(
      targets.map((target) async {
        if (!_bindingIntact(target, 'watched reconciliation')) return;
        try {
          await target.tracker.reconcileWatchedAfterStop(ctx, progressPercent);
        } catch (e) {
          appLogger.d('${target.tracker.name}: reconcileWatchedAfterStop failed, queued for retry', error: e);
          await _enqueueWrite(target.tracker, ctx, scope, watched: true);
        }
      }),
    );
  }

  /// Await every queued report so a terminal stop is on the wire before the
  /// caller (screen teardown, app shutdown) moves on.
  Future<void> _settleScrobbles() => Future.wait(_channels.map((channel) => channel.settle()));

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

/// One real-time tracker's report transport.
///
/// Reports are serialised per tracker, not globally: a service may accept one
/// write per user at a time (Simkl locks for 20 seconds and fails whatever
/// queued up behind it), while another has no such rule and must not wait on it.
class _ScrobbleChannel {
  _ScrobbleChannel(this.tracker);

  final RealtimeScrobbleTracker tracker;

  /// Soft bound against a play/pause storm outrunning the remote lock: overflow
  /// sheds the oldest non-terminal report. Terminal stops are never shed, so the
  /// bound is deliberately soft — a burst of episode swaps behind one hung
  /// request queues one stop per item, and each carries that item's own watch
  /// and resume position.
  static const int _maxQueued = 4;

  final List<_QueuedScrobble> _queue = [];
  Future<void>? _drain;

  Future<void> enqueue(TrackerScrobbleState state, Future<void> Function() send) {
    _queue.add(_QueuedScrobble(state, send));
    if (_queue.length > _maxQueued) {
      final victim = _queue.indexWhere((q) => q.state != TrackerScrobbleState.stop);
      if (victim >= 0) _queue.removeAt(victim);
    }
    final draining = _drain;
    if (draining != null) return draining;
    final drain = _drainQueue();
    _drain = drain;
    return drain;
  }

  Future<void> _drainQueue() async {
    try {
      while (_queue.isNotEmpty) {
        await _queue.removeAt(0).send();
      }
    } finally {
      _drain = null;
    }
  }

  /// Await the pending drain, including reports enqueued while it ran.
  Future<void> settle() async {
    var drain = _drain;
    while (drain != null) {
      await drain;
      final next = _drain;
      if (identical(next, drain)) break;
      drain = next;
    }
  }

  void clear() => _queue.clear();
}

/// One real-time tracker pinned to the account it was bound to when the current
/// playback began, plus that playback's report bookkeeping.
///
/// The bookkeeping is per playback *and* per tracker: two services can disagree
/// about whether a report is a duplicate, because their throttle windows are
/// their own.
class _PlaybackTarget {
  _PlaybackTarget(this.channel, this.binding);

  final _ScrobbleChannel channel;

  /// Account identity captured at pin time, compared only by [identical].
  final Object? binding;

  TrackerScrobbleState? _lastState;
  DateTime? _lastSentAt;
  DateTime? _lastSeekAt;
  bool _sessionStarted = false;
  bool _stopConfirmed = false;

  RealtimeScrobbleTracker get tracker => channel.tracker;

  bool get sessionStarted => _sessionStarted;

  /// True once the service accepted this playback's terminal stop. Until it
  /// does, nothing on that side has seen the item finish — so nothing there has
  /// applied the service's own completion rule either.
  bool get stopConfirmed => _stopConfirmed;

  /// Called after a report the service accepted.
  void confirmReported(TrackerScrobbleState state) {
    if (state == TrackerScrobbleState.stop) _stopConfirmed = true;
  }

  bool get bindingChanged => !identical(tracker.scrobbleBinding, binding);

  /// Whether this tracker should hear about [state] now.
  bool accepts(TrackerScrobbleState state, DateTime now, {required Duration debounce}) {
    final policy = tracker.scrobblePolicy;
    if (state == TrackerScrobbleState.seek) {
      final throttle = policy.seekThrottle;
      // A checkpoint only means something while the service believes playback is
      // running, and only as often as the service tolerates.
      if (throttle == null || _lastState != TrackerScrobbleState.start) return false;
      final last = _lastSeekAt;
      return last == null || now.difference(last) >= throttle;
    }
    // A pause/stop with no session behind it would only invent one — that is the
    // rolled-back player attempt, which never got as far as a start.
    if (state != TrackerScrobbleState.start && !_sessionStarted) return false;
    if (_lastState != state) return true;
    final last = _lastSentAt;
    if (last == null) return true;
    final elapsed = now.difference(last);
    if (elapsed < debounce) return false;
    return state != TrackerScrobbleState.start || elapsed >= policy.resendThrottle;
  }

  void record(TrackerScrobbleState state, DateTime now) {
    if (state == TrackerScrobbleState.seek) {
      _lastSeekAt = now;
      // A checkpoint leaves the session playing, so it counts as the latest
      // start: a regular start straight after must not fire again.
      _lastState = TrackerScrobbleState.start;
      _lastSentAt = now;
      return;
    }
    _lastState = state;
    _lastSentAt = now;
    if (state == TrackerScrobbleState.start) _sessionStarted = true;
  }
}

/// Aggregates a container's episodes into the single progress value a
/// series-progress tracker should end up with.
class _ManualSeriesProgress {
  final TrackerContext _base;
  final bool _fallbackToCount;
  int _count = 0;
  int? _maxMappedProgress;

  _ManualSeriesProgress(this._base, {required this._fallbackToCount});

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

/// The profile a watched write belongs to.
///
/// Captured before the write's first await and re-checked at every deferred
/// step: a profile switch mid-write must neither file one profile's retry under
/// another nor push a leftover row through the account that replaced it.
class _WriteScope {
  final String userUuid;
  final int generation;

  const _WriteScope(this.userUuid, this.generation);
}

/// Intent bookkeeping for one remote row, alive only while writes for it are.
class _RowIntents {
  /// Number handed to the most recent write to enter the row's channel.
  int lastIntent = 0;

  /// The newest write that completed, and what it applied. [hasApplied]
  /// distinguishes a completed non-claim write — null progress, covering the row
  /// outright — from nothing having completed at all.
  bool hasApplied = false;
  int lastAppliedIntent = 0;
  int? lastAppliedProgress;

  /// Writes still holding this row; the entry is dropped when it hits zero.
  int pending = 0;
}
