import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/jellyfin_client.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  test('Emby Live TV advertises mpegts and direct-plays an approved mpegts source', () async {
    final negotiations = <http.Request>[];
    final client = JellyfinClient.forTesting(
      connection: testEmbyConnection(),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/PlaybackInfo')) {
          negotiations.add(request);
          return http.Response(
            jsonEncode({
              'PlaySessionId': 'play-1',
              'MediaSources': [
                {
                  'Id': 'source-1',
                  'Container': 'mpegts',
                  'LiveStreamId': 'live-1',
                  'SupportsDirectPlay': true,
                },
              ],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200, headers: const {'content-type': 'application/json'});
      }),
    );
    addTearDown(client.close);

    final session = await client.liveTv.startPlayback('channel-1');

    final body = jsonDecode(negotiations.single.body) as Map<String, dynamic>;
    final deviceProfile = body['DeviceProfile'] as Map<String, dynamic>;
    final directPlayProfiles = deviceProfile['DirectPlayProfiles'] as List<dynamic>;
    final videoProfile = directPlayProfiles.cast<Map<String, dynamic>>().singleWhere(
      (profile) => profile['Type'] == 'Video',
    );
    final containers = (videoProfile['Container'] as String).split(',');
    expect(containers, contains('mpegts'));

    final uri = Uri.parse((await session!.streamUrlAt())!);
    expect(uri.path, '/Videos/channel-1/stream.mpegts');
    expect(uri.queryParameters['Static'], 'true');
    expect(uri.queryParameters['MediaSourceId'], 'source-1');
    expect(uri.queryParameters['LiveStreamId'], 'live-1');
  });
}
