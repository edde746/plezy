/// Backend-neutral metadata attached to a playback report.
///
/// This deliberately describes user/client intent rather than backend wire
/// parameters. Plex maps offline replays to `offline`, `updated`, and
/// `continuing` timeline query params; backends without equivalent semantics
/// can ignore the fields.
enum PlaybackReportOrigin { live, offlineReplay }

class PlaybackReportMetadata {
  final PlaybackReportOrigin origin;
  final DateTime? recordedAt;
  final bool? willContinue;

  const PlaybackReportMetadata({this.origin = PlaybackReportOrigin.live, this.recordedAt, this.willContinue});

  const PlaybackReportMetadata.live({bool? willContinue})
    : this(origin: PlaybackReportOrigin.live, willContinue: willContinue);

  const PlaybackReportMetadata.offlineReplay({required DateTime recordedAt, bool willContinue = false})
    : this(origin: PlaybackReportOrigin.offlineReplay, recordedAt: recordedAt, willContinue: willContinue);

  bool get isOfflineReplay => origin == PlaybackReportOrigin.offlineReplay;
}
