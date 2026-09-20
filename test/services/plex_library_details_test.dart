import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/library_filter_result.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_filter.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';

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
      testPlexClient(serverId: ServerId('server-id'), handler: handler);

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

  // Filter discovery reads the schema Plex publishes with `includeMeta=1`:
  // the browsed type's fields plus the operators that type can evaluate. It
  // is the only source for exclusion, ranges and text matching, so the shape
  // it produces is pinned here rather than inferred from the browse tab.
  group('filter schema discovery', () {
    PlexClient metaClient(Future<http.Response> Function(http.Request request) handler, {List<Uri>? requests}) =>
        makeClient((request) async {
          requests?.add(request.url);
          return handler(request);
        });

    test('parses fields and per-type operators, and never asks for items', () async {
      final requests = <Uri>[];
      final client = metaClient(requests: requests, (request) async {
        if (request.url.path == '/library/sections/1/all') {
          return http.Response(jsonEncode(_metaPayload()), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('not found', 404);
      });
      addTearDown(client.close);

      final result = await client.fetchLibraryFiltersWithValues('1', libraryKind: MediaKind.movie);
      final byField = {for (final filter in result.filters) filter.filter: filter};

      expect(requests.single.queryParameters['includeMeta'], '1');
      expect(requests.single.queryParameters['X-Plex-Container-Size'], '0');
      expect(requests.single.queryParameters['type'], '1');

      // A tag field can be included or excluded and lists its values.
      expect(byField['genre']!.operators, [LibraryFilterOperator.is_, LibraryFilterOperator.isNot]);
      expect(byField['genre']!.key, '/library/sections/1/genre?type=1');
      expect(byField['genre']!.editorKind, FilterEditorKind.valueList);

      // An integer field carries its bounds; `year` is one Plex also lists.
      expect(byField['year']!.operators, contains(LibraryFilterOperator.atLeast));
      expect(byField['year']!.operators, contains(LibraryFilterOperator.atMost));
      expect(byField['year']!.key, '/library/sections/1/year?type=1');

      // A sized integer has bounds but no value listing, so it gets the
      // numeric editor rather than a list nobody can populate.
      expect(byField['mediaSize']!.key, isEmpty);
      expect(byField['mediaSize']!.editorKind, FilterEditorKind.number);

      // Free text exposes Plex's match modes and no listing.
      expect(byField['title']!.operators, contains(LibraryFilterOperator.matches));
      expect(byField['title']!.operators, contains(LibraryFilterOperator.beginsWith));
      expect(byField['title']!.key, isEmpty);
      expect(byField['title']!.editorKind, FilterEditorKind.text);

      expect(byField['addedAt']!.editorKind, FilterEditorKind.date);
      expect(byField['unwatched']!.isBoolean, isTrue);
      expect(byField['unwatched']!.supportsExclusion, isTrue);

      // Undocumented, movie/episode only: the filename and folder filter.
      expect(byField[MediaFilterField.file], isNotNull);
      expect(byField[MediaFilterField.file]!.editorKind, FilterEditorKind.text);
      expect(result.cachedValues, isEmpty);
    });

    test('strips the browsed type prefix but keeps cross-type fields qualified', () async {
      final client = metaClient((request) async {
        if (request.url.path == '/library/sections/2/all') {
          return http.Response(jsonEncode(_showMetaPayload()), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('not found', 404);
      });
      addTearDown(client.close);

      final result = await client.fetchLibraryFiltersWithValues('2', libraryKind: MediaKind.show);
      final fields = result.filters.map((f) => f.filter).toList();

      // `show.genre` and a bare `genre` select the same rows on a show query,
      // and the bare name is what value endpoints and saved selections use.
      expect(fields, contains('genre'));
      expect(fields, isNot(contains('show.genre')));
      // An episode field on a show query is not the browsed type's own, so it
      // stays qualified — that is the only spelling Plex accepts for it.
      expect(fields, contains('episode.title'));
      // Value listings always use the bare name.
      final genre = result.filters.firstWhere((f) => f.filter == 'genre');
      expect(genre.key, '/library/sections/2/genre?type=2');
      // No file filter: a show-type query answers 500 for it.
      expect(fields, isNot(contains(MediaFilterField.file)));
    });

    test('falls back to the legacy filter listing when the server publishes no schema', () async {
      final paths = <String>[];
      final client = metaClient((request) async {
        paths.add(request.url.path);
        return switch (request.url.path) {
          // Old servers answer the browse endpoint without a Meta block.
          '/library/sections/1/all' => http.Response(
            jsonEncode({
              'MediaContainer': {'size': 0},
            }),
            200,
            headers: {'content-type': 'application/json'},
          ),
          '/library/sections/1/filters' => http.Response(
            jsonEncode(_filtersPayload()),
            200,
            headers: {'content-type': 'application/json'},
          ),
          _ => http.Response('not found', 404),
        };
      });
      addTearDown(client.close);

      final result = await client.fetchLibraryFiltersWithValues('1', libraryKind: MediaKind.movie);

      expect(paths, ['/library/sections/1/all', '/library/sections/1/filters']);
      expect(result.filters.map((f) => f.filter), ['genre', 'year', 'unwatched']);
      // Without a published vocabulary the editor still offers exclusion:
      // every supported Plex version evaluates `!=` for these types.
      final genre = result.filters.first;
      expect(genre.supportsExclusion, isTrue);
    });

    test('a shared library has no filter schema to read', () async {
      var calls = 0;
      final client = metaClient((request) async {
        calls++;
        return http.Response('not found', 404);
      });
      addTearDown(client.close);

      expect(await client.fetchLibraryFiltersWithValues('shared'), LibraryFilterResult.empty);
      expect(calls, 0);
    });
  });

  test('appends Date Added, Plays, and User Rating sorts only for video libraries', () async {
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

    // 'clip' is a Plex home-video / "Other Videos" section (`type="movie"
    // subtype="clip"`). Unmatched files carry no critic/audience rating, so the
    // viewer's own rating is the only score they can be ordered by.
    for (final type in ['movie', 'show', 'clip']) {
      final client = clientReturning();
      addTearDown(client.close);
      final sorts = await client.fetchSortOptions('1', libraryType: type);
      expect(sorts.map((s) => s.key), ['titleSort', 'addedAt', 'viewCount', 'userRating'], reason: type);

      final dateAdded = sorts.singleWhere((s) => s.key == 'addedAt');
      expect(dateAdded.descKey, 'addedAt:desc', reason: type);
      expect(dateAdded.defaultDirection, 'desc', reason: type);
    }

    // Other library types (e.g. music) are left as the server returned them.
    final musicClient = clientReturning();
    addTearDown(musicClient.close);
    final musicSorts = await musicClient.fetchSortOptions('1', libraryType: 'artist');
    expect(musicSorts.map((s) => s.key), ['titleSort']);
  });

  test('does not duplicate Date Added/Plays when the server already advertises them', () async {
    final client = makeClient((request) async {
      if (request.url.path == '/library/sections/1/sorts') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Directory': [
                {'key': 'titleSort', 'title': 'Title', 'defaultDirection': 'asc'},
                {'key': 'addedAt', 'title': 'Date Added', 'defaultDirection': 'desc'},
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
    // addedAt/viewCount already advertised -> not duplicated; userRating still appended.
    expect(sorts.map((s) => s.key), ['titleSort', 'addedAt', 'viewCount', 'userRating']);
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

    final page = await client.fetchLibraryPagedContent('7', query: const LibraryQuery(limit: 1));

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

  test('client-side episode fallback retains watched rows and sorts by watch order', () async {
    Uri? requestUri;
    final client = makeClient((request) async {
      if (request.url.path == '/library/metadata/show-1/grandchildren') {
        requestUri = request.url;
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'size': 3,
              'totalSize': 3,
              'Metadata': [
                {
                  'ratingKey': 'special',
                  'type': 'episode',
                  'title': 'Special',
                  'parentIndex': 0,
                  'index': 1,
                  'originallyAvailableAt': '2024-01-02',
                  'viewCount': 1,
                },
                {
                  'ratingKey': 'ep-2',
                  'type': 'episode',
                  'title': 'Episode 2',
                  'parentIndex': 1,
                  'index': 2,
                  'originallyAvailableAt': '2024-01-03',
                  'viewCount': 1,
                },
                {
                  'ratingKey': 'ep-1',
                  'type': 'episode',
                  'title': 'Episode 1',
                  'parentIndex': 1,
                  'index': 1,
                  'originallyAvailableAt': '2024-01-01',
                  'viewCount': 1,
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

    final episodes = await client.fetchClientSideEpisodeQueue('show-1');

    expect(requestUri!.path, '/library/metadata/show-1/grandchildren');
    expect(episodes!.map((episode) => episode.id), ['ep-1', 'special', 'ep-2']);
    expect(episodes.every((episode) => episode.isWatched), isTrue);
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

/// `Meta` block as PMS 1.43 publishes it for a movie section, trimmed to the
/// field shapes the editor has to tell apart.
Map<String, dynamic> _metaPayload() => {
  'MediaContainer': {
    'size': 0,
    'totalSize': 57,
    'Meta': {
      'Type': [
        {
          'type': 'movie',
          'active': true,
          'Field': [
            {'key': 'title', 'title': 'Title', 'type': 'string'},
            {'key': 'year', 'title': 'Year', 'type': 'integer'},
            {'key': 'mediaSize', 'title': 'File Size', 'type': 'integer'},
            {'key': 'genre', 'title': 'Genre', 'type': 'tag'},
            {'key': 'addedAt', 'title': 'Date Added', 'type': 'date'},
            {'key': 'unwatched', 'title': 'Unwatched', 'type': 'boolean'},
          ],
        },
      ],
      'FieldType': [
        {
          'type': 'tag',
          'Operator': [
            {'key': '=', 'title': 'is'},
            {'key': '!=', 'title': 'is not'},
          ],
        },
        {
          'type': 'integer',
          'Operator': [
            {'key': '=', 'title': 'is'},
            {'key': '!=', 'title': 'is not'},
            {'key': '>>=', 'title': 'is greater than'},
            {'key': '<<=', 'title': 'is less than'},
          ],
        },
        {
          'type': 'string',
          'Operator': [
            {'key': '=', 'title': 'contains'},
            {'key': '!=', 'title': 'does not contain'},
            {'key': '==', 'title': 'is'},
            {'key': '!==', 'title': 'is not'},
            {'key': '<=', 'title': 'begins with'},
            {'key': '>=', 'title': 'ends with'},
          ],
        },
        {
          'type': 'boolean',
          'Operator': [
            {'key': '=', 'title': 'is'},
            {'key': '!=', 'title': 'is not'},
          ],
        },
        {
          'type': 'date',
          'Operator': [
            {'key': '<<=', 'title': 'is before'},
            {'key': '>>=', 'title': 'is after'},
          ],
        },
      ],
    },
  },
};

/// A show section qualifies every field with its owning type, and carries the
/// episode fields alongside the show ones.
Map<String, dynamic> _showMetaPayload() => {
  'MediaContainer': {
    'size': 0,
    'Meta': {
      'Type': [
        {
          'type': 'show',
          'active': true,
          'Field': [
            {'key': 'show.title', 'title': 'Title', 'type': 'string'},
            {'key': 'show.genre', 'title': 'Genre', 'type': 'tag'},
            {'key': 'episode.title', 'title': 'Episode Title', 'type': 'string'},
          ],
        },
      ],
      'FieldType': [
        {
          'type': 'tag',
          'Operator': [
            {'key': '=', 'title': 'is'},
            {'key': '!=', 'title': 'is not'},
          ],
        },
      ],
    },
  },
};
