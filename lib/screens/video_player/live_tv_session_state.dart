import 'dart:async';

import '../../media/live_tv_support.dart';
import '../../media/media_source_info.dart';
import '../../models/livetv_capture_buffer.dart';
import '../../mpv/player/player_streams.dart';
import 'live_tv_session_args.dart';

class _LiveClockOpen {
  _LiveClockOpen({required this.generation, required this.targetEpoch});

  final int generation;
  final int targetEpoch;
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
  DateTime? playbackStartTime;

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

  /// Epoch of player position zero for the stream MPV is playing. Seeded
  /// provisionally at open ([markStreamRestartedAtLiveEdge], the offset of a
  /// time-shift open), calibrated against the first rendered position, then
  /// replaced by the server's own origin for the playback transcode as soon
  /// as a heartbeat reports it ([adoptPlaybackStreamOrigin]).
  double streamStartEpoch = 0;
  bool atLiveEdge = true;

  /// Bumped on every stream open. A heartbeat snapshots it when dispatched so
  /// a response describing a stream that has since been replaced cannot
  /// re-anchor the clock of its replacement.
  int streamGeneration = 0;

  int _nextClockGeneration = 0;
  int? _latestClockGeneration;
  int? activeClockSourceId;
  double? pendingStreamEpoch;
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
  int beginClockOpen(int targetEpoch) {
    final previousOpens = <_LiveClockOpen>{..._clockOpensByGeneration.values, ..._clockOpensBySource.values};
    for (final open in previousOpens) {
      open.canceled = true;
      if (!open.result.isCompleted) open.result.complete(false);
    }
    _clockOpensByGeneration.clear();
    _clockOpensBySource.clear();

    final open = _LiveClockOpen(generation: ++_nextClockGeneration, targetEpoch: targetEpoch);
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

  /// Calibrate epoch time against the first decoded position of [source].
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
    pendingStreamEpoch = null;
    _clockOpensByGeneration.remove(open.generation);
    if (!open.result.isCompleted) open.result.complete(true);
    return true;
  }

  void failClockSource(PlayerSourceFailed source) {
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

  /// Release an awaiter while keeping the requested epoch authoritative until
  /// a delayed readiness event can still calibrate this source.
  void timeoutClockOpen(int generation) {
    final open = _clockOpensByGeneration[generation];
    if (open == null || open.canceled || generation != _latestClockGeneration) return;
    pendingStreamEpoch = open.targetEpoch.toDouble();
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

  int epochForPosition(Duration position) {
    final pending = pendingStreamEpoch;
    if (pending != null) return pending.round();
    return (streamStartEpoch + position.inMilliseconds / 1000.0).round();
  }

  /// Re-anchor the clock on the playback transcode's server-reported origin:
  /// its `timeStamp` is the epoch of stream position zero (its first segment's
  /// program date-time is `timeStamp + minOffsetAvailable`), which no client
  /// side guess — wall clock at open, the requested offset — can match once
  /// tuner latency and keyframe snapping are in play (#2100).
  ///
  /// Skipped while an open is still calibrating: the heartbeat may describe
  /// the transcode being replaced. Returns whether the anchor moved.
  bool adoptPlaybackStreamOrigin(CaptureBuffer playbackStream, {required int generation}) {
    if (generation != streamGeneration || pendingStreamEpoch != null) return false;
    if (streamStartEpoch == playbackStream.startedAt) return false;
    streamStartEpoch = playbackStream.startedAt;
    return true;
  }

  /// Make [newSession] current and seed the seekable window from its tune
  /// snapshot. Every flow that produces a session (start, retry, channel
  /// zap) adopts it here, so a field can't be forgotten in one copy.
  void adoptSession(LiveTvPlaybackSession newSession) {
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
  /// [buffer] is the freshest capture window known for the stream being
  /// opened (the tune snapshot for start/retry/zap). An offset-less open
  /// starts at the capture's live edge, so its end is the provisional anchor
  /// until the first heartbeat reports the transcode's real origin — wall
  /// clock is not: the edge already trails real time by the tuner's ingest
  /// latency, and skipping back from a wall-clock anchor landed on or after
  /// the frame being shown (#2100).
  void markStreamRestartedAtLiveEdge(CaptureBuffer? buffer) {
    final now = DateTime.now();
    playbackStartTime = now;
    streamStartEpoch = buffer == null ? now.millisecondsSinceEpoch / 1000.0 : buffer.startedAt + buffer.seekEndSeconds;
    atLiveEdge = true;
  }
}
