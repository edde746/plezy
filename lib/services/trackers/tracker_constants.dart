/// Shared constants for non-Trakt tracker integrations (MAL, AniList, Simkl).
class TrackerConstants {
  TrackerConstants._();

  /// Progress percent at which an episode/movie counts as watched and is
  /// pushed to each tracker.
  static const double watchedThresholdPercent = 80.0;
}
