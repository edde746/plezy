import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/ids.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/providers/watch_state_store.dart';
import 'package:vibe_stream/utils/watch_state_notifier.dart';

Future<void> _emit(WatchStateEvent event) async {
  WatchStateNotifier().notify(event);
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

final _episode = MediaItem(
  id: 'episode-1',
  backend: MediaBackend.jellyfin,
  kind: MediaKind.episode,
  parentId: 'season-1',
  grandparentId: 'show-1',
  serverId: 'jf-machine',
);

void main() {
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

    final season = MediaItem(
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
}
