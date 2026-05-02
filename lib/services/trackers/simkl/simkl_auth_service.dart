import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/trackers/device_code.dart';
import '../../../utils/app_logger.dart';
import '../device_code_auth_service.dart';
import '../oauth_proxy_client.dart';
import '../tracker_constants.dart';
import 'simkl_constants.dart';
import 'simkl_session.dart';

/// Simkl OAuth PIN (device-code) flow.
///
/// `GET /oauth/pin?client_id=...&redirect=<success page>` returns a PIN the
/// user enters at https://simkl.com/pin. After entry Simkl redirects the
/// browser to the relay's static "signed in" page. The app polls
/// `/oauth/pin/<user_code>?client_id=...` until `result == "OK"`.
class SimklAuthService extends DeviceCodeAuthServiceBase<SimklSession> {
  SimklAuthService({super.httpClient});

  @override
  Future<DeviceCode> createDeviceCode() async {
    final uri = Uri.parse(SimklConstants.pinUrl).replace(
      queryParameters: {'client_id': SimklConstants.clientId, 'redirect': '${OAuthProxyClient.baseUrl}/auth/done'},
    );
    final res = await httpClient
        .get(uri, headers: SimklConstants.headers())
        .timeout(TrackerConstants.authRequestTimeout);
    if (res.statusCode != 200) {
      throw DeviceCodeAuthFlowException('Simkl PIN request failed: HTTP ${res.statusCode}: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return DeviceCode(
      deviceCode: body['device_code'] as String,
      userCode: body['user_code'] as String,
      verificationUrl: body['verification_url'] as String? ?? SimklConstants.verificationUrl,
      // Simkl doesn't expose a prefilled URL; the user manually enters the code.
      verificationUrlComplete: null,
      expiresIn: (body['expires_in'] as num?)?.toInt() ?? 900,
      interval: (body['interval'] as num?)?.toInt() ?? 5,
    );
  }

  @override
  Future<DevicePollEvent> probe(DeviceCode code) async {
    final pollUri = Uri.parse(
      SimklConstants.pinPollUrl(code.userCode),
    ).replace(queryParameters: {'client_id': SimklConstants.clientId});
    final http.Response res;
    try {
      res = await httpClient
          .get(pollUri, headers: SimklConstants.headers())
          .timeout(TrackerConstants.authRequestTimeout);
    } catch (e) {
      appLogger.d('Simkl device-code poll error (transient)', error: e);
      return const DevicePollPending();
    }

    // Simkl returns 200 for both pending and success; anything else is
    // effectively expired/denied.
    if (res.statusCode != 200) return const DevicePollExpired();

    final body = json.decode(res.body) as Map<String, dynamic>;
    if (body['result'] == 'OK' && body['access_token'] != null) {
      return DevicePollSuccess(body);
    }
    return const DevicePollPending();
  }

  @override
  SimklSession buildSession(Map<String, dynamic> tokenResponse) => SimklSession.fromTokenResponse(tokenResponse);
}
