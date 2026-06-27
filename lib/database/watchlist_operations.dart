import 'package:drift/drift.dart';

import 'app_database.dart';

extension WatchlistDatabaseOperations on AppDatabase {
  /// Streams all watchlist items for [profileId], emitting on every change.
  Stream<List<WatchlistItem>> watchWatchlist(String profileId) {
    return (select(watchlistItems)..where((t) => t.profileId.equals(profileId))).watch();
  }

  /// Toggles the bookmark for the given composite key: inserts if not
  /// present, deletes if present. Returns `true` when the item was added
  /// and `false` when it was removed.
  Future<bool> toggleBookmark({
    required String profileId,
    required String serverId,
    String? clientScopeId,
    required String ratingKey,
    required String globalKey,
    required String kind,
    required String title,
    String? thumbPath,
    String? backdropPath,
    int? year,
    int? index,
    String? parentTitle,
  }) async {
    final exists = await isBookmarked(profileId, globalKey);
    if (exists) {
      await (delete(watchlistItems)..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey))).go();
      return false;
    }

    await into(watchlistItems).insert(
      WatchlistItemsCompanion.insert(
        profileId: profileId,
        globalKey: globalKey,
        serverId: serverId,
        clientScopeId: Value(clientScopeId),
        ratingKey: ratingKey,
        kind: kind,
        title: title,
        thumbPath: Value(thumbPath),
        backdropPath: Value(backdropPath),
        year: Value(year),
        index: Value(index),
        parentTitle: Value(parentTitle),
        addedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      onConflict: DoUpdate(
        (_) => WatchlistItemsCompanion(
          serverId: Value(serverId),
          clientScopeId: Value(clientScopeId),
          ratingKey: Value(ratingKey),
          kind: Value(kind),
          title: Value(title),
          thumbPath: Value(thumbPath),
          backdropPath: Value(backdropPath),
          year: Value(year),
          index: Value(index),
          parentTitle: Value(parentTitle),
          addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      ),
    );
    return true;
  }

  /// Returns whether a row exists for the given profile + global key pair.
  Future<bool> isBookmarked(String profileId, String globalKey) async {
    final rows = await (select(watchlistItems)
          ..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey)))
        .get();
    return rows.isNotEmpty;
  }

  /// Deletes all watchlist rows for [profileId].
  Future<void> clearAll(String profileId) async {
    await (delete(watchlistItems)..where((t) => t.profileId.equals(profileId))).go();
  }
}
