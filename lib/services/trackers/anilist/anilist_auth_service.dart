import 'dart:async';

import '../loopback_auth_server.dart';
import 'anilist_constants.dart';
import 'anilist_session.dart';

/// AniList OAuth 2.0 implicit grant via RFC 8252 loopback redirect.
///
/// AniList returns the access token in the URL fragment, which browsers
/// don't send to servers. [LoopbackAuthServer] serves a tiny HTML page that
/// rewrites `location.hash` into a query string and reloads — the second
/// request is then captured normally.
class AnilistAuthService {
  static const String _callbackPath = '/anilist-oauth';

  /// Drive the full flow. Returns `null` if the user closes the browser
  /// before completing.
  Future<AnilistSession?> authorize() async {
    // AniList's implicit grant rejects the authorize request when
    // `redirect_uri` is present — MAL-Sync omits it too. The redirect URL
    // registered for the client at anilist.co is used automatically.
    final authorizeUri = Uri.parse(AnilistConstants.oauthAuthorizeUrl).replace(
      queryParameters: {'client_id': AnilistConstants.clientId, 'response_type': 'token'},
    );

    final callback = await LoopbackAuthServer.launchAndWait(authorizeUri, path: _callbackPath);
    if (callback == null) return null;

    final params = callback.queryParameters;
    final token = params['access_token'];
    if (token == null) {
      throw AnilistAuthFlowException('AniList redirect missing access_token: $callback');
    }

    final expiresIn = int.tryParse(params['expires_in'] ?? '') ?? (365 * 24 * 60 * 60);
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return AnilistSession(accessToken: token, expiresAt: createdAt + expiresIn, createdAt: createdAt);
  }
}

class AnilistAuthFlowException implements Exception {
  final String message;
  const AnilistAuthFlowException(this.message);
  @override
  String toString() => 'AnilistAuthFlowException: $message';
}
