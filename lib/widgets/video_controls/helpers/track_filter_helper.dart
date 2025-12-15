import '../../../mpv/mpv.dart';

/// Helper class for filtering tracks to remove auto/no tracks
///
/// This keeps track-filter rules in one place and eliminates duplication.
class TrackFilterHelper {
  /// Generic method to filter tracks based on type
  static List<T> filterTracks<T>(List<T> tracks) {
    return tracks.where(_isAllowedTrack).toList();
  }

  /// Extract and filter tracks from Tracks object
  static List<T> extractAndFilterTracks<T>(Tracks? tracks, List<T> Function(Tracks?) extractor) {
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

  static bool _isAllowedTrack<T>(T track) {
    final id = switch (track) {
      AudioTrack t => t.id,
      SubtitleTrack t => t.id,
      _ => '',
    };

    return id != 'auto' && id != 'no';
  }
}
