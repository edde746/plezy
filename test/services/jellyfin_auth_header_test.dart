import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_auth_header.dart';
import 'package:plezy/utils/device_identity.dart';

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

  // Jellyfin and Emby sessions carry no platform field, so session trackers
  // (Tracearr's `normalizeClient`, for one) keyword-match the Client string
  // the way they do for `Jellyfin Android TV` and `Swiftfin tvOS`. Each
  // expected value below was checked against that matcher.
  group('jellyfinClientName', () {
    test('appends the platform the way the first-party apps do', () {
      for (final platform in ['iOS', 'Android', 'macOS', 'Windows', 'Linux']) {
        expect(jellyfinClientName(DeviceIdentity(platform: platform)), 'Plezy $platform');
      }
    });

    test('names the Android TV variant without repeating TV for tvOS', () {
      expect(jellyfinClientName(const DeviceIdentity(platform: 'Android', isTv: true)), 'Plezy Android TV');
      expect(jellyfinClientName(const DeviceIdentity(platform: 'tvOS', isTv: true)), 'Plezy tvOS');
    });

    test('keeps the TV suffix on the degraded lowercase OS name', () {
      // DeviceIdentityService falls back to Platform.operatingSystem when the
      // platform plugin fails, and that is lowercase.
      expect(jellyfinClientName(const DeviceIdentity(platform: 'android', isTv: true)), 'Plezy Android TV');
    });

    test('only Android gets a TV suffix', () {
      expect(jellyfinClientName(const DeviceIdentity(platform: 'Linux', isTv: true)), 'Plezy Linux');
    });

    test('falls back to the bare app name without a platform', () {
      expect(jellyfinClientName(const DeviceIdentity(platform: '')), 'Plezy');
      expect(jellyfinClientName(const DeviceIdentity(platform: ' \u0000 ')), 'Plezy');
    });

    test('survives the header round trip', () {
      final header = buildJellyfinAuthHeader(
        clientName: jellyfinClientName(const DeviceIdentity(platform: 'Android', isTv: true)),
        clientVersion: '2.19.0',
        deviceName: 'Living Room Shield',
        deviceId: 'dev-1',
      );
      expect(parseAsJellyfinWould(header)['Client'], 'Plezy Android TV');
    });
  });

  group('jellyfinDeviceName', () {
    test('prefers the user-facing device name', () {
      const identity = DeviceIdentity(platform: 'iOS', deviceModel: 'iPhone', deviceName: '  Bob\'s iPhone ');
      expect(jellyfinDeviceName(identity), "Bob's iPhone");
    });

    test('falls back to the hardware model when the name lookup failed', () {
      // An Apple TV without a resolvable name should be listed as `Apple TV`,
      // not as a second `Plezy` next to the client name.
      const identity = DeviceIdentity(platform: 'tvOS', deviceModel: 'Apple TV', isTv: true);
      expect(jellyfinDeviceName(identity), 'Apple TV');
      expect(
        jellyfinDeviceName(const DeviceIdentity(platform: 'tvOS', deviceModel: 'Apple TV', deviceName: '   ')),
        'Apple TV',
      );
    });

    test('falls back to the platform when there is no model either', () {
      expect(jellyfinDeviceName(const DeviceIdentity(platform: 'Linux')), 'Linux');
      expect(jellyfinDeviceName(const DeviceIdentity(platform: 'Linux', deviceModel: '\u0000')), 'Linux');
    });

    test('falls back to the app name when nothing about the device is known', () {
      expect(jellyfinDeviceName(const DeviceIdentity(platform: '')), 'Plezy');
    });
  });

  group('jellyfinClientName and jellyfinDeviceName', () {
    test('derive from the same resolved identity', () async {
      // The production call sites resolve one identity and derive both names
      // from it, so an override must steer both.
      DeviceIdentityService.debugOverride(const DeviceIdentity(platform: 'Android', deviceModel: 'AFTKM', isTv: true));
      addTearDown(() => DeviceIdentityService.debugOverride(null));
      final identity = await DeviceIdentityService.resolve();
      expect(jellyfinClientName(identity), 'Plezy Android TV');
      expect(jellyfinDeviceName(identity), 'AFTKM');
    });
  });
}
