import '../../models/trackers/tracker_context.dart';
import '../settings_service.dart';
import 'tracker_constants.dart';
import 'tracker_id_resolver.dart';
import 'tracker_session.dart';

/// Abstract tracker contract. Every write a tracker performs enters through
/// this interface, and [TrackerCoordinator] is the only caller: playback
/// lifecycle for [RealtimeScrobbleTracker]s, watched-threshold and manual
/// marks for everyone else. Enabled/auth gating lives in [TrackerBase].
abstract class Tracker {
  String get name;

  /// Stable identifier used to persist per-service settings (library filter,
  /// scrobble enabled, etc.).
  TrackerService get service;

  /// True when a watched/unwatched history write may go out right now — the
  /// service's own toggle is on and a session is bound.
  ///
  /// Separate from [RealtimeScrobbleTracker.canReportPlayback] because Trakt
  /// exposes the two as independent user settings; for every other service the
  /// two answers are the same.
  bool get canWriteWatched;

  /// True if this tracker's IDs only come from the Fribb anime mapping
  /// (MAL, AniList). Simkl and Trakt return false because they accept Plex
  /// tvdb/imdb/tmdb directly; when no active tracker needs Fribb we skip the
  /// 5.6 MB mapping download entirely.
  bool get needsFribb;

  /// Identity of the account binding this tracker currently writes through,
  /// compared only by [identical]. Deferred work captures it and re-checks
  /// before writing or queueing, so a rebind — profile switch, disconnect,
  /// reconnect — cannot redirect a write to whichever account replaced it.
  Object? get accountBinding;

  Future<void> initialize();
  Future<void> setEnabled(bool enabled);

  /// Whether an item in the given library should be scrobbled. Applies the
  /// per-tracker whitelist/blacklist — callers pass the Plex library
  /// `serverId:sectionId` globalKey. Null is allowed only when no filter is
  /// configured for this tracker.
  bool shouldScrobbleForLibrary(String? libraryGlobalKey);

  /// [watchedAt] carries the moment the watch actually happened, set only when
  /// replaying a queued write whose original attempt failed. Services that
  /// cannot express a historical timestamp ignore it and record "now".
  Future<void> markWatched(TrackerContext ctx, {DateTime? watchedAt});

  Future<void> markUnwatched(TrackerContext ctx);
}

abstract interface class TrackerRatingSource {
  Future<int?> getRating(TrackerRatingContext ctx);
  Future<void> rate(TrackerRatingContext ctx, int score);
  Future<void> clearRating(TrackerRatingContext ctx);
}

/// A tracker whose history is a per-item record: every movie and episode is
/// added or removed on its own (Simkl, Trakt). The coordinator can therefore
/// hand it one item at a time, including a single episode of a container.
abstract interface class EpisodeHistoryTracker implements Tracker {
  /// A stable identifier for the remote row this tracker's history writes target,
  /// or null when it cannot name one — in which case no write could apply either.
  ///
  /// Queued writes coalesce on this, so it has to stay the same for one row over
  /// time. That rules out both the media-server rating key (server-local, so two
  /// unrelated items collide) and the full outbound id set (which grows an anime
  /// id as soon as some other tracker's mapping is downloaded, leaving rows
  /// already queued unmatchable). Prefer [trackerExternalRowIdentity].
  String? historyRowIdentity(TrackerContext ctx);
}

/// A tracker that keeps one progress counter per series instead of per-episode
/// rows (MAL, AniList). The coordinator aggregates a container's episodes into
/// a single entry update, and unwatching means dropping the whole entry.
abstract interface class SeriesProgressTracker implements Tracker {
  /// Identity of the series entry this tracker would write for [ctx], or null
  /// when it cannot map the item. Episodes sharing an entry id collapse into
  /// one write.
  Object? seriesEntryId(TrackerContext ctx);

  /// The absolute progress a watched write for [ctx] would claim on that entry.
  ///
  /// Because the write is absolute rather than incremental, this is what makes a
  /// deferred retry safe: a claim is monotonic, so two claims about one entry
  /// coalesce to the higher, and a claim already covered by a completed write is
  /// dropped instead of walking the counter backwards.
  int? seriesProgress(TrackerContext ctx);

  Future<void> removeFromList(TrackerContext ctx);
}

/// Playback state reported to trackers that accept real-time progress.
///
/// [seek] is a checkpoint rather than a transition: playback is still running,
/// the position just jumped. A service that has no seek concept declares so
/// through [ScrobblePolicy.seekThrottle] and never receives one.
enum TrackerScrobbleState { start, pause, seek, stop }

/// How closely one service tolerates repeated playback reports. Each rule
/// exists because of a documented server-side constraint, so it lives with the
/// tracker that knows it rather than in the coordinator.
class ScrobblePolicy {
  /// Minimum gap before the same state may be reported again. Guards against a
  /// pause/play storm turning into a burst of identical writes.
  final Duration resendThrottle;

  /// Minimum gap between two seek checkpoints, or null when the service wants
  /// no seek reports at all.
  final Duration? seekThrottle;

  const ScrobblePolicy({required this.resendThrottle, this.seekThrottle});
}

/// Trackers that record playback progress as it happens, not just a terminal
/// watched mark. [TrackerCoordinator] drives these from player lifecycle
/// events (start/resume, pause, seek, stop) with the current progress
/// percentage.
///
/// A real-time tracker owns its own watched semantics for in-player playback:
/// the coordinator deliberately excludes it from the watched-threshold
/// [Tracker.markWatched] fan-out so one watch never produces two writes.
/// Manual, container, offline-replay and external-player marks still go
/// through [Tracker.markWatched].
abstract interface class RealtimeScrobbleTracker implements Tracker {
  /// True when a playback lifecycle report may go out right now.
  bool get canReportPlayback;

  ScrobblePolicy get scrobblePolicy;

  /// Report a playback lifecycle event with the current progress percentage.
  Future<void> scrobble(TrackerContext ctx, TrackerScrobbleState state, double progressPercent);

  /// Called after a terminal [TrackerScrobbleState.stop] whose progress Plezy
  /// counts as watched (the media server's threshold was crossed).
  ///
  /// Services apply their own completion rule to a stop, which can be stricter
  /// than a server threshold the user configured lower. Only the tracker knows
  /// whether its stop already recorded the watch, so it decides here: no-op, or
  /// record it. [progressPercent] is reported as measured — it doubles as the
  /// user's resume position and is never inflated to force a watched state.
  Future<void> reconcileWatchedAfterStop(TrackerContext ctx, double progressPercent);
}

abstract interface class DisposableTrackerClient {
  void dispose();
}

class TrackerRatingUnavailableException implements Exception {
  final String trackerName;

  const TrackerRatingUnavailableException(this.trackerName);

  @override
  String toString() => 'TrackerRatingUnavailableException($trackerName)';
}

/// Shared enabled-state bookkeeping. Subclasses override [hasActiveClient]
/// and [markWatched].
abstract class TrackerBase implements Tracker {
  bool _isInitialized = false;
  bool _isEnabled = false;

  bool get hasActiveClient;

  /// The service's own scrobble toggle ANDed with a bound session. The default
  /// answer for both tracker capabilities; Trakt splits them.
  bool get isEnabledWithSession => _isEnabled && hasActiveClient;

  @override
  bool get canWriteWatched => isEnabledWithSession;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    final settings = await SettingsService.getInstance();
    _isEnabled = settings.read(SettingsService.scrobblePref(service));
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
  }

  @override
  bool shouldScrobbleForLibrary(String? libraryGlobalKey) =>
      SettingsService.instanceOrNull?.isLibraryAllowedForTracker(service, libraryGlobalKey) ?? true;
}

mixin ClientBackedTracker<TClient extends DisposableTrackerClient> on TrackerBase {
  TClient? _client;

  TClient? get client => _client;

  @override
  bool get hasActiveClient => _client != null;

  /// The bound client is replaced on every session rebind (including
  /// disconnect, which binds null), so its identity is the account identity.
  @override
  Object? get accountBinding => client;

  void rebindTrackerClient(
    TrackerSession? session, {
    required TClient Function(TrackerSession session) createClient,
    void Function()? onBeforeBind,
  }) {
    _client?.dispose();
    onBeforeBind?.call();
    _client = session == null ? null : createClient(session);
  }
}
