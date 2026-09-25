import '../../models/livetv_channel.dart';

/// Launch parameters for a live TV session — pure UX data. A
/// [VideoPlayerScreen] plays live TV iff it was constructed with one of
/// these.
///
/// Transport (tune/stream-URL resolution, session identity) is no longer
/// passed in: the player starts a backend-neutral `LiveTvPlaybackSession`
/// via `client.liveTv.startPlayback` itself, for both backends, so launch
/// and channel zapping share one resolution path and one spinner UX.
/// How to start a channel that already has recorded history (an in-progress
/// DVR recording or an existing capture session).
enum LiveTvStartPosition {
  /// Ask the user whether to start from the beginning or join live.
  ask,

  /// Start from the beginning of the current program without asking.
  beginning,

  /// Join at the live edge without asking.
  live,
}

class LiveTvSessionArgs {
  /// The channel to start on.
  final LiveTvChannel channel;

  /// Full channel list for channel up/down navigation.
  final List<LiveTvChannel>? channels;

  /// Index of [channel] within [channels] (-1 / null when unknown).
  final int? currentChannelIndex;

  /// How to handle recorded history on the first tune. Channel zaps inside
  /// the player always ask.
  final LiveTvStartPosition startPosition;

  const LiveTvSessionArgs({
    required this.channel,
    this.channels,
    this.currentChannelIndex,
    this.startPosition = LiveTvStartPosition.ask,
  });
}
