import 'audio_track.dart';
import 'subtitle_track.dart';

/// Represents the currently selected tracks.
class TrackSelection {
  /// Currently selected audio track.
  final AudioTrack? audio;

  /// Currently selected subtitle track.
  final SubtitleTrack? subtitle;

  const TrackSelection({
    this.audio,
    this.subtitle,
  });

  /// Creates a copy with the given fields replaced.
  TrackSelection copyWith({
    AudioTrack? audio,
    SubtitleTrack? subtitle,
  }) {
    return TrackSelection(
      audio: audio ?? this.audio,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  String toString() => 'TrackSelection(audio: $audio, subtitle: $subtitle)';
}
