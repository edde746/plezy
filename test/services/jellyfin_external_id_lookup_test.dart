import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/utils/external_ids.dart';

import '../test_helpers/backend_client_fixtures.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

Map<String, dynamic> _series({String id = 'series-1', int tmdb = 42}) => {
  'Id': id,
  'Type': 'Series',
  'Name': 'Parent Series',
  'ProviderIds': {'Tmdb': '$tmdb'},
};

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('tries later titles and verifies the matching provider id', () async {
    final searchTerms = <String>[];
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/Items') {
          final searchTerm = request.url.queryParameters['SearchTerm']!;
          searchTerms.add(searchTerm);
          return _json({
            'Items': searchTerm == 'Parent Series' ? [_series()] : <Object>[],
          });
        }
        if (request.url.path == '/Items/series-1/Ancestors') {
          return _json([
            {'Id': 'library-1', 'Name': 'Shows', 'Type': 'CollectionFolder'},
          ]);
        }
        fail('Unexpected request: ${request.url}');
      }),
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tmdb: 42),
      kind: MediaKind.show,
      titles: const ['Parent Series Season 2', 'Parent Series'],
    );

    expect(searchTerms, ['Parent Series Season 2', 'Parent Series']);
    expect(match?.id, 'series-1');
    expect(match?.libraryId, 'library-1');
    expect(match?.libraryTitle, 'Shows');
  });

  test('rejects a title hit whose provider ids do not intersect', () async {
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        expect(request.url.path, '/Items');
        return _json({
          'Items': [_series(tmdb: 99)],
        });
      }),
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tmdb: 42),
      kind: MediaKind.show,
      titles: const ['Parent Series'],
    );

    expect(match, isNull);
  });

  test('uses the year window only for the first title and broadens the later limit', () async {
    final searches = <Uri>[];
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/Items') {
          searches.add(request.url);
          final searchTerm = request.url.queryParameters['SearchTerm'];
          return _json({
            'Items': searchTerm == 'Parent Series' ? [_series()] : <Object>[],
          });
        }
        if (request.url.path == '/Items/series-1/Ancestors') return _json(<Object>[]);
        fail('Unexpected request: ${request.url}');
      }),
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tmdb: 42),
      kind: MediaKind.show,
      titles: const ['Parent Series Season 2', 'Parent Series'],
      year: 2024,
    );

    expect(match?.id, 'series-1');
    expect(searches, hasLength(2));
    expect(searches.first.queryParameters['years'], '2023,2024,2025');
    expect(searches.first.queryParameters['Limit'], '20');
    expect(searches.last.queryParameters.containsKey('years'), isFalse);
    expect(searches.last.queryParameters['Limit'], '50');
  });

  test('requires an agreed sequel season to exist in the matched series', () async {
    Future<String?> lookupWithSeasons(List<int> seasonNumbers) async {
      final client = testJellyfinClient(
        httpClient: MockClient((request) async {
          if (request.url.path == '/Items') {
            return _json({
              'Items': [_series()],
            });
          }
          if (request.url.path == '/Shows/series-1/Seasons') {
            return _json({
              'Items': [
                for (final number in seasonNumbers)
                  {'Id': 'season-$number', 'Type': 'Season', 'Name': 'Season $number', 'IndexNumber': number},
              ],
            });
          }
          if (request.url.path == '/Items/series-1/Ancestors') return _json(<Object>[]);
          fail('Unexpected request: ${request.url}');
        }),
      );
      addTearDown(client.close);

      final match = await client.findByExternalIds(
        const ExternalIds(tmdb: 42),
        kind: MediaKind.show,
        titles: const ['Parent Series'],
        year: 2024,
        season: const ExternalSeasonRef(tvdb: 2, tmdb: 2),
      );
      return match?.id;
    }

    expect(await lookupWithSeasons([1]), isNull);
    expect(await lookupWithSeasons([1, 2]), 'series-1');
  });

  test('does not gate when TVDB and TMDB seasons disagree and Jellyfin order is unknown', () async {
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/Items') {
          return _json({
            'Items': [_series()],
          });
        }
        if (request.url.path == '/Items/series-1/Ancestors') return _json(<Object>[]);
        fail('Season hierarchy must not be requested: ${request.url}');
      }),
    );
    addTearDown(client.close);

    final match = await client.findByExternalIds(
      const ExternalIds(tmdb: 42),
      kind: MediaKind.show,
      titles: const ['Parent Series'],
      season: const ExternalSeasonRef(tvdb: 2, tmdb: 1),
    );

    expect(match?.id, 'series-1');
  });
}
