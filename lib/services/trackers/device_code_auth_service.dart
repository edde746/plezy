import 'dart:async';

import 'package:http/http.dart' as http;

import '../../models/trackers/device_code.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import 'device_code_poller.dart' as poller;

/// Base for RFC 8628 device-code auth services.
///
/// Owns the HTTP client lifecycle and the full "request code → invoke UI →
/// poll → build session" dance. Subclasses only implement the three
/// service-specific hooks: [createDeviceCode], [probe], [buildSession].
abstract class DeviceCodeAuthServiceBase<T> {
  final http.Client httpClient;

  DeviceCodeAuthServiceBase({http.Client? httpClient})
    : httpClient = httpClient ?? platform.createPlatformClient();

  void dispose() => httpClient.close();

  /// Service-specific device-code request.
  Future<DeviceCode> createDeviceCode();

  /// One service-specific poll attempt — called at each interval tick.
  Future<DevicePollEvent> probe(DeviceCode code);

  /// Build the session object from a successful token response.
  T buildSession(Map<String, dynamic> tokenResponse);

  /// Drive the full flow. Invokes [onCodeReady] once with the code so the UI
  /// can render the dialog, then polls until the user authorizes, denies, or
  /// the code expires. Returns null on denied/expired/cancel.
  Future<T?> authorize({
    required void Function(DeviceCode code) onCodeReady,
    bool Function()? shouldCancel,
  }) async {
    final code = await createDeviceCode();
    onCodeReady(code);
    await for (final event in poller.pollDeviceCode(
      code,
      shouldCancel: shouldCancel,
      probe: () => probe(code),
    )) {
      if (event is DevicePollSuccess) return buildSession(event.tokenResponse);
      if (event is DevicePollDenied || event is DevicePollExpired) return null;
    }
    return null;
  }
}

class DeviceCodeAuthFlowException implements Exception {
  final String message;
  const DeviceCodeAuthFlowException(this.message);
  @override
  String toString() => 'DeviceCodeAuthFlowException: $message';
}
