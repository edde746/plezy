import 'package:drift/drift.dart';

/// Key-value cache table for Plex API responses.
/// Used for offline support - stores raw JSON responses.
class ApiCache extends Table {
  /// Composite key: serverId:endpoint (e.g., "abc123:/library/metadata/12345")
  TextColumn get cacheKey => text()();

  /// JSON response data
  TextColumn get data => text()();

  /// Whether this item is pinned for offline access
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  /// Timestamp for cache invalidation (optional future use)
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

@DataClassName('DownloadQueueItem')
class DownloadQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mediaGlobalKey => text().unique()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get addedAt => integer()();
  BoolColumn get downloadSubtitles =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get downloadArtwork =>
      boolean().withDefault(const Constant(true))();
}

@DataClassName('DownloadedMediaItem')
class DownloadedMedia extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text()();
  TextColumn get ratingKey => text()();
  TextColumn get globalKey => text().unique()();
  TextColumn get type => text()();
  TextColumn get parentRatingKey => text().nullable()();
  TextColumn get grandparentRatingKey => text().nullable()();
  IntColumn get status => integer()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get videoFilePath => text().nullable()();
  TextColumn get thumbPath => text().nullable()();
  IntColumn get downloadedAt => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

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
