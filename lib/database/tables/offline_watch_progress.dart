import 'package:drift/drift.dart';

/// Queue for offline watch progress and manual watch actions.
///
/// Stores watch progress updates and manual watch/unwatch actions
/// that need to be synced to the Plex server when back online.
@DataClassName('OfflineWatchProgressItem')
class OfflineWatchProgress extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Server ID this media belongs to
  TextColumn get serverId => text()();

  /// Rating key of the media item
  TextColumn get ratingKey => text()();

  /// Global key (serverId:ratingKey) for easy lookup
  TextColumn get globalKey => text()();

  /// Type of action: 'progress', 'watched', 'unwatched'
  TextColumn get actionType => text()();

  /// Current playback position in milliseconds (for 'progress' actions)
  IntColumn get viewOffset => integer().nullable()();

  /// Duration of the media in milliseconds (for calculating percentage)
  IntColumn get duration => integer().nullable()();

  /// Whether this item should be marked as watched (for progress sync)
  /// Auto-set to true when viewOffset >= 90% of duration
  BoolColumn get shouldMarkWatched =>
      boolean().withDefault(const Constant(false))();

  /// Timestamp when this action was recorded (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when this action was last updated (for merging progress updates)
  IntColumn get updatedAt => integer()();

  /// Number of sync attempts (for retry logic)
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();

  /// Last sync error message
  TextColumn get lastError => text().nullable()();
}
