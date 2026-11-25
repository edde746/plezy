package com.edde746.plezy.crash

import com.edde746.plezy.servers.OperationTimeoutException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.getAndUpdate
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.concurrent.Volatile
import kotlin.time.Duration

/**
 * One report for the crash reporter that isn't an uncaught exception: an [error] the app caught and runs on after, a
 * [message], or a crash in native code ([nativeCrash]), with what Sentry files it under ([tags], [contexts],
 * [fingerprint]). Its text is scrubbed as a crash's.
 */
data class CrashReport(
    val error: Throwable? = null,
    val message: String? = null,
    val level: Level = Level.ERROR,
    val tags: Map<String, String> = emptyMap(),
    /** Named blocks of extra data (Sentry's contexts): only values that say nothing about the user's media or servers. */
    val contexts: Map<String, Map<String, Any>> = emptyMap(),
    val fingerprint: List<String>? = null,
    val nativeCrash: NativeCrash? = null,
) {
    enum class Level { WARNING, ERROR, FATAL }

    companion object {
        /** [error] as an error report: a timeout tagged and grouped by its operation ([CrashFilter.timeoutTags]). */
        fun of(error: Throwable): CrashReport {
            val timeout = CrashFilter.timeoutTags(error)
            return CrashReport(error = error, tags = timeout?.first.orEmpty(), fingerprint = timeout?.second)
        }
    }
}

/**
 * A crash in native code as the process's crash handler recorded it: what happened ([type], [value]), the crashed
 * thread's [frames], innermost first, and the loaded [images] they ran in, so the crash tracker symbolicates the frames
 * with the images' uploaded debug files.
 */
data class NativeCrash(
    /** The signal or exception: `SIGSEGV`, `EXCEPTION_ACCESS_VIOLATION`. */
    val type: String,
    val value: String,
    val frames: List<Frame>,
    val images: List<Image>,
) {
    /** One frame: its address where its image is known, else the handler's text for it ([function]). */
    data class Frame(val instructionAddress: Long?, val module: String?, val function: String?)

    /**
     * One loaded library: [kind] `elf` or `pe`, its file, where it was loaded, and the ids its debug file is found by
     * (an ELF's build id, a PE's CodeView GUID and age); null ids when the file couldn't be read.
     */
    data class Image(
        val kind: String,
        val codeFile: String,
        val imageAddress: Long,
        val imageSize: Long,
        val debugId: String?,
        val codeId: String?,
        val debugFile: String?,
    )
}

/**
 * The process's way to the crash reporter for code with no app graph to hand (a mapper, the startup path): the
 * platform installs [sink] and [breadcrumbs] while its crash reporter runs (this device's reports on, a DSN in the
 * build) and removes them when it stops.
 */
object CrashCapture {
    /** Sends a report; true only when the reporter accepted it (Sentry gave it a non-empty id). */
    fun interface Sink {
        fun capture(report: CrashReport): Boolean
    }

    private val installed = MutableStateFlow<Sink?>(null)

    /** The running crash reporter; null while none runs. */
    var sink: Sink?
        get() = installed.value
        set(value) {
            installed.value = value
        }

    /** Waits up to [timeout] for a crash reporter to run; the sink, or null when none came. */
    suspend fun awaitSink(timeout: Duration): Sink? = withTimeoutOrNull(timeout) { installed.first { it != null } }

    /** Sends [report]; false when it went nowhere: reports off, no reporter yet, or the reporter dropped it. */
    fun capture(report: CrashReport): Boolean = sink?.capture(report) ?: false

    /** Adds a breadcrumb to the crash reporter's trail. */
    fun interface BreadcrumbSink {
        fun add(breadcrumb: Breadcrumb)
    }

    private val waiting = MutableStateFlow<List<Breadcrumb>>(emptyList())

    /**
     * The running crash reporter's trail; null while none runs. Installing one hands it the breadcrumbs that came
     * before, so the start's steps reach the first report.
     */
    @Volatile
    var breadcrumbs: BreadcrumbSink? = null
        set(value) {
            field = value
            if (value != null) waiting.getAndUpdate { emptyList() }.forEach(value::add)
        }

    /** Adds [breadcrumb] to the trail; while no crash reporter runs, the last [BUFFERED] wait for one. */
    fun breadcrumb(breadcrumb: Breadcrumb) {
        val trail = breadcrumbs
        if (trail != null) trail.add(breadcrumb) else waiting.update { (it + breadcrumb).takeLast(BUFFERED) }
    }

    private const val BUFFERED = 50
}

/**
 * One entry of the trail the crash reporter sends with its next report (Sentry's breadcrumb), under [category]; its
 * text is scrubbed as a crash's. [data] holds only values that say nothing about the user's media or servers.
 */
data class Breadcrumb(
    val category: String,
    val message: String,
    val data: Map<String, Any> = emptyMap(),
    val warning: Boolean = false,
)

/**
 * What every platform's crash reporter does to an event before it leaves (its `beforeSend`), besides scrubbing its text
 * ([CrashReports.scrub]): [drops] the failures nobody can act on, and [timeoutTags] files timeouts by operation.
 */
object CrashFilter {
    /**
     * Whether an exception of [type] (its class's simple name) with [value] (its message) is noise: a cache's file lock
     * on Windows, Linux without D-Bus, a full disk, a server's HTTP error the OS's HTTP stack reported, an event
     * channel's teardown race, Discord not running.
     */
    fun drops(type: String?, value: String?): Boolean {
        val lower = value?.lowercase()
        return when {
            type == "FileSystemException" && value != null && "plexImageCache" in value && "errno = 32" in value -> true
            type == "FileSystemException" && lower != null && "cached_network_image_ce" in lower &&
                ("lock failed" in lower || "writefrom failed" in lower) -> true
            type == "DBusServiceUnknownException" || (value != null && "system_bus_socket" in value) -> true
            isStorageFull(value) -> true
            type == "HTTPClientError" -> true
            type == "PlatformException" && value != null && "No active stream to cancel" in value -> true
            type == "DiscordStateException" -> true
            else -> false
        }
    }

    /** A message that says the device's storage is full. */
    fun isStorageFull(message: String?): Boolean {
        val value = message?.lowercase()?.takeIf { it.isNotEmpty() } ?: return false
        return STORAGE_FULL.any { it in value }
    }

    /**
     * The tags and fingerprint of a timeout ([OperationTimeoutException] anywhere in [error]'s causes): `timeout.operation`
     * (what timed out) and `timeout.duration` (`h:mm:ss.ffffff`), grouped as `TimeoutException` by operation; null for
     * anything else.
     */
    fun timeoutTags(error: Throwable): Pair<Map<String, String>, List<String>>? {
        val timeout = generateSequence(error) { it.cause }.take(16).filterIsInstance<OperationTimeoutException>().firstOrNull()
            ?: return null
        return mapOf("timeout.operation" to timeout.operation, "timeout.duration" to clockText(timeout.timeLimit)) to
            listOf("TimeoutException", timeout.operation)
    }

    /** [duration] as `h:mm:ss.ffffff`. */
    internal fun clockText(duration: Duration): String {
        val micros = duration.inWholeMicroseconds
        val hours = micros / 3_600_000_000
        val minutes = micros / 60_000_000 % 60
        val seconds = micros / 1_000_000 % 60
        val fraction = micros % 1_000_000
        return "$hours:${minutes.pad(2)}:${seconds.pad(2)}.${fraction.pad(6)}"
    }

    private fun Long.pad(width: Int) = toString().padStart(width, '0')

    private val STORAGE_FULL = listOf(
        "sqlite_full", "database or disk is full", "no space left on device", "enospc", "errno = 112",
        "not enough space on the disk", "insufficient space to store", "volume is out of space", "nsfilewriteoutofspaceerror",
    )
}
