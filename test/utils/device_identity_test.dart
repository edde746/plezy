import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/device_identity.dart';

void main() {
  group('sanitizeHeaderValue', () {
    test('passes plain ASCII names through trimmed', () {
      expect(sanitizeHeaderValue('  Living Room TV '), 'Living Room TV');
    });

    // Regression: header values above 0x7F make dart:io throw and CFNetwork
    // emit a Latin-1 byte that UTF-8 header parsers reject as a bad request.
    test('folds accented Latin letters instead of emitting them', () {
      expect(sanitizeHeaderValue("Édouard's Mac"), "Edouard's Mac");
      expect(sanitizeHeaderValue('Bjørn stue-TV'), 'Bjorn stue-TV');
      expect(sanitizeHeaderValue('Håkons Æra Straße'), 'Hakons AEra Strasse');
      expect(sanitizeHeaderValue('Łukasz Đorđe'), 'Lukasz Dorde');
    });

    test('drops code units that have no ASCII equivalent', () {
      expect(sanitizeHeaderValue('📱 Bob\'s iPhone'), "Bob's iPhone");
      expect(sanitizeHeaderValue('电视'), isNull);
    });

    test('strips HTTP control characters', () {
      expect(sanitizeHeaderValue('\u0000Living\u001f Room\u007f TV'), 'Living Room TV');
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
