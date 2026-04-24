/// Shared constants for non-Trakt tracker integrations (MAL, AniList, Simkl).
class TrackerConstants {
  TrackerConstants._();

  /// Progress percent at which an episode/movie counts as watched and is
  /// pushed to each tracker.
  static const double watchedThresholdPercent = 80.0;
}

/// Identifier used across the app to disambiguate per-service operations.
/// The enum's `.name` forms part of the persistence key — do not rename
/// without a migration.
enum TrackerService { mal, anilist, simkl, trakt }

/// Blacklist+[] syncs every library (the default); whitelist+[] syncs nothing.
enum TrackerLibraryFilterMode { blacklist, whitelist }
