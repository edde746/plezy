import '../models.dart';

/// Immutable snapshot of the current player state.
/// For reactive updates, use [PlayerStreams].
class PlayerState {
  final bool playing;
  final bool completed;
  final bool buffering;
  final Duration position;
  final Duration duration;
  final bool seekable;
  final Duration buffer;
  final double volume;
  final double rate;
  final Tracks tracks;
  final TrackSelection track;
  final double audioDelay;
  final double subtitleDelay;
  final bool audioPassthrough;
  final AudioDevice audioDevice;
  final List<AudioDevice> audioDevices;
  final List<BufferRange> bufferRanges;

  const PlayerState({
    this.playing = false,
    this.completed = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.seekable = false,
    this.buffer = Duration.zero,
    this.volume = 100.0,
    this.rate = 1.0,
    this.tracks = const Tracks(),
    this.track = const TrackSelection(),
    this.audioDelay = 0.0,
    this.subtitleDelay = 0.0,
    this.audioPassthrough = false,
    this.audioDevice = AudioDevice.auto,
    this.audioDevices = const [],
    this.bufferRanges = const [],
  });

  PlayerState copyWith({
    bool? playing,
    bool? completed,
    bool? buffering,
    Duration? position,
    Duration? duration,
    bool? seekable,
    Duration? buffer,
    double? volume,
    double? rate,
    Tracks? tracks,
    TrackSelection? track,
    double? audioDelay,
    double? subtitleDelay,
    bool? audioPassthrough,
    AudioDevice? audioDevice,
    List<AudioDevice>? audioDevices,
    List<BufferRange>? bufferRanges,
  }) {
    return PlayerState(
      playing: playing ?? this.playing,
      completed: completed ?? this.completed,
      buffering: buffering ?? this.buffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      seekable: seekable ?? this.seekable,
      buffer: buffer ?? this.buffer,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      tracks: tracks ?? this.tracks,
      track: track ?? this.track,
      audioDelay: audioDelay ?? this.audioDelay,
      subtitleDelay: subtitleDelay ?? this.subtitleDelay,
      audioPassthrough: audioPassthrough ?? this.audioPassthrough,
      audioDevice: audioDevice ?? this.audioDevice,
      audioDevices: audioDevices ?? this.audioDevices,
      bufferRanges: bufferRanges ?? this.bufferRanges,
    );
  }

  /// Whether media is actively playing (not paused, not at EOF).
  ///
  /// mpv keeps [playing] true at EOF, so raw [playing] alone is unreliable
  /// for gating wakelock, media controls, progress tracking, etc.
  bool get isActive => playing && !completed;

  @override
  String toString() => 'PlayerState(playing: $playing, position: $position, duration: $duration, seekable: $seekable)';
}
