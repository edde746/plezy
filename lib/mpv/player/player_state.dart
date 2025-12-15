import '../models.dart';

/// Immutable snapshot of the current player state.
///
/// This class provides synchronous access to the player's current state.
/// For reactive updates, use [PlayerStreams].
class PlayerState {
  /// Whether playback is currently active.
  final bool playing;

  /// Whether the media has completed playback.
  final bool completed;

  /// Whether the player is currently buffering.
  final bool buffering;

  /// Current playback position.
  final Duration position;

  /// Total duration of the media.
  final Duration duration;

  /// Amount of media buffered ahead of current position.
  final Duration buffer;

  /// Current volume level (0.0 to 100.0).
  final double volume;

  /// Current playback rate (1.0 = normal speed).
  final double rate;

  /// Available tracks in the media.
  final Tracks tracks;

  /// Currently selected tracks.
  final TrackSelection track;

  /// Audio delay/sync offset in seconds.
  final double audioDelay;

  /// Subtitle delay/sync offset in seconds.
  final double subtitleDelay;

  /// Whether audio passthrough is currently enabled.
  final bool audioPassthrough;

  /// Current audio output device.
  final AudioDevice audioDevice;

  /// Available audio output devices.
  final List<AudioDevice> audioDevices;

  const PlayerState({
    this.playing = false,
    this.completed = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
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
  });

  /// Creates a copy with the given fields replaced.
  PlayerState copyWith({
    bool? playing,
    bool? completed,
    bool? buffering,
    Duration? position,
    Duration? duration,
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
  }) {
    return PlayerState(
      playing: playing ?? this.playing,
      completed: completed ?? this.completed,
      buffering: buffering ?? this.buffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
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
    );
  }

  @override
  String toString() =>
      'PlayerState(playing: $playing, position: $position, duration: $duration)';
}
