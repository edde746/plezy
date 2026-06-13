import '../../models/livetv_channel.dart';

/// Launch parameters for a live TV session — pure UX data. A
/// [VideoPlayerScreen] plays live TV iff it was constructed with one of
/// these.
///
/// Transport (tune/stream-URL resolution, session identity) is no longer
/// passed in: the player starts a backend-neutral `LiveTvPlaybackSession`
/// via `client.liveTv.startPlayback` itself, for both backends, so launch
/// and channel zapping share one resolution path and one spinner UX.
class LiveTvSessionArgs {
  /// The channel to start on.
  final LiveTvChannel channel;

  /// Full channel list for channel up/down navigation.
  final List<LiveTvChannel>? channels;

  /// Index of [channel] within [channels] (-1 / null when unknown).
  final int? currentChannelIndex;

  const LiveTvSessionArgs({required this.channel, this.channels, this.currentChannelIndex});
}
