import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

/// `/Users/{id}/Views` shape: the id is the CollectionFolder id that
/// `ParentId=` accepts and that hidden-library keys are built from.
Map<String, dynamic> _view(String id, String name, String collectionType) => {
  'Id': id,
  'Name': name,
  'CollectionType': collectionType,
  'Type': 'CollectionFolder',
};

const _views = [
  {'Id': 'lib-movies', 'Name': 'Movies', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
  {'Id': 'lib-shows', 'Name': 'Shows', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
  {'Id': 'lib-music', 'Name': 'Music', 'CollectionType': 'music', 'Type': 'CollectionFolder'},
];

/// A search hit as Jellyfin actually returns it: no library field of any kind.
Map<String, dynamic> _hit(String id, String type, String name) => {'Id': id, 'Type': type, 'Name': name};

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  JellyfinClient makeClient(
    List<Uri> captured, {
    Map<String, List<Map<String, dynamic>>> itemsByParent = const {},
    List<Map<String, dynamic>> views = _views,
  }) {
    return testJellyfinClient(
      httpClient: MockClient((request) async {
        captured.add(request.url);
        final path = request.url.path;
        if (path.endsWith('/Views')) return jsonResponse({'Items': views});
        if (path == '/Items') {
          final parent = request.url.queryParameters['ParentId'];
          // Search is always library-scoped: an unscoped query can neither
          // attribute its hits to a library nor honour a hidden one (#1970).
          if (parent == null) fail('Unscoped /Items search: ${request.url}');
          final includedTypes = request.url.queryParameters['IncludeItemTypes']?.split(',').toSet();
          final items = itemsByParent[parent] ?? const <Map<String, dynamic>>[];
          return jsonResponse({
            'Items': [
              for (final item in items)
                if (includedTypes == null || includedTypes.contains(item['Type'])) item,
            ],
          });
        }
        if (path == '/Artists') {
          final parent = request.url.queryParameters['parentId'];
          if (parent == null) fail('Unscoped /Artists search: ${request.url}');
          return jsonResponse({'Items': itemsByParent['artists:$parent'] ?? const <Map<String, dynamic>>[]});
        }
        fail('Unexpected request: ${request.url}');
      }),
    );
  }

  test('every search fans out one scoped query per visible library', () async {
    final captured = <Uri>[];
    final client = makeClient(
      captured,
      itemsByParent: {
        'lib-movies': [_hit('movie-1', 'Movie', 'The Movie')],
        'lib-shows': [_hit('show-1', 'Series', 'The Show')],
        'lib-music': [_hit('album-1', 'MusicAlbum', 'The Album')],
      },
    );
    addTearDown(client.close);

    final results = await client.searchItems('the');

    expect(results.map((item) => item.id), ['movie-1', 'show-1', 'album-1']);
    // A cold search loads the library views itself, exactly once.
    expect(captured.where((uri) => uri.path.endsWith('/Views')), hasLength(1));
    // One /Items leg per video library, two (album + audio) for music.
    expect(captured.where((uri) => uri.path == '/Items').map((uri) => uri.queryParameters['ParentId']), [
      'lib-movies',
      'lib-shows',
      'lib-music',
      'lib-music',
    ]);
  });

  test('a hidden library is excluded by scoping one request per visible library', () async {
    final captured = <Uri>[];
    final client = makeClient(
      captured,
      itemsByParent: {
        'lib-movies': [_hit('movie-1', 'Movie', 'The Movie')],
        'lib-shows': [_hit('show-1', 'Series', 'The Show')],
        'lib-music': [_hit('album-1', 'MusicAlbum', 'The Album')],
      },
    );
    addTearDown(client.close);

    final results = await client.searchItems('the', excludedLibraryIds: {'lib-shows'});

    expect(results.map((item) => item.id), ['movie-1', 'album-1']);
    // The unscoped query must not run: it would reintroduce the hidden library.
    expect(captured.where((uri) => uri.path == '/Items' && !uri.queryParameters.containsKey('ParentId')), isEmpty);
    // The hidden library gets no request at all, under either param spelling.
    expect(
      captured.where(
        (uri) => uri.queryParameters['ParentId'] == 'lib-shows' || uri.queryParameters['parentId'] == 'lib-shows',
      ),
      isEmpty,
    );
    expect(captured.where((uri) => uri.path == '/Items').map((uri) => uri.queryParameters['ParentId']), [
      'lib-movies',
      'lib-music',
      'lib-music',
    ]);
  });

  test('every hit carries the library it came from', () async {
    final captured = <Uri>[];
    final client = makeClient(
      captured,
      itemsByParent: {
        'lib-movies': [_hit('movie-1', 'Movie', 'The Movie')],
        'lib-music': [_hit('album-1', 'MusicAlbum', 'The Album')],
      },
    );
    addTearDown(client.close);

    final results = await client.searchItems('the');

    // Jellyfin sends no library field, so this stamp is the only attribution
    // these items will ever have — what the caller renders and filters on.
    expect(results.map((item) => item.libraryId), ['lib-movies', 'lib-music']);
    expect(results.map((item) => item.libraryTitle), ['Movies', 'Music']);
    expect(results.map((item) => item.libraryGlobalKey), ['srv-1:lib-movies', 'srv-1:lib-music']);
  });

  test('only a music library scopes the artists leg', () async {
    final captured = <Uri>[];
    final client = makeClient(
      captured,
      itemsByParent: {
        'artists:lib-music': [_hit('artist-1', 'MusicArtist', 'The Artist')],
      },
    );
    addTearDown(client.close);

    final results = await client.searchItems('the');

    expect(results.map((item) => item.id), ['artist-1']);
    expect(captured.where((uri) => uri.path == '/Artists').map((uri) => uri.queryParameters['parentId']), [
      'lib-music',
    ]);
  });

  test('an artist spanning two music libraries is returned once', () async {
    final captured = <Uri>[];
    // /Artists resolves parentId to an ancestor filter, so an artist with
    // tracks in both libraries is a genuine hit for both legs. Ranking does
    // not deduplicate, so an undeduped merge would render the card twice.
    final client = makeClient(
      captured,
      views: const [
        {'Id': 'lib-shows', 'Name': 'Shows', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
        {'Id': 'lib-music', 'Name': 'Music', 'CollectionType': 'music', 'Type': 'CollectionFolder'},
        {'Id': 'lib-scores', 'Name': 'Soundtracks', 'CollectionType': 'music', 'Type': 'CollectionFolder'},
      ],
      itemsByParent: {
        'artists:lib-music': [_hit('artist-1', 'MusicArtist', 'The Artist')],
        'artists:lib-scores': [_hit('artist-1', 'MusicArtist', 'The Artist')],
        'lib-scores': [_hit('album-1', 'MusicAlbum', 'The Album')],
      },
    );
    addTearDown(client.close);

    final results = await client.searchItems('the', excludedLibraryIds: {'lib-shows'});

    expect(results.map((item) => item.id), ['artist-1', 'album-1']);
    // First leg wins, so the stamp stays deterministic.
    expect(results.first.libraryId, 'lib-music');
    expect(captured.where((uri) => uri.path == '/Artists').map((uri) => uri.queryParameters['parentId']), [
      'lib-music',
      'lib-scores',
    ]);
  });

  test('a warm search reuses the views the library load already fetched', () async {
    final captured = <Uri>[];
    final client = makeClient(captured);
    addTearDown(client.close);

    // What LibrariesProvider does before the content tabs refresh.
    await client.fetchLibraries();
    final afterLoad = captured.length;

    await client.searchItems('the');
    await client.searchItems('the movie', excludedLibraryIds: {'lib-shows'});

    // /Views sits serially in front of every leg, so re-fetching it per
    // keystroke is pure latency.
    expect(captured.sublist(afterLoad).where((uri) => uri.path.endsWith('/Views')), isEmpty);
  });

  test('a later library load is what the next scoped search sees', () async {
    final captured = <Uri>[];
    var views = const [
      {'Id': 'lib-movies', 'Name': 'Movies', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
      {'Id': 'lib-shows', 'Name': 'Shows', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
    ];
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        captured.add(request.url);
        if (request.url.path.endsWith('/Views')) return jsonResponse({'Items': views});
        return jsonResponse({'Items': <Map<String, dynamic>>[]});
      }),
    );
    addTearDown(client.close);

    await client.fetchLibraries();
    views = const [
      {'Id': 'lib-movies', 'Name': 'Movies', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
      {'Id': 'lib-shows', 'Name': 'Shows', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
      {'Id': 'lib-new', 'Name': 'Documentaries', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
    ];
    await client.fetchLibraries();

    captured.clear();
    await client.searchItems('the', excludedLibraryIds: {'lib-shows'});

    // A library added on the server reaches search as soon as anything
    // reloads the list, so search is never staler than the sidebar.
    expect(captured.where((uri) => uri.path == '/Items').map((uri) => uri.queryParameters['ParentId']), [
      'lib-movies',
      'lib-new',
    ]);
  });

  test('a slow cold search does not clobber views from a newer library load', () async {
    final viewsGate = Completer<void>();
    var viewsServed = 0;
    var views = const [
      {'Id': 'lib-movies', 'Name': 'Movies', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
      {'Id': 'lib-shows', 'Name': 'Shows', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
    ];
    final captured = <Uri>[];
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        captured.add(request.url);
        if (request.url.path.endsWith('/Views')) {
          viewsServed++;
          // Snapshot BEFORE gating: the delayed response must carry the views
          // as they were when it was issued, or it cannot be the stale one.
          final responseViews = views;
          // Hold the search's own (first) view fetch in flight.
          if (viewsServed == 1) await viewsGate.future;
          return jsonResponse({'Items': responseViews});
        }
        return jsonResponse({'Items': <Map<String, dynamic>>[]});
      }),
    );
    addTearDown(client.close);

    // A cold search starts fetching views...
    final search = client.searchItems('the', excludedLibraryIds: {'lib-shows'});
    await pumpEventQueue();
    // ...then a load that started later finishes first, with newer views.
    views = const [
      {'Id': 'lib-movies', 'Name': 'Movies', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
      {'Id': 'lib-shows', 'Name': 'Shows', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
      {'Id': 'lib-new', 'Name': 'Documentaries', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
    ];
    await client.fetchLibraries();
    viewsGate.complete();
    await search;

    captured.clear();
    await client.searchItems('the', excludedLibraryIds: {'lib-shows'});

    // The authoritative load must win: had the older in-flight response
    // overwritten it, the new library would stay invisible to search.
    expect(captured.where((uri) => uri.path == '/Items').map((uri) => uri.queryParameters['ParentId']), [
      'lib-movies',
      'lib-new',
    ]);
  });

  test('one library holding every match still fills the whole budget', () async {
    final captured = <Uri>[];
    // All 100 matches live in Movies; Music has none. Splitting the budget
    // across legs would hand back 50 and silently halve the result set.
    final client = makeClient(
      captured,
      itemsByParent: {
        'lib-movies': [for (var i = 0; i < 100; i++) _hit('movie-$i', 'Movie', 'The Movie $i')],
      },
    );
    addTearDown(client.close);

    final results = await client.searchItems('the', limit: 100, excludedLibraryIds: {'lib-shows'});

    expect(results, hasLength(100));
    expect(captured.where((uri) => uri.path == '/Items').map((uri) => uri.queryParameters['Limit']), [
      '100',
      '100',
      '100',
    ]);
  });

  test('search never pays for a total it does not read', () async {
    final captured = <Uri>[];
    final client = makeClient(captured);
    addTearDown(client.close);

    await client.searchItems('the');
    await client.searchItems('the', excludedLibraryIds: {'lib-shows'});

    final counted = captured
        .where((uri) => uri.path == '/Items' || uri.path == '/Artists')
        .where((uri) => uri.queryParameters['EnableTotalRecordCount'] != 'false');
    expect(counted, isEmpty);
  });

  test('music album and audio legs use safe field sets without losing either kind', () async {
    final captured = <Uri>[];
    final client = makeClient(
      captured,
      itemsByParent: {
        'lib-music': [_hit('album-1', 'MusicAlbum', 'The Album'), _hit('track-1', 'Audio', 'The Track')],
      },
    );
    addTearDown(client.close);

    final results = await client.searchItems('the', excludedLibraryIds: {'lib-shows'});

    expect(results.map((item) => item.id), ['album-1', 'track-1']);
    final musicRequests = captured
        .where((uri) => uri.path == '/Items' && uri.queryParameters['ParentId'] == 'lib-music')
        .toList();
    final album = musicRequests.singleWhere((uri) => uri.queryParameters['IncludeItemTypes'] == 'MusicAlbum');
    final audio = musicRequests.singleWhere((uri) => uri.queryParameters['IncludeItemTypes'] == 'Audio');
    // Album UserData and count fields trigger recursive per-album work.
    expect(album.queryParameters['EnableUserData'], 'false');
    expect(album.queryParameters['Fields'], isNot(contains('UserData')));
    expect(album.queryParameters['Fields'], isNot(contains('RecursiveItemCount')));
    expect(album.queryParameters['Fields'], isNot(contains('ChildCount')));
    // Audio is a leaf, so retaining its direct play-state lookup is cheap.
    expect(audio.queryParameters['Fields'], contains('UserData'));
    final movies = captured.singleWhere(
      (uri) => uri.path == '/Items' && uri.queryParameters['ParentId'] == 'lib-movies',
    );
    expect(movies.queryParameters['Fields'], contains('ChildCount'));
  });

  test('excluded ids owned by another server do not shrink the fan-out', () async {
    final captured = <Uri>[];
    final client = makeClient(
      captured,
      itemsByParent: {
        'lib-movies': [_hit('movie-1', 'Movie', 'The Movie')],
      },
    );
    addTearDown(client.close);

    final results = await client.searchItems('the', excludedLibraryIds: {'some-other-servers-library'});

    expect(results.map((item) => item.id), ['movie-1']);
    // The foreign key matches none of this server's views, so every library
    // stays visible — and every query stays scoped.
    expect(captured.where((uri) => uri.path == '/Items').map((uri) => uri.queryParameters['ParentId']), [
      'lib-movies',
      'lib-shows',
      'lib-music',
      'lib-music',
    ]);
  });

  test('hiding every library returns nothing instead of everything', () async {
    final captured = <Uri>[];
    final client = makeClient(captured);
    addTearDown(client.close);

    final results = await client.searchItems('the', excludedLibraryIds: {'lib-movies', 'lib-shows', 'lib-music'});

    expect(results, isEmpty);
    expect(captured.where((uri) => uri.path == '/Items'), isEmpty);
    expect(captured.where((uri) => uri.path == '/Artists'), isEmpty);
  });

  test('view ids map onto the library ids hidden keys are built from', () async {
    final captured = <Uri>[];
    final client = makeClient(captured);
    addTearDown(client.close);

    final libraries = await client.fetchLibraries();

    expect(libraries.map((library) => library.id), ['lib-movies', 'lib-shows', 'lib-music']);
    expect(libraries.map((library) => library.globalKey), ['srv-1:lib-movies', 'srv-1:lib-shows', 'srv-1:lib-music']);
    expect(_view('lib-movies', 'Movies', 'movies')['Id'], libraries.first.id);
  });

  // MockClient cannot abort a request itself — "it is the handler's
  // responsibility to throw RequestAbortedException". MockClient.streaming
  // hands over the real AbortableRequest, so honouring its trigger here is
  // both the documented contract and proof that the search pass wired its
  // controller into /Views: without that, the trigger only fires on client
  // teardown and this test would hang instead of completing.
  test('aborting mid-flight tears down the view fetch and launches no library legs', () async {
    final paths = <String>[];
    final viewsEntered = Completer<void>();
    final client = testJellyfinClient(
      httpClient: MockClient.streaming((request, _) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/Views')) {
          viewsEntered.complete();
          await (request as http.AbortableRequest).abortTrigger!;
          throw http.RequestAbortedException(request.url);
        }
        fail('No library search may start once the pass is cancelled: ${request.url}');
      }),
    );
    addTearDown(client.close);

    final abort = AbortController();
    final search = client.searchItems('the', excludedLibraryIds: {'lib-shows'}, abort: abort);
    await viewsEntered.future;
    abort.abort();

    await expectLater(
      search,
      throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
    );
    expect(paths.where((path) => path == '/Items'), isEmpty);
  });

  test('a failed view fetch fails the search instead of falling back to an unscoped one', () async {
    final paths = <String>[];
    final client = testJellyfinClient(
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/Views')) return http.Response('nope', 500);
        return jsonResponse({'Items': <Map<String, dynamic>>[]});
      }),
    );
    addTearDown(client.close);

    // Falling back to the unscoped query would quietly reintroduce every
    // hidden library; the server must be reported as failed instead.
    await expectLater(client.searchItems('the', excludedLibraryIds: {'lib-shows'}), throwsA(isA<Exception>()));
    expect(paths.where((path) => path == '/Items'), isEmpty);
  });

  group('searchPeople', () {
    const peopleViews = [
      {'Id': 'lib-movies', 'Name': 'Movies', 'CollectionType': 'movies', 'Type': 'CollectionFolder'},
      {'Id': 'lib-shows', 'Name': 'Shows', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
      {'Id': 'lib-music', 'Name': 'Music', 'CollectionType': 'music', 'Type': 'CollectionFolder'},
      {'Id': 'lib-anime', 'Name': 'Anime', 'CollectionType': 'tvshows', 'Type': 'CollectionFolder'},
    ];

    /// A `/Persons` row as the server returns it: no library, no credit.
    Map<String, dynamic> personRow(String id, String name, {String? primaryTag}) => {
      'Id': id,
      'Name': name,
      'Type': 'Person',
      if (primaryTag != null) 'ImageTags': {'Primary': primaryTag},
    };

    /// Serves `/Persons` in the given (name) order, honouring `Limit` the way
    /// the server does, and answers each `/Items?PersonIds=` check from
    /// [titlesByPerson]: person id → {library id: title type}.
    JellyfinClient makePeopleClient(
      List<Uri> captured, {
      required List<Map<String, dynamic>> persons,
      Map<String, Map<String, String>> titlesByPerson = const {},
      JellyfinClient Function({http.Client? httpClient}) factory = testJellyfinClient,
    }) {
      return factory(
        httpClient: MockClient((request) async {
          captured.add(request.url);
          final path = request.url.path;
          final params = request.url.queryParameters;
          if (path.endsWith('/Views')) return jsonResponse({'Items': peopleViews});
          if (path == '/Persons') {
            final limit = int.tryParse(params['Limit'] ?? '');
            return jsonResponse({'Items': limit == null ? persons : persons.take(limit).toList()});
          }
          if (path == '/Items') {
            final personId = params['PersonIds'];
            if (personId == null) fail('Unexpected /Items request: ${request.url}');
            final parent = params['ParentId'];
            final types = params['IncludeItemTypes']?.split(',').toSet();
            final matches = [
              for (final MapEntry(key: libraryId, value: type) in (titlesByPerson[personId] ?? const {}).entries)
                if ((parent == null || parent == libraryId) && (types == null || types.contains(type)))
                  _hit('$personId-$libraryId', type, 'A Title'),
            ];
            final limit = int.tryParse(params['Limit'] ?? '');
            return jsonResponse({'Items': limit == null ? matches : matches.take(limit).toList()});
          }
          fail('Unexpected request: ${request.url}');
        }),
      );
    }

    List<Uri> titleChecks(List<Uri> captured) => captured.where((uri) => uri.path == '/Items').toList();

    test('ranks the name-ordered candidates before cutting them to the limit', () async {
      final captured = <Uri>[];
      final client = makePeopleClient(
        captured,
        // `/Persons` sorts by name, so the exact match comes last.
        persons: [
          personRow('p-andrew', 'Andrew Jackson'),
          personRow('p-emily', 'Emily Jackson'),
          personRow('p-samuel', 'Samuel L. Jackson'),
        ],
        titlesByPerson: {
          'p-andrew': {'lib-movies': 'Movie'},
          'p-emily': {'lib-movies': 'Movie'},
          'p-samuel': {'lib-movies': 'Movie'},
        },
      );
      addTearDown(client.close);

      final results = await client.searchPeople('Samuel L. Jackson', limit: 2);

      expect(results, hasLength(2));
      expect(results.first.id, 'p-samuel');
      // Only the ranked top `limit` are worth an existence check.
      expect(titleChecks(captured).map((uri) => uri.queryParameters['PersonIds']), hasLength(2));
    });

    for (final (dialect, factory) in [('Jellyfin', testJellyfinClient), ('Emby', testEmbyClient)]) {
      test('$dialect drops candidates without a filmography title and keeps ranked order', () async {
        final captured = <Uri>[];
        final client = makePeopleClient(
          captured,
          factory: factory,
          persons: [
            personRow('p-christopher', 'Christopher Nolan'),
            personRow('p-jonathan', 'Jonathan Nolan'),
            personRow('p-gould', 'Nolan Gould'),
            personRow('p-north', 'Nolan North'),
          ],
          titlesByPerson: {
            'p-christopher': {'lib-movies': 'Movie'},
            // Credited on an episode only: the filmography lists movies and
            // series, so this person would open an empty screen.
            'p-jonathan': {'lib-shows': 'Episode'},
            'p-north': {'lib-shows': 'Series'},
          },
        );
        addTearDown(client.close);

        final results = await client.searchPeople('Nolan');

        // Best match first, not the server's name order.
        expect(results.map((person) => person.id), ['p-north', 'p-christopher']);
        expect(titleChecks(captured).map((uri) => uri.queryParameters['PersonIds']), hasLength(4));
        // Nothing is hidden, so no view fetch and no library scoping.
        expect(captured.where((uri) => uri.path.endsWith('/Views')), isEmpty);
        expect(titleChecks(captured).map((uri) => uri.queryParameters['ParentId']), everyElement(isNull));
      });
    }

    test('a person whose only titles sit in a hidden library is left out', () async {
      final captured = <Uri>[];
      final client = makePeopleClient(
        captured,
        persons: [
          personRow('p-bryan', 'Bryan Cranston'),
          personRow('p-waltz', 'Christoph Waltz'),
          personRow('p-kana', 'Kana Hanazawa'),
        ],
        titlesByPerson: {
          'p-bryan': {'lib-shows': 'Series'},
          // A title in any visible library keeps a person who is also in the hidden one.
          'p-waltz': {'lib-movies': 'Movie', 'lib-anime': 'Series'},
          'p-kana': {'lib-anime': 'Series'},
        },
      );
      addTearDown(client.close);

      final results = await client.searchPeople('a', excludedLibraryIds: {'lib-anime'});

      expect(results.map((person) => person.id), unorderedEquals(['p-bryan', 'p-waltz']));
      // An unscoped check or one scoped to the hidden library would bring
      // the hidden library's people back.
      expect(
        titleChecks(captured).map((uri) => uri.queryParameters['ParentId']),
        everyElement(isIn(['lib-movies', 'lib-shows', 'lib-music'])),
      );
    });

    test('hiding every library that can hold a title returns nobody without searching', () async {
      final captured = <Uri>[];
      final client = makePeopleClient(
        captured,
        persons: [personRow('p-waltz', 'Christoph Waltz')],
        titlesByPerson: {
          'p-waltz': {'lib-movies': 'Movie'},
        },
      );
      addTearDown(client.close);

      final results = await client.searchPeople('Waltz', excludedLibraryIds: {'lib-movies', 'lib-shows', 'lib-anime'});

      expect(results, isEmpty);
      expect(captured.where((uri) => uri.path == '/Persons' || uri.path == '/Items'), isEmpty);
    });

    test('a thumb exists only for a person with a primary image tag', () async {
      final captured = <Uri>[];
      final client = makePeopleClient(
        captured,
        persons: [
          personRow('p-tagged', 'Tagged Actor', primaryTag: 'tag-1'),
          personRow('p-untagged', 'Untagged Actor'),
        ],
        titlesByPerson: {
          'p-tagged': {'lib-movies': 'Movie'},
          'p-untagged': {'lib-movies': 'Movie'},
        },
      );
      addTearDown(client.close);

      final results = await client.searchPeople('Actor');
      final byId = {for (final person in results) person.id: person};

      final thumb = Uri.parse(byId['p-tagged']!.thumbPath!);
      expect(thumb.origin, 'https://jf.example.com');
      expect(thumb.path, '/Items/p-tagged/Images/Primary');
      expect(thumb.queryParameters['tag'], 'tag-1');
      // A tagless image URL 404s; no URL at all lets the row show a fallback.
      expect(byId['p-untagged']!.thumbPath, isNull);
    });

    test('aborting during the title checks cancels them and starts no further batch', () async {
      final checks = <String>[];
      final checksEntered = Completer<void>();
      final personsBody = jsonEncode({
        'Items': [for (var i = 0; i < 4; i++) personRow('p-$i', 'Actor $i')],
      });
      final client = testJellyfinClient(
        httpClient: MockClient.streaming((request, _) async {
          if (request.url.path == '/Persons') {
            return http.StreamedResponse(
              Stream.value(utf8.encode(personsBody)),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/Items') {
            checks.add(request.url.queryParameters['PersonIds']!);
            if (checks.length == 3) checksEntered.complete();
            await (request as http.AbortableRequest).abortTrigger!;
            throw http.RequestAbortedException(request.url);
          }
          fail('Unexpected request: ${request.url}');
        }),
      );
      addTearDown(client.close);

      final abort = AbortController();
      final search = client.searchPeople('Actor', abort: abort);
      await checksEntered.future;
      abort.abort();

      await expectLater(
        search,
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );
      // The fourth candidate sat in the next batch, which must never start.
      expect(checks, hasLength(3));
    });
  });
}
