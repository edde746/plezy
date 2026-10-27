import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/deep_links/deep_link.dart';
import 'package:plezy/services/deep_links/deep_link_launcher.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/media_items.dart';

/// Serves canned items. Every other call reaches [noSuchMethod] and throws.
class _Client implements MediaServerClient {
  _Client(String serverId, {this.backend = MediaBackend.plex}) : serverId = ServerId(serverId);

  @override
  final ServerId serverId;

  @override
  final MediaBackend backend;

  final items = <String, MediaItem>{};
  final onDeck = <String, MediaItem>{};
  final descendants = <String, List<MediaItem>>{};
  Object? fetchError;

  @override
  Future<MediaItem?> fetchItem(String id) async {
    if (fetchError case final error?) throw error;
    return items[id];
  }

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem item)? onItemReady,
  }) async => (item: items[id], onDeckEpisode: onDeck[id]);

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async => descendants[parentId] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _item(
  String id,
  MediaKind kind,
  String serverId, {
  int? lastViewedAt,
  int? season,
  int? episode,
  int? viewCount,
}) => testMediaItem(
  id: id,
  kind: kind,
  serverId: serverId,
  lastViewedAt: lastViewedAt,
  parentIndex: season,
  index: episode,
  viewCount: viewCount,
);

LibraryLookupResult _lookup(List<MediaItem> items, {Set<String> failed = const {}, Set<String> unqueried = const {}}) =>
    (
      items: items,
      succeededServerIds: {for (final item in items) item.serverId!},
      cancelledServerIds: const <String>{},
      failedServerIds: failed,
      unqueriedServerIds: unqueried,
    );

class _Servers extends ChangeNotifier {
  final clients = <String, _Client>{};
  final online = <String>{};
  LibraryLookupResult catalog = _lookup(const []);
  final downloads = <String, MediaItem>{};
  final catalogQueries = <CatalogPlayTarget>[];

  /// Plex Discover; null when no Plex account is signed in.
  Future<String?> Function(CatalogPlayTarget target)? plexHash;

  void add(_Client client, {bool online = true}) {
    clients[client.serverId] = client;
    if (online) this.online.add(client.serverId);
  }

  bool get listening => hasListeners;

  void bringOnline(String serverId) {
    online.add(serverId);
    notifyListeners();
  }

  PlayLinkResolver resolver({Duration serverWait = const Duration(minutes: 1)}) => PlayLinkResolver(
    PlayLinkSources(
      clientFor: (id) => clients[id],
      isServerOnline: online.contains,
      hasOnlineServers: () => online.isNotEmpty,
      serversChanged: this,
      findCatalogCopies: (target) async {
        catalogQueries.add(target);
        return catalog;
      },
      downloadedItem: (serverId, itemId) => downloads['$serverId:$itemId'],
      resolvePlexHash: plexHash,
    ),
    serverWait: serverWait,
  );
}

PlayLink _itemLink(String server, String id, {PlayMode mode = PlayMode.next}) => PlayLink(
  target: ItemPlayTarget(serverId: ServerId(server), itemId: id),
  mode: mode,
);

const _movieLink = PlayLink(
  target: CatalogPlayTarget(kind: MediaKind.movie, ids: ExternalIds(tmdb: 603)),
);
const _showLink = PlayLink(
  target: CatalogPlayTarget(kind: MediaKind.show, ids: ExternalIds(tvdb: 81189)),
);

Matcher _plays(String id, {bool offline = false}) =>
    isA<PlayLinkItem>().having((r) => r.item.id, 'item', id).having((r) => r.offline, 'offline', offline);

Matcher _fails(PlayLinkFailureReason reason) => isA<PlayLinkFailure>().having((r) => r.reason, 'reason', reason);

void main() {
  late _Servers servers;

  setUp(() => servers = _Servers());

  group('a link to one item', () {
    test('plays a movie or an episode as it is', () async {
      final client = _Client('s1')..items['m1'] = _item('m1', MediaKind.movie, 's1');
      servers.add(client);
      expect(await servers.resolver().resolve(_itemLink('s1', 'm1')), _plays('m1'));
    });

    test('plays the On Deck episode of a show, else its first regular episode', () async {
      final client = _Client('s1', backend: MediaBackend.jellyfin)
        ..items['show'] = _item('show', MediaKind.show, 's1')
        ..descendants['show'] = [
          _item('special', MediaKind.episode, 's1', season: 0, episode: 1),
          _item('s2e1', MediaKind.episode, 's1', season: 2, episode: 1),
          _item('s1e1', MediaKind.episode, 's1', season: 1, episode: 1),
        ];
      servers.add(client);
      expect(await servers.resolver().resolve(_itemLink('s1', 'show')), _plays('s1e1'));

      client.onDeck['show'] = _item('s2e1', MediaKind.episode, 's1', season: 2, episode: 1);
      expect(await servers.resolver().resolve(_itemLink('s1', 'show')), _plays('s2e1'));
    });

    test('plays the first unwatched episode of a season', () async {
      final client = _Client('s1')
        ..items['season'] = _item('season', MediaKind.season, 's1')
        ..descendants['season'] = [
          _item('e2', MediaKind.episode, 's1', season: 1, episode: 2),
          _item('e1', MediaKind.episode, 's1', season: 1, episode: 1, viewCount: 1),
        ];
      servers.add(client);
      expect(await servers.resolver().resolve(_itemLink('s1', 'season')), _plays('e2'));
    });

    test('shuffles a show', () async {
      servers.add(_Client('s1')..items['show'] = _item('show', MediaKind.show, 's1'));
      final resolution = await servers.resolver().resolve(_itemLink('s1', 'show', mode: PlayMode.shuffle));
      expect(resolution, isA<PlayLinkShuffle>().having((r) => r.item.id, 'item', 'show'));
    });

    test('refuses what a link cannot play', () async {
      servers.add(_Client('s1')..items['t1'] = _item('t1', MediaKind.track, 's1'));
      expect(await servers.resolver().resolve(_itemLink('s1', 't1')), _fails(PlayLinkFailureReason.unsupportedItem));
      expect(await servers.resolver().resolve(_itemLink('s1', 'gone')), _fails(PlayLinkFailureReason.notFound));
    });

    test('plays the download at once while its server is away', () async {
      servers.add(_Client('s1'), online: false);
      servers.downloads['s1:m1'] = _item('m1', MediaKind.movie, 's1');
      expect(await servers.resolver().resolve(_itemLink('s1', 'm1')), _plays('m1', offline: true));
    });

    test('falls back to the download when its server fails to answer', () async {
      servers.add(_Client('s1')..fetchError = StateError('timeout'));
      expect(await servers.resolver().resolve(_itemLink('s1', 'm1')), _fails(PlayLinkFailureReason.serverUnavailable));
      servers.downloads['s1:m1'] = _item('m1', MediaKind.movie, 's1');
      expect(await servers.resolver().resolve(_itemLink('s1', 'm1')), _plays('m1', offline: true));
    });

    test('waits for its server to come online', () async {
      servers.add(_Client('s1')..items['m1'] = _item('m1', MediaKind.movie, 's1'), online: false);
      final resolution = servers.resolver().resolve(_itemLink('s1', 'm1'));
      await pumpEventQueue();
      servers.bringOnline('s1');
      expect(await resolution, _plays('m1'));
      expect(servers.listening, isFalse);
    });

    test('gives up on a server that stays away', () async {
      servers.add(_Client('s1'), online: false);
      expect(
        await servers.resolver(serverWait: Duration.zero).resolve(_itemLink('s1', 'm1')),
        _fails(PlayLinkFailureReason.serverUnavailable),
      );
    });
  });

  group('a link to a catalogue title', () {
    test('resumes the copy of a movie watched last, across servers and backends', () async {
      final plex = _Client('plex')..items['p'] = _item('p', MediaKind.movie, 'plex', lastViewedAt: 100);
      final jelly = _Client('jelly', backend: MediaBackend.jellyfin)
        ..items['j'] = _item('j', MediaKind.movie, 'jelly', lastViewedAt: 200);
      servers
        ..add(plex)
        ..add(jelly)
        // The lookup rows carry stale watch state; the refreshed items decide.
        ..catalog = _lookup([_item('p', MediaKind.movie, 'plex'), _item('j', MediaKind.movie, 'jelly')]);
      expect(await servers.resolver().resolve(_movieLink), _plays('j'));
      expect(servers.catalogQueries.single.ids.tmdb, 603);
    });

    test('plays the best copy of a movie nobody watched', () async {
      servers
        ..add(_Client('a'))
        ..add(_Client('b'))
        ..catalog = _lookup([_item('a1', MediaKind.movie, 'a'), _item('b1', MediaKind.movie, 'b')]);
      expect(await servers.resolver().resolve(_movieLink), _plays('a1'));
    });

    test('continues the show where it is being watched', () async {
      final a = _Client('a')
        ..items['show-a'] = _item('show-a', MediaKind.show, 'a', lastViewedAt: 100)
        ..onDeck['show-a'] = _item('a-s1e3', MediaKind.episode, 'a');
      final b = _Client('b')
        ..items['show-b'] = _item('show-b', MediaKind.show, 'b', lastViewedAt: 300)
        ..onDeck['show-b'] = _item('b-s2e1', MediaKind.episode, 'b');
      servers
        ..add(a)
        ..add(b)
        ..catalog = _lookup([_item('show-a', MediaKind.show, 'a'), _item('show-b', MediaKind.show, 'b')]);
      expect(await servers.resolver().resolve(_showLink), _plays('b-s2e1'));
    });

    test('starts an unwatched show at its first episode', () async {
      final a = _Client('a')
        ..descendants['show-a'] = [
          _item('s1e2', MediaKind.episode, 'a', season: 1, episode: 2),
          _item('s1e1', MediaKind.episode, 'a', season: 1, episode: 1),
        ];
      servers
        ..add(a)
        ..catalog = _lookup([_item('show-a', MediaKind.show, 'a')]);
      expect(await servers.resolver().resolve(_showLink), _plays('s1e1'));
    });

    test('ignores matches of another kind', () async {
      servers
        ..add(_Client('a'))
        ..catalog = _lookup([_item('show-a', MediaKind.show, 'a')]);
      expect(await servers.resolver().resolve(_movieLink), _fails(PlayLinkFailureReason.notFound));
    });

    test('blames an unreachable server, not the library, when nothing matched', () async {
      servers.add(_Client('a'));
      servers.catalog = _lookup(const [], failed: {'b'});
      expect(await servers.resolver().resolve(_movieLink), _fails(PlayLinkFailureReason.serverUnavailable));

      servers.catalog = _lookup(const [], unqueried: {'offline'});
      expect(await servers.resolver().resolve(_movieLink), _fails(PlayLinkFailureReason.serverUnavailable));

      // Online but unable to run the query: it cannot hold the title.
      servers.catalog = _lookup(const [], unqueried: {'a'});
      expect(await servers.resolver().resolve(_movieLink), _fails(PlayLinkFailureReason.notFound));
    });

    test('waits for any server before looking', () async {
      servers.add(_Client('a'), online: false);
      servers.catalog = _lookup([_item('a1', MediaKind.movie, 'a')]);
      final resolution = servers.resolver().resolve(_movieLink);
      await pumpEventQueue();
      expect(servers.catalogQueries, isEmpty);
      servers.bringOnline('a');
      expect(await resolution, _plays('a1'));
    });

    test('looks a link without a Plex GUID up by the GUID Plex Discover has for its ids', () async {
      servers
        ..add(_Client('a'))
        ..catalog = _lookup([_item('a1', MediaKind.movie, 'a')])
        ..plexHash = (target) async => target.ids.tmdb == 603 ? '5d776825880197001ec967c2' : null;
      expect(await servers.resolver().resolve(_movieLink), _plays('a1'));
      expect(servers.catalogQueries.single.plexGuid, 'plex://movie/5d776825880197001ec967c2');
      expect(servers.catalogQueries.single.ids.tmdb, 603);
    });

    test('still looks up by catalogue id when Plex Discover fails', () async {
      servers
        ..add(_Client('a'))
        ..catalog = _lookup([_item('a1', MediaKind.movie, 'a')])
        ..plexHash = (_) async => throw StateError('discover down');
      expect(await servers.resolver().resolve(_movieLink), _plays('a1'));
      expect(servers.catalogQueries.single.plexGuid, isNull);
    });
  });
}
