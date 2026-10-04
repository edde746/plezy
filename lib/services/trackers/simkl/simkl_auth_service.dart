import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/trackers/device_code.dart';
import '../../../utils/abortable_http_request.dart';
import '../../../utils/app_logger.dart';
import '../device_code_auth_service.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_session.dart';
import 'simkl_constants.dart';

/// Simkl AUTH V2 device authorization grant (RFC 8628).
///
/// The user opens simkl.com on any device and approves the shown code while
/// the app polls the token endpoint. Every sign-in goes through the V2 app;
/// AUTH V1 tokens are never minted any more.
///
/// Like MDBList, poll state rides the JSON `error` of an HTTP 400, so [probe]
/// switches on the body. Simkl has no deny signal: a user who declines keeps
/// producing `authorization_pending`, and only the poll deadline ends the flow.
class SimklAuthService extends DeviceCodeAuthServiceBase {
  /// A terminally-invalid grant (revoked or expired refresh token); anything
  /// else (5xx, network) is transient and must not log the user out.
  static const Set<int> _permanentRefreshFailureStatuses = {400, 401, 403};

  /// Fallbacks for a response that omits them; Simkl documents 15 minutes
  /// and 5 seconds.
  static const int _defaultExpiresIn = 900;
  static const int _defaultInterval = 5;

  SimklAuthService({super.httpClient});

  @override
  Future<DeviceCode> createDeviceCode() async {
    final uri = Uri.parse(SimklConstants.deviceAuthorizationUrl);
    final res = await sendAbortableHttpRequest(
      httpClient,
      'POST',
      uri,
      headers: SimklConstants.oauthHeaders(appVersion: await SimklConstants.appVersion()),
      body: {'client_id': SimklConstants.v2ClientId, 'scope': SimklConstants.scope},
      timeout: TrackerConstants.authRequestTimeout,
      operation: 'Simkl device code request',
    );
    appLogger.d('Simkl POST ${uri.path} → ${res.statusCode}');

    if (res.statusCode != 200) {
      throw DeviceCodeAuthFlowException('Simkl device code request failed: HTTP ${res.statusCode}');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    return DeviceCode(
      deviceCode: body['device_code'] as String,
      userCode: body['user_code'] as String,
      verificationUrl: body['verification_uri'] as String,
      verificationUrlComplete: body['verification_uri_complete'] as String?,
      expiresIn: (body['expires_in'] as num?)?.toInt() ?? _defaultExpiresIn,
      interval: (body['interval'] as num?)?.toInt() ?? _defaultInterval,
    );
  }

  @override
  Future<DevicePollEvent> probe(DeviceCode code) async {
    final http.Response res;
    try {
      res = await sendAbortableHttpRequest(
        httpClient,
        'POST',
        Uri.parse(SimklConstants.tokenUrl),
        headers: SimklConstants.oauthHeaders(appVersion: await SimklConstants.appVersion()),
        body: {
          'grant_type': SimklConstants.deviceCodeGrantType,
          'client_id': SimklConstants.v2ClientId,
          'device_code': code.deviceCode,
        },
        timeout: TrackerConstants.authRequestTimeout,
        operation: 'Simkl device token poll',
      );
    } catch (e) {
      appLogger.d('Simkl device-code poll error (transient)', error: e);
      return const DevicePollPending();
    }

    final body = _decodeBody(res.body);
    if (res.statusCode == 200 && body['access_token'] != null) {
      // An omitted or misspelled scope is silently downgraded to read-only.
      // Binding that token would look connected and then fail every write, so
      // the connect fails instead.
      if (!_grantsWrite(body['scope'])) {
        appLogger.w('Simkl: authorization granted without ${SimklConstants.writeScope}; not connecting');
        return const DevicePollDenied();
      }
      return DevicePollSuccess(body);
    }

    return switch (body['error']) {
      'authorization_pending' => const DevicePollPending(),
      'slow_down' => const DevicePollSlowDown(),
      'access_denied' => const DevicePollDenied(),
      'expired_token' => const DevicePollExpired(),
      // Raised during client authentication, before the device code is even
      // looked at: polling again can never succeed.
      'invalid_client' => _invalidClient(res.statusCode),
      final error => _unexpected(error, res.statusCode),
    };
  }

  static bool _grantsWrite(Object? scope) => scope is String && scope.split(' ').contains(SimklConstants.writeScope);

  static DevicePollEvent _invalidClient(int statusCode) {
    appLogger.e('Simkl device-code poll rejected the client (HTTP $statusCode, invalid_client)');
    return const DevicePollExpired();
  }

  /// Keep polling on anything unrecognised: the deadline in the poll loop
  /// still bounds the flow, and treating an unknown code as terminal would
  /// abandon an authorization the user may be about to complete.
  static DevicePollEvent _unexpected(Object? error, int statusCode) {
    appLogger.w('Simkl device-code unexpected response (HTTP $statusCode, error=$error)');
    return const DevicePollPending();
  }

  static Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = json.decode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  @override
  TrackerSession buildSession(Map<String, dynamic> tokenResponse) =>
      TrackerSession.fromTokenResponse(TrackerService.simkl, tokenResponse);

  /// Exchange the refresh token for a fresh access token. Simkl's refresh is
  /// non-rotating: the same refresh token normally comes back, and a response
  /// that omits it keeps the current one.
  Future<TrackerSession> refresh(TrackerSession current) async {
    final refreshToken = current.requireRefreshToken(TrackerService.simkl);
    final res = await sendAbortableHttpRequest(
      httpClient,
      'POST',
      Uri.parse(SimklConstants.tokenUrl),
      headers: SimklConstants.oauthHeaders(appVersion: await SimklConstants.appVersion()),
      body: {'grant_type': 'refresh_token', 'client_id': SimklConstants.v2ClientId, 'refresh_token': refreshToken},
      timeout: TrackerConstants.refreshTimeout,
      operation: 'Simkl token refresh',
    );

    if (res.statusCode != 200) {
      appLogger.w('Simkl: refresh failed (HTTP ${res.statusCode})');
      throw TrackerAuthException(
        service: TrackerService.simkl,
        message: 'Refresh failed: HTTP ${res.statusCode}',
        statusCode: res.statusCode,
        isPermanent: _permanentRefreshFailureStatuses.contains(res.statusCode),
      );
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final fresh = TrackerSession.fromTokenResponse(TrackerService.simkl, {
      ...body,
      if (body['refresh_token'] is! String || (body['refresh_token'] as String).isEmpty) 'refresh_token': refreshToken,
    });
    return fresh.copyWith(username: current.username);
  }
}
