/// Bundled AniList API credentials and endpoints.
///
/// Register at https://anilist.co/settings/developer — redirect URL must be
/// `http://127.0.0.1:53682/anilist-oauth` (RFC 8252 loopback). AniList uses
/// OAuth 2.0 Implicit Grant; access tokens are valid for 1 year and have no
/// refresh — the user must re-auth on expiry.
class AnilistConstants {
  AnilistConstants._();

  static const String clientId = '39867';

  static const String apiBase = 'https://graphql.anilist.co';
  static const String oauthAuthorizeUrl = 'https://anilist.co/api/v2/oauth/authorize';

  static Map<String, String> headers({String? accessToken}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
}
