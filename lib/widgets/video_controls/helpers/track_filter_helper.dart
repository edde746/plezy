import '../../../mpv/mpv.dart';

class TrackFilterHelper {
  static List<T> filterTracks<T>(List<T> tracks) {
    return tracks.where(_isAllowedTrack).toList();
  }

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
      final AudioTrack t => t.id,
      final SubtitleTrack t => t.id,
      _ => '',
    };

    return id != 'auto' && id != 'no';
  }
}
