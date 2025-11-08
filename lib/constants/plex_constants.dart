/// Constants for Plex API and player configuration
class PlexConstants {
  // Plex API Type Parameters
  /// Type parameter for albums (used for audiobooks - shows books instead of artists)
  static const int plexTypeAlbum = 9;

  /// Type parameter for artists
  static const int plexTypeArtist = 8;

  /// Type parameter for tracks (chapters)
  static const int plexTypeTrack = 10;

  // Player Configuration
  /// Maximum attempts to wait for player initialization
  static const int maxPlayerInitAttempts = 100;

  /// Interval between player initialization checks
  static const Duration playerInitCheckInterval = Duration(milliseconds: 100);

  /// Delay to ensure player is fully ready before seeking
  static const Duration playerReadyDelay = Duration(milliseconds: 500);

  /// Delay to verify seek operation completed
  static const Duration seekVerificationDelay = Duration(milliseconds: 200);

  // Progress Tracking
  /// Interval for sending progress updates to Plex server
  static const Duration progressUpdateInterval = Duration(seconds: 10);

  // UI Behavior
  /// Duration before hiding player controls automatically
  static const Duration controlsHideDelay = Duration(seconds: 5);

  PlexConstants._(); // Private constructor to prevent instantiation
}
