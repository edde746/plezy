import 'dart:async';
import '../exceptions/media_server_exceptions.dart';
import '../media/ids.dart';

import '../mpv/mpv.dart';

import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../media/media_source_info.dart';
import '../media/watch_progress.dart';
import 'offline_watch_sync_service.dart';
import 'playback_report_session.dart';
import 'settings_service.dart';
import 'track_selection_service.dart';
import '../utils/app_logger.dart';
import '../utils/watch_state_notifier.dart';

/// Tracks playback progress and reports it to the active media server.
///
/// Plex and both MediaBrowser dialects go through the unified
/// [MediaServerClient.reportPlayback*] surface — Plex maps the three signals
/// onto `/:/timeline` updates with appropriate `state`, while MediaBrowser
/// uses the three `/Sessions/Playing*` endpoints.
///
/// Local watched state flips as soon as the position crosses the client's
/// [MediaServerClient.watchedThreshold] (per-server pref on Plex, fixed 90% on
/// MediaBrowser). The *server-side* mark is a separate decision: each backend
/// already marks an item played from a threshold crossing it observes in the
/// reports this tracker sends, so an explicit mark is issued only for sessions
/// that gave it no such crossing (#1287, #1740).
class PlaybackProgressTracker {
  /// Server client for online progress updates (null when offline). Pinned
  /// for the tracker's lifetime — one playback session against the server
  /// that started it; if that server is removed mid-playback, reports fail
  /// and are queued/dropped rather than re-routed.
  final MediaServerClient? client;

  /// Metadata of the media being played
  final MediaItem metadata;

  /// Video player instance
  final Player player;

  /// Whether playback is in offline mode
  final bool isOffline;

  /// Service for queuing offline progress updates
  final OfflineWatchSyncService? offlineWatchService;

  /// Queue the latest progress locally if online reporting fails. Used for
  /// downloaded/local playback where playback can continue without a server.
  final bool queueOnOnlineFailure;

  final String? playMethod;

  /// Backend session ID to echo in progress reports. Jellyfin uses this to
  /// associate `/Sessions/Playing*` calls with a transcoded playback session.
  final String? playSessionId;

  /// Source-level stream metadata for mapping local player track ids back to
  /// Jellyfin stream indexes in playback-progress reports.
  final MediaSourceInfo? mediaInfo;

  /// Invoked once after the item is successfully scrobbled. The player wires
  /// this to mark same-file sibling episodes of a Plex multi-episode file
  /// watched (#1500) — resolved lazily here because the play queue holding
  /// the siblings is created fire-and-forget and may not exist when this
  /// tracker is constructed. Best-effort: failures are logged and never
  /// un-scrobble the primary item.
  final Future<void> Function()? onScrobbled;

  /// Invoked on every paused progress tick. The player wires this to the
  /// Plex transcoder keepalive ping (`/video/:/transcode/universal/ping`) —
  /// timeline reports alone historically have not been enough to stop PMS
  /// from reaping an idle transcode, so official Plex clients send both
  /// while paused. Best-effort; failures are the callee's to swallow.
  final Future<void> Function()? onPausedKeepalive;

  /// Whether non-terminal playback reports reflect real playback output.
  /// Video passes first-frame readiness so a native clock cannot create
  /// progress before any renderer produces a frame. Other callers default to
  /// ready.
  final bool Function()? canReportPlayback;

  /// Whether this item has produced real playback output at least once.
  /// A stopped report still terminates the backend session when false, but
  /// must not turn an unrendered native clock position into watched progress.
  final bool Function()? hasRenderedPlayback;

  /// Whether an off subtitle state is a real decision (viewer or server)
  /// rather than the fallout of a declined cross-item carry. When false, the
  /// off state is not reported as an explicit `-1` stream index — persisting
  /// it would make Jellyfin hand the off back as this item's default on every
  /// later open, latching a metadata mismatch into a server-side choice
  /// (#1785). Callers default to deliberate.
  final bool Function()? subtitleOffIsDeliberate;

  /// Timer for periodic progress updates
  Timer? _progressTimer;

  StreamSubscription<TrackSelection>? _trackSelectionSubscription;

  /// Update interval (default: 10 seconds)
  final Duration updateInterval;

  /// Counts consecutive online progress failures for backoff logic.
  int _consecutiveFailures = 0;

  /// Timer ticks to skip before retrying after failures (exponential backoff).
  int _ticksToSkip = 0;

  /// Whether this playback session considers the item watched locally. Latched
  /// on the first observed threshold crossing, delivered to the server or not.
  bool _scrobbled = false;

  /// The backend has received a report from this session at a position that is
  /// both strictly positive and below [MediaServerClient.watchedThreshold], so
  /// a later at-or-above report reads as a crossing.
  ///
  /// Position zero does not count. Verified against PMS 1.43: a session
  /// reporting `time=0` and then the full duration is not marked played, while
  /// the same session starting at `time=1000` is. Plex treats a zero position
  /// as session initialisation rather than progress, so it has nothing to
  /// cross from. (Retention of a resume point is a separate, higher bar —
  /// reports at 5s and 30s arm the crossing without persisting an offset.)
  bool _deliveredBelow = false;

  /// The backend has received an at-or-above-threshold report while already
  /// holding a sub-threshold offset — it observed the crossing and marked the
  /// item itself, so an explicit mark would record the same watch twice
  /// (#1287 Jellyfin, #1740 Plex).
  bool _serverObservedCrossing = false;

  /// The terminal stopped report has been delivered; no further report can
  /// change what the backend saw.
  bool _sessionEnded = false;

  /// The in-flight [_settleServerMark], so the terminal stopped report can wait
  /// for the explicit mark it triggers instead of leaving it racing teardown.
  Future<void>? _pendingSettle;

  /// The server-side mark is resolved: either the backend marked the item from
  /// its own crossing, or we issued the explicit mark. Reset on failure so the
  /// next delivered report retries.
  bool _serverMarkSettled = false;

  /// The post-watch hook has run; it fires at most once per tracker.
  bool _scrobbledHookRan = false;

  /// Delivery provenance keyed by the exact snapshot handed to
  /// [PlaybackReportSession]. Acceptance alone cannot identify delivery
  /// because startup heartbeats may be dropped while still completing true.
  final Map<PlaybackReportSnapshot, bool> _deliveredProgressAcknowledgements = Map.identity();

  /// Whether this backend reporting session has successfully opened.
  bool _hasDeliveredStart = false;

  /// Whether a delivered stopped report reached a backend session able to act
  /// on it. MediaBrowser drops a stop for a session it never opened, so both
  /// the position it would persist and the watch it would record are lost.
  bool _stoppedReportActedOn = false;

  /// Whether the delivered stopped report persisted its position.
  bool _stoppedProgressServerAcknowledged = false;

  /// Allows the first persisted Progress after a MediaBrowser Started to
  /// upgrade local provenance even when the position delta is throttled.
  bool _lastProgressNotificationServerAcknowledged = false;

  /// The exact report-derived watched patch that a settled server-side watch
  /// can promote. Cleared once promoted so promotion happens at most once.
  WatchPatchId? _watchedPatchId;

  /// Whether the final stopped progress event was already emitted locally.
  bool _stopProgressNotified = false;

  /// The server explicitly terminated this playback session (#1916). While
  /// set, paused heartbeats stay closed (the report session is terminal) and
  /// the paused transcode keepalive is suppressed; the next playing report
  /// clears it and legitimately opens a fresh server session.
  bool _serverTerminatedSession = false;

  Future<void>? _stoppedProgressFuture;

  Duration? _lastProgressNotifiedPosition;
  Duration? _lastReportablePosition;

  static const Duration _progressNotifyDelta = Duration(seconds: 30);

  /// Built in the constructor body so the delivery callback can bind `this`.
  late final PlaybackReportSession? _reportSession;

  PlaybackProgressTracker({
    required this.client,
    required this.metadata,
    required this.player,
    this.isOffline = false,
    this.offlineWatchService,
    this.queueOnOnlineFailure = false,
    this.playMethod,
    this.playSessionId,
    this.mediaInfo,
    this.onScrobbled,
    this.onPausedKeepalive,
    this.canReportPlayback,
    this.hasRenderedPlayback,
    this.subtitleOffIsDeliberate,
    this.updateInterval = const Duration(seconds: 10),
  }) : assert(!isOffline || offlineWatchService != null, 'offlineWatchService is required when isOffline is true'),
       assert(isOffline || client != null, 'client is required when isOffline is false') {
    final reportingClient = client;
    _reportSession = isOffline || reportingClient == null
        ? null
        : PlaybackReportSession(
            client: reportingClient,
            itemId: metadata.id,
            playSessionId: playSessionId,
            playMethod: playMethod,
            onDelivered: _onReportDelivered,
          );
  }

  /// Starts the periodic report timer and sends the initial report.
  ///
  /// [initialPosition] and [initialDuration] override the live player state
  /// for that initial report only. Music binds a new tracker the instant a
  /// gapless advance is announced, when `player.state.position`/`duration`
  /// still hold the *outgoing* track's values — reporting those told Plex the
  /// new track was already at ~100%, which recorded a play (and a Last.fm
  /// scrobble) at track start on top of the real one (#1849). Callers that
  /// know where the item truly starts pass it here; timer ticks always read
  /// live state.
  void startTracking({Duration? initialPosition, Duration? initialDuration}) {
    if (_progressTimer != null) {
      appLogger.w('Progress tracking already started');
      return;
    }

    if (!isOffline) {
      _trackSelectionSubscription = player.streams.track.listen((_) {
        if (!player.state.isActive && (_reportSession?.isIdle ?? true)) return;
        final state = player.state.isActive ? 'playing' : 'paused';
        unawaited(_sendProgress(state));
      });
    }

    // Send initial progress immediately (don't wait for first timer tick)
    if (player.state.isActive) {
      _sendProgress('playing', positionOverride: initialPosition, durationOverride: initialDuration);
    }

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      // Skip ticks when backing off after consecutive failures to avoid
      // flooding the network with doomed requests during an outage.
      if (_ticksToSkip > 0) {
        _ticksToSkip--;
        return;
      }
      if (player.state.isActive) {
        _sendProgress('playing');
      } else {
        // Report every tick while paused too — official clients do the
        // same (~10s); the timeline heartbeat is what keeps the server
        // session and its transcoder from being reaped during a long
        // pause (#1520). Not after the server terminated the session:
        // pinging the reaped transcoder would only produce doomed requests.
        _sendProgress('paused');
        if (!_serverTerminatedSession) {
          final keepalive = onPausedKeepalive;
          if (keepalive != null) unawaited(keepalive());
        }
      }
    });

    appLogger.d('Started progress tracking (interval: ${updateInterval.inSeconds}s, offline: $isOffline)');
  }

  void stopTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _trackSelectionSubscription?.cancel();
    _trackSelectionSubscription = null;
    appLogger.d('Stopped progress tracking');
  }

  /// [state] can be 'playing', 'paused', or 'stopped'. The overrides exist
  /// for reports that must not read live player state — a terminal report
  /// retried after stop() has released the native pipeline would otherwise
  /// read a reset position/duration (see the zero-duration guard below).
  Future<void> sendProgress(String state, {Duration? positionOverride, Duration? durationOverride}) async {
    await _sendProgress(state, positionOverride: positionOverride, durationOverride: durationOverride);
  }

  Future<void> sendStoppedProgressOnce({Duration? positionOverride}) {
    final existing = _stoppedProgressFuture;
    if (existing != null) return existing;
    final future = sendProgress('stopped', positionOverride: positionOverride);
    _stoppedProgressFuture = future;
    return future;
  }

  /// Whether the terminal stopped report actually reached the backend.
  ///
  /// [sendStoppedProgressOnce] resolving is not delivery — the report is
  /// best-effort and its transport errors are swallowed. Callers that must
  /// retry a failed terminal report (the TV background suspend, whose whole
  /// purpose is closing the server session, #1911) key on this instead.
  /// Offline trackers have no backend session and report `true`.
  bool get stoppedReportDelivered => _reportSession?.isStopped ?? true;

  void resumeAfterStoppedReport() {
    _stoppedProgressFuture = null;
    _reportSession?.resetAfterStop();
    // A server-side termination latched against the old session does not
    // apply to the new one (and its fresh transcode needs its keepalive).
    _serverTerminatedSession = false;
    // A re-armed session is a new server-side session: backends only act on a
    // threshold crossing observed within one, so it must earn its own
    // below-threshold report before we can rely on it again.
    _deliveredBelow = false;
    _serverObservedCrossing = false;
    _sessionEnded = false;
    _hasDeliveredStart = false;
    _stoppedReportActedOn = false;
    _stoppedProgressServerAcknowledged = false;
  }

  /// The server killed this playback session out from under the client
  /// (Plex admin stop, paused-too-long auto-termination). Continuing the
  /// heartbeat loop would re-register the session on PMS as a zombie row the
  /// admin can no longer clear (#1916), so the local reporting session is
  /// closed with one final stopped report at the current playhead — verified
  /// against PMS 1.43 to remove the session row. No user-facing message and
  /// no forced player stop: buffered playback drains on its own and its
  /// eventual stall or exit rides the existing error/teardown paths.
  ///
  /// Deliberately not a failure: no backoff and no offline-queue write —
  /// the server received the report and answered it.
  void _handleServerTermination(PlaybackSessionTerminatedException e) {
    if (_serverTerminatedSession) return;
    _serverTerminatedSession = true;
    appLogger.w('Closing reporting session for ${metadata.id}: terminated server-side', error: e);
    unawaited(sendStoppedProgressOnce());
  }

  Future<void> _sendProgress(String state, {Duration? positionOverride, Duration? durationOverride}) async {
    Duration? attemptedPosition;
    Duration? attemptedDuration;
    try {
      // A playing report after a server-side termination is real consumption
      // again (unpause, or playback still draining its buffer): re-arm so it
      // opens a fresh, honest server session. Paused heartbeats never re-arm —
      // that is exactly what created the zombie.
      if (state == 'playing' && _serverTerminatedSession) {
        resumeAfterStoppedReport();
      }
      final canReport = canReportPlayback?.call() ?? true;
      final hasRenderedOutput = hasRenderedPlayback?.call() ?? canReport;
      if (state != 'stopped' && !canReport) return;
      final isSuppressedStop = state == 'stopped' && !canReport;
      final duration = durationOverride ?? player.state.duration;
      final positionSource = isSuppressedStop
          ? _lastReportablePosition ?? Duration(milliseconds: metadata.viewOffsetMs ?? 0)
          : positionOverride ?? player.state.position;
      final position = _clampPosition(positionSource, duration);
      if (canReport && hasRenderedOutput) _lastReportablePosition = position;
      final canCommitStoppedProgress = hasRenderedOutput && (!isSuppressedStop || _lastReportablePosition != null);
      attemptedPosition = position;
      attemptedDuration = duration;

      // Don't send progress if no duration (not ready)
      if (duration.inMilliseconds == 0) {
        return;
      }

      if (isOffline) {
        // There is no backend session to terminate offline. Do not turn a
        // resume offset into a fresh queued update when this run rendered
        // nothing.
        if (!canCommitStoppedProgress) return;
        await _sendOfflineProgress(position, duration);
        _notifyProgressIfNeeded(position, duration, force: state == 'stopped', serverAcknowledged: false);
      } else if (state == 'stopped') {
        // Stopped must complete before disposal. When reporting was disabled
        // by a fatal error, use the last position captured while output was
        // healthy rather than the still-advancing native media clock.
        final accepted = await _sendOnlineProgress(state, position, duration, allowScrobble: canCommitStoppedProgress);
        // The explicit mark is resolved at session end, so it has to ride the
        // terminal report's future — callers that await the stop before tearing
        // the player down would otherwise drop it.
        await _pendingSettle;
        _resetBackoff();
        if (accepted && canCommitStoppedProgress) {
          _notifyProgressIfNeeded(
            position,
            duration,
            force: true,
            serverAcknowledged: _stoppedProgressServerAcknowledged,
          );
        }
      } else {
        // Fire-and-forget for playing/paused — avoid blocking the Dart event loop
        unawaited(
          _sendOnlineProgress(state, position, duration)
              .then((_) {
                _resetBackoff();
              })
              .catchError((Object e) {
                if (e is PlaybackSessionTerminatedException) {
                  _handleServerTermination(e);
                  return;
                }
                _recordProgressFailure(e);
                unawaited(_queueOnlineFailureProgress(position, duration));
              }),
        );
      }
    } catch (e) {
      if (!isOffline) {
        _recordProgressFailure(e);
        await _queueOnlineFailureProgress(
          attemptedPosition ?? player.state.position,
          attemptedDuration ?? player.state.duration,
        );
      } else {
        appLogger.d('Failed to send progress update (non-critical)', error: e);
      }
    }
  }

  Duration _clampPosition(Duration position, Duration duration) {
    if (duration.inMilliseconds <= 0) return position;
    if (position.isNegative) return Duration.zero;
    if (position > duration) return duration;
    return position;
  }

  Future<void> _queueOnlineFailureProgress(Duration position, Duration duration) async {
    if (!queueOnOnlineFailure || offlineWatchService == null) return;
    if (duration.inMilliseconds == 0) return;
    try {
      await _sendOfflineProgress(_clampPosition(position, duration), duration);
    } catch (e) {
      appLogger.d('Failed to queue fallback progress after online report failure', error: e);
    }
  }

  void _recordProgressFailure(Object e) {
    _consecutiveFailures++;
    // Exponential backoff: skip 1, 2, 4, 8... ticks (capped at 6 ≈ 60s)
    _ticksToSkip = (1 << (_consecutiveFailures - 1)).clamp(1, 6);
    appLogger.d(
      'Progress update failed ($_consecutiveFailures consecutive), '
      'skipping next $_ticksToSkip tick(s)',
      error: e,
    );
  }

  void _resetBackoff() {
    if (_consecutiveFailures > 0) {
      _consecutiveFailures = 0;
      _ticksToSkip = 0;
    }
  }

  void _notifyProgressIfNeeded(
    Duration position,
    Duration duration, {
    bool force = false,
    required bool serverAcknowledged,
  }) {
    if (_scrobbled) return;
    if (position.inMilliseconds <= 0 || duration.inMilliseconds <= 0) return;
    if (force) {
      if (_stopProgressNotified) return;
      _stopProgressNotified = true;
    } else {
      final last = _lastProgressNotifiedPosition;
      if (last != null && (position - last).abs() < _progressNotifyDelta) {
        if (!serverAcknowledged || _lastProgressNotificationServerAcknowledged) return;
      }
    }

    _lastProgressNotifiedPosition = position;
    _lastProgressNotificationServerAcknowledged = serverAcknowledged;
    WatchStateNotifier().notifyProgress(
      item: metadata,
      cacheServerId: client?.cacheServerId,
      viewOffset: position.inMilliseconds,
      duration: duration.inMilliseconds,
      watchedThreshold: client?.watchedThreshold ?? 0.9,
      serverAcknowledged: serverAcknowledged,
    );
  }

  /// Send progress update to the active server through the unified
  /// [MediaServerClient.reportPlayback*] surface.
  Future<bool> _sendOnlineProgress(
    String state,
    Duration position,
    Duration duration, {
    bool allowScrobble = true,
  }) async {
    final c = client;
    final session = _reportSession;
    if (c == null || session == null) return false;

    final snapshot = PlaybackReportSnapshot(
      state: state,
      position: position,
      duration: duration,
      resolveStreamSelection: state == 'stopped'
          ? _currentStreamSelectionForStopped
          : _currentStreamSelectionForProgress,
    );
    final accepted = await session.report(snapshot);

    if (accepted && allowScrobble) {
      await _maybeScrobble(c, position, duration);
    }

    if (!snapshot.isStopped) {
      final serverAcknowledged = _deliveredProgressAcknowledgements.remove(snapshot);
      if (serverAcknowledged != null) {
        _notifyProgressIfNeeded(position, duration, serverAcknowledged: serverAcknowledged);
      }
    }
    return accepted;
  }

  PlaybackStreamSelection _currentStreamSelectionForStopped() {
    final info = mediaInfo;
    return info == null ? PlaybackStreamSelection.none : PlaybackStreamSelection(mediaSourceId: info.mediaSourceId);
  }

  /// Records what the backend actually received, then re-evaluates whether the
  /// explicit mark is still needed.
  ///
  /// Every supported backend marks an item played from a watched-threshold *crossing*
  /// observed inside a single reporting session — a report below the threshold
  /// followed by one at or above it. Absolute position is not enough: a session
  /// whose every report sits above the threshold, or one resuming past it, is
  /// never marked server-side.
  void _onReportDelivered(PlaybackReportSnapshot snapshot) {
    final c = client;
    // The same backend as the client's, but read from the item so the
    // classification matches the pattern already used for track selection
    // below and does not depend on a client method.
    final persistsPositionOnEveryReport = !metadata.backend.usesMediaBrowserApi;
    if (snapshot.isStopped) {
      // MediaBrowser needs a successfully opened session before Stopped can
      // persist position or record the watch; Plex timeline reports are
      // independent.
      _stoppedReportActedOn = persistsPositionOnEveryReport || _hasDeliveredStart;
      _stoppedProgressServerAcknowledged = _stoppedReportActedOn;
      // A backend that marks played from the stop has now done so, so a
      // crossing latched earlier this session is no longer a write owed to
      // it. Ordering runs both ways -- the crossing can latch before this
      // stop or from it -- so _settleServerMark promotes on the other path.
      if (_stoppedReportActedOn && (c?.marksWatchedOnPlaybackStopped ?? false)) _promoteWatchedPatch();
    } else {
      final isStarted = !_hasDeliveredStart;
      _hasDeliveredStart = true;
      // A MediaBrowser `Started` saves play count and last-played date but
      // deliberately not the position, so it cannot acknowledge an offset.
      _deliveredProgressAcknowledgements[snapshot] = !isStarted || persistsPositionOnEveryReport;
    }

    final threshold = c?.watchedThreshold;
    // isWatchedProgress reports false for an unknown duration; treating that as
    // a below-threshold report would wrongly arm the crossing.
    if (threshold == null || snapshot.duration.inMilliseconds <= 0) return;
    if (snapshot.isStopped) _sessionEnded = true;
    if (isWatchedProgress(
      positionMs: snapshot.position.inMilliseconds,
      durationMs: snapshot.duration.inMilliseconds,
      threshold: threshold,
    )) {
      if (_deliveredBelow) _serverObservedCrossing = true;
    } else if (snapshot.position > Duration.zero) {
      // Zero is session initialisation, not progress: the backend has nothing
      // to cross from, so it will never mark the item off such a session.
      _deliveredBelow = true;
    }
    // _settleServerMark swallows its own failures, so this never escapes.
    final settle = _settleServerMark(client);
    _pendingSettle = settle;
    unawaited(settle);
  }

  /// Issues the explicit server-side mark, but only once it is clear the
  /// backend will not record the watch itself.
  ///
  /// Called after the local crossing latches and again on every delivered
  /// report — between them those cover every transition that can change the
  /// answer.
  Future<void> _settleServerMark(MediaServerClient? c) async {
    if (c == null || !_scrobbled || _serverMarkSettled) return;
    // Backends that mark played from the playback-stopped report do it there,
    // and the terminal stop is always sent. An explicit mark on top would
    // double-scrobble through the Jellyfin Trakt plugin (#1287).
    if (c.marksWatchedOnPlaybackStopped) {
      _serverMarkSettled = true;
      // Only once the stop actually reached an open session: settling happens
      // when the crossing latches, which can be before the stop is sent, and
      // until it lands the watch is still owed to the server.
      if (_stoppedReportActedOn) _promoteWatchedPatch();
      await _runScrobbledHook();
      return;
    }
    // The backend observed the crossing and marked the item itself. Marking
    // again records the same watch twice (#1740).
    if (_serverObservedCrossing) {
      _serverMarkSettled = true;
      // Delivery is proven: the crossing was assembled from two delivered
      // reports, so nothing is owed.
      _promoteWatchedPatch();
      await _runScrobbledHook();
      return;
    }
    // Never mark while the session is still live. A crossing can appear at any
    // point until the stop: even a session that began past the threshold can
    // seek back below it and cross again, and the backend records that crossing
    // itself. No eager decision can know a future rewind won't create one.
    // Marking eagerly and then hitting that path reproduces the very
    // double-count this guards against — verified against PMS 1.43, where an
    // explicit mark followed by an in-session crossing leaves viewCount at 2
    // with a Play History row (#1740).
    //
    // A session that only ever sent its stop reaches this already ended, so the
    // common crossing-less case is still resolved immediately.
    if (!_sessionEnded) return;
    // The session is over and the backend never saw a crossing: a resume that
    // stayed past the threshold, one that only sent its stop, or one whose
    // crossing was coalesced away and never re-delivered. It will not mark this
    // itself.
    _serverMarkSettled = true;
    try {
      await c.markWatched(metadata);
    } catch (e) {
      appLogger.w('Failed to mark ${metadata.id} watched', error: e);
      _serverMarkSettled = false; // Retry on the next delivered report.
      return;
    }
    _promoteWatchedPatch();
    await _runScrobbledHook();
  }

  /// Settle the report-derived watched patch: the server has taken this watch,
  /// so the overlay entry is no longer a write owed to it and a later
  /// authoritative read may supersede it.
  ///
  /// Without this a crossing pins `watched` for the whole session — the read
  /// that would clear it cannot, because an unacknowledged patch is never
  /// suppressed. Idempotent: the id is cleared so repeated settle paths and
  /// the delivery callback cannot promote twice.
  void _promoteWatchedPatch() {
    final patchId = _watchedPatchId;
    if (patchId == null) return;
    _watchedPatchId = null;
    WatchPatchPromotionNotifier().promote(patchId);
  }

  /// Runs the post-watch hook once, after the item's own watched state is
  /// accounted for server-side.
  ///
  /// Its production caller marks same-file sibling episodes (#1500) with real
  /// server writes, so it must never run ahead of the primary: a resumed
  /// session whose explicit mark is still pending — or has just failed — would
  /// otherwise leave the siblings watched and the episode actually played
  /// unwatched. Hook failures are logged and never un-settle the mark.
  Future<void> _runScrobbledHook() async {
    final hook = onScrobbled;
    if (hook == null || _scrobbledHookRan) return;
    _scrobbledHookRan = true;
    try {
      await hook();
    } catch (e) {
      appLogger.w('Post-scrobble hook failed for ${metadata.id}', error: e);
    }
  }

  Future<void> _maybeScrobble(MediaServerClient c, Duration position, Duration duration) async {
    if (_scrobbled ||
        !isWatchedProgress(
          positionMs: position.inMilliseconds,
          durationMs: duration.inMilliseconds,
          threshold: c.watchedThreshold,
        )) {
      return;
    }
    final percent = position.inMilliseconds / duration.inMilliseconds;
    final threshold = c.watchedThreshold;
    _scrobbled = true;
    // Local state flips on the observed crossing, whether or not the backend
    // received that particular report. The server-side mark is a separate
    // question, answered by _settleServerMark once delivery is known.
    _watchedPatchId = c.notifyWatchedFromPlaybackSession(metadata);
    appLogger.d(
      'Watched ${metadata.id} (${(percent * 100).toStringAsFixed(0)}% >= ${(threshold * 100).toStringAsFixed(0)}%)',
    );
    // The #1500 sibling hook runs from _settleServerMark, once this item's own
    // watched state is accounted for server-side.
    await _settleServerMark(c);
  }

  Future<PlaybackStreamSelection> _currentStreamSelectionForProgress() async {
    final info = mediaInfo;
    if (info == null) {
      return PlaybackStreamSelection.none;
    }

    if (!await _shouldReportTrackSelections()) {
      return PlaybackStreamSelection(mediaSourceId: info.mediaSourceId);
    }

    return PlaybackStreamSelection(
      mediaSourceId: info.mediaSourceId,
      audioStreamIndex: _currentAudioStreamIndex(info),
      subtitleStreamIndex: _currentSubtitleStreamIndex(info),
    );
  }

  Future<bool> _shouldReportTrackSelections() async {
    try {
      final settings = await SettingsService.getInstance();
      return settings.read(SettingsService.rememberTrackSelections);
    } catch (e) {
      appLogger.d('Could not read track-selection persistence setting; reporting selected streams', error: e);
      return true;
    }
  }

  int? _currentAudioStreamIndex(MediaSourceInfo info) {
    final playerAudioTracks = player.state.tracks.audio.where((t) => t.id != 'auto' && t.id != 'no').toList();
    if (metadata.backend.usesMediaBrowserApi &&
        (info.audioTracks.any((track) => track.isExternal) || playerAudioTracks.length <= 1)) {
      final selectedSourceTrack = _selectedSourceAudioTrack(info);
      if (selectedSourceTrack != null) return selectedSourceTrack.id;
    }

    final track = player.state.track.audio;
    if (track == null) return null;

    final ordinal = playerAudioTracks.indexOf(track);
    if (ordinal >= 0 && ordinal < info.audioTracks.length) return info.audioTracks[ordinal].id;

    final matched = findPlexTrackForMpvAudio(track, info.audioTracks, allMpvTracks: player.state.tracks.audio);
    if (matched != null) return matched.id;

    final parsedId = int.tryParse(track.id);
    if (parsedId != null && info.audioTracks.any((t) => t.id == parsedId)) return parsedId;

    return null;
  }

  MediaAudioTrack? _selectedSourceAudioTrack(MediaSourceInfo info) {
    for (final track in info.audioTracks) {
      if (track.selected) return track;
    }
    final defaultIndex = info.defaultAudioStreamIndex;
    if (defaultIndex == null) return null;
    for (final track in info.audioTracks) {
      if (track.id == defaultIndex) return track;
    }
    return null;
  }

  int? _currentSubtitleStreamIndex(MediaSourceInfo info) {
    final track = player.state.track.subtitle;
    if (track == null || track.id == 'no') {
      // An off that merely fell out of a declined carry is withheld rather
      // than persisted as an explicit -1 (see [subtitleOffIsDeliberate]).
      return (subtitleOffIsDeliberate?.call() ?? true) ? -1 : null;
    }

    if (track.isExternal && track.uri != null) {
      for (final mediaTrack in info.subtitleTracks) {
        final key = mediaTrack.key;
        if (mediaTrack.isExternal && key != null && track.uri!.contains(key)) {
          return mediaTrack.id;
        }
      }
    }

    final ordinal = player.state.tracks.subtitle.where((t) => t.id != 'auto' && t.id != 'no').toList().indexOf(track);
    if (ordinal >= 0 && ordinal < info.subtitleTracks.length) return info.subtitleTracks[ordinal].id;

    final matched = findPlexTrackForMpvSubtitle(track, info.subtitleTracks, allMpvTracks: player.state.tracks.subtitle);
    if (matched != null) return matched.id;

    final parsedId = int.tryParse(track.id);
    if (parsedId != null && info.subtitleTracks.any((t) => t.id == parsedId)) return parsedId;

    return null;
  }

  /// Queue progress update locally (offline mode)
  Future<void> _sendOfflineProgress(Duration position, Duration duration) async {
    final serverId = metadata.serverId;
    if (serverId == null) {
      appLogger.w('Cannot queue offline progress: serverId is null');
      return;
    }

    await offlineWatchService!.queueProgressUpdate(
      serverId: ServerId(serverId),
      itemId: metadata.id,
      viewOffset: position.inMilliseconds,
      duration: duration.inMilliseconds,
    );

    final percent = (position.inMilliseconds / duration.inMilliseconds * 100);
    appLogger.d(
      'Offline progress queued: ${position.inSeconds}s / ${duration.inSeconds}s (${percent.toStringAsFixed(1)}%)',
    );
  }

  void dispose() {
    stopTracking();
  }
}
