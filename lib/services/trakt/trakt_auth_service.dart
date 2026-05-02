import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/trackers/device_code.dart';
import '../../utils/app_logger.dart';
import '../trackers/device_code_auth_service.dart';
import '../trackers/tracker_constants.dart';
import 'trakt_constants.dart';
import 'trakt_session.dart';

/// Trakt OAuth Device Authorization Grant flow (RFC 8628).
///
/// The user enters a short code at `trakt.tv/activate` (in any browser); the
/// app polls `/oauth/device/token` until the user completes the flow.
class TraktAuthService extends DeviceCodeAuthServiceBase<TraktSession> {
  TraktAuthService({super.httpClient});

  @override
  Future<DeviceCode> createDeviceCode() async {
    final uri = Uri.parse(TraktConstants.deviceCodeUrl);
    final sw = Stopwatch()..start();
    final res = await httpClient
        .post(uri, headers: TraktConstants.headers(), body: json.encode({'client_id': TraktConstants.clientId}))
        .timeout(TrackerConstants.authRequestTimeout);
    sw.stop();
    appLogger.d('Trakt POST ${uri.path} → ${res.statusCode} (${sw.elapsedMilliseconds}ms)');

    if (res.statusCode != 200) {
      throw DeviceCodeAuthFlowException('Trakt device code request failed: HTTP ${res.statusCode}: ${res.body}');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final verificationUrl = body['verification_url'] as String;
    final userCode = body['user_code'] as String;
    return DeviceCode(
      deviceCode: body['device_code'] as String,
      userCode: userCode,
      verificationUrl: verificationUrl,
      verificationUrlComplete: '$verificationUrl/$userCode',
      expiresIn: (body['expires_in'] as num).toInt(),
      interval: (body['interval'] as num).toInt(),
    );
  }

  @override
  Future<DevicePollEvent> probe(DeviceCode code) async {
    final tokenUri = Uri.parse(TraktConstants.deviceTokenUrl);
    final http.Response res;
    try {
      res = await httpClient
          .post(
            tokenUri,
            headers: TraktConstants.headers(),
            body: json.encode({
              'code': code.deviceCode,
              'client_id': TraktConstants.clientId,
              'client_secret': TraktConstants.clientSecret,
            }),
          )
          .timeout(TrackerConstants.authRequestTimeout);
      appLogger.d('Trakt POST ${tokenUri.path} → ${res.statusCode}');
    } catch (e) {
      appLogger.d('Trakt device-code poll error (transient)', error: e);
      return const DevicePollPending();
    }

    switch (res.statusCode) {
      case 200:
        return DevicePollSuccess(json.decode(res.body) as Map<String, dynamic>);
      case 400:
        return const DevicePollPending();
      case 404 || 410:
        return const DevicePollExpired();
      case 409 || 418:
        return const DevicePollDenied();
      case 429:
        return const DevicePollSlowDown();
      default:
        appLogger.w('Trakt device-code unexpected HTTP ${res.statusCode}: ${res.body}');
        return const DevicePollPending();
    }
  }

  @override
  TraktSession buildSession(Map<String, dynamic> tokenResponse) => TraktSession.fromTokenResponse(tokenResponse);
}
