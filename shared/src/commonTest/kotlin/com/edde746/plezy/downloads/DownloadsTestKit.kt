package com.edde746.plezy.downloads

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.net.NetworkState
import com.edde746.plezy.playback.resolve.FakeHttp
import com.edde746.plezy.playback.resolve.headers
import com.edde746.plezy.playback.resolve.respondRange
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.Runnable
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.testTimeSource
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.readByteArray
import kotlinx.io.write
import kotlin.coroutines.CoroutineContext
import kotlin.random.Random
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * A scripted [DownloadTransport]: [start] records the request (the test ends the transfer with [finish]); [stop]
 * answers [TransferResult.Stopped] for a transfer it runs; [reattach] reports the ids in [stillRunning] as still
 * running.
 */
internal class FakeTransport : DownloadTransport {
    val started = mutableListOf<TransferRequest>()
    val stopped = mutableListOf<String>()
    val running = mutableSetOf<String>()
    var stillRunning: Set<String> = emptySet()
    var listener: TransferListener? = null

    override fun start(request: TransferRequest, listener: TransferListener) {
        started += request
        running += request.id
        this.listener = listener
    }

    override fun stop(id: String) {
        stopped += id
        if (running.remove(id)) listener?.onResult(id, TransferResult.Stopped)
    }

    /** While set, [reattach] answers only at [releaseReattach]: a session slow to list its tasks. */
    var holdReattach = false
    private var heldReattach: (() -> Unit)? = null

    override fun reattach(ids: List<String>, listener: TransferListener, done: (running: List<String>) -> Unit) {
        this.listener = listener
        val answer = {
            val still = ids.filter { it in stillRunning }
            running += still
            done(still)
        }
        if (holdReattach) heldReattach = answer else answer()
    }

    fun releaseReattach() {
        heldReattach?.invoke()
        heldReattach = null
    }

    /** Ends the transfer [id] with [result]. */
    fun finish(id: String, result: TransferResult) {
        running -= id
        listener?.onResult(id, result)
    }

    fun progress(id: String, bytes: Long, total: Long?) {
        listener?.onProgress(id, bytes, total)
    }
}

/** A dispatcher that, while [held], keeps what is dispatched to it (in order) until released: a disk too busy to commit. */
internal class HeldDispatcher(private val inner: CoroutineDispatcher) : CoroutineDispatcher() {
    private val waiting = mutableListOf<Pair<CoroutineContext, Runnable>>()

    var held = false
        set(value) {
            field = value
            if (value) return
            val released = waiting.toList()
            waiting.clear()
            released.forEach { (context, block) -> inner.dispatch(context, block) }
        }

    override fun dispatch(context: CoroutineContext, block: Runnable) {
        if (held) waiting += context to block else inner.dispatch(context, block)
    }
}

/** The OS side of the tests' downloader: directories under [root], a volume whose room the test sets ([capacity]). */
internal class FakeDownloadPlatform(val root: Path, override val transport: DownloadTransport) : DownloadPlatform {
    var capacity: VolumeCapacity? = VolumeCapacity(available = 1L shl 40, total = 1L shl 41)
    val active = mutableListOf<Pair<Boolean, Boolean>>()
    val notified = mutableListOf<TaskNotification>()

    override fun baseDirectoryPath(base: BaseDirectory): String = when (base) {
        BaseDirectory.APPLICATION_DOCUMENTS -> Path(root, "documents").toString()
        BaseDirectory.APPLICATION_SUPPORT -> Path(root, "support").toString()
        BaseDirectory.ROOT -> "/"
    }

    override val tempDirectory: String = Path(root, "temp").toString()

    override fun capacity(path: String): VolumeCapacity? = capacity

    override fun onActive(active: Boolean, wifiOnly: Boolean) {
        this.active += active to wifiOnly
    }

    override fun notify(notification: TaskNotification) {
        notified += notification
    }
}

/** Every report a downloader made, in order. */
internal class RecordingCallbacks : TaskCallbacks {
    val statuses = mutableListOf<TaskStatusUpdate>()
    val progress = mutableListOf<TaskProgressUpdate>()

    override fun onStatus(update: TaskStatusUpdate) {
        statuses += update
    }

    override fun onProgress(update: TaskProgressUpdate) {
        progress += update
    }

    fun statusesOf(taskId: String): List<TaskStatus> = statuses.filter { it.task.taskId == taskId }.map { it.status }
}

internal val NOTIFICATIONS = TaskNotifications(
    runningTitle = "{displayName}",
    runningBody = "Downloading…",
    completeBody = "Download complete",
    errorBody = "Download failed",
    pausedBody = "Download paused",
)

/**
 * Downloaders on the test's virtual clock over one in-memory database ([data]: a [restart] makes a new downloader on
 * it, as the next process does), a [FakeDownloadPlatform] whose directories are under a fresh temporary [root]
 * ([cleanUp] deletes it), and the [network] the test sets. The transport is [fakeTransport], or the real
 * [KtorTransport] over a mock HTTP world (every request goes to [routes] by host; a host without a route answers 404)
 * with `fake = false`.
 */
@OptIn(ExperimentalCoroutinesApi::class)
internal class DownloadsHarness(val scope: TestScope, private val fake: Boolean = true) {
    val root: Path = Path(SystemTemporaryDirectory, "plezy-downloads-" + Random.nextLong().toULong())
    val routes = mutableMapOf<String, suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData>()
    val http = FakeHttp(scope) { request -> routes[request.url.host]?.invoke(this, request) ?: respond("", HttpStatusCode.NotFound) }
    private val io = StandardTestDispatcher(scope.testScheduler)
    val data = LocalData(inMemoryDatabase(), { TestClock().now }, StandardTestDispatcher(scope.testScheduler))
    val network = MutableStateFlow(NetworkState.ONLINE)
    var fakeTransport = FakeTransport()
        private set
    lateinit var platform: FakeDownloadPlatform
        private set
    var callbacks = RecordingCallbacks()
        private set
    lateinit var downloader: TaskDownloader
        private set
    private var process: CoroutineScope? = null

    /** What the downloader's requests are signed with, as the app adds a server's token: by default the token header. */
    var credentials = TaskCredentials { it.copy(headers = it.headers + ("X-Plex-Token" to "secret")) }

    /** A downloader on this harness, as a process starts one: built and configured, then its work settles. */
    suspend fun start(configure: Boolean = true): TaskDownloader {
        val transport: DownloadTransport = if (fake) fakeTransport else KtorTransport(http.client, io, SystemFileSystem, scope.testTimeSource, { platform.capacity })
        val next = FakeDownloadPlatform(root, transport)
        // The volume stays as the last process left it.
        if (::platform.isInitialized) next.capacity = platform.capacity
        platform = next
        val processScope = CoroutineScope(scope.backgroundScope.coroutineContext + Job(scope.backgroundScope.coroutineContext[Job]))
        process = processScope
        downloader = TaskDownloader(data.downloadTasks, platform, network, processScope, io, SystemFileSystem, scope.testTimeSource) {
            credentials.authorize(it)
        }
        if (configure) downloader.configure(callbacks, NOTIFICATIONS)
        settle()
        return downloader
    }

    /** The process ends without a word (its runs stop where they are), and the next one starts with a new transport. */
    suspend fun restart(configure: Boolean = true): TaskDownloader {
        process?.cancel()
        settle()
        fakeTransport = FakeTransport()
        callbacks = RecordingCallbacks()
        return start(configure)
    }

    fun settle() = scope.runCurrent()

    fun advance(duration: Duration) {
        scope.advanceTimeBy(duration)
        scope.runCurrent()
    }

    fun network(online: Boolean, metered: Boolean = false) {
        network.value = NetworkState(online, metered)
        settle()
    }

    /** Serves [bytes] at every path of `cdn.example` like a static file server with [etag] ([serveVideo]). */
    fun serveCdn(bytes: ByteArray, etag: String = "\"v1\"") {
        routes["cdn.example"] = { request -> serveVideo(request, bytes, etag) }
    }

    /** The transfers' requests to `cdn.example`. */
    fun transferRequests(): List<HttpRequestData> = http.requests.filter { it.url.host == "cdn.example" }

    /** The temporary file of [taskId]. */
    fun temp(taskId: String): Path = Path(platform.tempDirectory, TaskDownloader.tempName(taskId))

    fun cleanUp() {
        deleteTree(root)
    }
}

/** A task for `https://<host>/<id>.mkv`, saved as `downloads/<id>.mkv` in the documents directory. */
internal fun task(
    id: String = "film",
    host: String = "cdn.example",
    requiresWiFi: Boolean = false,
    retries: Int = 5,
    allowPause: Boolean = true,
) = DownloadTask(
    taskId = id,
    url = "https://$host/$id.mkv",
    headers = mapOf("X-Plex-Token" to "secret"),
    filename = "$id.mkv",
    directory = "downloads",
    baseDirectory = BaseDirectory.APPLICATION_DOCUMENTS,
    metaData = "server:$id",
    displayName = "Film $id",
    requiresWiFi = requiresWiFi,
    retries = retries,
    allowPause = allowPause,
    creationTime = 1_790_000_000_000L,
)

/**
 * Answers like a static file server with [etag]: the whole file without `Range` (or when `If-Range` names another
 * validator), else a 206 for `bytes=<first>-[<last>]`, or 416 past the end.
 */
internal fun MockRequestHandleScope.serveVideo(request: HttpRequestData, file: ByteArray, etag: String = "\"v1\""): HttpResponseData {
    val size = file.size.toLong()
    val range = request.headers[HttpHeaders.Range]?.removePrefix("bytes=")?.split('-')
    val ifRange = request.headers[HttpHeaders.IfRange]
    if (range == null || ifRange != null && ifRange != etag) {
        return respond(file, HttpStatusCode.OK, headers(HttpHeaders.ContentLength to "$size", HttpHeaders.ETag to etag))
    }
    val first = range[0].toLong()
    if (first >= size) return respond(ByteArray(0), HttpStatusCode.RequestedRangeNotSatisfiable, headers(HttpHeaders.ContentRange to "bytes */$size"))
    val last = range.getOrNull(1)?.takeIf { it.isNotEmpty() }?.toLong()?.coerceAtMost(size - 1) ?: (size - 1)
    return respondRange(file, first, last, size, HttpHeaders.ETag to etag)
}

/** A test over a fresh [DownloadsHarness] (its directory deleted after). */
internal fun downloadsTest(fake: Boolean = true, block: suspend TestScope.(DownloadsHarness) -> Unit) = runTest(timeout = 60.seconds) {
    val h = DownloadsHarness(this, fake)
    try {
        block(h)
    } finally {
        h.cleanUp()
    }
}

/** Writes [size] bytes into [request]'s part file. */
internal fun writePart(request: TransferRequest, size: Long) {
    val part = Path(request.partPath)
    part.parent?.let { SystemFileSystem.createDirectories(it) }
    SystemFileSystem.sink(part).buffered().use { it.write(ByteArray(size.toInt())) }
}

internal fun read(path: Path): ByteArray = SystemFileSystem.source(path).buffered().use { it.readByteArray() }

/** Deletes [path] and everything under it. */
internal fun deleteTree(path: Path) {
    val metadata = SystemFileSystem.metadataOrNull(path) ?: return
    if (metadata.isDirectory) SystemFileSystem.list(path).forEach(::deleteTree)
    SystemFileSystem.delete(path, mustExist = false)
}
