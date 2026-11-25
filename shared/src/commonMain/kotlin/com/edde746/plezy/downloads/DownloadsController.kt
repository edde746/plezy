package com.edde746.plezy.downloads

import com.edde746.plezy.app.NotificationPermission
import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.db.Download_owners
import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.downloads.DownloadCollectionRepository
import com.edde746.plezy.data.downloads.DownloadLibraryRepository
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.SyncRule
import com.edde746.plezy.data.downloads.SyncRuleFilter
import com.edde746.plezy.data.downloads.SyncRuleRepository
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.data.downloads.syncRuleKey
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.DownloadedCollection
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaItemSortExtras
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.collectEpisodes
import com.edde746.plezy.model.collectListLeaves
import com.edde746.plezy.model.groupByDownloadedCollection
import com.edde746.plezy.model.isSpecialSeasonNumber
import com.edde746.plezy.model.mergeFetchedMediaItem
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.profiles.ProfileDownloads
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.Connectivity
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.OfflineModeSource
import com.edde746.plezy.servers.OfflineWatchQueue
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlin.math.roundToInt
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds

/** A library the profile's completed downloads come from; [title] falls back to the server name. */
data class DownloadedLibrary(val serverId: String, val libraryId: String?, val title: String)

/** The servers downloads and rules reach: the active client of a server and whether it is online. */
interface DownloadServers : SyncRuleServers

/** Thrown when a sync-rule edit or cleanup meets a cleanup or rule pass in progress. */
class SyncRuleCleanupBusyException : IllegalStateException("A sync rule pass or cleanup is in progress")

/** Thrown when a list rule's downloads cannot be told apart because its list could not be read. */
class SyncRuleCleanupUnavailableException(val ruleGlobalKey: String) : IllegalStateException("Sync rule $ruleGlobalKey cannot be cleaned up now")

/**
 * The active profile's view of the downloads, and every download action the app takes: queueing (items, containers,
 * lists), pause/resume/retry/cancel/delete, sync rules and their triggers, collection folders and the downloaded
 * metadata the offline screens read.
 *
 * Physical downloads are shared across profiles; a profile sees (and acts on) only the rows it owns. A profile switch
 * bumps a generation so in-flight work for the previous profile stops instead of acting for the new one.
 *
 * State is read through the getters; [changes] ticks whenever any of it changes, and [progressFlow] follows one key.
 * Calls are expected on one thread (the UI's); work runs in [parentScope].
 */
class DownloadsController internal constructor(
    private val manager: DownloadManagerService,
    private val library: DownloadLibraryRepository,
    private val syncRuleRepository: SyncRuleRepository,
    private val collectionRepository: DownloadCollectionRepository,
    watchQueue: OfflineWatchQueue,
    private val servers: DownloadServers,
    watchStateNotifier: WatchStateNotifier,
    private val deletionNotifier: DeletionNotifier,
    private val notificationPermission: NotificationPermission,
    private val videoSource: DownloadedVideoSource,
    private val artwork: DownloadArtworkService,
    private val connectivity: suspend () -> Connectivity,
    caches: (BackendKind) -> BackendCache?,
    private val specialsOrdering: () -> SpecialsOrdering,
    private val autoRemoveWatchedDownloads: () -> Boolean,
    /** The global key of the item playing now, protected from auto-removal and watch-event runs. */
    private val playingItemKey: () -> String?,
    private val clock: () -> Long,
    parentScope: CoroutineScope,
    activeProfileId: String? = null,
    loadOnStart: Boolean = true,
    /** The manager's retry of one download; tests replace it to observe the retry order. */
    private val retryOnManager: suspend (globalKey: String, client: MediaBackend) -> Unit = manager::retryDownload,
) : ProfileDownloads {
    private data class QueueOwnership(val profileId: String, val generation: Int)

    private class RelatedMetadataContext {
        val hydratedMetadataKeys = mutableSetOf<String>()
        val ensuredArtworkKeys = mutableSetOf<String>()
    }

    private data class HydrationResult(val metadata: MediaItem?, val networkFilled: Boolean, val stale: Boolean)

    private data class LibraryStamp(val libraryId: String?, val libraryTitle: String?)

    private val scope = parentScope.childScope()
    private var disposed = false

    private val syncRuleExecutor = SyncRuleExecutor(
        syncRuleRepository,
        watchQueue,
        connectivity,
        cellularBlocked = manager::shouldBlockDownloadOnCellularWith,
        ordering = specialsOrdering,
        clock = clock,
    )

    private val downloadsMap = mutableMapOf<String, DownloadProgress>()
    private val metadataStore = DownloadMetadataStore(manager, watchQueue, caches, watchStateNotifier, scope, activeProfileId, ::notifyChanged)
    private val metadataMap: MutableMap<String, MediaItem> get() = metadataStore.items
    private val artworkPaths: MutableMap<String, String?> get() = metadataStore.artworkPaths
    private val queueing = mutableMapOf<String, QueueOwnership>()
    private val ownedDownloadKeys = mutableSetOf<String>()
    private val downloadLibraries = mutableMapOf<String, LibraryStamp>()
    private val deletionProgress = mutableMapOf<String, DeletionProgress>()
    private val retryingKeys = mutableSetOf<String>()
    private val syncRulesMap = mutableMapOf<String, SyncRule>()
    private val removingSyncRuleKeys = mutableSetOf<String>()
    private var syncRuleCleanupInProgress = false
    private val collections = mutableMapOf<String, DownloadedCollection>()
    private val collectionRefreshesRunning = mutableSetOf<String>()
    private val collectionRefreshesRequested = mutableSetOf<String>()
    private var batchDeletionDepth = 0

    private var activeProfileId: String? = activeProfileId
    private var profileGeneration = 0
    private var profileScopedReload: Job? = null

    private var offlineSource: OfflineModeSource? = null
    private var offlineSourceJob: Job? = null
    private var networkStateGeneration = 0

    private val _changes = MutableStateFlow(0L)

    /** Ticks on every change of the state the getters read. */
    val changes: StateFlow<Long> = _changes.asStateFlow()

    private val _syncedNewEpisodes = MutableSharedFlow<String>(extraBufferCapacity = 8)

    /** The message of each trigger pass that queued something (`syncedNewEpisodes`). */
    val syncMessages: SharedFlow<String> = _syncedNewEpisodes.asSharedFlow()

    private val _autoRemoved = MutableSharedFlow<String>(extraBufferCapacity = 8)

    /** The message of each auto-removal of watched downloads (`autoRemovedWatchedDownload(s)`). */
    val autoRemovedMessages: SharedFlow<String> = _autoRemoved.asSharedFlow()

    private val initialized: Deferred<Unit>

    init {
        scope.launch(start = CoroutineStart.UNDISPATCHED) { manager.progressStream.collect(::onProgressUpdate) }
        scope.launch(start = CoroutineStart.UNDISPATCHED) { manager.deletionProgressStream.collect(::onDeletionProgressUpdate) }
        scope.launch(start = CoroutineStart.UNDISPATCHED) { watchStateNotifier.events.collect(::onWatchEvent) }
        initialized = if (loadOnStart) scope.async { loadPersistedDownloads() } else scope.async { loadProfileScopedState() }
    }

    /** [completedChanged] false: the change left every download's completion as it was (a running download's tick). */
    private fun notifyChanged(completedChanged: Boolean = true) {
        if (completedChanged) completedVersion++
        if (!disposed) _changes.update { it + 1 }
    }

    /** Counts the changes that may touch the completed downloads; [albumTracks] is grouped at one. */
    private var completedVersion = 0L
    private var albumTracks: Pair<Long, Map<Pair<String?, String?>, List<MediaItem>>>? = null

    // region lifecycle and profile

    suspend fun ensureInitialized() = initialized.await()

    /** Supplies the offline state queueing and rule passes read; each transition counts in the activity snapshot. */
    fun setOfflineSource(source: OfflineModeSource?) {
        if (offlineSource !== source) {
            offlineSourceJob?.cancel()
            offlineSource = source
            networkStateGeneration++
            offlineSourceJob = source?.let { s ->
                scope.launch(start = CoroutineStart.UNDISPATCHED) {
                    var first = true
                    s.isOffline.collect {
                        if (!first) networkStateGeneration++
                        first = false
                    }
                }
            }
        }
        manager.setOfflineSource(source)
    }

    private val isOffline: Boolean get() = offlineSource?.isOffline?.value ?: false

    suspend fun setDownloadLocation(path: String, pathType: String, checkCurrent: (() -> Unit)? = null) =
        manager.setDownloadLocation(path, pathType, checkCurrent)

    suspend fun resetDownloadLocation(checkCurrent: (() -> Unit)? = null) = manager.resetDownloadLocation(checkCurrent)

    /** Switches the visible ownership and rules to [profileId]; physical downloads stay as they are. */
    fun setActiveProfileId(profileId: String?) {
        if (activeProfileId == profileId) return
        profileGeneration++
        queueing.clear()
        ownedDownloadKeys.clear()
        syncRulesMap.clear()
        collections.clear()
        metadataMap.clear()
        activeProfileId = profileId
        metadataStore.setActiveProfileId(profileId)
        notifyChanged()
        val targetProfile = profileId
        val targetGeneration = profileGeneration
        profileScopedReload = scope.launch {
            initialized.await()
            if (activeProfileId != targetProfile || profileGeneration != targetGeneration) return@launch
            loadProfileScopedState()
            refreshMetadataFromCache()
            if (activeProfileId == targetProfile && profileGeneration == targetGeneration) notifyChanged()
        }
    }

    private fun requireActiveProfileId(): String {
        val profileId = activeProfileId
        check(!profileId.isNullOrEmpty()) { "Cannot create, update, or claim downloads without an active profile" }
        return profileId
    }

    private fun captureQueueOwnership() = QueueOwnership(requireActiveProfileId(), profileGeneration)

    private fun isCurrent(ownership: QueueOwnership) =
        !disposed && activeProfileId == ownership.profileId && profileGeneration == ownership.generation

    private fun owns(globalKey: String) = globalKey in ownedDownloadKeys

    fun dispose() {
        disposed = true
        offlineSourceJob?.cancel()
        scope.cancel()
    }

    val isDisposed: Boolean get() = disposed

    // endregion

    // region ownership

    private suspend fun claimDownloadForProfile(globalKey: String, ownership: QueueOwnership, client: MediaBackend): Boolean {
        if (!isCurrent(ownership) || owns(globalKey)) return false
        library.addDownloadOwner(ownership.profileId, globalKey, client.backend.id, client.cacheServerId)
        if (!isCurrent(ownership)) return false
        ownedDownloadKeys += globalKey
        return true
    }

    private suspend fun releaseDownloadForProfile(
        globalKey: String,
        profileId: String,
        onlyIfShared: Boolean = false,
        ownerHint: Download_owners? = null,
    ): Boolean {
        var owner = ownerHint
        if (onlyIfShared) {
            owner = owner ?: library.getDownloadOwner(profileId, globalKey)
            val result = library.removeSharedDownloadOwnerAndRebindIncompleteMedia(profileId, globalKey)
            if (!result.hasRemainingOwner) return false
            owner = result.removedOwner ?: owner
        } else {
            owner = owner ?: library.getDownloadOwner(profileId, globalKey)
            library.removeDownloadOwner(profileId, globalKey)
        }
        val parsed = parseGlobalKey(globalKey)
        if (parsed != null && owner != null) {
            manager.deleteMetadataForOwner(globalKey, parsed.first, parsed.second, profileId, owner.backend, owner.client_scope_id)
        }
        if (activeProfileId == profileId) ownedDownloadKeys -= globalKey
        return true
    }

    /** Releases every download [profileId] owns; rows no other valid profile owns are deleted with their files. */
    override suspend fun deleteDownloadsForProfile(profileId: String) = releaseDownloadsForProfileWhere(profileId) { true }

    /** Keeps the files through a full logout: ownership is detached and the next profile adopts the rows. */
    suspend fun detachDownloadsForLogout() {
        activeProfileId = null
        metadataStore.setActiveProfileId(null)
        profileGeneration++
        initialized.await()
        profileScopedReload?.join()
        manager.preparePlexMetadataForLogoutTransfer()
        library.clearAllDownloadOwners()
        ownedDownloadKeys.clear()
        syncRulesMap.clear()
        collections.clear()
        notifyChanged()
    }

    /** Releases [profileId]'s downloads from [serverIds] (a removed connection); shared rows stay for their owners. */
    override suspend fun releaseDownloadsForProfileServers(profileId: String, serverIds: Set<String>) {
        if (serverIds.isEmpty()) return
        releaseDownloadsForProfileWhere(profileId) { key -> parseGlobalKey(key)?.first?.value in serverIds }
    }

    private suspend fun releaseDownloadsForProfileWhere(profileId: String, shouldRelease: (String) -> Boolean) {
        if (profileId.isEmpty()) return
        var changed = false
        for (globalKey in library.getDownloadOwnerKeysForProfile(profileId)) {
            if (!shouldRelease(globalKey)) continue
            val meta = metadataMap[globalKey]
            if (releaseDownloadForProfile(globalKey, profileId, onlyIfShared = true)) {
                if (meta != null && activeProfileId == profileId) deletionNotifier.notifyDeletedItem(meta, isDownloadOnly = true)
                changed = true
                continue
            }
            // The last owner stays recorded until the files are gone, so a retry can finish the cleanup.
            val finalOwner = library.getDownloadOwner(profileId, globalKey)
            manager.deleteDownload(globalKey)
            releaseDownloadForProfile(globalKey, profileId, ownerHint = finalOwner)
            forget(globalKey)
            if (meta != null) deletionNotifier.notifyDeletedItem(meta, isDownloadOnly = true)
            changed = true
        }
        if (changed) notifyChanged()
    }

    private fun forget(globalKey: String) {
        downloadsMap -= globalKey
        metadataMap -= globalKey
        artworkPaths -= globalKey
        downloadLibraries -= globalKey
    }

    // endregion

    // region loading

    private suspend fun loadProfileScopedState() {
        loadDownloadOwners()
        loadSyncRules()
    }

    private suspend fun loadPersistedDownloads() {
        try {
            manager.awaitRecovery()
            downloadsMap.clear()
            artworkPaths.clear()
            metadataMap.clear()
            queueing.clear()
            deletionProgress.clear()
            ownedDownloadKeys.clear()
            downloadLibraries.clear()
            loadDownloadOwners()
            val rows = manager.getAllDownloads()
            val pinned = manager.getAllPinnedMetadata(activeProfileId)
            for (row in rows) {
                downloadsMap[row.global_key] = row.toProgress()
                artworkPaths[row.global_key] = row.thumb_path
                downloadLibraries[row.global_key] = LibraryStamp(row.library_id, row.library_title)
                if (owns(row.global_key)) hydrateDownloadMetadata(row.global_key, pinned)
            }
            loadSyncRules()
            loadDownloadCollections(pinned)
            applyOfflineWatchOverlay()
            Log.i(TAG) { "Loaded ${downloadsMap.size} downloads, ${metadataMap.size} metadata entries, and ${syncRulesMap.size} sync rules" }
            notifyChanged()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Failed to load persisted downloads" }
        }
    }

    private fun Downloaded_media.toProgress() = DownloadProgress(
        globalKey = global_key,
        status = DownloadedMediaStatus.of(status) ?: DownloadedMediaStatus.FAILED,
        progress = progress.toInt(),
        downloadedBytes = downloaded_bytes,
        totalBytes = total_bytes ?: 0,
        errorMessage = error_message,
        downloadedAt = downloaded_at,
    )

    private suspend fun applyOfflineWatchOverlay(expectedProfileGeneration: Int? = null) {
        metadataStore.hydrateOfflineWatchOverlay(
            if (expectedProfileGeneration == null) null else ({ disposed || expectedProfileGeneration != profileGeneration }),
        )
    }

    /**
     * Rebuilds the collection folders from the profile's stored membership and the collections' pinned metadata; a
     * collection known only from the previous view keeps that metadata, one with neither waits for the next refresh.
     */
    private suspend fun loadDownloadCollections(pinned: PinnedDownloadMetadata) {
        val profileId = activeProfileId
        val generation = profileGeneration
        val stored = if (profileId == null) emptyList() else collectionRepository.collections(profileId)
        if (generation != profileGeneration) return
        val loaded = collections.toMap()
        collections.clear()
        for (entry in stored) {
            val serverId = ServerId.tryParse(entry.serverId) ?: continue
            val scopeId = pinned.scopesByServer[entry.serverId]?.let(ServerId::tryParse)
            val globalKey = buildGlobalKey(serverId, entry.collectionId)
            val cached = scopeId?.let { pinned.items[buildGlobalKey(it, entry.collectionId)] }
                ?: pinned.items[globalKey]
                ?: loaded[globalKey]?.collection
            if (cached != null) putDownloadedCollection(entry.serverId, cached, entry.memberIds)
        }
    }

    private fun putDownloadedCollection(serverId: String, collection: MediaItem, memberIds: List<String>) {
        val withServer = if (collection.serverId == null) collection.copy(serverId = serverId) else collection
        val globalKey = buildGlobalKey(ServerId(serverId), withServer.id)
        collections[globalKey] = DownloadedCollection(withServer, memberIds)
        artworkPaths[globalKey] = withServer.thumbPath
    }

    private suspend fun hydrateDownloadMetadata(
        globalKey: String,
        pinned: PinnedDownloadMetadata,
        fetchOnMiss: Boolean = false,
        isStale: (() -> Boolean)? = null,
    ): HydrationResult {
        val (serverId, itemId) = parseGlobalKey(globalKey) ?: return HydrationResult(null, false, false)
        // A user-scoped server's rows are keyed by its scope: the profile's own namespace first, then the public key,
        // then the per-item lookup (which also finds cached rows that are not pinned).
        val clientScopeId = pinned.scopesByServer[serverId.value]
        var cached = clientScopeId?.let(ServerId::tryParse)?.let { pinned.items[buildGlobalKey(it, itemId)] }
            ?: pinned.items[globalKey]
            ?: manager.lookupMetadata(serverId, itemId, preferActiveScope = true, activeProfileId = activeProfileId)
        if (isStale?.invoke() == true) return HydrationResult(null, false, true)
        var networkFilled = false
        if (cached == null && fetchOnMiss && globalKey in downloadsMap) {
            cached = manager.fetchAndPinMetadata(serverId, itemId, preferActiveScope = true, activeProfileId = activeProfileId)
            if (isStale?.invoke() == true) return HydrationResult(null, false, true)
            networkFilled = cached != null
        }
        if (cached == null) {
            // Parents can be shared by downloaded siblings: a missing leaf drops only itself.
            metadataMap -= globalKey
            return HydrationResult(null, false, false)
        }
        val stamp = downloadLibraries[globalKey]
        if (stamp != null && (stamp.libraryId != null || stamp.libraryTitle != null) && (cached.libraryId == null || cached.libraryTitle == null)) {
            cached = cached.copy(libraryId = cached.libraryId ?: stamp.libraryId, libraryTitle = cached.libraryTitle ?: stamp.libraryTitle)
        }
        metadataMap[globalKey] = cached
        if (cached.isEpisode || cached.isTrack) metadataStore.loadParentMetadataFromMap(cached, pinned.items, clientScopeId)
        return HydrationResult(cached, networkFilled, false)
    }

    private suspend fun loadSyncRules() {
        try {
            val profileId = activeProfileId
            if (profileId.isNullOrEmpty()) {
                syncRulesMap.clear()
                return
            }
            syncRuleRepository.adoptLegacyRulesForProfile(profileId)
            if (activeProfileId != profileId) return
            val rules = syncRuleRepository.rules(profileId)
            if (activeProfileId != profileId) return
            syncRulesMap.clear()
            rules.associateByTo(syncRulesMap) { it.globalKey }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to load sync rules" }
        }
    }

    private suspend fun loadDownloadOwners() {
        try {
            val profileId = activeProfileId
            val generation = profileGeneration
            if (profileId.isNullOrEmpty()) {
                ownedDownloadKeys.clear()
                return
            }
            val isStillActive = { activeProfileId == profileId && profileGeneration == generation }
            library.adoptLegacyDownloadsForProfile(profileId, isStillActive)
            manager.adoptTransferredPlexMetadataForProfile(profileId, isStillActive)
            if (!isStillActive()) return
            val owned = library.getDownloadOwnerKeysForProfile(profileId)
            if (!isStillActive()) return
            ownedDownloadKeys.clear()
            ownedDownloadKeys += owned
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to load download ownership" }
        }
    }

    /** Reloads every download and its metadata from the database and cache. */
    suspend fun refresh() = loadPersistedDownloads()

    /**
     * Reloads the profile's downloaded metadata from the cache (after a watch-state sync), fetching and pinning what
     * the cache misses, then reapplies the queued offline watch actions.
     */
    suspend fun refreshMetadataFromCache() {
        val generation = profileGeneration
        val isStale = { disposed || generation != profileGeneration }
        ensureInitialized()
        if (isStale()) return
        val keys = downloadsMap.keys.filter(::owns)
        if (keys.isEmpty()) {
            applyOfflineWatchOverlay(generation)
            return
        }
        val pinned = manager.getAllPinnedMetadata(activeProfileId)
        if (isStale()) return
        var updated = 0
        for (globalKey in keys) {
            try {
                val result = hydrateDownloadMetadata(globalKey, pinned, fetchOnMiss = true, isStale = isStale)
                if (result.stale) return
                if (result.metadata != null) updated++
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Failed to refresh metadata for $globalKey" }
            }
        }
        loadDownloadCollections(pinned)
        if (isStale()) return
        applyOfflineWatchOverlay(generation)
        if (isStale()) return
        if (updated > 0) notifyChanged()
    }

    // endregion

    // region progress

    internal fun onProgressUpdate(progress: DownloadProgress) {
        val previous = downloadsMap[progress.globalKey]
        val terminalOmittedBytes = previous != null && progress.downloadedBytes == 0L && previous.downloadedBytes > 0 &&
            progress.status in TERMINAL_STATUSES
        // Terminal status-only events carry no byte counters: keep the last ones. Live progress and retry resets win.
        val merged = if (terminalOmittedBytes) {
            progress.copy(
                progress = if (progress.progress == 0) previous.progress else progress.progress,
                downloadedBytes = previous.downloadedBytes,
                totalBytes = if (progress.totalBytes == 0L) previous.totalBytes else progress.totalBytes,
            )
        } else {
            progress
        }
        // Entering completed stamps the time (a re-download earns a fresh one); later events carry it on.
        val downloadedAt = merged.downloadedAt
            ?: if (merged.status == DownloadedMediaStatus.COMPLETED && previous?.status != DownloadedMediaStatus.COMPLETED) clock() else previous?.downloadedAt
        downloadsMap[progress.globalKey] = merged.copy(downloadedAt = downloadedAt)
        if (merged.hasArtworkPaths) artworkPaths[merged.globalKey] = merged.thumbPath
        val completedChanged = (previous?.status == DownloadedMediaStatus.COMPLETED) != (merged.status == DownloadedMediaStatus.COMPLETED)
        if (owns(progress.globalKey)) notifyChanged(completedChanged)
    }

    private fun onDeletionProgressUpdate(progress: DeletionProgress) {
        if (progress.isComplete) deletionProgress -= progress.globalKey else deletionProgress[progress.globalKey] = progress
        if (batchDeletionDepth == 0 && owns(progress.globalKey)) notifyChanged()
    }

    fun getDeletionProgress(globalKey: String): DeletionProgress? = deletionProgress[globalKey]

    /** The progress [getProgress] reports for [globalKey], now and on every change. */
    fun progressFlow(globalKey: String): Flow<DownloadProgress?> = _changes.map { getProgress(globalKey) }.distinctUntilChanged()

    /** Diagnostics' view of transfer activity, every profile's rows included. */
    fun downloadActivitySnapshot(): DownloadActivitySnapshot {
        var active = 0
        var completed = 0
        var failed = 0
        var bytes = 0L
        var units = 0
        for (progress in downloadsMap.values) {
            when (progress.status) {
                DownloadedMediaStatus.DOWNLOADING -> active++
                DownloadedMediaStatus.COMPLETED -> completed++
                DownloadedMediaStatus.FAILED -> failed++
                else -> Unit
            }
            bytes += progress.downloadedBytes
            units += progress.progress
        }
        return DownloadActivitySnapshot(active, completed, failed, bytes, units, offlineSource?.let { !it.isOffline.value }, networkStateGeneration)
    }

    // endregion

    // region reads

    /** The active profile's downloads by global key. */
    val downloads: Map<String, DownloadProgress> get() = downloadsMap.filterKeys(::owns)

    /** The active profile's downloaded metadata, watch state applied. */
    val metadata: Map<String, MediaItem> get() = metadataStore.resolvedItems

    val hasFailedDownloads: Boolean get() = downloadsMap.any { (key, p) -> p.status == DownloadedMediaStatus.FAILED && owns(key) }

    val failedDownloadKeys: List<String> get() = downloadsMap.filter { (key, p) -> p.status == DownloadedMediaStatus.FAILED && owns(key) }.keys.toList()

    fun getMetadata(globalKey: String): MediaItem? = metadataStore.resolved(globalKey)

    /** The artwork storage key (thumb path) of a download, for offline display. */
    fun getArtworkPath(globalKey: String): String? = artworkPaths[globalKey]

    /** The local file of an artwork path stored for [serverId]'s downloads, or null when not stored. */
    fun getArtworkLocalPath(serverId: ServerId, artworkPath: String?): String? = artwork.localPathSync(serverId, artworkPath)

    private fun completed(globalKey: String) = downloadsMap[globalKey]?.status == DownloadedMediaStatus.COMPLETED

    /**
     * Sort extras for [items] from the download bookkeeping: a leaf its own row's; a show, season or album the newest
     * completion and summed size of its completed leaves.
     */
    fun downloadSortExtras(items: List<MediaItem>): Map<String, MediaItemSortExtras> {
        val extras = mutableMapOf<String, MediaItemSortExtras>()
        val containerKeys = items.filter { it.isShow || it.isSeason || it.kind == MediaKind.ALBUM }.mapTo(mutableSetOf()) { it.globalKey }
        fun accumulate(key: String, progress: DownloadProgress) {
            val existing = extras[key]
            val at = progress.downloadedAt
            extras[key] = MediaItemSortExtras(
                downloadedAt = if (at != null && at > (existing?.downloadedAt ?: 0)) at else existing?.downloadedAt,
                totalBytes = (existing?.totalBytes ?: 0) + progress.totalBytes,
            )
        }
        for ((globalKey, meta) in metadataMap) {
            if (!owns(globalKey)) continue
            val progress = downloadsMap[globalKey]?.takeIf { it.status == DownloadedMediaStatus.COMPLETED } ?: continue
            val serverId = ServerId.tryParse(meta.serverId) ?: continue
            accumulate(globalKey, progress)
            if (containerKeys.isEmpty()) continue
            val parents = when {
                meta.isEpisode -> listOfNotNull(meta.grandparentId, meta.parentId?.takeIf { it.isNotEmpty() })
                meta.isTrack -> listOfNotNull(meta.parentId)
                else -> emptyList()
            }
            for (id in parents) {
                val key = buildGlobalKey(serverId, id)
                if (key in containerKeys) accumulate(key, progress)
            }
        }
        return extras
    }

    /** One item per show with completed owned episodes: its stored row, else one made from an episode. */
    val downloadedShows: List<MediaItem>
        get() = downloadedContainers(
            isLeaf = { it.isEpisode },
            containerIdOf = { it.grandparentId },
            containerKind = MediaKind.SHOW,
            synthesize = { meta, showId ->
                MediaItem(
                    id = showId,
                    backend = meta.backend,
                    kind = MediaKind.SHOW,
                    title = meta.grandparentTitle ?: T.common.unknown,
                    thumbPath = meta.grandparentThumbPath,
                    artPath = meta.grandparentArtPath,
                    serverId = meta.serverId,
                )
            },
            finish = ::withDownloadedLeafCounts,
        )

    private fun downloadedContainers(
        isLeaf: (MediaItem) -> Boolean,
        containerIdOf: (MediaItem) -> String?,
        containerKind: MediaKind,
        synthesize: (MediaItem, String) -> MediaItem,
        finish: (MediaItem, List<MediaItem>) -> MediaItem,
    ): List<MediaItem> {
        val containers = LinkedHashMap<String, MediaItem>()
        val leaves = mutableMapOf<String, MutableList<MediaItem>>()
        for ((globalKey, raw) in metadataMap) {
            if (!owns(globalKey) || !completed(globalKey)) continue
            val meta = metadataStore.applyWatchState(raw)
            if (!isLeaf(meta)) continue
            val containerId = containerIdOf(meta) ?: continue
            val serverId = ServerId.tryParse(meta.serverId) ?: continue
            val containerKey = buildGlobalKey(serverId, containerId)
            leaves.getOrPut(containerKey) { mutableListOf() } += meta
            if (containerKey in containers) continue
            val stored = metadataStore.resolved(containerKey)
            containers[containerKey] = if (stored != null && stored.kind == containerKind) stored else synthesize(meta, containerId)
        }
        return containers.map { (key, container) -> finish(container, leaves.getValue(key)) }
    }

    private fun withLibraryFallback(target: MediaItem, sources: List<MediaItem>): MediaItem {
        var libraryId = target.libraryId
        var libraryTitle = target.libraryTitle
        for (source in sources) {
            if (libraryId != null && libraryTitle != null) break
            libraryId = libraryId ?: source.libraryId
            libraryTitle = libraryTitle ?: source.libraryTitle
        }
        if (libraryId == target.libraryId && libraryTitle == target.libraryTitle) return target
        return target.copy(libraryId = libraryId, libraryTitle = libraryTitle)
    }

    private fun withDownloadedLeafCounts(container: MediaItem, episodes: List<MediaItem>): MediaItem =
        withLibraryFallback(container, episodes).copy(leafCount = episodes.size, viewedLeafCount = episodes.count { it.isWatched })

    /** Completed owned episodes, watch state applied, library inherited from the stored show row. */
    val downloadedEpisodes: List<MediaItem> get() = completedLeaves({ it.isEpisode }) { storedContainerFor(it, it.grandparentId) }

    /** Completed owned tracks, watch state applied, library inherited from the stored album row. */
    val downloadedTracks: List<MediaItem> get() = completedLeaves({ it.isTrack }) { storedContainerFor(it, it.parentId) }

    private fun completedLeaves(isLeaf: (MediaItem) -> Boolean, containerOf: (MediaItem) -> MediaItem?): List<MediaItem> =
        metadataMap.mapNotNull { (key, raw) ->
            if (!owns(key) || !completed(key) || !isLeaf(raw)) return@mapNotNull null
            val leaf = metadataStore.applyWatchState(raw)
            withLibraryFallback(leaf, listOfNotNull(containerOf(leaf)))
        }

    private fun storedContainerFor(leaf: MediaItem, containerId: String?): MediaItem? {
        val serverId = ServerId.tryParse(leaf.serverId) ?: return null
        return containerId?.let { metadataStore.resolved(buildGlobalKey(serverId, it)) }
    }

    /** Seasons with downloaded episodes across every show, by season number; counts from the downloaded episodes. */
    val downloadedSeasons: List<MediaItem> get() = downloadedSeasons(null)

    /** Seasons with downloaded episodes of the show [showKey] (a global key, or a bare id matching any server). */
    fun downloadedSeasonsForShow(showKey: String, showFallback: MediaItem? = null): List<MediaItem> = downloadedSeasons(showKey, showFallback)

    private fun downloadedSeasons(showKey: String?, showFallback: MediaItem? = null): List<MediaItem> {
        val parsed = showKey?.let(::parseGlobalKey)
        val episodes = downloadedEpisodes.filter { episode ->
            when {
                showKey == null -> true
                parsed != null -> episode.serverId == parsed.first.value && episode.grandparentId == parsed.second
                else -> episode.grandparentId == showKey
            }
        }
        // Grouped by the season id, else the season number, always within one server and show.
        val bySeason = LinkedHashMap<String, MutableList<MediaItem>>()
        for (episode in episodes) {
            val seasonId = episode.parentId
            val key = if (!seasonId.isNullOrEmpty()) {
                "${episode.serverId}:${episode.grandparentId}:$seasonId"
            } else {
                "${episode.serverId}:${episode.grandparentId}#${episode.parentIndex ?: 0}"
            }
            bySeason.getOrPut(key) { mutableListOf() } += episode
        }
        val fallback = showFallback?.takeIf { it.libraryId != null || it.libraryTitle != null }
        return bySeason.values
            .map { downloadedSeasonItem(it, fallback ?: storedContainerFor(it.first(), it.first().grandparentId)) }
            .sortedBy { it.index ?: 0 }
    }

    private fun downloadedSeasonItem(episodes: List<MediaItem>, libraryFallback: MediaItem?): MediaItem {
        val first = episodes.first()
        val seasonIndex = first.parentIndex ?: 0
        val seasonId = first.parentId.orEmpty()
        val stored = ServerId.tryParse(first.serverId)?.takeIf { seasonId.isNotEmpty() }?.let { metadataStore.resolved(buildGlobalKey(it, seasonId)) }
        val base = if (stored != null && stored.isSeason) {
            stored.copy(serverId = first.serverId, serverName = first.serverName ?: stored.serverName)
        } else {
            MediaItem(
                id = seasonId.ifEmpty { "${first.grandparentId}#s$seasonIndex" },
                backend = first.backend,
                kind = MediaKind.SEASON,
                title = first.parentTitle?.takeIf { it.isNotEmpty() } ?: T.common.seasonNumber(number = seasonIndex.toString()),
                index = seasonIndex,
                thumbPath = first.parentThumbPath,
                parentId = first.grandparentId,
                parentTitle = first.grandparentTitle,
                serverId = first.serverId,
                serverName = first.serverName,
            )
        }
        return withDownloadedLeafCounts(
            base,
            episodes.map {
                it.copy(libraryId = it.libraryId ?: libraryFallback?.libraryId, libraryTitle = it.libraryTitle ?: libraryFallback?.libraryTitle)
            },
        )
    }

    /** Distinct libraries of the completed owned downloads, by title, server and library id. */
    val downloadedLibraries: List<DownloadedLibrary>
        get() {
            val seen = LinkedHashMap<String, DownloadedLibrary>()
            for ((key, meta) in metadataMap) {
                if (!owns(key) || !completed(key)) continue
                val serverId = meta.serverId ?: continue
                seen.getOrPut("$serverId:${meta.libraryId}") {
                    DownloadedLibrary(serverId, meta.libraryId, meta.libraryTitle ?: meta.serverName ?: T.common.unknown)
                }
            }
            return seen.values.sortedWith(compareBy<DownloadedLibrary> { it.title }.thenBy { it.serverId }.thenBy { it.libraryId.orEmpty() })
        }

    val downloadedMovies: List<MediaItem>
        get() = metadataMap.filter { (key, meta) -> owns(key) && completed(key) && meta.isMovie }.values.map(metadataStore::applyWatchState)

    /** [items] with each collection holding two or more of them folded into one folder item. */
    fun groupDownloadsByCollection(items: List<MediaItem>): List<MediaItem> = groupByDownloadedCollection(items, collections.values)

    /** The downloaded movies and shows of the collection [collectionGlobalKey], in the collection's order. */
    fun downloadedCollectionItems(collectionGlobalKey: String): List<MediaItem> {
        val entry = collections[collectionGlobalKey] ?: return emptyList()
        val serverId = ServerId.tryParse(entry.collection.serverId) ?: return emptyList()
        val titles = (downloadedMovies + downloadedShows).associateBy { it.globalKey }
        return entry.memberIds.mapNotNull { titles[buildGlobalKey(serverId, it)] }
    }

    /** Albums with completed owned tracks, by album artist then title; library inherited from the tracks. */
    val downloadedAlbums: List<MediaItem>
        get() = downloadedContainers(
            isLeaf = { it.isTrack },
            containerIdOf = { it.parentId },
            containerKind = MediaKind.ALBUM,
            synthesize = { meta, albumId ->
                MediaItem(
                    id = albumId,
                    backend = meta.backend,
                    kind = MediaKind.ALBUM,
                    title = meta.albumTitle ?: T.common.unknown,
                    parentId = meta.grandparentId,
                    parentTitle = meta.grandparentTitle,
                    thumbPath = meta.parentThumbPath ?: meta.thumbPath,
                    serverId = meta.serverId,
                )
            },
            finish = ::withLibraryFallback,
        ).sortedWith(compareBy<MediaItem> { it.albumArtistTitle.orEmpty() }.thenBy { it.title.orEmpty() })

    /** The album's completed tracks by disc then track number: its offline play queue. */
    fun getDownloadedTracksForAlbum(albumGlobalKey: String): List<MediaItem> {
        val (serverId, albumId) = parseGlobalKey(albumGlobalKey) ?: return emptyList()
        return completedTracksByAlbum()[serverId.value to albumId].orEmpty().map(metadataStore::applyWatchState)
    }

    /** The completed owned tracks by (server, album), in disc and track order; regrouped once per [completedVersion]. */
    private fun completedTracksByAlbum(): Map<Pair<String?, String?>, List<MediaItem>> {
        albumTracks?.takeIf { it.first == completedVersion }?.let { return it.second }
        val grouped = metadataMap.filter { (key, meta) -> owns(key) && meta.isTrack && completed(key) }.values
            .groupBy { it.serverId to it.parentId }
            .mapValues { (_, tracks) -> tracks.sortedWith(compareBy<MediaItem> { it.discNumber ?: 1 }.thenBy { it.trackNumber ?: 0 }) }
        albumTracks = completedVersion to grouped
        return grouped
    }

    /** The show's completed owned episodes, any order. */
    fun getDownloadedEpisodesForShow(showGlobalKey: String): List<MediaItem> {
        val (serverId, showId) = parseGlobalKey(showGlobalKey) ?: return emptyList()
        return metadataMap
            .filter { (key, meta) -> owns(key) && completed(key) && meta.isEpisode && meta.serverId == serverId.value && meta.grandparentId == showId }
            .values.map(metadataStore::applyWatchState)
    }

    private fun leafDownloads(serverId: ServerId, grandparentId: String? = null, parentId: String? = null): List<DownloadProgress> =
        downloadsMap.filter { (key, _) ->
            if (!owns(key)) return@filter false
            val meta = metadataMap[key] ?: return@filter false
            (meta.isEpisode || meta.isTrack) && meta.serverId == serverId.value &&
                (grandparentId == null || meta.grandparentId == grandparentId) &&
                (parentId == null || meta.parentId == parentId)
        }.values.toList()

    fun getAggregateProgressForShow(serverId: ServerId, showId: String) = aggregateProgress(serverId, showId, leafDownloads(serverId, grandparentId = showId), music = false)

    fun getAggregateProgressForSeason(serverId: ServerId, seasonId: String) = aggregateProgress(serverId, seasonId, leafDownloads(serverId, parentId = seasonId), music = false)

    fun getAggregateProgressForAlbum(serverId: ServerId, albumId: String) = aggregateProgress(serverId, albumId, leafDownloads(serverId, parentId = albumId), music = true)

    fun getAggregateProgressForArtist(serverId: ServerId, artistId: String) = aggregateProgress(serverId, artistId, leafDownloads(serverId, grandparentId = artistId), music = true)

    /**
     * A container's progress over the leaves the profile queued under it (5 of a 50-episode show reach 100% at 5/5):
     * completed when all are, partial when some are and none is moving, else downloading, queued, failed. The percent
     * averages the leaves (completed = 100) and stays below 100 until every leaf completes.
     */
    private fun aggregateProgress(serverId: ServerId, id: String, leaves: List<DownloadProgress>, music: Boolean): DownloadProgress? {
        val total = leaves.size
        if (total == 0) return null
        val counts = leaves.groupingBy { it.status }.eachCount()
        val completedCount = counts[DownloadedMediaStatus.COMPLETED] ?: 0
        val downloading = counts[DownloadedMediaStatus.DOWNLOADING] ?: 0
        val queued = counts[DownloadedMediaStatus.QUEUED] ?: 0
        val failed = counts[DownloadedMediaStatus.FAILED] ?: 0
        val status = when {
            completedCount == total -> DownloadedMediaStatus.COMPLETED
            completedCount > 0 && downloading == 0 && queued == 0 -> DownloadedMediaStatus.PARTIAL
            downloading > 0 -> DownloadedMediaStatus.DOWNLOADING
            queued > 0 -> DownloadedMediaStatus.QUEUED
            failed > 0 -> DownloadedMediaStatus.FAILED
            else -> return null
        }
        val summed = leaves.sumOf { if (it.status == DownloadedMediaStatus.COMPLETED) 100 else it.progress }
        val raw = (summed.toDouble() / total).roundToInt()
        return DownloadProgress(
            globalKey = buildGlobalKey(serverId, id),
            status = status,
            progress = if (completedCount == total) 100 else raw.coerceAtMost(99),
            currentFile = "$completedCount/$total ${if (music) "tracks" else "episodes"}",
        )
    }

    /** A movie's, episode's or track's own progress; a show's, season's, album's or artist's aggregate. Owned only. */
    fun getProgress(globalKey: String): DownloadProgress? {
        downloadsMap[globalKey]?.let { return if (owns(globalKey)) it else null }
        val (serverId, id) = parseGlobalKey(globalKey) ?: return null
        val meta = metadataMap[globalKey]
            ?: return leafDownloads(serverId, grandparentId = id).ifEmpty { leafDownloads(serverId, parentId = id) }
                .takeIf { it.isNotEmpty() }?.let { aggregateProgress(serverId, id, it, music = false) }
        return when (meta.kind) {
            MediaKind.SHOW -> getAggregateProgressForShow(serverId, id)
            MediaKind.SEASON -> getAggregateProgressForSeason(serverId, id)
            MediaKind.ALBUM -> getAggregateProgressForAlbum(serverId, id)
            MediaKind.ARTIST -> getAggregateProgressForArtist(serverId, id)
            else -> null
        }
    }

    fun isDownloaded(globalKey: String) = getProgress(globalKey)?.status == DownloadedMediaStatus.COMPLETED

    fun isDownloading(globalKey: String) = getProgress(globalKey)?.status == DownloadedMediaStatus.DOWNLOADING

    fun isQueued(globalKey: String) = getProgress(globalKey)?.status == DownloadedMediaStatus.QUEUED

    /** Whether [globalKey] is being expanded into its downloads right now. */
    fun isQueueing(globalKey: String) = globalKey in queueing

    /** The completed row of an owned download (its version on disk), or null. */
    internal suspend fun getCompletedDownload(globalKey: String): Downloaded_media? {
        if (!owns(globalKey)) return null
        return manager.getDownloadedMedia(globalKey)?.takeIf { it.status == DownloadedMediaStatus.COMPLETED.code }
    }

    /**
     * The local file of an owned completed download: the version [mediaSourceId], else [mediaIndex] (null: any).
     * Null when not downloaded or the file is unreachable.
     */
    suspend fun getVideoFilePath(globalKey: String, mediaIndex: Int? = null, mediaSourceId: String? = null): String? {
        if (!owns(globalKey)) return null
        val (serverId, itemId) = parseGlobalKey(globalKey) ?: return null
        return videoSource.resolve(serverId, itemId, mediaIndex, mediaSourceId, allowAnyVersion = false)?.path
    }

    /** The cached metadata of an item, read through the active profile's own scope (never a download creator's). */
    suspend fun lookupOfflineMetadata(serverId: ServerId, itemId: String): MediaItem? =
        manager.lookupMetadata(serverId, itemId, preferActiveScope = true, activeProfileId = activeProfileId)

    // endregion

    // region queueing

    private suspend fun ensureNotCellularBlocked() {
        if (manager.shouldBlockDownloadOnCellularWith(connectivity())) throw CellularDownloadBlockedException()
    }

    /**
     * Queues [item]: a movie, episode or track directly; a show or season as its episodes ([filter], [maxCount],
     * Specials per [includeSpecials]); an album or artist as its tracks. Returns how many items were queued; 0 while
     * the same key is still being expanded. Throws [CellularDownloadBlockedException] when Wi-Fi-only blocks it.
     */
    suspend fun queueDownload(
        item: MediaItem,
        client: MediaBackend,
        versionConfig: DownloadVersionConfig? = null,
        filter: DownloadFilter = DownloadFilter.ALL,
        maxCount: Int? = null,
        includeSpecials: Boolean = true,
    ): Int {
        if (!manager.downloadsSupported) return 0
        val ownership = captureQueueOwnership()
        val globalKey = item.globalKey
        val config = versionConfig ?: DownloadVersionConfig()
        if (globalKey in queueing) return 0
        // Claimed before the first suspension, and held while the permission prompt is open, so a second tap
        // cannot start a duplicate expansion.
        queueing[globalKey] = ownership
        notifyChanged()
        try {
            ensureNotCellularBlocked()
            if (!isCurrent(ownership)) return 0
            notificationPermission.ensure()
            if (!isCurrent(ownership)) return 0
            manager.beginUserDownloadRequest()
            return when (item.kind) {
                MediaKind.MOVIE, MediaKind.EPISODE, MediaKind.TRACK ->
                    if (queueSingleDownload(item, client, ownership, mediaIndex = config.mediaIndex, quality = config.quality)) 1 else 0
                MediaKind.ALBUM, MediaKind.ARTIST ->
                    withStashedMetadata(item, ownership) { queueMusicContainerDownload(item, client, ownership) }
                MediaKind.SHOW, MediaKind.SEASON -> withStashedMetadata(item, ownership) {
                    expandAndQueue(item, client, ownership, config, filter, maxCount, skipExisting = false, includeSpecials = includeSpecials)
                }
                else -> throw IllegalArgumentException("Cannot download ${item.kind.id}")
            }
        } finally {
            if (queueing[globalKey] == ownership) {
                queueing -= globalKey
                notifyChanged()
            }
        }
    }

    private suspend fun <T> withStashedMetadata(item: MediaItem, ownership: QueueOwnership, operation: suspend () -> T): T {
        check(isCurrent(ownership)) { "Queue ownership is stale" }
        val globalKey = item.globalKey
        val previous = metadataMap[globalKey]
        metadataMap[globalKey] = item
        try {
            return operation()
        } catch (e: Throwable) {
            if (isCurrent(ownership)) {
                if (previous == null) metadataMap -= globalKey else metadataMap[globalKey] = previous
            }
            throw e
        }
    }

    /**
     * Queues every playable leaf of a collection's or playlist's [items] (expanded like the list sync rule). With
     * [syncRule], the list's whole membership (not only what this pass queues) is linked to the rule.
     */
    suspend fun queueListDownload(
        items: List<MediaItem>,
        client: MediaBackend,
        filter: DownloadFilter = DownloadFilter.ALL,
        syncRule: SyncRule? = null,
    ): Int {
        if (!manager.downloadsSupported) return 0
        val ownership = captureQueueOwnership()
        ensureNotCellularBlocked()
        if (!isCurrent(ownership)) return 0
        manager.beginUserDownloadRequest()
        val unwatchedOnly = filter == DownloadFilter.UNWATCHED
        val membership = mutableListOf<MediaItem>()
        val candidates = mutableListOf<MediaItem>()
        // One entry at a time, so a cancelled queue stops before the next container is fetched.
        for (item in items) {
            if (!isCurrent(ownership)) return 0
            val leaves = collectListLeaves(client, listOf(item), unwatchedOnly, specialsOrdering())
            candidates += leaves
            if (syncRule != null) {
                membership += if (unwatchedOnly) collectListLeaves(client, listOf(item), false, specialsOrdering()) else leaves
            }
        }
        if (!isCurrent(ownership)) return 0
        if (syncRule != null) {
            for (item in membership) {
                val key = ensureServerId(item, client.serverId.value).globalKey
                if (hasActiveOwnedDownload(key)) associateSyncRuleDownload(syncRule, key, ownership)
            }
        }
        val context = RelatedMetadataContext()
        var count = 0
        for (item in candidates) {
            if (!isCurrent(ownership)) return count
            val withServer = ensureServerId(item, client.serverId.value)
            if (hasActiveOwnedDownload(withServer.globalKey)) continue
            val queued = queueSingleDownload(withServer, client, ownership, relatedContext = context)
            if (syncRule != null) associateSyncRuleDownload(syncRule, withServer.globalKey, ownership)
            if (queued) count++
        }
        if (syncRule != null && isCurrent(ownership)) markSyncRuleDownloadLinksInitialized(syncRule.globalKey)
        return count
    }

    private fun ensureServerId(item: MediaItem, fallback: String?) = if (item.serverId != null) item else item.copy(serverId = fallback)

    /**
     * Queues one movie, episode or track at [quality]; whether it was queued (or an existing download claimed). An
     * [automatic] one (a sync rule's) is not queued while a storage failure stops downloads: its failed row keeps the
     * storage error.
     */
    private suspend fun queueSingleDownload(
        item: MediaItem,
        client: MediaBackend,
        ownership: QueueOwnership,
        mediaIndex: Int = 0,
        versionConfig: DownloadVersionConfig? = null,
        relatedContext: RelatedMetadataContext? = null,
        quality: TranscodeQualityPreset = versionConfig?.quality ?: TranscodeQualityPreset.ORIGINAL,
        automatic: Boolean = false,
    ): Boolean {
        if (!manager.downloadsSupported || !isCurrent(ownership)) return false
        if (automatic && manager.queueBlockedByStorageFailure) return false
        var toStore = if (item.serverId == null) item.copy(serverId = client.serverId.value) else item
        val globalKey = toStore.globalKey

        // One physical download per item: an active one is claimed for this profile instead of queued again.
        val existing = downloadsMap[globalKey]
        if (existing != null && SyncRuleExecutor.isActiveDownload(existing.status)) {
            try {
                manager.saveMetadata(toStore, client)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Claiming must work offline too; the cache enrichment is best effort.
                Log.w(TAG, e) { "Failed to pin metadata while claiming $globalKey" }
            }
            if (!isCurrent(ownership)) return false
            val claimed = claimDownloadForProfile(globalKey, ownership, client)
            if (!isCurrent(ownership)) return false
            if (claimed) {
                hydrateClaimedDownload(toStore, client, ownership, relatedContext)
                if (!isCurrent(ownership)) return false
                notifyChanged()
            }
            return claimed
        }

        // The full item carries the media parts a browse row lacks; offline, the partial item is queued and the
        // file resolves once back online.
        if (!isOffline) {
            try {
                client.fetchItem(item.id)?.let { toStore = mergeFetchedMediaItem(it, client.serverId, toStore) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to fetch full metadata for ${item.id}, using partial" }
            }
        }
        if (!isCurrent(ownership)) return false

        var resolvedIndex = mediaIndex
        var config = versionConfig
        if (config != null && config.acceptedSignatures.isNotEmpty()) {
            val versions = toStore.mediaVersions
            if (!versions.isNullOrEmpty()) {
                val matched = MediaVersion.findMatchingIndex(versions, config.acceptedSignatures)
                if (matched != null) {
                    resolvedIndex = matched
                } else if (config.onVersionMismatch != null) {
                    val picked = config.onVersionMismatch(toStore, versions)
                    if (!isCurrent(ownership) || picked == null) return false
                    resolvedIndex = picked
                    acceptedSignatureAdditions[config] = (acceptedSignatureAdditions[config] ?: emptySet()) + versions[picked].signature
                }
            }
        }

        if (toStore.isEpisode || toStore.isTrack) {
            fetchAndStoreParentMetadata(toStore, client, ownership, relatedContext ?: RelatedMetadataContext())
            if (!isCurrent(ownership)) return false
        }
        // The stop may have tripped during the metadata work above.
        if (automatic && manager.queueBlockedByStorageFailure) return false
        metadataMap[globalKey] = toStore
        claimDownloadForProfile(globalKey, ownership, client)
        if (!isCurrent(ownership)) return false
        downloadsMap[globalKey] = DownloadProgress(globalKey, DownloadedMediaStatus.QUEUED)
        notifyChanged()
        val stored = manager.queueDownload(toStore, client, mediaIndex = resolvedIndex, transcodeQuality = quality)
        if (stored != toStore) metadataMap[globalKey] = stored
        if (stored.libraryId != null || stored.libraryTitle != null) downloadLibraries[globalKey] = LibraryStamp(stored.libraryId, stored.libraryTitle)
        if (stored.isMovie || stored.isEpisode) scope.launch { refreshCollections(client) }
        return true
    }

    /**
     * Signatures picked on a mismatch during one queue pass, so later episodes with the same version take it without
     * asking again.
     */
    private val acceptedSignatureAdditions = mutableMapOf<DownloadVersionConfig, Set<String>>()

    private fun DownloadVersionConfig.withAdditions() =
        acceptedSignatureAdditions[this]?.let { copy(acceptedSignatures = acceptedSignatures + it) } ?: this

    /** Loads a just-claimed download's metadata for the claiming profile, and an episode's or track's parents. */
    private suspend fun hydrateClaimedDownload(item: MediaItem, client: MediaBackend, ownership: QueueOwnership, context: RelatedMetadataContext?) {
        val globalKey = item.globalKey
        val hydration = hydrateDownloadMetadata(globalKey, PinnedDownloadMetadata(emptyMap(), emptyMap()), isStale = { !isCurrent(ownership) })
        if (hydration.stale) return
        val hydrated = hydration.metadata ?: item
        metadataMap[globalKey] = hydrated
        if (hydrated.isEpisode || hydrated.isTrack) {
            try {
                fetchAndStoreParentMetadata(hydrated, client, ownership, context ?: RelatedMetadataContext())
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // The claim is durable already; the parents are best effort.
                Log.w(TAG, e) { "Failed to load parent metadata while claiming $globalKey" }
            }
        }
        if (hydrated.isMovie || hydrated.isEpisode) scope.launch { refreshCollections(client) }
    }

    private suspend fun fetchAndStoreParentMetadata(leaf: MediaItem, client: MediaBackend, ownership: QueueOwnership, context: RelatedMetadataContext) {
        val serverId = ServerId.tryParse(leaf.serverId) ?: return
        fetchAndStoreRelatedMetadata(serverId, leaf.grandparentId, client, ownership, context)
        if (!isCurrent(ownership)) return
        fetchAndStoreRelatedMetadata(serverId, leaf.parentId, client, ownership, context)
    }

    /** Fetches, pins and stores the artwork of a show or season (artist or album), once per queue pass. */
    private suspend fun fetchAndStoreRelatedMetadata(
        serverId: ServerId,
        id: String?,
        client: MediaBackend,
        ownership: QueueOwnership,
        context: RelatedMetadataContext,
    ) {
        if (id == null || !isCurrent(ownership)) return
        val globalKey = buildGlobalKey(serverId, id)
        var meta = metadataMap[globalKey]
        var fresh = false
        if (!isOffline && globalKey !in context.hydratedMetadataKeys) {
            try {
                client.fetchItem(id)?.let {
                    meta = mergeFetchedMediaItem(it, serverId, meta)
                    context.hydratedMetadataKeys += globalKey
                    fresh = true
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to fetch metadata for $id" }
            }
        }
        val withServer = meta?.copy(serverId = serverId.value) ?: return
        if (!isCurrent(ownership)) return
        metadataMap[globalKey] = withServer
        manager.saveMetadata(withServer, client)
        if (!isCurrent(ownership)) return
        if (fresh || context.ensuredArtworkKeys.add(globalKey)) {
            manager.downloadArtworkForMetadata(withServer, client)
            if (!isCurrent(ownership)) return
        }
        artworkPaths[globalKey] = withServer.thumbPath
    }

    private suspend fun queueMusicContainerDownload(container: MediaItem, client: MediaBackend, ownership: QueueOwnership): Int {
        val tracks = client.fetchPlayableDescendants(container.id)
        if (!isCurrent(ownership)) return 0
        val context = RelatedMetadataContext()
        var count = 0
        for (track in tracks) {
            if (!isCurrent(ownership)) return count
            if (queueSingleDownload(ensureServerId(track, container.serverId), client, ownership, relatedContext = context)) count++
        }
        return count
    }

    /** Queues a show's or season's episodes the profile does not have yet (completed, downloading or queued). */
    suspend fun queueMissingEpisodes(item: MediaItem, client: MediaBackend, versionConfig: DownloadVersionConfig? = null): Int {
        require(item.isShow || item.isSeason) { "queueMissingEpisodes only supports shows/seasons" }
        manager.beginUserDownloadRequest()
        return expandAndQueue(item, client, captureQueueOwnership(), versionConfig, DownloadFilter.ALL, null, skipExisting = true)
    }

    private suspend fun expandAndQueue(
        container: MediaItem,
        client: MediaBackend,
        ownership: QueueOwnership,
        versionConfig: DownloadVersionConfig?,
        filter: DownloadFilter,
        maxCount: Int?,
        skipExisting: Boolean,
        includeSpecials: Boolean = true,
    ): Int {
        // Downloading the Specials season itself still takes its episodes.
        val withSpecials = includeSpecials || (container.isSeason && isSpecialSeasonNumber(container.index))
        val episodes = collectEpisodes(client, container.id, filter == DownloadFilter.UNWATCHED, specialsOrdering(), container, withSpecials)
        if (!isCurrent(ownership)) return 0
        val context = RelatedMetadataContext()
        var count = 0
        try {
            for (episode in episodes) {
                if (!isCurrent(ownership)) return count
                if (maxCount != null && count >= maxCount) break
                val withServer = ensureServerId(episode, container.serverId)
                if (skipExisting && owns(withServer.globalKey) &&
                    downloadsMap[withServer.globalKey]?.status in SKIP_EXISTING_STATUSES
                ) {
                    continue
                }
                if (queueSingleDownload(withServer, client, ownership, versionConfig = versionConfig?.withAdditions(), relatedContext = context)) count++
            }
        } finally {
            versionConfig?.let { acceptedSignatureAdditions -= it }
        }
        return count
    }

    // endregion

    // region actions

    private suspend fun whenOwnedIn(globalKey: String, statuses: Set<DownloadedMediaStatus>, action: suspend () -> Unit) {
        if (!owns(globalKey)) return
        if (downloadsMap[globalKey]?.status in statuses) action()
    }

    /** Pauses a downloading or queued download. */
    suspend fun pauseDownload(globalKey: String) =
        whenOwnedIn(globalKey, setOf(DownloadedMediaStatus.DOWNLOADING, DownloadedMediaStatus.QUEUED)) { manager.pauseDownload(globalKey) }

    suspend fun resumeDownload(globalKey: String, client: MediaBackend) =
        whenOwnedIn(globalKey, setOf(DownloadedMediaStatus.PAUSED)) { manager.resumeDownload(globalKey, client) }

    /** Retries a failed download; a repeat call while the retry is in flight does nothing. */
    suspend fun retryDownload(globalKey: String, client: MediaBackend) {
        if (!retryingKeys.add(globalKey)) return
        try {
            whenOwnedIn(globalKey, setOf(DownloadedMediaStatus.FAILED)) { retryOnManager(globalKey, client) }
        } finally {
            retryingKeys -= globalKey
        }
    }

    /**
     * Retries the failed downloads among [globalKeys] one at a time, in order. A key whose server [clientFor] cannot
     * resolve stays failed; one key's error does not stop the rest; a profile switch does.
     */
    suspend fun retryDownloads(globalKeys: Iterable<String>, clientFor: (String) -> MediaBackend?) {
        val generation = profileGeneration
        for (globalKey in globalKeys.toList()) {
            if (disposed || generation != profileGeneration) return
            val client = clientFor(globalKey) ?: continue
            try {
                retryDownload(globalKey, client)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to retry download $globalKey" }
            }
        }
    }

    /** Cancels a download: another owner's copy only loses this profile's ownership, the last owner's is removed. */
    suspend fun cancelDownload(globalKey: String) {
        if (!owns(globalKey) || globalKey !in downloadsMap) return
        val profileId = requireActiveProfileId()
        val removed = metadataMap[globalKey]
        var released = releaseDownloadForProfile(globalKey, profileId, onlyIfShared = true)
        if (!released) released = removeExclusiveDownload(globalKey, profileId) { manager.cancelAndRemoveDownload(globalKey) }
        if (removed != null) {
            deletionNotifier.notifyDeletedItem(removed, isDownloadOnly = true)
        } else if (!released) {
            return
        }
        notifyChanged()
    }

    /** Deletes a download, or every owned download below a show, season, album or artist. */
    suspend fun deleteDownload(globalKey: String) = deleteDownload(globalKey, notify = true, generation = profileGeneration)

    /** Deletes every downloaded title of the collection folder [collectionGlobalKey]. */
    suspend fun deleteCollectionDownloads(collectionGlobalKey: String) {
        val generation = profileGeneration
        val titles = downloadedCollectionItems(collectionGlobalKey)
        batchDeletionDepth++
        try {
            for (title in titles) {
                if (generation != profileGeneration) return
                deleteDownload(title.globalKey, notify = true, generation = generation)
            }
        } finally {
            batchDeletionDepth--
        }
        notifyChanged()
    }

    /** [generation] is the profile generation that started the deletion; a switch aborts the rest. */
    private suspend fun deleteDownload(globalKey: String, notify: Boolean, generation: Int) {
        if (generation != profileGeneration) return
        try {
            val meta = metadataMap[globalKey]
            if (meta != null && (meta.isShow || meta.isSeason || meta.kind == MediaKind.ALBUM || meta.kind == MediaKind.ARTIST)) {
                deleteOwnedContainerDownloads(globalKey, meta, generation)
                return
            }
            if (!owns(globalKey)) {
                // A container has no row of its own and its metadata can be missing; its leaves' rows still name it.
                if (meta == null) deleteOwnedContainerDownloads(globalKey, null, generation)
                return
            }
            val profileId = requireActiveProfileId()
            if (!releaseDownloadForProfile(globalKey, profileId, onlyIfShared = true)) {
                removeExclusiveDownload(globalKey, profileId) { manager.deleteDownload(globalKey) }
            }
            if (notify && meta != null) deletionNotifier.notifyDeletedItem(meta, isDownloadOnly = true)
            if (notify) notifyChanged()
        } catch (e: Throwable) {
            deletionProgress -= globalKey
            if (notify) notifyChanged()
            throw e
        }
    }

    private suspend fun removeExclusiveDownload(globalKey: String, profileId: String, remove: suspend () -> Unit): Boolean {
        val finalOwner = library.getDownloadOwner(profileId, globalKey)
        remove()
        val released = releaseDownloadForProfile(globalKey, profileId, ownerHint = finalOwner)
        forget(globalKey)
        return released
    }

    private suspend fun deleteOwnedContainerDownloads(globalKey: String, container: MediaItem?, generation: Int) {
        val keys = ownedDescendantKeys(globalKey, container)
        if (generation != profileGeneration) return
        if (container == null && keys.isEmpty()) return
        batchDeletionDepth++
        try {
            for (key in keys) {
                if (generation != profileGeneration) return
                val meta = metadataMap[key]
                deleteDownload(key, notify = false, generation = generation)
                if (meta != null) deletionNotifier.notifyDeletedItem(meta, isDownloadOnly = true)
            }
        } finally {
            batchDeletionDepth--
        }
        if (container != null) deletionNotifier.notifyDeletedItem(container, isDownloadOnly = true)
        notifyChanged()
    }

    /** Owned leaves below [globalKey]: by loaded metadata, and by their rows' parent and grandparent keys. */
    private suspend fun ownedDescendantKeys(globalKey: String, container: MediaItem?): List<String> {
        val generation = profileGeneration
        val keys = mutableSetOf<String>()
        if (container != null) {
            val matchesGrandparent = container.isShow || container.kind == MediaKind.ARTIST
            for ((key, meta) in metadataMap) {
                if (!owns(key) || meta.serverId != container.serverId) continue
                val under = if (matchesGrandparent) meta.grandparentId == container.id || meta.parentId == container.id else meta.parentId == container.id
                if (under) keys += key
            }
        }
        val parsed = parseGlobalKey(globalKey)
        if (parsed != null) {
            val rows = library.getEpisodesBySeason(parsed.second, parsed.first.value) + library.getEpisodesByShow(parsed.second, parsed.first.value)
            if (generation != profileGeneration) return emptyList()
            rows.mapTo(keys) { it.global_key }
        }
        return keys.filter(::owns)
    }

    fun resumeQueuedDownloads(client: MediaBackend) {
        if (manager.downloadsSupported) manager.resumeQueuedDownloads(client)
    }

    suspend fun applyDownloadOnWifiOnly(wifiOnly: Boolean) = manager.applyDownloadOnWifiOnly(wifiOnly)

    /**
     * Deletes [globalKey] when it is a completed episode or movie and says so on [autoRemovedMessages]. The watched
     * judgment is the caller's.
     */
    suspend fun deleteWatchedDownload(globalKey: String) {
        val title = deleteCompletedLeaf(globalKey) ?: return
        _autoRemoved.tryEmit(T.messages.autoRemovedWatchedDownload(title = title))
    }

    /** Deletes [globalKey] when it is a completed episode or movie; the deleted item's title, else null. */
    private suspend fun deleteCompletedLeaf(globalKey: String): String? {
        val meta = metadataStore.resolved(globalKey) ?: return null
        if (!meta.isEpisode && !meta.isMovie) return null
        if (!completed(globalKey)) return null
        Log.i(TAG) { "Auto-deleting watched download ${meta.title} ($globalKey)" }
        deleteDownload(globalKey)
        return meta.title ?: T.common.unknown
    }

    /**
     * Deletes completed owned episodes and movies that are watched with no resume point (a watched item being
     * rewatched stays: rules would queue it again), except [activeGlobalKey]. The deleted titles.
     */
    suspend fun autoDeleteWatchedDownloads(activeGlobalKey: String? = null): List<String> {
        val deleted = mutableListOf<String>()
        val generation = profileGeneration
        val keys = downloadsMap.filter { (key, p) -> owns(key) && p.status == DownloadedMediaStatus.COMPLETED }.keys.toList()
        for (globalKey in keys) {
            if (generation != profileGeneration) break
            val meta = metadataStore.resolved(globalKey) ?: continue
            if (meta.isUnwatchedOrInProgress) continue
            if (activeGlobalKey != null && meta.globalKey == activeGlobalKey) continue
            try {
                deleteCompletedLeaf(globalKey)?.let { deleted += it }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to auto-delete watched download $globalKey" }
            }
        }
        return deleted
    }

    // endregion

    // region collections

    /**
     * Refreshes which collections hold the profile's downloaded movies and shows on each online server of
     * [serverIds] (run when servers connect). A server refreshed within a day that gained no title since is skipped.
     */
    suspend fun syncDownloadCollections(serverIds: Iterable<ServerId>) {
        if (!manager.downloadsSupported) return
        ensureInitialized()
        profileScopedReload?.join()
        for (serverId in serverIds) {
            val client = servers.client(serverId)?.takeIf { servers.isServerOnline(serverId) } ?: continue
            refreshCollections(client)
        }
    }

    /** A call while one runs for the same server folds into one rerun; a failure keeps the stored membership. */
    private suspend fun refreshCollections(client: MediaBackend) {
        val profileId = activeProfileId
        if (profileId.isNullOrEmpty() || isOffline) return
        val generation = profileGeneration
        val serverId = client.serverId
        val runKey = "$generation:$serverId"
        if (!collectionRefreshesRunning.add(runKey)) {
            collectionRefreshesRequested += runKey
            return
        }
        val isStale = { disposed || generation != profileGeneration }
        try {
            do {
                collectionRefreshesRequested -= runKey
                refreshCollectionsOnce(client, profileId, serverId, isStale)
            } while (runKey in collectionRefreshesRequested && !isStale())
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Collection membership refresh failed for $serverId" }
        } finally {
            collectionRefreshesRunning -= runKey
            collectionRefreshesRequested -= runKey
        }
    }

    private suspend fun refreshCollectionsOnce(client: MediaBackend, profileId: String, serverId: ServerId, isStale: () -> Boolean) {
        // Every owned movie and every owned episode's show, whatever its state: a queued title groups once complete.
        val titleIds = metadataMap.mapNotNullTo(mutableSetOf()) { (key, meta) ->
            if (!owns(key) || meta.serverId != serverId.value) null else if (meta.isMovie) meta.id else if (meta.isEpisode) meta.grandparentId else null
        }
        // A profile still hydrating has no titles; refreshing then would erase valid membership.
        if (titleIds.isEmpty()) return
        val previous = collectionRepository.sync(profileId, serverId.value)
        val now = clock()
        if (previous != null && previous.checkedIds.containsAll(titleIds) && now - previous.syncedAt < COLLECTION_REFRESH_INTERVAL.inWholeMilliseconds) return
        val memberships = client.fetchCollectionMemberships(titleIds)
        if (isStale()) return
        val refreshed = LinkedHashMap<String, DownloadedCollection>()
        for (membership in memberships) {
            val pinned = manager.pinCollectionForOffline(membership.collection.id, client)
            if (isStale()) return
            if (pinned != null) refreshed[membership.collection.id] = DownloadedCollection(pinned, membership.memberIds)
        }
        collectionRepository.replace(profileId, serverId.value, refreshed.mapValues { it.value.memberIds }, titleIds, now)
        if (isStale()) return
        collections.entries.removeAll { it.value.collection.serverId == serverId.value }
        for (entry in refreshed.values) putDownloadedCollection(serverId.value, entry.collection, entry.memberIds)
        notifyChanged()
    }

    // endregion

    // region sync rules

    /** The active profile's rules by their profile-scoped global key. */
    val syncRules: Map<String, SyncRule> get() = syncRulesMap.toMap()

    val syncRulesSupported: Boolean get() = manager.downloadsSupported

    /** The rule key of an item for [profileId] (default: the active one); unscoped without a profile. */
    fun syncRuleKeyFor(serverId: ServerId, ratingKey: String, profileId: String? = null): String =
        syncRuleKey(profileId ?: activeProfileId.orEmpty(), serverId, ratingKey)

    /** The active profile's rule keys a watch event of an item touches: the item's and its parents'. */
    fun syncRuleKeysForWatchEvent(event: WatchStateEvent): Set<String> {
        val profileId = activeProfileId
        if (profileId.isNullOrEmpty()) return emptySet()
        return (listOf(event.itemId) + event.parentChain).mapTo(mutableSetOf()) { syncRuleKeyFor(event.serverId, it, profileId) }
    }

    fun hasSyncRule(globalKey: String) = globalKey in syncRulesMap

    fun getSyncRule(globalKey: String): SyncRule? = syncRulesMap[globalKey]

    private fun hasActiveOwnedDownload(globalKey: String) = owns(globalKey) && SyncRuleExecutor.isActiveDownload(downloadsMap[globalKey]?.status)

    private suspend fun associateSyncRuleDownload(rule: SyncRule, downloadGlobalKey: String, ownership: QueueOwnership) {
        if (!isCurrent(ownership) || rule.globalKey in removingSyncRuleKeys || !hasActiveOwnedDownload(downloadGlobalKey)) return
        val current = syncRulesMap[rule.globalKey] ?: return
        syncRuleRepository.linkDownload(current, downloadGlobalKey)
    }

    suspend fun markSyncRuleDownloadLinksInitialized(globalKey: String) {
        syncRuleRepository.markDownloadLinksInitialized(globalKey)
        syncRulesMap[globalKey]?.let { syncRulesMap[globalKey] = it.copy(downloadLinksInitialized = true) }
    }

    /**
     * Creates (or updates) the active profile's rule for a show, season, collection or playlist. [targetMetadata] gives
     * the rule's title at once, for list rules no download would name.
     */
    suspend fun createSyncRule(
        serverId: ServerId,
        ratingKey: String,
        target: SyncRuleTarget,
        episodeCount: Int,
        mediaIndex: Int = 0,
        downloadFilter: SyncRuleFilter = SyncRuleFilter.UNWATCHED,
        includeSpecials: Boolean = true,
        targetMetadata: MediaItem? = null,
        transcodeQuality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
    ): SyncRule {
        val profileId = requireActiveProfileId()
        val rule = syncRuleRepository.upsert(profileId, serverId, ratingKey, target, episodeCount, mediaIndex, downloadFilter, includeSpecials, transcodeQuality)
        if (targetMetadata != null) {
            metadataMap[buildGlobalKey(serverId, ratingKey)] = targetMetadata.serverId?.let { targetMetadata } ?: targetMetadata.copy(serverId = serverId.value)
        }
        syncRulesMap[rule.globalKey] = rule
        notifyChanged()
        return rule
    }

    /** Edits a rule's options (never runs it). Throws busy during a pass or cleanup, and when the profile changed. */
    suspend fun updateSyncRuleOptions(
        globalKey: String,
        episodeCount: Int? = null,
        downloadFilter: SyncRuleFilter? = null,
        enabled: Boolean? = null,
        includeSpecials: Boolean? = null,
        mediaIndex: Int? = null,
        checkCurrent: (() -> Unit)? = null,
    ): SyncRule {
        val profileId = requireActiveProfileId()
        val generation = profileGeneration
        val expected = syncRulesMap[globalKey]
        check(expected != null && expected.profileId == profileId) { "Sync rule is not owned by this profile" }
        validateSyncRuleOptions(expected, episodeCount, downloadFilter, includeSpecials, mediaIndex)
        fun guard(requireIdle: Boolean = true) {
            checkCurrent?.invoke()
            check(!disposed && activeProfileId == profileId && profileGeneration == generation) { "Download profile changed" }
            if (requireIdle && (syncRuleCleanupInProgress || syncRuleExecutor.isExecuting || globalKey in removingSyncRuleKeys)) {
                throw SyncRuleCleanupBusyException()
            }
            check(syncRulesMap[globalKey]?.id == expected.id) { "Sync rule no longer exists" }
        }
        guard()
        val updated = syncRuleRepository.updateOptions(expected, episodeCount, downloadFilter, enabled, includeSpecials, mediaIndex)
        guard(requireIdle = false)
        syncRulesMap[globalKey] = updated
        notifyChanged()
        return updated
    }

    /** Deletes a rule; its downloads stay. */
    suspend fun deleteSyncRule(globalKey: String) {
        requireActiveProfileId()
        deleteSyncRuleRecord(globalKey, syncRulesMap[globalKey] ?: syncRuleRepository.rule(globalKey))
        notifyChanged()
    }

    /**
     * Deletes a list rule and the active profile's downloads linked only to it (other rules and profiles keep theirs),
     * after linking the server's rules whose links are not recorded yet.
     */
    suspend fun deleteSyncRuleAndDownloads(globalKey: String) {
        val profileId = requireActiveProfileId()
        if (syncRuleCleanupInProgress || syncRuleExecutor.isExecuting) throw SyncRuleCleanupBusyException()
        val ownership = captureQueueOwnership()
        val existing = syncRuleRepository.rule(globalKey)
        if (existing == null || existing.profileId != profileId) return
        require(existing.target == SyncRuleTarget.COLLECTION || existing.target == SyncRuleTarget.PLAYLIST) { "Only collection/playlist rules support cleanup" }
        var changed = false
        syncRuleCleanupInProgress = true
        try {
            backfillUninitializedRuleLinksForServer(existing, ownership)
            if (!isCurrent(ownership)) throw SyncRuleCleanupBusyException()
            val tracked = syncRuleRepository.rule(globalKey)
            if (tracked == null || !tracked.downloadLinksInitialized) throw SyncRuleCleanupUnavailableException(globalKey)
            removingSyncRuleKeys += globalKey
            syncRuleRepository.setEnabled(globalKey, false)
            syncRulesMap[globalKey]?.let { syncRulesMap[globalKey] = it.copy(enabled = false, downloadLinksInitialized = true) }
            changed = true
            val keys = syncRuleRepository.exclusiveDownloadKeys(tracked)
            batchDeletionDepth++
            try {
                for (key in keys) {
                    if (!isCurrent(ownership)) throw SyncRuleCleanupBusyException()
                    val wasOwned = owns(key)
                    val meta = metadataMap[key]
                    deleteDownload(key, notify = false, generation = ownership.generation)
                    if (wasOwned && meta != null) deletionNotifier.notifyDeletedItem(meta, isDownloadOnly = true)
                }
            } finally {
                batchDeletionDepth--
            }
            deleteSyncRuleRecord(globalKey, tracked)
        } finally {
            removingSyncRuleKeys -= globalKey
            syncRuleCleanupInProgress = false
            if (changed) notifyChanged()
        }
    }

    private suspend fun backfillUninitializedRuleLinksForServer(target: SyncRule, ownership: QueueOwnership) {
        val rules = syncRuleRepository.rulesNeedingLinks(target.profileId, ServerId(target.serverId))
            .filter { it.enabled || it.globalKey == target.globalKey }
        for (rule in rules) {
            if (!isCurrent(ownership)) throw SyncRuleCleanupBusyException()
            when (rule.target) {
                SyncRuleTarget.SHOW, SyncRuleTarget.SEASON -> {
                    val keys = syncRuleRepository.ownedDownloadKeysUnder(rule.profileId, ServerId(rule.serverId), rule.ratingKey, rule.target == SyncRuleTarget.SHOW)
                    for (key in keys) syncRuleRepository.linkDownload(rule, key)
                    syncRuleRepository.markDownloadLinksInitialized(rule.globalKey)
                }
                SyncRuleTarget.COLLECTION, SyncRuleTarget.PLAYLIST -> {
                    val backfilled = syncRuleExecutor.backfillListRuleDownloadLinks(rule, servers, statusSnapshot(), metadataMap.toMap()) { resolved, key ->
                        if (isCurrent(ownership) && hasActiveOwnedDownload(key)) syncRuleRepository.linkDownload(resolved, key)
                    }
                    if (!backfilled) throw SyncRuleCleanupUnavailableException(rule.globalKey)
                }
            }
            syncRulesMap[rule.globalKey]?.let { syncRulesMap[rule.globalKey] = it.copy(downloadLinksInitialized = true) }
        }
    }

    private suspend fun deleteSyncRuleRecord(globalKey: String, existing: SyncRule?) {
        val publicKey = existing?.let { buildGlobalKey(ServerId(it.serverId), it.ratingKey) } ?: globalKey
        syncRuleRepository.delete(globalKey)
        syncRulesMap -= globalKey
        // The target metadata a list rule stashed goes with it unless a download holds it.
        if (publicKey !in downloadsMap) metadataMap -= publicKey
    }

    private fun statusSnapshot(): Map<String, DownloadedMediaStatus> = downloadsMap.filterKeys(::owns).mapValues { it.value.status }

    /** Runs every rule of the active profile ([force] bypasses the cooldown); the queued titles as "Title (n)". */
    suspend fun executeSyncRules(force: Boolean = false): List<String> {
        if (!manager.downloadsSupported || syncRuleCleanupInProgress) return emptyList()
        val profileId = activeProfileId
        if (profileId.isNullOrEmpty()) return emptyList()
        val ownership = captureQueueOwnership()
        if (syncRulesMap.isEmpty()) return emptyList()
        // Before the executor: a stopped pass sends no requests and doesn't restart the cooldown.
        if (manager.queueBlockedByStorageFailure) {
            Log.d(TAG) { "Skipping sync rules: downloads stopped for storage" }
            return emptyList()
        }
        val context = RelatedMetadataContext()
        val results = syncRuleExecutor.executeSyncRules(
            profileId,
            servers,
            statusSnapshot(),
            metadataMap.toMap(),
            associateDownload = { rule, key -> associateSyncRuleDownload(rule, key, ownership) },
            // A profile switch mid-pass stops queueing; what is queued is claimed for the rule's owner.
            queueSingleDownload = { item, client, mediaIndex, quality ->
                isCurrent(ownership) && queueSingleDownload(item, client, ownership, mediaIndex, relatedContext = context, quality = quality, automatic = true)
            },
            isOffline = isOffline,
            force = force,
        )
        return results.filter { it.queuedCount > 0 }.map { "${it.title ?: T.common.unknown} (${it.queuedCount})" }
    }

    /** Runs one rule now (after adding to its list), bypassing the cooldown. */
    suspend fun executeSyncRuleFor(globalKey: String): SyncRuleResult? {
        if (!manager.downloadsSupported || syncRuleCleanupInProgress) return null
        val profileId = activeProfileId
        if (profileId.isNullOrEmpty()) return null
        val ownership = captureQueueOwnership()
        if (globalKey !in syncRulesMap) return null
        if (manager.queueBlockedByStorageFailure) {
            Log.d(TAG) { "Skipping sync rule $globalKey: downloads stopped for storage" }
            return null
        }
        val context = RelatedMetadataContext()
        return syncRuleExecutor.executeSingleRule(
            profileId,
            globalKey,
            servers,
            statusSnapshot(),
            metadataMap.toMap(),
            associateDownload = { rule, key -> associateSyncRuleDownload(rule, key, ownership) },
            queueSingleDownload = { item, client, mediaIndex, quality ->
                isCurrent(ownership) && queueSingleDownload(item, client, ownership, mediaIndex, relatedContext = context, quality = quality, automatic = true)
            },
            isOffline = isOffline,
        )
    }

    // endregion

    // region triggers

    private var autoDeleteRun: CompletableDeferred<Unit>? = null
    private val pendingSyncKeys = LinkedHashSet<String>()
    private var watchDebounce: Job? = null
    private var lastHadWifi: Boolean? = null

    /**
     * Connectivity changed: moving onto Wi-Fi or Ethernet runs auto-removal and a full rule pass (cooldown applies).
     * The first report only records the link.
     */
    fun onConnectivityChanged(links: Connectivity) {
        val hadWifi = lastHadWifi
        lastHadWifi = links.hasWifiOrEthernet
        if (hadWifi != null && links.hasWifiOrEthernet && !hadWifi) scope.launch { autoDeleteAndSync() }
    }

    /** Offline watch actions drained and server state refreshed: auto-removal and a forced full pass. */
    suspend fun onWatchStatesRefreshed() = autoDeleteAndSync(force = true)

    /** Added to playlist or collection [listId] of [serverId]: its rule, if it has one, runs now. */
    suspend fun onAddedToList(serverId: ServerId, listId: String): SyncRuleResult? = executeSyncRuleFor(syncRuleKeyFor(serverId, listId))

    /** A watched mark (not of the item playing) runs the rules covering the item or its parents, debounced. */
    private fun onWatchEvent(event: WatchStateEvent) {
        if (event.changeType != WatchStateChangeType.WATCHED) return
        if (playingItemKey() == event.globalKey) return
        pendingSyncKeys += syncRuleKeysForWatchEvent(event)
        watchDebounce?.cancel()
        watchDebounce = scope.launch {
            delay(WATCH_EVENT_DEBOUNCE)
            val keys = pendingSyncKeys.toList()
            pendingSyncKeys.clear()
            autoDeleteAndSync(targetKeys = keys)
        }
    }

    /**
     * Auto-removal (when on), then the rules: [targetKeys] only (no cooldown), else a full pass ([force] bypasses the
     * cooldown). Passes run one at a time; target keys arriving meanwhile run after the current pass.
     */
    suspend fun autoDeleteAndSync(targetKeys: List<String>? = null, force: Boolean = false) {
        autoDeleteRun?.let {
            if (targetKeys != null) pendingSyncKeys += targetKeys
            return
        }
        val run = CompletableDeferred<Unit>().also { autoDeleteRun = it }
        try {
            refreshMetadataFromCache()
            if (autoRemoveWatchedDownloads()) {
                val deleted = autoDeleteWatchedDownloads(playingItemKey())
                if (deleted.isNotEmpty()) {
                    _autoRemoved.tryEmit(
                        if (deleted.size == 1) T.messages.autoRemovedWatchedDownload(title = deleted.first())
                        else T.messages.autoRemovedWatchedDownloads(n = deleted.size),
                    )
                }
            }
            if (targetKeys != null) {
                for (key in targetKeys) {
                    if (!hasSyncRule(key)) continue
                    val result = executeSyncRuleFor(key)
                    if (result != null && result.queuedCount > 0) {
                        _syncedNewEpisodes.tryEmit(T.downloads.syncedNewEpisodes(count = "1", title = "${result.title ?: T.common.unknown} (${result.queuedCount})"))
                    }
                }
            } else {
                val synced = executeSyncRules(force)
                if (synced.isNotEmpty()) _syncedNewEpisodes.tryEmit(T.downloads.syncedNewEpisodes(count = synced.size.toString(), title = synced.first()))
            }
        } finally {
            autoDeleteRun = null
            run.complete(Unit)
            if (pendingSyncKeys.isNotEmpty() && !disposed) {
                val keys = pendingSyncKeys.toList()
                pendingSyncKeys.clear()
                scope.launch { autoDeleteAndSync(targetKeys = keys) }
            }
        }
    }

    // endregion

    companion object {
        private const val TAG = "DownloadsController"
        private val COLLECTION_REFRESH_INTERVAL: Duration = 24.hours
        private val WATCH_EVENT_DEBOUNCE: Duration = 5.seconds
        private val TERMINAL_STATUSES = setOf(
            DownloadedMediaStatus.COMPLETED,
            DownloadedMediaStatus.FAILED,
            DownloadedMediaStatus.CANCELLED,
            DownloadedMediaStatus.PARTIAL,
        )
        private val SKIP_EXISTING_STATUSES = setOf(DownloadedMediaStatus.COMPLETED, DownloadedMediaStatus.DOWNLOADING, DownloadedMediaStatus.QUEUED)

        /** Checks the options each rule kind uses: list rules take a filter, episode rules a count and version. */
        fun validateSyncRuleOptions(
            rule: SyncRule,
            episodeCount: Int? = null,
            downloadFilter: SyncRuleFilter? = null,
            includeSpecials: Boolean? = null,
            mediaIndex: Int? = null,
        ) {
            val isList = rule.target == SyncRuleTarget.COLLECTION || rule.target == SyncRuleTarget.PLAYLIST
            if (episodeCount != null) {
                if (isList) throw UnsupportedOperationException("List rules do not use episode counts")
                require(episodeCount >= 0) { "Episode count must be nonnegative" }
            }
            if (downloadFilter != null && !isList) throw UnsupportedOperationException("Episode rules always select unwatched episodes")
            if (includeSpecials != null && rule.target != SyncRuleTarget.SHOW) throw UnsupportedOperationException("Only show rules use includeSpecials")
            if (mediaIndex != null) {
                if (isList) throw UnsupportedOperationException("List rules always use the default version")
                require(mediaIndex >= 0) { "Version index must be nonnegative" }
            }
        }
    }
}
