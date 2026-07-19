import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/catalog_item_ref.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/jellyfin_favorites_catalog_source.dart';
import 'package:plezy/services/jellyfin_client.dart';

import '../../test_helpers/backend_client_fixtures.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('pages favorite videos across Jellyfin servers while retaining server identity', () async {
    final requests = <String, List<Uri>>{'server-a': [], 'server-b': []};

    JellyfinClient buildClient(String machineId, List<Map<String, Object?>> items) {
      return testJellyfinClient(
        connection: testJellyfinConnection(machineId: machineId, serverName: machineId),
        httpClient: MockClient((request) async {
          requests[machineId]!.add(request.url);
          if (request.url.path == '/Users/user-1/Views') {
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'lib-$machineId', 'Name': 'Videos', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
                ],
              }),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items') {
            final limit = int.parse(request.url.queryParameters['Limit']!);
            return http.Response(
              jsonEncode({'Items': items.take(limit).toList(), 'TotalRecordCount': items.length}),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        }),
      );
    }

    final first = buildClient('server-a', [
      {'Id': 'alpha', 'Type': 'Movie', 'Name': 'Alpha'},
      {'Id': 'delta', 'Type': 'Series', 'Name': 'Delta'},
      {'Id': 'song', 'Type': 'Audio', 'Name': 'Song'},
    ]);
    final second = buildClient('server-b', [
      {'Id': 'bravo', 'Type': 'Movie', 'Name': 'Bravo'},
      {'Id': 'charlie', 'Type': 'Episode', 'Name': 'Charlie'},
    ]);
    addTearDown(first.close);
    addTearDown(second.close);

    final source = JellyfinFavoritesCatalogSource([first, second]);
    addTearDown(source.dispose);

    final pageOne = await source.fetchMediaRow(CatalogRowId.favorites, page: 1, limit: 2);
    final pageTwo = await source.fetchMediaRow(CatalogRowId.favorites, page: 2, limit: 2);

    expect(pageOne.items.map((item) => item.title), ['Alpha', 'Bravo']);
    expect(pageOne.hasMore, isTrue);
    expect(pageTwo.items.map((item) => item.title), ['Charlie', 'Delta']);
    expect(pageTwo.hasMore, isFalse);
    expect([...pageOne.items, ...pageTwo.items].map((item) => item.serverId), [
      'server-a',
      'server-b',
      'server-b',
      'server-a',
    ]);
    expect([...pageOne.items, ...pageTwo.items].every((item) => !item.isCatalogItem), isTrue);

    for (final serverRequests in requests.values) {
      final itemRequests = serverRequests.where((uri) => uri.path == '/Items').toList();
      expect(itemRequests.map((uri) => uri.queryParameters['Limit']), ['2', '4']);
      for (final uri in itemRequests) {
        expect(uri.queryParameters['ParentId'], startsWith('lib-server-'));
        expect(uri.queryParameters['StartIndex'], '0');
        expect(uri.queryParameters['Filters'], 'IsFavorite');
        expect(uri.queryParameters['SortBy'], 'SortName');
        expect(uri.queryParameters['SortOrder'], 'Ascending');
      }
    }
  });

  test('excludes libraries hidden by the active profile', () async {
    final requestedLibraryIds = <String>[];
    final client = testJellyfinClient(
      connection: testJellyfinConnection(machineId: 'server-1'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/Users/user-1/Views') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'visible', 'Name': 'Visible', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
                {'Id': 'hidden', 'Name': 'Hidden', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
              ],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/Items') {
          final libraryId = request.url.queryParameters['ParentId']!;
          requestedLibraryIds.add(libraryId);
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'favorite-$libraryId', 'Type': 'Movie', 'Name': 'Favorite from $libraryId'},
              ],
              'TotalRecordCount': 1,
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      }),
    );
    addTearDown(client.close);

    final source = JellyfinFavoritesCatalogSource([client], hiddenLibraryKeys: const {'server-1:hidden'});
    addTearDown(source.dispose);

    final page = await source.fetchMediaRow(CatalogRowId.favorites);

    expect(page.items.map((item) => item.title), ['Favorite from visible']);
    expect(requestedLibraryIds, ['visible']);
  });
}
