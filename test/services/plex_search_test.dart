import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) =>
      testPlexClient(serverId: ServerId('plex-1'), serverName: 'Plex', handler: handler);

  test('search defaults to 100 movie, TV, and music candidates', () async {
    final captured = <Uri>[];
    final client = makeClient((request) async {
      captured.add(request.url);
      if (request.url.path == '/library/search') {
        return _json({
          'MediaContainer': {
            'SearchResult': [
              {
                'score': 90,
                'Metadata': {'ratingKey': 'movie-1', 'type': 'movie', 'title': 'The Movie'},
              },
            ],
          },
        });
      }
      return http.Response('unexpected request', 500);
    });
    addTearDown(client.close);

    final results = await client.searchItems('the');

    expect(results.map((item) => item.id), ['movie-1']);
    expect(captured, hasLength(1));
    expect(captured.single.path, '/library/search');
    expect(captured.single.queryParameters['limit'], '100');
    expect(captured.single.queryParameters['X-Plex-Container-Size'], '100');
    expect(captured.single.queryParameters['searchTypes'], 'movies,tv,music');
  });
}
