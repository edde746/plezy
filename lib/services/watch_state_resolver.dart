import '../database/app_database.dart';
import '../media/media_item.dart';
import '../utils/watch_state_notifier.dart';

class WatchStateSnapshot {
  final bool? isWatched;
  final bool hasViewOffsetMs;
  final int? viewOffsetMs;

  const WatchStateSnapshot({this.isWatched, this.hasViewOffsetMs = false, this.viewOffsetMs});

  bool get isEmpty => isWatched == null && !hasViewOffsetMs;

  MediaItem apply(MediaItem item) {
    var updated = item;
    if (isWatched != null) {
      updated = updated.withWatchedFlag(isWatched!);
    }
    if (hasViewOffsetMs) {
      updated = updated.copyWith(viewOffsetMs: viewOffsetMs);
    }
    return updated;
  }
}

class WatchStateResolver {
  const WatchStateResolver._();

  static WatchStateSnapshot fromEvent(WatchStateEvent event) {
    return switch (event.changeType) {
      WatchStateChangeType.watched => const WatchStateSnapshot(isWatched: true, hasViewOffsetMs: true, viewOffsetMs: 0),
      WatchStateChangeType.unwatched => const WatchStateSnapshot(
        isWatched: false,
        hasViewOffsetMs: true,
        viewOffsetMs: 0,
      ),
      WatchStateChangeType.progressUpdate =>
        event.isNowWatched == true
            ? const WatchStateSnapshot(isWatched: true, hasViewOffsetMs: true, viewOffsetMs: 0)
            : WatchStateSnapshot(hasViewOffsetMs: event.viewOffset != null, viewOffsetMs: event.viewOffset),
      WatchStateChangeType.removedFromContinueWatching => const WatchStateSnapshot(),
    };
  }

  static WatchStateSnapshot fromActions(Iterable<OfflineWatchProgressItem> actions) {
    OfflineWatchProgressItem? latest;

    for (final action in actions) {
      if (action.actionType != 'watched' && action.actionType != 'unwatched' && action.actionType != 'progress') {
        continue;
      }
      if (latest == null || action.updatedAt > latest.updatedAt) latest = action;
    }

    return switch (latest?.actionType) {
      'watched' => const WatchStateSnapshot(isWatched: true, hasViewOffsetMs: true, viewOffsetMs: 0),
      'unwatched' => const WatchStateSnapshot(isWatched: false, hasViewOffsetMs: true, viewOffsetMs: 0),
      'progress' =>
        latest!.shouldMarkWatched
            ? const WatchStateSnapshot(isWatched: true, hasViewOffsetMs: true, viewOffsetMs: 0)
            : WatchStateSnapshot(hasViewOffsetMs: latest.viewOffset != null, viewOffsetMs: latest.viewOffset),
      _ => const WatchStateSnapshot(),
    };
  }
}
