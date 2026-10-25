import '../media/media_item.dart';
import 'watch_actions.dart';

class BulkWatchResult {
  final int succeeded;
  final List<MediaItem> failed;
  final bool cancelled;

  const BulkWatchResult({required this.succeeded, required this.failed, required this.cancelled});
}

/// Serial execution avoids flooding the backend and preserves per-item watch
/// notifications and tracker behavior. Failed/skipped items are never retried
/// automatically. The owner checks its captured library/authentication session
/// before each dispatch and after each response.
Future<BulkWatchResult> markBulkWatched(
  List<MediaItem> items, {
  required Future<WatchMarkOutcome> Function(MediaItem) mark,
  required bool Function() isCurrent,
  required void Function(MediaItem, int completed) onSuccess,
}) async {
  var succeeded = 0;
  final failed = <MediaItem>[];
  for (final item in items) {
    if (!isCurrent()) return BulkWatchResult(succeeded: succeeded, failed: failed, cancelled: true);
    WatchMarkOutcome? outcome;
    try {
      outcome = await mark(item);
    } catch (_) {
      // The UI reports counts, never raw server responses or credentials.
    }
    if (!isCurrent()) return BulkWatchResult(succeeded: succeeded, failed: failed, cancelled: true);
    if (outcome == WatchMarkOutcome.marked) {
      succeeded++;
      onSuccess(item, succeeded + failed.length);
    } else {
      failed.add(item);
    }
  }
  return BulkWatchResult(succeeded: succeeded, failed: failed, cancelled: false);
}
