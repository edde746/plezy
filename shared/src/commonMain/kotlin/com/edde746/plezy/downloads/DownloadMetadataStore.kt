package com.edde746.plezy.downloads

import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.servers.HydratedWatchStatePatch
import com.edde746.plezy.servers.OfflineWatchQueue
import com.edde746.plezy.servers.WatchPatchId
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchStateSnapshot
import com.edde746.plezy.servers.WatchStateStore
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * Downloaded metadata, artwork references and the profile's watch-state overlay on them. [DownloadsController] keeps
 * queue and ownership; this store keeps cache hydration and watch-state synchronization.
 *
 * Watch events for a downloaded item are written to the item's cache rows under the active client scope (in order), so
 * offline browsing shows them; [onChanged] runs whenever the overlay changes.
 */
class DownloadMetadataStore internal constructor(
    private val manager: DownloadManagerService,
    private val watchQueue: OfflineWatchQueue,
    private val caches: (BackendKind) -> BackendCache?,
    notifier: WatchStateNotifier,
    private val scope: CoroutineScope,
    activeProfileId: String?,
    private val onChanged: () -> Unit,
) {
    private val watchStateStore = WatchStateStore(notifier, scope)
    private var watchStateWriteTail: Job? = null

    /** Raw metadata by public global key. */
    val items: MutableMap<String, MediaItem> = mutableMapOf()

    /** Artwork storage keys (the thumb path) by global key. */
    val artworkPaths: MutableMap<String, String?> = mutableMapOf()

    private val watchScopesByServer = mutableMapOf<ServerId, String?>()
    private var activeProfileId: String? = activeProfileId

    init {
        watchStateStore.setActiveProfileId(activeProfileId)
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            notifier.events.collect { event ->
                onWatchStateChanged(event)
                onChanged()
            }
        }
    }

    fun setActiveProfileId(profileId: String?) {
        if (activeProfileId == profileId) return
        activeProfileId = profileId
        watchScopesByServer.clear()
        watchStateStore.setActiveProfileId(profileId)
        watchStateStore.setActiveClientScopesByServer(emptyMap())
    }

    fun applyWatchState(item: MediaItem): MediaItem = watchStateStore.apply(item)

    fun resolved(globalKey: String): MediaItem? = items[globalKey]?.let(::applyWatchState)

    val resolvedItems: Map<String, MediaItem> get() = items.mapValues { applyWatchState(it.value) }

    /** Loads [leaf]'s show and season (artist and album) from a fetched snapshot, preferring [clientScopeId]'s rows. */
    fun loadParentMetadataFromMap(leaf: MediaItem, allMetadata: Map<String, MediaItem>, clientScopeId: String? = null) {
        val serverId = ServerId.tryParse(leaf.serverId) ?: return
        fun lookup(id: String): MediaItem? {
            if (!clientScopeId.isNullOrEmpty()) ServerId.tryParse(clientScopeId)?.let { scoped -> allMetadata[buildGlobalKey(scoped, id)]?.let { return it } }
            return allMetadata[buildGlobalKey(serverId, id)]
        }
        for (id in listOfNotNull(leaf.grandparentId, leaf.parentId)) {
            val key = buildGlobalKey(serverId, id)
            if (key in items) continue
            val parent = lookup(id) ?: continue
            items[key] = parent
            if (parent.thumbPath != null) artworkPaths[key] = parent.thumbPath
        }
    }

    /** Rebuilds the active profile's queued offline watch actions into the overlay; [isStale] aborts a superseded run. */
    suspend fun hydrateOfflineWatchOverlay(isStale: (() -> Boolean)? = null) {
        fun stale() = isStale?.invoke() ?: false
        try {
            val profileId = activeProfileId
            if (profileId.isNullOrEmpty()) {
                watchStateStore.setHydratedPatches(emptyList())
                return
            }
            val keys = mutableSetOf<String>()
            for (item in items.values.toList()) {
                keys += item.globalKey
                val serverId = ServerId.tryParse(item.serverId) ?: continue
                for (parentId in item.parentChain) keys += buildGlobalKey(serverId, parentId)
            }
            if (keys.isEmpty()) {
                watchStateStore.setHydratedPatches(emptyList())
                return
            }
            val scopes = mutableMapOf<String, String?>()
            val scopesByServer = mutableMapOf<ServerId, String?>()
            for (key in keys) {
                val serverId = parseGlobalKey(key)?.first ?: continue
                if (serverId !in scopesByServer) scopesByServer[serverId] = manager.profileClientScopeIdForServer(serverId, profileId)
                scopes[key] = scopesByServer[serverId]
                if (stale()) return
            }
            watchScopesByServer.clear()
            watchScopesByServer.putAll(scopesByServer)
            watchStateStore.setActiveClientScopesByServer(watchScopesByServer)

            val actions = watchQueue.actionsForKeys(keys, profileId, scopes)
            if (stale()) return
            val hydrated = actions.values.mapNotNull { list ->
                val patch = WatchStateSnapshot.fromActions(list)
                if (patch.isEmpty) return@mapNotNull null
                val latest = list.first()
                val scopedKey = if (!latest.clientScopeId.isNullOrEmpty()) "${latest.clientScopeId}:${latest.itemId}" else latest.globalKey
                HydratedWatchStatePatch(
                    globalKey = scopedKey,
                    patch = patch,
                    updatedAt = latest.updatedAt,
                    order = latest.rowId,
                    patchId = WatchPatchId.offlineAction(latest.profileId, latest.rowId, latest.updatedAt),
                )
            }
            watchStateStore.setHydratedPatches(hydrated)
            onChanged()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to apply offline watch overlay" }
        }
    }

    private fun onWatchStateChanged(event: WatchStateEvent) {
        val snapshot = WatchStateSnapshot.fromEvent(event)
        if (snapshot.isEmpty) return
        val base = items[event.globalKey]
        val activeScope = manager.activeClientScopeIdForServer(event.serverId)
        if (!activeScope.isNullOrEmpty()) {
            watchScopesByServer[event.serverId] = activeScope
            watchStateStore.setActiveClientScopesByServer(watchScopesByServer)
        }
        if (base == null || activeScope.isNullOrEmpty()) return
        val eventScope = event.cacheServerId
        if (!eventScope.isNullOrEmpty() && eventScope != event.serverId.value && eventScope != activeScope) return
        val isWatched = snapshot.isWatched ?: return
        if (event.changeType == WatchStateChangeType.PROGRESS_UPDATE && event.isNowWatched != true) return
        val cache = caches(base.backend) ?: return
        val previous = watchStateWriteTail
        watchStateWriteTail = scope.launch {
            previous?.join()
            try {
                cache.applyWatchState(activeScope, event.itemId, isWatched)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to apply watch state to cache for ${event.globalKey}" }
            }
        }
    }

    private companion object {
        const val TAG = "DownloadMetadataStore"
    }
}
