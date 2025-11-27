import 'mpv_audio_track.dart';
import 'mpv_subtitle_track.dart';

/// Container for all available tracks in the media.
class MpvTracks {
  /// Available audio tracks.
  final List<MpvAudioTrack> audio;

  /// Available subtitle tracks.
  final List<MpvSubtitleTrack> subtitle;

  const MpvTracks({
    this.audio = const [],
    this.subtitle = const [],
  });

  /// Creates a copy with the given fields replaced.
  MpvTracks copyWith({
    List<MpvAudioTrack>? audio,
    List<MpvSubtitleTrack>? subtitle,
  }) {
    return MpvTracks(
      audio: audio ?? this.audio,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  String toString() =>
      'MpvTracks(audio: ${audio.length}, subtitle: ${subtitle.length})';
}
