import 'dart:async';

import '../oauth_proxy_client.dart';
import 'anilist_session.dart';

/// AniList authentication via the Plezy relay's OAuth proxy.
///
/// We use AniList's authorization-code grant (not implicit), exchanged
/// server-side so the device never sees the fragment. The proxy handles both
/// state + client_secret; the device just gets the bearer token.
class AnilistAuthService {
  final OAuthProxyClient _proxy;

  AnilistAuthService({OAuthProxyClient? proxy}) : _proxy = proxy ?? OAuthProxyClient();

  void dispose() => _proxy.dispose();

  /// Drive the full flow. Returns null on user cancel.
  Future<AnilistSession?> authorize({
    required void Function(OAuthProxyStart) onCodeReady,
    bool Function()? shouldCancel,
  }) async {
    final start = await _proxy.start('anilist');
    onCodeReady(start);
    final result = await _proxy.poll(start.session, shouldCancel: shouldCancel);
    if (result == null) return null;
    return AnilistSession.fromProxyResult(result);
  }
}
