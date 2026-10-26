import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  test('screen lock defaults preserve the one-finger short hold', () async {
    final settings = await SettingsService.getInstance();
    expect(settings.read(SettingsService.screenLockHoldDurationMs), 500);
    expect(settings.read(SettingsService.screenLockFingerCount), 1);
    expect(settings.read(SettingsService.screenLockVerifiedFingerCount), 1);
    expect(settings.read(SettingsService.screenLockVerifiedDeviceKey), isEmpty);
  });

  test('out-of-range stored lock settings are bounded', () async {
    resetSharedPreferencesForTest(
      initialAsync: {
        'screen_lock_hold_duration_ms': -100,
        'screen_lock_finger_count': 100,
        'screen_lock_verified_finger_count': -1,
      },
    );
    final settings = await SettingsService.getInstance();
    expect(settings.read(SettingsService.screenLockHoldDurationMs), 500);
    expect(settings.read(SettingsService.screenLockFingerCount), 5);
    expect(settings.read(SettingsService.screenLockVerifiedFingerCount), 1);
  });

  test('touch counts and verification do not travel in settings exports', () {
    final portableKeys = SettingsService.portablePrefs.map((pref) => pref.key).toSet();
    expect(portableKeys, contains(SettingsService.screenLockHoldDurationMs.key));
    expect(portableKeys, isNot(contains(SettingsService.screenLockFingerCount.key)));
    expect(portableKeys, isNot(contains(SettingsService.screenLockVerifiedFingerCount.key)));
    expect(portableKeys, isNot(contains(SettingsService.screenLockVerifiedDeviceKey.key)));
  });

  test('reset clears the configured gesture and its device verification', () async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.screenLockHoldDurationMs, 4000);
    await settings.write(SettingsService.screenLockFingerCount, 4);
    await settings.write(SettingsService.screenLockVerifiedFingerCount, 5);
    await settings.write(SettingsService.screenLockVerifiedDeviceKey, 'verified-tablet');
    await settings.resetAllSettings();
    expect(settings.read(SettingsService.screenLockHoldDurationMs), 500);
    expect(settings.read(SettingsService.screenLockFingerCount), 1);
    expect(settings.read(SettingsService.screenLockVerifiedFingerCount), 1);
    expect(settings.read(SettingsService.screenLockVerifiedDeviceKey), isEmpty);
  });
}
