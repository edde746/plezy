import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_auth_header.dart';

/// Every field value Jellyfin reads back out of the header, mirroring the
/// server's own parse: split on the top-level commas, strip the quotes, then
/// `UrlDecode` (`WebUtility.UrlDecode` in `AuthorizationContext.GetParts`).
Map<String, String> parseAsJellyfinWould(String header) {
  expect(header, startsWith('MediaBrowser '));
  return {
    for (final part in header.substring('MediaBrowser '.length).split(', '))
      part.substring(0, part.indexOf('=')): Uri.decodeComponent(
        part.substring(part.indexOf('=') + 1).replaceAll('"', ''),
      ),
  };
}

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
        'MediaBrowser Client="Plezy", Device="Living%20Room%20TV", DeviceId="dev-1", Version="1.2.3", Token="tok"',
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

    // Regression: 2.9.0 started sending the real device name verbatim, so a
    // non-ASCII one made dart:io reject the header outright and made CFNetwork
    // emit a Latin-1 byte that Jellyfin's host rejects with 400 before the
    // login request is routed.
    test('keeps a non-ASCII device name on the wire as ASCII the server decodes back', () {
      const deviceName = 'Bjørn stue-TV 客厅 📺';
      final header = buildJellyfinAuthHeader(
        clientName: 'Plezy',
        clientVersion: '2.10.0',
        deviceName: deviceName,
        deviceId: 'dev-1',
        accessToken: 'tok',
      );

      // dart:io's own header-value rule: printable ASCII only.
      expect(header, matches(RegExp(r'^[\x20-\x7e]+$')));
      expect(parseAsJellyfinWould(header)['Device'], deviceName);
    });

    test('keeps a device name that would corrupt the header grammar intact', () {
      const deviceName = 'My "cool", TV = 1+2 100%';
      final header = buildJellyfinAuthHeader(
        clientName: 'Plezy',
        clientVersion: '1.2.3',
        deviceName: deviceName,
        deviceId: 'dev-1',
        accessToken: 'tok',
      );

      final parsed = parseAsJellyfinWould(header);
      expect(parsed['Device'], deviceName);
      expect(parsed['Client'], 'Plezy');
      expect(parsed['DeviceId'], 'dev-1');
      expect(parsed['Version'], '1.2.3');
      expect(parsed['Token'], 'tok');
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
