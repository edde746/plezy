import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) {
    return PlexClient.forTesting(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: '1',
      ),
      serverId: ServerId('server-id'),
      httpClient: MockClient(handler),
    );
  }

  test('filters and sorts use dedicated Plex endpoints', () async {
    final requests = <Uri>[];
    final client = makeClient((request) async {
      requests.add(request.url);
      return switch (request.url.path) {
        '/library/sections/1/filters' => http.Response(
          jsonEncode(_filtersPayload()),
          200,
          headers: {'content-type': 'application/json'},
        ),
        '/library/sections/1/sorts' => http.Response(
          jsonEncode(_sortsPayload()),
          200,
          headers: {'content-type': 'application/json'},
        ),
        _ => http.Response('not found', 404),
      };
    });
    addTearDown(client.close);

    final filters = await client.getLibraryFilters('1');
    final sorts = await client.fetchSortOptions('1', libraryType: 'show');

    expect(requests.map((u) => u.path), ['/library/sections/1/filters', '/library/sections/1/sorts']);
    expect(requests.every((u) => u.queryParameters.isEmpty), isTrue);
    expect(filters.map((f) => f.filter), ['genre', 'year', 'unwatched']);
    expect(sorts.map((s) => s.key), [
      'titleSort',
      'rating',
      'audienceRating',
      'addedAt',
      'episode.addedAt',
      'lastViewedAt',
      'random',
      // Plex doesn't advertise these in /sorts; we append them for movie/show.
      'viewCount',
      'userRating',
    ]);
  });

  test('appends Plays and User Rating sorts only for movie/show libraries', () async {
    PlexClient clientReturning() => makeClient((request) async {
      if (request.url.path == '/library/sections/1/sorts') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Directory': [
                {'key': 'titleSort', 'title': 'Title', 'defaultDirection': 'asc'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    for (final type in ['movie', 'show']) {
      final client = clientReturning();
      addTearDown(client.close);
      final sorts = await client.fetchSortOptions('1', libraryType: type);
      expect(sorts.map((s) => s.key), ['titleSort', 'viewCount', 'userRating'], reason: type);
    }

    // Other library types (e.g. music) are left as the server returned them.
    final musicClient = clientReturning();
    addTearDown(musicClient.close);
    final musicSorts = await musicClient.fetchSortOptions('1', libraryType: 'artist');
    expect(musicSorts.map((s) => s.key), ['titleSort']);
  });

  test('does not duplicate Plays/User Rating when the server already advertises them', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/library/sections/1/sorts') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Directory': [
                {'key': 'titleSort', 'title': 'Title', 'defaultDirection': 'asc'},
                {'key': 'viewCount', 'title': 'Plays', 'defaultDirection': 'desc'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final sorts = await client.fetchSortOptions('1', libraryType: 'movie');
    // viewCount already advertised -> not duplicated; userRating still appended.
    expect(sorts.map((s) => s.key), ['titleSort', 'viewCount', 'userRating']);
  });

  test('library content stamps known section when Plex omits librarySectionID on rows', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/library/sections/7/all') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 1,
              'Metadata': [
                {'ratingKey': '42', 'type': 'movie', 'title': 'Library Movie'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchLibraryContent('7', const LibraryQuery(limit: 1));

    expect(page.items.single.id, '42');
    expect(page.items.single.libraryId, '7');
  });

  test('child metadata inherits hoisted MediaContainer library section', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/library/metadata/show-1/children') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'librarySectionID': '9',
              'librarySectionTitle': 'TV Shows',
              'Metadata': [
                {'ratingKey': 'season-1', 'type': 'season', 'title': 'Season 1'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final children = await client.fetchChildren('show-1');

    expect(children.single.libraryId, '9');
    expect(children.single.libraryTitle, 'TV Shows');
  });

  test('hub content infers library section from /hubs/sections key', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/hubs/sections/7/recentlyAdded/items') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'Metadata': [
                {'ratingKey': '42', 'type': 'movie', 'title': 'Hub Movie'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final items = await client.fetchHubContent('/hubs/sections/7/recentlyAdded/items');

    expect(items.single.id, '42');
    expect(items.single.libraryId, '7');
  });

  test('collection page can inherit source collection library section', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/library/collections/99/children') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 1,
              'Metadata': [
                {'ratingKey': '42', 'type': 'movie', 'title': 'Collection Movie'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchCollectionPage('99', libraryId: '7', libraryTitle: 'Movies');

    expect(page.items.single.id, '42');
    expect(page.items.single.libraryId, '7');
    expect(page.items.single.libraryTitle, 'Movies');
  });

  test('library collections are fetched in pages', () async {
    final requests = <Uri>[];
    final client = makeClient((request) async {
      if (request.url.path == '/library/sections/7/collections') {
        requests.add(request.url);
        final start = request.url.queryParameters['X-Plex-Container-Start'];
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 2,
              'Metadata': [
                {'ratingKey': start == '0' ? '99' : '100', 'type': 'collection', 'title': 'Collection'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final collections = await client.fetchCollections('7');

    expect(collections.map((item) => item.id).toList(), ['99', '100']);
    expect(requests.map((u) => u.queryParameters['X-Plex-Container-Start']).toList(), ['0', '1']);
    expect(requests.every((u) => u.queryParameters['X-Plex-Container-Size'] == '200'), isTrue);
    expect(requests.every((u) => u.queryParameters['includeGuids'] == '1'), isTrue);
  });

  test('library collection page passes requested pagination params', () async {
    Uri? requestUri;
    final client = makeClient((request) async {
      if (request.url.path == '/library/sections/7/collections') {
        requestUri = request.url;
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 50,
              'Metadata': [
                {'ratingKey': '120', 'type': 'collection', 'title': 'Collection'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchCollectionsPage('7', start: 20, size: 10);

    expect(page.items.single.id, '120');
    expect(page.totalCount, 50);
    expect(page.offset, 20);
    expect(requestUri, isNotNull);
    expect(requestUri!.queryParameters['X-Plex-Container-Start'], '20');
    expect(requestUri!.queryParameters['X-Plex-Container-Size'], '10');
    expect(requestUri!.queryParameters['includeGuids'], '1');
  });

  test('playlist page passes requested pagination params', () async {
    Uri? requestUri;
    final client = makeClient((request) async {
      if (request.url.path == '/playlists') {
        requestUri = request.url;
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 50,
              'Metadata': [
                {
                  'ratingKey': '120',
                  'key': '/playlists/120/items',
                  'type': 'playlist',
                  'playlistType': 'video',
                  'title': 'Playlist',
                  'smart': false,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchPlaylistsPage(start: 20, size: 10);

    expect(page.items.single.id, '120');
    expect(page.totalCount, 50);
    expect(page.offset, 20);
    expect(requestUri, isNotNull);
    expect(requestUri!.queryParameters['playlistType'], 'video');
    expect(requestUri!.queryParameters['X-Plex-Container-Start'], '20');
    expect(requestUri!.queryParameters['X-Plex-Container-Size'], '10');
  });

  test('playlist page fallback total only exposes one possible next item', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/playlists') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 10,
              'Metadata': List.generate(
                10,
                (i) => {
                  'ratingKey': '${120 + i}',
                  'key': '/playlists/${120 + i}/items',
                  'type': 'playlist',
                  'playlistType': 'video',
                  'title': 'Playlist',
                  'smart': false,
                },
              ),
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchPlaylistsPage(start: 20, size: 10);

    expect(page.items.length, 10);
    expect(page.totalCount, 31);
    expect(page.offset, 20);
  });

  test('playlist page uses X-Plex-Container-Total-Size header when body total is absent', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/playlists') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'Metadata': [
                {
                  'ratingKey': '120',
                  'key': '/playlists/120/items',
                  'type': 'playlist',
                  'playlistType': 'video',
                  'title': 'Playlist',
                  'smart': false,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json', 'X-Plex-Container-Total-Size': '50'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchPlaylistsPage(start: 20, size: 10);

    expect(page.items.single.id, '120');
    expect(page.totalCount, 50);
    expect(page.offset, 20);
  });

  test('fetchPlaylists walks playlist pages', () async {
    final requests = <Uri>[];
    final client = makeClient((request) async {
      if (request.url.path == '/playlists') {
        requests.add(request.url);
        final start = int.parse(request.url.queryParameters['X-Plex-Container-Start'] ?? '0');
        final metadata = start == 0
            ? [
                {'ratingKey': '1', 'type': 'playlist', 'playlistType': 'video', 'title': 'One'},
                {'ratingKey': '2', 'type': 'playlist', 'playlistType': 'video', 'title': 'Two'},
              ]
            : [
                {'ratingKey': '3', 'type': 'playlist', 'playlistType': 'video', 'title': 'Three'},
              ];
        return http.Response(
          jsonEncode({
            'MediaContainer': {'size': metadata.length, 'totalSize': 3, 'Metadata': metadata},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final playlists = await client.fetchPlaylists();

    expect(playlists.map((p) => p.id), ['1', '2', '3']);
    expect(requests.map((u) => u.queryParameters['X-Plex-Container-Start']), ['0', '2']);
    expect(requests.every((u) => u.queryParameters['X-Plex-Container-Size'] == '200'), isTrue);
  });

  test('fetchPlaylists returns empty on list failure', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/playlists') {
        return http.Response('server error', 500);
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final playlists = await client.fetchPlaylists();

    expect(playlists, isEmpty);
  });

  test('playlist item page passes requested pagination params', () async {
    Uri? requestUri;
    final client = makeClient((request) async {
      if (request.url.path == '/playlists/42/items') {
        requestUri = request.url;
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 30,
              'Metadata': [
                {'ratingKey': '99', 'type': 'movie', 'title': 'Movie'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchPlaylistPage('42', start: 20, size: 10);

    expect(page.items.single.id, '99');
    expect(page.totalCount, 30);
    expect(page.offset, 20);
    expect(requestUri, isNotNull);
    expect(requestUri!.queryParameters['X-Plex-Container-Start'], '20');
    expect(requestUri!.queryParameters['X-Plex-Container-Size'], '10');
  });

  test('playlist item page uses X-Plex-Container-Total-Size header when body total is absent', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/playlists/42/items') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'Metadata': [
                {'ratingKey': '99', 'type': 'movie', 'title': 'Movie'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json', 'X-Plex-Container-Total-Size': '30'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchPlaylistPage('42', start: 20, size: 10);

    expect(page.items.single.id, '99');
    expect(page.totalCount, 30);
    expect(page.offset, 20);
  });

  test('person media page passes requested pagination params', () async {
    Uri? requestUri;
    final client = makeClient((request) async {
      if (request.url.path == '/library/people/person-1/media') {
        requestUri = request.url;
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 30,
              'Metadata': [
                {'ratingKey': '99', 'type': 'movie', 'title': 'Movie'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchPersonMediaPage('person-1', start: 20, size: 10);

    expect(page.items.single.id, '99');
    expect(page.totalCount, 30);
    expect(page.offset, 20);
    expect(requestUri, isNotNull);
    expect(requestUri!.queryParameters['X-Plex-Container-Start'], '20');
    expect(requestUri!.queryParameters['X-Plex-Container-Size'], '10');
  });

  test('playable descendants page passes requested pagination params', () async {
    Uri? requestUri;
    final client = makeClient((request) async {
      if (request.url.path == '/library/metadata/show-1/grandchildren') {
        requestUri = request.url;
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 1,
              'totalSize': 30,
              'Metadata': [
                {'ratingKey': 'ep-1', 'type': 'episode', 'title': 'Episode'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final page = await client.fetchPlayableDescendantsPage('show-1', start: 20, size: 10);

    expect(page.items.single.id, 'ep-1');
    expect(page.totalCount, 30);
    expect(page.offset, 20);
    expect(requestUri, isNotNull);
    expect(requestUri!.queryParameters['X-Plex-Container-Start'], '20');
    expect(requestUri!.queryParameters['X-Plex-Container-Size'], '10');
  });

  test('hub content pages by filtered video item offset', () async {
    final requests = <Uri>[];
    final client = makeClient((request) async {
      if (request.url.path == '/hubs/sections/7/recent') {
        requests.add(request.url);
        final start = request.url.queryParameters['X-Plex-Container-Start'] ?? '0';
        final metadata = start == '0'
            ? [
                {'ratingKey': 'collection-1', 'type': 'collection', 'title': 'Collection'},
                {'ratingKey': 'movie-1', 'type': 'movie', 'title': 'Movie'},
              ]
            : [
                {'ratingKey': 'episode-1', 'type': 'episode', 'title': 'Episode'},
              ];
        return http.Response(
          jsonEncode({
            'MediaContainer': {'size': metadata.length, 'totalSize': 3, 'Metadata': metadata},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });
    addTearDown(client.close);

    final firstPage = await client.fetchMoreHubItemsPage('/hubs/sections/7/recent', start: 0, size: 1);
    final secondPage = await client.fetchMoreHubItemsPage('/hubs/sections/7/recent', start: 1, size: 1);

    expect(firstPage.items.single.id, 'movie-1');
    expect(firstPage.totalCount, 2);
    expect(firstPage.offset, 0);
    expect(secondPage.items.single.id, 'episode-1');
    expect(secondPage.totalCount, 2);
    expect(secondPage.offset, 1);
    expect(requests.map((u) => u.queryParameters['X-Plex-Container-Start']).toList(), ['0', '0', '2']);
    expect(requests.every((u) => u.queryParameters['X-Plex-Container-Size'] == '200'), isTrue);
  });
}

Map<String, dynamic> _filtersPayload() => {
  'MediaContainer': {
    'Directory': [
      {
        'filter': 'genre',
        'filterType': 'string',
        'key': '/library/sections/1/genre',
        'title': 'Genre',
        'type': 'filter',
      },
      {'filter': 'year', 'filterType': 'integer', 'key': '/library/sections/1/year', 'title': 'Year', 'type': 'filter'},
      {
        'filter': 'unwatched',
        'filterType': 'boolean',
        'key': '/library/sections/1/unwatched',
        'title': 'Unwatched',
        'type': 'filter',
      },
    ],
  },
};

Map<String, dynamic> _sortsPayload() => {
  'MediaContainer': {
    'Directory': [
      {'defaultDirection': 'asc', 'descKey': 'titleSort:desc', 'key': 'titleSort', 'title': 'Title'},
      {'defaultDirection': 'desc', 'descKey': 'rating:desc', 'key': 'rating', 'title': 'Critic Rating'},
      {
        'defaultDirection': 'desc',
        'descKey': 'audienceRating:desc',
        'key': 'audienceRating',
        'title': 'Audience Rating',
      },
      {'defaultDirection': 'desc', 'descKey': 'addedAt:desc', 'key': 'addedAt', 'title': 'Date Added'},
      {
        'defaultDirection': 'desc',
        'descKey': 'episode.addedAt:desc',
        'key': 'episode.addedAt',
        'title': 'Last Episode Date Added',
      },
      {'defaultDirection': 'desc', 'descKey': 'lastViewedAt:desc', 'key': 'lastViewedAt', 'title': 'Date Viewed'},
      {'defaultDirection': 'desc', 'descKey': 'random:desc', 'key': 'random', 'title': 'Randomly'},
    ],
  },
};
