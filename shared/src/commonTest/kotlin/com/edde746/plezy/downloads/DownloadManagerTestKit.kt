package com.edde746.plezy.downloads

import app.cash.sqldelight.db.SqlDriver
import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.buildArtworkSpecs
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.data.testData
import com.edde746.plezy.jellyfin.JellyfinApiCache
import com.edde746.plezy.jellyfin.JellyfinCacheResolver
import com.edde746.plezy.jellyfin.JellyfinConnection
import com.edde746.plezy.jellyfin.JellyfinProfileBinding
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexApiCache
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockRequestHandler
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.job
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.io.files.SystemFileSystem
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * A [NativeDownloader] for tests: every operation is a scriptable handler; [calls] records the order of the ones
 * recovery sequences (`allRecords`, `deleteRecord:<id>`, `cancel:<ids>`, `initialize`, `reschedule`).
 */
internal class FakeNativeDownloader : NativeDownloader {
    val calls = mutableListOf<String>()
    val cancelledIds = mutableListOf<String>()
    val deletedRecordIds = mutableListOf<String>()
    val requirements = mutableListOf<RequireWiFi>()

    /** Every task handed to [enqueue], in order. */
    val enqueued = Channel<DownloadTask>(Channel.UNLIMITED)

    var tasks: suspend () -> List<DownloadTask> = { emptyList() }
    var records: suspend () -> List<TaskRecord> = { emptyList() }
    var enqueueHandler: suspend (DownloadTask) -> Boolean = { true }
    var taskForIdHandler: suspend (String) -> DownloadTask? = { id -> tasks().firstOrNull { it.taskId == id } }
    var pauseHandler: suspend (DownloadTask) -> Boolean = { false }
    var resumeHandler: suspend (DownloadTask) -> Boolean = { false }
    var resetHandler: suspend () -> Int = { 0 }

    /** Where each base directory resolves; [BaseDirectory.ROOT] is the file system root. */
    val bases = mutableMapOf(BaseDirectory.ROOT to "/")

    /** The manager's receiver of reports, once it configured the downloader. */
    lateinit var callbacks: TaskCallbacks

    override suspend fun configure(callbacks: TaskCallbacks, notifications: TaskNotifications) {
        calls += "initialize"
        this.callbacks = callbacks
    }

    /** Holds [held] at [status] in its tasks and records, as the downloader of a running app would. */
    fun holds(vararg held: DownloadTask, status: TaskStatus = TaskStatus.RUNNING) {
        tasks = { held.toList() }
        records = { held.map { TaskRecord(it, status, 0.0) } }
    }

    override suspend fun resumeFromBackground() = Unit

    override suspend fun enqueue(task: DownloadTask): Boolean {
        val accepted = enqueueHandler(task)
        if (accepted) enqueued.trySend(task)
        return accepted
    }

    override suspend fun allTasks(): List<DownloadTask> = tasks()

    override suspend fun taskForId(taskId: String): DownloadTask? = taskForIdHandler(taskId)

    override suspend fun allRecords(): List<TaskRecord> {
        calls += "allRecords"
        return records()
    }

    override suspend fun deleteRecord(taskId: String) {
        calls += "deleteRecord:$taskId"
        deletedRecordIds += taskId
    }

    override suspend fun cancelTasksWithIds(taskIds: Collection<String>): Boolean {
        calls += "cancel:${taskIds.joinToString(",")}"
        cancelledIds += taskIds
        return true
    }

    override suspend fun pause(task: DownloadTask): Boolean = pauseHandler(task)

    override suspend fun resume(task: DownloadTask): Boolean = resumeHandler(task)

    override suspend fun reset(): Int = resetHandler()

    override suspend fun cleanUpOrphanedTempFiles(): Int = 0

    override suspend fun rescheduleKilledTasks(): Pair<List<DownloadTask>, List<DownloadTask>> {
        calls += "reschedule"
        return emptyList<DownloadTask>() to emptyList()
    }

    override suspend fun requireWiFi(requirement: RequireWiFi): Boolean {
        requirements += requirement
        return true
    }

    override fun filePath(task: DownloadTask): String =
        task.directoryUri?.let { "$it/${task.filename}" } ?: LocalPath.join(baseDirectoryPath(task.baseDirectory), task.directory, task.filename)

    override fun baseDirectoryPath(base: BaseDirectory): String = bases[base] ?: error("No path for $base")

    /** The next task handed to [enqueue]. */
    suspend fun nextEnqueued(timeout: Duration = 10.seconds): DownloadTask =
        withContext(Dispatchers.Default) { withTimeout(timeout) { enqueued.receive() } }
}

/** A task the way the downloader would hold it: app-storage anchored unless [baseDirectory] says otherwise. */
internal fun downloadTask(
    taskId: String,
    globalKey: String,
    directory: String = "downloads",
    baseDirectory: BaseDirectory = BaseDirectory.APPLICATION_SUPPORT,
    directoryUri: String? = null,
    filename: String = "video.mp4",
) = DownloadTask(
    taskId = taskId,
    url = "https://example.test/video.mp4",
    filename = filename,
    directory = directory,
    baseDirectory = baseDirectory,
    directoryUri = directoryUri,
    metaData = globalKey,
    displayName = "video",
    creationTime = 0,
)

/** A custom-folder task: its absolute [directory] anchored at the file system root. */
internal fun rootTask(taskId: String, globalKey: String, directory: String) =
    downloadTask(taskId, globalKey, directory = directory, baseDirectory = BaseDirectory.ROOT)

/** A document (storage access framework) task writing into [directoryUri]. */
internal fun documentTask(taskId: String, globalKey: String, directoryUri: String) =
    downloadTask(taskId, globalKey, directory = "", baseDirectory = BaseDirectory.ROOT, directoryUri = directoryUri)

/**
 * Stores a `downloaded_media` row at any [status], as no production path does: admission only ever queues. A row that
 * exists is replaced with its error and retry count reset; its paths, artwork and completion time stay unless given.
 */
internal suspend fun LocalData.insertDownload(
    serverId: String,
    ratingKey: String,
    globalKey: String = "$serverId:$ratingKey",
    type: String = "movie",
    status: DownloadedMediaStatus,
    clientScopeId: String? = null,
    parentRatingKey: String? = null,
    grandparentRatingKey: String? = null,
    libraryId: String? = null,
    libraryTitle: String? = null,
    mediaIndex: Long = 0,
    mediaSourceId: String? = null,
    progress: Int = 0,
    downloadedBytes: Long = 0,
    totalBytes: Long? = null,
    downloadedAt: Long? = null,
    thumbPath: String? = null,
    transcodeQuality: String? = null,
) {
    db.write {
        val m = q.downloadedMediaQueries
        val existing = m.selectMedia(globalKey).executeAsOneOrNull()
        if (existing != null) m.deleteMedia(globalKey)
        m.insertRow(
            Downloaded_media(
                id = existing?.id ?: nextFixtureId++, server_id = serverId, client_scope_id = clientScopeId, rating_key = ratingKey,
                global_key = globalKey, type = type, parent_rating_key = parentRatingKey, grandparent_rating_key = grandparentRatingKey,
                status = status.code, progress = progress.toLong(), total_bytes = totalBytes, downloaded_bytes = downloadedBytes,
                video_file_path = existing?.video_file_path, additional_part_paths = existing?.additional_part_paths,
                saf_root_uri = existing?.saf_root_uri, thumb_path = thumbPath ?: existing?.thumb_path,
                downloaded_at = downloadedAt ?: existing?.downloaded_at, error_message = null, retry_count = 0,
                bg_task_id = existing?.bg_task_id, media_index = mediaIndex, media_source_id = mediaSourceId, library_id = libraryId,
                library_title = libraryTitle, transcode_quality = transcodeQuality,
            ),
        )
    }
}

private var nextFixtureId = 1_000_000L

/** An item as a backend would return it. */
internal fun testMediaItem(
    id: String,
    kind: MediaKind,
    serverId: String,
    backend: BackendKind = BackendKind.PLEX,
    title: String? = "Item $id",
    year: Int? = null,
    parentId: String? = null,
    parentTitle: String? = null,
    parentIndex: Int? = null,
    grandparentId: String? = null,
    grandparentTitle: String? = null,
    index: Int? = null,
    thumbPath: String? = null,
    clearLogoPath: String? = null,
    artPath: String? = null,
    backgroundSquarePath: String? = null,
) = MediaItem(
    id = id, backend = backend, kind = kind, serverId = serverId, title = title, year = year, parentId = parentId,
    parentTitle = parentTitle, parentIndex = parentIndex, grandparentId = grandparentId, grandparentTitle = grandparentTitle,
    index = index, thumbPath = thumbPath, clearLogoPath = clearLogoPath, artPath = artPath, backgroundSquarePath = backgroundSquarePath,
)

/**
 * A download manager over an in-memory database, the real Plex and MediaBrowser caches and a temporary storage root.
 * [connection] and [binding] persist saved connections and profile bindings both where the database's owner rules and
 * the MediaBrowser cache resolver read them; [pin] adds items to the caches' pinned metadata.
 */
internal class DmsHarness private constructor(val root: StorageRoot, val data: LocalData) {
    val library get() = data.downloadLibrary
    private val connections = mutableListOf<JellyfinConnection>()
    private val bindings = mutableListOf<JellyfinProfileBinding>()
    val resolver = JellyfinCacheResolver(data.apiCache, { connections.toList() }, { bindings.toList() })
    val plexCache = PlexApiCache(data.apiCache)
    val jellyfinCache = JellyfinApiCache(data.apiCache, resolver)
    private val pinnedItems = mutableMapOf<String, MediaItem>()
    val caches: Map<BackendKind, BackendCache> = PinnedItems(jellyfinCache).let { mediaBrowser ->
        mapOf(BackendKind.PLEX to PinnedItems(plexCache), BackendKind.JELLYFIN to mediaBrowser, BackendKind.EMBY to mediaBrowser)
    }

    /** Pins [items] as the offline metadata of downloads: their backend's cache lists them for any client scope asked. */
    fun pin(items: Collection<MediaItem>) {
        items.associateByTo(pinnedItems) { it.globalKey }
    }

    private inner class PinnedItems(private val cache: BackendCache) : BackendCache by cache {
        override suspend fun getAllPinnedMetadata(cacheServerIds: Set<String>?): Map<String, MediaItem> {
            val rows = cache.getAllPinnedMetadata(cacheServerIds)
            if (cacheServerIds?.isEmpty() == true) return rows
            return rows + pinnedItems.filterValues { caches[it.backend] === this }
        }
    }

    lateinit var storage: DownloadStorageService
        private set

    /**
     * The managers' scope, on one thread as the app's main scope is: a manager keeps its state (the queue drain's
     * guard, its maps) unsynchronized on that thread, and two of its coroutines on a pool would race on it.
     */
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default.limitedParallelism(1))
    private val managers = mutableListOf<DownloadManagerService>()

    /** One parent per manager: its one child is the manager's own scope, whose children are the work it launched. */
    private val managerParents = mutableListOf<Job>()

    /** The managers' launched work running now. */
    fun work(): List<Job> = managerParents.flatMap { it.children }.flatMap { it.children }

    /**
     * Waits until the managers' launched work is done, the work it launched in turn included: a barrier for what a
     * call left running in the background. [except] is work that waits here itself (a backend call inside a drain), or
     * that a test holds.
     */
    suspend fun idle(vararg except: Job) = withContext(Dispatchers.Default) {
        withTimeout(10.seconds) {
            while (true) {
                val pending = work().filterNot { job -> except.any { job.encloses(it) } }
                if (pending.isEmpty()) break
                pending.joinAll()
            }
        }
    }

    private fun Job.encloses(job: Job): Boolean = this === job || children.any { it.encloses(job) }

    fun sql(statement: String) {
        data.driver.execute(null, statement, 0)
    }

    fun profile(id: String) = sql("INSERT INTO profiles VALUES ('$id', 'local', '$id', NULL, '{}', 0, 0, NULL)")

    fun connection(id: String, kind: String, config: JsonObject = JsonObject(emptyMap())) {
        val json = Json.encodeToString(JsonObject.serializer(), config).replace("'", "''")
        sql("INSERT INTO connections VALUES ('$id', '$kind', '$json', 0, NULL, NULL)")
        if (kind == "jellyfin" || kind == "emby") connections += JellyfinConnection.fromConfigJson(id, config, createdAt = 0)
    }

    fun binding(profileId: String, connectionId: String, user: String) {
        sql("INSERT INTO profile_connections VALUES ('$profileId', '$connectionId', '$user', 0, NULL, NULL, NULL)")
        bindings += JellyfinProfileBinding(profileId, connectionId, user)
    }

    /** Caches a Plex metadata row of [item] under [cacheServerId] (`/library/metadata/{id}`). */
    suspend fun putPlexMetadata(cacheServerId: String, id: String, fields: JsonObject) {
        data.apiCache.put(cacheServerId, "/library/metadata/$id", plexContainer(fields))
    }

    fun manager(
        clientResolver: (ServerId, String?) -> MediaBackend? = { _, _ -> null },
        downloader: NativeDownloader? = null,
        safStorage: SafStorageOperations = UnsupportedSafStorage,
        http: MediaServerHttpClient = httpClient { respond("", HttpStatusCode.NotFound) },
        locationStore: DownloadLocationStore? = null,
        autoRetryDelay: Duration = DownloadManagerService.DEFAULT_AUTO_RETRY_DELAY,
        queueProcessorOverride: (suspend (MediaBackend) -> Unit)? = null,
        nativeRecoveryOverride: (suspend () -> Unit)? = null,
        timeSource: TimeSource = TimeSource.Monotonic,
    ): DownloadManagerService {
        (downloader as? FakeNativeDownloader)?.bases?.set(storage.baseDirectory, storage.baseAppDirectoryPath())
        return build(clientResolver, downloader, safStorage, http, locationStore, autoRetryDelay, queueProcessorOverride, nativeRecoveryOverride, timeSource)
    }

    private fun build(
        clientResolver: (ServerId, String?) -> MediaBackend?,
        downloader: NativeDownloader?,
        safStorage: SafStorageOperations,
        http: MediaServerHttpClient,
        locationStore: DownloadLocationStore?,
        autoRetryDelay: Duration,
        queueProcessorOverride: (suspend (MediaBackend) -> Unit)?,
        nativeRecoveryOverride: (suspend () -> Unit)?,
        timeSource: TimeSource,
    ): DownloadManagerService = DownloadManagerService(
        database = data.downloadLibrary,
        storage = storage,
        artwork = DownloadArtworkService(storage, http, Dispatchers.Default),
        clientResolver = clientResolver,
        caches = caches,
        mediaBrowserResolver = resolver,
        downloader = downloader,
        safStorage = safStorage,
        settings = data.deviceSettings,
        http = http,
        fileSystem = SystemFileSystem,
        io = Dispatchers.Default,
        parentScope = CoroutineScope(scope.coroutineContext + Job(scope.coroutineContext.job).also { managerParents += it }),
        locationStore = locationStore,
        autoRetryDelay = autoRetryDelay,
        queueProcessorOverride = queueProcessorOverride,
        nativeRecoveryOverride = nativeRecoveryOverride,
        timeSource = timeSource,
    ).also { managers += it }

    /**
     * Starts [manager] over [downloader] as the app does, then clears what the startup asked of the downloader: from
     * here on it is a running app's.
     */
    suspend fun start(manager: DownloadManagerService, downloader: FakeNativeDownloader) {
        manager.recoverInterruptedDownloads()
        idle()
        downloader.calls.clear()
        downloader.cancelledIds.clear()
        downloader.deletedRecordIds.clear()
    }

    /** [downloader] reports [update]; returns once its manager handled it. */
    suspend fun report(downloader: FakeNativeDownloader, update: TaskStatusUpdate) {
        downloader.callbacks.onStatus(update)
        idle()
    }

    /** [downloader] reports [update]; returns once its manager handled it. */
    suspend fun report(downloader: FakeNativeDownloader, update: TaskProgressUpdate) {
        downloader.callbacks.onProgress(update)
        idle()
    }

    fun close() {
        managers.forEach { it.dispose() }
        scope.cancel()
        data.close()
        root.delete()
    }

    companion object {
        /**
         * A harness whose storage is the temporary root's app storage, or with [safBaseUri] a document tree.
         * [wrapDriver] wraps the database's driver, for tests that observe or hold its queries.
         */
        suspend fun create(safBaseUri: String? = null, wrapDriver: ((SqlDriver) -> SqlDriver)? = null): DmsHarness {
            val data = if (wrapDriver == null) {
                testData()
            } else {
                val factory = inMemoryDatabase()
                LocalData({ schema -> wrapDriver(factory.createDriver(schema)) }, { 1_790_000_000_000L }, Dispatchers.Default, {}, null)
            }
            val harness = DmsHarness(StorageRoot("plezy-dms-"), data)
            if (safBaseUri != null) harness.data.deviceSettings.setCustomDownloadPath(safBaseUri, DownloadStorageService.PATH_TYPE_SAF)
            harness.storage = DownloadStorageService(harness.root.platform(supportsSaf = safBaseUri != null), harness.data.deviceSettings)
            harness.storage.initialize()
            return harness
        }

        fun httpClient(handler: MockRequestHandler) = MediaServerHttpClient(HttpClient(MockEngine(handler)))

        fun plexContainer(fields: JsonObject): JsonObject = Json.parseToJsonElement(
            """{"MediaContainer":{"Metadata":[${Json.encodeToString(JsonObject.serializer(), fields)}]}}""",
        ) as JsonObject
    }
}

/**
 * A server for the supplementary-download tests: [metadata] is the only item it knows; [resolution] answers every
 * download resolution (it may throw); artwork URLs are `https://example.test{path}`; playback extras have no chapters.
 */
internal open class SupplementaryBackend(
    val metadata: MediaItem,
    val resolution: suspend () -> DownloadResolution,
    serverId: String = "srv",
    backend: BackendKind = BackendKind.PLEX,
    scopeId: String? = null,
) : FakeMediaBackend(serverId, backend, scopeId = scopeId) {
    var lastMediaSourceId: String? = null

    init {
        items = { id -> if (id == metadata.id) metadata else null }
    }

    override suspend fun resolveDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?): DownloadResolution {
        lastMediaSourceId = mediaSourceId
        return resolution()
    }

    override fun resolveDownloadArtwork(item: MediaItem): List<DownloadArtworkSpec> = buildArtworkSpecs(item) { "https://example.test$it" }

    override suspend fun stampLibrary(item: MediaItem): MediaItem = item

    override suspend fun fetchPlaybackExtras(
        itemId: String,
        introPattern: String?,
        creditsPattern: String?,
        forceChapterFallback: Boolean,
        forceRefresh: Boolean,
    ): PlaybackExtras = PlaybackExtras(emptyList(), emptyList())

    override suspend fun fetchPlaybackExtrasFromCacheOnly(
        itemId: String,
        introPattern: String?,
        creditsPattern: String?,
        forceChapterFallback: Boolean,
    ): PlaybackExtras? = null
}

/**
 * The storage-access fake of the manager's suites: a document tree of folders and files with persisted grants.
 * [canonicalRoots] maps a URI to the grant it falls under (an unknown existing URI is its own); [resolveOverride]
 * replaces that lookup; [failDeletes] refuses deletion.
 */
internal class DocumentTreeFake(
    private val failDeletes: Set<String> = emptySet(),
    canonicalRoots: Map<String, String> = emptyMap(),
    persistedRoots: Set<String> = emptySet(),
    private val resolveOverride: (suspend (String) -> String?)? = null,
) : SafStorageOperations {
    val canonicalRoots = canonicalRoots.toMutableMap()
    val persistedRoots = persistedRoots.toMutableSet()
    val releaseCalls = mutableListOf<String>()
    private val childrenByPath = mutableMapOf<String, SafDocumentFile>()
    private val childrenByUri = mutableMapOf<String, MutableList<SafDocumentFile>>()
    private val existing = mutableSetOf<String>()

    override val isAvailable: Boolean get() = true

    fun addEpisode(storage: DownloadStorageService, episode: MediaItem, videoUri: String, showYear: Int) {
        val show = document(SHOW_URI, "Show (2000)", isDir = true)
        val season = document(SEASON_URI, "Season 01", isDir = true)
        val video = document(videoUri, storage.getEpisodeSafFileName(episode, "mkv"), isDir = false)
        childrenByPath[pathKey(ROOT_URI, storage.getShowSafPathComponents(episode, showYear))] = show
        childrenByPath[pathKey(ROOT_URI, storage.getEpisodeSafPathComponents(episode, showYear))] = season
        childrenByUri[ROOT_URI] = mutableListOf(show)
        childrenByUri[SHOW_URI] = mutableListOf(season)
        childrenByUri[SEASON_URI] = mutableListOf(video)
        childrenByUri[videoUri] = mutableListOf()
        existing += listOf(ROOT_URI, SHOW_URI, SEASON_URI, videoUri)
    }

    /** A movie, season or show folder; a movie's holds its own video ([CONTAINER_VIDEO_URI]); [withForeignFile] adds one it doesn't own. */
    fun addContainer(storage: DownloadStorageService, item: MediaItem, withForeignFile: Boolean = false) {
        val target = document(TARGET_URI, item.displayTitle, isDir = true)
        val components = when (item.kind) {
            MediaKind.MOVIE -> storage.getMovieSafPathComponents(item)
            MediaKind.SEASON -> storage.getSeasonSafPathComponents(item)
            MediaKind.SHOW -> storage.getShowSafPathComponents(item)
            else -> error("Unsupported test kind: ${item.kind}")
        }
        childrenByPath[pathKey(ROOT_URI, components)] = target
        childrenByUri[TARGET_URI] = buildList {
            if (item.kind == MediaKind.MOVIE) add(document(CONTAINER_VIDEO_URI, storage.getMovieSafFileName(item, "mkv"), isDir = false))
            if (withForeignFile) add(document(ASSET_URI, "asset.bin", isDir = false))
        }.toMutableList()
        existing += ROOT_URI
        existing += TARGET_URI
        if (item.kind == MediaKind.MOVIE) existing += CONTAINER_VIDEO_URI
        if (withForeignFile) existing += ASSET_URI
        if (item.kind == MediaKind.SEASON) {
            val show = document(SHOW_URI, "Show (2000)", isDir = true)
            childrenByPath[pathKey(ROOT_URI, storage.getShowSafPathComponents(item))] = show
            childrenByUri[SHOW_URI] = mutableListOf(target)
            existing += SHOW_URI
        } else {
            childrenByUri[ROOT_URI] = mutableListOf(target)
        }
    }

    /** Adds [movie]'s shared title folder and returns its URI. */
    fun addMovieDir(storage: DownloadStorageService, movie: MediaItem): String {
        val key = pathKey(ROOT_URI, storage.getMovieSafPathComponents(movie))
        val dir = childrenByPath.getOrPut(key) { document(MOVIE_DIR_URI, "Movie (2000)", isDir = true) }
        childrenByUri[ROOT_URI] = mutableListOf(dir)
        childrenByUri.getOrPut(MOVIE_DIR_URI) { mutableListOf() }
        existing += listOf(ROOT_URI, MOVIE_DIR_URI)
        return MOVIE_DIR_URI
    }

    /** Adds [fileName] to [movie]'s shared title folder and returns its URI. */
    fun addMovieFile(storage: DownloadStorageService, movie: MediaItem, fileName: String): String {
        val dirUri = addMovieDir(storage, movie)
        val uri = "content://movie-file/$fileName"
        val siblings = childrenByUri.getValue(dirUri)
        if (siblings.none { it.uri == uri }) siblings += document(uri, fileName, isDir = false)
        childrenByPath[pathKey(dirUri, listOf(fileName))] = document(uri, fileName, isDir = false)
        existing += uri
        return uri
    }

    fun existsNow(uri: String): Boolean = uri in existing

    override suspend fun createNestedDirectories(parentUri: String, pathComponents: List<String>): String? =
        childrenByPath[pathKey(parentUri, pathComponents)]?.uri

    override suspend fun getChild(parentUri: String, names: List<String>): SafDocumentFile? = childrenByPath[pathKey(parentUri, names)]

    override suspend fun list(uri: String): List<SafDocumentFile> = childrenByUri[uri].orEmpty().toList()

    override suspend fun size(uri: String): Long? = throw UnsupportedOperationException("size")

    override suspend fun read(uri: String, offset: Long, length: Int): ByteArray? = throw UnsupportedOperationException("read")

    override suspend fun resolvePersistedPermissionUri(uri: String): String? {
        resolveOverride?.let { return it(uri) }
        return canonicalRoots[uri] ?: uri.takeIf { it in existing }
    }

    override suspend fun getPersistedPermissionUris(): List<String> = persistedRoots.toList()

    override suspend fun releasePersistedPermission(uri: String): Boolean {
        releaseCalls += uri
        persistedRoots -= uri
        return true
    }

    override suspend fun exists(uri: String, isDir: Boolean): Boolean = uri in existing

    override suspend fun delete(uri: String, isDir: Boolean): Boolean {
        if (uri in failDeletes) return false
        existing -= uri
        childrenByUri.values.forEach { children -> children.removeAll { it.uri == uri } }
        return true
    }

    private fun pathKey(parentUri: String, names: List<String>) = "$parentUri/${names.joinToString("/")}"

    private fun document(uri: String, name: String, isDir: Boolean) = SafDocumentFile(uri, name, isDir, length = 0, lastModified = 0)

    companion object {
        const val ROOT_URI = "content://downloads"
        const val SHOW_URI = "content://show"
        const val SEASON_URI = "content://season"
        const val TARGET_URI = "content://target"
        const val ASSET_URI = "content://asset"
        const val MOVIE_DIR_URI = "content://movie-dir"
        const val CONTAINER_VIDEO_URI = "content://container-video"
    }
}

/**
 * A location store over a variable, with hooks that fail or hold the transactional switch; [live] is the location the
 * last completed storage refresh loaded.
 */
internal class MemoryLocationStore(var location: DownloadLocationSnapshot) : DownloadLocationStore {
    var onWrite: suspend (Int) -> Unit = {}
    var onRefresh: suspend (Int) -> Unit = {}
    var live: DownloadLocationSnapshot = location
        private set
    private var writes = 0
    private var refreshes = 0

    override suspend fun read() = location

    override suspend fun write(location: DownloadLocationSnapshot) {
        onWrite(++writes)
        this.location = location
    }

    override suspend fun refreshStorage() {
        onRefresh(++refreshes)
        live = location
    }
}
