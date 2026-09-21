import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

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

    test('always requests JSON responses', () {
      final config = PlexConfig(
        baseUrl: 'https://plex.example.com',
        clientIdentifier: 'client-1',
        product: 'Plezy',
        version: '1.0',
      );
      expect(config.headers['Accept'], 'application/json');
    });
  });

  group('X-Plex-Product identity', () {
    PlexConfig config() =>
        PlexConfig(baseUrl: 'https://plex.example.com', clientIdentifier: 'client-1', product: 'Plezy', version: '1.0');

    setUp(() async {
      resetSharedPreferencesForTest();
      await SettingsService.getInstance();
    });

    test('reports the configured product by default', () {
      expect(config().headers['X-Plex-Product'], 'Plezy');
    });

    test('reports Plex for Xbox while the Xbox identity setting is on', () async {
      await SettingsService.instance.write(SettingsService.thisIsAnXbox, true);

      expect(config().reportedProduct, SettingsService.plexForXboxProductName);
      expect(config().headers['X-Plex-Product'], 'Plex for Xbox');
    });
  });
}
