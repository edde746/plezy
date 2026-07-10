import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/device_identity.dart';

void main() {
  group('sanitizeHeaderValue', () {
    test('passes plain latin-1 names through trimmed', () {
      expect(sanitizeHeaderValue('  Living Room TV '), 'Living Room TV');
      expect(sanitizeHeaderValue("Édouard's Mac"), "Édouard's Mac");
    });

    test('strips code units above latin-1 (emoji would break dart:io headers)', () {
      expect(sanitizeHeaderValue('📱 Bob\'s iPhone'), "Bob's iPhone");
      expect(sanitizeHeaderValue('电视'), isNull);
    });

    test('strips CR/LF', () {
      expect(sanitizeHeaderValue('evil\r\nX-Injected: 1'), 'evilX-Injected: 1');
    });

    test('returns null for null, empty, and whitespace-only input', () {
      expect(sanitizeHeaderValue(null), isNull);
      expect(sanitizeHeaderValue(''), isNull);
      expect(sanitizeHeaderValue('   '), isNull);
    });
  });

  group('DeviceIdentityService.debugOverride', () {
    tearDown(() => DeviceIdentityService.debugOverride(null));

    test('resolve returns the overridden identity', () async {
      const identity = DeviceIdentity(platform: 'TestOS', deviceModel: 'Model-X', deviceName: 'Unit Test', isTv: true);
      DeviceIdentityService.debugOverride(identity);
      final resolved = await DeviceIdentityService.resolve();
      expect(resolved.platform, 'TestOS');
      expect(resolved.deviceModel, 'Model-X');
      expect(resolved.deviceName, 'Unit Test');
      expect(resolved.isTv, isTrue);
    });

    test('a later override replaces the memoized value', () async {
      DeviceIdentityService.debugOverride(const DeviceIdentity(platform: 'First'));
      expect((await DeviceIdentityService.resolve()).platform, 'First');
      DeviceIdentityService.debugOverride(const DeviceIdentity(platform: 'Second'));
      expect((await DeviceIdentityService.resolve()).platform, 'Second');
    });
  });
}
