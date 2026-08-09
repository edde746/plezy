import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../media/ids.dart';
import '../media/media_backend.dart';

import 'app_database.dart';
import '../models/download_models.dart';
import '../profiles/profile.dart';
import '../utils/active_client_scope.dart';

enum QueueDownloadOutcome {
  /// A missing or retryable row was durably admitted to the queue.
  admitted,

  /// The row was already queued; only its queue policy was refreshed.
  alreadyQueued,

  /// The existing row is active, paused, or complete and was left unchanged.
  unchanged,
}

extension DownloadDatabaseOperations on AppDatabase {
  Future<void> addDownloadOwner({
    required String profileId,
    required String globalKey,
    String? backendId,
    String? clientScopeId,
  }) async {
    if (profileId.isEmpty) return;
    await customUpdate(
      '''
      INSERT INTO download_owners (
        profile_id,
        global_key,
        backend,
        client_scope_id,
        created_at
      ) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(profile_id, global_key) DO UPDATE SET
        backend = COALESCE(excluded.backend, download_owners.backend),
        client_scope_id = COALESCE(excluded.client_scope_id, download_owners.client_scope_id)
      ''',
      variables: [
        Variable<String>(profileId),
        Variable<String>(globalKey),
        Variable<String>(backendId),
        Variable<String>(clientScopeId),
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
      ],
      updates: {downloadOwners},
    );
  }

  Future<void> removeDownloadOwner({required String profileId, required String globalKey}) {
    return transaction(() async {
      await (delete(
        syncRuleDownloads,
      )..where((t) => t.profileId.equals(profileId) & t.downloadGlobalKey.equals(globalKey))).go();
      await (delete(downloadOwners)..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey))).go();
    });
  }

  /// Removes one owner from a shared download while keeping an incomplete
  /// physical row usable by a remaining owner.
  ///
  /// When there is no remaining valid owner, nothing is removed so callers
  /// can delete the physical download before releasing its final durable
  /// owner. Selection, scope rebinding, and owner removal share a transaction.
  Future<({DownloadOwnerItem? removedOwner, bool hasRemainingOwner})>
  removeSharedDownloadOwnerAndRebindIncompleteMedia({required String profileId, required String globalKey}) {
    return transaction(() async {
      final departingOwner = await getDownloadOwner(profileId: profileId, globalKey: globalKey);
      final remainingOwners = (await _validDownloadOwnerRows(globalKey, excludingProfileId: profileId)).toList()
        ..sort((a, b) {
          final aHasScope = a.clientScopeId?.isNotEmpty ?? false;
          final bHasScope = b.clientScopeId?.isNotEmpty ?? false;
          if (aHasScope != bHasScope) return aHasScope ? -1 : 1;
          final createdAtComparison = a.createdAt.compareTo(b.createdAt);
          return createdAtComparison != 0 ? createdAtComparison : a.profileId.compareTo(b.profileId);
        });
      if (remainingOwners.isEmpty) {
        return (removedOwner: null, hasRemainingOwner: false);
      }

      if (departingOwner != null) {
        final media = await getDownloadedMedia(globalKey);
        final departingScope = departingOwner.clientScopeId;
        if (media != null &&
            media.status != DownloadStatus.completed.index &&
            departingScope != null &&
            departingScope.isNotEmpty &&
            media.clientScopeId == departingScope) {
          final replacementScope = remainingOwners.first.clientScopeId;
          if (replacementScope != media.clientScopeId) {
            await updateDownloadedMediaClientScope(globalKey, replacementScope);
          }
        }
        await removeDownloadOwner(profileId: profileId, globalKey: globalKey);
      }
      return (removedOwner: departingOwner, hasRemainingOwner: true);
    });
  }

  Future<DownloadOwnerItem?> getDownloadOwner({required String profileId, required String globalKey}) {
    return (select(
      downloadOwners,
    )..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey))).getSingleOrNull();
  }

  Future<List<DownloadOwnerItem>> getDownloadOwners(String globalKey) {
    return (select(downloadOwners)..where((t) => t.globalKey.equals(globalKey))).get();
  }

  Future<void> clearAllDownloadOwners() {
    return transaction(() async {
      await delete(syncRuleDownloads).go();
      await update(syncRules).write(const SyncRulesCompanion(downloadLinksInitialized: Value(false)));
      await delete(downloadOwners).go();
    });
  }

  Future<void> clearAllDownloadQualityDemands() async {
    await delete(downloadQualityDemands).go();
  }

  Future<void> upsertDownloadQualityDemand({
    required String profileId,
    required String globalKey,
    required String sourceKey,
    required String? qualityPreset,
  }) async {
    if (profileId.isEmpty) return;
    await into(downloadQualityDemands).insert(
      DownloadQualityDemandsCompanion.insert(
        profileId: profileId,
        globalKey: globalKey,
        sourceKey: sourceKey,
        qualityPreset: Value(qualityPreset),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<DownloadQualityDemandItem>> getDownloadQualityDemands(String globalKey) {
    return (select(downloadQualityDemands)..where((t) => t.globalKey.equals(globalKey))).get();
  }

  Future<List<DownloadQualityDemandItem>> getDownloadQualityDemandsForSource({
    required String profileId,
    required String sourceKey,
  }) {
    return (select(
      downloadQualityDemands,
    )..where((t) => t.profileId.equals(profileId) & t.sourceKey.equals(sourceKey))).get();
  }

  Future<void> removeDownloadQualityDemand({
    required String profileId,
    required String globalKey,
    required String sourceKey,
  }) async {
    await (delete(downloadQualityDemands)
          ..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey) & t.sourceKey.equals(sourceKey)))
        .go();
  }

  Future<void> removeDownloadQualityDemandsForProfileKey({required String profileId, required String globalKey}) async {
    await (delete(
      downloadQualityDemands,
    )..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey))).go();
  }

  Future<void> updateDownloadQualityDemandsForSource({
    required String profileId,
    required String sourceKey,
    required String? qualityPreset,
  }) async {
    await (update(downloadQualityDemands)..where((t) => t.profileId.equals(profileId) & t.sourceKey.equals(sourceKey)))
        .write(DownloadQualityDemandsCompanion(qualityPreset: Value(qualityPreset)));
  }

  Future<Set<String>> replaceDownloadQualityDemandsForSource({
    required String profileId,
    required String sourceKey,
    required Set<String> globalKeys,
    required String? qualityPreset,
  }) async {
    final previous = await getDownloadQualityDemandsForSource(profileId: profileId, sourceKey: sourceKey);
    final affected = <String>{...previous.map((row) => row.globalKey), ...globalKeys};
    await transaction(() async {
      await (delete(
        downloadQualityDemands,
      )..where((t) => t.profileId.equals(profileId) & t.sourceKey.equals(sourceKey))).go();
      for (final globalKey in globalKeys) {
        await upsertDownloadQualityDemand(
          profileId: profileId,
          globalKey: globalKey,
          sourceKey: sourceKey,
          qualityPreset: qualityPreset,
        );
        await removeDownloadQualityDemand(profileId: profileId, globalKey: globalKey, sourceKey: 'legacy');
      }
    });
    return affected;
  }

  Future<Set<String>> getDownloadOwnerKeysForProfile(String profileId) async {
    if (profileId.isEmpty) return const {};
    final rows = await (select(downloadOwners)..where((t) => t.profileId.equals(profileId))).get();
    return rows.map((row) => row.globalKey).toSet();
  }

  Future<List<DownloadOwnerItem>> getDownloadOwnersForProfile(String profileId) {
    if (profileId.isEmpty) return Future.value(const []);
    return (select(downloadOwners)..where((t) => t.profileId.equals(profileId))).get();
  }

  Future<void> updateDownloadOwnerScope({
    required String profileId,
    required String globalKey,
    required String backendId,
    required String clientScopeId,
  }) {
    return (update(downloadOwners)..where((t) => t.profileId.equals(profileId) & t.globalKey.equals(globalKey))).write(
      DownloadOwnersCompanion(backend: Value(backendId), clientScopeId: Value(clientScopeId)),
    );
  }

  Future<void> updateDownloadedMediaClientScope(String globalKey, String? clientScopeId) {
    return (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(clientScopeId: Value(clientScopeId)),
    );
  }

  Future<int> getDownloadOwnerCount(String globalKey) async {
    return (await _validDownloadOwnerRows(globalKey)).length;
  }

  @visibleForTesting
  Future<bool> hasDownloadOwner(String globalKey, {String? excludingProfileId}) async {
    final rows = await _validDownloadOwnerRows(globalKey, excludingProfileId: excludingProfileId);
    return rows.isNotEmpty;
  }

  Future<List<DownloadOwnerItem>> getValidDownloadOwnersForKey(String globalKey) {
    return _validDownloadOwnerRows(globalKey);
  }

  Future<bool> hasDownloadOwnerForCacheScope(
    String globalKey, {
    required String backendId,
    required String clientScopeId,
  }) async {
    final owners = await _validDownloadOwnerRows(globalKey);
    return owners.any((owner) => owner.backend == backendId && owner.clientScopeId == clientScopeId);
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
  Future<void> adoptLegacyDownloadsForProfile(String profileId, {bool Function()? isStillActive}) async {
    if (profileId.isEmpty) return;
    if (isStillActive != null && !isStillActive()) return;
    final rows = await select(downloadedMedia).get();
    if (rows.isEmpty) return;

    final owners = await select(downloadOwners).get();
    final localProfileIds = (await select(profiles).get()).map((row) => row.id).toSet();
    final connectionRows = await select(connections).get();
    final connectionIds = connectionRows.map((row) => row.id).toSet();
    final connectionKindsById = {for (final row in connectionRows) row.id: row.kind};
    final mediaBrowserIdentities = <String, ({String machineId, String? userId, String backendId})>{};
    final mediaBrowserMachineIds = <String>{};
    // `Connections.kind` is the authoritative dialect discriminator; both
    // MediaBrowser kinds use the same compound machine/user scope shape.
    for (final connection in connectionRows.where(
      (row) => row.kind == MediaBackend.jellyfin.id || row.kind == MediaBackend.emby.id,
    )) {
      final identity = _mediaBrowserConnectionIdentity(connection);
      mediaBrowserIdentities[connection.id] = (
        machineId: identity.machineId,
        userId: identity.userId,
        backendId: connection.kind,
      );
      mediaBrowserMachineIds.add(identity.machineId);
    }
    final mediaBrowserScopesByProfileAndMachine = <String, Map<String, Set<({String scopeId, String backendId})>>>{};
    for (final binding in await select(profileConnections).get()) {
      if (binding.userIdentifier.isEmpty) continue;
      final identity = mediaBrowserIdentities[binding.connectionId];
      if (identity == null || identity.userId != null && identity.userId != binding.userIdentifier) continue;
      mediaBrowserScopesByProfileAndMachine
          .putIfAbsent(binding.profileId, () => <String, Set<({String scopeId, String backendId})>>{})
          .putIfAbsent(identity.machineId, () => <({String scopeId, String backendId})>{})
          .add((scopeId: '${identity.machineId}/${binding.userIdentifier}', backendId: identity.backendId));
    }
    final ownedKeys = <String>{
      for (final owner in owners)
        if (_isValidDownloadOwner(owner, localProfileIds: localProfileIds, connectionIds: connectionIds))
          owner.globalKey,
    };
    for (final row in rows) {
      if (!ownedKeys.contains(row.globalKey)) {
        if (isStillActive != null && !isStillActive()) return;
        final scopeId = row.clientScopeId;
        final plexScope = PlexProfileScopeId.tryParse(scopeId ?? '');
        final transferScope = PlexTransferScopeId.tryParse(scopeId ?? '');
        // A scoped Plex row already identifies the Plezy profile whose token
        // and cache namespace produced it. Logout first moves preserved rows
        // through a sanitized transfer namespace so a new profile can adopt
        // the physical file without inheriting the old profile's watch state.
        if (plexScope != null && plexScope.profileId != profileId) continue;
        if (plexScope != null || transferScope != null) {
          await addDownloadOwner(
            profileId: profileId,
            globalKey: row.globalKey,
            backendId: MediaBackend.plex.id,
            clientScopeId: scopeId,
          );
          await _seedAdoptedLegacyPlexQualityDemand(profileId, row);
          continue;
        }

        final mediaBrowserScopes =
            mediaBrowserScopesByProfileAndMachine[profileId]?[row.serverId] ??
            const <({String scopeId, String backendId})>{};
        if (mediaBrowserScopes.length == 1) {
          final adopting = mediaBrowserScopes.single;
          await transaction(() async {
            if (isStillActive != null && !isStillActive()) return;
            await updateDownloadedMediaClientScope(row.globalKey, adopting.scopeId);
            await addDownloadOwner(
              profileId: profileId,
              globalKey: row.globalKey,
              backendId: adopting.backendId,
              clientScopeId: adopting.scopeId,
            );
          });
          continue;
        }

        // A compound non-Plex scope is a legacy MediaBrowser user namespace.
        // Never attach it to another profile unless that profile has exactly
        // one matching MediaBrowser binding. The same applies when persisted
        // MediaBrowser connections identify the machine but the profile has
        // zero or multiple possible users.
        final hasLegacyMediaBrowserScope = scopeId?.startsWith('${row.serverId}/') ?? false;
        if (hasLegacyMediaBrowserScope || mediaBrowserMachineIds.contains(row.serverId)) continue;

        final backendId = connectionKindsById[scopeId];
        await addDownloadOwner(
          profileId: profileId,
          globalKey: row.globalKey,
          backendId: backendId,
          clientScopeId: scopeId,
        );
        if (backendId == MediaBackend.plex.id) {
          await _seedAdoptedLegacyPlexQualityDemand(profileId, row);
        }
      }
    }
  }

  Future<void> _seedAdoptedLegacyPlexQualityDemand(String profileId, DownloadedMediaItem row) async {
    if (row.type != 'movie' && row.type != 'episode') return;
    if ((await getDownloadQualityDemands(row.globalKey)).isNotEmpty) return;
    await upsertDownloadQualityDemand(
      profileId: profileId,
      globalKey: row.globalKey,
      sourceKey: 'legacy',
      qualityPreset: null,
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

  Future<void> updateSupplementaryQueueIntent(
    String mediaGlobalKey, {
    required bool downloadSubtitles,
    required bool downloadArtwork,
  }) async {
    await (update(downloadQueue)..where((t) => t.mediaGlobalKey.equals(mediaGlobalKey))).write(
      DownloadQueueCompanion(downloadSubtitles: Value(downloadSubtitles), downloadArtwork: Value(downloadArtwork)),
    );
  }

  /// Atomically admits a durable media row and its executable queue item.
  ///
  /// Existing active, paused, and completed media rows are never rewritten.
  /// Failed, cancelled, and partial attempts keep their stable row identity
  /// and physical-file fields while their request and attempt state is refreshed.
  Future<QueueDownloadOutcome> insertQueuedDownload({
    required ServerId serverId,
    String? clientScopeId,
    required String ratingKey,
    required String globalKey,
    required String type,
    String? parentRatingKey,
    String? grandparentRatingKey,
    int mediaIndex = 0,
    String? mediaSourceId,
    String downloadQualityPreset = 'original',
    int priority = 0,
    bool downloadSubtitles = true,
    bool downloadArtwork = true,
  }) {
    return transaction(() async {
      final admitted = await customUpdate(
        '''
        INSERT INTO downloaded_media (
          server_id,
          client_scope_id,
          rating_key,
          global_key,
          type,
          parent_rating_key,
          grandparent_rating_key,
          status,
          media_index,
          media_source_id,
          download_quality_preset
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(global_key) DO UPDATE SET
          server_id = excluded.server_id,
          client_scope_id = excluded.client_scope_id,
          rating_key = excluded.rating_key,
          type = excluded.type,
          parent_rating_key = excluded.parent_rating_key,
          grandparent_rating_key = excluded.grandparent_rating_key,
          status = excluded.status,
          progress = 0,
          total_bytes = NULL,
          downloaded_bytes = 0,
          error_message = NULL,
          retry_count = 0,
          bg_task_id = NULL,
          media_index = excluded.media_index,
          media_source_id = excluded.media_source_id,
          download_quality_preset = excluded.download_quality_preset
        WHERE downloaded_media.status IN (?, ?, ?)
        ''',
        variables: [
          Variable<String>(serverId),
          Variable<String>(clientScopeId),
          Variable<String>(ratingKey),
          Variable<String>(globalKey),
          Variable<String>(type),
          Variable<String>(parentRatingKey),
          Variable<String>(grandparentRatingKey),
          Variable<int>(DownloadStatus.queued.index),
          Variable<int>(mediaIndex),
          Variable<String>(mediaSourceId),
          Variable<String>(downloadQualityPreset),
          Variable<int>(DownloadStatus.failed.index),
          Variable<int>(DownloadStatus.cancelled.index),
          Variable<int>(DownloadStatus.partial.index),
        ],
        updates: {downloadedMedia},
      );

      if (admitted > 0) {
        await addToQueue(
          mediaGlobalKey: globalKey,
          priority: priority,
          downloadSubtitles: downloadSubtitles,
          downloadArtwork: downloadArtwork,
        );
        return QueueDownloadOutcome.admitted;
      }

      final current = await getDownloadedMedia(globalKey);
      if (current?.status == DownloadStatus.queued.index) {
        await addToQueue(
          mediaGlobalKey: globalKey,
          priority: priority,
          downloadSubtitles: downloadSubtitles,
          downloadArtwork: downloadArtwork,
        );
        return QueueDownloadOutcome.alreadyQueued;
      }
      return QueueDownloadOutcome.unchanged;
    });
  }

  /// Restores queue items omitted by legacy non-atomic queue creation.
  ///
  /// Existing queue rows are never rewritten because they retain the original
  /// priority and supplementary-download policy.
  Future<int> repairMissingQueuedDownloadEntries() async {
    return transaction(() async {
      final queuedMedia = await (select(
        downloadedMedia,
      )..where((t) => t.status.equals(DownloadStatus.queued.index))).get();
      if (queuedMedia.isEmpty) return 0;

      final existingKeys = (await select(downloadQueue).get()).map((row) => row.mediaGlobalKey).toSet();
      var repaired = 0;
      for (final media in queuedMedia) {
        if (existingKeys.contains(media.globalKey)) continue;
        await addToQueue(mediaGlobalKey: media.globalKey);
        existingKeys.add(media.globalKey);
        repaired++;
      }
      return repaired;
    });
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

  /// Completed videos whose retained queue row records unsettled
  /// supplementary download intent.
  Future<List<DownloadQueueItem>> getPendingSupplementaryQueueItems() async {
    final query = select(
      downloadQueue,
    ).join([innerJoin(downloadedMedia, downloadedMedia.globalKey.equalsExp(downloadQueue.mediaGlobalKey))]);
    query
      ..where(downloadedMedia.status.equals(DownloadStatus.completed.index) & downloadedMedia.videoFilePath.isNotNull())
      ..orderBy([OrderingTerm(expression: downloadQueue.addedAt)]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(downloadQueue)).toList(growable: false);
  }

  /// Fails every queued or active download after the target filesystem fills.
  ///
  /// Clearing native task ids and queue rows prevents startup recovery from
  /// immediately re-enqueueing work after partial files have been discarded.
  Future<List<String>> failActiveDownloadsForStorageFull(String errorMessage) {
    return transaction(() async {
      final active = await (select(
        downloadedMedia,
      )..where((row) => row.status.isIn([DownloadStatus.queued.index, DownloadStatus.downloading.index]))).get();
      if (active.isEmpty) return const <String>[];

      final globalKeys = active.map((item) => item.globalKey).toList(growable: false);
      await (update(downloadedMedia)..where((row) => row.globalKey.isIn(globalKeys))).write(
        DownloadedMediaCompanion(
          status: Value(DownloadStatus.failed.index),
          bgTaskId: const Value(null),
          errorMessage: Value(errorMessage),
        ),
      );
      await (delete(downloadQueue)..where((row) => row.mediaGlobalKey.isIn(globalKeys))).go();
      return globalKeys;
    });
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

  Future<void> updateDownloadQualityPreset(String globalKey, String qualityPreset) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(downloadQualityPreset: Value(qualityPreset)),
    );
  }

  Future<void> prepareDownloadQualityReplacement(String globalKey, String qualityPreset) async {
    await (update(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).write(
      DownloadedMediaCompanion(
        status: Value(DownloadStatus.queued.index),
        progress: const Value(0),
        totalBytes: const Value(null),
        downloadedBytes: const Value(0),
        videoFilePath: const Value(null),
        downloadedAt: const Value(null),
        errorMessage: const Value(null),
        retryCount: const Value(0),
        bgTaskId: const Value(null),
        downloadQualityPreset: Value(qualityPreset),
      ),
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

  Future<void> updateDownloadSafRoot(String globalKey, String? safRootUri) async {
    await (update(
      downloadedMedia,
    )..where((t) => t.globalKey.equals(globalKey))).write(DownloadedMediaCompanion(safRootUri: Value(safRootUri)));
  }

  Future<int> countDownloadsReferencingSafRoot(String safRootUri) async {
    final count = downloadedMedia.id.count();
    final query = selectOnly(downloadedMedia)
      ..addColumns([count])
      ..where(downloadedMedia.safRootUri.equals(safRootUri));
    return (await query.map((row) => row.read(count) ?? 0).getSingle());
  }

  @visibleForTesting
  Future<Set<String>> getReferencedDownloadSafRoots() async {
    final rows =
        await (selectOnly(downloadedMedia)
              ..addColumns([downloadedMedia.safRootUri])
              ..where(downloadedMedia.safRootUri.isNotNull()))
            .map((row) => row.read(downloadedMedia.safRootUri))
            .get();
    return rows.whereType<String>().toSet();
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

  /// Removes the physical row and all dependent queue/owner state atomically,
  /// returning the row's SAF root only after the transaction commits.
  ///
  /// The caller owns persisted-grant reconciliation after this returns.
  Future<String?> deleteDownload(String globalKey) async {
    late String? safRootUri;
    await transaction(() async {
      safRootUri = (await getDownloadedMedia(globalKey))?.safRootUri;
      await (delete(syncRuleDownloads)..where((t) => t.downloadGlobalKey.equals(globalKey))).go();
      await (delete(downloadOwners)..where((t) => t.globalKey.equals(globalKey))).go();
      await (delete(downloadQualityDemands)..where((t) => t.globalKey.equals(globalKey))).go();
      await (delete(downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).go();
      await (delete(downloadQueue)..where((t) => t.mediaGlobalKey.equals(globalKey))).go();
    });
    return safRootUri;
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

({String machineId, String? userId}) _mediaBrowserConnectionIdentity(ConnectionRow connection) {
  final separator = connection.id.indexOf('/');
  var machineId = separator < 0 ? connection.id : connection.id.substring(0, separator);
  String? userId = separator < 0 || separator == connection.id.length - 1
      ? null
      : connection.id.substring(separator + 1);
  try {
    final config = jsonDecode(connection.configJson);
    if (config is Map<String, dynamic>) {
      final configuredMachineId = config['serverMachineId'];
      final configuredUserId = config['userId'];
      if (configuredMachineId is String && configuredMachineId.isNotEmpty) machineId = configuredMachineId;
      if (configuredUserId is String && configuredUserId.isNotEmpty) userId = configuredUserId;
    }
  } on FormatException {
    // Legacy rows still carry enough identity in their canonical id.
  }
  return (machineId: machineId, userId: userId);
}
