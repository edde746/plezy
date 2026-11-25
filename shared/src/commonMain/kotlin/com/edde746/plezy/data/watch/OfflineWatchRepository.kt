package com.edde746.plezy.data.watch

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Offline_watch_progress
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.servers.OfflineWatchAction
import com.edde746.plezy.servers.OfflineWatchActionType
import com.edde746.plezy.servers.OfflineWatchQueue
import com.edde746.plezy.servers.OfflineWatchRevision

/**
 * Watch progress and watched/unwatched marks made offline, per profile, server and client scope, replayed to their
 * servers oldest first ([pendingActions]).
 *
 * Per item (global key), profile and client scope there is at most one progress action, merged on every update
 * ([upsertProgress]); a manual mark replaces every action of the item there ([insertMark]). Replay snapshots a row's
 * revision ([OfflineWatchRevision.revision], its `updatedAt`) and settles it only while the row still has that revision
 * ([deleteIfUnchanged], [recordFailedAttemptIfUnchanged]), so an update made during replay is never lost.
 */
class OfflineWatchRepository internal constructor(private val db: Db) : OfflineWatchQueue {
    /**
     * Queues playback progress of the item, merged into the progress action already queued for it in the same profile
     * and client scope. [shouldMarkWatched]: the caller's decision that [viewOffsetMs] crossed the server's watched
     * threshold ([com.edde746.plezy.model.isWatchedProgress]).
     *
     * A merge keeps the row and moves its revision past the previous one even within one clock millisecond; its retry
     * history goes, being the failed revision's.
     */
    override suspend fun upsertProgress(
        profileId: String?,
        serverId: ServerId,
        clientScopeId: String?,
        itemId: String,
        viewOffsetMs: Long,
        durationMs: Long?,
        shouldMarkWatched: Boolean,
    ): OfflineWatchRevision {
        val globalKey = buildGlobalKey(serverId, itemId)
        return db.write {
            val now = now()
            val existing = itemActions(globalKey, profileId, clientScopeId).filter { it.action_type == OfflineWatchActionType.PROGRESS.id }
            val keep = existing.firstOrNull()
            if (keep != null) {
                val revision = maxOf(now, keep.updated_at + 1)
                q.offlineWatchQueries.updateProgress(viewOffsetMs, durationMs, shouldMarkWatched, revision, keep.id)
                val duplicates = existing.drop(1).map { it.id }
                if (duplicates.isNotEmpty()) q.offlineWatchQueries.deleteByIds(duplicates)
                return@write OfflineWatchRevision(keep.id, revision)
            }
            insert(profileId, serverId, clientScopeId, itemId, globalKey, OfflineWatchActionType.PROGRESS, viewOffsetMs, durationMs, shouldMarkWatched, now)
        }
    }

    /**
     * Queues a manual watched or unwatched mark ([type] is not [OfflineWatchActionType.PROGRESS]), replacing every
     * action queued for the item in the same profile and client scope.
     */
    override suspend fun insertMark(
        profileId: String?,
        serverId: ServerId,
        clientScopeId: String?,
        itemId: String,
        type: OfflineWatchActionType,
    ): OfflineWatchRevision {
        require(type != OfflineWatchActionType.PROGRESS) { "A mark is watched or unwatched" }
        val globalKey = buildGlobalKey(serverId, itemId)
        return db.write {
            val conflicting = itemActions(globalKey, profileId, clientScopeId).map { it.id }
            if (conflicting.isNotEmpty()) q.offlineWatchQueries.deleteByIds(conflicting)
            insert(profileId, serverId, clientScopeId, itemId, globalKey, type, null, null, false, now())
        }
    }

    /**
     * Drops the item's queued progress in the profile and client scope, leaving marks alone, and returns how many
     * went: a watched or unwatched state that reached the server directly supersedes it, and replaying it would move
     * the resume point the mark just cleared. With [beforeRevision] (settling a queued mark), only progress older than
     * that revision goes: progress as new or newer is a rewatch.
     */
    override suspend fun deleteProgress(
        profileId: String?,
        serverId: ServerId,
        clientScopeId: String?,
        itemId: String,
        beforeRevision: Long?,
    ): Int = db.write {
        val stale = itemActions(buildGlobalKey(serverId, itemId), profileId, clientScopeId)
            .filter { it.action_type == OfflineWatchActionType.PROGRESS.id && (beforeRevision == null || it.updated_at < beforeRevision) }
            .map { it.id }
        if (stale.isNotEmpty()) q.offlineWatchQueries.deleteByIds(stale)
        stale.size
    }

    /**
     * The actions of each of [globalKeys] that has any, newest revision first (then the later row), only [profileId]'s
     * when given. A key in [clientScopeIdsByGlobalKey] keeps only the actions made in its scope there (an empty scope
     * is the same as none).
     */
    override suspend fun actionsForKeys(
        globalKeys: Set<String>,
        profileId: String?,
        clientScopeIdsByGlobalKey: Map<String, String?>,
    ): Map<String, List<OfflineWatchAction>> {
        if (globalKeys.isEmpty()) return emptyMap()
        val rows = db.read { offlineWatchQueries.selectForKeys(globalKeys).executeAsList() }
        val result = LinkedHashMap<String, MutableList<OfflineWatchAction>>()
        for (row in rows) {
            if (profileId != null && row.profile_id != profileId) continue
            if (row.global_key in clientScopeIdsByGlobalKey &&
                row.client_scope_id.orNullIfEmpty() != clientScopeIdsByGlobalKey[row.global_key].orNullIfEmpty()
            ) {
                continue
            }
            result.getOrPut(row.global_key) { mutableListOf() } += row.toModel()
        }
        return result
    }

    /** [profileId]'s queued actions, oldest first: replay order. */
    override suspend fun pendingActions(profileId: String): List<OfflineWatchAction> =
        db.read { offlineWatchQueries.selectPendingForProfile(profileId).executeAsList() }.map { it.toModel() }

    /** How many actions are queued and tried fewer than [maxSyncAttempts] times, or only [profileId]'s. */
    override suspend fun pendingCount(profileId: String?, maxSyncAttempts: Int): Int = db.read {
        if (profileId == null) {
            offlineWatchQueries.countPending(maxSyncAttempts.toLong())
        } else {
            offlineWatchQueries.countPendingForProfile(profileId, maxSyncAttempts.toLong())
        }.executeAsOne().toInt()
    }

    /** Deletes the action if it still has [revision]; returns whether it did. */
    override suspend fun deleteIfUnchanged(rowId: Long, revision: Long): Boolean = db.write {
        if (q.offlineWatchQueries.selectById(rowId).executeAsOneOrNull()?.updated_at != revision) return@write false
        q.offlineWatchQueries.deleteByIds(listOf(rowId))
        true
    }

    /**
     * Counts a failed replay of the action and records [error] (null clears it), if it still has [revision]; returns
     * whether it did.
     */
    override suspend fun recordFailedAttemptIfUnchanged(rowId: Long, revision: Long, error: String?): Boolean = db.write {
        if (q.offlineWatchQueries.selectById(rowId).executeAsOneOrNull()?.updated_at != revision) return@write false
        q.offlineWatchQueries.recordSyncAttempt(error, rowId)
        true
    }

    /**
     * Gives [profileId] the actions queued before profiles existed (no profile), so watch progress made offline then
     * isn't stranded. An empty id does nothing.
     */
    override suspend fun adoptLegacyActions(profileId: String) {
        if (profileId.isEmpty()) return
        db.write { q.offlineWatchQueries.adoptLegacy(profileId) }
    }

    /** Drops a removed profile's queued actions. */
    suspend fun deleteForProfile(profileId: String) {
        db.write { q.offlineWatchQueries.deleteForProfile(profileId) }
    }

    /** Drops every queued action (a full sign-out). */
    override suspend fun clearAll() {
        db.write { q.offlineWatchQueries.deleteAll() }
    }

    /** The item's actions in the profile and client scope (nulls matching nulls), oldest row first. */
    private fun Tx.itemActions(globalKey: String, profileId: String?, clientScopeId: String?): List<Offline_watch_progress> =
        q.offlineWatchQueries.selectForItem(globalKey, profileId, clientScopeId).executeAsList()

    private fun Tx.insert(
        profileId: String?,
        serverId: ServerId,
        clientScopeId: String?,
        itemId: String,
        globalKey: String,
        type: OfflineWatchActionType,
        viewOffsetMs: Long?,
        durationMs: Long?,
        shouldMarkWatched: Boolean,
        now: Long,
    ): OfflineWatchRevision {
        q.offlineWatchQueries.insertAction(
            profileId, serverId.value, clientScopeId, itemId, globalKey, type.id, viewOffsetMs, durationMs, shouldMarkWatched, now, now,
        )
        return OfflineWatchRevision(q.offlineWatchQueries.lastInsertId().executeAsOne(), now)
    }
}

private fun String?.orNullIfEmpty(): String? = if (isNullOrEmpty()) null else this

private fun Offline_watch_progress.toModel() = OfflineWatchAction(
    rowId = id,
    profileId = profile_id,
    serverId = ServerId(server_id),
    clientScopeId = client_scope_id,
    itemId = rating_key,
    type = OfflineWatchActionType.entries.firstOrNull { it.id == action_type }
        ?: throw IllegalArgumentException("Unknown offline watch action '$action_type'"),
    viewOffsetMs = view_offset,
    durationMs = duration,
    shouldMarkWatched = should_mark_watched,
    createdAt = created_at,
    updatedAt = updated_at,
    syncAttempts = sync_attempts.toInt(),
    lastError = last_error,
)
