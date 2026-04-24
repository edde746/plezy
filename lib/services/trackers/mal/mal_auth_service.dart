import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utils/app_logger.dart';
import '../../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../../utils/platform_http_client_io.dart'
    as platform;
import '../oauth_proxy_client.dart';
import 'mal_constants.dart';
import 'mal_session.dart';

/// MyAnimeList authentication.
///
/// New sessions come from the Plezy relay's OAuth proxy (PKCE is server-side).
/// Refreshes are direct public-client calls against MAL's token endpoint —
/// no proxy needed because refresh requires no redirect.
class MalAuthService {
  final OAuthProxyClient _proxy;
  final http.Client _http;

  MalAuthService({OAuthProxyClient? proxy, http.Client? httpClient})
    : _proxy = proxy ?? OAuthProxyClient(),
      _http = httpClient ?? platform.createPlatformClient();

  void dispose() {
    _proxy.dispose();
    _http.close();
  }

  /// Drive the full flow. Invokes [onCodeReady] with the QR URL once the
  /// session is created, then long-polls for tokens. Returns null on cancel.
  Future<MalSession?> authorize({
    required void Function(OAuthProxyStart) onCodeReady,
    bool Function()? shouldCancel,
    Future<void>? onCancel,
  }) async {
    final start = await _proxy.start('mal');
    onCodeReady(start);
    final result = await _proxy.poll(start.session, shouldCancel: shouldCancel, onCancel: onCancel);
    if (result == null) return null;
    return MalSession.fromProxyResult(result);
  }

  Future<MalSession> refresh(MalSession current) async {
    final res = await _http
        .post(
          Uri.parse(MalConstants.tokenUrl),
          body: {
            'client_id': MalConstants.clientId,
            'grant_type': 'refresh_token',
            'refresh_token': current.refreshToken,
          },
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      appLogger.w('MAL: refresh failed (${res.statusCode}): ${res.body}');
      throw MalAuthFlowException('Refresh failed: HTTP ${res.statusCode}');
    }
    final fresh = MalSession.fromTokenResponse(json.decode(res.body) as Map<String, dynamic>);
    return fresh.copyWith(username: current.username);
  }
}

class MalAuthFlowException implements Exception {
  final String message;
  const MalAuthFlowException(this.message);
  @override
  String toString() => 'MalAuthFlowException: $message';
}
