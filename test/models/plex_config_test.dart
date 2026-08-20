import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_config.dart';

void main() {
  group('PlexConfig.headers', () {
    test('includes X-Plex-Device-Name when deviceName is set', () {
      final config = PlexConfig(
        baseUrl: 'https://plex.example.com',
        clientIdentifier: 'client-1',
        product: 'Plezy',
        version: '1.0',
        platform: 'Windows',
        device: 'Windows',
        deviceName: 'Living Room PC',
      );
      expect(config.headers['X-Plex-Platform'], 'Windows');
      expect(config.headers['X-Plex-Device'], 'Windows');
      expect(config.headers['X-Plex-Device-Name'], 'Living Room PC');
    });

    test('omits X-Plex-Device-Name and X-Plex-Device when unset', () {
      final config = PlexConfig(
        baseUrl: 'https://plex.example.com',
        clientIdentifier: 'client-1',
        product: 'Plezy',
        version: '1.0',
      );
      expect(config.headers.containsKey('X-Plex-Device-Name'), isFalse);
      expect(config.headers.containsKey('X-Plex-Device'), isFalse);
      // Raw-constructor default is unchanged for tests that rely on it.
      expect(config.headers['X-Plex-Platform'], 'Flutter');
    });
  });
}
