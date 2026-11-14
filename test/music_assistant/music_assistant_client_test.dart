import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/music_assistant/music_assistant_api.dart';
import 'package:plezy/services/music_assistant_client.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

import 'fake_ma_server.dart';

/// An audio sink that does nothing, for tests about registration lifecycle
/// rather than about playback.

void main() {
  /// Answers the library commands with [rows], and every `count` with [total].
  FakeMaServer libraryServer({List<Map<String, dynamic>> rows = const [], int total = 33369}) {
    return FakeMaServer(
      responder: (command, args) {
        if (command.endsWith('/count')) return total;
        if (command.endsWith('/library_items')) return rows;
        return const <dynamic>[];
      },
    );
  }

  group('grouping', () {
    test('reads the artists collection when the query asks for artists', () async {
      final server = libraryServer(rows: [maArtist('46')]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      final page = await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.artist, limit: 50),
      );

      expect(server.commands, contains('music/artists/library_items'));
      expect(page.items.single.kind, MediaKind.artist);
    });

    test('reads albums and tracks for their own groupings', () async {
      final albums = await connectedClient(libraryServer(rows: [maAlbum('1')]));
      addTearDown(albums.close);
      await albums.fetchLibraryPagedContent('music', query: const LibraryQuery(kind: MediaKind.album, limit: 50));

      final server = libraryServer(rows: [maTrack('1')]);
      final tracks = await connectedClient(server);
      addTearDown(tracks.close);
      await tracks.fetchLibraryPagedContent('music', query: const LibraryQuery(kind: MediaKind.track, limit: 50));

      expect(server.commands, contains('music/tracks/library_items'));
    });

    test('defaults to artists, not the 370,000-row track list', () async {
      final server = libraryServer();
      final client = await connectedClient(server);
      addTearDown(client.close);

      // No kind at all: the library's own kind is the only hint, and even that
      // must not open onto every track in the collection.
      await client.fetchLibraryPagedContent('music', query: const LibraryQuery(limit: 50));

      expect(server.commands, contains('music/artists/library_items'));
    });

    test('honours the library kind when the query carries none', () async {
      final server = libraryServer();
      final client = await connectedClient(server);
      addTearDown(client.close);

      await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(limit: 50),
        libraryKind: MediaKind.album,
      );

      expect(server.commands, contains('music/albums/library_items'));
    });
  });

  group('paging', () {
    test('always sends an explicit limit, even for a query that omits one', () async {
      final server = libraryServer();
      final client = await connectedClient(server);
      addTearDown(client.close);

      // A request with no limit is truncated at 500 rows by the server with no
      // indication, so a zero/absent limit must never reach the wire.
      await client.fetchLibraryPagedContent('music', query: const LibraryQuery(limit: 0));

      final args = server.argsFor('music/artists/library_items');
      expect(args['limit'], isA<int>().having((limit) => limit > 0, 'positive', isTrue));
    });

    test('passes offset and limit straight through', () async {
      final server = libraryServer();
      final client = await connectedClient(server);
      addTearDown(client.close);

      await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.album, offset: 12800, limit: 200),
      );

      expect(server.argsFor('music/albums/library_items'), containsPair('offset', 12800));
      expect(server.argsFor('music/albums/library_items'), containsPair('limit', 200));
    });

    test('takes the total from the matching count command', () async {
      final client = await connectedClient(libraryServer(rows: [maAlbum('1')], total: 33369));
      addTearDown(client.close);

      final page = await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.album, limit: 50),
      );

      expect(page.totalCount, 33369);
      expect(page.offset, 0);
    });

    test('does not re-ask for the total on every page', () async {
      final server = libraryServer(rows: [maAlbum('1')]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      for (var offset = 0; offset < 500; offset += 100) {
        await client.fetchLibraryPagedContent(
          'music',
          query: LibraryQuery(kind: MediaKind.album, offset: offset, limit: 100),
        );
      }

      // Five pages, one total: re-measuring a count that changes on the scale of
      // a library scan is pure latency on a fast scroll.
      expect(server.countOf('music/albums/count'), 1);
      // Six reads for five pages: the extra one is the one-off probe that
      // measures the `#` block at the head of the alphabetical list, and it is
      // memoised for the same reason the total is.
      expect(server.countOf('music/albums/library_items'), 6);
    });

    test('preserves server order rather than re-sorting by title', () async {
      // sort_name and name disagree for about one item in nine; sorting by name
      // client-side makes rows jump as later pages land.
      final server = libraryServer(
        rows: [
          {...maAlbum('1', name: 'The 100 Greatest Hits'), 'sort_name': '100 greatest hits'},
          maAlbum('2', name: 'Abbey Road'),
        ],
      );
      final client = await connectedClient(server);
      addTearDown(client.close);

      final page = await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.album, limit: 50),
      );

      expect(page.items.map((item) => item.title), ['The 100 Greatest Hits', 'Abbey Road']);
    });
  });

  group('ordering', () {
    Future<Object?> orderFor(LibrarySort? sort) async {
      final server = libraryServer();
      final client = await connectedClient(server);
      addTearDown(client.close);
      await client.fetchLibraryPagedContent(
        'music',
        query: LibraryQuery(kind: MediaKind.album, limit: 50, sort: sort),
      );
      return server.argsFor('music/albums/library_items')['order_by'];
    }

    test('newest-first uses the underscore suffix the server actually honours', () async {
      // "timestamp_added DESC" is accepted and then silently ordered ascending,
      // which would make a "recently added" sort show the oldest albums.
      expect(await orderFor(const LibrarySort(field: 'addedAt')), 'timestamp_added_desc');
      expect(
        await orderFor(const LibrarySort(field: 'addedAt', direction: LibrarySortDirection.ascending)),
        'timestamp_added',
      );
    });

    test('maps title and year in both directions', () async {
      expect(
        await orderFor(const LibrarySort(field: 'titleSort', direction: LibrarySortDirection.ascending)),
        'sort_name',
      );
      expect(await orderFor(const LibrarySort(field: 'titleSort')), 'sort_name_desc');
      expect(await orderFor(const LibrarySort(field: 'year')), 'year_desc');
    });

    test('never forwards an unknown field, falling back to the alphabetical default', () async {
      // An unknown order_by is not rejected, it is dropped — and the query then
      // runs with no ORDER BY at all, which is insertion order rather than the
      // sort_name default. Forwarding a guess would show a list that looks
      // shuffled and reports success.
      expect(await orderFor(const LibrarySort(field: 'communityRating')), 'sort_name');
      expect(await orderFor(null), 'sort_name');
    });

    test('offers year only on albums, where the column exists', () async {
      // `year` on artists, tracks or playlists is error_code 999 "no such
      // column: year" — a page that fails outright, not one that quietly
      // reorders. A saved sort surviving a switch from Albums to Tracks is
      // enough to hit it, so the mapping has to refuse as well as the menu.
      expect(await orderFor(const LibrarySort(field: 'year')), 'year_desc');

      final server = libraryServer();
      final client = await connectedClient(server);
      addTearDown(client.close);
      await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(
          kind: MediaKind.track,
          limit: 50,
          sort: LibrarySort(field: 'year'),
        ),
      );
      expect(server.argsFor('music/tracks/library_items')['order_by'], 'sort_name');
    });

    test('offers duration only on tracks, where the column exists', () async {
      final server = libraryServer();
      final client = await connectedClient(server);
      addTearDown(client.close);
      await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(
          kind: MediaKind.track,
          limit: 50,
          sort: LibrarySort(field: 'runtime', direction: LibrarySortDirection.ascending),
        ),
      );
      expect(server.argsFor('music/tracks/library_items')['order_by'], 'duration');

      // `duration` on albums is error_code 999 the same way `year` is on tracks.
      expect(await orderFor(const LibrarySort(field: 'runtime')), 'sort_name');
    });

    test('pins the sort set to the orderings verified against a live server', () async {
      final client = await connectedClient(libraryServer());
      addTearDown(client.close);

      Future<List<String>> keysFor(String? type) async =>
          (await client.fetchSortOptions('music', libraryType: type)).map((sort) => sort.key).toList();

      // Verified means "changed the result set", not "was accepted": the server
      // takes `track_number`, `album_name` and `original_sort_name` without
      // complaint and returns the collection in insertion order for all three.
      expect(await keysFor('artist'), ['titleSort', 'addedAt']);
      expect(await keysFor('album'), ['titleSort', 'addedAt', 'year']);
      expect(await keysFor('track'), ['titleSort', 'addedAt', 'runtime']);
      expect(await keysFor('playlist'), ['titleSort', 'addedAt']);

      // random is a real server-side shuffle, so paging it would repeat and skip
      // rows. It backs the discovery row instead, which is one page by design.
      expect(await keysFor('album'), isNot(contains('random')));
    });
  });

  group('the # bucket', () {
    /// Serves [head] followed by [body], answering any offset/limit out of the
    /// concatenation — enough to observe where the client cuts the list.
    FakeMaServer bucketServer(List<Map<String, dynamic>> head, List<Map<String, dynamic>> body) {
      final all = [...head, ...body];
      return FakeMaServer(
        responder: (command, args) {
          if (command.endsWith('/count')) return all.length;
          if (!command.endsWith('/library_items')) return const <dynamic>[];
          final offset = args['offset'] as int? ?? 0;
          final limit = args['limit'] as int? ?? all.length;
          return all.skip(offset).take(limit).toList();
        },
      );
    }

    /// `sort_name` values taken straight off the reference server's first page.
    List<Map<String, dynamic>> unsortable(List<String> sortNames) => [
      for (var i = 0; i < sortNames.length; i++) {...maAlbum('p$i', name: sortNames[i]), 'sort_name': sortNames[i]},
    ];

    test('opens the alphabetical list on a real title, not on punctuation', () async {
      final server = bucketServer(unsortable(const ['+', '-', '÷', '.', '!', '( )', '!', '?']), [
        maAlbum('1', name: 'Abbey Road'),
        maAlbum('2', name: 'Back in Black'),
      ]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      final page = await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.album, limit: 2),
      );

      expect(page.items.map((item) => item.title), ['Abbey Road', 'Back in Black']);
      expect(page.totalCount, 10);
    });

    test('serves the # block after Z rather than dropping it', () async {
      final server = bucketServer(unsortable(const ['+', '-']), [
        maAlbum('1', name: 'Abbey Road'),
        maAlbum('2', name: 'Back in Black'),
      ]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      final tail = await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.album, offset: 2, limit: 2),
      );

      // Moved, not hidden: the rotation has to stay reversible or the total
      // would be claiming rows the list can never reach.
      expect(tail.items.map((item) => item.title), ['+', '-']);
      expect(tail.totalCount, 4);
    });

    test('fills the last page from both regions without repeating a row', () async {
      final server = bucketServer(unsortable(const ['+', '-']), [
        maAlbum('1', name: 'Abbey Road'),
        maAlbum('2', name: 'Back in Black'),
        maAlbum('3', name: 'Cross'),
      ]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      final page = await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.album, offset: 2, limit: 3),
      );

      expect(page.items.map((item) => item.title), ['Cross', '+', '-']);
      expect(page.items.map((item) => item.id).toSet(), hasLength(3));
    });

    test('leaves a numeric title where the server put it', () async {
      // 1989 is a title people look for under 1. Folding numerics into `#`
      // would bury 658 albums behind a symbol on the reference library.
      final server = bucketServer(unsortable(const ['+']), [
        {...maAlbum('n', name: '1989'), 'sort_name': '1989'},
        maAlbum('1', name: 'Abbey Road'),
      ]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      final page = await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.album, limit: 3),
      );

      expect(page.items.map((item) => item.title), ['1989', 'Abbey Road', '+']);
    });

    test('does not rotate a descending list, which has no # block at its head', () async {
      final server = bucketServer(unsortable(const ['+']), [maAlbum('1', name: 'Abbey Road')]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(
          kind: MediaKind.album,
          offset: 40,
          limit: 10,
          sort: LibrarySort(field: 'titleSort'),
        ),
      );

      final args = server.argsFor('music/albums/library_items');
      expect(args['order_by'], 'sort_name_desc');
      expect(args['offset'], 40, reason: 'a descending list already ends on the # block');
    });

    test('gives up rather than rotate at a boundary it never found', () async {
      // A first page that is entirely unsortable means the block is longer than
      // one page and its size was not measured. Rotating on that guess would
      // shift every offset by a wrong amount.
      final server = bucketServer(unsortable(List.generate(500, (i) => '!' * (i % 7 + 1))), []);
      final client = await connectedClient(server);
      addTearDown(client.close);

      await client.fetchLibraryPagedContent(
        'music',
        query: const LibraryQuery(kind: MediaKind.album, offset: 100, limit: 10),
      );

      expect(server.argsFor('music/albums/library_items')['offset'], 100);
    });
  });

  group('discovery rows', () {
    FakeMaServer discoveryServer({
      List<Map<String, dynamic>> albums = const [],
      List<Map<String, dynamic>> favouriteAlbums = const [],
      List<Map<String, dynamic>> favouriteTracks = const [],
      List<Map<String, dynamic>> played = const [],
    }) {
      return FakeMaServer(
        responder: (command, args) {
          if (command.endsWith('/count')) return 33369;
          if (command == 'music/recently_played_items') return played;
          if (args['favorite'] == true) {
            return command == 'music/albums/library_items' ? favouriteAlbums : favouriteTracks;
          }
          if (command == 'music/albums/library_items') return albums;
          return const <dynamic>[];
        },
      );
    }

    test('recently added asks for newest first, not the ascending lookalike', () async {
      final server = discoveryServer(albums: [maAlbum('1')]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 20);

      final recent = hubs.firstWhere((hub) => hub.id == 'ma:recentlyAdded');
      expect(recent.items, isNotEmpty);
      expect(
        server.requests
            .where((request) => request['command'] == 'music/albums/library_items')
            .map((request) => (request['args'] as Map)['order_by']),
        contains('timestamp_added_desc'),
      );
    });

    test('random albums shuffles server-side rather than paging at a random offset', () async {
      final server = discoveryServer(albums: [maAlbum('1')]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      await client.fetchGlobalHubs(limit: 20);

      final randomRequest = server.requests.firstWhere((request) => (request['args'] as Map?)?['order_by'] == 'random');
      // A random offset only reshuffles the window; `order_by: random` puts the
      // whole collection in play.
      expect((randomRequest['args'] as Map)['offset'], anyOf(isNull, 0));
    });

    test('drops a row the server has nothing for instead of rendering it blank', () async {
      final client = await connectedClient(discoveryServer(albums: [maAlbum('1')]));
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 20);

      expect(hubs.map((hub) => hub.id), isNot(contains('ma:favorites')));
      expect(hubs.map((hub) => hub.id), containsAll(['ma:recentlyAdded', 'ma:randomAlbums']));
    });

    test('combines favourite albums and tracks into one row', () async {
      final client = await connectedClient(
        discoveryServer(favouriteAlbums: [maAlbum('1')], favouriteTracks: [maTrack('2')]),
      );
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 20);

      final favourites = hubs.firstWhere((hub) => hub.id == 'ma:favorites');
      expect(favourites.items.map((item) => item.kind), [MediaKind.album, MediaKind.track]);
    });

    test('offers no "see more" on the shuffle row', () async {
      final client = await connectedClient(discoveryServer(albums: [for (var i = 0; i < 20; i++) maAlbum('$i')]));
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 20);

      expect(hubs.firstWhere((hub) => hub.id == 'ma:recentlyAdded').more, isTrue);
      // "See more" on a shuffle would just reshuffle.
      expect(hubs.firstWhere((hub) => hub.id == 'ma:randomAlbums').more, isFalse);
    });

    test('recently played reads the play log, never an ordered library page', () async {
      final server = discoveryServer(albums: [maAlbum('1')], played: [maTrack('2'), maAlbum('3')]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 20);

      final played = hubs.firstWhere((hub) => hub.id == 'ma:recentlyPlayed');
      expect(played.items.map((item) => item.kind), [MediaKind.track, MediaKind.album]);
      // Measured on the reference server: only 10 of 33,369 albums carry any
      // play data, so `last_played_desc`/`play_count_desc` would answer with
      // ten real rows followed by ten arbitrary ones. Neither may be sent.
      expect(
        server.requests.map((request) => (request['args'] as Map?)?['order_by']),
        isNot(anyElement(anyOf('last_played_desc', 'play_count_desc'))),
      );
      // radio/podcast/audiobook have no neutral kind and would render as
      // unknown items, and a playlist has no square silhouette.
      expect(server.argsFor('music/recently_played_items')['media_types'], ['artist', 'album', 'track']);
    });

    test('recently played is the first row, and drops when nothing has been played', () async {
      final client = await connectedClient(discoveryServer(albums: [maAlbum('1')], played: [maTrack('2')]));
      addTearDown(client.close);
      expect((await client.fetchGlobalHubs(limit: 20)).first.id, 'ma:recentlyPlayed');

      final quiet = await connectedClient(discoveryServer(albums: [maAlbum('1')]));
      addTearDown(quiet.close);
      expect((await quiet.fetchGlobalHubs(limit: 20)).map((hub) => hub.id), isNot(contains('ma:recentlyPlayed')));
    });

    test('offers no "see more" on the play log — a full row is the whole history', () async {
      final client = await connectedClient(
        discoveryServer(albums: [maAlbum('1')], played: [for (var i = 0; i < 20; i++) maTrack('$i')]),
      );
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 20);

      expect(hubs.firstWhere((hub) => hub.id == 'ma:recentlyPlayed').more, isFalse);
      // And paging it cannot invent a second page: the command takes no offset,
      // so re-asking would hand back the same rows under a later index.
      final second = await client.fetchMoreHubItemsPage('ma:recentlyPlayed', start: 20, size: 20);
      expect(second.items, isEmpty);
    });
  });

  group('search', () {
    test('always restricts to the library index', () async {
      final server = FakeMaServer(
        responder: (command, args) => command == 'music/search'
            ? {
                'artists': [maArtist('46')],
                'albums': [maAlbum('1')],
                'tracks': [maTrack('2')],
              }
            : const <dynamic>[],
      );
      final client = await connectedClient(server);
      addTearDown(client.close);

      final results = await client.searchItems('radiohead', limit: 25);

      // Without library_only the server queries every configured provider live:
      // 8.42s versus 0.09s for a common query, for the same rows.
      expect(server.argsFor('music/search'), containsPair('library_only', true));
      expect(server.argsFor('music/search'), containsPair('limit', 25));
      expect(results.map((item) => item.kind), [MediaKind.artist, MediaKind.album, MediaKind.track]);
    });
  });

  group('children', () {
    test('resolves an album uri without a lookup round-trip', () async {
      final server = FakeMaServer(
        responder: (command, args) => command == 'music/albums/album_tracks' ? [maTrack('1')] : const <dynamic>[],
      );
      final client = await connectedClient(server);
      addTearDown(client.close);

      final tracks = await client.fetchAlbumTracks('library://album/9560');

      // The uri already encodes provider, media type and item id, so asking the
      // server who this is would be a wasted round-trip.
      expect(server.commands, ['music/albums/album_tracks']);
      expect(server.argsFor('music/albums/album_tracks'), {
        'item_id': '9560',
        'provider_instance_id_or_domain': 'library',
      });
      expect(tracks.single.kind, MediaKind.track);
    });

    test('dispatches on the media type in the uri', () async {
      final server = FakeMaServer(responder: (command, args) => const <dynamic>[]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      await client.fetchChildren('library://artist/46');
      await client.fetchChildren('library://playlist/4');

      // The second playlist_tracks is the force_refresh retry: an unresolved
      // playlist answers empty with no error, so one empty answer is not proof
      // the playlist is empty.
      expect(server.commands, [
        'music/artists/artist_albums',
        'music/playlists/playlist_tracks',
        'music/playlists/playlist_tracks',
      ]);
      expect(server.argsFor('music/playlists/playlist_tracks'), containsPair('force_refresh', true));
    });

    test('pages children client-side, because the commands take no offset', () async {
      final server = FakeMaServer(
        responder: (command, args) =>
            command == 'music/albums/album_tracks' ? [for (var i = 0; i < 16; i++) maTrack('$i')] : const <dynamic>[],
      );
      final client = await connectedClient(server);
      addTearDown(client.close);

      final page = await client.fetchChildrenPage('library://album/9560', start: 4, size: 5);

      expect(page.items, hasLength(5));
      expect(page.offset, 4);
      expect(page.totalCount, 16);
    });

    test('an artist expands to tracks via its own command, not album by album', () async {
      final server = FakeMaServer(responder: (command, args) => const <dynamic>[]);
      final client = await connectedClient(server);
      addTearDown(client.close);

      await client.fetchPlayableDescendants('library://artist/46');

      expect(server.commands, ['music/artists/artist_tracks']);
    });
  });

  group('identity', () {
    MusicAssistantConnection row({String? serverId}) => MusicAssistantConnection(
      id: 'ma-row',
      displayName: 'Basement NAS',
      baseUrl: 'http://10.0.2.107:8095',
      serverId: serverId,
      createdAt: DateTime.utc(2026),
    );

    Future<MusicAssistantClient> unreachable({String? serverId}) => MusicAssistantClient.create(
      row(serverId: serverId),
      api: MusicAssistantApi(
        channelFactory: (_) async => throw const MaConnectionException('refused'),
        autoReconnect: false,
      ),
    );

    test('serverId falls back to the row id, and settledServerId refuses to', () async {
      // The two answers are deliberately different. `serverId` must never be
      // empty because registries and cache keys are built from it the instant
      // a client exists. `settledServerId` is what anything durable takes: the
      // row id is a placeholder that stops being true the moment the
      // transport's own retry succeeds, and a persisted row keyed on it names
      // a server nothing will ever answer to.
      final client = await unreachable();
      addTearDown(client.close);

      expect(client.hasSettledIdentity, isFalse);
      expect(client.serverId.value, 'ma-row', reason: 'registries still need a non-empty key');
      expect(client.settledServerId, isNull);
    });

    test('a serverId persisted by an earlier handshake is durable even while offline', () async {
      // It was written *by* a greeting, so it is the server's own id — it just
      // came from a previous run rather than this one.
      final client = await unreachable(serverId: 'fe2f5b6fd78e4608bb8b075a6c269fbf');
      addTearDown(client.close);

      expect(client.settledServerId?.value, 'fe2f5b6fd78e4608bb8b075a6c269fbf');
    });

    test('once the greeting lands both answer the server id', () async {
      final client = await connectedClient(libraryServer());
      addTearDown(client.close);

      expect(client.hasSettledIdentity, isTrue);
      expect(client.settledServerId, client.serverId);
      expect(client.serverId.value, 'fe2f5b6fd78e4608bb8b075a6c269fbf');
    });
  });

  group('log redaction', () {
    // Global static state, so it is reset around each case rather than left to
    // leak into whatever runs next in this file.
    setUp(LogRedactionManager.clearTrackedValues);
    tearDown(LogRedactionManager.clearTrackedValues);

    test('the server URL and token are registered before the socket is opened', () async {
      // Logging is not compiled out in release: ProductionFilter passes
      // Level.info into a 5 MB ring buffer the user can upload. Plex and
      // Jellyfin both register here; Music Assistant registered nothing, so
      // every `Music Assistant probe failed for <url>` shipped the host. An IP
      // is masked by the generic pattern, a hostname is not — hence the
      // hostname in this fixture.
      const url = 'http://music.home.lan:8095';
      expect(
        LogRedactionManager.redact('probe failed for $url'),
        contains('music.home.lan'),
        reason: 'precondition: nothing is registered yet',
      );

      final client = await MusicAssistantClient.create(
        MusicAssistantConnection(
          id: 'ma-1',
          displayName: 'Basement NAS',
          baseUrl: url,
          accessToken: 'ma-token-2f8c1e',
          createdAt: DateTime.utc(2026),
        ),
        // Unreachable on purpose: registration must not depend on the
        // handshake succeeding, because the failure path is what logs.
        api: MusicAssistantApi(
          channelFactory: (_) async => throw const MaConnectionException('refused'),
          autoReconnect: false,
        ),
      );
      addTearDown(client.close);

      expect(LogRedactionManager.redact('Music Assistant probe failed for $url'), isNot(contains('music.home.lan')));
      expect(LogRedactionManager.redact('sent ma-token-2f8c1e upstream'), isNot(contains('ma-token-2f8c1e')));
    });
  });

  group('surfaces this backend does not have', () {
    test('the alpha bar gets nothing to render', () async {
      final client = await connectedClient(libraryServer());
      addTearDown(client.close);

      // There is no way to turn a letter into an offset here, so a bar would be
      // a control that cannot jump.
      expect(await client.fetchFirstCharacters('music'), isEmpty);
    });

    test('one synthetic library, named after the server', () async {
      final client = await connectedClient(libraryServer());
      addTearDown(client.close);

      final libraries = await client.fetchLibraries();

      expect(libraries.single.title, 'Basement NAS');
      expect(libraries.single.kind, MediaKind.artist);
    });

    test('a connection named after its address does not name the music', () async {
      // The old default display name was the host, so this is what every
      // connection saved before that changed still holds. 33,000 albums under
      // the title `10.0.2.107` is not a library anyone recognises as theirs.
      final client = await connectedClient(libraryServer(), displayName: '10.0.2.107');
      addTearDown(client.close);

      expect((await client.fetchLibraries()).single.title, 'Music Assistant');
      expect(client.serverName, 'Music Assistant');
    });

    test('video features refuse rather than answering emptily', () async {
      final client = await connectedClient(libraryServer());
      addTearDown(client.close);

      final item = MediaItem(id: 'library://track/1', backend: MediaBackend.musicAssistant, kind: MediaKind.track);
      expect(client.fetchLibraryFolders('music'), throwsUnsupportedError);
      expect(client.markWatched(item), throwsUnsupportedError);
      expect(client.rate(item, 8), throwsUnsupportedError);
      expect(await client.liveTv.isAvailable(), isFalse);
    });
  });

  group('a disposed client', () {
    test('reports as cancelled, not as the server being unreachable', () async {
      // The client is disposed when *we* replace it — a rebind, a reconnect, a
      // profile switch. Reporting that as a connection failure told users the
      // media server could not be reached while it was answering fine.
      final client = await connectedClient(libraryServer());
      client.close();

      await expectLater(
        client.fetchLibraryPagedContent('music', query: const LibraryQuery(kind: MediaKind.album, limit: 1)),
        throwsA(
          isA<MediaServerHttpException>()
              .having((e) => e.type, 'type', MediaServerHttpErrorType.cancelled)
              .having((e) => e.isCancellation, 'isCancellation', isTrue),
        ),
      );
    });
  });

  group('a wedged server', () {
    test('is reported unhealthy in seconds, not in the request timeout', () {
      // A wedged Music Assistant keeps its socket open and has already sent
      // its greeting, so nothing about the connection says anything is wrong;
      // commands simply stop coming back. Inheriting the 30s request budget
      // meant every surface that asks about health waited half a minute to
      // learn what one unanswered probe already implied, and the app looked
      // hung rather than degraded.
      fakeAsync((async) {
        final server = libraryServer();
        HealthStatus? health;
        MusicAssistantClient? client;

        // The production request budget, so the probe's own shorter budget is
        // what the assertion measures.
        connectedClient(server, requestTimeout: const Duration(seconds: 30)).then((c) {
          client = c;
          server.wedged = true;
          c.checkHealth().then((result) => health = result);
        });

        async.elapse(const Duration(seconds: 1));
        expect(health, isNull, reason: 'a probe should not resolve before it has had a chance');

        async.elapse(MusicAssistantClient.healthProbeTimeout + const Duration(seconds: 1));
        expect(health, HealthStatus.offline, reason: 'a server that answers nothing must be reported offline promptly');

        client?.close();
        async.flushTimers();
      });
    });
  });
}
