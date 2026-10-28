import '../media/live_tv_support.dart';
import '../media/live_tv_timeline.dart';
import '../media/media_source_info.dart';
import '../models/livetv_capture_buffer.dart';

/// Direct playlist playback participates in the existing Live TV player
/// lifecycle. It has no server DVR, but native MPV can expose a bounded local
/// seek window when the stream itself reports seekable buffer ranges.
class IptvLiveTvPlaybackSession implements LiveTvPlaybackSession, LiveTvTimeshiftSession {
  IptvLiveTvPlaybackSession({
    required String initialUrl,
    required Future<String?> Function() refreshUrl,
    this.streamHeaders = const {},
    this.localTimeShiftEnabled = true,
    this.isCatchup = false,
    this.programInfo = LiveProgramInfo.none,
  }) : _url = initialUrl,
       _refreshUrl = refreshUrl;

  String? _url;
  final Future<String?> Function() _refreshUrl;
  final Map<String, String> streamHeaders;
  final LiveProgramInfo programInfo;
  final bool localTimeShiftEnabled;
  final bool isCatchup;
  CaptureBuffer? _localBuffer;
  bool _closed = false;

  @override
  LiveProgramInfo get program => programInfo;

  @override
  LiveTvBackgroundPolicy get backgroundPolicy => LiveTvBackgroundPolicy.stopAndExit;

  @override
  CaptureBuffer? get captureBuffer => _localBuffer;

  @override
  List<MediaSubtitleTrack> get subtitleTracks => const [];

  @override
  bool get canTimeShift => localTimeShiftEnabled && _localBuffer != null;

  void updateLocalBuffer(CaptureBuffer? buffer) {
    _localBuffer = localTimeShiftEnabled && buffer?.isValid == true ? buffer : null;
  }

  @override
  LiveTvSeekWindow? seekWindow(CaptureBuffer buffer) {
    if (!canTimeShift || !buffer.isValid || buffer.seekableDurationSeconds < 3) return null;
    return LiveTvSeekWindow(
      startEpoch: buffer.startedAt + buffer.seekStartSeconds,
      endEpoch: buffer.startedAt + buffer.seekEndSeconds,
      stepSeconds: 1,
    );
  }

  @override
  Future<LiveTvSeekRequest?> resolveSeek({
    required double? targetEpoch,
    required CaptureBuffer buffer,
    MediaSubtitleTrack? subtitleTrack,
  }) async {
    if (_closed || !canTimeShift || _url == null || subtitleTrack != null) return null;
    final window = seekWindow(buffer);
    final epoch = targetEpoch == null ? window?.endEpoch : window?.target(targetEpoch);
    if (epoch == null || window == null) return null;
    final positionSeconds = epoch - buffer.startedAt;
    if (!positionSeconds.isFinite || positionSeconds < buffer.seekStartSeconds || positionSeconds > buffer.seekEndSeconds) {
      return null;
    }
    return LiveTvSeekRequest(
      url: _url!,
      effectiveTargetEpoch: epoch,
      localPosition: Duration(microseconds: (positionSeconds * Duration.microsecondsPerSecond).round()),
    );
  }

  @override
  Future<String?> streamUrlAt({int? offsetSeconds, MediaSubtitleTrack? subtitleTrack}) async {
    if (_closed || offsetSeconds != null || subtitleTrack != null) return null;
    return _url;
  }

  @override
  Future<LiveTimelineUpdate?> reportTimeline({
    required String state,
    required int positionMs,
    required int durationMs,
  }) async {
    if (state == 'stopped') _closed = true;
    return null;
  }

  @override
  Future<void> discard() async {
    _closed = true;
    _url = null;
  }

  @override
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio}) async {
    if (_closed) return null;
    final refreshed = await _refreshUrl();
    if (refreshed == null) return null;
    return IptvLiveTvPlaybackSession(
      initialUrl: refreshed,
      refreshUrl: _refreshUrl,
      streamHeaders: streamHeaders,
      localTimeShiftEnabled: localTimeShiftEnabled,
      isCatchup: isCatchup,
      programInfo: programInfo,
    );
  }
}
