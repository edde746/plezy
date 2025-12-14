/// Extension methods for appending Plex authentication tokens to URLs.
extension PlexUrlExtension on String {
  /// Appends a Plex authentication token to this URL string.
  ///
  /// Automatically determines whether to use '?' or '&' as the separator
  /// based on whether the URL already contains query parameters.
  ///
  /// If [token] is null or empty, returns the URL unchanged.
  ///
  /// Example:
  /// ```dart
  /// final url = '/library/metadata/123'.withPlexToken('abc123');
  /// // Result: '/library/metadata/123?X-Plex-Token=abc123'
  ///
  /// final urlWithParams = '/library/metadata/123?type=1'.withPlexToken('abc123');
  /// // Result: '/library/metadata/123?type=1&X-Plex-Token=abc123'
  /// ```
  String withPlexToken(String? token) {
    if (token == null || token.isEmpty) return this;
    final separator = contains('?') ? '&' : '?';
    return '$this${separator}X-Plex-Token=$token';
  }

  /// Appends a base URL and Plex authentication token to this path string.
  ///
  /// If [token] is null or empty, returns the URL without a token parameter.
  ///
  /// Example:
  /// ```dart
  /// final fullUrl = '/library/metadata/123'.toPlexUrl('http://server:32400', 'abc123');
  /// // Result: 'http://server:32400/library/metadata/123?X-Plex-Token=abc123'
  /// ```
  String toPlexUrl(String baseUrl, String? token) {
    return '$baseUrl$this'.withPlexToken(token);
  }
}
