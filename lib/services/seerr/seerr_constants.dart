/// Constants for the Seerr REST API (https://docs.seerr.dev).
class SeerrConstants {
  SeerrConstants._();

  /// Path prefix appended to a user-configured base URL. e.g. final URL is
  /// `{connection.baseUrl}/api/v1/auth/me`.
  static const String apiPath = '/api/v1';

  /// TMDB image CDN base. Seerr returns `posterPath` / `backdropPath` as
  /// TMDB-relative paths (e.g. `/abc.jpg`); prepend one of the size segments
  /// (`w300`, `w500`, `original`, ...) to render.
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';
  static const String tmdbPosterSize = 'w500';
  static const String tmdbBackdropSize = 'original';

  /// Session cookie name issued by Seerr's Express session middleware.
  static const String sessionCookieName = 'connect.sid';

  static const Duration probeTimeout = Duration(seconds: 10);
  static const Duration authRequestTimeout = Duration(seconds: 20);
  static const Duration requestTimeout = Duration(seconds: 20);

  /// Build a poster URL from a TMDB-relative path. Returns null when [path]
  /// is null or empty (some catalog items lack artwork).
  static String? posterUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final normalised = path.startsWith('/') ? path : '/$path';
    return '$tmdbImageBase/$tmdbPosterSize$normalised';
  }

  static String? backdropUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final normalised = path.startsWith('/') ? path : '/$path';
    return '$tmdbImageBase/$tmdbBackdropSize$normalised';
  }
}
