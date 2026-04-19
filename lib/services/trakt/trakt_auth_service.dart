import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/trakt/trakt_device_code.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
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

  /// Request a device code. The returned [TraktDeviceCode.userCode] is what
  /// the user must enter at [TraktDeviceCode.verificationUrl].
  Future<TraktDeviceCode> createDeviceCode() async {
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

    return TraktDeviceCode.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  /// Poll the device-token endpoint until the user authorizes, denies, or the
  /// code expires. Yields one event per poll attempt; the stream completes
  /// after the first terminal event ([TraktDevicePollSuccess],
  /// [TraktDevicePollDenied], [TraktDevicePollExpired]).
  ///
  /// Pass [shouldCancel] to abort polling early (e.g. user dismissed the
  /// dialog).
  Stream<TraktDevicePollEvent> pollDeviceCode(TraktDeviceCode code, {bool Function()? shouldCancel}) async* {
    var interval = Duration(seconds: code.interval);
    final deadline = DateTime.now().add(Duration(seconds: code.expiresIn));

    while (DateTime.now().isBefore(deadline)) {
      if (shouldCancel != null && shouldCancel()) return;

      await Future<void>.delayed(interval);

      if (shouldCancel != null && shouldCancel()) return;

      http.Response res;
      final tokenUri = Uri.parse(TraktConstants.deviceTokenUrl);
      final sw = Stopwatch()..start();
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
        sw.stop();
        appLogger.d('Trakt POST ${tokenUri.path} → ${res.statusCode} (${sw.elapsedMilliseconds}ms)');
      } catch (e) {
        appLogger.d('Trakt device-code poll error (transient)', error: e);
        yield const TraktDevicePollPending();
        continue;
      }

      switch (res.statusCode) {
        case 200:
          final body = json.decode(res.body) as Map<String, dynamic>;
          yield TraktDevicePollSuccess(body);
          return;
        case 400:
          // Pending — keep polling
          yield const TraktDevicePollPending();
          break;
        case 404:
          // Code not found / expired
          yield const TraktDevicePollExpired();
          return;
        case 409:
          // Already used
          yield const TraktDevicePollDenied();
          return;
        case 410:
          yield const TraktDevicePollExpired();
          return;
        case 418:
          // Denied
          yield const TraktDevicePollDenied();
          return;
        case 429:
          // Slow down — increase interval by 5s
          interval += const Duration(seconds: 5);
          yield const TraktDevicePollSlowDown();
          break;
        default:
          appLogger.w('Trakt device-code unexpected HTTP ${res.statusCode}: ${res.body}');
          yield const TraktDevicePollPending();
      }
    }

    yield const TraktDevicePollExpired();
  }
}

class TraktAuthFlowException implements Exception {
  final String message;
  const TraktAuthFlowException(this.message);
  @override
  String toString() => 'TraktAuthFlowException: $message';
}
