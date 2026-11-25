package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.isWatchedProgress
import com.edde746.plezy.model.parseGlobalKey
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Instant
import kotlin.time.TimeMark
import kotlin.time.TimeSource
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex

/** Where the offline sync reads a server's watched threshold when its client can't answer it. */
interface WatchedThresholdSource {
    /** Whether [client]'s [MediaBackend.watchedThreshold] is the server's own setting (Plex: once `/:/prefs` loaded). */
    fun reportsServerThreshold(client: MediaBackend): Boolean

    /** The percent the last successful Plex prefs fetch stored for [serverId] (`watched_threshold_<serverId>`); null when never. */
    fun cachedPercent(serverId: ServerId): Int?
}

/**
 * Queues watch progress and marks made offline and replays them to their servers once online; also pulls the
 * server's watch state of the active profile's downloads (watched on another device). Backend-neutral over
 * [MediaBackend]: Plex scrobble and timeline, MediaBrowser played items and playback sessions, through one queue.
 *
 * Queued actions belong to the active profile and replay through the exact client scope they were queued under; the
 * trackers they reach are that profile's ([ProfileTrackerWatchMarks]), and a profile change mid-action stops it before
 * its next write, leaving it queued. Syncs run on the offline→online edge of [offlineMode], whenever a server joins the
 * online servers ([onServersConnected]: the first ones, one connecting after them, one back after dropping out), and on
 * resume ([onAppResumed]); never before servers connect. Call from [scope]'s dispatcher; [scope] owns the service's
 * lifetime.
 */
class OfflineWatchSyncService(
    private val queue: OfflineWatchQueue,
    private val downloads: OfflineWatchDownloads,
    private val clients: WatchClients,
    private val notifier: WatchStateNotifier,
    private val trackers: ProfileTrackerWatchMarks,
    private val thresholds: WatchedThresholdSource,
    private val offlineMode: OfflineModeSource,
    private val scope: CoroutineScope,
    /** The least time between two server pulls unless forced: zero on phones and tablets, [DESKTOP_MIN_SYNC_INTERVAL] elsewhere. */
    private val minSyncInterval: Duration,
    /** Resume forces a full pass: phones and tablets, where the user switches devices. */
    private val forceSyncOnResume: Boolean,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    /** Held while a push of queued actions runs. */
    private val syncing = Mutex()

    private val _watchStatesRefreshed = eventFlow<Unit>()

    /** A pull updated cached watch state; the downloads re-read their metadata. */
    val watchStatesRefreshed: SharedFlow<Unit> = _watchStatesRefreshed.asSharedFlow()

    private var activeProfileId: String? = null
    private var availableProfileCount: Int? = null

    /** Bumped on every profile change, so in-flight work notices its profile is gone even after A → B → A. */
    private var profileGeneration = 0
    private val legacyAdoptedProfiles = mutableSetOf<String>()

    /** The online servers [onServersConnected] last saw, for the current profile. */
    private var connectedServers: Set<ServerId> = emptySet()
    private var lastPull: TimeMark? = null

    /** The online servers when the last pull started: one that came online since is pulled despite the throttle. */
    private var lastPullServers: Set<ServerId> = emptySet()

    private var bidirectionalPass: CompletableDeferred<Unit>? = null
    private var bidirectionalPassGeneration: Int? = null
    private var bidirectionalPassServers: Set<ServerId> = emptySet()
    private var rerunRequested = false
    private var backgroundSyncStopped = false

    init {
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            notifier.events.collect { event ->
                if (event.changeType == WatchStateChangeType.WATCHED || event.changeType == WatchStateChangeType.UNWATCHED) {
                    discardQueuedProgress(event.serverId, event.itemId, beforeRevision = event.patchId?.offlineRevision)
                }
            }
        }
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            var wasOffline = offlineMode.isOffline.value
            offlineMode.isOffline.collect { offline ->
                val cameOnline = wasOffline && !offline
                wasOffline = offline
                if (cameOnline) {
                    Log.i(TAG) { "connectivity restored, starting bidirectional watch sync" }
                    launchBidirectionalSync(force = false)
                }
            }
        }
    }

    /**
     * A threshold for [serverId]: a Plex client's loaded server setting, a MediaBrowser client's fixed one, else the
     * stored Plex setting, else 90%.
     */
    fun getWatchedThreshold(serverId: ServerId): Double {
        val client = clients.client(serverId)
        if (client != null && (client.backend.usesMediaBrowserApi || thresholds.reportsServerThreshold(client))) return client.watchedThreshold
        return (thresholds.cachedPercent(serverId) ?: DEFAULT_WATCHED_THRESHOLD_PERCENT) / 100.0
    }

    /** Whether [viewOffsetMs] of [durationMs] counts as watched on [serverId] (90% without one). */
    fun isWatchedByProgress(viewOffsetMs: Long, durationMs: Long, serverId: ServerId? = null): Boolean {
        val threshold = serverId?.let(::getWatchedThreshold) ?: (DEFAULT_WATCHED_THRESHOLD_PERCENT / 100.0)
        return isWatchedProgress(viewOffsetMs, durationMs, threshold)
    }

    /**
     * A new profile resets the joined servers and the pull throttle, so the servers-connected signal after the switch
     * syncs this profile. Actions queued before profiles existed are adopted only when exactly one profile exists
     * ([availableProfileCount] null: not known yet).
     */
    fun setActiveProfileId(profileId: String?, availableProfileCount: Int? = null) {
        if (profileId != activeProfileId) {
            profileGeneration++
            connectedServers = emptySet()
            lastPull = null
        }
        activeProfileId = profileId
        this.availableProfileCount = availableProfileCount
        if (!profileId.isNullOrEmpty()) scope.launch { adoptLegacyActions(profileId, availableProfileCount) }
    }

    suspend fun queueProgressUpdate(serverId: ServerId, itemId: String, viewOffsetMs: Long, durationMs: Long?): QueuedOfflineWatchAction {
        val shouldMarkWatched = durationMs != null && isWatchedByProgress(viewOffsetMs, durationMs, serverId)
        val clientScopeId = clientScopeIdForItem(serverId, itemId)
        val profileId = activeProfileId
        val queued = queue.upsertProgress(profileId, serverId, clientScopeId, itemId, viewOffsetMs, durationMs, shouldMarkWatched)
        Log.d(TAG) { "queued offline progress $serverId:$itemId at ${viewOffsetMs / 1000}s / ${durationMs?.let { "${it / 1000}s" } ?: "unknown"}" }
        return QueuedOfflineWatchAction(clientScopeId, profileId, queued.rowId, queued.revision)
    }

    suspend fun queueMarkWatched(serverId: ServerId, itemId: String): QueuedOfflineWatchAction =
        queueMark(serverId, itemId, OfflineWatchActionType.WATCHED)

    suspend fun queueMarkUnwatched(serverId: ServerId, itemId: String): QueuedOfflineWatchAction =
        queueMark(serverId, itemId, OfflineWatchActionType.UNWATCHED)

    private suspend fun queueMark(serverId: ServerId, itemId: String, type: OfflineWatchActionType): QueuedOfflineWatchAction {
        val clientScopeId = clientScopeIdForItem(serverId, itemId)
        val profileId = activeProfileId
        val queued = queue.insertMark(profileId, serverId, clientScopeId, itemId, type)
        Log.d(TAG) { "queued offline mark ${type.id}: $serverId:$itemId" }
        return QueuedOfflineWatchAction(clientScopeId, profileId, queued.rowId, queued.revision)
    }

    /**
     * The local watch status of [globalKey] from queued actions: true for a watched mark or threshold-crossing
     * progress, false for an unwatched mark, null otherwise (use the server's). [clientScopeId] defaults to the active
     * client's scope.
     */
    suspend fun getLocalWatchStatus(globalKey: String, clientScopeId: String? = null): Boolean? =
        localSnapshot(globalKey, clientScopeId).isWatched

    /** [getLocalWatchStatus] for many keys in one read; every requested key is in the result. */
    suspend fun getLocalWatchStatusesBatched(
        globalKeys: Set<String>,
        clientScopeIdsByGlobalKey: Map<String, String?>? = null,
    ): Map<String, Boolean?> {
        if (globalKeys.isEmpty()) return emptyMap()
        adoptLegacyActionsForActiveProfile()
        val scopes = clientScopeIdsByGlobalKey ?: buildMap {
            for (key in globalKeys) activeScopeForGlobalKey(key)?.let { put(key, it) }
        }
        val actions = queue.actionsForKeys(globalKeys, activeProfileId, scopes)
        return globalKeys.associateWith { WatchStateSnapshot.fromActions(actions[it].orEmpty()).isWatched }
    }

    private suspend fun localSnapshot(globalKey: String, clientScopeId: String?): WatchStateSnapshot {
        adoptLegacyActionsForActiveProfile()
        val expectedScope = clientScopeId ?: activeScopeForGlobalKey(globalKey)
        val scopes = if (expectedScope != null) mapOf(globalKey to expectedScope) else emptyMap()
        val actions = queue.actionsForKeys(setOf(globalKey), activeProfileId, scopes)
        return WatchStateSnapshot.fromActions(actions[globalKey].orEmpty())
    }

    /** Queued actions still under [MAX_SYNC_ATTEMPTS], the active profile's when one is set. */
    suspend fun getPendingSyncCount(): Int {
        adoptLegacyActionsForActiveProfile()
        return queue.pendingCount(activeProfileId?.takeIf { it.isNotEmpty() }, MAX_SYNC_ATTEMPTS)
    }

    /**
     * Replays the active profile's queued actions; one push at a time. Without an active profile nothing replays: the
     * bound clients could be another user's. A profile change or [stopBackgroundSync] mid-pass leaves the rest queued;
     * a profile change mid-action stops it before its next write or acknowledgment, leaving it queued without spending
     * an attempt. An action whose server is unbound or offline waits without spending an attempt; one past
     * [MAX_SYNC_ATTEMPTS] stays queued for explicit cleanup. A replayed row is deleted only if unchanged meanwhile, then
     * its patch promoted; a failed or unpersisted write counts an attempt.
     */
    suspend fun syncPendingItems() {
        if (!syncing.tryLock()) {
            Log.d(TAG) { "sync already in progress, skipping" }
            return
        }
        try {
            adoptLegacyActionsForActiveProfile()
            val profileId = activeProfileId
            if (profileId.isNullOrEmpty()) {
                Log.d(TAG) { "no active profile, deferring pending watch sync" }
                return
            }
            val generation = profileGeneration
            val pass = Replay(trackers.forProfile(profileId)) { generation == profileGeneration }
            val pending = queue.pendingActions(profileId)
            if (pending.isEmpty()) return
            Log.i(TAG) { "syncing ${pending.size} pending watch actions" }
            for (action in pending) {
                if (backgroundSyncStopped) return
                if (!pass.isCurrent()) {
                    Log.i(TAG) { "active profile changed mid-sync, requeueing remaining watch actions" }
                    return
                }
                if (action.syncAttempts >= MAX_SYNC_ATTEMPTS) {
                    Log.w(TAG) { "skipping action ${action.rowId}: ${action.syncAttempts} attempts, last error ${action.lastError}" }
                    continue
                }
                val target = replayTarget(action)
                if (target == null || !clients.isClientOnline(action.serverId, target.clientScopeId)) {
                    Log.d(TAG) { "keeping action ${action.rowId} queued until ${action.serverId} is available" }
                    continue
                }
                replay(target.client, action, pass)
            }
        } finally {
            syncing.unlock()
        }
    }

    /** One push's profile: its trackers ([marks]), and whether it is still the active one ([isCurrent]). */
    private class Replay(val marks: TrackerWatchMarks, val isCurrent: () -> Boolean)

    private suspend fun replay(client: MediaBackend, action: OfflineWatchAction, pass: Replay) {
        try {
            val persisted = syncAction(client, action, pass)
            if (!pass.isCurrent()) {
                Log.i(TAG) { "active profile changed during action ${action.rowId}; keeping it queued" }
                return
            }
            if (!persisted) {
                Log.d(TAG) { "action ${action.rowId} did not persist; keeping it queued" }
                queue.recordFailedAttemptIfUnchanged(action.rowId, action.updatedAt, "write did not persist")
                return
            }
            if (!queue.deleteIfUnchanged(action.rowId, action.updatedAt)) {
                Log.d(TAG) { "synced action ${action.rowId} revision ${action.updatedAt}; a newer revision remains queued" }
                return
            }
            notifier.promote(WatchPatchId.offlineAction(action.profileId, action.rowId, action.updatedAt))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "failed to sync action ${action.rowId}" }
            queue.recordFailedAttemptIfUnchanged(action.rowId, action.updatedAt, e.toString())
        }
    }

    /**
     * Writes one action through [client]; whether the server persisted it. Marks fetch the item first (best effort)
     * so trackers get ids, parents and library. Progress replays a stopped report at the queued position (the duration
     * when completed) stamped as an offline replay; MediaBrowser drops a stop for a session never opened, so there the
     * started report must succeed. A completed replay marks watched explicitly only where the stop report doesn't.
     * Stops before any further write once [pass]'s profile is no longer active (the answer then means nothing).
     */
    private suspend fun syncAction(client: MediaBackend, action: OfflineWatchAction, pass: Replay): Boolean {
        val needsRichItem = action.type != OfflineWatchActionType.PROGRESS || action.shouldMarkWatched
        val fetched = if (needsRichItem) {
            try {
                client.fetchItem(action.itemId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "metadata fetch for ${action.itemId} failed; replaying with a minimal item" }
                null
            }
        } else {
            null
        }
        val item = fetched ?: MediaItem(id = action.itemId, backend = client.backend, kind = MediaKind.UNKNOWN, serverId = action.serverId.value)
        if (!pass.isCurrent()) return false
        when (action.type) {
            OfflineWatchActionType.WATCHED -> {
                client.markWatched(item)
                if (pass.isCurrent()) pass.marks.mark(item, client, watched = true)
                return true
            }
            OfflineWatchActionType.UNWATCHED -> {
                client.markUnwatched(item)
                if (pass.isCurrent()) pass.marks.mark(item, client, watched = false)
                return true
            }
            OfflineWatchActionType.PROGRESS -> {
                var persisted = false
                val offset = action.viewOffsetMs
                if (offset != null) {
                    val duration = action.durationMs?.milliseconds
                    val position = if (action.shouldMarkWatched && duration != null) duration else offset.milliseconds
                    val requiresOpenSession = client.backend.usesMediaBrowserApi
                    var started = !requiresOpenSession
                    if (!action.shouldMarkWatched || requiresOpenSession) {
                        try {
                            client.reportPlaybackStarted(itemId = action.itemId, position = position, duration = duration)
                            started = true
                        } catch (e: CancellationException) {
                            throw e
                        } catch (e: Exception) {
                            // Plex may 5xx a start nothing follows; its stop still persists the position.
                            Log.d(TAG, e) { "offline progress: started report failed, continuing" }
                        }
                    }
                    if (!pass.isCurrent()) return false
                    client.reportPlaybackStopped(
                        itemId = action.itemId,
                        position = position,
                        duration = duration,
                        report = PlaybackReportMetadata.offlineReplay(recordedAt = Instant.fromEpochMilliseconds(action.updatedAt)),
                    )
                    persisted = started
                }
                if (action.shouldMarkWatched) {
                    if (!pass.isCurrent()) return false
                    if (!client.marksWatchedOnPlaybackStopped) {
                        client.markWatched(item)
                        persisted = true
                    }
                    if (pass.isCurrent()) pass.marks.mark(item, client, watched = true)
                }
                return persisted
            }
        }
    }

    /**
     * Pulls the server's watch state of the active profile's downloads through the active scoped clients: episodes one
     * request per season, everything else one per item. Patches the cached watch fields; a change against the cached
     * prior emits an acknowledged event and goes to the trackers, while an item without a cached row is only cached.
     * Stops once the profile changes.
     */
    suspend fun syncWatchStatesFromServer() {
        try {
            val profileId = activeProfileId
            if (profileId.isNullOrEmpty()) {
                Log.d(TAG) { "skipping watch-state pull: no active profile" }
                return
            }
            val generation = profileGeneration
            val marks = trackers.forProfile(profileId)
            var stopped = false
            fun isStale(): Boolean {
                if (!stopped && (backgroundSyncStopped || generation != profileGeneration)) {
                    stopped = true
                    Log.i(TAG) { if (generation != profileGeneration) "active profile changed mid-pull, stopping" else "watch-state pull stopped" }
                }
                return stopped
            }

            val owned = downloads.ownedDownloads(profileId)
            if (owned.isEmpty()) return
            Log.i(TAG) { "syncing watch states from server for ${owned.size} items" }

            val episodesBySeason = LinkedHashMap<PullScope, LinkedHashMap<String, MutableSet<String>>>()
            val others = LinkedHashMap<PullScope, MutableList<String>>()
            for (item in owned) {
                val pullScope = PullScope(item.serverId, activeScopeForServer(item.serverId))
                val seasonId = item.parentId
                if (item.kind == MediaKind.EPISODE && seasonId != null) {
                    episodesBySeason.getOrPut(pullScope) { LinkedHashMap() }.getOrPut(seasonId) { mutableSetOf() }.add(item.itemId)
                } else {
                    others.getOrPut(pullScope) { mutableListOf() }.add(item.itemId)
                }
            }

            var synced = 0
            for ((pullScope, seasons) in episodesBySeason) {
                if (isStale()) return
                val client = onlineClientFor(pullScope) ?: continue
                for ((seasonId, episodeIds) in seasons) {
                    if (isStale()) return
                    val count = syncSeasonEpisodes(client, seasonId, episodeIds, marks) { isStale() }
                    if (count >= 0) synced += count
                }
            }
            for ((pullScope, itemIds) in others) {
                if (isStale()) return
                val client = onlineClientFor(pullScope) ?: continue
                for (itemId in itemIds) {
                    if (isStale()) return
                    try {
                        val prior = client.cache.getMetadata(client.cacheServerId, itemId)
                        val wasWatched = (prior?.viewCount ?: 0) > 0
                        val metadata = client.fetchItem(itemId)
                        if (isStale()) return
                        if (metadata != null) {
                            synced++
                            val isWatched = (metadata.viewCount ?: 0) > 0
                            if (wasWatched != isWatched) announceServerChange(metadata, client, isWatched, marks)
                        }
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.d(TAG, e) { "failed to sync watch state for $itemId" }
                    }
                }
            }
            if (isStale()) return
            Log.i(TAG) { "synced $synced watch states" }
            if (synced > 0) _watchStatesRefreshed.tryEmit(Unit)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "error syncing watch states from server" }
        }
    }

    /** Syncs the downloaded episodes of one season; how many, or -1 when the season fetch failed. */
    private suspend fun syncSeasonEpisodes(
        client: MediaBackend,
        seasonId: String,
        episodeIds: Set<String>,
        marks: TrackerWatchMarks,
        isStale: () -> Boolean,
    ): Int {
        try {
            val episodes = client.fetchChildren(seasonId)
            var synced = 0
            for (episode in episodes) {
                if (isStale()) return synced
                if (episode.id !in episodeIds) continue
                val cacheServerId = client.cacheServerId
                val prior = client.cache.getMetadata(cacheServerId, episode.id)
                val isWatched = (episode.viewCount ?: 0) > 0
                if (prior != null) {
                    client.cache.applyWatchState(cacheServerId, episode.id, isWatched, episode.viewOffsetMs, episode.lastViewedAt, episode.viewedLeafCount)
                    if ((prior.viewCount ?: 0) > 0 != isWatched) announceServerChange(episode, client, isWatched, marks)
                } else {
                    // No cached row: fetchItem writes it, then the watch fields land on it. No prior state, no event.
                    try {
                        client.fetchItem(episode.id)
                        client.cache.applyWatchState(cacheServerId, episode.id, isWatched, episode.viewOffsetMs, episode.lastViewedAt, episode.viewedLeafCount)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.d(TAG, e) { "cache populate failed for ${episode.id}" }
                    }
                }
                synced++
            }
            return synced
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "failed to sync watch states for season $seasonId" }
            return -1
        }
    }

    /**
     * A change made on another device: no playback or mark here told anyone, so announce it and tell the pulling
     * profile's trackers ([marks]).
     */
    private suspend fun announceServerChange(item: MediaItem, client: MediaBackend, isWatched: Boolean, marks: TrackerWatchMarks) {
        notifier.notifyWatched(item, isNowWatched = isWatched, cacheServerId = client.cacheServerId, serverAcknowledged = true)
        marks.mark(item, client, isWatched)
    }

    /** Deletes every queued action (sign-out). */
    suspend fun clearAll() {
        queue.clearAll()
    }

    /** The app became active: sync for changes made on other devices; forced per [forceSyncOnResume]. */
    fun onAppResumed() {
        if (offlineMode.isOffline.value) return
        Log.d(TAG) { "app resumed, ${if (forceSyncOnResume) "forcing" else "checking"} sync" }
        launchBidirectionalSync(force = forceSyncOnResume)
    }

    /**
     * The online servers changed; call after every change. Each server that joined them since the last call (for this
     * profile) starts a pass, so its queued actions replay and its downloads' state is pulled whichever order the servers
     * connect in.
     */
    fun onServersConnected() {
        val online = clients.onlineClients.keys.toSet()
        val joined = online - connectedServers
        connectedServers = online
        if (joined.isEmpty() || offlineMode.isOffline.value) return
        Log.i(TAG) { "${joined.joinToString { it.value }} connected, syncing watch state" }
        launchBidirectionalSync(force = false)
    }

    /**
     * Stops background sync for good: no trigger starts another pass and the one in flight stops at its next step.
     * Returns once that pass settled, so the database can close after it.
     */
    suspend fun stopBackgroundSync() {
        backgroundSyncStopped = true
        bidirectionalPass?.await()
    }

    private fun launchBidirectionalSync(force: Boolean) {
        scope.launch { performBidirectionalSync(force) }
    }

    /**
     * Pushes the queue, then pulls the server's state unless one ran within [minSyncInterval] over the same online
     * servers ([force] skips the throttle). One pass at a time; a request during a pass reruns it, forced, once it
     * settles when the pass is a previous profile's or a server came online after it started (its actions were skipped).
     */
    private suspend fun performBidirectionalSync(force: Boolean) {
        if (backgroundSyncStopped) return
        if (bidirectionalPass != null) {
            if (bidirectionalPassGeneration != profileGeneration || !bidirectionalPassServers.containsAll(clients.onlineClients.keys)) {
                rerunRequested = true
            }
            Log.d(TAG) { "bidirectional sync already in progress, skipping" }
            return
        }
        val online = clients.onlineClients.keys.toSet()
        if (online.isEmpty()) {
            Log.d(TAG) { "skipping watch sync: no connected servers yet" }
            return
        }
        val pass = CompletableDeferred<Unit>()
        bidirectionalPass = pass
        val generation = profileGeneration
        bidirectionalPassGeneration = generation
        bidirectionalPassServers = online
        try {
            syncPendingItems()
            if (backgroundSyncStopped) return
            val last = lastPull
            if (!force && last != null && last.elapsedNow() < minSyncInterval && lastPullServers.containsAll(online)) {
                Log.d(TAG) { "skipping server pull: last one ${last.elapsedNow()} ago" }
                return
            }
            syncWatchStatesFromServer()
            if (generation == profileGeneration) {
                lastPull = timeSource.markNow()
                lastPullServers = online
            }
        } finally {
            bidirectionalPass = null
            bidirectionalPassGeneration = null
            bidirectionalPassServers = emptySet()
            pass.complete(Unit)
            if (rerunRequested) {
                rerunRequested = false
                launchBidirectionalSync(force = true)
            }
        }
    }

    /**
     * A terminal mark landed, so progress still queued for the item would rewrite the resume position the mark
     * cleared (on MediaBrowser pinning it to Continue Watching). For an offline mark only progress older than
     * its revision is stale; newer progress is a rewatch.
     */
    private suspend fun discardQueuedProgress(serverId: ServerId, itemId: String, beforeRevision: Long?) {
        try {
            val removed = queue.deleteProgress(activeProfileId, serverId, clientScopeIdForItem(serverId, itemId), itemId, beforeRevision)
            if (removed > 0) Log.d(TAG) { "dropped $removed superseded queued progress action(s) for $serverId:$itemId" }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "failed to drop superseded queued progress for $serverId:$itemId" }
        }
    }

    /**
     * The scope a new action for the item is queued under: the active scoped client's, else the download's (a Plex
     * profile scope rewritten to the active profile's, since actions are user-owned).
     */
    private suspend fun clientScopeIdForItem(serverId: ServerId, itemId: String): String? {
        activeScopeForServer(serverId)?.let { return it }
        val downloaded = resolveActiveClientScopeId(serverId, downloads.downloadedClientScopeId(buildGlobalKey(serverId, itemId)))
        val profileId = activeProfileId
        if (downloaded != null && isPlexProfileScopeId(downloaded) && !profileId.isNullOrEmpty()) return PlexProfileScopeId.of(serverId, profileId).value
        return downloaded
    }

    /**
     * The client an action replays through: exactly its queued scope's (none bound: wait). An unscoped action never
     * replays through a user-scoped MediaBrowser client, which could be another user's.
     */
    private fun replayTarget(action: OfflineWatchAction): ReplayTarget? {
        val scopeId = resolveActiveClientScopeId(action.serverId, action.clientScopeId)
        if (scopeId != null) return clients.clientByScope(scopeId)?.let { ReplayTarget(it, scopeId) }
        val client = clients.client(action.serverId) ?: return null
        if (client.backend.usesMediaBrowserApi && client.cacheServerId != action.serverId.value) {
            Log.w(TAG) { "refusing to sync unscoped MediaBrowser action ${action.rowId} for ${action.globalKey}: no queued client scope" }
            return null
        }
        return ReplayTarget(client, action.clientScopeId)
    }

    private fun onlineClientFor(pullScope: PullScope): MediaBackend? {
        val scopeId = pullScope.clientScopeId
        val client = if (!scopeId.isNullOrEmpty()) clients.clientByScope(scopeId) else clients.client(pullScope.serverId)
        if (client == null || !clients.isClientOnline(pullScope.serverId, scopeId)) {
            Log.d(TAG) { "no online client for ${pullScope.serverId} scope $scopeId, skipping" }
            return null
        }
        return client
    }

    private fun activeScopeForServer(serverId: ServerId): String? = resolveActiveClientScopeId(serverId, clients.client(serverId)?.cacheServerId)

    private fun activeScopeForGlobalKey(globalKey: String): String? = parseGlobalKey(globalKey)?.let { activeScopeForServer(it.first) }

    private suspend fun adoptLegacyActionsForActiveProfile() {
        val profileId = activeProfileId
        if (!profileId.isNullOrEmpty()) adoptLegacyActions(profileId, availableProfileCount)
    }

    private suspend fun adoptLegacyActions(profileId: String, availableProfileCount: Int?) {
        if (!legacyAdoptedProfiles.add(profileId)) return
        if (availableProfileCount != 1) {
            legacyAdoptedProfiles.remove(profileId)
            return
        }
        try {
            queue.adoptLegacyActions(profileId)
        } catch (e: CancellationException) {
            legacyAdoptedProfiles.remove(profileId)
            throw e
        } catch (e: Exception) {
            legacyAdoptedProfiles.remove(profileId)
            Log.w(TAG, e) { "failed to adopt legacy offline watch actions for $profileId" }
        }
    }

    private class ReplayTarget(val client: MediaBackend, val clientScopeId: String?)

    private data class PullScope(val serverId: ServerId, val clientScopeId: String?)

    companion object {
        /** Attempts after which an action stops replaying; it stays queued so an outage never drops progress. */
        const val MAX_SYNC_ATTEMPTS = 5

        val DESKTOP_MIN_SYNC_INTERVAL: Duration = 2.minutes

        private const val DEFAULT_WATCHED_THRESHOLD_PERCENT = 90
        private const val TAG = "OfflineWatchSync"
    }
}
