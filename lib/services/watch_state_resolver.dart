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
      updated = updated.copyWith(viewCount: isWatched! ? 1 : 0);
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
      WatchStateChangeType.removedFromContinueWatching => const WatchStateSnapshot(
        hasViewOffsetMs: true,
        viewOffsetMs: 0,
      ),
    };
  }

  static WatchStateSnapshot fromActions(Iterable<OfflineWatchProgressItem> actions) {
    OfflineWatchProgressItem? latestManual;
    OfflineWatchProgressItem? latestProgress;

    for (final action in actions) {
      if (action.actionType == 'watched' || action.actionType == 'unwatched') {
        if (latestManual == null || action.updatedAt > latestManual.updatedAt) latestManual = action;
      } else if (action.actionType == 'progress') {
        if (latestProgress == null || action.updatedAt > latestProgress.updatedAt) latestProgress = action;
      }
    }

    bool? isWatched;
    var hasViewOffsetMs = false;
    int? viewOffsetMs;

    final progress = latestProgress;
    final manual = latestManual;
    final progressIsNewest = progress != null && (manual == null || progress.updatedAt >= manual.updatedAt);

    if (progress != null && progress.shouldMarkWatched && progressIsNewest) {
      isWatched = true;
      hasViewOffsetMs = true;
      viewOffsetMs = 0;
    } else if (manual != null) {
      isWatched = manual.actionType == 'watched';
      hasViewOffsetMs = true;
      viewOffsetMs = 0;
    }

    if (progress != null && !progress.shouldMarkWatched && progressIsNewest) {
      hasViewOffsetMs = true;
      viewOffsetMs = progress.viewOffset;
    }

    return WatchStateSnapshot(isWatched: isWatched, hasViewOffsetMs: hasViewOffsetMs, viewOffsetMs: viewOffsetMs);
  }
}
