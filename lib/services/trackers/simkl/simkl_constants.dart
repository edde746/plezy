enum SimklCatalogType { movies, tv, anime }

extension SimklCatalogTypeApi on SimklCatalogType {
  String get searchPath => this == SimklCatalogType.movies ? 'movie' : name;

  String get detailPath => this == SimklCatalogType.movies ? 'movies' : name;
}

/// Bundled Simkl API credentials and endpoints.
///
/// Register at https://simkl.com/settings/developer — app type should be
/// "Commandline / Console / Device code" (the same flow Trakt uses).
/// Replace [clientId] with the registered client ID before shipping.
class SimklConstants {
  SimklConstants._();

  /// Registered Simkl app client ID. Extractable from the binary; same threat
  /// model as the Plex token already in SharedPreferences.
  static const String clientId = 'ac97718a469c33eab948b63f92226106157e58fdcdd70c1b5857f1779b1d3a6a';

  static const String apiBase = 'https://api.simkl.com';
  static const String dataBase = 'https://data.simkl.in';
  static const String appName = 'plezy';
  static const String appVersion = '2';

  // OAuth (device-code / PIN) endpoints
  static const String pinUrl = '$apiBase/oauth/pin';

  /// Poll URL for a given user code. Append `/<userCode>?client_id=...`.
  static String pinPollUrl(String userCode) => '$apiBase/oauth/pin/$userCode';

  /// Web page the user visits to enter the code.
  static const String verificationUrl = 'https://simkl.com/pin';

  static Map<String, String> queryParameters([Map<String, String>? query]) => {
    ...?query,
    'client_id': clientId,
    'app-name': appName,
    'app-version': appVersion,
  };

  /// Required identity headers on every Simkl request. Authenticated API
  /// calls additionally carry the bearer token; CDN requests deliberately do
  /// not receive it.
  static Map<String, String> headers({String? accessToken}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': '$appName/$appVersion',
    'simkl-api-key': clientId,
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
}
