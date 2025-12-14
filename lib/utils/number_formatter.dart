/// Utility class for formatting numbers consistently across the app.
class NumberFormatter {
  NumberFormatter._();

  /// Formats a season number with leading zeros (e.g., "01", "02", "10").
  ///
  /// Used for consistent season display in file names and UI.
  static String formatSeason(int? seasonNumber) {
    return (seasonNumber ?? 0).toString().padLeft(2, '0');
  }

  /// Formats an episode number with leading zeros (e.g., "01", "02", "10").
  ///
  /// Used for consistent episode display in file names and UI.
  static String formatEpisode(int? episodeNumber) {
    return (episodeNumber ?? 0).toString().padLeft(2, '0');
  }

  /// Formats a season and episode as "SXXEXX" (e.g., "S01E05", "S12E23").
  ///
  /// Commonly used for episode identifiers in file names.
  static String formatSeasonEpisode(int? season, int? episode) {
    return 'S${formatSeason(season)}E${formatEpisode(episode)}';
  }

  /// Formats a number with a minimum number of digits using leading zeros.
  ///
  /// Example: `padNumber(5, 3)` returns "005"
  static String padNumber(int number, int width) {
    return number.toString().padLeft(width, '0');
  }
}
