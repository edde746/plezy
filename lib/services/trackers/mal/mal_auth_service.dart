import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../utils/app_logger.dart';
import '../../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../../utils/platform_http_client_io.dart'
    as platform;
import '../loopback_auth_server.dart';
import 'mal_constants.dart';
import 'mal_session.dart';

/// MyAnimeList OAuth 2.0 PKCE flow via RFC 8252 loopback redirect.
///
/// **Quirk**: MAL requires `code_challenge_method=plain` — it rejects `S256`
/// despite RFC 7636.
class MalAuthService {
  static const String _callbackPath = '/mal-oauth';

  final http.Client _http;

  MalAuthService({http.Client? httpClient}) : _http = httpClient ?? platform.createPlatformClient();

  void dispose() => _http.close();

  /// Drive the full flow: build the authorize URL, start a loopback server
  /// for the redirect, launch the browser, exchange the code for tokens.
  /// Returns `null` if the user closes the browser before completing.
  Future<MalSession?> authorize() async {
    final verifier = _randomVerifier();
    final state = _randomVerifier(length: 16);
    final redirectUri = LoopbackAuthServer.redirectUri(_callbackPath);

    final authorizeUri = Uri.parse(MalConstants.authorizeUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': MalConstants.clientId,
        'code_challenge': verifier, // plain method → challenge == verifier
        'code_challenge_method': 'plain',
        'redirect_uri': redirectUri,
        'state': state,
      },
    );

    final callback = await LoopbackAuthServer.launchAndWait(authorizeUri, path: _callbackPath);
    if (callback == null) return null;

    final code = callback.queryParameters['code'];
    final returnedState = callback.queryParameters['state'];
    if (code == null) {
      throw MalAuthFlowException('MAL redirect missing code: $callback');
    }
    if (returnedState != state) {
      throw const MalAuthFlowException('MAL state mismatch (possible CSRF)');
    }

    final res = await _http
        .post(
          Uri.parse(MalConstants.tokenUrl),
          body: {
            'client_id': MalConstants.clientId,
            'code': code,
            'code_verifier': verifier,
            'grant_type': 'authorization_code',
            'redirect_uri': redirectUri,
          },
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw MalAuthFlowException('Token exchange failed: HTTP ${res.statusCode}: ${res.body}');
    }
    return MalSession.fromTokenResponse(json.decode(res.body) as Map<String, dynamic>);
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

  /// MAL requires 43–128 chars from the unreserved URL-safe set.
  String _randomVerifier({int length = 64}) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rand = Random.secure();
    return List.generate(length, (_) => alphabet[rand.nextInt(alphabet.length)]).join();
  }
}

class MalAuthFlowException implements Exception {
  final String message;
  const MalAuthFlowException(this.message);
  @override
  String toString() => 'MalAuthFlowException: $message';
}
