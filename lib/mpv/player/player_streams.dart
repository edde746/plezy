import '../models.dart';

/// Reactive streams for player state changes.
///
/// Subscribe to these streams to receive updates when the player state changes.
/// For synchronous state access, use [PlayerState].
class PlayerStreams {
  /// Stream of playing state changes.
  final Stream<bool> playing;

  /// Stream of completion state changes.
  final Stream<bool> completed;

  /// Stream of buffering state changes.
  final Stream<bool> buffering;

  /// Stream of position updates.
  final Stream<Duration> position;

  /// Stream of duration changes (when media is loaded).
  final Stream<Duration> duration;

  /// Stream of buffer position updates.
  final Stream<Duration> buffer;

  /// Stream of volume changes.
  final Stream<double> volume;

  /// Stream of playback rate changes.
  final Stream<double> rate;

  /// Stream of available tracks updates.
  final Stream<Tracks> tracks;

  /// Stream of track selection changes.
  final Stream<TrackSelection> track;

  /// Stream of log messages from the player.
  final Stream<PlayerLog> log;

  /// Stream of error messages.
  final Stream<String> error;

  /// Stream of audio device changes.
  final Stream<AudioDevice> audioDevice;

  /// Stream of available audio devices.
  final Stream<List<AudioDevice>> audioDevices;

  /// Stream that emits when playback restarts (first frame ready after load/seek).
  final Stream<void> playbackRestart;

  /// Stream of seekable buffer ranges from the demuxer cache.
  final Stream<List<BufferRange>> bufferRanges;

  /// Stream that emits when the native player backend switches (e.g., ExoPlayer to MPV).
  /// Only emitted on Android when ExoPlayer encounters an unsupported format.
  final Stream<void> backendSwitched;

  const PlayerStreams({
    required this.playing,
    required this.completed,
    required this.buffering,
    required this.position,
    required this.duration,
    required this.buffer,
    required this.volume,
    required this.rate,
    required this.tracks,
    required this.track,
    required this.log,
    required this.error,
    required this.audioDevice,
    required this.audioDevices,
    required this.bufferRanges,
    required this.playbackRestart,
    required this.backendSwitched,
  });
}
