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

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

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
        if (path.endsWith('/Views')) return _json({'Items': views});
        if (path == '/Items') {
          final parent = request.url.queryParameters['ParentId'];
          // Search is always library-scoped: an unscoped query can neither
          // attribute its hits to a library nor honour a hidden one (#1970).
          if (parent == null) fail('Unscoped /Items search: ${request.url}');
          final includedTypes = request.url.queryParameters['IncludeItemTypes']?.split(',').toSet();
          final items = itemsByParent[parent] ?? const <Map<String, dynamic>>[];
          return _json({
            'Items': [
              for (final item in items)
                if (includedTypes == null || includedTypes.contains(item['Type'])) item,
            ],
          });
        }
        if (path == '/Artists') {
          final parent = request.url.queryParameters['parentId'];
          if (parent == null) fail('Unscoped /Artists search: ${request.url}');
          return _json({'Items': itemsByParent['artists:$parent'] ?? const <Map<String, dynamic>>[]});
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
        if (request.url.path.endsWith('/Views')) return _json({'Items': views});
        return _json({'Items': <Map<String, dynamic>>[]});
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
          return _json({'Items': responseViews});
        }
        return _json({'Items': <Map<String, dynamic>>[]});
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
        return _json({'Items': <Map<String, dynamic>>[]});
      }),
    );
    addTearDown(client.close);

    // Falling back to the unscoped query would quietly reintroduce every
    // hidden library; the server must be reported as failed instead.
    await expectLater(client.searchItems('the', excludedLibraryIds: {'lib-shows'}), throwsA(isA<Exception>()));
    expect(paths.where((path) => path == '/Items'), isEmpty);
  });
}
