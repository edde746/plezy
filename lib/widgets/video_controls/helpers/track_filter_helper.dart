import '../../../mpv/mpv.dart';

/// Helper class for filtering tracks to remove auto/no tracks
///
/// This keeps track-filter rules in one place and eliminates duplication.
class TrackFilterHelper {
  /// Filter out 'auto' and 'no' tracks from a list of audio tracks
  static List<AudioTrack> filterAudioTracks(List<AudioTrack> tracks) {
    return tracks
        .where((track) => track.id != 'auto' && track.id != 'no')
        .toList();
  }

  /// Filter out 'auto' and 'no' tracks from a list of subtitle tracks
  static List<SubtitleTrack> filterSubtitleTracks(List<SubtitleTrack> tracks) {
    return tracks
        .where((track) => track.id != 'auto' && track.id != 'no')
        .toList();
  }

  /// Generic method to filter tracks based on type
  static List<T> filterTracks<T>(List<T> tracks) {
    if (T == AudioTrack) {
      return filterAudioTracks(tracks as List<AudioTrack>) as List<T>;
    } else if (T == SubtitleTrack) {
      return filterSubtitleTracks(tracks as List<SubtitleTrack>) as List<T>;
    }
    return tracks;
  }

  /// Extract and filter tracks from Tracks object
  static List<T> extractAndFilterTracks<T>(
    Tracks? tracks,
    List<T> Function(Tracks?) extractor,
  ) {
    return filterTracks<T>(extractor(tracks));
  }

  /// Check if a track list has multiple tracks (excluding auto/no)
  static bool hasMultipleTracks<T>(List<T> tracks) {
    return filterTracks<T>(tracks).length > 1;
  }

  /// Check if a track list has any tracks (excluding auto/no)
  static bool hasTracks<T>(List<T> tracks) {
    return filterTracks<T>(tracks).isNotEmpty;
  }
}
