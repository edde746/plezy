import 'package:drift/drift.dart';
import '../media/ids.dart';

import 'app_database.dart';
import '../models/download_models.dart';
import '../profiles/profile.dart';

extension DownloadDatabaseOperations on AppDatabase {
  Future<void> addDownloadOwner({required String profileId, required String globalKey}) async {
    if (profileId.isEmpty) return;
    await into(downloadOwners).insert(
      DownloadOwnersCompanion.insert(
        profileId: profileId,
        globalKey: globalKey,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeDownloadOwner({required String profileId, required String globalKey}) async {
    await (delete(downloadOwners)..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey))).go();
  }

  Future<void> clearAllDownloadOwners() async {
    await delete(downloadOwners).go();
  }

  Future<Set<String>> getDownloadOwnerKeysForProfile(String profileId) async {
    if (profileId.isEmpty) return const {};
    final rows = await (select(downloadOwners)..where((t) => t.profileId.equals(profileId))).get();
    return rows.map((row) => row.globalKey).toSet();
  }

  Future<int> getDownloadOwnerCount(String globalKey) async {
    return (await _validDownloadOwnerRows(globalKey)).length;
  }

  Future<bool> hasDownloadOwner(String globalKey, {String? excludingProfileId}) async {
    final rows = await _validDownloadOwnerRows(globalKey, excludingProfileId: excludingProfileId);
    return rows.isNotEmpty;
  }

  Future<List<DownloadOwnerItem>> _validDownloadOwnerRows(String globalKey, {String? excludingProfileId}) async {
    final rows = await (select(downloadOwners)..where((t) => t.globalKey.equals(globalKey))).get();
    if (rows.isEmpty) return const [];
    final candidates = rows
        .where((row) => excludingProfileId == null || excludingProfileId.isEmpty || row.profileId != excludingProfileId)
        .toList(growable: false);
    if (candidates.isEmpty) return const [];

    final localProfileRows = await select(profiles).get();
    final localProfileIds = localProfileRows.map((row) => row.id).toSet();
    final connectionRows = await select(connections).get();
    final connectionIds = connectionRows.map((row) => row.id).toSet();
    return candidates
        .where((row) => _isValidDownloadOwner(row, localProfileIds: localProfileIds, connectionIds: connectionIds))
        .toList(growable: false);
  }

  /// Claim pre-v17 shared download rows for [profileId]. Rows that already
  /// have any valid owner are left untouched so later profiles do not
  /// inherit them.
  ///
  /// Runs on every profile switch — validity context is computed once and
  /// applied in memory instead of the per-download full-table rescan
  /// `getDownloadOwnerCount` would do.
  Future<void> adoptLegacyDownloadsForProfile(String profileId) async {
    if (profileId.isEmpty) return;
    final rows = await select(downloadedMedia).get();
    if (rows.isEmpty) return;

    final owners = await select(downloadOwners).get();
    final localProfileIds = (await select(profiles).get()).map((row) => row.id).toSet();
    final connectionIds = (await select(connections).get()).map((row) => row.id).toSet();
    final ownedKeys = <String>{
      for (final owner in owners)
        if (_isValidDownloadOwner(owner, localProfileIds: localProfileIds, connectionIds: connectionIds))
          owner.globalKey,
    };
    for (final row in rows) {
      if (!ownedKeys.contains(row.globalKey)) {
        await addDownloadOwner(profileId: profileId, globalKey: row.globalKey);
      }
    }
  }

  Future<void> insertDownload({
    required ServerId serverId,
    String? clientScopeId,
    required String ratingKey,
    required String globalKey,
    required String type,
    String? parentRatingKey,
    String? grandparentRatingKey,
    required int status,
    int mediaIndex = 0,
    String? mediaSourceId,
  }) async {
    await into(downloadedMedia).insert(
      DownloadedMediaCompanion.insert(
        serverId: serverId,
        clientScopeId: Value(clientScopeId),
        ratingKey: ratingKey,
        globalKey: globalKey,
        type: type,
        parentRatingKey: Value(parentRatingKey),
        grandparentRatingKey: Value(grandparentRatingKey),
        status: status,
        mediaIndex: Value(mediaIndex),
        mediaSourceId: Value(mediaSourceId),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> addToQueue({
    required String mediaGlobalKey,
    int priority = 0,
    bool downloadSubtitles = true,
    bool downloadArtwork = true,
  }) async {
    await into(downloadQueue).insert(
      DownloadQueueCompanion.insert(
        mediaGlobalKey: mediaGlobalKey,
        priority: Value(priority),
        addedAt: DateTime.now().millisecondsSinceEpoch,
        downloadSubtitles: Value(downloadSubtitles),
        downloadArtwork: Value(downloadArtwork),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Get next item from queue (highest priority, oldest first)
  /// Only returns items that are not paused
  Future<DownloadQueueItem?> getNextQueueItem() async {
    final query = select(
      downloadQueue,
    ).join([innerJoin(downloadedMedia, downloadedMedia.globalKey.equalsExp(downloadQueue.mediaGlobalKey))]);

    query
      ..where(downloadedMedia.status.equals(DownloadStatus.queued.index))
      ..orderBy([
        OrderingTerm(expression: downloadQueue.priority, mode: OrderingMode.desc),
        OrderingTerm(expression: downloadQueue.addedAt),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.readTable(downloadQueue);
  }

  Future<void> updateDownloadStatus(String globalKey, int status) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(DownloadedMediaCompanion(status: Value(status)));
  }

  Future<void> updateDownloadMediaSource(String globalKey, String? mediaSourceId) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(mediaSourceId: Value(mediaSourceId)),
    );
  }

  Future<void> updateDownloadProgress(String globalKey, int progress, int downloadedBytes, int totalBytes) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(
        progress: Value(progress),
        downloadedBytes: Value(downloadedBytes),
        totalBytes: Value(totalBytes),
      ),
    );
  }

  Future<void> updateVideoFilePath(String globalKey, String filePath) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(
        videoFilePath: Value(filePath),
        downloadedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateArtworkPaths({required String globalKey, String? thumbPath}) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(DownloadedMediaCompanion(thumbPath: Value(thumbPath)));
  }

  Future<void> updateDownloadError(String globalKey, String errorMessage) async {
    final existing = await getDownloadedMedia(globalKey);
    final currentCount = existing?.retryCount ?? 0;

    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(errorMessage: Value(errorMessage), retryCount: Value(currentCount + 1)),
    );
  }

  Future<void> clearDownloadError(String globalKey) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      const DownloadedMediaCompanion(errorMessage: Value(null), retryCount: Value(0)),
    );
  }

  Future<void> removeFromQueue(String mediaGlobalKey) async {
    await (delete(downloadQueue)..where((t) => t.mediaGlobalKey.equals(mediaGlobalKey))).go();
  }

  Future<DownloadedMediaItem?> getDownloadedMedia(String globalKey) {
    return (select(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).getSingleOrNull();
  }

  Future<void> deleteDownload(String globalKey) async {
    await (delete(downloadOwners)..where((t) => t.globalKey.equals(globalKey))).go();
    await (delete(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).go();
    await (delete(downloadQueue)..where((t) => t.mediaGlobalKey.equals(globalKey))).go();
  }

  Future<List<DownloadedMediaItem>> getEpisodesBySeason(
    String seasonKey, {
    ServerId? serverId,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return (select(downloadedMedia)..where(
          (t) =>
              t.parentRatingKey.equals(seasonKey) &
              _optionalServerPredicate(t.serverId, serverIdOrNull(serverId)) &
              _optionalClientScopePredicate(t.clientScopeId, clientScopeId, filterClientScope: filterClientScope),
        ))
        .get();
  }

  Future<List<DownloadedMediaItem>> getEpisodesByShow(
    String showKey, {
    ServerId? serverId,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return (select(downloadedMedia)..where(
          (t) =>
              t.grandparentRatingKey.equals(showKey) &
              _optionalServerPredicate(t.serverId, serverIdOrNull(serverId)) &
              _optionalClientScopePredicate(t.clientScopeId, clientScopeId, filterClientScope: filterClientScope),
        ))
        .get();
  }

  /// Downloaded tracks belonging to an album (parentRatingKey). Mirrors
  /// [getEpisodesBySeason] but filters on type so an id collision with a
  /// season key can never mix media kinds.
  Future<List<DownloadedMediaItem>> getTracksByAlbum(
    String albumKey, {
    ServerId? serverId,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return (select(downloadedMedia)..where(
          (t) =>
              t.type.equals('track') &
              t.parentRatingKey.equals(albumKey) &
              _optionalServerPredicate(t.serverId, serverIdOrNull(serverId)) &
              _optionalClientScopePredicate(t.clientScopeId, clientScopeId, filterClientScope: filterClientScope),
        ))
        .get();
  }

  /// Downloaded tracks belonging to an artist (grandparentRatingKey). Mirrors
  /// [getEpisodesByShow] with the same type filter as [getTracksByAlbum].
  Future<List<DownloadedMediaItem>> getTracksByArtist(
    String artistKey, {
    ServerId? serverId,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return (select(downloadedMedia)..where(
          (t) =>
              t.type.equals('track') &
              t.grandparentRatingKey.equals(artistKey) &
              _optionalServerPredicate(t.serverId, serverIdOrNull(serverId)) &
              _optionalClientScopePredicate(t.clientScopeId, clientScopeId, filterClientScope: filterClientScope),
        ))
        .get();
  }

  Future<List<DownloadedMediaItem>> getDownloadsByServerId(ServerId serverId) {
    return (select(downloadedMedia)..where((t) => t.serverId.equals(serverId))).get();
  }

  Expression<bool> _optionalServerPredicate(GeneratedColumn<String> column, ServerId? serverId) {
    return serverId == null ? const Constant(true) : column.equals(serverId);
  }

  Expression<bool> _optionalClientScopePredicate(
    GeneratedColumn<String> column,
    String? clientScopeId, {
    required bool filterClientScope,
  }) {
    if (!filterClientScope && (clientScopeId == null || clientScopeId.isEmpty)) {
      return const Constant(true);
    }
    if (clientScopeId == null || clientScopeId.isEmpty) {
      return column.isNull() | column.equals('');
    }
    return column.equals(clientScopeId);
  }

  Future<void> updateBgTaskId(String globalKey, String? taskId) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(DownloadedMediaCompanion(bgTaskId: Value(taskId)));
  }

  Future<String?> getBgTaskId(String globalKey) async {
    final item = await getDownloadedMedia(globalKey);
    return item?.bgTaskId;
  }
}

bool _isValidDownloadOwner(
  DownloadOwnerItem owner, {
  required Set<String> localProfileIds,
  required Set<String> connectionIds,
}) {
  if (localProfileIds.contains(owner.profileId)) return true;
  final plexHome = parsePlexHomeProfileId(owner.profileId);
  if (plexHome != null) return connectionIds.contains(plexHome.accountConnectionId);
  return localProfileIds.isEmpty;
}
