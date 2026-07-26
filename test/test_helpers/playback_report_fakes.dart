import 'package:plezy/media/playback_report_metadata.dart';

enum PlaybackReportKind { started, progress, stopped }

/// One `reportPlayback*` invocation flattened into a single value.
class PlaybackReportCall {
  const PlaybackReportCall({
    required this.kind,
    required this.itemId,
    required this.position,
    this.duration,
    this.isPaused = false,
    this.playSessionId,
    this.playMethod,
    this.liveStreamId,
    this.mediaSourceId,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.report = const PlaybackReportMetadata.live(),
  });

  final PlaybackReportKind kind;
  final String itemId;
  final Duration position;
  final Duration? duration;
  final bool isPaused;
  final String? playSessionId;
  final String? playMethod;
  final String? liveStreamId;
  final String? mediaSourceId;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final PlaybackReportMetadata report;
}

/// Carries the three playback-reporting signatures so fakes implement the
/// surface once in [onPlaybackReport]. Forwarding is synchronous, so
/// [onPlaybackReport] runs with the same timing the overridden method had.
mixin PlaybackReportRecorder {
  Future<void> onPlaybackReport(PlaybackReportCall call);

  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) {
    return onPlaybackReport(
      PlaybackReportCall(
        kind: PlaybackReportKind.started,
        itemId: itemId,
        position: position,
        duration: duration,
        playSessionId: playSessionId,
        playMethod: playMethod,
        liveStreamId: liveStreamId,
        mediaSourceId: mediaSourceId,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
      ),
    );
  }

  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) {
    return onPlaybackReport(
      PlaybackReportCall(
        kind: PlaybackReportKind.progress,
        itemId: itemId,
        position: position,
        duration: duration,
        isPaused: isPaused,
        playSessionId: playSessionId,
        playMethod: playMethod,
        liveStreamId: liveStreamId,
        mediaSourceId: mediaSourceId,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
      ),
    );
  }

  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? liveStreamId,
    String? mediaSourceId,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) {
    return onPlaybackReport(
      PlaybackReportCall(
        kind: PlaybackReportKind.stopped,
        itemId: itemId,
        position: position,
        duration: duration,
        playSessionId: playSessionId,
        liveStreamId: liveStreamId,
        mediaSourceId: mediaSourceId,
        report: report,
      ),
    );
  }
}
