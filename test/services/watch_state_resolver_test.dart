import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/watch_state_resolver.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import '../test_helpers/media_items.dart';

OfflineWatchProgressItem _action({
  required String actionType,
  required int updatedAt,
  int? viewOffset,
  int? duration,
  bool shouldMarkWatched = false,
}) {
  return OfflineWatchProgressItem(
    id: updatedAt,
    serverId: 'srv',
    ratingKey: 'item-1',
    globalKey: 'srv:item-1',
    actionType: actionType,
    viewOffset: viewOffset,
    duration: duration,
    shouldMarkWatched: shouldMarkWatched,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    syncAttempts: 0,
  );
}

void main() {
  test('newer sub-threshold progress preserves watched state while updating resume offset', () {
    final snapshot = WatchStateResolver.fromActions([
      _action(actionType: 'watched', updatedAt: 1),
      _action(actionType: 'progress', updatedAt: 2, viewOffset: 5000, duration: 100000),
    ]);

    expect(snapshot.isWatched, isNull);
    expect(snapshot.hasViewOffsetMs, isTrue);
    expect(snapshot.viewOffsetMs, 5000);
  });

  test('newer watched action clears older progress offset', () {
    final snapshot = WatchStateResolver.fromActions([
      _action(actionType: 'progress', updatedAt: 1, viewOffset: 5000, duration: 100000),
      _action(actionType: 'watched', updatedAt: 2),
    ]);

    expect(snapshot.isWatched, isTrue);
    expect(snapshot.hasViewOffsetMs, isTrue);
    expect(snapshot.viewOffsetMs, 0);
  });

  test('sub-threshold progress events only update resume offset', () {
    final snapshot = WatchStateResolver.fromEvent(
      WatchStateEvent(
        itemId: 'item-1',
        serverId: ServerId('srv'),
        changeType: WatchStateChangeType.progressUpdate,
        parentChain: const [],
        mediaType: 'movie',
        viewOffset: 5000,
        isNowWatched: false,
      ),
    );

    expect(snapshot.isWatched, isNull);
    expect(snapshot.hasViewOffsetMs, isTrue);
    expect(snapshot.viewOffsetMs, 5000);
  });

  test('removed from continue watching is not a watch-state overlay patch', () {
    final snapshot = WatchStateResolver.fromEvent(
      WatchStateEvent(
        itemId: 'item-1',
        serverId: ServerId('srv'),
        changeType: WatchStateChangeType.removedFromContinueWatching,
        parentChain: const [],
        mediaType: 'movie',
      ),
    );

    expect(snapshot.isEmpty, isTrue);
  });

  test('applying a watched snapshot patches container leaf counts so isWatched flips', () {
    const snapshot = WatchStateSnapshot(isWatched: true, hasViewOffsetMs: true, viewOffsetMs: 0);
    final season = testMediaItem(
      id: 'season-1',
      backend: MediaBackend.plex,
      kind: MediaKind.season,
      leafCount: 8,
      viewedLeafCount: 2,
      serverId: 'srv',
    );

    final resolved = snapshot.apply(season);
    expect(resolved.viewedLeafCount, 8);
    expect(resolved.isWatched, isTrue);

    final unmarked = const WatchStateSnapshot(isWatched: false, hasViewOffsetMs: true, viewOffsetMs: 0).apply(resolved);
    expect(unmarked.viewedLeafCount, 0);
    expect(unmarked.isWatched, isFalse);
  });
}
