package com.edde746.plezy.downloads

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.downloads.DownloadTaskRepository
import com.edde746.plezy.data.downloads.StoredTask
import com.edde746.plezy.log.Log
import com.edde746.plezy.net.NetworkState
import io.ktor.http.Url
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.io.IOException
import kotlinx.io.buffered
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemPathSeparator
import kotlin.concurrent.Volatile
import kotlin.coroutines.ContinuationInterceptor
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.resume
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * The [NativeDownloader] on every platform with downloads: the background downloader's rules over the platform's
 * [DownloadTransport] ([DownloadPlatform]).
 *
 * - **Queue:** tasks run in the order they were enqueued, [MAX_RUNNING] at a time overall and [MAX_PER_HOST] per host
 *   (Plex can refuse concurrent media downloads). A task waits while the network doesn't allow it: offline, or on a
 *   metered network when it needs Wi-Fi ([RequireWiFi] policy over the task's own flag; Ethernet and a VPN over an
 *   unmetered link count as Wi-Fi: the network state's metered flag decides, not its transport).
 * - **A run** checks the volume's room ([StorageFloor]) before it transfers, then moves the bytes into the task's
 *   temporary file (a document task: into its document), resuming with `Range`/`If-Range` from what is there once the
 *   file's size is known; the progress and the resume offset count the same bytes once. A file task's bytes move to its
 *   file once complete.
 * - **Failures:** a failed run is retried [DownloadTask.retries] times (`WAITING_TO_RETRY`, 2 s, 4 s, 8 s… apart),
 *   resuming; a 404 is `NOT_FOUND`; a volume too full fails at once with a storage-full message and its partial file
 *   deleted. A run the network or the platform stopped (Android's worker ending, the system stopping it) goes back to
 *   the queue, keeping its bytes when the task allows pausing: never `CANCELED`. `CANCELED` is reported for every
 *   cancel, the app's or the notification's.
 * - **Persistence:** every task and its last status and progress (its record) are kept in the database
 *   ([DownloadTaskRepository]); a task the last process left running is enqueued again by [rescheduleKilledTasks],
 *   after [resumeFromBackground] reattached what the platform still runs (Apple's background session). Tasks are kept
 *   without their credentials ([withoutCredentials]), which [credentials] adds to each request as it is sent; a task an
 *   earlier version stored with them loses them as the tasks are read.
 *
 * Reports go to [TaskCallbacks] on [scope]'s dispatcher, which must be the main thread's; tasks only run once
 * [configure]d. Every function may be called from any thread.
 */
class TaskDownloader internal constructor(
    private val store: DownloadTaskRepository,
    private val platform: DownloadPlatform,
    private val network: StateFlow<NetworkState>,
    private val scope: CoroutineScope,
    private val io: CoroutineContext,
    private val fileSystem: FileSystem,
    private val timeSource: TimeSource,
    private val credentials: TaskCredentials,
) : NativeDownloader {
    /** The downloader over [data]'s task table; [scope] runs on the main thread. */
    constructor(data: LocalData, platform: DownloadPlatform, network: StateFlow<NetworkState>, scope: CoroutineScope, credentials: TaskCredentials) :
        this(data.downloadTasks, platform, network, scope, Dispatchers.IO, SystemFileSystem, TimeSource.Monotonic, credentials)

    private val main: CoroutineContext = scope.coroutineContext[ContinuationInterceptor] ?: EmptyCoroutineContext
    private val transfers = Transfers(platform.transport, scope, timeSource, ::onLive, ::onValidator)

    // Main thread only from here.
    private val tasks = LinkedHashMap<String, StoredTask>()
    private val runs = mutableMapOf<String, Run>()
    private val retryWaits = mutableMapOf<String, Job>()
    private val persistedAt = mutableMapOf<String, TimeMark>()
    private var policy = RequireWiFi.AS_SET_BY_TASK
    private var nextSequence = 1L
    private var callbacks: TaskCallbacks? = null
    private var notifications: TaskNotifications? = null
    private var configured = false
    private var reattached: CompletableDeferred<Unit>? = null
    private var lastActive: Pair<Boolean, Boolean>? = null
    private val loaded = CompletableDeferred<Unit>()

    /** Document tasks' documents, by task id: [filePath] reads them from any thread. */
    @Volatile
    private var documentUris: Map<String, String> = emptyMap()

    init {
        scope.launch {
            try {
                for (read in store.all()) {
                    val task = read.task.withoutCredentials()
                    val stored = if (task == read.task) read else read.copy(task = task).also { store.save(it) }
                    tasks[task.taskId] = stored
                }
                policy = store.requireWiFi()
                nextSequence = (tasks.values.maxOfOrNull { it.sequence } ?: 0L) + 1
                publishDocuments()
                loaded.complete(Unit)
            } catch (e: CancellationException) {
                loaded.cancel(e)
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "reading the download tasks failed (${e::class.simpleName})" }
                loaded.completeExceptionally(e)
            }
        }
    }

    /** Runs [block] on the main thread once the tasks are read. */
    private suspend fun <T> onMain(block: suspend () -> T): T = withContext(main) {
        loaded.await()
        block()
    }

    // ---- NativeDownloader -------------------------------------------------------------------------------------------

    override suspend fun configure(callbacks: TaskCallbacks, notifications: TaskNotifications) = onMain {
        this.callbacks = callbacks
        this.notifications = notifications
        if (!configured) {
            configured = true
            scope.launch { network.collect { onNetwork() } }
        }
        schedule()
    }

    override suspend fun resumeFromBackground() = onMain { reattach() }

    override suspend fun enqueue(task: DownloadTask): Boolean = onMain {
        val existing = tasks[task.taskId]
        if (existing != null && !existing.status.isFinal) return@onMain false
        if (!downloadable(task.url)) {
            Log.w(TAG) { "task ${task.taskId}: refused, its URL isn't http(s)" }
            return@onMain false
        }
        val stored = StoredTask(
            task = task.withoutCredentials(),
            status = TaskStatus.ENQUEUED,
            progress = 0.0,
            expectedFileSize = -1,
            exception = null,
            retriesRemaining = task.retries,
            validator = null,
            documentUri = null,
            sequence = nextSequence++,
        )
        tasks[task.taskId] = stored
        store.save(stored)
        report(stored)
        schedule()
        true
    }

    override suspend fun allTasks(): List<DownloadTask> = onMain { tasks.values.filter { !it.status.isFinal }.map { it.task } }

    override suspend fun taskForId(taskId: String): DownloadTask? = onMain { tasks[taskId]?.takeIf { !it.status.isFinal }?.task }

    override suspend fun allRecords(): List<TaskRecord> = onMain {
        tasks.values.map { TaskRecord(it.task, it.status, it.progress, it.expectedFileSize, it.exception) }
    }

    /** Deletes [taskId]'s record; a task still under way keeps going, and its next update records it again. */
    override suspend fun deleteRecord(taskId: String) = onMain {
        val stored = tasks[taskId]
        if (stored != null && stored.status.isFinal) tasks.remove(taskId)
        store.delete(taskId)
    }

    override suspend fun cancelTasksWithIds(taskIds: Collection<String>): Boolean = onMain {
        for (id in taskIds) cancel(id)
        true
    }

    override suspend fun pause(task: DownloadTask): Boolean = onMain {
        val run = runs[task.taskId] ?: return@onMain false
        if (!task.allowPause || run.reason != null) return@onMain false
        run.stop(StopReason.PAUSE)
        run.ended.await()
        tasks[task.taskId]?.status == TaskStatus.PAUSED
    }

    override suspend fun resume(task: DownloadTask): Boolean = onMain {
        val stored = tasks[task.taskId]?.takeIf { it.status == TaskStatus.PAUSED } ?: return@onMain false
        report(update(stored.copy(status = TaskStatus.ENQUEUED, exception = null)))
        schedule()
        true
    }

    override suspend fun reset(): Int = onMain {
        // The queued ones first, so a running one's end starts none of them.
        val active = tasks.values.filter { !it.status.isFinal }.sortedBy { it.task.taskId in runs }.map { it.task.taskId }
        for (id in active) cancel(id)
        tasks.clear()
        store.deleteAll()
        publishDocuments()
        withContext(io) { fileSystem.listOrEmpty(Path(platform.tempDirectory)).forEach { delete(it) } }
        updateActive()
        active.size
    }

    override suspend fun cleanUpOrphanedTempFiles(): Int = onMain {
        val owned = tasks.values.filter { !it.status.isFinal }.map { tempName(it.task.taskId) }
        withContext(io) {
            fileSystem.listOrEmpty(Path(platform.tempDirectory))
                .filter { file -> owned.none { file.name.startsWith(it) } }
                .count { delete(it) }
        }
    }

    override suspend fun rescheduleKilledTasks(): Pair<List<DownloadTask>, List<DownloadTask>> = onMain {
        reattach()
        val killed = tasks.values.filter {
            val id = it.task.taskId
            (it.status == TaskStatus.RUNNING && id !in runs) || (it.status == TaskStatus.WAITING_TO_RETRY && id !in retryWaits)
        }
        val rescheduled = mutableListOf<DownloadTask>()
        val failed = mutableListOf<DownloadTask>()
        for (stored in killed) {
            try {
                report(update(stored.copy(status = TaskStatus.ENQUEUED)))
                rescheduled += stored.task
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "task ${stored.task.taskId}: enqueueing it again failed (${e::class.simpleName})" }
                failed += stored.task
            }
        }
        schedule()
        rescheduled to failed
    }

    override suspend fun requireWiFi(requirement: RequireWiFi): Boolean = onMain {
        val before = runs.keys.associateWith { id -> tasks[id]?.let { needsWifi(it.task) } }
        policy = requirement
        store.setRequireWiFi(requirement)
        for ((id, run) in runs) {
            val task = tasks[id]?.task ?: continue
            // A transfer keeps the network rules it started with (Apple's sessions): one whose requirement changed
            // starts again under the new ones, from what it has.
            if (before[id] != needsWifi(task) || !networkAllows(task)) run.stop(StopReason.REQUEUE)
        }
        schedule()
        true
    }

    override fun filePath(task: DownloadTask): String {
        if (task.isDocumentTask) return documentUris[task.taskId].orEmpty()
        return join(join(platform.baseDirectoryPath(task.baseDirectory), task.directory), task.filename)
    }

    override fun baseDirectoryPath(base: BaseDirectory): String = platform.baseDirectoryPath(base)

    /**
     * Some task waits for the network (offline, or Wi-Fi only on a metered one) and none runs: Android's worker then
     * ends asking to run again once its network constraint holds. Main thread.
     */
    fun waitingForNetwork(): Boolean =
        runs.isEmpty() && tasks.values.any { it.status == TaskStatus.ENQUEUED && !networkAllows(it.task) }

    /** The task running now, for a notification's actions; null when none runs. Main thread. */
    fun runningTask(): DownloadTask? = runs.keys.firstOrNull()?.let { tasks[it]?.task }

    // ---- The queue --------------------------------------------------------------------------------------------------

    private fun needsWifi(task: DownloadTask): Boolean = when (policy) {
        RequireWiFi.FOR_ALL_TASKS -> true
        RequireWiFi.FOR_NO_TASKS -> false
        RequireWiFi.AS_SET_BY_TASK -> task.requiresWiFi
    }

    private fun networkAllows(task: DownloadTask): Boolean {
        val state = network.value
        return state.online && !(state.metered && needsWifi(task))
    }

    private fun onNetwork() {
        for ((id, run) in runs) {
            val task = tasks[id]?.task ?: continue
            if (!networkAllows(task)) run.stop(StopReason.REQUEUE)
        }
        schedule()
    }

    /** Starts enqueued tasks in their order while the limits and the network allow. */
    private fun schedule() {
        if (configured) {
            val hosts = runs.keys.mapNotNull { tasks[it]?.task?.let { task -> hostOf(task.url) } }.toMutableList()
            for (stored in tasks.values.sortedBy { it.sequence }) {
                if (runs.size >= MAX_RUNNING) break
                val id = stored.task.taskId
                if (stored.status != TaskStatus.ENQUEUED || id in runs) continue
                val host = hostOf(stored.task.url)
                if (hosts.count { it == host } >= MAX_PER_HOST || !networkAllows(stored.task)) continue
                hosts += host
                start(id, attached = null)
            }
        }
        updateActive()
    }

    private fun updateActive() {
        val pending = tasks.values.filter { it.status == TaskStatus.ENQUEUED || it.status == TaskStatus.RUNNING || it.status == TaskStatus.WAITING_TO_RETRY }
        val now = pending.isNotEmpty() to (pending.isNotEmpty() && pending.all { needsWifi(it.task) })
        if (now == lastActive) return
        lastActive = now
        platform.onActive(now.first, now.second)
    }

    @OptIn(DelicateCoroutinesApi::class)
    private fun start(id: String, attached: CompletableDeferred<TransferResult>?) {
        val run = Run()
        runs[id] = run
        // Atomic: a run stopped before it began still runs its end, which reports it and completes [Run.ended].
        run.job = scope.launch(start = CoroutineStart.ATOMIC) {
            val outcome = try {
                attempt(id, run, attached)
            } catch (e: CancellationException) {
                if (run.reason == null) {
                    runs.remove(id)
                    run.ended.complete(Unit)
                    throw e
                }
                null
            } catch (e: Exception) {
                Log.e(TAG, e) { "task $id: its run threw (${e::class.simpleName})" }
                Outcome.Failed(TaskException.General(e::class.simpleName ?: "Exception"), retryable = true)
            }
            withContext(NonCancellable) {
                try {
                    finish(id, run, outcome)
                } finally {
                    runs.remove(id)
                    transfers.clear(id)
                    persistedAt.remove(id)
                    run.ended.complete(Unit)
                    schedule()
                }
            }
        }
    }

    /**
     * Asks the transport which of the tasks the last process left running it still runs (Apple's background session),
     * once per process, and runs those again from their transfer; the rest are left for [rescheduleKilledTasks].
     */
    private suspend fun reattach() {
        reattached?.let { return it.await() }
        val done = CompletableDeferred<Unit>()
        reattached = done
        val orphans = tasks.values.filter { it.status == TaskStatus.RUNNING && it.task.taskId !in runs }.map { it.task.taskId }
        val results = orphans.associateWith { transfers.expect(it) }
        val still = withTimeoutOrNull(REATTACH_TIMEOUT) {
            suspendCancellableCoroutine { continuation ->
                platform.transport.reattach(orphans, transfers) { running ->
                    scope.launch { if (continuation.isActive) continuation.resume(running.toSet()) }
                }
            }
        }.orEmpty()
        for (id in orphans) {
            when {
                id !in still -> transfers.forget(id)
                // Cancelled or reset while the transport was asked: the transfer it still runs is stopped, not adopted.
                tasks[id]?.status != TaskStatus.RUNNING -> {
                    transfers.forget(id)
                    platform.transport.stop(id)
                }
                else -> start(id, results.getValue(id))
            }
        }
        done.complete(Unit)
    }

    // ---- A run ------------------------------------------------------------------------------------------------------

    /**
     * Runs [id] until its transfer ends one way or another; [attached] is the result of a transfer the platform already
     * runs (reattached). Cancelled when the run is stopped ([Run.stop]).
     */
    private suspend fun attempt(id: String, run: Run, attached: CompletableDeferred<TransferResult>?): Outcome {
        var stored = tasks[id] ?: return Outcome.Gone
        val task = stored.task
        stored = update(stored.copy(status = TaskStatus.RUNNING, exception = null))
        report(stored)
        val part: String = if (task.isDocumentTask) {
            val documents = platform.documents ?: return Outcome.Failed(TaskException.FileSystem("document tasks aren't supported here"), retryable = false)
            val uri = try {
                withContext(io) { documents.findOrCreate(task.directoryUri!!, task.filename) }
            } catch (e: IOException) {
                Log.w(TAG) { "task $id: its document can't be opened (${e::class.simpleName})" }
                return Outcome.Failed(TaskException.FileSystem("the document can't be created"), retryable = true)
            }
            if (stored.documentUri != uri) {
                stored = update(stored.copy(documentUri = uri))
                publishDocuments()
            }
            uri
        } else {
            val created = withContext(io) {
                createDirectories(Path(platform.tempDirectory)) && createDirectories(Path(filePath(task)).parent)
            }
            if (!created) return Outcome.Failed(TaskException.FileSystem("the download's directories can't be created"), retryable = true)
            tempPath(id)
        }
        var pending = attached
        var restarts = 0
        while (true) {
            val result: TransferResult
            if (pending != null) {
                result = transfers.await(id, pending) { run.reason != null }
                pending = null
            } else {
                val expected = stored.expectedFileSize.takeIf { it > 0 }
                val existing = withContext(io) { partSize(part) } ?: 0L
                // Bytes are kept only for a file whose size an earlier answer announced: anything else starts over.
                val offset = if (expected != null && existing <= expected) existing else 0L
                if (refused(part, task, if (expected != null) expected - offset else 0L)) return Outcome.Storage
                result = if (expected != null && offset == expected) {
                    TransferResult.Completed(offset, stored.validator)
                } else {
                    val signed = credentials.authorize(task)
                        ?: return Outcome.Failed(TaskException.Connection("the server's credentials aren't available"), retryable = true)
                    val request = TransferRequest(
                        id = id,
                        url = signed.url,
                        headers = signed.headers,
                        partPath = part,
                        offset = offset,
                        expectedSize = expected,
                        validator = stored.validator.takeIf { offset > 0 },
                        title = task.displayName,
                        wifiOnly = needsWifi(task),
                    )
                    transfers.transfer(request) { run.reason != null }
                }
            }
            stored = tasks[id] ?: stored
            when (result) {
                is TransferResult.Completed -> return complete(stored, part, result)
                is TransferResult.Http -> when (result.status) {
                    NOT_FOUND -> return Outcome.NotFound
                    RANGE_NOT_SATISFIABLE -> {
                        if (++restarts > MAX_RESTARTS) return Outcome.Failed(TaskException.Resume("the server can't continue the file"), retryable = true)
                        stored = startOver(stored, part)
                    }
                    else -> return Outcome.Failed(TaskException.HttpResponse(result.status, "HTTP ${result.status}"), retryable = true, httpStatus = result.status)
                }
                TransferResult.Changed -> {
                    Log.i(TAG) { "task $id: the server's file changed; starting over" }
                    if (++restarts > MAX_RESTARTS) return Outcome.Failed(TaskException.Resume("the server's file keeps changing"), retryable = true)
                    stored = startOver(stored, part)
                }
                is TransferResult.Network -> {
                    Log.i(TAG) { "task $id: transfer failed (${result.kind})" }
                    return if (networkAllows(task)) Outcome.Failed(TaskException.Connection(result.kind), retryable = true) else Outcome.Requeue
                }
                TransferResult.DiskFull -> return Outcome.Storage
                TransferResult.WriteFailed ->
                    return if (refused(part, task, 0L)) Outcome.Storage else Outcome.Failed(TaskException.FileSystem("writing the file failed"), retryable = true)
                TransferResult.Stopped -> return Outcome.Requeue
            }
        }
    }

    /** Nothing of the file is kept: the next transfer starts from zero. */
    private suspend fun startOver(stored: StoredTask, part: String): StoredTask {
        withContext(io) { truncatePart(part) }
        return update(stored.copy(expectedFileSize = -1, validator = null, progress = 0.0))
    }

    /** The whole file is in [part]: a file task's moves to its file (copied when it lives on another volume). */
    private suspend fun complete(stored: StoredTask, part: String, result: TransferResult.Completed): Outcome {
        if (stored.task.isDocumentTask) return Outcome.Complete(result.bytes)
        val target = Path(filePath(stored.task))
        val moved = withContext(io) {
            try {
                fileSystem.atomicMove(Path(part), target)
                true
            } catch (e: IOException) {
                Log.d(TAG, e) { "task ${stored.task.taskId}: moving the file failed; copying it instead" }
                null
            }
        }
        if (moved == null) {
            if (StorageFloor.refuses(platform.capacity(target.toString()), result.bytes)) return Outcome.Storage
            if (!withContext(io) { copyThenDelete(Path(part), target, stored.task.taskId) }) {
                return Outcome.Failed(TaskException.FileSystem("moving the file into place failed"), retryable = true)
            }
        }
        return Outcome.Complete(result.bytes)
    }

    /** How a run ended ([outcome]), or the stop it was asked for ([Run.reason]). */
    private suspend fun finish(id: String, run: Run, outcome: Outcome?) {
        val stored = tasks[id] ?: return
        val task = stored.task
        val reason = run.reason
        when {
            outcome is Outcome.Complete ->
                report(update(stored.copy(status = TaskStatus.COMPLETE, progress = 1.0, expectedFileSize = outcome.bytes, exception = null)))
            reason == StopReason.CANCEL -> cancelled(stored)
            reason == StopReason.PAUSE -> {
                val bytes = withContext(io) { partSize(part(stored)) } ?: 0L
                report(update(stored.copy(status = TaskStatus.PAUSED, progress = fraction(bytes, stored.expectedFileSize, stored.progress))))
            }
            reason == StopReason.REQUEUE || outcome == Outcome.Requeue -> {
                // The network or the platform stopped it: back to the queue, never cancelled.
                if (!task.allowPause) {
                    withContext(io) { deletePart(stored) }
                    report(update(stored.copy(status = TaskStatus.ENQUEUED, progress = 0.0, expectedFileSize = -1, validator = null)))
                } else {
                    report(update(stored.copy(status = TaskStatus.ENQUEUED)))
                }
            }
            outcome == Outcome.NotFound -> {
                withContext(io) { deletePart(stored) }
                report(update(stored.copy(status = TaskStatus.NOT_FOUND, exception = TaskException.HttpResponse(NOT_FOUND, "HTTP $NOT_FOUND"))), NOT_FOUND)
            }
            outcome == Outcome.Storage -> {
                // The task's own partial file goes, so the refusal frees what it took; no retry refills the volume.
                withContext(io) { deletePart(stored) }
                Log.w(TAG) { "task $id: refused, the volume is too full" }
                report(update(stored.copy(status = TaskStatus.FAILED, progress = 0.0, exception = TaskException.FileSystem(StorageFloor.REFUSAL))))
            }
            outcome is Outcome.Failed -> failed(stored, outcome)
            else -> {}
        }
    }

    private suspend fun failed(stored: StoredTask, outcome: Outcome.Failed) {
        val id = stored.task.taskId
        if (outcome.retryable && stored.retriesRemaining > 0) {
            val waiting = update(stored.copy(status = TaskStatus.WAITING_TO_RETRY, retriesRemaining = stored.retriesRemaining - 1, exception = outcome.exception))
            report(waiting)
            val attempt = waiting.task.retries - waiting.retriesRemaining
            retryWaits[id] = scope.launch {
                delay(retryDelay(attempt))
                retryWaits.remove(id)
                val current = tasks[id]?.takeIf { it.status == TaskStatus.WAITING_TO_RETRY } ?: return@launch
                report(update(current.copy(status = TaskStatus.ENQUEUED)))
                schedule()
            }
            return
        }
        Log.i(TAG) { "task $id failed: ${outcome.exception::class.simpleName} ${outcome.exception.description}" }
        if (!stored.task.isDocumentTask) withContext(io) { deletePart(stored) }
        report(update(stored.copy(status = TaskStatus.FAILED, exception = outcome.exception)), outcome.httpStatus)
    }

    private suspend fun cancel(id: String) {
        runs[id]?.let { run ->
            run.stop(StopReason.CANCEL)
            run.ended.await()
            return
        }
        retryWaits.remove(id)?.cancel()
        val stored = tasks[id]?.takeIf { !it.status.isFinal } ?: return
        cancelled(stored)
    }

    private suspend fun cancelled(stored: StoredTask) {
        withContext(io) { deletePart(stored) }
        report(update(stored.copy(status = TaskStatus.CANCELED)))
    }

    // ---- Reports ----------------------------------------------------------------------------------------------------

    private suspend fun onLive(id: String, live: LiveProgress) {
        val stored = tasks[id]?.takeIf { it.status == TaskStatus.RUNNING } ?: return
        val total = live.totalBytes?.takeIf { it > 0 }
        val sized = total != null && total != stored.expectedFileSize
        val next = stored.copy(
            expectedFileSize = total ?: stored.expectedFileSize,
            progress = fraction(live.bytes, total ?: stored.expectedFileSize, stored.progress),
        )
        tasks[id] = next
        callbacks?.onProgress(TaskProgressUpdate(next.task, next.progress, next.expectedFileSize, live.bytesPerSecond ?: -1, live.bytes))
        notify(next)
        val last = persistedAt[id]
        if (sized || last == null || last.elapsedNow() >= PERSIST_INTERVAL) {
            persistedAt[id] = timeSource.markNow()
            store.save(next)
        }
    }

    private suspend fun onValidator(id: String, validator: String?) {
        val stored = tasks[id] ?: return
        if (stored.validator != validator) update(stored.copy(validator = validator))
    }

    private fun report(stored: StoredTask, httpStatus: Int? = null) {
        callbacks?.onStatus(TaskStatusUpdate(stored.task, stored.status, stored.exception.takeIf { stored.status == TaskStatus.FAILED || stored.status == TaskStatus.NOT_FOUND }, httpStatus))
        notify(stored)
    }

    private fun notify(stored: StoredTask) {
        val texts = notifications ?: return
        val name = stored.task.displayName
        val (state, body) = when (stored.status) {
            TaskStatus.RUNNING -> TaskNotification.State.RUNNING to texts.runningBody
            TaskStatus.COMPLETE -> TaskNotification.State.COMPLETE to texts.completeBody
            TaskStatus.FAILED, TaskStatus.NOT_FOUND -> TaskNotification.State.ERROR to texts.errorBody
            TaskStatus.PAUSED -> TaskNotification.State.PAUSED to texts.pausedBody
            TaskStatus.ENQUEUED, TaskStatus.WAITING_TO_RETRY, TaskStatus.CANCELED -> TaskNotification.State.GONE to ""
        }
        val progress = stored.progress.takeIf { stored.status == TaskStatus.RUNNING && stored.expectedFileSize > 0 }
        platform.notify(TaskNotification(stored.task, state, texts.runningTitle.replace(DISPLAY_NAME, name), body.replace(DISPLAY_NAME, name), progress))
    }

    // ---- Storage ----------------------------------------------------------------------------------------------------

    /** Writes [stored] as the task's state, in memory and then in the database (in the order of the calls). */
    private suspend fun update(stored: StoredTask): StoredTask {
        tasks[stored.task.taskId] = stored
        store.save(stored)
        return stored
    }

    private fun publishDocuments() {
        documentUris = tasks.values.mapNotNull { stored -> stored.documentUri?.let { stored.task.taskId to it } }.toMap()
    }

    /** Whether [required] more bytes for [task] would leave its volumes below [StorageFloor]. */
    private suspend fun refused(part: String, task: DownloadTask, required: Long): Boolean = withContext(io) {
        if (isDocumentUri(part)) return@withContext StorageFloor.refuses(platform.documents?.capacity(part), required)
        StorageFloor.refuses(platform.capacity(platform.tempDirectory), required) ||
            StorageFloor.refuses(platform.capacity(filePath(task)), required)
    }

    private fun tempPath(taskId: String): String = Path(platform.tempDirectory, tempName(taskId)).toString()

    private fun part(stored: StoredTask): String = stored.documentUri ?: tempPath(stored.task.taskId)

    private fun partSize(part: String): Long? =
        if (isDocumentUri(part)) platform.documents?.size(part) else fileSystem.metadataOrNull(Path(part))?.size

    private fun truncatePart(part: String) {
        try {
            if (isDocumentUri(part)) platform.documents?.truncate(part) else if (fileSystem.exists(Path(part))) fileSystem.sink(Path(part)).close()
        } catch (e: IOException) {
            Log.w(TAG) { "emptying a partial download failed (${e::class.simpleName})" }
        }
    }

    /** Deletes what a task left of its file: its temporary file and sidecars, or its document. */
    private fun deletePart(stored: StoredTask) {
        val document = stored.documentUri
        if (document != null) {
            platform.documents?.delete(document)
            return
        }
        val temp = tempPath(stored.task.taskId)
        (listOf("") + DownloadNames.PART_SIDECARS.map { it.removePrefix(DownloadNames.PART) }).forEach { delete(Path(temp + it)) }
    }

    private fun delete(path: Path): Boolean = try {
        if (fileSystem.exists(path)) {
            fileSystem.delete(path)
            true
        } else {
            false
        }
    } catch (e: IOException) {
        Log.w(TAG) { "deleting a download's file failed (${e::class.simpleName})" }
        false
    }

    private fun createDirectories(directory: Path?): Boolean = try {
        directory?.let { fileSystem.createDirectories(it) }
        true
    } catch (e: IOException) {
        Log.w(TAG) { "creating a download directory failed (${e::class.simpleName})" }
        false
    }

    /** Copies [from] to a staging file beside [to], renames that onto [to] and deletes [from]; false when it fails. */
    private fun copyThenDelete(from: Path, to: Path, taskId: String): Boolean {
        val staging = Path("$to.${DownloadNames.clean(taskId)}.partial")
        return try {
            fileSystem.source(from).buffered().use { source -> fileSystem.sink(staging).buffered().use { source.transferTo(it) } }
            fileSystem.atomicMove(staging, to)
            fileSystem.delete(from)
            true
        } catch (e: IOException) {
            Log.w(TAG) { "copying a download into place failed (${e::class.simpleName})" }
            delete(staging)
            false
        }
    }

    private fun FileSystem.listOrEmpty(directory: Path): List<Path> = try {
        if (exists(directory)) list(directory).toList() else emptyList()
    } catch (e: IOException) {
        Log.w(TAG) { "listing the downloader's temporary files failed (${e::class.simpleName})" }
        emptyList()
    }

    /** A run: its coroutine, and once asked to stop, why. */
    private class Run {
        var job: Job? = null
        var reason: StopReason? = null
        val ended = CompletableDeferred<Unit>()

        /** Stops the run for [reason], unless it is stopping for one as strong already. */
        fun stop(reason: StopReason) {
            val current = this.reason
            if (current != null && current >= reason) return
            this.reason = reason
            job?.cancel()
        }
    }

    /** Why a run stops, weakest first: a stronger one replaces a weaker one, never the other way. */
    private enum class StopReason { REQUEUE, PAUSE, CANCEL }

    private sealed interface Outcome {
        data class Complete(val bytes: Long) : Outcome

        data class Failed(val exception: TaskException, val retryable: Boolean, val httpStatus: Int? = null) : Outcome

        data object NotFound : Outcome

        /** The volume would fall below [StorageFloor], or is full. */
        data object Storage : Outcome

        /** The network or the platform stopped it: back to the queue. */
        data object Requeue : Outcome

        data object Gone : Outcome
    }

    companion object {
        /** Tasks running at once, overall and per host (the holding queue's limits). */
        const val MAX_RUNNING = 1
        const val MAX_PER_HOST = 1

        /** A task's progress is written to the database at most this often while it runs. */
        val PERSIST_INTERVAL: Duration = 2.seconds
        private val REATTACH_TIMEOUT: Duration = 30.seconds
        private const val MAX_RESTARTS = 3
        private const val NOT_FOUND = 404
        private const val RANGE_NOT_SATISFIABLE = 416
        private const val DISPLAY_NAME = "{displayName}"
        private const val TAG = "downloads"

        /** The wait before the [attempt]th retry: 2 s, doubling, at most 512 s. */
        fun retryDelay(attempt: Int): Duration = (2L shl (attempt - 1).coerceIn(0, 8)).seconds

        /** The name of [taskId]'s temporary file in [DownloadPlatform.tempDirectory]. */
        internal fun tempName(taskId: String): String = "${DownloadNames.clean(taskId)}${DownloadNames.PART}"

        private fun downloadable(url: String): Boolean {
            val scheme = url.substringBefore(':', "").lowercase()
            return scheme == "http" || scheme == "https"
        }

        private fun hostOf(url: String): String = try {
            Url(url).host
        } catch (_: Exception) {
            url
        }

        private fun fraction(bytes: Long, total: Long, fallback: Double): Double =
            if (total > 0) (bytes.toDouble() / total).coerceIn(0.0, 1.0) else fallback

        private fun join(directory: String, child: String): String {
            if (directory.isEmpty()) return child
            if (child.isEmpty()) return directory
            val trimmed = child.trimStart('/', '\\')
            return if (directory.endsWith('/') || directory.endsWith('\\')) directory + trimmed else directory + SystemPathSeparator + trimmed
        }
    }
}
