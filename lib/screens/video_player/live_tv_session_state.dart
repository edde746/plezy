import 'dart:async';

import '../../media/media_server_client.dart';
import '../../models/livetv_capture_buffer.dart';
import '../../services/jellyfin_client.dart';
import '../../services/live_session_tracker.dart';
import 'live_tv_session_args.dart';

/// Mutable state for one live TV playback session: tune/session identity,
/// the timeline heartbeat machinery, the capture buffer used for
/// time-shifting, and the retry/fallback ladder.
///
/// One instance lives on the player screen (inert when the screen plays
/// VOD); the live-TV part file owns all the logic and reads/writes through
/// this object so the session state has a single boundary and lifetime.
class LiveTvSessionState {
  LiveTvSessionState(LiveTvSessionArgs? args, {required this.itemId})
    : channelIndex = args?.currentChannelIndex ?? -1,
      channelName = args?.channelName,
      client = args?.client,
      dvrKey = args?.dvrKey,
      streamUrl = args?.streamUrl,
      sessionIdentifier = args?.sessionIdentifier,
      sessionPath = args?.sessionPath,
      jellyfin = args?.client is JellyfinClient && args?.sessionIdentifier != null
          ? JellyfinLiveSessionTracker(playSessionId: args?.sessionIdentifier)
          : JellyfinLiveSessionTracker();

  int channelIndex;
  String? channelName;
  MediaServerClient? client;
  String? dvrKey;
  String? streamUrl;

  /// The channel/program item progress reports are attributed to; updated
  /// on channel switches.
  String itemId;

  String? sessionIdentifier;
  String? sessionPath;
  Timer? timelineTimer;
  int timelineGeneration = 0;
  DateTime? playbackStartTime;
  String? programId;
  int? durationMs;

  /// Jellyfin live TV heartbeat state machine. The Plex live branch keeps
  /// its bespoke capture-buffer flow inline; this tracker only collapses
  /// the Jellyfin started/progress/stopped transition.
  JellyfinLiveSessionTracker jellyfin;

  CaptureBuffer? captureBuffer;
  int? programBeginsAt;
  double streamStartEpoch = 0;
  bool atLiveEdge = true;
  String? transcodeSessionId;

  /// Fallback level for live TV stream errors (mirrors Plex web client
  /// behavior). 0 = directStream+directStreamAudio, 1 = no directStream,
  /// 2 = no DS + no DS audio.
  int fallbackLevel = 0;
  bool retrying = false;

  /// Whether the timeline heartbeat should restart when the app resumes
  /// from the background (it is suspended on hide).
  bool resumeTimelineOnResume = false;

  /// The stream just (re)started at the live edge — align the epoch
  /// bookkeeping every restart flow shares (retry, channel zap).
  void markStreamRestartedAtLiveEdge() {
    final now = DateTime.now();
    playbackStartTime = now;
    streamStartEpoch = now.millisecondsSinceEpoch / 1000.0;
    atLiveEdge = true;
  }
}
