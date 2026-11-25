package com.edde746.plezy.downloads

import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.DownloadSubtitleSpec
import com.edde746.plezy.backend.DownloadTranscoding
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.artworkStorageKey
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.crash.Breadcrumb
import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.data.db.Download_queue
import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.downloads.DownloadLibraryRepository
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.CANCELLED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PARTIAL
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PAUSED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.data.downloads.QueueDownloadOutcome
import com.edde746.plezy.data.downloads.additionalPartPathList
import com.edde746.plezy.data.downloads.downloadStatus
import com.edde746.plezy.data.downloads.nextMissingPartIndex
import com.edde746.plezy.data.downloads.partCount
import com.edde746.plezy.data.downloads.storedPartPaths
import com.edde746.plezy.data.downloads.transcodeQuality
import com.edde746.plezy.data.isStorageFullError
import com.edde746.plezy.data.isStorageFullMessage
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.format.subtitleExtension
import com.edde746.plezy.jellyfin.JellyfinCacheResolver
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.mergeFetchedMediaItem
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.Connectivity
import com.edde746.plezy.servers.OfflineModeSource
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import com.edde746.plezy.backend.net.MediaServerHttpClient
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlinx.io.IOException
import kotlinx.io.files.FileSystem
import kotlin.math.roundToInt
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/** The selected download location as the settings hold it: a path (or document tree URI) and its kind (`file`, `saf`). */
data class DownloadLocationSnapshot(val path: String?, val type: String?)

/** The pinned metadata a profile sees offline, by global key, and the cache scope used for each owned server. */
data class PinnedDownloadMetadata(val items: Map<String, MediaItem>, val scopesByServer: Map<String, String?>)

/**
 * Downloads media for offline use. It admits items to the durable queue (`downloaded_media` + `download_queue`),
 * prepares each file and hands it to the [NativeDownloader], follows the downloader's reports, stores artwork, chapter
 * thumbnails and subtitles beside the video, recovers what an interrupted process left, owns the storage-access grants
 * of the download location, and deletes downloads with their files.
 *
 * Without a [downloader] (Apple TV) downloads are unsupported: every entry point is a logged no-op.
 */
class DownloadManagerService internal constructor(
    private val database: DownloadLibraryRepository,
    private val storage: DownloadStorageService,
    private val artwork: DownloadArtworkService,
    clientResolver: (ServerId, String?) -> MediaBackend?,
    caches: Map<BackendKind, BackendCache>,
    mediaBrowserResolver: JellyfinCacheResolver,
    private val downloader: NativeDownloader?,
    private val safStorage: SafStorageOperations,
    private val settings: DeviceSettingsRepository,
    private val http: MediaServerHttpClient,
    fileSystem: FileSystem,
    io: CoroutineDispatcher,
    parentScope: CoroutineScope,
    locationStore: DownloadLocationStore? = null,
    private val autoRetryDelay: Duration = DEFAULT_AUTO_RETRY_DELAY,
    private val queueProcessorOverride: (suspend (MediaBackend) -> Unit)? = null,
    private val nativeRecoveryOverride: (suspend () -> Unit)? = null,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    private val scope = parentScope.childScope()
    private val files = LocalFiles(fileSystem, io)
    private val metadata = DownloadMetadataScopes(database, clientResolver, caches, mediaBrowserResolver)
    private val ledger = SafGrantLedger(database, safStorage, locationStore ?: SettingsDownloadLocationStore(settings, storage)) { storage.isDirectoryWritable(it) }
    private val deleter = DownloadFileDeleter(database, storage, safStorage, metadata, ledger, files, ::emitDeletionProgress)

    /** Whether this platform downloads at all (Apple TV has no background downloader). */
    val downloadsSupported: Boolean get() = downloader != null

    // A collector that falls behind loses the oldest events, never a terminal status that comes last.
    private val progress = MutableSharedFlow<DownloadProgress>(extraBufferCapacity = EVENT_BUFFER, onBufferOverflow = BufferOverflow.DROP_OLDEST)
    private val deletionProgress = MutableSharedFlow<DeletionProgress>(extraBufferCapacity = EVENT_BUFFER, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    /** Every status change, progress tick and supplementary step of every download. */
    val progressStream: Flow<DownloadProgress> = progress.asSharedFlow()

    /** The progress of each deletion. */
    val deletionProgressStream: Flow<DeletionProgress> = deletionProgress.asSharedFlow()

    private val recovery = CompletableDeferred<Unit>()

    /** What one prepared task downloads; lives from enqueue to its completion in this process. */
    private class DownloadContext(
        val metadata: MediaItem,
        val queueItem: Download_queue,
        /** The absolute file path, or the document folder URI of a document task. */
        val filePath: String,
        val extension: String,
        val client: MediaBackend,
        val resolution: DownloadResolution,
        /** Which file of [resolution] the task fetches (0 = the first). */
        val partIndex: Int,
        val showYear: Int?,
        val safRootUri: String?,
    ) {
        val isSafMode: Boolean get() = safRootUri != null

        /** Each file's external subtitles when enrichment resolved them; null keeps the subtitle work deferred. */
        val subtitlesPerPart: List<List<DownloadSubtitleSpec>>? get() = if (resolution.externalSubtitlesResolved) resolution.subtitlesPerPart() else null
    }

    private val pendingDownloadContext = mutableMapOf<String, DownloadContext>()
    private var supplementaryRepair: Deferred<Unit>? = null
    private var offlineSource: OfflineModeSource? = null
    private var downloaderInitialized = false
    private var loggedUnsupported = false

    // Keys being paused, cancelled, or completing: the downloader's reports for them are held off meanwhile.
    private val pausingKeys = mutableSetOf<String>()
    private val cancellingKeys = mutableSetOf<String>()
    private val completingKeys = mutableSetOf<String>()

    private var isProcessingQueue = false
    private var queueRerunRequested = false
    private var isRepairingArtwork = false
    private var disposed = false

    /**
     * A storage failure stopped the queue. Only an explicit request lifts it ([beginUserDownloadRequest], a resume, a
     * retry) or an app restart: what is queued meanwhile waits behind it.
     */
    var queueBlockedByStorageFailure = false
        private set

    private var consecutiveQueueFailures = 0

    /** The last progress of each running download: its row gets it at most every [PROGRESS_WRITE_INTERVAL], and on pause. */
    private val rowProgress = mutableMapOf<String, RowProgress>()
    private val autoRetryTimers = mutableMapOf<String, Job>()

    /** Bytes of the files a stacked download already stored, measured once per task. */
    private val storedPartBytes = mutableMapOf<String, Pair<String, Deferred<Long>>>()

    private val isOffline: Boolean get() = offlineSource?.isOffline?.value ?: false

    private fun skipUnsupported(operation: String): Boolean {
        if (downloadsSupported) return false
        if (!loggedUnsupported) {
            loggedUnsupported = true
            Log.i(TAG) { "Downloads are unavailable on this platform; skipping $operation" }
        } else {
            Log.d(TAG) { "Skipping $operation: downloads unavailable on this platform" }
        }
        return true
    }

    /** Completes when startup recovery ([recoverInterruptedDownloads]) has finished; read download state after it. */
    suspend fun awaitRecovery() = recovery.await()

    /** Whether a download must wait for Wi-Fi now: [connectivity] is cellular only and the user asked for Wi-Fi only. */
    suspend fun shouldBlockDownloadOnCellularWith(connectivity: Connectivity): Boolean {
        // The link decides first: an empty or unknown report is not cellular only.
        if (!connectivity.isCellularOnly) return false
        return settings.value(AppSettings.downloadOnWifiOnly)
    }

    /** While [source] says offline, queue and resume paths skip network work until connectivity returns. */
    fun setOfflineSource(source: OfflineModeSource?) {
        offlineSource = source
    }

    // Download location

    /** Switches the download location, all or nothing; [checkCurrent] throws to abort a superseded switch. */
    suspend fun setDownloadLocation(path: String, pathType: String, checkCurrent: (() -> Unit)? = null) =
        ledger.setDownloadLocation(path, pathType, checkCurrent)

    suspend fun resetDownloadLocation(checkCurrent: (() -> Unit)? = null) = ledger.resetDownloadLocation(checkCurrent)

    // Metadata and scopes

    fun activeClientScopeIdForServer(serverId: ServerId): String? = metadata.activeClientScopeIdForServer(serverId)

    suspend fun profileClientScopeIdForServer(serverId: ServerId, activeProfileId: String?): String? =
        metadata.profileClientScopeIdForServer(serverId, activeProfileId)

    /** The pinned metadata of every download [activeProfileId] owns, from that profile's namespaces only. */
    suspend fun getAllPinnedMetadata(activeProfileId: String?): PinnedDownloadMetadata = metadata.getAllPinnedMetadata(activeProfileId)

    suspend fun lookupMetadata(serverId: ServerId, itemId: String, preferActiveScope: Boolean = false, activeProfileId: String? = null): MediaItem? =
        metadata.lookupMetadata(serverId, itemId, preferActiveScope, activeProfileId)

    suspend fun fetchAndPinMetadata(serverId: ServerId, itemId: String, preferActiveScope: Boolean = false, activeProfileId: String? = null): MediaItem? =
        metadata.fetchAndPinMetadata(serverId, itemId, preferActiveScope, activeProfileId)

    /**
     * Keeps Plex downloads' metadata through a full logout, which leaves them without an owner for a while: each moves
     * to its server's neutral transfer scope with its metadata sanitized, in one transaction.
     */
    suspend fun preparePlexMetadataForLogoutTransfer() {
        database.preparePlexMetadataForLogoutTransfer { serverId -> metadata.client(ServerId(serverId))?.backend == BackendKind.PLEX }
    }

    /** Moves transferred Plex metadata into [profileId]'s private scope before the profile's downloads load. */
    suspend fun adoptTransferredPlexMetadataForProfile(profileId: String, isStillActive: (() -> Boolean)? = null) =
        database.adoptTransferredPlexMetadataForProfile(profileId, isStillActive)

    suspend fun deleteMetadataForOwner(
        globalKey: String,
        serverId: ServerId,
        itemId: String,
        profileId: String,
        backendId: String? = null,
        clientScopeId: String? = null,
    ) = metadata.deleteMetadataForOwner(globalKey, serverId, itemId, profileId, backendId, clientScopeId)

    // Native downloader

    private suspend fun initializeDownloader() {
        if (downloaderInitialized) return
        val downloader = downloader ?: return
        downloader.configure(
            object : TaskCallbacks {
                override fun onStatus(update: TaskStatusUpdate) {
                    if (disposed) return
                    scope.launch { logFailure("status", update.task) { handleTaskStatus(update) } }
                }

                override fun onProgress(update: TaskProgressUpdate) {
                    if (disposed) return
                    scope.launch { logFailure("progress", update.task) { handleTaskProgress(update) } }
                }
            },
            TaskNotifications(
                runningTitle = DISPLAY_NAME,
                runningBody = T.downloads.notificationDownloading,
                completeBody = T.downloads.notificationComplete,
                errorBody = T.downloads.errorDownloadFailed,
                pausedBody = T.downloads.notificationPaused,
            ),
        )
        // The downloader's persisted policy follows the setting, which may have changed while it wasn't running.
        applyDownloadOnWifiOnly(settings.value(AppSettings.downloadOnWifiOnly))
        downloader.resumeFromBackground()
        downloaderInitialized = true
    }

    private suspend fun logFailure(event: String, task: DownloadTask, block: suspend () -> Unit) {
        try {
            block()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Error handling download $event for ${task.metaData}" }
        }
    }

    /**
     * Applies "download on Wi-Fi only" to every task the downloader holds; a task's own flag is fixed at enqueue, so
     * the downloader's policy overrides it in both directions.
     */
    suspend fun applyDownloadOnWifiOnly(wifiOnly: Boolean) {
        val downloader = downloader ?: return
        val requirement = if (wifiOnly) RequireWiFi.FOR_ALL_TASKS else RequireWiFi.FOR_NO_TASKS
        try {
            downloader.requireWiFi(requirement)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to apply Wi-Fi-only download policy ($requirement)" }
        }
    }

    // Recovery

    /**
     * Recovers what the last process left: missing queue rows, artwork keys holding a token, downloader records aimed
     * at a storage location the app has left, killed tasks, tasks the rows no longer match, storage grants nothing
     * holds, stored paths of older releases, and downloads stuck downloading with no task.
     */
    suspend fun recoverInterruptedDownloads() {
        try {
            if (skipUnsupported("download recovery")) return
            recover()
        } finally {
            recovery.complete(Unit)
        }
    }

    private suspend fun recover() {
        val downloader = downloader ?: return
        try {
            try {
                val repaired = database.repairMissingQueuedDownloadEntries()
                if (repaired > 0) Log.i(TAG) { "Repaired $repaired missing download queue item(s)" }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to repair missing download queue items" }
            }
            try {
                dropArtworkKeyTokens()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to drop tokens from stored artwork keys" }
            }
            nativeRecoveryOverride?.let {
                it()
                return
            }
            // Strictly before the downloader is wired up: its first reports can fail a relocated task on the old
            // path, and a failed row is no longer restartable; rescheduling would re-enqueue it there again.
            purgeRelocatedDownloadRecords()
            CrashCapture.breadcrumb(Breadcrumb(BREADCRUMBS, "Initializing the downloader"))
            initializeDownloader()

            val deletedTempFiles = downloader.cleanUpOrphanedTempFiles()
            if (deletedTempFiles > 0) Log.i(TAG) { "Deleted $deletedTempFiles orphaned downloader temp file(s)" }
            CrashCapture.breadcrumb(Breadcrumb(BREADCRUMBS, "Rescheduling killed tasks"))
            val (rescheduled, _) = downloader.rescheduleKilledTasks()
            if (rescheduled.isNotEmpty()) Log.i(TAG) { "Rescheduled ${rescheduled.size} killed download task(s)" }

            reconcileNativeDownloadTasks()
            reconcileSafGrantOwnership()
            normalizeStoredPaths()

            CrashCapture.breadcrumb(Breadcrumb(BREADCRUMBS, "Scanning for orphaned downloads"))
            for (item in database.getAllDownloads()) {
                if (item.downloadStatus != DOWNLOADING) continue
                if (item.global_key in completingKeys) continue
                // Every file stored, post-processing interrupted: the queue row keeps the supplementary intent.
                if (item.nextMissingPartIndex == null) {
                    Log.i(TAG) { "Download ${item.global_key} has video but incomplete post-processing, completing" }
                    database.updateDownloadStatus(item.global_key, COMPLETED)
                    emitProgress(item.global_key, COMPLETED, 100)
                    continue
                }
                val task = item.bg_task_id?.let { downloader.taskForId(it) }
                if (task == null) {
                    Log.i(TAG) { "Re-queuing orphaned download: ${item.global_key}" }
                    database.updateDownloadStatus(item.global_key, QUEUED)
                    database.updateBgTaskId(item.global_key, null)
                    database.addToQueue(item.global_key)
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Failed to recover interrupted downloads" }
        }
    }

    /**
     * Earlier releases and builds stored a Jellyfin or Emby image URL with no parameter but its `api_key` under a key
     * that kept the token, in `thumb_path` and in the artwork file's name. Each such row gets the key without it
     * ([artworkStorageKey]) and its file the matching name, so the token leaves the database and the offline artwork
     * stays found. Rows sharing one image share one file: the first moves it, the rest find it moved.
     */
    private suspend fun dropArtworkKeyTokens() {
        for (item in database.getAllDownloads()) {
            val stored = item.thumb_path?.takeIf { "api_key" in it } ?: continue
            val key = artworkStorageKey(stored)
            if (key == stored) continue
            parseGlobalKey(item.global_key)?.let { (serverId, _) ->
                val legacy = storage.getArtworkPathFromThumb(serverId, stored)
                val current = storage.getArtworkPathFromThumb(serverId, key)
                if (files.exists(current)) {
                    files.deleteIfExists(legacy, "artwork named after a token")
                } else if (files.exists(legacy)) {
                    files.move(legacy, current)
                }
            }
            database.updateArtworkPaths(item.global_key, key)
        }
    }

    /**
     * Stored paths of older releases may carry a doubled base-directory prefix or be absolute inside the app's
     * storage: they are made relative once (setting `download_paths_normalized_version` 2).
     */
    private suspend fun normalizeStoredPaths() {
        if (settings.value(AppSettings.downloadPathsNormalizedVersion) >= 2) return
        suspend fun normalize(stored: String): String {
            var normalized = storage.toRelativePath(stored)
            if (normalized == stored) {
                val idx = stored.indexOf("downloads/")
                if (idx > 0) normalized = stored.substring(idx)
            }
            return normalized
        }
        var fixed = 0
        for (item in database.getAllDownloads()) {
            item.video_file_path?.let { stored ->
                val normalized = normalize(stored)
                if (normalized != stored) {
                    database.updateVideoFilePath(item.global_key, normalized, stampDownloadedAt = false)
                    fixed++
                }
            }
            item.additionalPartPathList?.let { parts ->
                val normalizedParts = parts.map { it?.let { part -> normalize(part) } }
                if (normalizedParts != parts) {
                    database.updateAdditionalPartPaths(item.global_key, normalizedParts)
                    fixed++
                }
            }
            item.thumb_path?.let { thumb ->
                val normalized = normalize(thumb)
                if (normalized != thumb) database.updateArtworkPaths(item.global_key, normalized)
            }
        }
        if (fixed > 0) Log.i(TAG) { "Normalized $fixed corrupted download path(s)" }
        settings.set(AppSettings.downloadPathsNormalizedVersion, 2)
    }

    private suspend fun relocationCheck(): (DownloadTask) -> Boolean {
        val downloader = downloader ?: return { false }
        val rootBasePath = downloader.baseDirectoryPath(BaseDirectory.ROOT)
        val baseAppDirPath = storage.baseAppDirectoryPath()
        val customRootPath = storage.customFileRootPath
        return { task -> isRelocatedRootTaskDirectory(task, rootBasePath, baseAppDirPath, customRootPath) }
    }

    private suspend fun reconcileNativeDownloadTasks() {
        val downloader = downloader ?: return
        val nativeTasks = try {
            downloader.allTasks()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to enumerate native download tasks during recovery" }
            return
        }
        if (nativeTasks.isEmpty()) return

        val tasksByGlobalKey = linkedMapOf<String, MutableList<DownloadTask>>()
        val relocatedByGlobalKey = linkedMapOf<String, MutableList<DownloadTask>>()
        val rootTasks = nativeTasks.filter { it.baseDirectory == BaseDirectory.ROOT }
        for (task in nativeTasks) {
            if (task.baseDirectory != BaseDirectory.ROOT && task.metaData.isNotEmpty()) tasksByGlobalKey.getOrPut(task.metaData) { mutableListOf() } += task
        }
        // A root-anchored task carries its absolute directory in the downloader's store: one enqueued before the
        // app's storage moved writes where the app owns nothing, and can't be resumed.
        if (rootTasks.isNotEmpty()) {
            val isRelocated = relocationCheck()
            for (task in rootTasks) {
                when {
                    isRelocated(task) -> relocatedByGlobalKey.getOrPut(task.metaData) { mutableListOf() } += task
                    task.metaData.isNotEmpty() -> tasksByGlobalKey.getOrPut(task.metaData) { mutableListOf() } += task
                }
            }
        }
        if (relocatedByGlobalKey.isEmpty() && tasksByGlobalKey.isEmpty()) return

        val rowsByGlobalKey = database.getAllDownloads().associateBy { it.global_key }
        val pausedTaskIds = try {
            downloader.allRecords().filter { it.status == TaskStatus.PAUSED }.mapTo(HashSet()) { it.task.taskId }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to read paused download tasks during recovery" }
            emptySet()
        }
        for ((globalKey, tasks) in relocatedByGlobalKey) {
            Log.i(TAG) { "Discarding ${tasks.size} download task(s) for $globalKey targeting relocated storage" }
            rowsByGlobalKey[globalKey]?.let { requeueRelocatedDownload(it.global_key, it) }
            cancelNativeTaskIds(globalKey, tasks.map { it.taskId }, "relocated app storage during recovery")
        }
        for ((globalKey, tasks) in tasksByGlobalKey) {
            val row = rowsByGlobalKey[globalKey]
            if (row == null) {
                cancelNativeTaskIds(globalKey, tasks.map { it.taskId }, "no download row during recovery")
                continue
            }
            when (row.downloadStatus) {
                DOWNLOADING -> reconcileDownloadingNativeTasks(row, tasks, pausedTaskIds)
                PAUSED -> reconcilePausedNativeTasks(row, tasks)
                QUEUED -> {
                    cancelNativeTaskIds(globalKey, tasks.map { it.taskId }, "queued download during recovery")
                    database.addToQueue(globalKey)
                }
                COMPLETED, FAILED, CANCELLED, PARTIAL, null ->
                    cancelNativeTaskIds(globalKey, tasks.map { it.taskId }, "download status ${row.downloadStatus} during recovery")
            }
        }
    }

    /**
     * Drops the downloader's records whose directory belongs to a previous location of the app's storage and requeues
     * their downloads to restart under the current one. Runs before the downloader is configured: rescheduling would
     * re-enqueue such a record against the old directory, and the first reports could fail its row for good.
     */
    private suspend fun purgeRelocatedDownloadRecords() {
        val downloader = downloader ?: return
        val records = try {
            downloader.allRecords()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to enumerate download records during recovery" }
            return
        }
        val rootRecords = records.filter { it.task.baseDirectory == BaseDirectory.ROOT }
        if (rootRecords.isEmpty()) return
        val isRelocated = relocationCheck()
        for (record in rootRecords) {
            if (!isRelocated(record.task)) continue
            val globalKey = record.task.metaData
            Log.i(TAG) { "Dropping download record ${record.task.taskId} for $globalKey targeting relocated storage" }
            try {
                downloader.deleteRecord(record.task.taskId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to drop relocated download record ${record.task.taskId}" }
                continue
            }
            cancelNativeTaskIds(globalKey, listOf(record.task.taskId), "relocated app storage before rescheduling")
            if (globalKey.isNotEmpty()) requeueRelocatedDownload(globalKey)
        }
    }

    /** Sends a download stranded on a previous storage location back to the queue; a finished or abandoned one stays. */
    private suspend fun requeueRelocatedDownload(globalKey: String, row: Downloaded_media? = null) {
        val current = row ?: database.getDownloadedMedia(globalKey) ?: return
        if (current.downloadStatus !in RESTARTABLE) return
        database.updateBgTaskId(globalKey, null)
        database.updateDownloadStatus(globalKey, QUEUED)
        database.addToQueue(globalKey)
    }

    private suspend fun reconcileSafGrantOwnership() {
        val tasks = try {
            downloader?.allTasks().orEmpty()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "SAF grant reconciliation deferred: native task enumeration failed" }
            return
        }
        ledger.reconcile(tasks)
    }

    private suspend fun retainUniqueCurrentNativeTask(row: Downloaded_media, tasks: List<DownloadTask>, statusLabel: String): Int {
        val partition = partitionNativeTasks(tasks, row.bg_task_id)
        if (partition.current.size != 1) return partition.current.size
        cancelNativeTaskIds(row.global_key, partition.stale.map { it.taskId }, "duplicate $statusLabel task during recovery")
        return 1
    }

    /** A task the downloader holds paused (a pause outside the app whose report the last process missed) pauses its row. */
    private suspend fun reconcileDownloadingNativeTasks(row: Downloaded_media, tasks: List<DownloadTask>, pausedTaskIds: Set<String>) {
        val currentMatches = retainUniqueCurrentNativeTask(row, tasks, "downloading")
        if (currentMatches == 1) {
            if (row.bg_task_id in pausedTaskIds) markPaused(row.global_key)
            return
        }
        if (currentMatches > 1) {
            Log.w(TAG) { "Multiple native tasks share current task id ${row.bg_task_id} for ${row.global_key}; re-queueing" }
            resetAndRequeue(row, tasks, "duplicate current task id during recovery")
            return
        }
        if (tasks.size == 1) {
            Log.i(TAG) { "Adopting recovered native task ${tasks.single().taskId} for ${row.global_key}" }
            database.updateBgTaskId(row.global_key, tasks.single().taskId)
            if (tasks.single().taskId in pausedTaskIds) markPaused(row.global_key)
            return
        }
        resetAndRequeue(row, tasks, "ambiguous downloading tasks during recovery")
    }

    /** Drops every task of [row] and queues it from scratch; the row lets go of its task first. */
    private suspend fun resetAndRequeue(row: Downloaded_media, tasks: List<DownloadTask>, reason: String) {
        database.updateBgTaskId(row.global_key, null)
        cancelNativeTaskIds(row.global_key, tasks.map { it.taskId }, reason)
        database.updateDownloadProgress(row.global_key, 0, 0, 0)
        transitionStatus(row.global_key, QUEUED)
        database.addToQueue(row.global_key)
    }

    private suspend fun reconcilePausedNativeTasks(row: Downloaded_media, tasks: List<DownloadTask>) {
        val currentMatches = retainUniqueCurrentNativeTask(row, tasks, "paused")
        if (currentMatches == 1) return
        if (currentMatches > 1) Log.w(TAG) { "Multiple paused native tasks share current task id ${row.bg_task_id} for ${row.global_key}; clearing task" }
        cancelNativeTaskIds(row.global_key, tasks.map { it.taskId }, "unexpected paused native tasks during recovery")
        database.updateBgTaskId(row.global_key, null)
    }

    private suspend fun cancelNativeTaskIds(globalKey: String, taskIds: Iterable<String>, reason: String) {
        val downloader = downloader ?: return
        val ids = taskIds.filter { it.isNotEmpty() }.toSet()
        if (ids.isEmpty()) return
        try {
            if (downloader.cancelTasksWithIds(ids)) Log.d(TAG) { "Cancelled ${ids.size} native task(s) for $globalKey ($reason): ${ids.joinToString()}" }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to cancel native tasks for $globalKey ($reason): ${ids.joinToString()}" }
        }
    }

    private suspend fun cancelNativeTask(globalKey: String, taskId: String, reason: String) = cancelNativeTaskIds(globalKey, listOf(taskId), reason)

    private suspend fun cancelNativeTasksForGlobalKey(globalKey: String, includeTaskId: String? = null, exceptTaskId: String? = null, reason: String) {
        val downloader = downloader ?: return
        val ids = mutableSetOf<String>()
        if (includeTaskId != null && includeTaskId != exceptTaskId) ids += includeTaskId
        if (!downloaderInitialized && ids.isEmpty()) return
        try {
            for (task in downloader.allTasks()) {
                if (task.metaData == globalKey && task.taskId != exceptTaskId) ids += task.taskId
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to enumerate native tasks for $globalKey ($reason)" }
        }
        cancelNativeTaskIds(globalKey, ids, reason)
    }

    // Queue

    /** Resumes the queue once a server is reachable (after connecting on launch): repairs, then the next download. */
    fun resumeQueuedDownloads(client: MediaBackend) {
        if (skipUnsupported("queued download resume")) return
        metadata.fallbackClient = client
        if (isOffline) {
            Log.d(TAG) { "Skipping resumeQueuedDownloads: offline" }
            return
        }
        scope.launch { repairPendingSupplementaryDownloads() }
        scope.launch { repairMissingArtworkForDownloads() }
        scope.launch {
            try {
                if (database.getNextQueueItem() != null) {
                    Log.i(TAG) { "Resuming queued downloads after app restart" }
                    processQueue(client)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to resume queued downloads" }
            }
        }
    }

    /**
     * Queues [metadata] for download and returns the item as stored: identical unless library stamping filled its
     * library id and title. A download already active, paused or complete is left alone. It does not lift a storage
     * stop: the item waits behind it unless its request began with [beginUserDownloadRequest].
     */
    suspend fun queueDownload(
        metadata: MediaItem,
        client: MediaBackend,
        priority: Int = 0,
        downloadSubtitles: Boolean = true,
        downloadArtwork: Boolean = true,
        mediaIndex: Int = 0,
        transcodeQuality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
    ): MediaItem {
        if (skipUnsupported("queue download")) return metadata
        val globalKey = metadata.globalKey
        val serverId = ServerId(requireNotNull(metadata.serverId) { "Cannot queue a download without a server id" })

        // The library identity lets downloads group by library offline; a failed lookup never blocks the enqueue.
        var stored = metadata
        if (metadata.libraryId == null && !isOffline) {
            try {
                stored = client.stampLibrary(metadata)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Library stamping failed for $globalKey; enqueueing unstamped" }
            }
        }

        // Read before the upsert: a re-admitted stacked attempt's files are this call's to discard.
        val prior = database.getDownloadedMedia(globalKey)
        val outcome = database.insertQueuedDownload(
            serverId = serverId.value,
            clientScopeId = client.cacheServerId.takeUnless { it == metadata.serverId },
            ratingKey = metadata.id,
            globalKey = globalKey,
            type = metadata.kind.id,
            parentRatingKey = metadata.parentId,
            grandparentRatingKey = metadata.grandparentId,
            libraryId = stored.libraryId,
            libraryTitle = stored.libraryTitle,
            mediaIndex = mediaIndex,
            mediaSourceId = mediaSourceIdForIndex(metadata, mediaIndex),
            transcodeQuality = transcodeQuality,
            priority = priority,
            downloadSubtitles = downloadSubtitles,
            downloadArtwork = downloadArtwork,
        )
        if (outcome == QueueDownloadOutcome.UNCHANGED) {
            Log.i(TAG) { "Download already active, paused, or completed for $globalKey" }
            return stored
        }
        if (outcome == QueueDownloadOutcome.ADMITTED) {
            if (prior?.additionalPartPathList != null) discardStackedAttempt(prior)
            // Pinning prepares offline use; the queued download must stay executable when it fails.
            try {
                this.metadata.pinMetadataForOffline(client, stored)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to pin metadata for queued download $globalKey" }
            }
        }
        emitProgress(globalKey, QUEUED, 0)
        scope.launch { processQueue(client) }
        return stored
    }

    /** Starts a re-requested stacked download over: the row forgets the earlier files before they are deleted. */
    private suspend fun discardStackedAttempt(prior: Downloaded_media) {
        database.resetDownloadParts(prior.global_key, 0)
        partPathsOf(prior).forEachIndexed { index, stored ->
            if (stored == null) return@forEachIndexed
            try {
                deleter.deleteStoredPartFile(prior, index, stored)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to delete file ${index + 1} of an earlier attempt at ${prior.global_key}" }
            }
        }
    }

    private fun mediaSourceIdForIndex(item: MediaItem, mediaIndex: Int): String? =
        item.mediaVersions?.getOrNull(mediaIndex)?.id?.trim()?.takeIf { it.isNotEmpty() }

    /** Prepares and enqueues queued downloads until the queue is empty, blocked, or failing in a row. */
    private suspend fun processQueue(client: MediaBackend) {
        if (skipUnsupported("download queue processing") || queueBlockedByStorageFailure) return
        queueProcessorOverride?.let {
            metadata.fallbackClient = client
            it(client)
            return
        }
        if (isProcessingQueue) {
            // A server that connected mid-drain re-drives the pass: rows it skipped as offline would otherwise wait.
            queueRerunRequested = true
            return
        }
        isProcessingQueue = true
        metadata.fallbackClient = client
        try {
            initializeDownloader()
            do {
                queueRerunRequested = false
                // Heads whose client can't be resolved this pass are skipped, so the drain moves on.
                val skipped = mutableSetOf<String>()
                while (!queueBlockedByStorageFailure) {
                    if (consecutiveQueueFailures >= MAX_CONSECUTIVE_FAILURES) {
                        Log.w(TAG) { "Circuit breaker: $consecutiveQueueFailures consecutive failures, pausing queue" }
                        break
                    }
                    val next = database.getNextQueueItem(skipped) ?: break
                    val itemClient = metadata.clientForDownloadKey(next.media_global_key)
                    if (itemClient == null) {
                        Log.d(TAG) { "Skipping queued download ${next.media_global_key}: server offline" }
                        skipped += next.media_global_key
                        continue
                    }
                    if (prepareAndEnqueueDownload(next.media_global_key, itemClient, next)) consecutiveQueueFailures = 0 else consecutiveQueueFailures++
                }
            } while (queueRerunRequested && !queueBlockedByStorageFailure && consecutiveQueueFailures < MAX_CONSECUTIVE_FAILURES)
        } finally {
            isProcessingQueue = false
            queueRerunRequested = false
        }
    }

    /** Drops any lingering task and resets progress before a fresh attempt. */
    private suspend fun cleanupStaleDownload(globalKey: String) {
        val existingTaskId = database.getBgTaskId(globalKey)
        database.updateBgTaskId(globalKey, null)
        pendingDownloadContext.remove(globalKey)
        cancelNativeTasksForGlobalKey(globalKey, includeTaskId = existingTaskId, reason = "stale task before re-download")
        database.updateDownloadProgress(globalKey, 0, 0, 0)
    }

    private suspend fun requeueDownload(globalKey: String, fallbackClient: MediaBackend? = null) {
        val row = database.getDownloadedMedia(globalKey)
        transitionStatus(globalKey, QUEUED, progress = row?.let(::storedPartsPercent))
        database.addToQueue(globalKey)
        val client = metadata.clientForDownloadKey(globalKey) ?: fallbackClient
        if (client != null) scope.launch { processQueue(client) }
    }

    /** What a stacked download earned with the files it stored, so a resume at a later file doesn't report 0%. */
    private fun storedPartsPercent(row: Downloaded_media): Int {
        val stored = row.nextMissingPartIndex
        if (row.partCount == 1 || stored == null) return 0
        return stored * 100 / row.partCount
    }

    private suspend fun isCancelledOrDeleted(globalKey: String): Boolean {
        if (globalKey in cancellingKeys) return true
        val existing = database.getDownloadedMedia(globalKey)
        return existing == null || existing.downloadStatus == CANCELLED
    }

    private suspend fun isInactiveForEnqueue(globalKey: String): Boolean {
        if (globalKey in cancellingKeys) return true
        val existing = database.getDownloadedMedia(globalKey)
        return existing == null || existing.downloadStatus == COMPLETED || existing.downloadStatus == CANCELLED
    }

    /**
     * Hands [task] to the downloader, its id recorded first so a concurrent cancel finds it. True when the download went
     * inactive meanwhile and the task was dropped again.
     */
    private suspend fun enqueuePreparedTask(globalKey: String, task: DownloadTask, kind: String): Boolean {
        val downloader = checkNotNull(downloader)
        database.updateBgTaskId(globalKey, task.taskId)
        if (!downloader.enqueue(task)) throw IllegalStateException("Failed to enqueue $kind task")
        if (isCancelledOrDeleted(globalKey)) {
            downloader.cancelTasksWithIds(listOf(task.taskId))
            database.updateBgTaskId(globalKey, null)
            database.removeFromQueue(globalKey)
            pendingDownloadContext.remove(globalKey)
            return true
        }
        Log.i(TAG) { "Enqueued $kind task ${task.taskId} for $globalKey" }
        return false
    }

    /**
     * Resolves the item, its URL and its file path, then enqueues its next file. True when enqueued (or the download
     * went inactive); false when it failed at once, which counts towards the circuit breaker.
     */
    private suspend fun prepareAndEnqueueDownload(globalKey: String, client: MediaBackend, queueItem: Download_queue): Boolean {
        if (skipUnsupported("download enqueue")) return false
        if (globalKey in cancellingKeys || queueBlockedByStorageFailure) return true
        try {
            val existing = database.getDownloadedMedia(globalKey)
            if (globalKey in cancellingKeys || existing == null || existing.downloadStatus == COMPLETED || existing.downloadStatus == CANCELLED) {
                Log.d(TAG) { "Skipping enqueue for $globalKey: already completed or deleted" }
                database.removeFromQueue(globalKey)
                return true
            }
            Log.i(TAG) { "Preparing download for $globalKey" }
            cleanupStaleDownload(globalKey)
            if (isInactiveForEnqueue(globalKey)) {
                database.removeFromQueue(globalKey)
                return true
            }
            if (queueBlockedByStorageFailure) return true
            transitionStatus(globalKey, DOWNLOADING, progress = storedPartsPercent(existing))

            val (serverId, ratingKey) = parseGlobalKey(globalKey) ?: throw IllegalStateException("Invalid globalKey: $globalKey")
            var item = metadata.lookup(serverId, ratingKey, existing.client_scope_id)
            if (item == null) {
                // The cache may have been cleared since queueing.
                Log.w(TAG) { "Cache miss for $globalKey, attempting network re-fetch" }
                try {
                    item = client.fetchItem(ratingKey)?.copy(serverId = serverId.value)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "Network re-fetch failed for $globalKey" }
                }
                item ?: throw IllegalStateException("Metadata not found in cache and could not be fetched for $globalKey")
            }
            val mediaIndex = existing.media_index.toInt()
            val quality = existing.transcodeQuality
            var resolution = resolveDownload(client, item, mediaIndex, existing.media_source_id, quality)
            if (resolution.videoUrl == null) {
                Log.w(TAG) { "No video URL from cache for $globalKey, retrying via network" }
                client.fetchItem(ratingKey)?.let { item = it.copy(serverId = serverId.value) }
                resolution = resolveDownload(client, item!!, mediaIndex, existing.media_source_id, quality)
                if (resolution.videoUrl == null) throw IllegalStateException("Could not get video URL for $globalKey")
            }
            val resolvedItem = item!!
            if (resolution.mediaSourceId != null && resolution.mediaSourceId != existing.media_source_id) {
                database.updateDownloadMediaSource(globalKey, resolution.mediaSourceId)
            }
            // A transcode announces no length: the row's total is the estimate its progress runs against.
            resolution.transcode?.expectedBytes?.let { database.updateDownloadProgress(globalKey, 0, 0, it) }
            if (isCancelledOrDeleted(globalKey)) {
                database.removeFromQueue(globalKey)
                pendingDownloadContext.remove(globalKey)
                return true
            }
            val partIndex = partToDownload(globalKey, resolution)
            val showYear = if (resolvedItem.isEpisode) metadata.showYear(serverId, resolvedItem.grandparentId, existing.client_scope_id) else null
            enqueueDownloadPart(globalKey, resolvedItem, client, queueItem, resolution, partIndex, showYear)
            return true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            return handleEnqueueFailure(globalKey, client, e)
        }
    }

    /** Fails, or schedules an app retry of, a download whose next task could not be prepared. */
    private suspend fun handleEnqueueFailure(globalKey: String, client: MediaBackend, e: Exception): Boolean {
        if (isCancelledOrDeleted(globalKey)) {
            database.removeFromQueue(globalKey)
            pendingDownloadContext.remove(globalKey)
            return true
        }
        Log.e(TAG, e) { "Failed to prepare download for $globalKey" }
        // The exception's text names hosts and paths: the row gets a localized reason.
        val errorMessage = T.downloads.errorDownloadFailedWithReason(localizedErrorReason(e))
        val existing = database.getDownloadedMedia(globalKey)
        if (isRetryablePrepareFailure(e) && existing != null && existing.retry_count < MAX_APP_RETRIES &&
            existing.downloadStatus != COMPLETED && existing.downloadStatus != CANCELLED
        ) {
            scheduleDownloadRetry(globalKey, client, existing.retry_count.toInt(), errorMessage, processQueueAfterProgress = false)
        } else {
            transitionStatus(globalKey, FAILED, errorMessage = errorMessage)
            database.removeFromQueue(globalKey)
        }
        pendingDownloadContext.remove(globalKey)
        return false
    }

    /**
     * Which file of [resolution] the next task fetches. A stacked download resumes at its first missing file while its
     * stored files still fit (same count, same storage location); otherwise it starts over, deleting them.
     */
    private suspend fun partToDownload(globalKey: String, resolution: DownloadResolution): Int {
        val row = database.getDownloadedMedia(globalKey) ?: return 0
        val storedParts = row.additionalPartPathList
        val additionalCount = resolution.additionalParts.size
        if (storedParts == null && additionalCount == 0) return 0
        if (storedParts != null && storedParts.size == additionalCount) {
            val next = row.nextMissingPartIndex
            if (next != null && storedPartsMatchCurrentLocation(row)) {
                if (next > 0) Log.i(TAG) { "Resuming $globalKey at file ${next + 1} of ${additionalCount + 1}" }
                return next
            }
        }
        if (storedParts != null) {
            partPathsOf(row).forEachIndexed { index, stored -> if (stored != null) deleter.deleteStoredPartFile(row, index, stored) }
        }
        if (additionalCount > 0) Log.i(TAG) { "Downloading $globalKey as ${additionalCount + 1} files" }
        database.resetDownloadParts(globalKey, additionalCount)
        return 0
    }

    /** Whether [row]'s stored files sit where the next file would go (same storage mode, same document root). */
    private suspend fun storedPartsMatchCurrentLocation(row: Downloaded_media): Boolean {
        val stored = row.storedPartPaths
        val safBaseUri = storage.safBaseUri
        if (storage.isUsingSaf && safBaseUri != null) {
            if (!stored.all(storage::isSafUri)) return false
            val root = safStorage.resolvePersistedPermissionUri(safBaseUri)
            return root != null && root == row.saf_root_uri
        }
        return stored.none(storage::isSafUri)
    }

    /**
     * Builds and enqueues the task of file [partIndex]: the first file takes the item's download path, a later file of a
     * stacked version is named after it in the same folder with its own URL's extension.
     */
    private suspend fun enqueueDownloadPart(
        globalKey: String,
        item: MediaItem,
        client: MediaBackend,
        queueItem: Download_queue,
        resolution: DownloadResolution,
        partIndex: Int,
        showYear: Int?,
    ) {
        val serverId = parseGlobalKey(globalKey)?.first ?: throw IllegalStateException("Invalid globalKey: $globalKey")
        val videoUrl = resolution.videoUrl!!
        val firstExt = downloadExtensionFromUrl(videoUrl) ?: DEFAULT_EXTENSION
        val url = if (partIndex == 0) videoUrl else resolution.additionalParts[partIndex - 1].url
        val ext = if (partIndex == 0) firstExt else downloadExtensionFromUrl(url) ?: DEFAULT_EXTENSION
        fun partTarget(firstFile: String) = if (partIndex == 0) firstFile else storage.partFilePath(firstFile, partIndex, ext)

        // Episodes lead with the show, tracks with the artist.
        val trackArtist = item.trackArtistTitle
        val displayName = when {
            item.isEpisode -> "${item.grandparentTitle ?: item.displayTitle} - ${item.displayTitle}"
            item.kind == MediaKind.TRACK && !trackArtist.isNullOrEmpty() -> "$trackArtist - ${item.displayTitle}"
            else -> item.displayTitle
        }
        val requiresWiFi = settings.value(AppSettings.downloadOnWifiOnly)

        ledger.serialize {
            if (queueBlockedByStorageFailure) return@serialize true
            val safBaseUri = storage.safBaseUri
            val task: DownloadTask
            val filePath: String
            val safRootUri: String?
            if (storage.isUsingSaf && safBaseUri != null) {
                val rootUri = safStorage.resolvePersistedPermissionUri(safBaseUri) ?: throw IllegalStateException("Selected SAF root has no persisted permission")
                ledger.replaceDownloadSafRootClaim(globalKey, rootUri)
                // A document task writes straight into the document and resumes by appending. It must allow pause:
                // only a pausable task carries on across Android's run window instead of failing at its end.
                val target = storage.safTarget(item, firstExt, showYear, serverId.value)
                val fileName = partTarget(target.fileName)
                val dirUri = safStorage.createNestedDirectories(rootUri, target.components) ?: throw IllegalStateException("Failed to create SAF directory")
                cleanupSafTargetFile(dirUri, fileName)
                task = newTask(url, fileName, directory = "", BaseDirectory.ROOT, dirUri, globalKey, displayName, requiresWiFi)
                filePath = dirUri
                safRootUri = rootUri
            } else {
                ledger.replaceDownloadSafRootClaim(globalKey, null)
                val firstFilePath = when {
                    item.isMovie -> storage.getMovieVideoPath(item, firstExt)
                    item.isEpisode -> storage.getEpisodeVideoPath(item, firstExt, showYear)
                    item.isTrack -> storage.getTrackAudioPath(item, firstExt)
                    else -> storage.getVideoFilePath(serverId, item.id, firstExt)
                }
                val downloadFilePath = partTarget(firstFilePath)
                // Leftovers of earlier attempts would make the downloader number its file. The name carries this
                // item's identity, so whatever sits there is this item's own.
                files.deleteIfExists(downloadFilePath, "stale video before re-download")
                files.deleteIfExists("$downloadFilePath.part", "stale .part before re-download")
                files.createDirectories(LocalPath.dirname(downloadFilePath))
                val location = storage.resolveTaskDirectory(downloadFilePath)
                task = newTask(url, LocalPath.basename(downloadFilePath), location.directory, location.baseDirectory, null, globalKey, displayName, requiresWiFi)
                filePath = downloadFilePath
                safRootUri = null
            }
            pendingDownloadContext[globalKey] = DownloadContext(item, queueItem, filePath, ext, client, resolution, partIndex, showYear, safRootUri)
            enqueuePreparedTask(globalKey, task, if (safRootUri != null) "SAF download" else "download")
        }
    }

    private fun newTask(
        url: String,
        filename: String,
        directory: String,
        baseDirectory: BaseDirectory,
        directoryUri: String?,
        globalKey: String,
        displayName: String,
        requiresWiFi: Boolean,
    ) = DownloadTask(
        taskId = newTaskId(),
        url = url,
        filename = filename,
        directory = directory,
        baseDirectory = baseDirectory,
        directoryUri = directoryUri,
        metaData = globalKey,
        displayName = displayName,
        requiresWiFi = requiresWiFi,
        retries = NATIVE_RETRIES,
        allowPause = true,
        creationTime = kotlin.time.Clock.System.now().toEpochMilliseconds(),
    )

    /**
     * Deletes the target document and every numbered copy of it ("name (1).ext", "name.ext (1)", at any depth) before
     * a document task writes it again: document providers number a conflicting name instead of replacing it.
     */
    private suspend fun cleanupSafTargetFile(dirUri: String, fileName: String) {
        val children = safStorage.list(dirUri) ?: return
        val base = LocalPath.withoutExtension(fileName)
        val ext = fileName.removePrefix(base)
        val duplicate = Regex("^${Regex.escape(base)}( \\(\\d+\\))+${Regex.escape(ext)}$|^${Regex.escape(fileName)}( \\(\\d+\\))+$")
        for (child in children) {
            if (child.isDir || (child.name != fileName && !duplicate.matches(child.name))) continue
            if (safStorage.delete(child.uri, isDir = false)) Log.i(TAG) { "Deleted stale SAF copy before re-download: ${child.uri}" }
        }
    }

    /**
     * Fetches file [partIndex] of a stacked download once the previous file landed. Without this session's context (a
     * restart between files) or after the location changed, the row goes back to the queue, whose next pass resumes
     * or restarts it.
     */
    private suspend fun continueStackedDownload(globalKey: String, partIndex: Int, ctx: DownloadContext?) {
        if (disposed) return
        try {
            val row = database.getDownloadedMedia(globalKey) ?: return
            if (row.downloadStatus != DOWNLOADING || globalKey in cancellingKeys || globalKey in pausingKeys) return
            if (ctx == null || !storedPartsMatchCurrentLocation(row)) {
                Log.i(TAG) { "Re-queueing $globalKey for file ${partIndex + 1} of ${row.partCount}" }
                transitionStatus(globalKey, QUEUED, progress = storedPartsPercent(row))
                if (queueItemFor(globalKey) == null) database.addToQueue(globalKey)
                val client = ctx?.client ?: metadata.clientForDownloadKey(globalKey)
                if (client != null) scope.launch { processQueue(client) }
                return
            }
            Log.i(TAG) { "Downloading file ${partIndex + 1} of ${row.partCount} for $globalKey" }
            try {
                enqueueDownloadPart(globalKey, ctx.metadata, ctx.client, ctx.queueItem, ctx.resolution, partIndex, ctx.showYear)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                handleEnqueueFailure(globalKey, ctx.client, e)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Failed to continue stacked download $globalKey" }
        }
    }

    private suspend fun queueItemFor(globalKey: String): Download_queue? = database.getQueue().firstOrNull { it.media_global_key == globalKey }

    // Downloader reports

    /** The row when [taskId] is its current task (in [requiredStatus]); else null, cancelling the stale task if asked. */
    private suspend fun downloadForCurrentTaskSession(
        globalKey: String,
        taskId: String,
        event: String,
        cancelStale: Boolean = false,
        requiredStatus: DownloadedMediaStatus? = null,
    ): Downloaded_media? {
        val existing = database.getDownloadedMedia(globalKey)
        val statusMatches = requiredStatus == null || existing?.downloadStatus == requiredStatus
        if (existing != null && existing.bg_task_id == taskId && statusMatches) return existing
        Log.d(TAG) { "Ignoring stale download $event for $globalKey from task $taskId (current task: ${existing?.bg_task_id ?: "none"}, status: ${existing?.downloadStatus ?: "none"})" }
        if (cancelStale) cancelNativeTask(globalKey, taskId, "stale $event")
        return null
    }

    private suspend fun handleTaskProgress(update: TaskProgressUpdate) {
        if (disposed) return
        val globalKey = update.task.metaData
        if (globalKey.isEmpty() || update.progress < 0) return
        val existing = downloadForCurrentTaskSession(globalKey, update.task.taskId, "progress", cancelStale = true) ?: return
        // A stacked download reports the whole item: the stored files plus the one this task fetches.
        val partCount = existing.partCount
        val storedBytes = if (partCount == 1) 0L else storedPartBytesFor(existing, update.task)
        // A pause in flight (or just recorded) keeps reporting until it stops the task; cancelling here would discard
        // the resume data the pause is producing.
        if (globalKey in pausingKeys || existing.downloadStatus == PAUSED) return
        if (existing.downloadStatus != DOWNLOADING) {
            cancelNativeTask(globalKey, update.task.taskId, "progress for inactive download")
            return
        }
        if (globalKey in cancellingKeys) {
            cancelNativeTask(globalKey, update.task.taskId, "cancellation in progress")
            return
        }
        val speed = update.bytesPerSecond.coerceAtLeast(0).toDouble()
        // A transcode announces no length: it runs against the estimate stored as the row's total, short of the end
        // until the file is whole.
        val estimate = existing.total_bytes?.takeIf { it > 0 && update.expectedFileSize <= 0 && !existing.transcodeQuality.isOriginal }
        val fileBytes = when {
            update.expectedFileSize > 0 -> update.expectedFileSize
            estimate != null -> maxOf(estimate, update.downloadedBytes)
            else -> 0L
        }
        val fileProgress = if (estimate != null) minOf(update.downloadedBytes.toDouble() / fileBytes, TRANSCODE_PROGRESS_CAP) else update.progress
        val fileDownloaded = when {
            estimate != null -> update.downloadedBytes.coerceAtLeast(0)
            fileBytes > 0 -> (update.progress * fileBytes).roundToLong()
            else -> 0L
        }
        val partIndex = existing.nextMissingPartIndex ?: (partCount - 1)
        val percent = ((partIndex + fileProgress) * 100 / partCount).roundToInt().coerceIn(0, 100)
        val downloadedBytes = storedBytes + fileDownloaded
        val totalBytes = if (fileBytes > 0) storedBytes + fileBytes else 0L
        progress.tryEmit(DownloadProgress(globalKey, DOWNLOADING, percent, downloadedBytes, totalBytes, speed, currentFile = "video"))
        // The stream is live; the row keeps the latest value for a restart, written at most every interval.
        val writtenAt = rowProgress[globalKey]?.writtenAt?.takeIf { it.elapsedNow() < PROGRESS_WRITE_INTERVAL }
        rowProgress[globalKey] = RowProgress(percent, downloadedBytes, totalBytes, writtenAt ?: timeSource.markNow())
        if (writtenAt == null) database.updateDownloadProgress(globalKey, percent, downloadedBytes, totalBytes)
    }

    private class RowProgress(val percent: Int, val downloadedBytes: Long, val totalBytes: Long, val writtenAt: TimeMark)

    private fun Double.roundToLong(): Long = kotlin.math.round(this).toLong()

    private suspend fun storedPartBytesFor(row: Downloaded_media, task: DownloadTask): Long {
        val cached = storedPartBytes[row.global_key]
        if (cached != null && cached.first == task.taskId) return cached.second.await()
        val bytes = scope.async { measureStoredParts(row, task) }
        storedPartBytes[row.global_key] = task.taskId to bytes
        return bytes.await()
    }

    /** The size of [row]'s stored files; documents are measured through the folder [task] writes into. */
    private suspend fun measureStoredParts(row: Downloaded_media, task: DownloadTask): Long {
        var total = 0L
        var safSiblings: List<SafDocumentFile>? = null
        for (stored in row.storedPartPaths) {
            try {
                if (storage.isSafUri(stored)) {
                    val siblings = safSiblings ?: (task.directoryUri?.let { safStorage.list(it) }.orEmpty()).also { safSiblings = it }
                    total += siblings.firstOrNull { it.uri == stored }?.length ?: 0
                } else {
                    total += files.size(storage.ensureAbsolutePath(stored))
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Could not measure stored file of ${row.global_key}: $stored" }
            }
        }
        return total
    }

    private suspend fun handleTaskStatus(update: TaskStatusUpdate) {
        if (disposed) return
        val globalKey = update.task.metaData
        if (globalKey.isEmpty()) return
        Log.d(TAG) { "Background task status: ${update.status} for $globalKey (task ${update.task.taskId})" }
        val active = update.status == TaskStatus.ENQUEUED || update.status == TaskStatus.RUNNING || update.status == TaskStatus.WAITING_TO_RETRY
        downloadForCurrentTaskSession(globalKey, update.task.taskId, "status ${update.status}", cancelStale = active, requiredStatus = DOWNLOADING) ?: return
        try {
            when (update.status) {
                TaskStatus.COMPLETE -> onDownloadComplete(globalKey, update.task)
                TaskStatus.FAILED -> onDownloadFailed(globalKey, update.task.taskId, update.exception)
                TaskStatus.NOT_FOUND -> onDownloadPermanentlyFailed(globalKey, update.task.taskId, T.downloads.errorFileNotFound)
                TaskStatus.CANCELED -> if (globalKey !in pausingKeys && globalKey !in cancellingKeys) onDownloadCanceledOutsideApp(globalKey, update.task.taskId)
                TaskStatus.PAUSED -> if (globalKey !in pausingKeys) onDownloadPausedOutsideApp(globalKey, update.task.taskId)
                TaskStatus.WAITING_TO_RETRY -> Log.d(TAG) { "Download waiting to retry for $globalKey" }
                TaskStatus.ENQUEUED, TaskStatus.RUNNING -> {
                    // The downloader promoted a task the app is pausing or cancelling.
                    if (globalKey in pausingKeys) cancelNativeTask(globalKey, update.task.taskId, "pause in progress")
                    if (globalKey in cancellingKeys) cancelNativeTask(globalKey, update.task.taskId, "cancellation in progress")
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Error handling download status change for $globalKey" }
        }
    }

    /**
     * The shared entry of terminal reports: ignored while cancelling or completing, or for a stale task; otherwise
     * stops the download's timers and context and returns its row.
     */
    private suspend fun claimTerminalEvent(globalKey: String, taskId: String, event: String): Downloaded_media? {
        if (globalKey in cancellingKeys || globalKey in completingKeys) {
            Log.d(TAG) { "Ignoring $event for $globalKey: cancellation or completion in progress" }
            return null
        }
        val existing = downloadForCurrentTaskSession(globalKey, taskId, event, requiredStatus = DOWNLOADING) ?: return null
        cancelDownloadTimers(globalKey)
        pendingDownloadContext.remove(globalKey)
        return existing
    }

    /**
     * A cancel the app didn't issue (the notification's Cancel, iOS after a force quit): the user asked for the stop, so
     * the download ends cancelled instead of starting over.
     */
    private suspend fun onDownloadCanceledOutsideApp(globalKey: String, taskId: String) {
        claimTerminalEvent(globalKey, taskId, "cancellation outside the app") ?: return
        Log.i(TAG) { "Download $globalKey was cancelled outside the app (task $taskId)" }
        database.updateBgTaskId(globalKey, null)
        markCancelled(globalKey)
    }

    /**
     * A pause the app didn't issue (the notification's Pause): the download ends paused as [pauseDownload] leaves it,
     * so Resume continues its task.
     */
    private suspend fun onDownloadPausedOutsideApp(globalKey: String, taskId: String) {
        claimTerminalEvent(globalKey, taskId, "pause outside the app") ?: return
        Log.i(TAG) { "Download $globalKey was paused outside the app (task $taskId)" }
        markPaused(globalKey)
    }

    /** A paused download keeps its task (and the resume data), its last progress, and leaves the queue. */
    private suspend fun markPaused(globalKey: String) {
        rowProgress.remove(globalKey)?.let { database.updateDownloadProgress(globalKey, it.percent, it.downloadedBytes, it.totalBytes) }
        transitionStatus(globalKey, PAUSED)
        database.removeFromQueue(globalKey)
    }

    /** A user action (new download, resume, retry) lifts a storage-failure block and resets the circuit breaker. */
    private fun rearmQueueForUserAction(operation: String) {
        consecutiveQueueFailures = 0
        if (!queueBlockedByStorageFailure) return
        Log.i(TAG) { "Resuming download queue after storage failure: $operation" }
        queueBlockedByStorageFailure = false
    }

    /**
     * Re-arms the queue for a download the user asked for: once per request, before its items are queued, so a stop
     * during a season's or list's expansion holds the rest of it. Automatic enqueues (sync rules) never lift a stop:
     * each pass would refuse the same file and stop every download again.
     */
    fun beginUserDownloadRequest() = rearmQueueForUserAction("new download")

    /** The device is full: every active download fails with the storage error, then the downloader stops. */
    private suspend fun handleStorageFullFailure(globalKey: String, taskId: String, message: String?) {
        queueBlockedByStorageFailure = true
        autoRetryTimers.values.forEach { it.cancel() }
        autoRetryTimers.clear()
        // The rows fail before the downloader stops: its reset reports each task canceled, which a row still
        // downloading would take as a user cancel.
        val errorMessage = message ?: T.downloads.storageFull
        val failedKeys = database.failActiveDownloadsForStorageFull(errorMessage)
        for (key in failedKeys) {
            cancelDownloadTimers(key)
            pendingDownloadContext.remove(key)
            emitProgress(key, FAILED, 0, errorMessage = errorMessage)
        }
        downloader?.let { downloader ->
            try {
                downloader.deleteRecord(taskId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to discard partial download for $globalKey" }
            }
            try {
                downloader.reset()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Failed to stop native download queue after storage exhaustion" }
            }
        }
        Log.e(TAG) { "Download storage safety check stopped ${failedKeys.size} active download(s)" }
    }

    private fun isRetryablePrepareFailure(error: Throwable): Boolean {
        if (error !is MediaServerHttpException || error.isCancellation) return false
        val status = error.statusCode
        if (status == 401 || status == 403) return false
        return error.isTransient || (status != null && status >= 500)
    }

    private suspend fun scheduleDownloadRetry(globalKey: String, client: MediaBackend, retryCount: Int, errorMessage: String, processQueueAfterProgress: Boolean) {
        Log.w(TAG) { "Download failed for $globalKey (attempt ${retryCount + 1}/$MAX_APP_RETRIES), scheduling auto-retry in $autoRetryDelay" }
        transitionStatus(globalKey, FAILED, errorMessage = errorMessage)
        database.countDownloadRetry(globalKey)
        database.removeFromQueue(globalKey)
        autoRetryTimers.remove(globalKey)?.cancel()
        autoRetryTimers[globalKey] = scope.launch {
            delay(autoRetryDelay)
            autoRetryTimers.remove(globalKey)
            performAutoRetry(globalKey)
        }
        if (processQueueAfterProgress) scope.launch { processQueue(client) }
    }

    /**
     * A failed transfer: storage exhaustion stops the queue; a 403, a 500 (with the bitrate hint), and a host that
     * can't be found or refuses the connection fail for good; otherwise an app retry while retries remain. The user
     * never sees the native description, only the log does: an HTTP body is the server's, other text the platform's (it
     * can quote the tokenized URL); a server's own full disk says nothing about this device's.
     */
    private suspend fun onDownloadFailed(globalKey: String, taskId: String, exception: TaskException?) {
        val existing = claimTerminalEvent(globalKey, taskId, "failure") ?: return
        val httpStatus = (exception as? TaskException.HttpResponse)?.httpResponseCode
        if (exception != null) {
            val detail = exception.description
            Log.w(TAG) { "Download of $globalKey failed with ${exception::class.simpleName}${httpStatus?.let { " (HTTP $it)" } ?: ""}: ${if (detail.length > 500) detail.take(500) + "…" else detail}" }
        }
        if (httpStatus == null && exception != null && isStorageFullDownloadFailure(exception)) {
            handleStorageFullFailure(globalKey, taskId, if (exception.description.lowercase().contains(CAPACITY_UNKNOWN)) T.downloads.storageUnavailable else null)
            return
        }
        // A refusal of this account or connection doesn't clear on retry.
        if (httpStatus == 403) {
            failPermanently(globalKey, T.downloads.errorDownloadNotAllowed)
            return
        }
        val errorMessage = when (exception) {
            null -> T.downloads.errorDownloadFailed
            is TaskException.HttpResponse -> T.downloads.errorHttpStatus(exception.httpResponseCode.toString())
            else -> T.downloads.errorDownloadFailedWithReason(nativeDownloadFailureReason(exception))
        }
        // A host that can't be found or refuses the connection exhausts the native retries in milliseconds.
        val isNetworkError = exception is TaskException.Connection && exception.description in UNREACHABLE_HOST_KINDS
        val isServerError = httpStatus == 500
        val client = metadata.clientForDownloadKey(globalKey)
        if (!isNetworkError && !isServerError && existing.retry_count < MAX_APP_RETRIES && client != null) {
            scheduleDownloadRetry(globalKey, client, existing.retry_count.toInt(), errorMessage, processQueueAfterProgress = existing.downloaded_bytes > 0)
        } else {
            if (isNetworkError) Log.w(TAG) { "Network error for $globalKey, failing permanently (no auto-retry)" }
            failPermanently(globalKey, if (isServerError) T.downloads.serverErrorBitrate else errorMessage)
        }
    }

    private fun isStorageFullDownloadFailure(exception: TaskException): Boolean =
        isStorageFullMessage(exception.description) || exception.description.lowercase().contains(CAPACITY_UNKNOWN)

    /** A failure that doesn't clear on retry (404): fails at once and moves the queue on. */
    private suspend fun onDownloadPermanentlyFailed(globalKey: String, taskId: String, errorMessage: String) {
        claimTerminalEvent(globalKey, taskId, "permanent failure") ?: return
        failPermanently(globalKey, errorMessage)
    }

    private suspend fun failPermanently(globalKey: String, errorMessage: String) {
        Log.e(TAG) { "Download permanently failed for $globalKey" }
        transitionStatus(globalKey, FAILED, errorMessage = errorMessage)
        database.removeFromQueue(globalKey)
        metadata.clientForDownloadKey(globalKey)?.let { client -> scope.launch { processQueue(client) } }
    }

    private suspend fun performAutoRetry(globalKey: String) {
        if (disposed) return
        val client = metadata.clientForDownloadKey(globalKey)
        if (client == null) {
            Log.w(TAG) { "Cannot auto-retry $globalKey: no client available" }
            return
        }
        // Cancelled, deleted or retried by the user during the delay.
        if (database.getDownloadedMedia(globalKey)?.downloadStatus != FAILED) return
        // A storage stop cancels the retry timers, not a retry already past its timer.
        if (queueBlockedByStorageFailure) return
        Log.i(TAG) { "Auto-retrying download for $globalKey" }
        cleanupStaleDownload(globalKey)
        if (queueBlockedByStorageFailure) return
        // The retry delay already throttles failures: the circuit breaker must not suppress the attempt.
        consecutiveQueueFailures = 0
        requeueDownload(globalKey, client)
    }

    /**
     * A file landed: its path is stored, then either the next file of a stacked version is fetched or the
     * supplementary files are downloaded and the download completes.
     */
    private suspend fun onDownloadComplete(globalKey: String, task: DownloadTask) {
        consecutiveQueueFailures = 0
        // The downloader can replay a completion.
        if (globalKey in completingKeys) return
        completingKeys += globalKey
        var nextPart: Int? = null
        var nextPartContext: DownloadContext? = null
        try {
            val existingCheck = downloadForCurrentTaskSession(globalKey, task.taskId, "completion", requiredStatus = DOWNLOADING)
            if (globalKey in cancellingKeys || existingCheck == null) return
            cancelDownloadTimers(globalKey)
            val ctx = pendingDownloadContext.remove(globalKey)
            // Files are fetched in order: after a restart the task wrote the row's first missing file.
            val partIndex = ctx?.partIndex ?: existingCheck.nextMissingPartIndex

            val storedPath = if (ctx != null) storedPathFromContext(ctx, task) else storedPathAfterRestart(globalKey, task, existingCheck, partIndex) ?: return

            if (!existingCheck.transcodeQuality.isOriginal) {
                val runtimeMs = ctx?.resolution?.transcode?.durationMs ?: metadata.metadataFor(globalKey)?.durationMs
                val size = verifiedTranscodeSize(storedPath, runtimeMs)
                if (size == null) {
                    discardIncompleteTranscode(globalKey, storedPath, existingCheck)
                    return
                }
                database.updateDownloadProgress(globalKey, 100, size, size)
            }

            val partCount = existingCheck.partCount
            if (partIndex == null || partIndex == 0) {
                database.updateVideoFilePath(globalKey, storedPath, stampDownloadedAt = partCount == 1 || partIndex == null)
            } else {
                database.updateAdditionalPartPath(globalKey, partIndex, storedPath, stampDownloadedAt = partIndex == partCount - 1)
            }
            val recorded = database.getDownloadedMedia(globalKey)
            val missingPart = recorded?.nextMissingPartIndex
            if (missingPart != null) {
                // Detach the finished task while the key is held: a replay of its completion must read as stale.
                database.updateBgTaskId(globalKey, null)
                nextPart = missingPart
                nextPartContext = ctx
                return
            }

            val persistedQueueItem = queueItemFor(globalKey)
            val queueItem = ctx?.queueItem ?: persistedQueueItem
            val downloadArtwork = queueItem?.download_artwork ?: true
            val downloadSubtitles = queueItem?.download_subtitles ?: true
            var artworkSettled = !downloadArtwork
            var subtitlesSettled = !downloadSubtitles
            try {
                val item = ctx?.metadata ?: metadata.metadataFor(globalKey)
                val client = ctx?.client ?: metadata.clientForDownloadKey(globalKey)
                if (item != null && client != null) {
                    val settled = runSupplementaryDownloads(
                        globalKey, item, client, isRepair = false, downloadArtwork, downloadSubtitles, existingCheck, ctx?.showYear,
                        partPaths = recorded?.let(::partPathsOf) ?: listOf(storedPath),
                        preresolvedSubtitles = ctx?.subtitlesPerPart,
                    )
                    artworkSettled = settled.first
                    subtitlesSettled = settled.second
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Supplementary downloads failed for $globalKey (video is saved)" }
            }

            // The video is done whatever became of the supplementary files.
            transitionStatus(globalKey, COMPLETED)
            try {
                when {
                    artworkSettled && subtitlesSettled -> database.removeFromQueue(globalKey)
                    persistedQueueItem != null -> database.updateSupplementaryQueueIntent(globalKey, !subtitlesSettled, !artworkSettled)
                    else -> database.addToQueue(globalKey, queueItem?.priority?.toInt() ?: 0, !subtitlesSettled, !artworkSettled)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Failed to settle supplementary queue state for $globalKey" }
            }
            Log.i(TAG) { "Download completed for $globalKey" }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Post-download processing failed for $globalKey" }
            // The error can carry file paths and platform text: the row gets a localized reason.
            val reason = when {
                isStorageFullError(e) -> T.downloads.reasonDeviceStorageFull
                e is IOException -> T.downloads.reasonFileNotSaved
                else -> localizedErrorReason(e)
            }
            transitionStatus(globalKey, FAILED, errorMessage = T.downloads.errorPostProcessing(reason))
            database.removeFromQueue(globalKey)
        } finally {
            completingKeys -= globalKey
            nextPart?.let { continueStackedDownload(globalKey, it, nextPartContext) }
            // The queue moves on, even after an error.
            metadata.clientForDownloadKey(globalKey)?.let { client -> scope.launch { processQueue(client) } }
        }
    }

    private suspend fun storedPathFromContext(ctx: DownloadContext, task: DownloadTask): String {
        if (!ctx.isSafMode) return storage.toRelativePath(ctx.filePath)
        safStorage.getChild(ctx.filePath, listOf(task.filename))?.let { return it.uri }
        val root = ctx.safRootUri ?: throw IllegalStateException("SAF download context has no root claim")
        return resolveSafStoredPath(ctx.metadata, ctx.extension, ctx.showYear, root, ctx.partIndex)
            ?: throw IllegalStateException("Cannot determine SAF file URI")
    }

    /** The path the task wrote, without this session's context (the app restarted); null when there is nothing to record. */
    private suspend fun storedPathAfterRestart(globalKey: String, task: DownloadTask, existingCheck: Downloaded_media, partIndex: Int?): String? {
        val existing = database.getDownloadedMedia(globalKey)
        if (existing?.video_file_path != null && existing.downloadStatus == COMPLETED) return null
        if (partIndex == null) return existingCheck.video_file_path!!
        val directoryUri = task.directoryUri
        if (directoryUri == null) {
            // The downloader rejoins the base directory a root task's directory is relative to.
            return storage.toRelativePath(checkNotNull(downloader).filePath(task))
        }
        // Restore the row's originating root before resolving any path: the selected root may have changed.
        val safRootUri = existing?.saf_root_uri ?: safStorage.resolvePersistedPermissionUri(directoryUri)
            ?: throw IllegalStateException("Cannot recover SAF root ownership")
        ledger.serialize { ledger.replaceDownloadSafRootClaim(globalKey, safRootUri) }
        safStorage.getChild(directoryUri, listOf(task.filename))?.let { return it.uri }
        val (serverId, ratingKey) = parseGlobalKey(globalKey) ?: throw IllegalStateException("Invalid globalKey for recovery: $globalKey")
        val item = metadata.lookup(serverId, ratingKey, existing?.client_scope_id) ?: throw IllegalStateException("No metadata for SAF recovery of $globalKey")
        val ext = downloadExtensionFromUrl(task.url) ?: DEFAULT_EXTENSION
        val showYear = resolveSafRecoveryShowYear(item, existing?.client_scope_id)
        return resolveSafStoredPath(item, ext, showYear, safRootUri, partIndex)
            ?: showYear?.let { resolveSafStoredPath(item, ext, null, safRootUri, partIndex) }
            ?: throw IllegalStateException("Cannot resolve SAF path on recovery")
    }

    /** The document of file [partIndex] of [item]'s download under [safRootUri]. */
    private suspend fun resolveSafStoredPath(item: MediaItem, ext: String, showYear: Int?, safRootUri: String, partIndex: Int): String? {
        val target = storage.safTarget(item, ext, showYear, item.serverId)
        val fileName = if (partIndex == 0) target.fileName else storage.partFilePath(target.fileName, partIndex, ext)
        val dirUri = safStorage.createNestedDirectories(safRootUri, target.components) ?: return null
        return safStorage.getChild(dirUri, listOf(fileName))?.uri
    }

    private suspend fun resolveSafRecoveryShowYear(item: MediaItem, clientScopeId: String?): Int? {
        val serverId = item.serverId
        if (!item.isEpisode || serverId == null) return null
        return metadata.showYear(ServerId(serverId), item.grandparentId, clientScopeId)
    }

    // Supplementary files

    /**
     * Best-effort artwork, chapter thumbnails and subtitles for a stored video; returns whether each half (artwork,
     * subtitles) settled so the caller can keep the rest pending.
     */
    private suspend fun runSupplementaryDownloads(
        globalKey: String,
        item: MediaItem,
        client: MediaBackend,
        isRepair: Boolean,
        downloadArtwork: Boolean,
        downloadSubtitles: Boolean,
        record: Downloaded_media?,
        showYear: Int?,
        partPaths: List<String?>,
        preresolvedSubtitles: List<List<DownloadSubtitleSpec>>? = null,
    ): Pair<Boolean, Boolean> {
        var artworkSettled = !downloadArtwork
        if (downloadArtwork) {
            val itemArtwork = downloadArtwork(globalKey, item, client, isRepair)
            val chapters = item.serverId?.let { downloadChapterThumbnails(ServerId(it), item.id, client) } ?: false
            artworkSettled = itemArtwork && chapters
        }
        var subtitlesSettled = !downloadSubtitles
        if (downloadSubtitles) {
            try {
                var subtitles = preresolvedSubtitles
                if (subtitles == null) {
                    val resolution = resolveDownload(client, item, record?.media_index?.toInt() ?: 0, record?.media_source_id, record?.transcodeQuality ?: TranscodeQualityPreset.ORIGINAL)
                    if (resolution.externalSubtitlesResolved) subtitles = resolution.subtitlesPerPart() else Log.d(TAG) { "Subtitle enrichment remains deferred for $globalKey" }
                }
                if (subtitles != null) subtitlesSettled = downloadSubtitles(globalKey, item, subtitles, isRepair, showYear, partPaths)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Could not resolve subtitles for $globalKey" }
            }
        }
        return artworkSettled to subtitlesSettled
    }

    private suspend fun downloadArtwork(globalKey: String, item: MediaItem, client: MediaBackend, isRepair: Boolean): Boolean {
        val serverId = item.serverId ?: return false
        return try {
            if (!isRepair) emitProgress(globalKey, DOWNLOADING, 0, currentFile = "artwork")
            val settled = artwork.ensureArtworkSpecs(ServerId(serverId), client.resolveDownloadArtwork(item))
            val thumb = item.thumbPath?.let(::artworkStorageKey)
            database.updateArtworkPaths(globalKey, thumb)
            emit(DownloadProgress(globalKey, if (isRepair) COMPLETED else DOWNLOADING, if (isRepair) 100 else 0, currentFile = "artwork", thumbPath = thumb))
            settled
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to download artwork for $globalKey" }
            false
        }
    }

    /** Downloads the artwork of a parent item (show, season, album) for offline display. */
    suspend fun downloadArtworkForMetadata(metadata: MediaItem, client: MediaBackend) {
        val serverId = metadata.serverId ?: return
        artwork.ensureArtworkSpecs(ServerId(serverId), client.resolveDownloadArtwork(metadata))
    }

    private suspend fun downloadChapterThumbnails(serverId: ServerId, ratingKey: String, client: MediaBackend): Boolean = try {
        val extras = client.fetchPlaybackExtras(ratingKey)
        var allSettled = true
        for (chapter in extras.chapters) {
            val thumb = chapter.thumb?.takeIf { it.isNotEmpty() } ?: continue
            val url = client.thumbnailUrl(thumb)
            if (url.isEmpty() || !artwork.downloadSingleArtwork(serverId, DownloadArtworkSpec(thumb, url))) allSettled = false
        }
        allSettled
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Failed to download chapter thumbnails" }
        false
    }

    /**
     * Saves each stored file's external subtitles beside it (a later file of a stacked version keeps its own, a
     * document's in an app-managed folder). Only the files the row stores get sidecars.
     */
    private suspend fun downloadSubtitles(
        globalKey: String,
        item: MediaItem,
        subtitlesPerPart: List<List<DownloadSubtitleSpec>>,
        isRepair: Boolean,
        showYear: Int?,
        partPaths: List<String?>,
    ): Boolean {
        if (!isRepair) emitProgress(globalKey, DOWNLOADING, 0, currentFile = "subtitles")
        var allSettled = true
        for (partIndex in 0 until minOf(partPaths.size, subtitlesPerPart.size)) {
            val videoFilePath = partPaths[partIndex]
            val sidecarDirectory: String? = if (partIndex == 0) {
                // Movie and episode sidecars sit next to the video as named on disk, where playback looks.
                if ((item.isMovie || item.isEpisode) && videoFilePath != null && !storage.isSafUri(videoFilePath)) {
                    storage.sidecarSubtitlesDirectoryPath(storage.ensureAbsolutePath(videoFilePath))
                } else {
                    null
                }
            } else {
                if (videoFilePath == null) continue
                try {
                    if (storage.isSafUri(videoFilePath)) {
                        storage.getPartSubtitlesDirectory(ServerId(item.serverId!!), item.id, partIndex)
                    } else {
                        storage.sidecarSubtitlesDirectoryPath(storage.ensureAbsolutePath(videoFilePath))
                    }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    allSettled = false
                    Log.w(TAG, e) { "No subtitle folder for file ${partIndex + 1} of $globalKey" }
                    continue
                }
            }
            for (subtitle in subtitlesPerPart[partIndex]) {
                try {
                    val extension = subtitleExtension(subtitle.codec)
                    val serverId = ServerId(item.serverId!!)
                    val subtitlePath = when {
                        sidecarDirectory != null -> LocalPath.join(sidecarDirectory, "${subtitle.id}.$extension")
                        storage.isUsingSaf -> storage.getSubtitlePath(serverId, item.id, subtitle.id, extension)
                        item.isEpisode -> storage.getEpisodeSubtitlePath(item, subtitle.id, extension, showYear)
                        item.isMovie -> storage.getMovieSubtitlePath(item, subtitle.id, extension)
                        else -> storage.getSubtitlePath(serverId, item.id, subtitle.id, extension)
                    }
                    if (files.exists(subtitlePath)) continue
                    files.createDirectories(LocalPath.dirname(subtitlePath))
                    http.downloadFile(subtitle.url, subtitlePath)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    allSettled = false
                    Log.w(TAG, e) { "Failed to download subtitle ${subtitle.id} for $globalKey" }
                }
            }
        }
        return allSettled
    }

    /** Repairs artwork of completed downloads that is missing (also their show and season artwork). */
    suspend fun repairMissingArtworkForDownloads() {
        if (isRepairingArtwork || isOffline) return
        isRepairingArtwork = true
        try {
            val ensuredParents = mutableSetOf<String>()
            for (row in database.getAllDownloads()) {
                if (row.downloadStatus != COMPLETED) continue
                val client = metadata.clientForDownloadKey(row.global_key) ?: continue
                val serverId = ServerId(row.server_id)
                val cached = metadata.lookup(serverId, row.rating_key, row.client_scope_id) ?: continue
                val withServer = if (cached.serverId == null) cached.copy(serverId = row.server_id) else cached
                artwork.ensureArtworkForMetadata(withServer, client)
                backfillArtworkPath(row, withServer)
                if (!withServer.isEpisode) continue
                repairParentArtwork(serverId, withServer.grandparentId, client, ensuredParents, row.client_scope_id)
                repairParentArtwork(serverId, withServer.parentId, client, ensuredParents, row.client_scope_id)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Missing artwork repair failed" }
        } finally {
            isRepairingArtwork = false
        }
    }

    private suspend fun repairParentArtwork(serverId: ServerId, ratingKey: String?, client: MediaBackend, ensured: MutableSet<String>, clientScopeId: String?) {
        if (ratingKey.isNullOrEmpty()) return
        if (!ensured.add(buildGlobalKey(serverId, ratingKey))) return
        val cached = metadata.lookup(serverId, ratingKey, clientScopeId)
        var item = cached
        if (!isOffline) {
            try {
                client.fetchItem(ratingKey)?.let { fetched ->
                    item = mergeFetchedMediaItem(fetched, serverId, cached)
                    metadata.cacheFor(client.backend).pinForOffline(client.cacheServerId, fetched.id)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "Artwork repair parent metadata fetch failed for $serverId:$ratingKey" }
            }
        }
        val resolved = item ?: return
        artwork.ensureArtworkForMetadata(if (resolved.serverId == null) resolved.copy(serverId = serverId.value) else resolved, client)
    }

    private suspend fun backfillArtworkPath(row: Downloaded_media, item: MediaItem) {
        val thumb = item.thumbPath?.takeIf { it.isNotEmpty() } ?: return
        val normalized = artworkStorageKey(thumb)
        if (row.thumb_path == normalized) return
        database.updateArtworkPaths(row.global_key, normalized)
        val status = row.downloadStatus ?: return
        emit(
            DownloadProgress(
                row.global_key, status, if (status == COMPLETED) 100 else row.progress.toInt(), row.downloaded_bytes, row.total_bytes ?: 0,
                thumbPath = normalized,
            ),
        )
    }

    /** Repairs completed videos whose queue row still asks for subtitles or artwork; concurrent calls share one pass. */
    suspend fun repairPendingSupplementaryDownloads() {
        if (disposed || isOffline) return
        val active = supplementaryRepair
        if (active != null && active.isActive) return active.await()
        val repair = scope.async { runPendingSupplementaryRepair() }
        supplementaryRepair = repair
        try {
            repair.await()
        } finally {
            if (supplementaryRepair === repair) supplementaryRepair = null
        }
    }

    private suspend fun runPendingSupplementaryRepair() {
        val queueItems = try {
            database.getPendingSupplementaryQueueItems()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Could not read pending supplementary downloads" }
            return
        }
        for (queueItem in queueItems) {
            if (disposed || isOffline) return
            val globalKey = queueItem.media_global_key
            try {
                val client = metadata.clientForDownloadKey(globalKey) ?: continue
                val item = metadata.metadataFor(globalKey) ?: continue
                val record = database.getDownloadedMedia(globalKey)
                val showYear = if (item.isEpisode && item.grandparentId != null && item.serverId != null) {
                    metadata.showYear(ServerId(item.serverId), item.grandparentId, record?.client_scope_id)
                } else {
                    null
                }
                val (artworkSettled, subtitlesSettled) = runSupplementaryDownloads(
                    globalKey, item, client, isRepair = true, queueItem.download_artwork, queueItem.download_subtitles, record, showYear,
                    partPaths = partPathsOf(record),
                )
                if (artworkSettled && subtitlesSettled) {
                    database.removeFromQueue(globalKey)
                } else {
                    database.updateSupplementaryQueueIntent(globalKey, !subtitlesSettled, !artworkSettled)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Deferred supplementary downloads failed for $globalKey" }
            }
        }
    }

    // Progress

    private fun emit(event: DownloadProgress) {
        if (!disposed) progress.tryEmit(event)
    }

    private fun emitProgress(globalKey: String, status: DownloadedMediaStatus, percent: Int, errorMessage: String? = null, currentFile: String? = null) =
        emit(DownloadProgress(globalKey, status, percent, errorMessage = errorMessage, currentFile = currentFile))

    private fun emitDeletionProgress(event: DeletionProgress) {
        if (!disposed) deletionProgress.tryEmit(event)
    }

    /** Stores [status] (and a failure's [errorMessage]) and reports it; progress defaults to 0, or 100 when completed. */
    private suspend fun transitionStatus(globalKey: String, status: DownloadedMediaStatus, progress: Int? = null, errorMessage: String? = null) {
        rowProgress.remove(globalKey)
        database.updateDownloadStatus(globalKey, status)
        if (status == FAILED && errorMessage != null) database.updateDownloadError(globalKey, errorMessage)
        emitProgress(globalKey, status, progress ?: if (status == COMPLETED) 100 else 0, errorMessage)
    }

    private fun cancelDownloadTimers(key: String) {
        autoRetryTimers.remove(key)?.cancel()
        storedPartBytes.remove(key)
    }

    private fun partPathsOf(row: Downloaded_media?): List<String?> = listOf(row?.video_file_path) + row?.additionalPartPathList.orEmpty()

    // User actions

    /** Pauses a downloading or queued download; a task the downloader can't pause is cancelled and re-fetched on resume. */
    suspend fun pauseDownload(globalKey: String) {
        // Marked first, so a task the downloader promotes meanwhile is cancelled.
        pausingKeys += globalKey
        try {
            cancelDownloadTimers(globalKey)
            val taskId = database.getBgTaskId(globalKey)
            stopServerTranscode(globalKey, taskId)
            cancelNativeTasksForGlobalKey(globalKey, exceptTaskId = taskId, reason = "duplicate task before pause")
            val downloader = downloader
            if (taskId != null && downloader != null) {
                val task = downloader.taskForId(taskId)
                if (task == null || !downloader.pause(task)) downloader.cancelTasksWithIds(listOf(taskId))
            } else if (taskId != null) {
                database.updateBgTaskId(globalKey, null)
            }
            pendingDownloadContext.remove(globalKey)
            markPaused(globalKey)
        } finally {
            pausingKeys -= globalKey
        }
    }

    /** Resumes a paused download where its task stopped, else from scratch. */
    suspend fun resumeDownload(globalKey: String, client: MediaBackend) {
        if (skipUnsupported("download resume")) return
        rearmQueueForUserAction("manual resume")
        val taskId = database.getBgTaskId(globalKey)
        if (taskId != null && tryResumeNativeTask(globalKey, taskId)) return
        cleanupStaleDownload(globalKey)
        requeueDownload(globalKey, client)
    }

    private suspend fun tryResumeNativeTask(globalKey: String, taskId: String): Boolean {
        val downloader = downloader ?: return false
        cancelNativeTasksForGlobalKey(globalKey, exceptTaskId = taskId, reason = "duplicate task before resume")
        var markedDownloading = false
        try {
            val task = downloader.taskForId(taskId) ?: return false
            // The row reads downloading before the task goes back: the downloader reports it (desktop inside resume)
            // and a report that found the row paused would cancel the task, discarding its resume data.
            transitionStatus(globalKey, DOWNLOADING)
            markedDownloading = true
            if (downloader.resume(task)) {
                Log.i(TAG) { "Resumed download for $globalKey" }
                return true
            }
            Log.w(TAG) { "Native resume returned false for $globalKey; re-enqueuing from scratch" }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Native resume failed for $globalKey; re-enqueuing from scratch" }
        }
        if (markedDownloading) transitionStatus(globalKey, PAUSED)
        return false
    }

    suspend fun retryDownload(globalKey: String, client: MediaBackend) {
        if (skipUnsupported("download retry")) return
        rearmQueueForUserAction("manual retry")
        autoRetryTimers.remove(globalKey)?.cancel()
        cleanupStaleDownload(globalKey)
        database.clearDownloadError(globalKey)
        requeueDownload(globalKey, client)
    }

    /** Runs [body] with [globalKey] marked cancelling, after detaching and cancelling the row's task. */
    private suspend fun withCancellation(globalKey: String, reason: String, body: suspend () -> Unit) {
        cancellingKeys += globalKey
        try {
            cancelDownloadTimers(globalKey)
            val taskId = database.getBgTaskId(globalKey)
            stopServerTranscode(globalKey, taskId)
            database.updateBgTaskId(globalKey, null)
            cancelNativeTasksForGlobalKey(globalKey, includeTaskId = taskId, reason = reason)
            pendingDownloadContext.remove(globalKey)
            body()
        } finally {
            cancellingKeys -= globalKey
        }
    }

    /** Cancels a download; it stays, out of the queue, for the user to retry or delete. */
    suspend fun cancelDownload(globalKey: String) = withCancellation(globalKey, "user cancellation") { markCancelled(globalKey) }

    private suspend fun markCancelled(globalKey: String) {
        transitionStatus(globalKey, CANCELLED)
        database.removeFromQueue(globalKey)
    }

    /** Cancels the download, then deletes its row and reconciles its storage grant. */
    suspend fun cancelAndRemoveDownload(globalKey: String) {
        cancelDownload(globalKey)
        ledger.deleteDownloadRowAndRelease(globalKey)
    }

    /** Deletes a download (a container: each of its downloaded leaves) with its files, cached metadata and row. */
    suspend fun deleteDownload(globalKey: String) = withCancellation(globalKey, "delete download") {
        val parsed = parseGlobalKey(globalKey)
        if (parsed == null) {
            ledger.deleteDownloadRowAndRelease(globalKey)
            return@withCancellation
        }
        val (serverId, ratingKey) = parsed
        val record = database.getDownloadedMedia(globalKey)
        val clientScopeId = record?.client_scope_id
        val item = metadata.lookup(serverId, ratingKey, clientScopeId)
        if (item == null) {
            deleter.deleteMediaFiles(serverId, ratingKey, record, null)
            metadata.deleteForItemByServer(serverId, ratingKey, clientScopeId)
            ledger.deleteDownloadRowAndRelease(globalKey)
            return@withCancellation
        }
        val children = deleter.containerChildren(item, serverId)
        val totalItems = children?.size ?: 1
        emitDeletionProgress(DeletionProgress(globalKey, item.displayTitle, 0, totalItems))
        deleter.deleteMediaFiles(serverId, ratingKey, record, item, children)
        metadata.deleteForItemByServer(serverId, ratingKey, clientScopeId)
        ledger.deleteDownloadRowAndRelease(globalKey)
        emitDeletionProgress(DeletionProgress(globalKey, item.displayTitle, totalItems, totalItems))
    }

    internal suspend fun getAllDownloads(): List<Downloaded_media> = database.getAllDownloads()

    internal suspend fun getDownloadedMedia(globalKey: String): Downloaded_media? = database.getDownloadedMedia(globalKey)

    /** Pins a parent item's metadata (show, season) for offline display. */
    suspend fun saveMetadata(metadata: MediaItem, client: MediaBackend) {
        if (metadata.serverId == null) {
            Log.w(TAG) { "Cannot save metadata without serverId" }
            return
        }
        this.metadata.pinMetadataForOffline(client, metadata)
    }

    /**
     * Fetches, pins and downloads the artwork of collection [collectionId] so the downloads screen can draw it offline;
     * null when the server no longer has it.
     */
    suspend fun pinCollectionForOffline(collectionId: String, client: MediaBackend): MediaItem? {
        val fetched = client.fetchItem(collectionId) ?: return null
        val collection = if (fetched.serverId == null) fetched.copy(serverId = client.serverId.value) else fetched
        metadata.cacheFor(client.backend).pinForOffline(client.cacheServerId, collectionId)
        downloadArtworkForMetadata(collection, client)
        return collection
    }

    fun dispose() {
        disposed = true
        scope.cancel()
        autoRetryTimers.clear()
        rowProgress.clear()
        pendingDownloadContext.clear()
        storedPartBytes.clear()
        completingKeys.clear()
        pausingKeys.clear()
        cancellingKeys.clear()
    }

    // Transcoded downloads

    /** The file of version [mediaIndex] of [item] at [quality]: the original, or the server's transcode. */
    private suspend fun resolveDownload(client: MediaBackend, item: MediaItem, mediaIndex: Int, mediaSourceId: String?, quality: TranscodeQualityPreset): DownloadResolution =
        if (quality.isOriginal) client.resolveDownload(item, mediaIndex, mediaSourceId) else transcoder(client).resolveTranscodedDownload(item, mediaIndex, mediaSourceId, quality)

    private fun transcoder(client: MediaBackend): DownloadTranscoding =
        client as? DownloadTranscoding ?: throw IllegalStateException("${client.backend.id} servers don't transcode downloads")

    /**
     * Stops the server's encode behind a transcoded download's task [taskId]: the transfer stopping leaves it running
     * until the server notices. In the background, so the user's action doesn't wait on the server.
     */
    private suspend fun stopServerTranscode(globalKey: String, taskId: String?) {
        if (taskId == null || database.getDownloadedMedia(globalKey)?.transcodeQuality?.isOriginal != false) return
        val url = downloader?.taskForId(taskId)?.url ?: return
        val transcoder = metadata.clientForDownloadKey(globalKey) as? DownloadTranscoding ?: return
        scope.launch { transcoder.stopDownloadTranscode(url) }
    }

    /**
     * The size of the transcoded file at [storedPath] when it is whole: an MPEG transport stream whose timestamps span
     * the item's [runtimeMs] ([TransportStreamSpan.covers]; any span when the runtime is unknown). Null when the server's
     * transcode ended early or the file can't be read.
     */
    private suspend fun verifiedTranscodeSize(storedPath: String, runtimeMs: Long?): Long? {
        val saf = storage.isSafUri(storedPath)
        val path = if (saf) storedPath else storage.ensureAbsolutePath(storedPath)
        val measured = try {
            val size = if (saf) safStorage.size(path) ?: return null else files.size(path)
            size to TransportStreamSpan.measure(size) { offset, length -> if (saf) safStorage.read(path, offset, length) else files.read(path, offset, length) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Could not read a transcoded download" }
            return null
        }
        val (size, span) = measured
        val complete = span != null && (runtimeMs == null || TransportStreamSpan.covers(span, runtimeMs))
        Log.i(TAG) { "Transcoded download of $size bytes spans ${span ?: "no timestamps"} (runtime ${runtimeMs ?: "unknown"} ms): ${if (complete) "whole" else "cut short"}" }
        return size.takeIf { complete }
    }

    /**
     * A transcode the server ended early: the file goes, and the download fails with the server's fault, retried from
     * the start while app retries remain.
     */
    private suspend fun discardIncompleteTranscode(globalKey: String, storedPath: String, row: Downloaded_media) {
        if (storage.isSafUri(storedPath)) safStorage.delete(storedPath, isDir = false) else files.deleteIfExists(storage.ensureAbsolutePath(storedPath), "incomplete transcode")
        database.updateBgTaskId(globalKey, null)
        val message = T.downloads.errorDownloadFailedWithReason(T.errors.reasonServerError)
        val client = metadata.clientForDownloadKey(globalKey)
        if (client != null && row.retry_count < MAX_APP_RETRIES) {
            scheduleDownloadRetry(globalKey, client, row.retry_count.toInt(), message, processQueueAfterProgress = false)
        } else {
            failPermanently(globalKey, message)
        }
    }

    companion object {
        private const val TAG = "DownloadManager"

        /** The crash reporter's breadcrumb category for the downloads' start-up recovery. */
        private const val BREADCRUMBS = "downloads"
        private const val DISPLAY_NAME = "{displayName}"
        private const val MAX_APP_RETRIES = 3
        private const val NATIVE_RETRIES = 5
        private const val MAX_CONSECUTIVE_FAILURES = 3
        private const val DEFAULT_EXTENSION = "mp4"
        private const val EVENT_BUFFER = 256
        private const val CAPACITY_UNKNOWN = "download storage capacity could not be determined"
        internal val DEFAULT_AUTO_RETRY_DELAY: Duration = 30.seconds
        private val PROGRESS_WRITE_INTERVAL: Duration = 2.seconds
        private val RESTARTABLE = setOf(QUEUED, DOWNLOADING, PAUSED)

        /** How far a transcode's progress goes on its estimate before the file is whole. */
        private const val TRANSCODE_PROGRESS_CAP = 0.99

        /**
         * The transports' failure kinds ([TaskException.Connection]) of a host that can't be found or reached: the JVM's
         * exceptions, and URLSession's cannot find host, cannot connect and DNS lookup failed. The downloader reports
         * them only while the device has a network (without one the task waits for it), and "not connected to the
         * internet" (-1009) stays retryable: a lost network is not a lost server.
         */
        private val UNREACHABLE_HOST_KINDS = setOf(
            "UnknownHostException", "UnresolvedAddressException", "ConnectException", "NoRouteToHostException",
            "NSURLErrorDomain -1003", "NSURLErrorDomain -1004", "NSURLErrorDomain -1006",
        )

        /** Transport failure markers in a native description; the exception type alone can't tell (DNS is an IOException). */
        private val TRANSPORT_FAILURE_MARKERS = listOf(
            "unable to resolve host", "unknownhostexception", "no address associated with hostname", "failed host lookup",
            "network is unreachable", "connection refused", "connection reset", "connection closed", "connection abort",
            "broken pipe", "socketexception", "handshake", "javax.net.ssl", "clientexception", "unexpected end of stream",
        )

        /** The localized reason of a non-HTTP native failure; the description only picks the phrase. */
        internal fun nativeDownloadFailureReason(exception: TaskException): String {
            val text = exception.description.lowercase()
            return when {
                "timed out" in text || "timeout" in text -> T.errors.reasonTimedOut
                exception is TaskException.Connection || TRANSPORT_FAILURE_MARKERS.any { it in text } -> T.errors.reasonUnreachable
                exception is TaskException.Resume -> T.downloads.reasonCannotResume
                exception is TaskException.FileSystem -> T.downloads.reasonFileNotSaved
                else -> T.errors.reasonUnexpected
            }
        }

        private var taskCounter = 0L

        private fun newTaskId(): String = "${kotlin.time.Clock.System.now().toEpochMilliseconds()}-${++taskCounter}-${kotlin.random.Random.nextInt(1_000_000)}"
    }
}

/** Each file's external subtitles, in playback order. */
internal fun DownloadResolution.subtitlesPerPart(): List<List<DownloadSubtitleSpec>> = listOf(externalSubtitles) + additionalParts.map { it.externalSubtitles }

/** The location in [AppSettings]; the storage service reloads it ([DownloadStorageService.refreshCustomPath]). */
private class SettingsDownloadLocationStore(
    private val settings: DeviceSettingsRepository,
    private val storage: DownloadStorageService,
) : DownloadLocationStore {
    override suspend fun read() = DownloadLocationSnapshot(settings.value(AppSettings.customDownloadPath), settings.value(AppSettings.customDownloadPathType))

    override suspend fun write(location: DownloadLocationSnapshot) =
        settings.set(AppSettings.customDownloadPath, location.path, AppSettings.customDownloadPathType, location.type)

    override suspend fun refreshStorage() = storage.refreshCustomPath()
}
