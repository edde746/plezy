import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/utils/media_server_http_client.dart';

void main() {
  group('MediaServerHttpClient.buildUri', () {
    test('merges params into a path that already has a query string', () {
      // Regression for #1282: Plex home hub keys carry the library in the query
      // string (`sectionID`). Pagination params must merge with `&`, not append a
      // second `?` that corrupts `sectionID`.
      final client = MediaServerHttpClient(baseUrl: 'https://plex.example.com');
      final uri = client.buildUri(
        '/hubs/home/recentlyAdded?type=2&sectionID=2',
        queryParameters: {'X-Plex-Container-Start': 0, 'X-Plex-Container-Size': 200},
      );

      expect(uri.queryParameters['type'], '2');
      expect(uri.queryParameters['sectionID'], '2'); // not "2?X-Plex-Container-Start=0"
      expect(uri.queryParameters['X-Plex-Container-Start'], '0');
      expect(uri.queryParameters['X-Plex-Container-Size'], '200');
      expect('${uri.scheme}://${uri.host}${uri.path}', 'https://plex.example.com/hubs/home/recentlyAdded');

      client.close();
    });

    test('keeps a single ? for a plain path (no regression)', () {
      final client = MediaServerHttpClient(baseUrl: 'https://plex.example.com');
      final uri = client.buildUri('/library/sections/2/all', queryParameters: {'sort': 'addedAt:desc'});

      expect(uri.path, '/library/sections/2/all');
      expect(uri.queryParameters['sort'], 'addedAt:desc');

      client.close();
    });

    test('leaves a query-bearing path untouched when no extra params are given', () {
      final client = MediaServerHttpClient(baseUrl: 'https://plex.example.com');
      final uri = client.buildUri('/library/sections/2/all?genre=5');

      expect(uri.path, '/library/sections/2/all');
      expect(uri.queryParameters['genre'], '5');

      client.close();
    });
  });
}
