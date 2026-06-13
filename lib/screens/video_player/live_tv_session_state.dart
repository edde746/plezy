import 'dart:async';

import '../../media/live_tv_support.dart';
import '../../models/livetv_capture_buffer.dart';
import 'live_tv_session_args.dart';

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

  double streamStartEpoch = 0;
  bool atLiveEdge = true;

  /// Fallback level for live TV stream errors (mirrors Plex web client
  /// behavior). 0 = directStream+directStreamAudio, 1 = no directStream,
  /// 2 = no DS + no DS audio.
  int fallbackLevel = 0;
  bool retrying = false;

  /// Whether the timeline heartbeat should restart when the app resumes
  /// from the background (it is suspended on hide).
  bool resumeTimelineOnResume = false;

  /// Make [newSession] current and seed the seekable window from its tune
  /// snapshot. Every flow that produces a session (start, retry, channel
  /// zap) adopts it here, so a field can't be forgotten in one copy.
  void adoptSession(LiveTvPlaybackSession newSession) {
    session = newSession;
    captureBuffer = newSession.captureBuffer;
  }

  /// The stream just (re)started at the live edge — align the epoch
  /// bookkeeping every restart flow shares (retry, channel zap).
  void markStreamRestartedAtLiveEdge() {
    final now = DateTime.now();
    playbackStartTime = now;
    streamStartEpoch = now.millisecondsSinceEpoch / 1000.0;
    atLiveEdge = true;
  }
}
