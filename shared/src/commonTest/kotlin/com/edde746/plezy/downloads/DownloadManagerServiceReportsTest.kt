package com.edde746.plezy.downloads

import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.CANCELLED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PAUSED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.io.IOException
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

/** Every progress event of [manager] from now on, recorded from any thread. */
internal class EventLog<T>(scope: CoroutineScope, flow: kotlinx.coroutines.flow.Flow<T>) {
    private val state = MutableStateFlow(emptyList<T>())
    val events: List<T> get() = state.value

    init {
        scope.launch(Dispatchers.Unconfined, CoroutineStart.UNDISPATCHED) { flow.collect { event -> state.update { it + event } } }
    }

    fun clear() = state.update { emptyList() }

    suspend fun awaitFirst(timeout: Duration = 10.seconds, predicate: (T) -> Boolean): T =
        withContext(Dispatchers.Default) { withTimeout(timeout) { state.first { list -> list.any(predicate) }.first(predicate) } }
}

internal fun DownloadManagerService.progressLog(scope: CoroutineScope) = EventLog(scope, progressStream)

/** Runs [block] on a real dispatcher: HTTP timeouts must not fire on the test's virtual clock. */
internal suspend fun <T> real(block: suspend () -> T): T = withContext(Dispatchers.Default) { block() }

class DownloadManagerServiceReportsTest {
    private lateinit var harness: DmsHarness
    private val globalKey = "srv:item-1"
    private val downloader = FakeNativeDownloader()
    private val current = downloadTask("current-task", globalKey)

    @AfterTest
    fun close() = harness.close()

    private suspend fun seed(status: DownloadedMediaStatus, taskId: String? = "current-task", queued: Boolean = false, key: String = globalKey) {
        val ratingKey = key.substringAfter(':')
        harness.data.insertDownload("srv", ratingKey, globalKey = key, status = status)
        if (taskId != null) harness.library.updateBgTaskId(key, taskId)
        if (queued) harness.library.addToQueue(key)
    }

    private suspend fun row(key: String = globalKey) = harness.library.getDownloadedMedia(key)!!

    /** [manager] after the app's startup, the downloader holding [held] at [status]: reports reach it from here on. */
    private suspend fun started(manager: DownloadManagerService, vararg held: DownloadTask = arrayOf(current), status: TaskStatus = TaskStatus.RUNNING): DownloadManagerService {
        downloader.holds(*held, status = status)
        harness.start(manager, downloader)
        return manager
    }

    private suspend fun report(update: TaskStatusUpdate) = harness.report(downloader, update)

    private suspend fun report(update: TaskProgressUpdate) = harness.report(downloader, update)

    // Storage exhaustion

    private fun storageFailureStopsEverything(failure: String) = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING, queued = true)
        seed(QUEUED, taskId = "queued-task", queued = true, key = "srv:item-2")
        val manager = started(harness.manager(downloader = downloader))
        val log = manager.progressLog(backgroundScope)

        report(TaskStatusUpdate(current, TaskStatus.FAILED, TaskException.FileSystem(failure)))

        assertEquals(setOf(globalKey, "srv:item-2"), log.events.filter { it.status == FAILED }.map { it.globalKey }.toSet())
        val current = row()
        val queued = row("srv:item-2")
        assertEquals(FAILED.code, current.status)
        assertEquals(FAILED.code, queued.status)
        assertNull(current.bg_task_id)
        assertNull(queued.bg_task_id)
        assertEquals(log.events.first { it.globalKey == globalKey }.errorMessage, current.error_message)
        assertEquals(current.error_message, queued.error_message)
        assertTrue(harness.library.getQueue().isEmpty())
    }

    @Test
    fun `storage failure stops every active download and clears the queue ENOSPC`() =
        storageFailureStopsEverything("write failed: ENOSPC (No space left on device)")

    @Test
    fun `storage failure stops every active download and clears the queue insufficient space`() =
        storageFailureStopsEverything("Insufficient space to store the file to be downloaded")

    @Test
    fun `storage failure stops every active download and clears the queue capacity unknown`() =
        storageFailureStopsEverything("Download storage capacity could not be determined")

    @Test
    fun `downloads stopped by the reset after storage exhaustion stay failed with the storage error`() = runTest {
        harness = DmsHarness.create()
        val first = downloadTask("task-1", globalKey)
        val second = downloadTask("task-2", "srv:item-2")
        seed(DOWNLOADING, taskId = first.taskId)
        seed(DOWNLOADING, taskId = second.taskId, key = "srv:item-2")
        // The reset reports every task it stops as canceled.
        downloader.resetHandler = {
            downloader.callbacks.onStatus(TaskStatusUpdate(second, TaskStatus.CANCELED))
            1
        }
        started(harness.manager(downloader = downloader), first, second)

        report(TaskStatusUpdate(first, TaskStatus.FAILED, TaskException.General("No space left on device")))

        for (key in listOf(globalKey, "srv:item-2")) {
            assertEquals(FAILED.code, row(key).status, key)
            assertEquals(T.downloads.storageFull, row(key).error_message, key)
        }
    }

    /** [key] downloading until the downloader refuses it for storage, which stops the queue. */
    private suspend fun stopForStorage(manager: DownloadManagerService, key: String) {
        seed(DOWNLOADING, taskId = "task-$key", key = key)
        report(TaskStatusUpdate(downloadTask("task-$key", key), TaskStatus.FAILED, TaskException.FileSystem(StorageFloor.REFUSAL)))
        assertTrue(manager.queueBlockedByStorageFailure, key)
    }

    @Test
    fun `only a download the user asks for a retry or a resume lifts a storage stop`() = runTest {
        harness = DmsHarness.create()
        var queueRuns = 0
        val movie = testMediaItem("item-2", MediaKind.MOVIE, "srv", title = "Movie")
        val client = SupplementaryBackend(movie, { DownloadResolution("https://example.test/video") })
        val manager = started(harness.manager(clientResolver = { _, _ -> client }, downloader = downloader, queueProcessorOverride = { queueRuns++ }))
        // Stored before the enqueue below, so the rows the later stops refuse don't take the id it assigns.
        for (key in listOf("srv:item-3", "srv:item-4")) seed(COMPLETED, taskId = null, key = key)
        stopForStorage(manager, globalKey)

        // An automatic enqueue (a sync rule's) waits behind the stop.
        manager.queueDownload(movie, client)
        harness.idle()
        assertTrue(manager.queueBlockedByStorageFailure)
        assertEquals(QUEUED.code, row("srv:item-2").status)
        assertEquals(0, queueRuns)

        manager.beginUserDownloadRequest()
        assertFalse(manager.queueBlockedByStorageFailure)

        stopForStorage(manager, "srv:item-3")
        manager.retryDownload(globalKey, client)
        harness.idle()
        assertFalse(manager.queueBlockedByStorageFailure)
        assertEquals(1, queueRuns)

        stopForStorage(manager, "srv:item-4")
        manager.resumeDownload("srv:item-4", client)
        harness.idle()
        assertFalse(manager.queueBlockedByStorageFailure)
        assertEquals(2, queueRuns)
    }

    @Test
    fun `an auto retry already past its timer does not requeue after a storage stop`() = runTest {
        // Holds the first read of the download's row once armed: the retry's, after its timer fired.
        val armed = CompletableDeferred<Unit>()
        val held = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        harness = DmsHarness.create(wrapDriver = { driver ->
            ObservedDriver(driver) { sql, args ->
                if (armed.isCompleted && "downloaded_media" in sql && globalKey in args && held.complete(Unit)) runBlocking { release.await() }
            }
        })
        seed(DOWNLOADING, queued = true)
        val item = testMediaItem("item-1", MediaKind.MOVIE, "srv", title = "Movie")
        val client = SupplementaryBackend(item, { DownloadResolution("https://example.test/video") })
        val manager = started(harness.manager(clientResolver = { _, _ -> client }, downloader = downloader, autoRetryDelay = 1.seconds, queueProcessorOverride = {}))

        downloader.callbacks.onStatus(TaskStatusUpdate(current, TaskStatus.FAILED, TaskException.Connection("NSURLErrorDomain -1009")))
        // The retry is scheduled once the failure left the queue.
        until { harness.library.getQueue().isEmpty() }
        armed.complete(Unit)
        real { withTimeout(5.seconds) { held.await() } }
        seed(DOWNLOADING, taskId = "task-2", key = "srv:item-2")
        downloader.callbacks.onStatus(TaskStatusUpdate(downloadTask("task-2", "srv:item-2"), TaskStatus.FAILED, TaskException.FileSystem(StorageFloor.REFUSAL)))
        until { manager.queueBlockedByStorageFailure }
        release.complete(Unit)
        harness.idle()

        assertEquals(FAILED.code, row().status)
        assertTrue(harness.library.getQueue().isEmpty())
    }

    // HTTP failures

    @Test
    fun `HTTP 403 fails for good with localized copy instead of retrying into the server body`() = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING, queued = true)
        // A client resolves, so any other failure would schedule an app retry.
        val item = testMediaItem("item-1", MediaKind.MOVIE, "srv", title = "Movie")
        val client = SupplementaryBackend(item, { DownloadResolution("https://example.test/video") })
        started(harness.manager(clientResolver = { _, _ -> client }, downloader = downloader, autoRetryDelay = Duration.ZERO, queueProcessorOverride = {}))

        report(
            TaskStatusUpdate(
                current,
                TaskStatus.FAILED,
                TaskException.HttpResponse(403, "<html><body>Upgrade your subscription to download</body></html>"),
            ),
        )

        assertEquals(FAILED.code, row().status)
        assertEquals(T.downloads.errorDownloadNotAllowed, row().error_message)
        assertEquals(0L, row().retry_count)
        assertTrue(harness.library.getQueue().isEmpty())
    }

    @Test
    fun `HTTP 500 fails for good with the bitrate hint instead of retrying`() = failsForGood(TaskException.HttpResponse(500, "HTTP 500")) {
        T.downloads.serverErrorBitrate
    }

    @Test
    fun `a host that cannot be found fails for good instead of retrying`() = failsForGood(TaskException.Connection("UnknownHostException")) {
        T.downloads.errorDownloadFailedWithReason(T.errors.reasonUnreachable)
    }

    @Test
    fun `a host that refuses the connection fails for good instead of retrying`() = failsForGood(TaskException.Connection("NSURLErrorDomain -1004")) {
        T.downloads.errorDownloadFailedWithReason(T.errors.reasonUnreachable)
    }

    @Test
    fun `a download that lost the network is retried`() = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING, queued = true)
        val item = testMediaItem("item-1", MediaKind.MOVIE, "srv", title = "Movie")
        val client = SupplementaryBackend(item, { DownloadResolution("https://example.test/video") })
        started(harness.manager(clientResolver = { _, _ -> client }, downloader = downloader, autoRetryDelay = Duration.ZERO, queueProcessorOverride = {}))

        report(TaskStatusUpdate(current, TaskStatus.FAILED, TaskException.Connection("NSURLErrorDomain -1009")))

        assertEquals(QUEUED.code, row().status)
    }

    /** A client resolves and retries come at once: a failure that retried would be queued again by now. */
    private fun failsForGood(exception: TaskException, message: () -> String) = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING, queued = true)
        val item = testMediaItem("item-1", MediaKind.MOVIE, "srv", title = "Movie")
        val client = SupplementaryBackend(item, { DownloadResolution("https://example.test/video") })
        started(harness.manager(clientResolver = { _, _ -> client }, downloader = downloader, autoRetryDelay = Duration.ZERO, queueProcessorOverride = {}))

        report(TaskStatusUpdate(current, TaskStatus.FAILED, exception))

        assertEquals(FAILED.code, row().status)
        assertEquals(message(), row().error_message)
        assertEquals(0L, row().retry_count)
        assertTrue(harness.library.getQueue().isEmpty())
    }

    @Test
    fun `any other status shows the status and never the server body`() = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING)
        started(harness.manager(downloader = downloader))

        report(
            TaskStatusUpdate(current, TaskStatus.FAILED, TaskException.HttpResponse(502, "<html><title>Bad Gateway</title><body>proxy.internal refused</body></html>")),
        )

        assertEquals(FAILED.code, row().status)
        assertEquals(T.downloads.errorHttpStatus("502"), row().error_message)
    }

    @Test
    fun `a server body about disk space does not stop downloads as local storage exhaustion`() = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING, queued = true)
        seed(QUEUED, taskId = null, queued = true, key = "srv:item-2")
        started(harness.manager(downloader = downloader))

        // The server's transcode disk is full, not this device's.
        report(
            TaskStatusUpdate(current, TaskStatus.FAILED, TaskException.HttpResponse(500, "IOException: No space left on device : /config/transcodes")),
        )

        assertEquals(T.downloads.serverErrorBitrate, row().error_message)
        assertEquals(QUEUED.code, row("srv:item-2").status)
        assertNull(row("srv:item-2").error_message)
    }

    // Native failure copy: descriptions as each platform's downloader reports them.

    private fun nativeFailureShowsLocalizedReason(exception: TaskException, reason: () -> String) = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING)
        started(harness.manager(downloader = downloader))

        report(TaskStatusUpdate(current, TaskStatus.FAILED, exception))

        assertEquals(FAILED.code, row().status)
        assertEquals(T.downloads.errorDownloadFailedWithReason(reason()), row().error_message)
    }

    @Test
    fun `Android DNS failure typed as a file system error shows a localized reason and never the platform text`() = nativeFailureShowsLocalizedReason(
        TaskException.FileSystem("java.net.UnknownHostException: Unable to resolve host \"plex.example.com\": No address associated with hostname"),
    ) { T.errors.reasonUnreachable }

    @Test
    fun `desktop DNS failure typed as a file system error shows a localized reason and never the platform text`() = nativeFailureShowsLocalizedReason(
        TaskException.FileSystem("SocketException: Failed host lookup: 'plex.example.com' (OS Error: nodename nor servname provided, errno = 8)"),
    ) { T.errors.reasonUnreachable }

    @Test
    fun `native timeout shows a localized reason and never the platform text`() =
        nativeFailureShowsLocalizedReason(TaskException.Connection("Task timed out")) { T.errors.reasonTimedOut }

    @Test
    fun `the catch all of Android quoting the tokenized URL shows a localized reason and never the platform text`() = nativeFailureShowsLocalizedReason(
        TaskException.General("Error for url https://plex.example.com/library/parts/1/file.mkv?X-Plex-Token=secret: boom"),
    ) { T.errors.reasonUnexpected }

    @Test
    fun `local write failure shows a localized reason and never the platform text`() = nativeFailureShowsLocalizedReason(
        TaskException.FileSystem("FileSystemException: Cannot open file, path = '/data/user/0/app/downloads/x.mkv'"),
    ) { T.downloads.reasonFileNotSaved }

    @Test
    fun `lost resume data shows a localized reason and never the platform text`() =
        nativeFailureShowsLocalizedReason(TaskException.Resume("Task was paused but cannot resume")) { T.downloads.reasonCannotResume }

    private fun postProcessingFailure(error: Exception, reason: () -> String) = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING, taskId = "saf-task")
        // Recovering a document completion resolves the task's root first; the failure lands there.
        val task = documentTask("saf-task", globalKey, "content://dir")
        started(harness.manager(downloader = downloader, safStorage = DocumentTreeFake(resolveOverride = { throw error })), task)

        report(TaskStatusUpdate(task, TaskStatus.COMPLETE))

        assertEquals(FAILED.code, row().status)
        assertEquals(T.downloads.errorPostProcessing(reason()), row().error_message)
    }

    @Test
    fun `post processing that fails on a full device shows a localized reason and never the path`() =
        postProcessingFailure(IOException("Write failed: /storage/emulated/0/x.mkv: No space left on device")) { T.downloads.reasonDeviceStorageFull }

    @Test
    fun `post processing that fails on any other file error shows a localized reason and never the path`() =
        postProcessingFailure(IOException("Cannot open file: /data/user/0/app/downloads/x.mkv")) { T.downloads.reasonFileNotSaved }

    // Task session validation

    @Test
    fun `ignores progress from stale native task ids`() = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING)
        val manager = started(harness.manager(downloader = downloader))
        val log = manager.progressLog(backgroundScope)

        report(TaskProgressUpdate(downloadTask("stale-task", globalKey), 0.5, 1000))
        assertTrue(log.events.isEmpty())

        report(TaskProgressUpdate(current, 0.5, 1000))

        assertEquals(1, log.events.size)
        assertEquals(globalKey, log.events.single().globalKey)
        assertEquals(50, log.events.single().progress)
    }

    @Test
    fun `progress still in flight after a pause neither cancels the task nor reports downloading`() = runTest {
        harness = DmsHarness.create()
        seed(PAUSED)
        val manager = started(harness.manager(downloader = downloader), status = TaskStatus.PAUSED)
        val log = manager.progressLog(backgroundScope)

        report(TaskProgressUpdate(current, 0.5, 1000))

        assertTrue(downloader.cancelledIds.isEmpty(), "cancelling would discard the resume data of the pause")
        assertTrue(log.events.isEmpty())
        assertEquals(PAUSED.code, row().status)
    }

    @Test
    fun `ignores terminal status from stale native task ids`() = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING)
        started(harness.manager(downloader = downloader))

        report(TaskStatusUpdate(downloadTask("stale-task", globalKey), TaskStatus.FAILED))

        assertEquals(DOWNLOADING.code, row().status)
        assertNull(row().error_message)
        assertEquals("current-task", row().bg_task_id)
    }

    @Test
    fun `ignores terminal status when the current row is no longer downloading`() = runTest {
        harness = DmsHarness.create()
        seed(COMPLETED)
        started(harness.manager(downloader = downloader))

        report(TaskStatusUpdate(current, TaskStatus.CANCELED))

        assertEquals(COMPLETED.code, row().status)
        assertEquals("current-task", row().bg_task_id)
        assertNull(harness.library.getNextQueueItem())
    }

    @Test
    fun `a cancel from outside the app ends the download cancelled instead of restarting it`() = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING, queued = true)
        val manager = started(harness.manager(downloader = downloader))
        val log = manager.progressLog(backgroundScope)

        report(TaskStatusUpdate(current, TaskStatus.CANCELED))

        assertEquals(CANCELLED.code, row().status)
        assertNull(row().bg_task_id)
        assertTrue(harness.library.getQueue().isEmpty())
        assertEquals(listOf(CANCELLED), log.events.map { it.status })
    }

    // Wi-Fi only policy

    private suspend fun applyAll(values: List<Boolean>, supported: Boolean): List<RequireWiFi> {
        harness = DmsHarness.create()
        val manager = harness.manager(downloader = downloader.takeIf { supported })
        values.forEach { manager.applyDownloadOnWifiOnly(it) }
        return downloader.requirements
    }

    @Test
    fun `overrides every native task in both directions`() = runTest {
        // AS_SET_BY_TASK would leave tasks enqueued Wi-Fi only waiting for Wi-Fi after the setting is turned off.
        assertEquals(listOf(RequireWiFi.FOR_ALL_TASKS, RequireWiFi.FOR_NO_TASKS), applyAll(listOf(true, false), supported = true))
    }

    @Test
    fun `is a no op where downloads are unsupported`() = runTest {
        assertTrue(applyAll(listOf(true), supported = false).isEmpty())
    }

    // Resume handling

    private suspend fun resumeHarness(resume: suspend (DownloadTask) -> Boolean): DownloadManagerService {
        harness = DmsHarness.create()
        seed(PAUSED)
        downloader.resumeHandler = resume
        return started(harness.manager(downloader = downloader, queueProcessorOverride = {}), status = TaskStatus.PAUSED)
    }

    @Test
    fun `a failed native resume queues the download again`() = runTest {
        val manager = resumeHarness { false }

        manager.resumeDownload(globalKey, FakeMediaBackend("srv"))

        assertEquals(QUEUED.code, row().status)
    }

    @Test
    fun `successful native resume transitions to downloading`() = runTest {
        val manager = resumeHarness { true }

        manager.resumeDownload(globalKey, FakeMediaBackend("srv"))

        assertEquals(DOWNLOADING.code, row().status)
        assertEquals("current-task", row().bg_task_id)
    }

    @Test
    fun `updates the downloader reports while resuming do not cancel the resumed task`() = runTest {
        // The desktop downloader re-enqueues inside resume and reports it, and the first progress, before returning.
        val manager = resumeHarness { task ->
            report(TaskStatusUpdate(task, TaskStatus.ENQUEUED))
            report(TaskProgressUpdate(task, 0.4, 1000))
            true
        }
        val log = manager.progressLog(backgroundScope)

        manager.resumeDownload(globalKey, FakeMediaBackend("srv"))

        assertTrue(downloader.cancelledIds.isEmpty())
        assertEquals(DOWNLOADING.code, row().status)
        assertTrue(log.events.any { it.progress == 40 })
    }

    // Progress kept for a restart

    @Test
    fun `a paused download keeps its progress after a restart`() = runTest {
        harness = DmsHarness.create()
        seed(DOWNLOADING)
        val clock = TestTimeSource()
        downloader.pauseHandler = { true }
        val manager = started(harness.manager(downloader = downloader, timeSource = clock))

        // A transfer reporting every 500 ms.
        for (step in 1..4) {
            report(TaskProgressUpdate(current, step / 10.0, 1000))
            clock += 500.milliseconds
        }
        manager.pauseDownload(globalKey)
        manager.dispose()
        started(harness.manager(downloader = downloader), status = TaskStatus.PAUSED)

        assertEquals(PAUSED.code, row().status)
        assertEquals(40L, row().progress)
        assertEquals(400L, row().downloaded_bytes)
    }
}
