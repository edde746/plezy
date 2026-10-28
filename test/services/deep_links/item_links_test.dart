import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/deep_links/deep_link.dart';
import 'package:plezy/services/deep_links/item_links.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/media_items.dart';

/// Answers only the external-id lookup, which is all a link needs.
class _ExternalIdsClient implements MediaServerClient {
  _ExternalIdsClient([this.ids = const ExternalIds(), this.error]);

  final ExternalIds ids;

  /// Thrown by every lookup: the server failing rather than an item with
  /// no mapping.
  final Exception? error;
  final List<String> calls = [];

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    calls.add(itemId);
    if (error case final error?) throw error;
    return ids;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _allIds = ExternalIds(imdb: 'tt0133093', tmdb: 603, tvdb: 169);

void main() {
  final movie = testMediaItem(id: 'movie-1', kind: MediaKind.movie, serverId: 'plex-1');
  final show = testMediaItem(id: 'show-1', kind: MediaKind.show, serverId: 'plex-1');

  /// The link [item] gets from a server answering [ids], after a round trip
  /// through the parser so every expectation also proves the link parses.
  Future<PlayLink> linkFrom(ExternalIds ids, {MediaItem? item}) async {
    final link = await linkForItem(_ExternalIdsClient(ids), item ?? movie);
    final parsed = DeepLink.tryParse(link!.toUri().toString());
    expect(parsed, isA<PlayLink>());
    expect((parsed! as PlayLink).target, link.target);
    return link;
  }

  group('linkForItem catalogue preference', () {
    test('a movie uses TMDB, then IMDb, then TVDB', () async {
      expect((await linkFrom(_allIds)).toUri().toString(), 'plezy://play?type=movie&tmdb=603');
      expect(
        (await linkFrom(const ExternalIds(imdb: 'tt0133093', tvdb: 169))).toUri().toString(),
        'plezy://play?type=movie&imdb=tt0133093',
      );
      expect((await linkFrom(const ExternalIds(tvdb: 169))).toUri().toString(), 'plezy://play?type=movie&tvdb=169');
    });

    test('a show uses TVDB, then TMDB, then IMDb', () async {
      expect((await linkFrom(_allIds, item: show)).toUri().toString(), 'plezy://play?type=show&tvdb=169');
      expect(
        (await linkFrom(const ExternalIds(imdb: 'tt0903747', tmdb: 1396), item: show)).toUri().toString(),
        'plezy://play?type=show&tmdb=1396',
      );
      expect(
        (await linkFrom(const ExternalIds(imdb: 'tt0903747'), item: show)).toUri().toString(),
        'plezy://play?type=show&imdb=tt0903747',
      );
    });

    test('names one id even when the server knows several', () async {
      final link = await linkFrom(_allIds);

      expect(link.target, const CatalogPlayTarget(kind: MediaKind.movie, ids: ExternalIds(tmdb: 603)));
    });

    test('skips an IMDb id the link grammar cannot carry', () async {
      final link = await linkFrom(const ExternalIds(imdb: 'nm0000206', tvdb: 169));

      expect(link.toUri().toString(), 'plezy://play?type=movie&tvdb=169');
    });

    test('a Jellyfin movie gets a catalogue link too', () async {
      final jellyfinMovie = testMediaItem(
        id: 'jf-movie',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'jf-server',
      );

      final link = await linkFrom(_allIds, item: jellyfinMovie);

      expect(link.toUri().toString(), 'plezy://play?type=movie&tmdb=603');
    });

    test('an Emby show gets a catalogue link too', () async {
      final embyShow = testMediaItem(
        id: 'emby-show',
        backend: MediaBackend.emby,
        kind: MediaKind.show,
        serverId: 'emby',
      );

      final link = await linkFrom(_allIds, item: embyShow);

      expect(link.toUri().toString(), 'plezy://play?type=show&tvdb=169');
    });
  });

  group('linkForItem fallbacks', () {
    test('an item without catalogue ids uses its Plex GUID', () async {
      final matched = testMediaItem(
        id: 'show-1',
        kind: MediaKind.show,
        guid: 'plex://show/5d9c086c46115600200aa2fe',
        serverId: 'plex-1',
      );

      final link = await linkFrom(const ExternalIds(), item: matched);

      expect(link.toUri().toString(), 'plezy://play?type=show&plex=5d9c086c46115600200aa2fe');
    });

    test('a Plex title carries its Plex GUID next to the catalogue id', () async {
      final matched = testMediaItem(
        id: 'movie-1',
        kind: MediaKind.movie,
        guid: 'plex://movie/5d776825880197001ec967c2',
        serverId: 'plex-1',
      );

      final link = await linkFrom(const ExternalIds(tmdb: 603), item: matched);

      // The GUID finds it on Plex libraries on the current agent, which
      // cannot be looked up by catalogue id; the id finds it elsewhere.
      expect(link.toUri().toString(), 'plezy://play?type=movie&tmdb=603&plex=5d776825880197001ec967c2');
    });

    test('ignores a Plex GUID for another kind', () async {
      final mismatched = testMediaItem(
        id: 'movie-1',
        kind: MediaKind.movie,
        guid: 'plex://show/5d9c086c46115600200aa2fe',
        serverId: 'plex-1',
      );

      final link = await linkFrom(const ExternalIds(), item: mismatched);

      expect(link.target, ItemPlayTarget(serverId: ServerId('plex-1'), itemId: 'movie-1'));
    });

    test('an unmatched item links to itself on its server', () async {
      final link = await linkFrom(const ExternalIds());

      expect(link.toUri().toString(), 'plezy://play?server=plex-1&id=movie-1');
    });

    test('a failed id lookup links to the item on its server', () async {
      final client = _ExternalIdsClient(
        _allIds,
        MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'unreachable'),
      );

      final link = await linkForItem(client, movie);

      expect(client.calls, ['movie-1']);
      expect(link!.target, ItemPlayTarget(serverId: ServerId('plex-1'), itemId: 'movie-1'));
    });

    test('a failed id lookup still uses the Plex GUID, which needs no request', () async {
      final matched = testMediaItem(
        id: 'movie-1',
        kind: MediaKind.movie,
        guid: 'plex://movie/5d776825880197001ec967c2',
        serverId: 'plex-1',
      );
      final client = _ExternalIdsClient(
        _allIds,
        MediaServerHttpException(type: MediaServerHttpErrorType.receiveTimeout, message: 'slow'),
      );

      final link = await linkForItem(client, matched);

      expect(link!.toUri().toString(), 'plezy://play?type=movie&plex=5d776825880197001ec967c2');
    });
  });

  group('episodes and unsupported items', () {
    test('an episode always links to itself, without a lookup', () async {
      final episode = testMediaItem(
        id: 'ep-1',
        kind: MediaKind.episode,
        guid: 'plex://episode/5d9c1276e9d5a1001f4ff2fa',
        serverId: 'plex-1',
      );
      final client = _ExternalIdsClient(_allIds);

      final link = await linkForItem(client, episode);

      expect(client.calls, isEmpty);
      expect(link!.toUri().toString(), 'plezy://play?server=plex-1&id=ep-1');
      expect((DeepLink.tryParse(link.toUri().toString())! as PlayLink).target, link.target);
    });

    test('a Jellyfin episode links to itself', () async {
      final episode = testMediaItem(
        id: 'jf-ep',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.episode,
        serverId: 'jf-server',
      );

      final link = await linkForItem(_ExternalIdsClient(_allIds), episode);

      expect(link!.target, ItemPlayTarget(serverId: ServerId('jf-server'), itemId: 'jf-ep'));
    });

    test('other kinds have no link', () async {
      for (final kind in [MediaKind.season, MediaKind.album, MediaKind.track, MediaKind.collection]) {
        final item = testMediaItem(id: 'x', kind: kind, serverId: 'plex-1');
        final client = _ExternalIdsClient(_allIds);

        expect(await linkForItem(client, item), isNull, reason: kind.name);
        expect(client.calls, isEmpty, reason: kind.name);
        expect(canLinkItem(item), isFalse, reason: kind.name);
      }
    });

    test('an item without a server has no link', () async {
      final orphan = testMediaItem(id: 'movie-1', kind: MediaKind.movie);

      expect(await linkForItem(_ExternalIdsClient(_allIds), orphan), isNull);
      expect(canLinkItem(orphan), isFalse);
    });
  });

  test('canLinkItem accepts movies, shows and episodes of every backend', () {
    for (final backend in MediaBackend.values) {
      for (final kind in [MediaKind.movie, MediaKind.show, MediaKind.episode]) {
        expect(
          canLinkItem(testMediaItem(id: 'x', backend: backend, kind: kind, serverId: 'srv')),
          isTrue,
          reason: '${backend.name} ${kind.name}',
        );
      }
    }
  });
}
