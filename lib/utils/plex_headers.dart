/// Utility class for building Plex API headers
class PlexHeaders {
  /// Standard Plex headers required for API requests
  static const String plexClientIdentifier = 'X-Plex-Client-Identifier';
  static const String plexProduct = 'X-Plex-Product';
  static const String plexVersion = 'X-Plex-Version';
  static const String plexToken = 'X-Plex-Token';
  static const String plexPlatform = 'X-Plex-Platform';
  static const String plexPlatformVersion = 'X-Plex-Platform-Version';
  static const String plexDevice = 'X-Plex-Device';

  /// Builds standard Plex headers with optional token
  static Map<String, String> buildHeaders({
    required String clientIdentifier,
    String? token,
    String product = 'Plezy',
    String version = '1.0',
    String platform = 'Flutter',
    String platformVersion = '1.0',
    String device = 'Mobile',
  }) {
    final headers = {
      plexClientIdentifier: clientIdentifier,
      plexProduct: product,
      plexVersion: version,
      plexPlatform: platform,
      plexPlatformVersion: platformVersion,
      plexDevice: device,
    };

    if (token != null) {
      headers[plexToken] = token;
    }

    return headers;
  }
}
