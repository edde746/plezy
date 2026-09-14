import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

/// A `/library/metadata/{id}` response carrying whichever guid shapes the
/// server's agent produces.
http.Response _metadata({List<Object>? guidArray, Object? scalarGuid}) => _json({
  'MediaContainer': {
    'Metadata': [
      {'ratingKey': 'show-1', 'type': 'show', 'title': 'Show', 'guid': ?scalarGuid, 'Guid': ?guidArray},
    ],
  },
});

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('reads the modern Guid array and asks for it', () async {
    late Uri requestUri;
    final client = testPlexClient(
      handler: (request) async {
        requestUri = request.url;
        return _metadata(
          guidArray: [
            {'id': 'imdb://tt12345'},
            {'id': 'tmdb://456'},
            {'id': 'tvdb://789'},
          ],
          scalarGuid: 'plex://show/abc',
        );
      },
    );
    addTearDown(client.close);

    final ids = await client.fetchExternalIds('show-1');

    expect(requestUri.path, '/library/metadata/show-1');
    expect(requestUri.queryParameters['includeGuids'], '1');
    expect((ids.imdb, ids.tmdb, ids.tvdb), ('tt12345', 456, 789));
  });

  // Plex only builds the `Guid` array for the Plex Movie / Plex TV Series
  // agents. A library still on a legacy agent answers with the scalar `guid`
  // alone, and reading only the array left every tracker blind to it (#1788).
  test('falls back to a legacy agent scalar guid', () async {
    final client = testPlexClient(
      handler: (request) async => _metadata(scalarGuid: 'com.plexapp.agents.thetvdb://315500?lang=en'),
    );
    addTearDown(client.close);

    final ids = await client.fetchExternalIds('show-1');

    expect(ids.tvdb, 315500);
  });

  test('maps a HAMA AniDB guid, which carries no catalog id at all', () async {
    final client = testPlexClient(
      handler: (request) async => _metadata(scalarGuid: 'com.plexapp.agents.hama://anidb-11905?lang=en'),
    );
    addTearDown(client.close);

    final ids = await client.fetchExternalIds('show-1');

    expect(ids.anidb, 11905);
    expect(ids.hasAny, isTrue);
    expect(ids.hasCatalogIds, isFalse);
  });

  test('the Guid array wins per field and the scalar fills the rest', () async {
    final client = testPlexClient(
      handler: (request) async => _metadata(
        guidArray: [
          {'id': 'tvdb://789'},
        ],
        scalarGuid: 'com.plexapp.agents.hama://tvdb-315500',
      ),
    );
    addTearDown(client.close);

    final ids = await client.fetchExternalIds('show-1');

    expect(ids.tvdb, 789);
  });

  test('an unmatched item and a failed request both resolve to no ids', () async {
    final unmatched = testPlexClient(
      handler: (request) async => _metadata(scalarGuid: 'com.plexapp.agents.none://315500'),
    );
    addTearDown(unmatched.close);
    expect((await unmatched.fetchExternalIds('show-1')).hasAny, isFalse);

    final failing = testPlexClient(handler: (request) async => http.Response('nope', 500));
    addTearDown(failing.close);
    expect((await failing.fetchExternalIds('show-1')).hasAny, isFalse);
  });
}
