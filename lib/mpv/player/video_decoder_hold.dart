/// A video stream's rate and size as the demuxer declares them, before any
/// decoder has seen a frame. [fps] is null when the container declares no
/// rate; 0 is an unknown dimension.
typedef DemuxedVideoFormat = ({double? fps, int width, int height});

/// A hold on the next opened file's video decoder ([Player.holdVideoDecoderAtPreload]).
class VideoDecoderHold {
  VideoDecoderHold({required this.format, required this._release});

  /// The held file's demuxed video format once the player reached the hold,
  /// or null when nothing was held: the file has no video track, the open
  /// failed or was superseded, or the player went away.
  final Future<DemuxedVideoFormat?> format;

  final Future<void> Function() _release;

  /// Lets the held decoder open. Before the hold was reached, cancels it so
  /// it cannot hold a later file instead.
  Future<void> release() => _release();
}
