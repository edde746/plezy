/// Bundled MyAnimeList API credentials and endpoints.
///
/// Register at https://myanimelist.net/apiconfig — "App type: Other", redirect
/// URI `http://127.0.0.1:53682/mal-oauth` (RFC 8252 loopback). PKCE-only
/// (no client secret).
///
/// **MAL quirk**: `code_challenge_method` must be `plain` — MAL rejects `S256`
/// despite RFC 7636. See [MalAuthService.authorize].
class MalConstants {
  MalConstants._();

  static const String clientId = '463b1c92992505e4bdfcef6aab3aedbe';

  static const String apiBase = 'https://api.myanimelist.net/v2';
  static const String oauthBase = 'https://myanimelist.net/v1/oauth2';

  static const String authorizeUrl = '$oauthBase/authorize';
  static const String tokenUrl = '$oauthBase/token';

  static Map<String, String> headers({String? accessToken}) => {
    'Accept': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
}
