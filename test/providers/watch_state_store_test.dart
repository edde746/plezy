import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/watch_state_store.dart';
import 'package:plezy/utils/favorite_state_notifier.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import '../test_helpers/media_items.dart';

Future<void> _emit(WatchStateEvent event) async {
  WatchStateNotifier().notify(event);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _emitFavorite(MediaItem item, bool favorite, {String? cacheServerId}) async {
  FavoriteStateNotifier().notifyFavorite(
    item: item,
    cacheServerId: cacheServerId ?? item.serverId ?? '',
    isFavorite: favorite,
  );
  await Future<void>.delayed(Duration.zero);
}

WatchStateEvent _event({
  required WatchStateChangeType changeType,
  required bool? isNowWatched,
  String serverId = 'jf-machine',
  String itemId = 'item-1',
  String? cacheServerId,
  int? viewOffset,
  List<String> parentChain = const [],
  String mediaType = 'movie',
}) {
  return WatchStateEvent(
    itemId: itemId,
    serverId: ServerId(serverId),
    cacheServerId: cacheServerId,
    changeType: changeType,
    parentChain: parentChain,
    mediaType: mediaType,
    isNowWatched: isNowWatched,
    viewOffset: viewOffset,
  );
}

final _episode = testMediaItem(
  id: 'episode-1',
  backend: MediaBackend.jellyfin,
  kind: MediaKind.episode,
  parentId: 'season-1',
  grandparentId: 'show-1',
  serverId: 'jf-machine',
);

void main() {
  test('favorite events patch the exact item across the session', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    final movie = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      serverId: 'jf-machine',
      isFavorite: false,
    );

    await _emitFavorite(movie, true);

    expect(store.favoriteForItem(movie), isTrue);
    expect(store.apply(movie).isFavorite, isTrue);
  });

  test('a show favorite does not leak through the episode parent chain', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    final show = testMediaItem(
      id: 'show-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.show,
      serverId: 'jf-machine',
    );

    await _emitFavorite(show, true);

    expect(store.apply(show).isFavorite, isTrue);
    expect(store.favoriteForItem(_episode), isNull);
    expect(store.apply(_episode).isFavorite, _episode.isFavorite);
  });

  test('a scoped favorite completion cannot leak into a newly active Jellyfin user', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    store
      ..setActiveProfileId('profile-b')
      ..setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-b'});
    final movie = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      serverId: 'jf-machine',
      isFavorite: false,
    );

    // Models user A's request completing after the session remounted for B.
    await _emitFavorite(movie, true, cacheServerId: 'jf-machine/user-a');

    expect(store.favoriteForItem(movie), isNull);
    expect(store.apply(movie).isFavorite, isFalse);
  });

  test('active scoped favorite lookup does not fall back to an unscoped patch', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    store.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-b'});
    final movie = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      serverId: 'jf-machine',
      isFavorite: false,
    );

    await _emitFavorite(movie, true, cacheServerId: 'jf-machine');

    expect(store.favoriteForItem(movie), isNull);
    expect(store.apply(movie).isFavorite, isFalse);
  });

  test('favorite patch reconciles when a server snapshot reaches the same state', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    final movie = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      serverId: 'jf-machine',
      isFavorite: false,
    );
    await _emitFavorite(movie, true);
    expect(store.favoriteForGlobalKey(movie.globalKey), isTrue);

    final settled = movie.copyWith(isFavorite: true);
    expect(store.apply(settled).isFavorite, isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(store.favoriteForGlobalKey(movie.globalKey), isNull);
  });

  test('favorite patch expires so a later authoritative snapshot can take over', () async {
    final store = WatchStateStore(favoritePatchLifetime: const Duration(milliseconds: 20));
    addTearDown(store.dispose);
    final movie = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      serverId: 'jf-machine',
      isFavorite: false,
    );

    await _emitFavorite(movie, true);
    expect(store.apply(movie).isFavorite, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(store.favoriteForItem(movie), isNull);
    expect(store.apply(movie).isFavorite, isFalse);
  });

  testWidgets('favorite expiry notifies an idle listener and reveals the server snapshot', (tester) async {
    var now = DateTime.utc(2026, 1, 1);
    final store = WatchStateStore(favoritePatchLifetime: const Duration(milliseconds: 20), favoriteClock: () => now);
    addTearDown(store.dispose);
    final movie = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      serverId: 'jf-machine',
      isFavorite: false,
    );
    FavoriteStateNotifier().notifyFavorite(item: movie, cacheServerId: movie.serverId!, isFavorite: true);
    await tester.pump();

    var notifications = 0;
    void listener() => notifications++;
    store.addListener(listener);
    expect(store.apply(movie).isFavorite, isTrue);

    now = now.add(const Duration(milliseconds: 21));
    await tester.pump(const Duration(milliseconds: 21));

    expect(notifications, 1);
    expect(store.apply(movie).isFavorite, isFalse);
    store.removeListener(listener);
  });

  test('removed from continue watching does not replace an existing watched patch', () async {
    final provider = WatchStateStore();
    addTearDown(provider.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true));
    await _emit(_event(changeType: WatchStateChangeType.removedFromContinueWatching, isNowWatched: null));

    final patch = provider.patchForGlobalKey('jf-machine:item-1');
    expect(patch?.isWatched, isTrue);
    expect(patch?.viewOffsetMs, 0);
  });

  test('newer unscoped patch wins over older active scoped patch', () async {
    final provider = WatchStateStore();
    addTearDown(provider.dispose);
    provider.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(
      _event(changeType: WatchStateChangeType.watched, isNowWatched: true, cacheServerId: 'jf-machine/user-a'),
    );
    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false));

    expect(provider.patchForGlobalKey('jf-machine:item-1')?.isWatched, isFalse);
  });

  test('newer active scoped patch wins over older unscoped patch', () async {
    final provider = WatchStateStore();
    addTearDown(provider.dispose);
    provider.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false));
    await _emit(
      _event(changeType: WatchStateChangeType.watched, isNowWatched: true, cacheServerId: 'jf-machine/user-a'),
    );

    expect(provider.patchForGlobalKey('jf-machine:item-1')?.isWatched, isTrue);
  });

  test('an ancestor patch reaches descendants through parentChain', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true, itemId: 'show-1'));

    expect(store.patchForItem(_episode)?.isWatched, isTrue);
    expect(store.apply(_episode).isWatched, isTrue);
    // The episode's own key still has no patch — only resolution sees the ancestor.
    expect(store.patchForGlobalKey(_episode.globalKey), isNull);
  });

  test('newer container mark overrides an older per-item patch', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false, itemId: 'episode-1'));
    await _emit(
      _event(
        changeType: WatchStateChangeType.watched,
        isNowWatched: true,
        itemId: 'season-1',
        parentChain: ['show-1'],
        mediaType: 'season',
      ),
    );

    expect(store.patchForItem(_episode)?.isWatched, isTrue);
  });

  test('newer per-item patch overrides an older container mark', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true, itemId: 'show-1'));
    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false, itemId: 'episode-1'));

    expect(store.patchForItem(_episode)?.isWatched, isFalse);
  });

  test('ancestor patches resolve through the active client scope', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    store.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(
      _event(
        changeType: WatchStateChangeType.watched,
        isNowWatched: true,
        itemId: 'show-1',
        cacheServerId: 'jf-machine/user-a',
      ),
    );

    expect(store.patchForItem(_episode)?.isWatched, isTrue);
  });

  test('applying a watched patch to a container also patches leaf counts', () async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true, itemId: 'season-1'));

    final season = testMediaItem(
      id: 'season-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.season,
      parentId: 'show-1',
      serverId: 'jf-machine',
      leafCount: 10,
      viewedLeafCount: 3,
    );
    final resolved = store.apply(season);
    expect(resolved.viewedLeafCount, 10);
    expect(resolved.isWatched, isTrue);
  });

  test('hydrated parent and item patches retain persisted freshness', () {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    store.setHydratedPatches(const [
      HydratedWatchStatePatch(
        globalKey: 'jf-machine:show-1',
        patch: WatchStatePatch(isWatched: true, hasViewOffsetMs: true, viewOffsetMs: 0),
        updatedAt: 100,
        order: 1,
      ),
      HydratedWatchStatePatch(
        globalKey: 'jf-machine:episode-1',
        patch: WatchStatePatch(isWatched: false, hasViewOffsetMs: true, viewOffsetMs: 0),
        updatedAt: 200,
        order: 2,
      ),
    ]);

    final resolved = store.apply(_episode.copyWith(viewOffsetMs: 30000));
    expect(resolved.isWatched, isFalse);
    expect(resolved.viewOffsetMs, 0);
  });

  test('hydrated patches are isolated to the active client scope', () {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    store.setHydratedPatches(const [
      HydratedWatchStatePatch(
        globalKey: 'jf-machine/user-a:show-1',
        patch: WatchStatePatch(isWatched: true),
        updatedAt: 100,
        order: 1,
      ),
      HydratedWatchStatePatch(
        globalKey: 'jf-machine/user-b:show-1',
        patch: WatchStatePatch(isWatched: false),
        updatedAt: 100,
        order: 2,
      ),
    ]);

    store.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});
    expect(store.apply(_episode).isWatched, isTrue);
    store.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-b'});
    expect(store.apply(_episode).isWatched, isFalse);
  });
}
