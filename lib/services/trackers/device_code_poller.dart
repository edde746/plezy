import 'dart:async';

import '../../models/trackers/device_code.dart';

/// Runs the RFC 8628 poll loop. Service-specific HTTP is delegated to [probe];
/// this helper owns interval decay (`slow_down`), the deadline window, and the
/// cancel-check cadence so Trakt and Simkl can share it.
///
/// [probe] must perform one poll attempt and return a single event.
/// [DevicePollSlowDown] triggers a 5-second interval bump; terminal events
/// ([DevicePollSuccess], [DevicePollDenied], [DevicePollExpired]) end the
/// stream.
Stream<DevicePollEvent> pollDeviceCode(
  DeviceCode code, {
  required Future<DevicePollEvent> Function() probe,
  bool Function()? shouldCancel,
}) async* {
  var interval = Duration(seconds: code.interval);
  final deadline = DateTime.now().add(Duration(seconds: code.expiresIn));

  while (DateTime.now().isBefore(deadline)) {
    if (shouldCancel != null && shouldCancel()) return;
    await Future<void>.delayed(interval);
    if (shouldCancel != null && shouldCancel()) return;

    final event = await probe();
    yield event;
    switch (event) {
      case DevicePollSuccess() || DevicePollDenied() || DevicePollExpired():
        return;
      case DevicePollSlowDown():
        interval += const Duration(seconds: 5);
      case DevicePollPending():
        break;
    }
  }

  yield const DevicePollExpired();
}
