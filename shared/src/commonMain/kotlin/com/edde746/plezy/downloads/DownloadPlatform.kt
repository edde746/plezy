package com.edde746.plezy.downloads

import com.edde746.plezy.log.Log
import kotlinx.io.RawSink

/**
 * What the [TaskDownloader] needs from the OS (the glue stays native): where its directories are, how much room a
 * volume has, how bytes move, and how a task shows in the system's notifications. One per process. Apple TV has none:
 * no downloads there.
 *
 * - Android: [KtorTransport] inside a WorkManager foreground `dataSync` worker ([onActive] keeps it running), storage-
 *   access-framework documents ([documents]), a notification per task.
 * - iPhone, iPad, Mac: a background `URLSession` ([DownloadTransport] in Swift, using [TransferFiles]).
 * - Windows, Linux: [KtorTransport] in the app's process.
 */
interface DownloadPlatform {
    /**
     * The absolute directory [base] resolves to now: the earlier releases' app directories, so the relative paths they
     * stored keep resolving. [BaseDirectory.ROOT] is the filesystem root (`/`; empty on Windows, whose absolute paths
     * carry their drive).
     */
    fun baseDirectoryPath(base: BaseDirectory): String

    /** Where file tasks' bytes arrive before they move to their file; the downloader creates it. */
    val tempDirectory: String

    /** The volume holding [path] (its nearest existing directory); null when it can't be told. */
    fun capacity(path: String): VolumeCapacity?

    /** Moves the bytes. */
    val transport: DownloadTransport

    /** Android's storage-access-framework documents, for document tasks; null where there are none. */
    val documents: DocumentStore? get() = null

    /**
     * The downloader has tasks to run ([active]) or none, and whether every one of them needs an unmetered network
     * ([wifiOnly]). Android keeps its foreground worker running while active. Main thread.
     */
    fun onActive(active: Boolean, wifiOnly: Boolean) {}

    /** A task's notification changed. Main thread. */
    fun notify(notification: TaskNotification) {}
}

/** A volume's room: [available] bytes for the app's data of [total]; a [total] of 0 or less is unknown. */
data class VolumeCapacity(val available: Long, val total: Long)

/**
 * What a task's notification shows now. [title] and [body] are [TaskNotifications]' texts with the task's display name
 * in place of `{displayName}`; [progress] (0–1) is set while it runs with a known size.
 */
data class TaskNotification(val task: DownloadTask, val state: State, val title: String, val body: String, val progress: Double? = null) {
    enum class State {
        RUNNING,
        COMPLETE,
        ERROR,
        PAUSED,

        /** Cancelled or waiting: its notification goes. */
        GONE,
    }
}

/**
 * Android's storage-access-framework documents under a tree the user granted ([DownloadTask.directoryUri]). A
 * document task writes straight into its document, appending on a resume. Paths of documents are their `content://`
 * URIs ([isDocumentUri]).
 */
interface DocumentStore {
    /**
     * The document [filename] directly under the tree [treeUri]: the one there (a paused or dead run's partial file),
     * else a new empty one; never a numbered copy beside it. Throws an IOException when the tree can't be written.
     */
    fun findOrCreate(treeUri: String, filename: String): String

    /** The document's size; null when it is gone. */
    fun size(documentUri: String): Long?

    /** Empties the document. Throws an IOException when it can't. */
    fun truncate(documentUri: String)

    /** Appends to the document. Throws an IOException when it can't be opened. */
    fun appendSink(documentUri: String): RawSink

    /** Deletes the document; false when it is still there. */
    fun delete(documentUri: String): Boolean

    /** The volume holding the document; null when it can't be told. */
    fun capacity(documentUri: String): VolumeCapacity?
}

/** A storage-access-framework document's path (`content://…`), not a file's. */
fun isDocumentUri(path: String): Boolean = path.startsWith("content://")

/**
 * One file's transfer, as the [TaskDownloader] hands it to the [DownloadTransport]: the task's URL into [partPath],
 * continuing after the [offset] bytes already there.
 *
 * The URL and header values can carry credentials: [toString] leaves them out, and so must every log, notification and
 * error built from a request.
 *
 * @param id the task's id: the transfer's key in every callback.
 * @param headers the request's headers, `User-Agent` included.
 * @param partPath where the bytes go: a temporary file, moved to the task's file once complete; a document task's
 *   document URI ([isDocumentUri]).
 * @param offset bytes already in [partPath] to keep: sent as `Range: bytes=<offset>-`; 0 starts over.
 * @param expectedSize the file's size as an earlier answer announced it, when known: a resumed answer's
 *   `Content-Range` total must match.
 * @param validator the `ETag` (or else `Last-Modified`) the bytes in [partPath] came with, sent as `If-Range`.
 * @param title the task's display name, for a platform notification (no URL in it).
 * @param wifiOnly the transfer may only use an unmetered network (Apple: no expensive or constrained access).
 */
data class TransferRequest(
    val id: String,
    val url: String,
    val headers: Map<String, String>,
    val partPath: String,
    val offset: Long,
    val expectedSize: Long?,
    val validator: String?,
    val title: String,
    val wifiOnly: Boolean,
) {
    override fun toString(): String =
        "TransferRequest(id=$id, url=<redacted>, headers=${headers.keys}, offset=$offset, expectedSize=$expectedSize, validator=${validator != null})"
}

/** How a transfer ended ([TransferListener.onResult]). */
sealed interface TransferResult {
    /**
     * [TransferRequest.partPath] holds the whole file: [bytes] long, with the [validator] its answer carried (`ETag`,
     * else `Last-Modified`).
     */
    data class Completed(val bytes: Long, val validator: String?) : TransferResult

    /** The server answered [status]. */
    data class Http(val status: Int) : TransferResult

    /**
     * The server's file isn't the one in [TransferRequest.partPath]: a resumed request was answered with the whole file
     * (`If-Range` didn't match) or a different total. The downloader starts it over from zero.
     */
    data object Changed : TransferResult

    /** The connection failed or timed out. [kind] names the exception's class for diagnostics, never its message. */
    data class Network(val kind: String) : TransferResult

    /** The volume is full, or would leave less than the downloader's floor free ([StorageFloor]). */
    data object DiskFull : TransferResult

    /** Writing failed; the downloader tells a full volume from its capacity, never from the error's text. */
    data object WriteFailed : TransferResult

    /** [DownloadTransport.stop] stopped it, or the platform did; what arrived is kept in [TransferRequest.partPath]. */
    data object Stopped : TransferResult
}

/** What a [DownloadTransport] reports; callable from any thread. */
interface TransferListener {
    /** [bytes] of the file are in place now (the request's offset included), of [totalBytes] when known. */
    fun onProgress(id: String, bytes: Long, totalBytes: Long?)

    /**
     * The server accepted the transfer's request (a 200, or a 206 continuing the file): the bytes arriving now carry
     * [validator] (`ETag`, else `Last-Modified`), which a later resume sends as `If-Range`. Transports that resume by
     * other means (Apple's resume data) may skip it.
     */
    fun onResponse(id: String, validator: String?)

    /** The transfer ended. Called once per [DownloadTransport.start]. */
    fun onResult(id: String, result: TransferResult)
}

/**
 * Moves one file's bytes per request (the [TaskDownloader] decides how many run at once). Implemented by
 * [KtorTransport] (Android, desktop) and by the Apple apps over a background `URLSession`.
 */
interface DownloadTransport {
    /** Starts [request]; it reports to [listener] until its [TransferListener.onResult]. */
    fun start(request: TransferRequest, listener: TransferListener)

    /** Stops the transfer [id], keeping what arrived; its result is [TransferResult.Stopped]. Nothing when it isn't running. */
    fun stop(id: String)

    /**
     * Which of [ids] (transfers the downloader had running when the last process ended) still run (Apple background
     * sessions go on while the app is suspended or killed), and the results of those that ended meanwhile. Those report
     * to [listener] from now on; [done] gets their ids. The default: none still runs.
     */
    fun reattach(ids: List<String>, listener: TransferListener, done: (running: List<String>) -> Unit) {
        done(emptyList())
    }
}

/**
 * The room a download leaves free: the fork's adaptive floor, the larger of 256 MiB and 1 % of the volume. A transfer
 * that would leave less is refused before it fills the volume (a full system volume can leave a device unable to boot).
 */
object StorageFloor {
    private const val MIN_FLOOR: Long = 256L * 1024 * 1024

    /** How often a transfer samples its volume while writing. */
    const val SAMPLE_BYTES: Long = 1024L * 1024

    /** The description of a refused task's [TaskException.FileSystem]: a storage-full message. */
    const val REFUSAL: String = "Insufficient space to store the download"

    fun floor(total: Long): Long = maxOf(MIN_FLOOR, (total + 99) / 100)

    /**
     * Whether writing [required] more bytes on a volume of [capacity] leaves at least [floor] free. A volume of unknown
     * size (no total: some network and FUSE mounts) fits anything; a write that then fails on a full volume still ends
     * as [TransferResult.DiskFull].
     */
    fun fits(capacity: VolumeCapacity, required: Long): Boolean =
        capacity.total <= 0 || capacity.available < 0 || capacity.available - maxOf(0L, required) >= floor(capacity.total)

    /**
     * Whether [required] more bytes don't [fit][fits] on a volume of [capacity] (null: unknown, refuses nothing). A
     * refusal logs its figures.
     */
    fun refuses(capacity: VolumeCapacity?, required: Long): Boolean {
        if (capacity == null || fits(capacity, required)) return false
        Log.w(TAG) {
            "Refusing a download: needs ${maxOf(0L, required)} bytes above a reserve of ${floor(capacity.total)} bytes; " +
                "${capacity.available} of ${capacity.total} bytes free"
        }
        return true
    }

    private const val TAG = "downloads"
}
