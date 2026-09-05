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
  final List<_LiveClockOpen> _unboundClockOpens = [];
  final Map<int, _LiveClockOpen> _clockOpensBySource = {};
  final Map<int, _LiveClockOpen> _clockOpensByGeneration = {};

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

  /// Register an offset-based MPV open before dispatching `loadfile`.
  ///
  /// Opens and MPV START_FILE events are ordered. Canceled entries stay in the
  /// unbound queue until their START_FILE arrives so a late predecessor cannot
  /// steal the next open's source identity.
  int beginClockOpen(int targetEpoch) {
    final previousOpens = <_LiveClockOpen>{
      ..._clockOpensByGeneration.values,
      ..._unboundClockOpens,
      ..._clockOpensBySource.values,
    };
    for (final open in previousOpens) {
      open.canceled = true;
      if (!open.result.isCompleted) open.result.complete(false);
    }
    _clockOpensBySource.removeWhere((_, open) => open.canceled);

    final open = _LiveClockOpen(generation: ++_nextClockGeneration, targetEpoch: targetEpoch);
    _clockOpensByGeneration[open.generation] = open;
    _unboundClockOpens.add(open);
    _latestClockGeneration = open.generation;
    pendingStreamEpoch = targetEpoch.toDouble();
    return open.generation;
  }

  /// Bind the oldest dispatched live open to the source MPV started next.
  bool bindClockSource(PlayerSourceStarted source) {
    if (_unboundClockOpens.isEmpty) return false;
    final open = _unboundClockOpens.removeAt(0);
    open.sourceId = source.sourceId;
    if (open.canceled) return false;
    _clockOpensBySource[source.sourceId] = open;
    return true;
  }

  /// Calibrate epoch time against the first decoded position of [source].
  bool calibrateClockSource(PlayerSourceReady source) {
    final open = _clockOpensBySource.remove(source.sourceId);
    if (open == null || open.canceled || open.generation != _latestClockGeneration) return false;

    streamStartEpoch = open.targetEpoch - source.position.inMilliseconds / 1000.0;
    activeClockSourceId = source.sourceId;
    pendingStreamEpoch = null;
    _clockOpensByGeneration.remove(open.generation);
    if (!open.result.isCompleted) open.result.complete(true);
    return true;
  }

  void failClockSource(PlayerSourceFailed source) {
    final open = _clockOpensBySource.remove(source.sourceId);
    if (open != null) _failClockOpen(open);
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
    _unboundClockOpens.remove(open);
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

  Future<bool> clockOpenResult(int generation) {
    final open = _clockOpensByGeneration[generation];
    if (open == null) return Future<bool>.value(false);
    return open.result.future.whenComplete(() {
      if (identical(_clockOpensByGeneration[generation], open)) {
        _clockOpensByGeneration.remove(generation);
      }
    });
  }

  void cancelClockOpens() {
    final generations = _clockOpensByGeneration.keys.toList(growable: false);
    for (final generation in generations) {
      failClockOpen(generation);
    }
    _unboundClockOpens.clear();
    _clockOpensBySource.clear();
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
