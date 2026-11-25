package com.edde746.plezy.downloads

/**
 * Where a [DownloadTask]'s [DownloadTask.directory] is anchored. [APPLICATION_DOCUMENTS] and [APPLICATION_SUPPORT] are
 * resolved against the app's directories at run time, so a task keeps its file when the app's container moves (an iOS
 * container UUID change, Android adoptable storage); [ROOT] holds an absolute directory (a custom download folder).
 */
enum class BaseDirectory { APPLICATION_DOCUMENTS, APPLICATION_SUPPORT, ROOT }

/**
 * One file the [NativeDownloader] fetches. The URL and headers can carry a server's credentials: [toString] leaves
 * them out, and so must every log, notification and error built from a task.
 *
 * A file task lands at `<base>/<directory>/<filename>` ([NativeDownloader.filePath]), its bytes arriving in a temporary
 * file first. A document task ([directoryUri] set, Android's storage access framework) writes straight into the
 * document `<filename>` under that tree directory and resumes by appending to it.
 *
 * @param taskId unique per attempt; the download row keeps it (`bg_task_id`).
 * @param metaData the download's global key (`serverId:ratingKey`).
 * @param displayName what the platform's notification shows.
 * @param requiresWiFi runs only on an unmetered network (Wi-Fi, Ethernet; a VPN over them counts).
 * @param retries how many times a failed transfer is retried (resuming with `Range`) before it fails.
 * @param allowPause the task can be paused and resumed where it stopped, and carries on across a platform's run limit
 *   (Android's WorkManager window).
 * @param creationTime epoch milliseconds.
 */
data class DownloadTask(
    val taskId: String,
    val url: String,
    val headers: Map<String, String> = emptyMap(),
    val filename: String,
    val directory: String,
    val baseDirectory: BaseDirectory,
    val directoryUri: String? = null,
    val metaData: String,
    val displayName: String,
    val requiresWiFi: Boolean = false,
    val retries: Int = 0,
    val allowPause: Boolean = false,
    val creationTime: Long,
) {
    /** A storage-access-framework task: it writes into [directoryUri]'s document [filename]. */
    val isDocumentTask: Boolean get() = directoryUri != null

    override fun toString(): String =
        "DownloadTask(taskId=$taskId, metaData=$metaData, filename=$filename, base=$baseDirectory, document=$isDocumentTask)"
}

/** A task's state, as background downloaders report it. */
enum class TaskStatus {
    ENQUEUED,
    RUNNING,
    COMPLETE,
    NOT_FOUND,
    FAILED,
    CANCELED,
    WAITING_TO_RETRY,
    PAUSED,
    ;

    /** The task ended: nothing more is reported for it. */
    val isFinal: Boolean get() = this == COMPLETE || this == NOT_FOUND || this == FAILED || this == CANCELED
}

/** Why a task failed ([TaskStatusUpdate.exception]). [description] is for logs only, never shown. */
sealed interface TaskException {
    val description: String

    /** Something else went wrong. */
    data class General(override val description: String) : TaskException

    /** Writing or moving the file failed (a full volume says so in [description]). */
    data class FileSystem(override val description: String) : TaskException

    /** The URL was refused before any connection. */
    data class Url(override val description: String) : TaskException

    /** The connection failed, timed out, or the host could not be found. */
    data class Connection(override val description: String) : TaskException

    /** A paused or interrupted transfer could not continue where it stopped. */
    data class Resume(override val description: String) : TaskException

    /** The server answered [httpResponseCode]; [description] may carry its body (logged truncated, never shown). */
    data class HttpResponse(val httpResponseCode: Int, override val description: String) : TaskException
}

/** A task's status changed. [exception] is set for [TaskStatus.FAILED]. */
data class TaskStatusUpdate(
    val task: DownloadTask,
    val status: TaskStatus,
    val exception: TaskException? = null,
    val responseStatusCode: Int? = null,
)

/**
 * A running task's progress.
 *
 * @param progress fraction of the file, 0–1; while its size is unknown, the last fraction known.
 * @param expectedFileSize the file's size in bytes, -1 while unknown.
 * @param bytesPerSecond the transfer's speed, -1 while unknown.
 * @param downloadedBytes the bytes of the file so far, -1 while unknown.
 */
data class TaskProgressUpdate(
    val task: DownloadTask,
    val progress: Double,
    val expectedFileSize: Long = -1,
    val bytesPerSecond: Long = -1,
    val downloadedBytes: Long = -1,
)

/** What the downloader persisted about a task: its last status and progress. Survives the process. */
data class TaskRecord(
    val task: DownloadTask,
    val status: TaskStatus,
    val progress: Double,
    val expectedFileSize: Long = -1,
    val exception: TaskException? = null,
)

/** The downloader's Wi-Fi policy ([NativeDownloader.requireWiFi]); it overrides each task's [DownloadTask.requiresWiFi]. */
enum class RequireWiFi { AS_SET_BY_TASK, FOR_ALL_TASKS, FOR_NO_TASKS }

/** What the platform's notification says for the downloads ("{displayName}" is replaced by the task's). */
data class TaskNotifications(
    val runningTitle: String,
    val runningBody: String,
    val completeBody: String,
    val errorBody: String,
    val pausedBody: String,
)

/** Receives a downloader's reports; called on the main thread. */
interface TaskCallbacks {
    fun onStatus(update: TaskStatusUpdate)

    fun onProgress(update: TaskProgressUpdate)
}

/**
 * The background downloader under the download manager: it moves one task's bytes at a time (one overall, one per
 * host: Plex can refuse concurrent media downloads), retries with `Range` resume, pauses and resumes, checks the free
 * space before a transfer, honours Wi-Fi only, persists its tasks and their records across process death, and reports
 * through [TaskCallbacks]. Android runs it inside a foreground WorkManager worker that outlives the platform's run
 * window; iPhone, iPad and the Mac in a background `URLSession`; Windows and Linux in the app's process. Apple TV has
 * none.
 */
interface NativeDownloader {
    /** Registers the receiver of every status and progress report, and the notification texts. */
    suspend fun configure(callbacks: TaskCallbacks, notifications: TaskNotifications)

    /** Delivers what happened while the app was away (Apple's background session), as reports. */
    suspend fun resumeFromBackground()

    /** Queues [task]; false when the downloader refused it. */
    suspend fun enqueue(task: DownloadTask): Boolean

    /** The tasks not yet final: enqueued, running, waiting to retry or paused. */
    suspend fun allTasks(): List<DownloadTask>

    /** The task [taskId] while not final, else null. */
    suspend fun taskForId(taskId: String): DownloadTask?

    /** Every persisted record. */
    suspend fun allRecords(): List<TaskRecord>

    suspend fun deleteRecord(taskId: String)

    /** Cancels the tasks; their partial files go. True when every one was found or already gone. */
    suspend fun cancelTasksWithIds(taskIds: Collection<String>): Boolean

    /** Pauses a running task, keeping what arrived; false when it can't (not started, not pausable, gone). */
    suspend fun pause(task: DownloadTask): Boolean

    /** Resumes a paused task where it stopped; false when it can't. */
    suspend fun resume(task: DownloadTask): Boolean

    /** Cancels every task and deletes every record and partial file; returns how many tasks it cancelled. */
    suspend fun reset(): Int

    /** Deletes temporary files no task owns; returns how many. */
    suspend fun cleanUpOrphanedTempFiles(): Int

    /**
     * Enqueues again the tasks the last process left enqueued or running with no live transfer. Returns the tasks
     * rescheduled and the ones that failed to reschedule.
     */
    suspend fun rescheduleKilledTasks(): Pair<List<DownloadTask>, List<DownloadTask>>

    /** Applies the Wi-Fi policy to every task, rescheduling those whose requirement changed. */
    suspend fun requireWiFi(requirement: RequireWiFi): Boolean

    /** The absolute path of a file task's target; a document task's is its document URI once known. */
    fun filePath(task: DownloadTask): String

    /** The absolute directory a [BaseDirectory] resolves to now ([BaseDirectory.ROOT]: the filesystem root). */
    fun baseDirectoryPath(base: BaseDirectory): String
}
