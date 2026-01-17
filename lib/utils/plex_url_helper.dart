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

class PlexUrlHelper {
  /// Verifies if the destination URL is secure for transmitting the X-Plex-Token.
  ///
  /// The token should only be sent to:
  /// 1. Subdomains of plex.tv
  /// 2. The user's specific server IP (or hostname)
  /// 3. Loopback addresses (localhost, 127.0.0.1)
  ///
  /// [url] The destination URL to check
  /// [serverBaseUrl] The configured base URL of the Plex server
  static bool isSecureDestination(String url, String? serverBaseUrl) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // 1. Allow plex.tv subdomains
      if (host == 'plex.tv' || host.endsWith('.plex.tv')) {
        return true;
      }

      // 2. Allow loopback/local addresses
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return true;
      }

      // 3. Allow plex.direct domains (used for secure connections to servers)
      if (host.endsWith('.plex.direct')) {
        return true;
      }

      // 4. Allow configured server host
      if (serverBaseUrl != null) {
        final serverUri = Uri.parse(serverBaseUrl);
        if (host == serverUri.host.toLowerCase()) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // If URL parsing fails, assume insecure
      return false;
    }
  }
}
