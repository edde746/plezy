import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/ids.dart';
import 'package:vibe_stream/providers/watch_state_overlay_provider.dart';
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
}) {
  return WatchStateEvent(
    itemId: itemId,
    serverId: ServerId(serverId),
    cacheServerId: cacheServerId,
    changeType: changeType,
    parentChain: const [],
    mediaType: 'movie',
    isNowWatched: isNowWatched,
    viewOffset: viewOffset,
  );
}

void main() {
  test('removed from continue watching does not replace an existing watched patch', () async {
    final provider = WatchStateOverlayProvider();
    addTearDown(provider.dispose);

    await _emit(_event(changeType: WatchStateChangeType.watched, isNowWatched: true));
    await _emit(_event(changeType: WatchStateChangeType.removedFromContinueWatching, isNowWatched: null));

    final patch = provider.patchForGlobalKey('jf-machine:item-1');
    expect(patch?.isWatched, isTrue);
    expect(patch?.viewOffsetMs, 0);
  });

  test('newer unscoped patch wins over older active scoped patch', () async {
    final provider = WatchStateOverlayProvider();
    addTearDown(provider.dispose);
    provider.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(
      _event(changeType: WatchStateChangeType.watched, isNowWatched: true, cacheServerId: 'jf-machine/user-a'),
    );
    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false));

    expect(provider.patchForGlobalKey('jf-machine:item-1')?.isWatched, isFalse);
  });

  test('newer active scoped patch wins over older unscoped patch', () async {
    final provider = WatchStateOverlayProvider();
    addTearDown(provider.dispose);
    provider.setActiveClientScopesByServer({'jf-machine': 'jf-machine/user-a'});

    await _emit(_event(changeType: WatchStateChangeType.unwatched, isNowWatched: false));
    await _emit(
      _event(changeType: WatchStateChangeType.watched, isNowWatched: true, cacheServerId: 'jf-machine/user-a'),
    );

    expect(provider.patchForGlobalKey('jf-machine:item-1')?.isWatched, isTrue);
  });
}
