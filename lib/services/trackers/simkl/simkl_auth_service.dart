import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/trackers/device_code.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../../utils/platform_http_client_io.dart'
    as platform;
import '../device_code_poller.dart' as poller;
import '../loopback_auth_server.dart';
import 'simkl_constants.dart';

/// Simkl OAuth PIN (device-code) flow.
///
/// `GET /oauth/pin?client_id=...&redirect=http://127.0.0.1:53682/simkl-oauth`
/// returns a PIN the user enters at https://simkl.com/pin. After entry Simkl
/// redirects the browser to our loopback callback (where we show a friendly
/// "close this tab" page). The app polls `/oauth/pin/<user_code>?client_id=...`
/// until `result == "OK"`.
class SimklAuthService {
  /// Redirect path Simkl bounces the browser to after PIN entry. Must match
  /// the URL registered at simkl.com/settings/developer for this client.
  static const String _callbackPath = '/simkl-oauth';

  final http.Client _http;

  SimklAuthService({http.Client? httpClient}) : _http = httpClient ?? platform.createPlatformClient();

  void dispose() => _http.close();

  Future<DeviceCode> createDeviceCode() async {
    final uri = Uri.parse(SimklConstants.pinUrl).replace(
      queryParameters: {
        'client_id': SimklConstants.clientId,
        'redirect': LoopbackAuthServer.redirectUri(_callbackPath),
      },
    );
    final res = await _http.get(uri, headers: SimklConstants.headers()).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw SimklAuthFlowException('PIN request failed: HTTP ${res.statusCode}: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 900;

    // Serve the "close this tab" success page when Simkl redirects the
    // browser back after PIN entry. Fire-and-forget — the PIN poll captures
    // the token; this listener is purely cosmetic.
    unawaited(
      LoopbackAuthServer.listenOnce(
        path: _callbackPath,
        timeout: Duration(seconds: expiresIn),
      ).catchError((Object _) => Uri()),
    );

    return DeviceCode(
      deviceCode: body['device_code'] as String,
      userCode: body['user_code'] as String,
      verificationUrl: body['verification_url'] as String? ?? SimklConstants.verificationUrl,
      // Simkl doesn't expose a prefilled URL; the user manually enters the code.
      verificationUrlComplete: null,
      expiresIn: expiresIn,
      interval: (body['interval'] as num?)?.toInt() ?? 5,
    );
  }

  Stream<DevicePollEvent> pollDeviceCode(DeviceCode code, {bool Function()? shouldCancel}) {
    return poller.pollDeviceCode(code, shouldCancel: shouldCancel, probe: () => _probe(code));
  }

  Future<DevicePollEvent> _probe(DeviceCode code) async {
    final pollUri = Uri.parse(
      SimklConstants.pinPollUrl(code.userCode),
    ).replace(queryParameters: {'client_id': SimklConstants.clientId});
    final http.Response res;
    try {
      res = await _http.get(pollUri, headers: SimklConstants.headers()).timeout(const Duration(seconds: 15));
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
}

class SimklAuthFlowException implements Exception {
  final String message;
  const SimklAuthFlowException(this.message);
  @override
  String toString() => 'SimklAuthFlowException: $message';
}
