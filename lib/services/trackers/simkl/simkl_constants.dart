import 'package:package_info_plus/package_info_plus.dart';

import '../../../utils/app_logger.dart';

enum SimklCatalogType { movies, tv, anime }

extension SimklCatalogTypeApi on SimklCatalogType {
  String get searchPath => this == SimklCatalogType.movies ? 'movie' : name;

  String get detailPath => this == SimklCatalogType.movies ? 'movies' : name;
}

/// Bundled Simkl API credentials and endpoints.
///
/// Two registrations run side by side until Simkl retires AUTH V1 (around
/// April 2027). Every new sign-in mints an AUTH V2 token; sessions created
/// before that keep their V1 token. Each `client_id` only works with its own
/// tokens, so the id is always derived from the session's token through
/// [clientIdFor] rather than chosen independently.
class SimklConstants {
  SimklConstants._();

  /// AUTH V1 app. Only used for sessions minted before the V2 cutover; nothing
  /// signs in with it any more. Its tokens never expire and cannot be revoked.
  static const String legacyClientId = 'ac97718a469c33eab948b63f92226106157e58fdcdd70c1b5857f1779b1d3a6a';

  /// AUTH V2 app, registered as "TV, devices & command line": device flow
  /// only, no client secret. Public by design — on its own it reaches nothing
  /// but public catalog data.
  static const String v2ClientId = 'ec68bc6a9d04b3c50af8cc495f9c9bf478c2371b979aed7e3385bdb771b9b18d';

  static const String apiBase = 'https://api.simkl.com';
  static const String dataBase = 'https://data.simkl.in';
  static const String appName = 'plezy';

  /// Sent as `app-version` when the platform cannot report the real one.
  static const String fallbackAppVersion = 'unknown';

  // AUTH V2 endpoints.
  static const String deviceAuthorizationUrl = '$apiBase/oauth2/device';
  static const String tokenUrl = '$apiBase/oauth2/token';
  static const String revokeUrl = '$apiBase/oauth2/revoke';

  static const String deviceCodeGrantType = 'urn:ietf:params:oauth:grant-type:device_code';

  /// Requested on every sign-in. Simkl silently downgrades an omitted or
  /// misspelled scope to read-only, so the granted scope is checked for
  /// [writeScope] before a session is accepted.
  static const String scope = 'media:read media:write';
  static const String writeScope = 'media:write';

  /// Minimum gap between the end of one write and the start of the next.
  /// Simkl allows one POST per second per user, and repeated overages extend a
  /// throttling block on the token.
  static const Duration writeSpacing = Duration(seconds: 1);

  static const String _v2AccessTokenPrefix = 'simkl_at_';

  /// AUTH V2 access tokens carry a `simkl_at_` prefix; V1 tokens are 64 hex
  /// characters with none.
  static bool isV2AccessToken(String token) => token.startsWith(_v2AccessTokenPrefix);

  /// The `client_id` that matches [accessToken]. Anything without a token
  /// (a new sign-in) uses the V2 app.
  static String clientIdFor(String? accessToken) =>
      accessToken == null || isV2AccessToken(accessToken) ? v2ClientId : legacyClientId;

  static String? _appVersion;
  static Future<String>? _appVersionLoad;

  /// The running app's version, read once from the platform. Once known it is
  /// handed out as a fresh future in the caller's zone rather than through the
  /// shared load future, which belongs to whichever zone first asked.
  static Future<String> appVersion() {
    final known = _appVersion;
    if (known != null) return Future.value(known);
    return _appVersionLoad ??= _loadAppVersion().then((version) => _appVersion = version);
  }

  static Future<String> _loadAppVersion() async {
    try {
      final version = (await PackageInfo.fromPlatform()).version.trim();
      if (version.isNotEmpty) return version;
    } catch (e) {
      // Tests and platforms whose version read fails (see main.dart) still
      // identify the app; only the version degrades.
      appLogger.d('Simkl: app version unavailable, sending "$fallbackAppVersion"', error: e);
    }
    return fallbackAppVersion;
  }

  static String userAgent(String appVersion) => '$appName/$appVersion';

  /// The app identity Simkl requires on every API URL.
  static Map<String, String> queryParameters({
    required String clientId,
    required String appVersion,
    Map<String, String>? query,
  }) => {...?query, 'client_id': clientId, 'app-name': appName, 'app-version': appVersion};

  /// Identity headers for an API request. Authenticated calls additionally
  /// carry the bearer token; CDN requests deliberately do not receive it.
  static Map<String, String> headers({required String clientId, required String appVersion, String? accessToken}) => {
    'Accept': 'application/json',
    'User-Agent': userAgent(appVersion),
    'simkl-api-key': clientId,
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };

  /// Headers for the OAuth endpoints, whose `client_id` travels in the form
  /// body instead.
  static Map<String, String> oauthHeaders({required String appVersion}) => {
    'Accept': 'application/json',
    'User-Agent': userAgent(appVersion),
  };
}
