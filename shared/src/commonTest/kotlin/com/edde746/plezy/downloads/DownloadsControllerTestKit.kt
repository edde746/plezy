package com.edde746.plezy.downloads

import com.edde746.plezy.app.NotificationPermission
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlCursor
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlPreparedStatement
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.servers.Connectivity
import com.edde746.plezy.servers.ConnectivityLink
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.WatchStateNotifier
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.job
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** Servers a test registers by hand; a registered server is online unless listed in [offline]. */
internal class FakeDownloadServers : DownloadServers {
    val clients = mutableMapOf<ServerId, MediaBackend>()
    val offline = mutableSetOf<ServerId>()

    fun register(client: MediaBackend, online: Boolean = true) {
        clients[client.serverId] = client
        if (online) offline -= client.serverId else offline += client.serverId
    }

    override fun client(serverId: ServerId): MediaBackend? = clients[serverId]

    override fun isServerOnline(serverId: ServerId): Boolean = serverId in clients && serverId !in offline
}

/** Counts how often the notification permission was asked for; [gate] holds the ask while set. */
internal class RecordingNotificationPermission : NotificationPermission {
    var asks = 0
    var gate: kotlinx.coroutines.CompletableDeferred<Unit>? = null

    override suspend fun ensure() {
        asks++
        gate?.await()
    }
}

/**
 * A [DownloadsController] over [dms] (the real manager over an in-memory database), with hand-registered [servers].
 * The manager is unsupported-platform unless [downloader] is given; [managerOf] replaces it (built over [servers]).
 */
internal class ControllerHarness(
    val dms: DmsHarness,
    val downloader: NativeDownloader? = FakeNativeDownloader(),
    private val activeProfileId: String? = "test-profile",
    loadOnStart: Boolean = false,
    managerOf: ((FakeDownloadServers) -> DownloadManagerService)? = null,
    retryOnManager: (suspend (String, MediaBackend) -> Unit)? = null,
) {
    val servers = FakeDownloadServers()
    val watchNotifier = WatchStateNotifier()
    val deletionNotifier = DeletionNotifier()
    val permission = RecordingNotificationPermission()
    var connectivity: Connectivity = Connectivity.of(ConnectivityLink.WIFI)
    var autoRemove = false
    var playingKey: String? = null
    var now = 1_790_000_000_000L
    val manager: DownloadManagerService =
        managerOf?.invoke(servers) ?: dms.manager(clientResolver = { id, _ -> servers.client(id) }, downloader = downloader)

    /** The controller's parent: its one child is the controller's own scope, whose children are the work it launched. */
    private val controllerParent = Job(dms.scope.coroutineContext.job)

    val controller = DownloadsController(
        manager = manager,
        library = dms.library,
        syncRuleRepository = dms.data.syncRules,
        collectionRepository = dms.data.downloadCollections,
        watchQueue = dms.data.offlineWatch,
        servers = servers,
        watchStateNotifier = watchNotifier,
        deletionNotifier = deletionNotifier,
        notificationPermission = permission,
        videoSource = LibraryDownloadedVideoSource(dms.library, dms.storage, UnsupportedSafStorage),
        artwork = DownloadArtworkService(dms.storage, DmsHarness.httpClient { respond("", HttpStatusCode.NotFound) }, Dispatchers.Default),
        connectivity = { connectivity },
        caches = { dms.caches[it] },
        specialsOrdering = { SpecialsOrdering.SPECIALS_LAST },
        autoRemoveWatchedDownloads = { autoRemove },
        playingItemKey = { playingKey },
        clock = { now },
        parentScope = CoroutineScope(dms.scope.coroutineContext + controllerParent),
        activeProfileId = activeProfileId,
        loadOnStart = loadOnStart,
        retryOnManager = retryOnManager ?: manager::retryDownload,
    )

    private fun work(): List<Job> = controllerParent.children.flatMap { it.children }.toList()

    /** What the controller started with: the flows it collects for its life, and its first load. */
    private val resident = work().toSet()

    /**
     * Waits until the work the controller launched since it started is done (a profile switch's reload, a claim's
     * collection refresh). An offline source's watcher runs for good: don't wait with one set.
     */
    suspend fun idle() = withContext(Dispatchers.Default) {
        withTimeout(10.seconds) {
            while (true) {
                val pending = work() - resident
                if (pending.isEmpty()) break
                pending.joinAll()
            }
        }
    }

    private var recovered = false

    /** Runs the manager's startup recovery, once: the controller's reload waits for it. */
    private suspend fun recover() {
        if (recovered) return
        val fake = downloader as? FakeNativeDownloader
        if (fake != null) dms.start(manager, fake) else manager.recoverInterruptedDownloads()
        recovered = true
    }

    /** Loads the stored downloads as a start does: the manager's startup recovery, then the controller's reload. */
    suspend fun load() {
        recover()
        controller.refresh()
    }

    /**
     * Brings the controller to [downloads] as they stand after the start: past the manager's startup recovery, each is
     * stored as a row (of its item's kind and parents in [metadata]), [metadata] is pinned, and the controller reloads.
     * The active profile owns the downloads in [owned]; the rest are [OTHER_PROFILE]'s, and their items in [metadata]
     * stay loaded as when the active profile removes its copy of a shared download. A server of [metadata] without a
     * client gets an offline one (a Jellyfin or Emby one signed in as `user`): the reload reads the server's backend and
     * scope from it.
     */
    suspend fun seed(downloads: Map<String, DownloadProgress>, metadata: Map<String, MediaItem> = emptyMap(), owned: Set<String> = downloads.keys) {
        recover()
        val profileId = checkNotNull(activeProfileId)
        for ((key, progress) in downloads) {
            val (serverId, id) = checkNotNull(parseGlobalKey(key))
            val item = metadata[key]
            dms.data.insertDownload(
                serverId.value, id, key, type = item?.kind?.id ?: MediaKind.MOVIE.id, status = progress.status, parentRatingKey = item?.parentId,
                grandparentRatingKey = item?.grandparentId, progress = progress.progress, downloadedBytes = progress.downloadedBytes,
                totalBytes = progress.totalBytes, downloadedAt = progress.downloadedAt, thumbPath = progress.thumbPath,
            )
            if (key in owned || key in metadata) dms.library.addDownloadOwner(profileId, key)
            if (key !in owned) dms.library.addDownloadOwner(OTHER_PROFILE, key)
        }
        for (item in metadata.values) {
            val serverId = ServerId(checkNotNull(item.serverId))
            if (servers.client(serverId) == null) {
                val scopeId = if (item.backend.usesMediaBrowserApi) "${serverId.value}/user" else null
                servers.register(FakeMediaBackend(serverId.value, item.backend, scopeId = scopeId), online = false)
            }
        }
        dms.pin(metadata.values)
        controller.refresh()
        for (key in downloads.keys - owned) if (key in metadata) controller.deleteDownload(key)
    }

    fun close() {
        controller.dispose()
        dms.close()
    }

    companion object {
        /** The profile [seed] gives the downloads the active profile doesn't own. */
        const val OTHER_PROFILE = "other-profile"

        suspend fun create(downloader: NativeDownloader? = FakeNativeDownloader(), activeProfileId: String? = "test-profile"): ControllerHarness =
            ControllerHarness(DmsHarness.create(), downloader, activeProfileId).also { it.controller.ensureInitialized() }
    }
}

/** Waits (on the real clock, at most 5 s) until [condition] holds: for state another thread brings about. */
internal suspend fun until(condition: suspend () -> Boolean) = withContext(Dispatchers.Default) {
    withTimeout(5.seconds) { while (!condition()) delay(10.milliseconds) }
}

/**
 * Collects [flow] from now on, in the emitter's own call: an event emitted during a call is here once the call returns.
 * [take] waits for the next events, [drain] returns what arrived so far.
 */
internal class FlowRecorder<T>(flow: Flow<T>, scope: CoroutineScope) {
    private val channel = Channel<T>(Channel.UNLIMITED)
    private val job = scope.launch(Dispatchers.Unconfined, CoroutineStart.UNDISPATCHED) { flow.collect { channel.send(it) } }

    suspend fun take(count: Int): List<T> = withContext(Dispatchers.Default) { withTimeout(5.seconds) { List(count) { channel.receive() } } }

    fun drain(): List<T> = generateSequence { channel.tryReceive().getOrNull() }.toList()

    fun cancel() = job.cancel()
}

/** A driver that reports every query (its SQL and bound arguments) to [onSelect] before running it. */
internal class ObservedDriver(private val delegate: SqlDriver, private val onSelect: (String, List<Any?>) -> Unit) : SqlDriver by delegate {
    override fun <R> executeQuery(
        identifier: Int?,
        sql: String,
        mapper: (SqlCursor) -> QueryResult<R>,
        parameters: Int,
        binders: (SqlPreparedStatement.() -> Unit)?,
    ): QueryResult<R> {
        val args = ArgumentRecorder().also { recorder -> binders?.invoke(recorder) }.values
        onSelect(sql, args)
        return delegate.executeQuery(identifier, sql, mapper, parameters, binders)
    }

    private class ArgumentRecorder : SqlPreparedStatement {
        val values = mutableListOf<Any?>()
        override fun bindBytes(index: Int, bytes: ByteArray?) { values += bytes }
        override fun bindLong(index: Int, long: Long?) { values += long }
        override fun bindDouble(index: Int, double: Double?) { values += double }
        override fun bindString(index: Int, string: String?) { values += string }
        override fun bindBoolean(index: Int, boolean: Boolean?) { values += boolean }
    }
}
