import 'dart:async';

import '../../media/live_tv_support.dart';
import '../../media/live_tv_timeline.dart';
import '../../media/media_source_info.dart';
import '../../models/livetv_capture_buffer.dart';
import '../../mpv/player/player_streams.dart';
import 'live_tv_session_args.dart';
import 'live_timeline_report.dart';

class _LiveClockOpen {
  _LiveClockOpen({required this.generation, required this.targetEpoch});

  final int generation;
  final double targetEpoch;
  final Completer<bool> result = Completer<bool>();
  int? sourceId;
  bool canceled = false;
}

/// What the player has reported so far about one MPV source that no clock
/// open has claimed yet. The `loadfile` reply that names the source and the
/// source's own events travel on independent channels, so readiness or
/// failure can land before the open learns its id.
class _UnclaimedSourceEvents {
  Duration? readyPosition;
  bool failed = false;
}

/// Mutable runtime state for one live TV playback: the current
/// [LiveTvPlaybackSession] protocol handle, the timeline heartbeat
/// machinery, the capture buffer used for time-shifting, and the
/// retry/fallback ladder.
///
/// One instance lives on the player screen (inert when the screen plays
/// VOD); the live-TV part file owns all the logic and reads/writes through
/// this object so the session state has a single boundary and lifetime.
/// Protocol state (tune outputs, stream URLs, per-backend reporting) lives
/// on [session] — adopting a new session via [adoptSession] is the single
/// point where a (re)tune's outputs become current.
class LiveTvSessionState {
  LiveTvSessionState(LiveTvSessionArgs? args)
    : channelIndex = args?.currentChannelIndex ?? -1,
      channelName = args?.channel.displayName;

  int channelIndex;
  String? channelName;

  /// Backend-neutral protocol handle for the playing channel. Null until
  /// the first `startPlayback` lands.
  LiveTvPlaybackSession? session;

  Timer? timelineTimer;
  int timelineGeneration = 0;
  final Stopwatch playbackElapsed = Stopwatch();
  late LiveTimelineReportQueue timelineReports = LiveTimelineReportQueue();

  /// Current seekable window. Seeded from [session] on adoption, then
  /// refreshed by timeline heartbeat responses.
  CaptureBuffer? captureBuffer;

  /// Server-side subtitle track the live stream is currently delivering
  /// (Plex burn), or null when subtitles are off. Owned here because every
  /// stream rebuild (time-shift seek, retry) must re-apply it. Reset by
  /// [adoptSession] — stream ids are tune-scoped — and re-established by
  /// flows that carry the choice across sessions (retry re-maps via
  /// [remapSubtitleSelection]).
  MediaSubtitleTrack? selectedSubtitle;

  /// Legacy player-zero epoch estimate. Request/readiness pairing and server
  /// origins can update it, but only [playbackPosition] describes validity.
  double streamStartEpoch = 0;

  /// Bumped on every stream open. A heartbeat snapshots it when dispatched so
  /// a response describing a stream that has since been replaced cannot
  /// re-anchor the clock of its replacement.
  int streamGeneration = 0;

  int _nextClockGeneration = 0;
  int? _latestClockGeneration;
  int? activeClockSourceId;
  double? pendingStreamEpoch;
  double? get pendingTargetEpoch => pendingStreamEpoch;
  LiveTvSeekStatus seekStatus = LiveTvSeekStatus.idle;
  double? _lastPlaybackEpoch;
  bool _unidentifiedStreamEstimate = false;
  Duration? _lastObservedPosition;

  /// The request/first-position pairing and Plex origin are estimates until
  /// their relationship to the rendered media clock is independently known.
  LiveTvPlaybackPosition playbackPosition(Duration position) {
    if ((activeClockSourceId != null || _unidentifiedStreamEstimate) && pendingStreamEpoch == null) {
      final epoch = streamStartEpoch + position.inMilliseconds / 1000.0;
      if (epoch.isFinite) {
        _lastPlaybackEpoch = epoch;
        return LiveTvPlaybackPosition(epoch: epoch, accuracy: LiveTvTimeAccuracy.estimated, active: true);
      }
    }
    return LiveTvPlaybackPosition(
      epoch: _lastPlaybackEpoch,
      accuracy: _lastPlaybackEpoch == null ? LiveTvTimeAccuracy.unknown : LiveTvTimeAccuracy.stale,
    );
  }

  /// Invalidate the active mapping before a replacement or discontinuity.
  /// Retain only the last sampled playback epoch, never a failed request.
  void invalidatePlayback() {
    cancelClockOpens();
    activeClockSourceId = null;
    _unidentifiedStreamEstimate = false;
    _lastObservedPosition = null;
    seekStatus = LiveTvSeekStatus.idle;
  }

  /// Non-native players expose no load-bound source ID. Preserve their
  /// legacy seek coordinate as an explicitly unverified estimate; they can
  /// never establish confirmed broadcast position from open completion.
  void estimateUnidentifiedStream(double epoch, Duration position) {
    streamStartEpoch = epoch - position.inMilliseconds / 1000.0;
    _lastPlaybackEpoch = epoch;
    _unidentifiedStreamEstimate = true;
    _lastObservedPosition = position;
    seekStatus = LiveTvSeekStatus.idle;
  }

  /// Live seeks replace sources; a backwards jump within the same source is
  /// a timestamp discontinuity, not a new valid anchor. Allow 2s of reporting
  /// jitter. Forward gaps cannot be distinguished from missing events here.
  bool observePlayerPosition(Duration position) {
    if (activeClockSourceId == null && !_unidentifiedStreamEstimate) return false;
    final previous = _lastObservedPosition;
    if (previous != null && position < previous - const Duration(seconds: 2)) {
      invalidatePlayback();
      return true;
    }
    _lastObservedPosition = position;
    playbackPosition(position);
    return false;
  }

  final Map<int, _LiveClockOpen> _clockOpensBySource = {};
  final Map<int, _LiveClockOpen> _clockOpensByGeneration = {};

  /// Recent source events no open has claimed, keyed by source id in arrival
  /// order and bounded so opens that never register (live-edge re-opens,
  /// VOD on the same player) cannot grow it.
  final Map<int, _UnclaimedSourceEvents> _unclaimedSources = {};
  static const int _maxUnclaimedSources = 8;

  /// Fallback level for live TV stream errors (mirrors Plex web client
  /// behavior). 0 = directStream+directStreamAudio, 1 = no directStream,
  /// 2 = no DS + no DS audio.
  int fallbackLevel = 0;
  bool retrying = false;
  Object? _retryOwner;

  Object beginRetry() {
    retrying = true;
    return _retryOwner = Object();
  }

  bool ownsRetry(Object owner) => identical(_retryOwner, owner);

  void finishRetry(Object owner) {
    if (!ownsRetry(owner)) return;
    _retryOwner = null;
    retrying = false;
  }

  void cancelRetry() {
    _retryOwner = null;
    retrying = false;
  }

  bool retryFailed = false;

  /// Whether the timeline heartbeat should restart when the app resumes
  /// from the background (it is suspended on hide).
  bool resumeTimelineOnResume = false;

  /// A non-resumable live session was stopped while the TV app was hidden.
  /// The player route is closed instead of attempting to reuse that session.
  bool exitOnResume = false;

  /// Register an offset-based MPV open before dispatching `loadfile`. The
  /// returned generation is the handle the caller binds to the source id the
  /// load reports ([bindClockOpen]); until then the open is unbound and no
  /// source event can reach it. Every earlier open is superseded.
  int beginClockOpen(num targetEpoch) {
    activeClockSourceId = null;
    seekStatus = LiveTvSeekStatus.opening;
    final previousOpens = <_LiveClockOpen>{..._clockOpensByGeneration.values, ..._clockOpensBySource.values};
    for (final open in previousOpens) {
      open.canceled = true;
      if (!open.result.isCompleted) open.result.complete(false);
    }
    _clockOpensByGeneration.clear();
    _clockOpensBySource.clear();

    final open = _LiveClockOpen(generation: ++_nextClockGeneration, targetEpoch: targetEpoch.toDouble());
    _clockOpensByGeneration[open.generation] = open;
    _latestClockGeneration = open.generation;
    pendingStreamEpoch = targetEpoch.toDouble();
    return open.generation;
  }

  /// Bind [generation] to the MPV source its `loadfile` reply named. Source
  /// events that already arrived for [sourceId] apply immediately, so a
  /// readiness or failure report that beat the reply is not lost. Returns
  /// whether the open is still live and now keyed by the source.
  bool bindClockOpen(int generation, int sourceId) {
    final open = _clockOpensByGeneration[generation];
    if (open == null) return false;
    open.sourceId = sourceId;
    if (open.canceled) {
      _unclaimedSources.remove(sourceId);
      return false;
    }
    _clockOpensBySource[sourceId] = open;
    final observed = _unclaimedSources.remove(sourceId);
    if (observed == null) return true;
    if (observed.failed) {
      _failClockOpen(open);
      return false;
    }
    final readyPosition = observed.readyPosition;
    if (readyPosition != null) {
      calibrateClockSource(PlayerSourceReady(sourceId: sourceId, position: readyPosition));
    }
    return true;
  }

  /// Estimate an epoch mapping from intent and the first decoded position.
  /// Readiness of a source no open has claimed yet is kept for a later
  /// [bindClockOpen].
  bool calibrateClockSource(PlayerSourceReady source) {
    final open = _clockOpensBySource.remove(source.sourceId);
    if (open == null) {
      _unclaimedSource(source.sourceId).readyPosition = source.position;
      return false;
    }
    if (open.canceled || open.generation != _latestClockGeneration) return false;

    streamStartEpoch = open.targetEpoch - source.position.inMilliseconds / 1000.0;
    activeClockSourceId = source.sourceId;
    _lastObservedPosition = source.position;
    _lastPlaybackEpoch = open.targetEpoch;
    seekStatus = LiveTvSeekStatus.idle;
    pendingStreamEpoch = null;
    _clockOpensByGeneration.remove(open.generation);
    if (!open.result.isCompleted) open.result.complete(true);
    return true;
  }

  void failClockSource(PlayerSourceFailed source) {
    if (activeClockSourceId == source.sourceId) {
      activeClockSourceId = null;
      seekStatus = LiveTvSeekStatus.failed;
    }
    final open = _clockOpensBySource.remove(source.sourceId);
    if (open == null) {
      _unclaimedSource(source.sourceId).failed = true;
      return;
    }
    _failClockOpen(open);
  }

  _UnclaimedSourceEvents _unclaimedSource(int sourceId) {
    final existing = _unclaimedSources.remove(sourceId);
    if (existing != null) {
      return _unclaimedSources[sourceId] = existing;
    }
    if (_unclaimedSources.length >= _maxUnclaimedSources) {
      _unclaimedSources.remove(_unclaimedSources.keys.first);
    }
    return _unclaimedSources[sourceId] = _UnclaimedSourceEvents();
  }

  void failClockOpen(int generation) {
    final open = _clockOpensByGeneration[generation];
    if (open != null) _failClockOpen(open);
  }

  /// Release the failed pending request; retain the source registration so
  /// late readiness may still establish an estimate if it remains current.
  void timeoutClockOpen(int generation) {
    final open = _clockOpensByGeneration[generation];
    if (open == null || open.canceled || generation != _latestClockGeneration) return;
    pendingStreamEpoch = null;
    seekStatus = LiveTvSeekStatus.failed;
    if (!open.result.isCompleted) open.result.complete(false);
  }

  void _failClockOpen(_LiveClockOpen open) {
    open.canceled = true;
    final sourceId = open.sourceId;
    if (sourceId != null && identical(_clockOpensBySource[sourceId], open)) {
      _clockOpensBySource.remove(sourceId);
    }
    if (identical(_clockOpensByGeneration[open.generation], open)) {
      _clockOpensByGeneration.remove(open.generation);
    }
    if (_latestClockGeneration == open.generation) {
      _latestClockGeneration = null;
      pendingStreamEpoch = null;
      seekStatus = LiveTvSeekStatus.failed;
    }
    if (!open.result.isCompleted) open.result.complete(false);
  }

  /// Resolves true once the open's source is calibrated, false when it is
  /// superseded, failed or timed out. A timed-out open stays registered so a
  /// late `loadfile` reply or readiness event can still bind and calibrate it.
  Future<bool> clockOpenResult(int generation) {
    final open = _clockOpensByGeneration[generation];
    if (open == null) return Future<bool>.value(false);
    return open.result.future;
  }

  void cancelClockOpens() {
    final generations = _clockOpensByGeneration.keys.toList(growable: false);
    for (final generation in generations) {
      failClockOpen(generation);
    }
    _clockOpensBySource.clear();
    _unclaimedSources.clear();
    _latestClockGeneration = null;
    pendingStreamEpoch = null;
  }

  /// Adopt a server-origin estimate only for a currently active source.
  /// Server origin alone does not establish its relationship to MPV time-pos.
  bool adoptPlaybackStreamOrigin(CaptureBuffer playbackStream, {required int generation}) {
    if (generation != streamGeneration ||
        pendingStreamEpoch != null ||
        activeClockSourceId == null ||
        !playbackStream.isValid) {
      return false;
    }
    if (streamStartEpoch == playbackStream.startedAt) return false;
    streamStartEpoch = playbackStream.startedAt;
    return true;
  }

  /// Make [newSession] current and seed the seekable window from its tune
  /// snapshot. Every flow that produces a session (start, retry, channel
  /// zap) adopts it here, so a field can't be forgotten in one copy.
  void adoptSession(LiveTvPlaybackSession newSession) {
    if (!identical(session, newSession)) timelineReports = LiveTimelineReportQueue();
    session = newSession;
    captureBuffer = newSession.captureBuffer;
    selectedSubtitle = null;
  }

  /// Re-map a subtitle selection onto a replacement session's track list.
  /// Stream ids are tune-scoped, so a re-tuned session's equivalent track is
  /// found by identity fields instead: same language and stream index first,
  /// then the first track of the same language.
  static MediaSubtitleTrack? remapSubtitleSelection(List<MediaSubtitleTrack> tracks, MediaSubtitleTrack? previous) {
    if (previous == null) return null;
    MediaSubtitleTrack? languageMatch;
    for (final track in tracks) {
      if (track.id == previous.id) return track;
      if (track.languageCode != previous.languageCode) continue;
      if (track.index != null && track.index == previous.index) return track;
      languageMatch ??= track;
    }
    return languageMatch;
  }

  /// The stream just (re)started at the live edge — align the epoch
  /// bookkeeping every restart flow shares (start, retry, channel zap,
  /// subtitle switch).
  ///
  /// The freshest capture edge supplies a provisional request estimate.
  /// Neither this edge nor wall clock establishes the rendered frame's epoch.
  void markStreamRestartedAtLiveEdge(CaptureBuffer? buffer) {
    final now = DateTime.now();
    playbackElapsed
      ..reset()
      ..start();
    invalidatePlayback();
    streamStartEpoch = buffer == null ? now.millisecondsSinceEpoch / 1000.0 : buffer.startedAt + buffer.seekEndSeconds;
  }
}
