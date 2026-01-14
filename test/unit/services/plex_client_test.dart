import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/models/plex_config.dart';

void main() {
  group('PlexStreamType', () {
    test('video stream type is 1', () {
      expect(PlexStreamType.video, 1);
    });

    test('audio stream type is 2', () {
      expect(PlexStreamType.audio, 2);
    });

    test('subtitle stream type is 3', () {
      expect(PlexStreamType.subtitle, 3);
    });
  });

  group('ConnectionTestResult', () {
    test('creates with success and latency', () {
      final result = ConnectionTestResult(success: true, latencyMs: 150);

      expect(result.success, true);
      expect(result.latencyMs, 150);
    });

    test('creates with failure and latency', () {
      final result = ConnectionTestResult(success: false, latencyMs: 5000);

      expect(result.success, false);
      expect(result.latencyMs, 5000);
    });
  });

  group('PlexConfig', () {
    test('creates config with required parameters', () {
      final config = PlexConfig(
        baseUrl: 'https://192.168.1.100:32400',
        token: 'test-token',
        clientIdentifier: 'test-client-id',
        product: 'Plezy',
        version: '1.0.0',
      );

      expect(config.baseUrl, 'https://192.168.1.100:32400');
      expect(config.token, 'test-token');
      expect(config.clientIdentifier, 'test-client-id');
      expect(config.product, 'Plezy');
      expect(config.version, '1.0.0');
    });

    test('uses default platform', () {
      final config = PlexConfig(
        baseUrl: 'https://192.168.1.100:32400',
        clientIdentifier: 'test-client-id',
        product: 'Plezy',
        version: '1.0.0',
      );

      expect(config.platform, 'Flutter');
    });

    test('acceptJson defaults to true', () {
      final config = PlexConfig(
        baseUrl: 'https://192.168.1.100:32400',
        clientIdentifier: 'test-client-id',
        product: 'Plezy',
        version: '1.0.0',
      );

      expect(config.acceptJson, true);
    });

    group('headers', () {
      test('includes required headers', () {
        final config = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
        );

        final headers = config.headers;

        expect(headers['X-Plex-Client-Identifier'], 'test-client-id');
        expect(headers['X-Plex-Product'], 'Plezy');
        expect(headers['X-Plex-Version'], '1.0.0');
        expect(headers['X-Plex-Platform'], 'Flutter');
        expect(headers['X-Plex-Client-Profile-Name'], 'Generic');
        expect(headers['Accept-Charset'], 'utf-8');
      });

      test('includes Accept header when acceptJson is true', () {
        final config = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
          acceptJson: true,
        );

        expect(config.headers['Accept'], 'application/json');
      });

      test('excludes Accept header when acceptJson is false', () {
        final config = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
          acceptJson: false,
        );

        expect(config.headers.containsKey('Accept'), false);
      });

      test('includes token when provided', () {
        final config = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          token: 'test-token',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
        );

        expect(config.headers['X-Plex-Token'], 'test-token');
      });

      test('excludes token when not provided', () {
        final config = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
        );

        expect(config.headers.containsKey('X-Plex-Token'), false);
      });

      test('includes device when provided', () {
        final config = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
          device: 'MacBook Pro',
        );

        expect(config.headers['X-Plex-Device'], 'MacBook Pro');
      });

      test('excludes device when not provided', () {
        final config = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
        );

        expect(config.headers.containsKey('X-Plex-Device'), false);
      });
    });

    group('copyWith', () {
      test('copies all values when no overrides provided', () {
        final original = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          token: 'test-token',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
          platform: 'macOS',
          device: 'MacBook Pro',
          acceptJson: true,
          machineIdentifier: 'machine-123',
        );

        final copy = original.copyWith();

        expect(copy.baseUrl, original.baseUrl);
        expect(copy.token, original.token);
        expect(copy.clientIdentifier, original.clientIdentifier);
        expect(copy.product, original.product);
        expect(copy.version, original.version);
        expect(copy.platform, original.platform);
        expect(copy.device, original.device);
        expect(copy.acceptJson, original.acceptJson);
        expect(copy.machineIdentifier, original.machineIdentifier);
      });

      test('overrides specified values', () {
        final original = PlexConfig(
          baseUrl: 'https://192.168.1.100:32400',
          token: 'old-token',
          clientIdentifier: 'test-client-id',
          product: 'Plezy',
          version: '1.0.0',
        );

        final copy = original.copyWith(
          baseUrl: 'https://10.0.0.1:32400',
          token: 'new-token',
        );

        expect(copy.baseUrl, 'https://10.0.0.1:32400');
        expect(copy.token, 'new-token');
        expect(copy.clientIdentifier, original.clientIdentifier);
        expect(copy.product, original.product);
        expect(copy.version, original.version);
      });
    });
  });

  group('PlexClient', () {
    late PlexConfig config;

    setUp(() {
      config = PlexConfig(
        baseUrl: 'https://192.168.1.100:32400',
        token: 'test-token',
        clientIdentifier: 'test-client-id',
        product: 'Plezy',
        version: '1.0.0',
      );
    });

    test('creates client with config and serverId', () {
      final client = PlexClient(
        config,
        serverId: 'server-123',
        serverName: 'My Server',
      );

      expect(client.config.baseUrl, config.baseUrl);
      expect(client.serverId, 'server-123');
      expect(client.serverName, 'My Server');
    });

    test('offline mode is false by default', () {
      final client = PlexClient(
        config,
        serverId: 'server-123',
      );

      expect(client.isOfflineMode, false);
    });

    test('setOfflineMode changes offline state', () {
      final client = PlexClient(
        config,
        serverId: 'server-123',
      );

      client.setOfflineMode(true);
      expect(client.isOfflineMode, true);

      client.setOfflineMode(false);
      expect(client.isOfflineMode, false);
    });

    test('updateToken updates config and returns correct headers', () {
      final client = PlexClient(
        config,
        serverId: 'server-123',
      );

      client.updateToken('new-token-123');

      expect(client.config.token, 'new-token-123');
      expect(client.config.headers['X-Plex-Token'], 'new-token-123');
    });

    test('getThumbnailUrl returns empty string for null path', () {
      final client = PlexClient(
        config,
        serverId: 'server-123',
      );

      expect(client.getThumbnailUrl(null), '');
    });

    test('getThumbnailUrl returns empty string for empty path', () {
      final client = PlexClient(
        config,
        serverId: 'server-123',
      );

      expect(client.getThumbnailUrl(''), '');
    });

    test('getThumbnailUrl constructs URL with token', () {
      final client = PlexClient(
        config,
        serverId: 'server-123',
      );

      final url = client.getThumbnailUrl('/library/metadata/123/thumb/12345');

      expect(url, contains(config.baseUrl));
      expect(url, contains('library/metadata/123/thumb/12345'));
      expect(url, contains('X-Plex-Token=test-token'));
    });

    test('getThumbnailUrl handles path without leading slash', () {
      final client = PlexClient(
        config,
        serverId: 'server-123',
      );

      final url = client.getThumbnailUrl('library/metadata/123/thumb/12345');

      expect(url, contains('${config.baseUrl}/library/metadata/123/thumb/12345'));
    });
  });

  group('PlexClient with endpoint failover', () {
    test('creates client with prioritized endpoints', () {
      final config = PlexConfig(
        baseUrl: 'https://192.168.1.100:32400',
        token: 'test-token',
        clientIdentifier: 'test-client-id',
        product: 'Plezy',
        version: '1.0.0',
      );

      final endpoints = [
        'https://192.168.1.100:32400',
        'https://10.0.0.1:32400',
        'https://external.server.com:32400',
      ];

      // Should not throw
      final client = PlexClient(
        config,
        serverId: 'server-123',
        prioritizedEndpoints: endpoints,
      );

      expect(client, isNotNull);
    });

    test('creates client without endpoints when list is empty', () {
      final config = PlexConfig(
        baseUrl: 'https://192.168.1.100:32400',
        token: 'test-token',
        clientIdentifier: 'test-client-id',
        product: 'Plezy',
        version: '1.0.0',
      );

      // Should not throw with empty list
      final client = PlexClient(
        config,
        serverId: 'server-123',
        prioritizedEndpoints: [],
      );

      expect(client, isNotNull);
    });
  });
}
