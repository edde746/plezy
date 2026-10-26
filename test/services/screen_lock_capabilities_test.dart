import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/screen_lock_capabilities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const distinct = 'android.hardware.touchscreen.multitouch.distinct';
  const jazzhand = 'android.hardware.touchscreen.multitouch.jazzhand';
  const device = ScreenLockCapabilities(reportedFingerLimit: 2, deviceKey: 'tablet-a');

  setUp(ScreenLockCapabilities.debugReset);
  tearDown(ScreenLockCapabilities.debugReset);

  test('unknown features and basic multitouch do not promise independent fingers', () {
    for (final features in [
      <String>[],
      ['android.hardware.touchscreen.multitouch'],
      ['android.hardware.touchscreen'],
    ]) {
      final capability = ScreenLockCapabilities.fromSystemFeatures(features, deviceKey: 'tablet-a');
      expect(capability.reportedFingerLimit, 1);
    }
  });

  test('distinct and jazzhand features report their independent-pointer lower bounds', () {
    expect(ScreenLockCapabilities.fromSystemFeatures([distinct], deviceKey: 'tablet-a').reportedFingerLimit, 2);
    expect(ScreenLockCapabilities.fromSystemFeatures([jazzhand], deviceKey: 'tablet-a').reportedFingerLimit, 5);
    expect(
      ScreenLockCapabilities.fromSystemFeatures([distinct, jazzhand], deviceKey: 'tablet-a').reportedFingerLimit,
      5,
    );
  });

  test('a successful local touch check can raise the reported lower bound', () {
    expect(device.supportedFingerLimit(verifiedFingerCount: 4, verifiedDeviceKey: 'tablet-a'), 4);
    expect(device.effectiveFingerCount(4, verifiedFingerCount: 4, verifiedDeviceKey: 'tablet-a'), 4);
  });

  test('a different hardware/build key cannot reuse a previous touch check', () {
    expect(device.supportedFingerLimit(verifiedFingerCount: 5, verifiedDeviceKey: 'tablet-b'), 2);
    expect(device.effectiveFingerCount(4, verifiedFingerCount: 5, verifiedDeviceKey: 'tablet-b'), 1);
  });

  test('jazzhand hardware cannot enable multiple fingers without local proof', () {
    final capability = ScreenLockCapabilities.fromSystemFeatures([jazzhand], deviceKey: 'tablet-a');
    expect(capability.supportedFingerLimit(verifiedFingerCount: 1, verifiedDeviceKey: ''), 5);
    expect(capability.effectiveFingerCount(4, verifiedFingerCount: 1, verifiedDeviceKey: ''), 1);
  });

  test('jazzhand hardware still requires proof from this device', () {
    final capability = ScreenLockCapabilities.fromSystemFeatures([jazzhand], deviceKey: 'tablet-a');
    expect(capability.effectiveFingerCount(4, verifiedFingerCount: 5, verifiedDeviceKey: 'tablet-b'), 1);
  });

  test('jazzhand hardware cannot substitute for proof of the requested finger count', () {
    final capability = ScreenLockCapabilities.fromSystemFeatures([jazzhand], deviceKey: 'tablet-a');
    expect(capability.effectiveFingerCount(4, verifiedFingerCount: 3, verifiedDeviceKey: 'tablet-a'), 1);
    expect(capability.effectiveFingerCount(3, verifiedFingerCount: 3, verifiedDeviceKey: 'tablet-a'), 3);
  });

  test('verification does not narrow reported support and clamps corrupt counts', () {
    expect(device.supportedFingerLimit(verifiedFingerCount: -10, verifiedDeviceKey: 'tablet-a'), 2);
    expect(device.supportedFingerLimit(verifiedFingerCount: 30, verifiedDeviceKey: 'tablet-a'), 5);
    expect(device.effectiveFingerCount(-20, verifiedFingerCount: 3, verifiedDeviceKey: 'tablet-a'), 1);
    expect(device.effectiveFingerCount(20, verifiedFingerCount: 3, verifiedDeviceKey: 'tablet-a'), 1);
    expect(device.effectiveFingerCount(20, verifiedFingerCount: 30, verifiedDeviceKey: 'tablet-a'), 5);
  });

  test('unknown identities never share remembered verification', () {
    for (final key in ['', 'unverified:android']) {
      final capability = ScreenLockCapabilities(reportedFingerLimit: 1, deviceKey: key);
      expect(capability.canRememberVerification, isFalse);
      expect(capability.supportedFingerLimit(verifiedFingerCount: 5, verifiedDeviceKey: key), 1);
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
      expect(capability.reportedFingerLimit, 1);
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
