/// Bundled AniList API endpoint.
///
/// Auth is driven entirely by the Plezy relay's OAuth proxy — the device
/// never needs the AniList authorize URL, client ID, or client secret.
/// Tokens are valid for 1 year and have no refresh; users re-auth on expiry.
class AnilistConstants {
  AnilistConstants._();

  static const String apiBase = 'https://graphql.anilist.co';

  static Map<String, String> headers({String? accessToken}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
}
