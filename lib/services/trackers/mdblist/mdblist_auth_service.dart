import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/trackers/device_code.dart';
import '../../../utils/abortable_http_request.dart';
import '../../../utils/app_logger.dart';
import '../device_code_auth_service.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_session.dart';
import 'mdblist_constants.dart';

/// MDBList OAuth Device Authorization Grant (RFC 8628).
///
/// The user opens `mdblist.com/oauth/device/` on any second device and
/// approves the shown code; the app polls the token endpoint meanwhile. No
/// redirect URI, no local listener and no client secret are involved, so the
/// same flow works identically on TV, mobile and desktop.
///
/// Unlike Trakt, MDBList reports poll state in the JSON body rather than
/// through distinct status codes — `authorization_pending` and `slow_down`
/// both arrive as HTTP 400 — so [probe] switches on `error`, not the status.
class MdblistAuthService extends DeviceCodeAuthServiceBase {
  /// MDBList returns these for a terminally-invalid grant (revoked or expired
  /// refresh token); anything else (5xx, network) is transient and must not
  /// log the user out.
  static const Set<int> _permanentRefreshFailureStatuses = {400, 401, 403};

  /// Fallbacks for a response that omits them. MDBList currently answers with
  /// a 30-minute window and a 5-second interval.
  static const int _defaultExpiresIn = 1800;
  static const int _defaultInterval = 5;

  MdblistAuthService({super.httpClient});

  @override
  Future<DeviceCode> createDeviceCode() async {
    final uri = Uri.parse(MdblistConstants.deviceAuthorizationUrl);
    final res = await sendAbortableHttpRequest(
      httpClient,
      'POST',
      uri,
      body: {'client_id': MdblistConstants.clientId, 'scope': MdblistConstants.scope},
      timeout: TrackerConstants.authRequestTimeout,
      operation: 'MDBList device code request',
    );
    appLogger.d('MDBList POST ${uri.path} → ${res.statusCode}');

    if (res.statusCode != 200) {
      throw DeviceCodeAuthFlowException('MDBList device code request failed: HTTP ${res.statusCode}');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final userCode = body['user_code'] as String;
    final verificationUrl = body['verification_uri'] as String? ?? MdblistConstants.verificationUrl;
    return DeviceCode(
      deviceCode: body['device_code'] as String,
      userCode: userCode,
      verificationUrl: verificationUrl,
      // MDBList omits `verification_uri_complete`, but its device page seeds
      // the form from `?user_code=`, so build the prefilled link ourselves and
      // still prefer a server-supplied one if it ever starts sending it.
      verificationUrlComplete:
          body['verification_uri_complete'] as String? ??
          MdblistConstants.verificationUrlFor(userCode, verificationUrl: verificationUrl),
      expiresIn: (body['expires_in'] as num?)?.toInt() ?? _defaultExpiresIn,
      interval: (body['interval'] as num?)?.toInt() ?? _defaultInterval,
    );
  }

  @override
  Future<DevicePollEvent> probe(DeviceCode code) async {
    final tokenUri = Uri.parse(MdblistConstants.tokenUrl);
    final http.Response res;
    try {
      res = await sendAbortableHttpRequest(
        httpClient,
        'POST',
        tokenUri,
        body: {
          'grant_type': MdblistConstants.deviceCodeGrantType,
          'device_code': code.deviceCode,
          'client_id': MdblistConstants.clientId,
        },
        timeout: TrackerConstants.authRequestTimeout,
        operation: 'MDBList device token poll',
      );
    } catch (e) {
      appLogger.d('MDBList device-code poll error (transient)', error: e);
      return const DevicePollPending();
    }

    final body = _decodeBody(res.body);
    if (res.statusCode == 200 && body['access_token'] != null) {
      return DevicePollSuccess(body);
    }

    return switch (body['error']) {
      'authorization_pending' => const DevicePollPending(),
      'slow_down' => const DevicePollSlowDown(),
      'access_denied' => const DevicePollDenied(),
      // `device_not_found` is MDBList's own code for a device grant that no
      // longer exists, which is terminal in the same way as an expiry.
      'expired_token' || 'device_not_found' => const DevicePollExpired(),
      final error => _unexpected(error, res.statusCode),
    };
  }

  /// Keep polling on anything unrecognised: the deadline in the poll loop
  /// still bounds the flow, and treating an unknown code as terminal would
  /// abandon an authorization the user may be about to complete.
  static DevicePollEvent _unexpected(Object? error, int statusCode) {
    appLogger.w('MDBList device-code unexpected response (HTTP $statusCode, error=$error)');
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
      TrackerSession.fromTokenResponse(TrackerService.mdblist, tokenResponse);

  /// Exchange the refresh token for a fresh access token. Public client, so
  /// no secret rides along — only the client ID.
  Future<TrackerSession> refresh(TrackerSession current) async {
    final res = await sendAbortableHttpRequest(
      httpClient,
      'POST',
      Uri.parse(MdblistConstants.tokenUrl),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': current.requireRefreshToken(TrackerService.mdblist),
        'client_id': MdblistConstants.clientId,
      },
      timeout: TrackerConstants.refreshTimeout,
      operation: 'MDBList token refresh',
    );

    if (res.statusCode != 200) {
      appLogger.w('MDBList: refresh failed (HTTP ${res.statusCode})');
      throw TrackerAuthException(
        service: TrackerService.mdblist,
        message: 'Refresh failed: HTTP ${res.statusCode}',
        statusCode: res.statusCode,
        isPermanent: _permanentRefreshFailureStatuses.contains(res.statusCode),
      );
    }

    final fresh = TrackerSession.fromTokenResponse(
      TrackerService.mdblist,
      json.decode(res.body) as Map<String, dynamic>,
    );
    return fresh.copyWith(username: current.username);
  }
}
