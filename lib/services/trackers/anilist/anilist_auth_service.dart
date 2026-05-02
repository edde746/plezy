import '../oauth_proxy_client.dart';
import '../oauth_proxy_auth_service.dart';
import 'anilist_session.dart';

/// AniList authentication via the Plezy relay's OAuth proxy.
///
/// We use AniList's authorization-code grant (not implicit), exchanged
/// server-side so the device never sees the fragment. The proxy handles both
/// state + client_secret; the device just gets the bearer token.
class AnilistAuthService extends OAuthProxyAuthServiceBase<AnilistSession> {
  AnilistAuthService({OAuthProxyClient? proxy}) : super(proxy: proxy);

  @override
  String get service => 'anilist';

  @override
  AnilistSession buildSession(OAuthProxyResult result) => AnilistSession.fromProxyResult(result);
}
