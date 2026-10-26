import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/screen_lock_capabilities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const device = ScreenLockCapabilities(deviceKey: 'tablet-a');

  setUp(ScreenLockCapabilities.debugReset);
  tearDown(ScreenLockCapabilities.debugReset);

  test('a demonstrated finger count is allowed on the same device', () {
    expect(device.effectiveFingerCount(4, verifiedFingerCount: 4, verifiedDeviceKey: 'tablet-a'), 4);
  });

  test('a different hardware/build key cannot reuse a previous touch check', () {
    expect(device.effectiveFingerCount(4, verifiedFingerCount: 5, verifiedDeviceKey: 'tablet-b'), 1);
  });

  test('multiple fingers require local proof', () {
    expect(device.effectiveFingerCount(4, verifiedFingerCount: 1, verifiedDeviceKey: ''), 1);
  });

  test('proof must cover the requested finger count', () {
    expect(device.effectiveFingerCount(4, verifiedFingerCount: 3, verifiedDeviceKey: 'tablet-a'), 1);
    expect(device.effectiveFingerCount(3, verifiedFingerCount: 3, verifiedDeviceKey: 'tablet-a'), 3);
  });

  test('corrupt counts are bounded and cannot bypass proof', () {
    expect(device.effectiveFingerCount(-20, verifiedFingerCount: 3, verifiedDeviceKey: 'tablet-a'), 1);
    expect(device.effectiveFingerCount(20, verifiedFingerCount: 3, verifiedDeviceKey: 'tablet-a'), 1);
    expect(device.effectiveFingerCount(20, verifiedFingerCount: 30, verifiedDeviceKey: 'tablet-a'), 5);
  });

  test('unknown identities never share remembered verification', () {
    for (final key in ['', 'unverified:android']) {
      final capability = ScreenLockCapabilities(deviceKey: key);
      expect(capability.canRememberVerification, isFalse);
      expect(capability.effectiveFingerCount(5, verifiedFingerCount: 5, verifiedDeviceKey: key), 1);
    }
  });

  test('probe failures return a conservative stable identity', () async {
    for (final error in [
      MissingPluginException(),
      PlatformException(code: 'unavailable'),
      StateError('no device info'),
    ]) {
      ScreenLockCapabilities.debugReset(loader: () async => throw error);
      final capability = await ScreenLockCapabilities.load();
      expect(capability.deviceKey, startsWith('unverified:'));
      expect(capability.canRememberVerification, isFalse);
      expect(capability.effectiveFingerCount(5, verifiedFingerCount: 5, verifiedDeviceKey: capability.deviceKey), 1);
    }
  });

  test('concurrent callers share one completed probe', () async {
    final probe = Completer<ScreenLockCapabilities>();
    var calls = 0;
    ScreenLockCapabilities.debugReset(
      loader: () {
        calls++;
        return probe.future;
      },
    );

    final first = ScreenLockCapabilities.load();
    final second = ScreenLockCapabilities.load();
    probe.complete(device);

    expect(await first, same(device));
    expect(await second, same(device));
    expect(await ScreenLockCapabilities.load(), same(device));
    expect(calls, 1);
  });
}
