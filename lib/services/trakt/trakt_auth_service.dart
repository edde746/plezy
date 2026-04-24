import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/trackers/device_code.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../trackers/device_code_poller.dart' as poller;
import 'trakt_constants.dart';

/// Trakt OAuth Device Authorization Grant flow (RFC 8628).
///
/// Mirrors the shape of `PlexAuthService.pollPinUntilClaimed`. The user enters
/// a short code at `trakt.tv/activate` (in any browser); the app polls
/// `/oauth/device/token` until the user completes the flow.
class TraktAuthService {
  final http.Client _http;

  TraktAuthService({http.Client? httpClient}) : _http = httpClient ?? platform.createPlatformClient();

  void dispose() => _http.close();

  /// Request a device code. The returned [DeviceCode.userCode] is what the
  /// user must enter at [DeviceCode.verificationUrl].
  Future<DeviceCode> createDeviceCode() async {
    final uri = Uri.parse(TraktConstants.deviceCodeUrl);
    final sw = Stopwatch()..start();
    final res = await _http
        .post(uri, headers: TraktConstants.headers(), body: json.encode({'client_id': TraktConstants.clientId}))
        .timeout(const Duration(seconds: 15));
    sw.stop();
    appLogger.d('Trakt POST ${uri.path} → ${res.statusCode} (${sw.elapsedMilliseconds}ms)');

    if (res.statusCode != 200) {
      throw TraktAuthFlowException('Device code request failed: HTTP ${res.statusCode}: ${res.body}');
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

  /// Poll the device-token endpoint until the user authorizes, denies, or the
  /// code expires. Pass [shouldCancel] to abort early.
  Stream<DevicePollEvent> pollDeviceCode(DeviceCode code, {bool Function()? shouldCancel}) {
    return poller.pollDeviceCode(code, shouldCancel: shouldCancel, probe: () => _probe(code));
  }

  Future<DevicePollEvent> _probe(DeviceCode code) async {
    final tokenUri = Uri.parse(TraktConstants.deviceTokenUrl);
    final http.Response res;
    try {
      res = await _http
          .post(
            tokenUri,
            headers: TraktConstants.headers(),
            body: json.encode({
              'code': code.deviceCode,
              'client_id': TraktConstants.clientId,
              'client_secret': TraktConstants.clientSecret,
            }),
          )
          .timeout(const Duration(seconds: 15));
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
}

class TraktAuthFlowException implements Exception {
  final String message;
  const TraktAuthFlowException(this.message);
  @override
  String toString() => 'TraktAuthFlowException: $message';
}
