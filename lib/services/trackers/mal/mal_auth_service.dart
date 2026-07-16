import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utils/abortable_http_request.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../../utils/platform_http_client_io.dart'
    as platform;
import '../oauth_proxy_client.dart';
import '../oauth_proxy_auth_service.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_session.dart';
import 'mal_constants.dart';

/// MyAnimeList authentication.
///
/// New sessions come from the Plezy relay's OAuth proxy (PKCE is server-side).
/// Refreshes are direct public-client calls against MAL's token endpoint —
/// no proxy needed because refresh requires no redirect.
class MalAuthService extends OAuthProxyAuthServiceBase {
  /// MAL returns these for a terminally-invalid grant (revoked/expired refresh
  /// token); anything else (5xx, network) is transient and must not log out.
  static const Set<int> _permanentRefreshFailureStatuses = {400, 401, 403};

  final http.Client _http;

  MalAuthService({super.proxy, http.Client? httpClient}) : _http = httpClient ?? platform.createPlatformClient();

  @override
  String get service => 'mal';

  @override
  TrackerSession buildSession(OAuthProxyResult result) =>
      TrackerSession.fromOAuthProxyResult(TrackerService.mal, result);

  @override
  void dispose() {
    super.dispose();
    _http.close();
  }

  Future<TrackerSession> refresh(TrackerSession current) async {
    final res = await sendAbortableHttpRequest(
      _http,
      'POST',
      Uri.parse(MalConstants.tokenUrl),
      body: {
        'client_id': MalConstants.clientId,
        'grant_type': 'refresh_token',
        'refresh_token': current.requireRefreshToken(TrackerService.mal),
      },
      timeout: TrackerConstants.requestTimeout,
      operation: 'MAL token refresh',
    );

    if (res.statusCode != 200) {
      appLogger.w('MAL: refresh failed (${res.statusCode}): ${res.body}');
      throw TrackerAuthException(
        service: TrackerService.mal,
        message: 'Refresh failed: HTTP ${res.statusCode}',
        statusCode: res.statusCode,
        isPermanent: _permanentRefreshFailureStatuses.contains(res.statusCode),
      );
    }
    final fresh = TrackerSession.fromTokenResponse(TrackerService.mal, json.decode(res.body) as Map<String, dynamic>);
    return fresh.copyWith(username: current.username);
  }
}
