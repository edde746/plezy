import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/screens/settings/add_direct_plex_screen.dart';

void main() {
  group('probePlexServer', () {
    test('identifies server when unauthenticated root returns 200 JSON', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/') {
          return http.Response(
            jsonEncode({
              'MediaContainer': {
                'friendlyName': 'LocalTower',
                'machineIdentifier': 'mach-123',
                'version': '1.32.0.1000',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final info = await probePlexServer(
        url: 'http://192.168.1.50:32400',
        clientIdentifier: 'plezy-client-1',
        client: client,
      );

      expect(info.serverName, 'LocalTower');
      expect(info.serverMachineId, 'mach-123');
      expect(info.version, '1.32.0.1000');
      expect(info.requiresAuth, isFalse);
      expect(info.isAuthenticated, isTrue);
    });

    test('identifies server when unauthenticated root returns 200 XML', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/') {
          return http.Response(
            '<MediaContainer friendlyName="XmlServer" machineIdentifier="mach-xml-456" version="1.31.0" />',
            200,
            headers: {'content-type': 'application/xml'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final info = await probePlexServer(
        url: 'http://192.168.1.50:32400',
        clientIdentifier: 'plezy-client-1',
        client: client,
      );

      expect(info.serverName, 'XmlServer');
      expect(info.serverMachineId, 'mach-xml-456');
      expect(info.version, '1.31.0');
      expect(info.requiresAuth, isFalse);
      expect(info.isAuthenticated, isTrue);
    });

    test('detects when server requires authentication (401 on root, 200 on /identity)', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/') {
          return http.Response('Unauthorized', 401);
        }
        if (request.url.path == '/identity') {
          return http.Response(
            jsonEncode({
              'MediaContainer': {'claimed': true, 'machineIdentifier': 'auth-mach-789', 'version': '1.32.5.7000'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final info = await probePlexServer(
        url: 'http://192.168.1.50:32400',
        clientIdentifier: 'plezy-client-1',
        client: client,
      );

      expect(info.requiresAuth, isTrue);
      expect(info.isAuthenticated, isFalse);
      expect(info.serverMachineId, 'auth-mach-789');
      expect(info.version, '1.32.5.7000');
    });

    test('accepts valid token on auth-required server', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/') {
          if (request.headers['X-Plex-Token'] == 'valid-secret-token') {
            return http.Response(
              jsonEncode({
                'MediaContainer': {
                  'friendlyName': 'SecuredTower',
                  'machineIdentifier': 'mach-secured-1',
                  'version': '1.32.8',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Unauthorized', 401);
        }
        return http.Response('Not Found', 404);
      });

      final info = await probePlexServer(
        url: 'http://192.168.1.50:32400',
        clientIdentifier: 'plezy-client-1',
        token: 'valid-secret-token',
        client: client,
      );

      expect(info.serverName, 'SecuredTower');
      expect(info.requiresAuth, isFalse);
      expect(info.isAuthenticated, isTrue);
    });

    test('throws when token is invalid and server returns 401', () async {
      final client = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      expect(
        () => probePlexServer(
          url: 'http://192.168.1.50:32400',
          clientIdentifier: 'plezy-client-1',
          token: 'bad-token',
          client: client,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
