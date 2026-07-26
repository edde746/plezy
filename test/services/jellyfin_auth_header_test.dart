import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_auth_header.dart';

void main() {
  group('buildJellyfinAuthHeader', () {
    test('formats the SDK-style MediaBrowser header', () {
      final header = buildJellyfinAuthHeader(
        clientName: 'Plezy',
        clientVersion: '1.2.3',
        deviceName: 'Living Room TV',
        deviceId: 'dev-1',
        accessToken: 'tok',
      );
      expect(
        header,
        'MediaBrowser Client="Plezy", Device="Living Room TV", DeviceId="dev-1", Version="1.2.3", Token="tok"',
      );
    });

    test('omits Token when access token is null or empty', () {
      for (final token in [null, '']) {
        final header = buildJellyfinAuthHeader(
          clientName: 'Plezy',
          clientVersion: '1.2.3',
          deviceName: 'Plezy',
          deviceId: 'dev-1',
          accessToken: token,
        );
        expect(header, isNot(contains('Token=')));
      }
    });

    test('strips embedded quotes so a device name cannot corrupt the header', () {
      final header = buildJellyfinAuthHeader(
        clientName: 'Plezy',
        clientVersion: '1.2.3',
        deviceName: 'My "cool" TV',
        deviceId: 'dev-1',
        accessToken: 'tok',
      );
      expect(header, contains('Device="My cool TV"'));
    });

    test('uses non-empty fallbacks for required session identity fields', () {
      final header = buildJellyfinAuthHeader(
        clientName: '',
        clientVersion: '   ',
        deviceName: '\u0000\u007f',
        deviceId: 'dev-1',
      );

      expect(header, 'MediaBrowser Client="Plezy", Device="Plezy", DeviceId="dev-1", Version="1.0"');
    });

    test('omits an empty device ID instead of emitting a malformed field', () {
      final header = buildJellyfinAuthHeader(
        clientName: 'Plezy',
        clientVersion: '1.2.3',
        deviceName: 'Living Room',
        deviceId: '',
        accessToken: 'tok',
      );

      expect(header, isNot(contains('DeviceId=')));
      expect(header, contains('Token="tok"'));
    });

    test('rejects an empty or unsafe unauthenticated device ID', () {
      for (final deviceId in ['', ' dev-1 ', 'dev\u0000-1', '"dev-1"']) {
        expect(() => requireJellyfinDeviceId(deviceId), throwsArgumentError);
      }
      expect(requireJellyfinDeviceId('dev-1'), 'dev-1');
    });
  });
}
