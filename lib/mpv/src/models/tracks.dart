import 'audio_track.dart';
import 'subtitle_track.dart';

/// Container for all available tracks in the media.
class Tracks {
  /// Available audio tracks.
  final List<AudioTrack> audio;

  /// Available subtitle tracks.
  final List<SubtitleTrack> subtitle;

  const Tracks({
    this.audio = const [],
    this.subtitle = const [],
  });

  /// Creates a copy with the given fields replaced.
  Tracks copyWith({
    List<AudioTrack>? audio,
    List<SubtitleTrack>? subtitle,
  }) {
    return Tracks(
      audio: audio ?? this.audio,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  String toString() =>
      'Tracks(audio: ${audio.length}, subtitle: ${subtitle.length})';
}
