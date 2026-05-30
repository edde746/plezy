/// Shared constants for tracker integrations.
class TrackerConstants {
  TrackerConstants._();

  /// Fallback watched threshold (percent) used only until the active server's
  /// threshold is known. The operative value follows
  /// [MediaServerClient.watchedThreshold] (captured per playback in
  /// [TrackerCoordinator]); this constant just seeds the field before playback.
  static const double watchedThresholdPercent = 80.0;

  static const Duration requestTimeout = Duration(seconds: 20);
  static const Duration authRequestTimeout = Duration(seconds: 15);
  static const Duration refreshTimeout = Duration(seconds: 15);
  static const Duration revokeTimeout = Duration(seconds: 10);
  static const Duration oauthProxyPollTimeout = Duration(seconds: 65);
  static const Duration oauthProxyRetryDelay = Duration(seconds: 2);
}

/// Identifier used across the app to disambiguate per-service operations.
/// The enum's `.name` forms part of the persistence key — do not rename
/// without a migration.
enum TrackerService { mal, anilist, simkl, trakt }

/// Blacklist+[] syncs every library (the default); whitelist+[] syncs nothing.
enum TrackerLibraryFilterMode { blacklist, whitelist }
