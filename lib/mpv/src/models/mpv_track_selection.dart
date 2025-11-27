import 'mpv_audio_track.dart';
import 'mpv_subtitle_track.dart';

/// Represents the currently selected tracks.
class MpvTrackSelection {
  /// Currently selected audio track.
  final MpvAudioTrack? audio;

  /// Currently selected subtitle track.
  final MpvSubtitleTrack? subtitle;

  const MpvTrackSelection({
    this.audio,
    this.subtitle,
  });

  /// Creates a copy with the given fields replaced.
  MpvTrackSelection copyWith({
    MpvAudioTrack? audio,
    MpvSubtitleTrack? subtitle,
  }) {
    return MpvTrackSelection(
      audio: audio ?? this.audio,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  String toString() => 'MpvTrackSelection(audio: $audio, subtitle: $subtitle)';
}
