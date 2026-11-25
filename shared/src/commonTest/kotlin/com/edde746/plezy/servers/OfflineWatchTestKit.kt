package com.edde746.plezy.servers

import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import kotlin.time.Duration
import kotlinx.coroutines.flow.MutableStateFlow

/** The queue contract of [OfflineWatchQueue] in memory; every write is one clock millisecond later than the last. */
internal class InMemoryOfflineWatchQueue : OfflineWatchQueue {
    val rows = mutableListOf<OfflineWatchAction>()
    private var nextRowId = 1L
    private var clockMs = 1_000L

    private fun now(): Long = ++clockMs

    private fun OfflineWatchAction.isSameItem(profileId: String?, globalKey: String, clientScopeId: String?) =
        this.globalKey == globalKey && this.profileId == profileId && this.clientScopeId == clientScopeId

    fun latest(globalKey: String): OfflineWatchAction? =
        rows.filter { it.globalKey == globalKey }.maxWithOrNull(compareBy<OfflineWatchAction> { it.updatedAt }.thenBy { it.rowId })

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
        val now = now()
        val existing = rows.filter { it.isSameItem(profileId, globalKey, clientScopeId) && it.type == OfflineWatchActionType.PROGRESS }.sortedBy { it.rowId }
        val keep = existing.firstOrNull()
        if (keep != null) {
            val revision = maxOf(now, keep.updatedAt + 1)
            rows.removeAll { row -> existing.any { it.rowId == row.rowId } }
            rows += keep.copy(
                viewOffsetMs = viewOffsetMs,
                durationMs = durationMs,
                shouldMarkWatched = shouldMarkWatched,
                updatedAt = revision,
                syncAttempts = 0,
                lastError = null,
            )
            return OfflineWatchRevision(keep.rowId, revision)
        }
        val row = OfflineWatchAction(
            rowId = nextRowId++,
            profileId = profileId,
            serverId = serverId,
            clientScopeId = clientScopeId,
            itemId = itemId,
            type = OfflineWatchActionType.PROGRESS,
            viewOffsetMs = viewOffsetMs,
            durationMs = durationMs,
            shouldMarkWatched = shouldMarkWatched,
            createdAt = now,
            updatedAt = now,
        )
        rows += row
        return OfflineWatchRevision(row.rowId, now)
    }

    override suspend fun insertMark(
        profileId: String?,
        serverId: ServerId,
        clientScopeId: String?,
        itemId: String,
        type: OfflineWatchActionType,
    ): OfflineWatchRevision {
        val globalKey = buildGlobalKey(serverId, itemId)
        val now = now()
        rows.removeAll { it.isSameItem(profileId, globalKey, clientScopeId) }
        val row = OfflineWatchAction(
            rowId = nextRowId++,
            profileId = profileId,
            serverId = serverId,
            clientScopeId = clientScopeId,
            itemId = itemId,
            type = type,
            createdAt = now,
            updatedAt = now,
        )
        rows += row
        return OfflineWatchRevision(row.rowId, now)
    }

    override suspend fun deleteProgress(profileId: String?, serverId: ServerId, clientScopeId: String?, itemId: String, beforeRevision: Long?): Int {
        val globalKey = buildGlobalKey(serverId, itemId)
        val before = rows.size
        rows.removeAll {
            it.isSameItem(profileId, globalKey, clientScopeId) && it.type == OfflineWatchActionType.PROGRESS &&
                (beforeRevision == null || it.updatedAt < beforeRevision)
        }
        return before - rows.size
    }

    override suspend fun actionsForKeys(
        globalKeys: Set<String>,
        profileId: String?,
        clientScopeIdsByGlobalKey: Map<String, String?>,
    ): Map<String, List<OfflineWatchAction>> = rows
        .filter { it.globalKey in globalKeys && (profileId == null || it.profileId == profileId) }
        .filter { row ->
            if (row.globalKey !in clientScopeIdsByGlobalKey) return@filter true
            row.clientScopeId?.takeIf { it.isNotEmpty() } == clientScopeIdsByGlobalKey[row.globalKey]?.takeIf { it.isNotEmpty() }
        }
        .sortedWith(compareByDescending<OfflineWatchAction> { it.updatedAt }.thenByDescending { it.rowId })
        .groupBy { it.globalKey }

    override suspend fun pendingActions(profileId: String): List<OfflineWatchAction> =
        rows.filter { it.profileId == profileId }.sortedWith(compareBy<OfflineWatchAction> { it.createdAt }.thenBy { it.rowId })

    override suspend fun pendingCount(profileId: String?, maxSyncAttempts: Int): Int =
        rows.count { (profileId == null || it.profileId == profileId) && it.syncAttempts < maxSyncAttempts }

    override suspend fun deleteIfUnchanged(rowId: Long, revision: Long): Boolean = rows.removeAll { it.rowId == rowId && it.updatedAt == revision }

    override suspend fun recordFailedAttemptIfUnchanged(rowId: Long, revision: Long, error: String?): Boolean {
        val index = rows.indexOfFirst { it.rowId == rowId && it.updatedAt == revision }
        if (index < 0) return false
        rows[index] = rows[index].copy(syncAttempts = rows[index].syncAttempts + 1, lastError = error)
        return true
    }

    override suspend fun adoptLegacyActions(profileId: String) {
        for (i in rows.indices) if (rows[i].profileId == null) rows[i] = rows[i].copy(profileId = profileId)
    }

    override suspend fun clearAll() {
        rows.clear()
    }
}

internal class FakeOfflineWatchDownloads : OfflineWatchDownloads {
    val clientScopes = mutableMapOf<String, String>()
    val owned = mutableMapOf<String, MutableList<DownloadedWatchItem>>()
    val episodesByShow = mutableMapOf<String, List<MediaItem>>()
    val metadataByKey = mutableMapOf<String, MediaItem>()
    val removable = mutableSetOf<String>()
    val deleted = mutableListOf<String>()

    fun own(profileId: String, item: DownloadedWatchItem) {
        owned.getOrPut(profileId) { mutableListOf() } += item
    }

    override suspend fun downloadedClientScopeId(globalKey: String): String? = clientScopes[globalKey]
    override suspend fun ownedDownloads(profileId: String): List<DownloadedWatchItem> = owned[profileId].orEmpty()
    override suspend fun downloadedEpisodesForShow(showGlobalKey: String): List<MediaItem> = episodesByShow[showGlobalKey].orEmpty()
    override suspend fun metadata(globalKey: String): MediaItem? = metadataByKey[globalKey]
    override suspend fun deleteWatchedDownload(globalKey: String) {
        if (removable.remove(globalKey)) deleted += globalKey
    }
}

/** Bound clients: the last one registered for a server is its active client; each client is online on its own. */
internal class FakeWatchClients : WatchClients {
    private val registered = mutableListOf<MediaBackend>()
    private val offlineScopes = mutableSetOf<String>()

    fun register(client: MediaBackend, online: Boolean = true) {
        registered.remove(client)
        registered += client
        if (online) offlineScopes.remove(client.cacheServerId) else offlineScopes += client.cacheServerId
    }

    override fun client(serverId: ServerId): MediaBackend? = registered.lastOrNull { it.serverId == serverId }
    override fun clientByScope(clientScopeId: String): MediaBackend? = registered.lastOrNull { it.cacheServerId == clientScopeId }
    override val onlineClients: Map<ServerId, MediaBackend>
        get() = registered.filter { it.cacheServerId !in offlineScopes }.associateBy { it.serverId }

    override fun isClientOnline(serverId: ServerId, clientScopeId: String?): Boolean {
        val client = if (clientScopeId.isNullOrEmpty()) client(serverId) else clientByScope(clientScopeId)
        return client != null && client.cacheServerId !in offlineScopes
    }
}

internal class ToggleOfflineMode(offline: Boolean = false) : OfflineModeSource {
    override val isOffline = MutableStateFlow(offline)
}

/** Records every mark, the active profile's and each profile's ([forProfile]) alike. */
internal class RecordingTrackers : TrackerWatchMarks, ProfileTrackerWatchMarks {
    val marks = mutableListOf<Pair<String, Boolean>>()
    override suspend fun mark(item: MediaItem, client: MediaBackend, watched: Boolean) {
        marks += item.id to watched
    }

    override fun forProfile(profileId: String): TrackerWatchMarks = this
}

internal class FakeBackendCache : BackendCache {
    val metadata = mutableMapOf<String, MediaItem>()
    val applied = mutableListOf<String>()
    override val store: ApiCacheStore get() = throw AssertionError("FakeBackendCache.store")
    override suspend fun getMetadata(cacheServerId: String, itemId: String): MediaItem? = metadata["$cacheServerId|$itemId"]
    override suspend fun pinForOffline(cacheServerId: String, itemId: String) = throw AssertionError("pinForOffline")
    override suspend fun deleteForItem(cacheServerId: String, itemId: String) = throw AssertionError("deleteForItem")
    override suspend fun applyWatchState(cacheServerId: String, itemId: String, isWatched: Boolean, viewOffsetMs: Long?, lastViewedAt: Long?, viewedLeafCount: Int?) {
        applied += "$cacheServerId|$itemId|$isWatched"
    }
    override suspend fun getAllPinnedMetadata(cacheServerIds: Set<String>?): Map<String, MediaItem> = throw AssertionError("getAllPinnedMetadata")
}

/**
 * A client that records what replays write: started and stopped reports, explicit marks. Jellyfin marks played from
 * the stopped report; Plex needs the explicit mark.
 */
internal class RecordingBackend(serverId: String, backend: BackendKind, scopeId: String? = null) : FakeMediaBackend(serverId, backend, scopeId = scopeId) {
    data class Report(val itemId: String, val positionMs: Long, val durationMs: Long?, val report: PlaybackReportMetadata? = null)

    val started = mutableListOf<Report>()
    val stopped = mutableListOf<Report>()
    val watched = mutableListOf<String>()
    val unwatched = mutableListOf<String>()

    init {
        marksWatchedOnPlaybackStopped = backend == BackendKind.JELLYFIN
        items = { id -> MediaItem(id = id, backend = backend, kind = MediaKind.MOVIE, serverId = serverId) }
        markWatchedHandler = { watched += it.id }
        markUnwatchedHandler = { unwatched += it.id }
        playbackStartedHandler = { id, position, duration -> started += Report(id, position.inWholeMilliseconds, duration?.inWholeMilliseconds) }
        playbackStoppedHandler = { id, position, duration: Duration?, report -> stopped += Report(id, position.inWholeMilliseconds, duration?.inWholeMilliseconds, report) }
        cacheHandle = FakeBackendCache()
    }
}
