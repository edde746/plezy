import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/services/jellyfin_endpoint_discovery.dart';

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
