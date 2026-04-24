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

  // OAuth (device-code / PIN) endpoints
  static const String pinUrl = '$apiBase/oauth/pin';

  /// Poll URL for a given user code. Append `/<userCode>?client_id=...`.
  static String pinPollUrl(String userCode) => '$apiBase/oauth/pin/$userCode';

  /// Web page the user visits to enter the code.
  static const String verificationUrl = 'https://simkl.com/pin';

  /// Headers on every Simkl request. `simkl-api-key` is required on all
  /// endpoints, authed or not.
  static Map<String, String> headers({String? accessToken}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'simkl-api-key': clientId,
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
}
