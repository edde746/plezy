package com.edde746.plezy.servers

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey

/** A queued offline watch action's kind; [id] is the persisted token. */
enum class OfflineWatchActionType(val id: String) {
    WATCHED("watched"),
    UNWATCHED("unwatched"),
    PROGRESS("progress"),
}

/**
 * One queued offline watch action, waiting to replay to its server.
 *
 * [profileId] is the local profile that owns it (null: queued before profiles existed). [clientScopeId] is the
 * user-scoped client namespace it replays through (a Jellyfin `"{machineId}/{userId}"`, a Plex profile scope), null
 * for the public one. [updatedAt] (epoch ms) doubles as the row's revision: every merge advances it, so a write
 * replayed from an older revision can tell the row changed meanwhile. Offsets and durations are milliseconds.
 */
data class OfflineWatchAction(
    val rowId: Long,
    val profileId: String?,
    val serverId: ServerId,
    val clientScopeId: String?,
    val itemId: String,
    val type: OfflineWatchActionType,
    val viewOffsetMs: Long? = null,
    val durationMs: Long? = null,
    /** A progress action that crossed the watched threshold. */
    val shouldMarkWatched: Boolean = false,
    val createdAt: Long,
    val updatedAt: Long,
    val syncAttempts: Int = 0,
    val lastError: String? = null,
) {
    val globalKey: String get() = buildGlobalKey(serverId, itemId)
}

/** Where an action was queued: its row and revision, and the profile and scope it was stamped with. */
data class QueuedOfflineWatchAction(val clientScopeId: String?, val profileId: String?, val rowId: Long, val revision: Long)

/** A row's id and revision after a queue write. */
data class OfflineWatchRevision(val rowId: Long, val revision: Long)

/**
 * The persisted queue of offline watch actions. "Same item" below means the same global key, profile id and client
 * scope id, nulls matching nulls. Each write is atomic.
 */
interface OfflineWatchQueue {
    /**
     * Merges into the item's single progress row, or inserts one (revision = now). A merge overwrites offset, duration,
     * [shouldMarkWatched], profile and scope, resets the attempts and error, and advances the revision to
     * `max(now, previous + 1)`; duplicate progress rows of the item are deleted.
     */
    suspend fun upsertProgress(
        profileId: String?,
        serverId: ServerId,
        clientScopeId: String?,
        itemId: String,
        viewOffsetMs: Long,
        durationMs: Long?,
        shouldMarkWatched: Boolean,
    ): OfflineWatchRevision

    /** Deletes every action of the same item (opposite mark and progress alike), then inserts [type] (revision = now). */
    suspend fun insertMark(
        profileId: String?,
        serverId: ServerId,
        clientScopeId: String?,
        itemId: String,
        type: OfflineWatchActionType,
    ): OfflineWatchRevision

    /**
     * Deletes the same item's progress rows, only those with a revision below [beforeRevision] when given. Returns how
     * many were deleted.
     */
    suspend fun deleteProgress(profileId: String?, serverId: ServerId, clientScopeId: String?, itemId: String, beforeRevision: Long?): Int

    /**
     * The actions of [globalKeys], newest revision first (then highest row id). [profileId] non-null: only that profile's
     * (a null profile id matches nothing then). A key present in [clientScopeIdsByGlobalKey] keeps only actions whose
     * scope equals the mapped one, null and empty being equal. Keys without actions are absent.
     */
    suspend fun actionsForKeys(
        globalKeys: Set<String>,
        profileId: String?,
        clientScopeIdsByGlobalKey: Map<String, String?> = emptyMap(),
    ): Map<String, List<OfflineWatchAction>>

    /** [profileId]'s actions in queue order (oldest created first). */
    suspend fun pendingActions(profileId: String): List<OfflineWatchAction>

    /** Actions below [maxSyncAttempts] attempts; only [profileId]'s when given. */
    suspend fun pendingCount(profileId: String?, maxSyncAttempts: Int): Int

    /** Deletes the row if it still has [revision]; whether it did. */
    suspend fun deleteIfUnchanged(rowId: Long, revision: Long): Boolean

    /** Counts one failed attempt with [error] if the row still has [revision]; whether it did. */
    suspend fun recordFailedAttemptIfUnchanged(rowId: Long, revision: Long, error: String?): Boolean

    /** Stamps every action without a profile with [profileId]. */
    suspend fun adoptLegacyActions(profileId: String)

    suspend fun clearAll()
}

/** A downloaded item, as the watch-state pull groups it. */
data class DownloadedWatchItem(val serverId: ServerId, val itemId: String, val kind: MediaKind, val parentId: String?) {
    val globalKey: String get() = buildGlobalKey(serverId, itemId)
}

/** What offline watch state reads from the downloads. */
interface OfflineWatchDownloads {
    /** The client scope the download of [globalKey] was made under; null when not downloaded or unscoped. */
    suspend fun downloadedClientScopeId(globalKey: String): String?

    /** The downloads [profileId] owns, after adopting downloads made before profiles existed into it. */
    suspend fun ownedDownloads(profileId: String): List<DownloadedWatchItem>

    /** A show's downloaded episodes, any order. */
    suspend fun downloadedEpisodesForShow(showGlobalKey: String): List<MediaItem>

    /** The downloaded metadata of [globalKey], parents filled; null when not downloaded. */
    suspend fun metadata(globalKey: String): MediaItem?

    /** Deletes the download of [globalKey] if it may go once watched, telling the user it went. */
    suspend fun deleteWatchedDownload(globalKey: String)
}
