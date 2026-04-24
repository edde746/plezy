/// Bundled MyAnimeList API endpoints and public client ID.
///
/// The authorize flow lives in the Plezy relay's OAuth proxy; see
/// `lib/services/trackers/oauth_proxy_client.dart`. Only the refresh path
/// (public-client, no redirect) calls MAL directly from the device.
class MalConstants {
  MalConstants._();

  static const String clientId = '463b1c92992505e4bdfcef6aab3aedbe';

  static const String apiBase = 'https://api.myanimelist.net/v2';
  static const String tokenUrl = 'https://myanimelist.net/v1/oauth2/token';

  static Map<String, String> headers({String? accessToken}) => {
    'Accept': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
}
