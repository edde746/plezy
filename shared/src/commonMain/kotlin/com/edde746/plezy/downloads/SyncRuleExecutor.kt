package com.edde746.plezy.downloads

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.SyncRule
import com.edde746.plezy.data.downloads.SyncRuleFilter
import com.edde746.plezy.data.downloads.SyncRuleRepository
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.collectEpisodes
import com.edde746.plezy.model.collectListLeaves
import com.edde746.plezy.model.drainPages
import com.edde746.plezy.servers.Connectivity
import com.edde746.plezy.servers.OfflineWatchActionType
import com.edde746.plezy.servers.OfflineWatchQueue
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.sync.Mutex
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes

/** Records that [rule] covers the existing download of a global key. */
typealias AssociateSyncRuleDownload = suspend (rule: SyncRule, downloadGlobalKey: String) -> Unit

/** Queues and records a missing download of version [mediaIndex] at [quality]; whether a queue entry was created. */
typealias QueueSyncRuleDownload = suspend (item: MediaItem, client: MediaBackend, mediaIndex: Int, quality: TranscodeQualityPreset) -> Boolean

/** What one rule run queued: [queuedCount] downloads for the rule [globalKey], titled [title] when known. */
data class SyncRuleResult(val globalKey: String, val title: String?, val queuedCount: Int)

/** The servers a rule runs against: [client] is the active client of a server, [isServerOnline] its reachability. */
interface SyncRuleServers {
    fun client(serverId: ServerId): MediaBackend?

    fun isServerOnline(serverId: ServerId): Boolean
}

/**
 * Evaluates sync rules and queues downloads so the device matches each rule's target.
 *
 * Show and season rules keep N unwatched episodes queued (0 = every unwatched one). Collection and playlist rules mirror
 * the list's current contents, shows and seasons expanded to episodes, filtered by the rule's download filter.
 *
 * [connectivity] is read once per full run, for the Wi-Fi-only gate ([cellularBlocked]) and the cooldown pick. [clock]
 * is epoch milliseconds.
 */
class SyncRuleExecutor(
    private val rules: SyncRuleRepository,
    private val watchQueue: OfflineWatchQueue,
    private val connectivity: suspend () -> Connectivity,
    private val cellularBlocked: suspend (Connectivity) -> Boolean,
    private val ordering: () -> SpecialsOrdering,
    private val clock: () -> Long,
) {
    private val executing = Mutex()

    /** Per profile: one profile's background pass must not use up another profile's cooldown after a switch. */
    private val lastFullRunAtByProfile = mutableMapOf<String, Long>()

    val isExecuting: Boolean get() = executing.isLocked

    /**
     * Runs every enabled rule of [profileId]. The cooldown (30 min on Wi-Fi or Ethernet, 3 h on cellular) applies to
     * background passes only; user-initiated runs (a watch event, an offline-queue drain) pass [force] to bypass it.
     * [downloads] maps download global keys to their status. Only results that queued something are returned.
     */
    suspend fun executeSyncRules(
        profileId: String,
        servers: SyncRuleServers,
        downloads: Map<String, DownloadedMediaStatus>,
        metadata: Map<String, MediaItem>,
        associateDownload: AssociateSyncRuleDownload,
        queueSingleDownload: QueueSyncRuleDownload,
        isOffline: Boolean,
        force: Boolean = false,
    ): List<SyncRuleResult> {
        if (executing.isLocked || isOffline) return emptyList()
        val links = connectivity()
        if (cellularBlocked(links)) {
            Log.d(TAG) { "Skipping sync rules: cellular download blocked" }
            return emptyList()
        }
        val lastFullRunAt = lastFullRunAtByProfile[profileId]
        if (!force && lastFullRunAt != null) {
            val cooldown = if (links.hasWifiOrEthernet) COOLDOWN_WIFI else COOLDOWN_CELLULAR
            if ((clock() - lastFullRunAt).milliseconds < cooldown) return emptyList()
        }
        if (!executing.tryLock()) return emptyList()
        try {
            val all = rules.rules(profileId)
            if (all.isEmpty()) return emptyList()
            val results = mutableListOf<SyncRuleResult>()
            for (rule in all) {
                if (!rule.enabled) continue
                try {
                    val result = executeRule(rule, servers, downloads, metadata, associateDownload, queueSingleDownload)
                    if (result != null && result.queuedCount > 0) results += result
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "Failed to execute sync rule ${rule.globalKey}" }
                }
            }
            lastFullRunAtByProfile[profileId] = clock()
            return results
        } finally {
            executing.unlock()
        }
    }

    /** Runs one rule (the eager run after adding to a list); not throttled by the cooldown. */
    suspend fun executeSingleRule(
        profileId: String,
        globalKey: String,
        servers: SyncRuleServers,
        downloads: Map<String, DownloadedMediaStatus>,
        metadata: Map<String, MediaItem>,
        associateDownload: AssociateSyncRuleDownload,
        queueSingleDownload: QueueSyncRuleDownload,
        isOffline: Boolean,
    ): SyncRuleResult? {
        if (executing.isLocked || isOffline) return null
        if (cellularBlocked(connectivity())) return null
        val rule = rules.rule(globalKey)
        if (rule == null || !rule.enabled || rule.profileId != profileId) return null
        if (!executing.tryLock()) return null
        return try {
            executeRule(rule, servers, downloads, metadata, associateDownload, queueSingleDownload)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to execute single sync rule $globalKey" }
            null
        } finally {
            executing.unlock()
        }
    }

    /**
     * Records which existing downloads a list rule from before download links covers, queueing nothing. False when the
     * rule is not a list rule, its server is unavailable, or the list cannot be read.
     */
    suspend fun backfillListRuleDownloadLinks(
        rule: SyncRule,
        servers: SyncRuleServers,
        downloads: Map<String, DownloadedMediaStatus>,
        metadata: Map<String, MediaItem>,
        associateDownload: AssociateSyncRuleDownload,
    ): Boolean {
        if (rule.target != SyncRuleTarget.COLLECTION && rule.target != SyncRuleTarget.PLAYLIST) return false
        val serverId = ServerId(rule.serverId)
        val client = servers.client(serverId)?.takeIf { servers.isServerOnline(serverId) } ?: return false
        if (!executing.tryLock()) return false
        return try {
            for (item in resolveListRuleItems(rule, client, metadata)) {
                val key = buildGlobalKey(serverId, item.id)
                if (isActiveDownload(downloads[key])) associateDownload(rule, key)
            }
            rules.completeExecution(rule.globalKey)
            true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to backfill sync rule ${rule.globalKey}" }
            false
        } finally {
            executing.unlock()
        }
    }

    private suspend fun executeRule(
        rule: SyncRule,
        servers: SyncRuleServers,
        downloads: Map<String, DownloadedMediaStatus>,
        metadata: Map<String, MediaItem>,
        associateDownload: AssociateSyncRuleDownload,
        queueSingleDownload: QueueSyncRuleDownload,
    ): SyncRuleResult? {
        val serverId = ServerId(rule.serverId)
        val client = servers.client(serverId)?.takeIf { servers.isServerOnline(serverId) } ?: return null
        // Rules made without the target's metadata fetch its title once, so the result is not untitled.
        var resolved = metadata
        if (metadata[rule.globalKey]?.title == null) {
            try {
                client.fetchItem(rule.ratingKey)?.let { resolved = metadata + (rule.globalKey to it) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Sync rule ${rule.globalKey}: title fetch failed" }
            }
        }
        val scope = client.cacheServerId.takeUnless { it == serverId.value || it.isEmpty() }
        return when (rule.target) {
            SyncRuleTarget.SHOW, SyncRuleTarget.SEASON ->
                executeEpisodeRule(rule, client, scope, downloads, resolved, associateDownload, queueSingleDownload)
            SyncRuleTarget.COLLECTION, SyncRuleTarget.PLAYLIST ->
                executeListRule(rule, client, scope, downloads, resolved, associateDownload, queueSingleDownload)
        }
    }

    /** Keeps the rule's episode count of unwatched episodes queued (0 = all). */
    private suspend fun executeEpisodeRule(
        rule: SyncRule,
        client: MediaBackend,
        clientScopeId: String?,
        downloads: Map<String, DownloadedMediaStatus>,
        metadata: Map<String, MediaItem>,
        associateDownload: AssociateSyncRuleDownload,
        queueSingleDownload: QueueSyncRuleDownload,
    ): SyncRuleResult? {
        val serverId = ServerId(rule.serverId)
        val fromServer = collectEpisodes(
            client,
            rule.ratingKey,
            unwatchedOnly = true,
            ordering = ordering(),
            fallback = metadata[rule.globalKey],
            includeSpecials = rule.target != SyncRuleTarget.SHOW || rule.includeSpecials,
        )
        val unwatched = excludeLocallyWatched(fromServer, serverId, rule.profileId, clientScopeId)
        if (unwatched.isEmpty()) {
            rules.completeExecution(rule.globalKey)
            return null
        }
        var alreadyHave = 0
        for (episode in unwatched) {
            val key = buildGlobalKey(serverId, episode.id)
            if (isActiveDownload(downloads[key])) {
                alreadyHave++
                associateDownload(rule, key)
            }
        }
        val target = if (rule.episodeCount > 0) rule.episodeCount else unwatched.size
        val deficit = target - alreadyHave
        if (deficit <= 0) {
            rules.completeExecution(rule.globalKey)
            return null
        }
        var queued = 0
        for (episode in unwatched) {
            if (queued >= deficit) break
            val key = buildGlobalKey(serverId, episode.id)
            if (isActiveDownload(downloads[key])) continue
            val withServer = if (episode.serverId != null) episode else episode.copy(serverId = rule.serverId)
            val ok = queueSingleDownload(withServer, client, rule.mediaIndex, rule.transcodeQuality)
            associateDownload(rule, key)
            if (ok) queued++
        }
        rules.completeExecution(rule.globalKey)
        return SyncRuleResult(rule.globalKey, metadata[rule.globalKey]?.title, queued)
    }

    /** Mirrors a collection or playlist: every member not yet downloaded is queued, no cap; media index 0. */
    private suspend fun executeListRule(
        rule: SyncRule,
        client: MediaBackend,
        clientScopeId: String?,
        downloads: Map<String, DownloadedMediaStatus>,
        metadata: Map<String, MediaItem>,
        associateDownload: AssociateSyncRuleDownload,
        queueSingleDownload: QueueSyncRuleDownload,
    ): SyncRuleResult? {
        val serverId = ServerId(rule.serverId)
        val membership = try {
            resolveListRuleItems(rule, client, metadata)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Sync rule ${rule.globalKey}: failed to fetch list items" }
            return null
        }
        for (item in membership) {
            val key = buildGlobalKey(serverId, item.id)
            if (isActiveDownload(downloads[key])) associateDownload(rule, key)
        }
        val candidates = if (rule.downloadFilter == SyncRuleFilter.UNWATCHED) {
            excludeLocallyWatched(membership.filter { it.isUnwatchedOrInProgress }, serverId, rule.profileId, clientScopeId)
        } else {
            membership
        }
        var queued = 0
        for (item in candidates) {
            val key = buildGlobalKey(serverId, item.id)
            if (isActiveDownload(downloads[key])) continue
            val withServer = if (item.serverId != null) item else item.copy(serverId = rule.serverId)
            val ok = queueSingleDownload(withServer, client, 0, TranscodeQualityPreset.ORIGINAL)
            associateDownload(rule, key)
            if (ok) queued++
        }
        rules.completeExecution(rule.globalKey)
        return SyncRuleResult(rule.globalKey, metadata[rule.globalKey]?.title, queued)
    }

    /**
     * Every playable member of the rule's list, watched ones included: the unwatched filter applies to queueing only,
     * and watched downloads still belong to the list for cleanup.
     */
    private suspend fun resolveListRuleItems(rule: SyncRule, client: MediaBackend, metadata: Map<String, MediaItem>): List<MediaItem> {
        val roots = if (rule.target == SyncRuleTarget.COLLECTION) {
            val source = metadata[rule.globalKey]
            drainPages(COLLECTION_PAGE_SIZE, stopOnShortPage = true) { start, size ->
                client.fetchCollectionPage(rule.ratingKey, start, size, source?.libraryId, source?.libraryTitle)
            }
        } else {
            drainPages(PLAYLIST_PAGE_SIZE) { start, size -> client.fetchPlaylistPage(rule.ratingKey, start, size) }
        }
        if (roots.isEmpty()) return emptyList()
        return collectListLeaves(client, roots, unwatchedOnly = false, ordering = ordering())
    }

    /**
     * Drops items the profile marked watched here: the server still reports them unwatched until the offline queue
     * replays, and without this a rule would queue again an episode just marked watched.
     */
    private suspend fun excludeLocallyWatched(
        items: List<MediaItem>,
        serverId: ServerId,
        profileId: String,
        clientScopeId: String?,
    ): List<MediaItem> {
        if (items.isEmpty()) return items
        val keys = items.mapTo(mutableSetOf()) { buildGlobalKey(serverId, it.id) }
        val actions = watchQueue.actionsForKeys(keys, profileId, keys.associateWith { clientScopeId })
        if (actions.isEmpty()) return items
        return items.filter { item ->
            val latest = actions[buildGlobalKey(serverId, item.id)]?.firstOrNull() ?: return@filter true
            when (latest.type) {
                OfflineWatchActionType.WATCHED -> false
                OfflineWatchActionType.PROGRESS -> !latest.shouldMarkWatched
                OfflineWatchActionType.UNWATCHED -> true
            }
        }
    }

    companion object {
        private const val TAG = "SyncRuleExecutor"
        private val COOLDOWN_WIFI: Duration = 30.minutes
        private val COOLDOWN_CELLULAR: Duration = 3.hours
        const val PLAYLIST_PAGE_SIZE = 200
        const val COLLECTION_PAGE_SIZE = 100

        /** A download a rule counts as present: completed, or on its way. */
        fun isActiveDownload(status: DownloadedMediaStatus?): Boolean = status == DownloadedMediaStatus.COMPLETED ||
            status == DownloadedMediaStatus.DOWNLOADING ||
            status == DownloadedMediaStatus.QUEUED ||
            status == DownloadedMediaStatus.PAUSED
    }
}
