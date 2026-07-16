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
  });
}
