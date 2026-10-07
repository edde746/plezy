import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// One collection's downloaded members for a profile: the persisted form of
/// [DownloadCollections] with [memberIds] decoded, in collection order.
typedef StoredDownloadCollection = ({String serverId, String collectionId, List<String> memberIds});

/// The last membership refresh of one profile's downloads on one server.
typedef DownloadCollectionSyncState = ({int syncedAt, Set<String> checkedIds});

extension DownloadCollectionDatabaseOperations on AppDatabase {
  /// Every stored collection for [profileId]. A row whose member list does not
  /// decode is skipped; the next refresh of its server rewrites it.
  Future<List<StoredDownloadCollection>> getDownloadCollections(String profileId) async {
    if (profileId.isEmpty) return const [];
    final rows = await (select(downloadCollections)..where((t) => t.profileId.equals(profileId))).get();
    return [
      for (final row in rows)
        if (_decodeIds(row.memberIds) case final memberIds?)
          (serverId: row.serverId, collectionId: row.collectionId, memberIds: memberIds),
    ];
  }

  Future<DownloadCollectionSyncState?> getDownloadCollectionSync({
    required String profileId,
    required String serverId,
  }) async {
    final row = await (select(
      downloadCollectionSyncs,
    )..where((t) => t.profileId.equals(profileId) & t.serverId.equals(serverId))).getSingleOrNull();
    if (row == null) return null;
    final checkedIds = _decodeIds(row.checkedIds);
    if (checkedIds == null) return null;
    return (syncedAt: row.syncedAt, checkedIds: checkedIds.toSet());
  }

  /// Replace [profileId]'s stored membership on [serverId] with
  /// [membersByCollection] (collection id → member ids in collection order)
  /// and record the refresh, atomically.
  Future<void> replaceDownloadCollections({
    required String profileId,
    required String serverId,
    required Map<String, List<String>> membersByCollection,
    required Set<String> checkedIds,
    required int syncedAt,
  }) {
    return transaction(() async {
      await (delete(
        downloadCollections,
      )..where((t) => t.profileId.equals(profileId) & t.serverId.equals(serverId))).go();
      await batch((batch) {
        batch.insertAll(downloadCollections, [
          for (final entry in membersByCollection.entries)
            DownloadCollectionsCompanion.insert(
              profileId: profileId,
              serverId: serverId,
              collectionId: entry.key,
              memberIds: jsonEncode(entry.value),
            ),
        ]);
      });
      await into(downloadCollectionSyncs).insertOnConflictUpdate(
        DownloadCollectionSyncsCompanion.insert(
          profileId: profileId,
          serverId: serverId,
          syncedAt: syncedAt,
          checkedIds: jsonEncode(checkedIds.toList()..sort()),
        ),
      );
    });
  }

  /// Drop a removed profile's collection membership (profile teardown).
  Future<void> deleteDownloadCollectionsForProfile(String profileId) {
    return transaction(() async {
      await (delete(downloadCollections)..where((t) => t.profileId.equals(profileId))).go();
      await (delete(downloadCollectionSyncs)..where((t) => t.profileId.equals(profileId))).go();
    });
  }

  /// Drop every profile's collection membership (full logout).
  Future<void> clearAllDownloadCollections() {
    return transaction(() async {
      await delete(downloadCollections).go();
      await delete(downloadCollectionSyncs).go();
    });
  }
}

List<String>? _decodeIds(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return null;
    return [for (final id in decoded) id.toString()];
  } on FormatException {
    return null;
  }
}
