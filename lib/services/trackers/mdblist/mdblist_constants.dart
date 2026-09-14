/// Bundled MDBList API credentials and endpoints.
///
/// Registered as a **Device Code** app at https://mdblist.com/developer. That
/// app type takes no client secret and no redirect URI, so the public client
/// ID below is the only credential in the binary — unlike Trakt, there is no
/// extractable secret to worry about.
class MdblistConstants {
  MdblistConstants._();

  /// Registered MDBList Device Code app client ID. Public by design: the
  /// device-code grant authenticates the user, not the binary.
  static const String clientId = 'xOUwKUPdGEbHif6aKwW2gCxCAvFx7m0Q3jX0ZxXZ';

  static const String apiBase = 'https://api.mdblist.com';
  static const String webBase = 'https://mdblist.com';

  static const String appName = 'plezy';
  static const String appVersion = '2';

  /// OAuth endpoints. MDBList runs django-oauth-toolkit, whose routes are
  /// registered with a trailing slash — dropping it 404s the request.
  static const String deviceAuthorizationUrl = '$apiBase/oauth/device-authorization/';
  static const String tokenUrl = '$apiBase/oauth/token/';
  static const String revokeUrl = '$apiBase/oauth/revoke_token/';

  /// Page the user opens on a phone or laptop to approve the device.
  static const String verificationUrl = '$webBase/oauth/device/';

  static const String deviceCodeGrantType = 'urn:ietf:params:oauth:grant-type:device_code';

  /// The only scope MDBList offers. Grants the user's profile, lists,
  /// watchlist, ratings, collection and playback state — there is no
  /// read-only alternative to pick.
  static const String scope = 'write';

  /// Prefilled activation URL for [userCode].
  ///
  /// MDBList does not return `verification_uri_complete`, but its device page
  /// seeds the code field from a `user_code` query parameter and the sign-in
  /// redirect preserves the query string. Building the URL here is what makes
  /// the dialog's "open to activate" button land on a filled-in form instead
  /// of an empty one. If the parameter is ever ignored the page still renders
  /// normally, so this degrades to manual entry rather than breaking.
  static String verificationUrlFor(String userCode, {String? verificationUrl}) => Uri.parse(
    verificationUrl ?? MdblistConstants.verificationUrl,
  ).replace(queryParameters: {'user_code': userCode}).toString();

  /// Headers for every MDBList API call. The token rides the `Authorization`
  /// header; the `?apikey=` query form is deliberately unused so credentials
  /// never enter a URL.
  static Map<String, String> headers({String? accessToken}) => {
    'Accept': 'application/json',
    'User-Agent': '$appName/$appVersion',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
}
