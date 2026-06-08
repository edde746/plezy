import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/exceptions/media_server_exceptions.dart';
import 'package:vibe_stream/services/jellyfin_endpoint_discovery.dart';

http.Response _info({required String id, String name = 'Home'}) => http.Response(
  jsonEncode({'Id': id, 'ServerName': name, 'Version': '10.9.0'}),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('JellyfinEndpointDiscovery', () {
    test('normalizes and deduplicates endpoint URLs', () {
      expect(
        JellyfinEndpointDiscovery.normalizeBaseUrls([
          ' https://jf.example.com/ ',
          'https://jf.example.com',
          '',
          'https://jf.lan:8096/',
        ]),
        ['https://jf.example.com', 'https://jf.lan:8096'],
      );
      expect(JellyfinEndpointDiscovery.normalizeBaseUrl('jf.example.com/'), 'jf.example.com');
    });

    test('expands bare host input into Jellyfin URL candidates', () {
      expect(JellyfinEndpointDiscovery.expandInputToBaseUrls('jf.example.com'), [
        'http://jf.example.com:8096',
        'https://jf.example.com',
        'https://jf.example.com:8096',
        'http://jf.example.com',
      ]);
    });

    test('expands host and port input without changing the port', () {
      expect(JellyfinEndpointDiscovery.expandInputToBaseUrls('192.168.1.10:8096'), [
        'http://192.168.1.10:8096',
        'https://192.168.1.10:8096',
      ]);
    });

    test('races expanded bare host candidates', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((req) async {
          if (req.url.scheme == 'http' && req.url.host == 'jf.example.com' && req.url.port == 8096) {
            return _info(id: 'srv-1');
          }
          throw TimeoutException('offline');
        }),
      );
      final input = JellyfinEndpointDiscovery.buildUserInputCandidates(['jf.example.com']);

      final result = await discovery.raceEndpoints(
        input.probeBaseUrls,
        baseUrlsToPersist: input.explicitBaseUrls,
        baseUrlValidationGroups: input.validationBaseUrlGroups,
      );

      expect(result.activeBaseUrl, 'http://jf.example.com:8096');
      expect(result.baseUrls, ['http://jf.example.com:8096']);
    });

    test('does not persist failed shorthand guesses as failover URLs', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((req) async {
          if (req.url.scheme == 'http' && req.url.host == '192.168.1.10' && req.url.port == 8096) {
            return _info(id: 'srv-1');
          }
          throw TimeoutException('offline');
        }),
      );
      final input = JellyfinEndpointDiscovery.buildUserInputCandidates(['192.168.1.10']);

      final result = await discovery.raceEndpoints(
        input.probeBaseUrls,
        baseUrlsToPersist: input.explicitBaseUrls,
        baseUrlValidationGroups: input.validationBaseUrlGroups,
      );

      expect(result.baseUrls, ['http://192.168.1.10:8096']);
    });

    test('does not reject different servers found only through shorthand guesses', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((req) async {
          if (req.url.scheme == 'http' && req.url.host == 'jf.example.com' && req.url.port == 8096) {
            return _info(id: 'srv-1');
          }
          if (req.url.scheme == 'https' && req.url.host == 'jf.example.com' && !req.url.hasPort) {
            return _info(id: 'srv-2');
          }
          throw TimeoutException('offline');
        }),
      );
      final input = JellyfinEndpointDiscovery.buildUserInputCandidates(['jf.example.com']);

      final result = await discovery.raceEndpoints(
        input.probeBaseUrls,
        baseUrlsToPersist: input.explicitBaseUrls,
        baseUrlValidationGroups: input.validationBaseUrlGroups,
      );

      expect(result.baseUrls, [result.activeBaseUrl]);
    });

    test('rejects different servers reached from separate shorthand entries', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((req) async {
          if (req.url.scheme == 'http' && req.url.host == 'one.example.com' && req.url.port == 8096) {
            return _info(id: 'srv-1');
          }
          if (req.url.scheme == 'http' && req.url.host == 'two.example.com' && req.url.port == 8096) {
            return _info(id: 'srv-2');
          }
          throw TimeoutException('offline');
        }),
      );
      final input = JellyfinEndpointDiscovery.buildUserInputCandidates(['one.example.com', 'two.example.com']);

      await expectLater(
        discovery.raceEndpoints(
          input.probeBaseUrls,
          baseUrlsToPersist: input.explicitBaseUrls,
          baseUrlValidationGroups: input.validationBaseUrlGroups,
        ),
        throwsA(isA<MediaServerUrlException>()),
      );
    });

    test('retains explicit user-entered failover URLs when using input candidates', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((req) async {
          if (req.url.host == 'offline.example.com') {
            throw TimeoutException('offline');
          }
          return _info(id: 'srv-1');
        }),
      );
      final input = JellyfinEndpointDiscovery.buildUserInputCandidates([
        'https://offline.example.com',
        'https://jf.example.com',
      ]);

      final result = await discovery.raceEndpoints(
        input.probeBaseUrls,
        baseUrlsToPersist: input.explicitBaseUrls,
        baseUrlValidationGroups: input.validationBaseUrlGroups,
      );

      expect(result.activeBaseUrl, 'https://jf.example.com');
      expect(result.baseUrls, ['https://jf.example.com', 'https://offline.example.com']);
    });

    test('races URLs and selects the lowest-latency reachable endpoint', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((req) async {
          if (req.url.host == 'slow.example.com') {
            await Future<void>.delayed(const Duration(milliseconds: 35));
          } else {
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          return _info(id: 'srv-1');
        }),
      );

      final result = await discovery.raceEndpoints(['https://slow.example.com', 'https://fast.example.com']);

      expect(result.activeBaseUrl, 'https://fast.example.com');
      expect(result.baseUrls, ['https://fast.example.com', 'https://slow.example.com']);
      expect(result.serverInfo.machineId, 'srv-1');
    });

    test('keeps unreachable URLs but validates every reachable URL is the same server', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((req) async {
          if (req.url.host == 'offline.example.com') {
            throw TimeoutException('offline');
          }
          return _info(id: 'srv-1');
        }),
      );

      final result = await discovery.raceEndpoints(['https://offline.example.com', 'https://jf.example.com']);

      expect(result.activeBaseUrl, 'https://jf.example.com');
      expect(result.baseUrls, ['https://jf.example.com', 'https://offline.example.com']);
    });

    test('rejects reachable URLs that point to different Jellyfin servers', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((req) async {
          return _info(id: req.url.host == 'one.example.com' ? 'srv-1' : 'srv-2');
        }),
      );

      await expectLater(
        discovery.raceEndpoints(['https://one.example.com', 'https://two.example.com']),
        throwsA(isA<MediaServerUrlException>()),
      );
    });

    test('rejects URLs that do not match an expected existing server id', () async {
      final discovery = JellyfinEndpointDiscovery(
        testHttpClientFactory: () => MockClient((_) async => _info(id: 'srv-2')),
      );

      await expectLater(
        discovery.raceEndpoints(['https://jf.example.com'], expectedMachineId: 'srv-1'),
        throwsA(isA<MediaServerUrlException>()),
      );
    });
  });
}
