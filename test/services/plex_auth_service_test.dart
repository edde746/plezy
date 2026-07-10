import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';

void main() {
  group('PlexAuthService', () {
    test('fetchServers retries resources through plex.tv after clients host transport failure', () async {
      final hosts = <String>[];
      final client = MediaServerHttpClient(
        client: MockClient((request) async {
          hosts.add(request.url.host);
          if (request.url.host == 'clients.plex.tv') {
            throw http.ClientException('DNS failed', request.url);
          }
          return http.Response(jsonEncode([_serverJson()]), 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(client.close);
      final auth = PlexAuthService.forTesting(http: client);

      final servers = await auth.fetchServers('token');

      expect(hosts, ['clients.plex.tv', 'plex.tv']);
      expect(servers.single.clientIdentifier, 'srv-1');
    });

    test('fetchServers does not retry canonical host for HTTP auth failures', () async {
      final hosts = <String>[];
      final client = MediaServerHttpClient(
        client: MockClient((request) async {
          hosts.add(request.url.host);
          return http.Response('{"errors":[]}', 401, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(client.close);
      final auth = PlexAuthService.forTesting(http: client);

      await expectLater(
        auth.fetchServers('bad-token'),
        throwsA(isA<MediaServerHttpException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
      expect(hosts, ['clients.plex.tv']);
    });

    test('switchToUser tolerates drifted field shapes on the 201 body (#1488)', () async {
      final client = MediaServerHttpClient(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.host, 'clients.plex.tv');
          expect(request.url.path, '/api/v2/home/users/uuid-1/switch');
          return http.Response(
            jsonEncode({
              'id': 312174832,
              'uuid': 'uuid-1',
              'title': 'hi_phi',
              'authToken': 'minted-user-token',
              'profile': {
                'defaultAudioLanguages': 'en,sv',
                'defaultSubtitleLanguages': 'en,sv',
                'mediaPostsVisibility': true,
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      final auth = PlexAuthService.forTesting(http: client);

      final response = await auth.switchToUser('uuid-1', 'account-token');

      expect(response.authToken, 'minted-user-token');
      expect(response.profile.defaultAudioLanguages, ['en', 'sv']);
      expect(response.profile.defaultSubtitleLanguages, ['en', 'sv']);
    });
  });
}

Map<String, dynamic> _serverJson() => {
  'name': 'Home Server',
  'clientIdentifier': 'srv-1',
  'accessToken': 'server-token',
  'owned': true,
  'provides': 'server',
  'connections': [
    {
      'protocol': 'https',
      'address': '192.168.1.3',
      'port': 32400,
      'uri': 'https://192-168-1-3.machine.plex.direct:32400',
      'local': true,
      'relay': false,
      'IPv6': false,
    },
  ],
};
