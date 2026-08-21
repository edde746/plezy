import '../oauth_proxy_client.dart';
import '../oauth_proxy_auth_service.dart';
import '../tracker_constants.dart';
import '../tracker_session.dart';

/// AniList authentication via the Plezy relay's OAuth proxy.
///
/// We use AniList's authorization-code grant (not implicit), exchanged
/// server-side so the device never sees the fragment. The proxy handles both
/// state + client_secret; the device just gets the bearer token.
class AnilistAuthService extends OAuthProxyAuthServiceBase {
  AnilistAuthService({super.proxy});

  @override
  String get service => 'anilist';

  @override
  TrackerSession buildSession(OAuthProxyResult result) =>
      TrackerSession.fromOAuthProxyResult(TrackerService.anilist, result);
}
