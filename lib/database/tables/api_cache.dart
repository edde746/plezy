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
