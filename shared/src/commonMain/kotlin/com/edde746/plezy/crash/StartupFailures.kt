package com.edde746.plezy.crash

import com.edde746.plezy.data.DataFault
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.Redactor
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readString
import kotlinx.io.writeString
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put
import kotlin.concurrent.Volatile
import kotlin.random.Random
import kotlin.time.Clock
import kotlin.time.Instant

/** The OS and its version, as a startup failure record names them (`os osVersion`). */
internal expect fun osDescription(): String

/** The named steps of the app's start; their ids are stable: persisted records and Sentry tags match on them. */
enum class StartupPhase(val id: String) {
    PREFERENCES("preferences"),
    CRASH_REPORTING("crash-reporting"),
    LOCALE("locale"),
    WINDOW_MANAGER("window-manager"),
    DEVICE_CAPABILITIES("device-capabilities"),
    CERTIFICATE_TRUST("certificate-trust"),
    STORAGE("storage"),
    DATABASE("database"),

    /** The import of the data Plezy's earlier releases left on the device. */
    EARLIER_RELEASE_IMPORT("earlier-release-import"),
    IMAGE_CACHE("image-cache"),
    DOWNLOAD_STORAGE("download-storage"),

    /** Building the app over the opened database (`AppSession`). */
    APP("app"),
    ;

    companion object {
        fun fromId(id: String?): StartupPhase? = entries.firstOrNull { it.id == id }
    }
}

/**
 * A failed start, cut down to fields safe to show, copy, persist and upload: nothing from the preferences, the
 * database or a file's bytes, and [message] and [stackTrace] redacted ([Redactor]) as they are made.
 *
 * @param id tells this record from any other, including one a later failed start wrote moments after.
 * @param timestamp when it failed, ISO 8601 in UTC.
 * @param appVersion `version+build (commit7)`.
 * @param platform `os osVersion`: enough to diagnose, never enough to identify a machine.
 * @param reported whether it reached the crash reporter (or never can: reports off, a build without them).
 * @param dataFault why the app's saved data can't be used, when that is what failed: the failure screen then offers
 *   to reset it.
 */
data class StartupFailureRecord(
    val id: String,
    val phase: StartupPhase?,
    val errorType: String,
    val message: String,
    val stackTrace: String?,
    val timestamp: String,
    val appVersion: String,
    val platform: String,
    val reported: Boolean = false,
    val dataFault: DataFault? = null,
) {
    val phaseId: String get() = phase?.id ?: "unknown"

    /** One line for the log and the crash report: `[phase] Type: message`. */
    val headline: String get() = "[$phaseId] $errorType: $message"

    /** The plain-text block the Logs screen shows and every copy and upload of the logs carries. */
    fun describe(): String = buildString {
        appendLine("Plezy startup failure")
        appendLine("Version: $appVersion")
        appendLine("Platform: $platform")
        appendLine("When: $timestamp")
        appendLine("Phase: $phaseId")
        appendLine("Error: $errorType")
        appendLine("Message: $message")
        if (!stackTrace.isNullOrEmpty()) {
            appendLine("Stack trace:")
            appendLine(stackTrace)
        }
    }.trimEnd()

    /** The crash report it is sent as, once a crash reporter runs: a fatal message tagged and grouped by phase. */
    fun report(): CrashReport = CrashReport(
        message = "Startup failed: $headline",
        level = CrashReport.Level.FATAL,
        tags = mapOf("startup.phase" to phaseId),
        contexts = mapOf(
            "startup" to buildMap {
                put("phase", phaseId)
                put("errorType", errorType)
                put("when", timestamp)
                stackTrace?.let { put("stackTrace", it) }
            },
        ),
    )

    fun toJson(): String = buildJsonObject {
        put("id", id)
        put("phase", phase?.id)
        put("errorType", errorType)
        put("message", message)
        put("stackTrace", stackTrace)
        put("timestamp", timestamp)
        put("appVersion", appVersion)
        put("platform", platform)
        put("reported", reported)
        put("dataFault", dataFault?.id)
    }.toString()

    companion object {
        /**
         * The record of [error] (its phase from a [StartupPhaseException], unless [phase] names one), failed [at].
         */
        fun of(
            error: Throwable,
            appVersion: String,
            platform: String,
            phase: StartupPhase? = null,
            at: Instant = Clock.System.now(),
        ): StartupFailureRecord {
            val cause = StartupPhaseException.unwrap(error)
            val safeMessage = describeErrorSafely(cause)
            // A stack trace starts with the exception's message: the safe one replaces it there too.
            val stack = cause.stackTraceToString().let { trace -> cause.message?.let { trace.replace(it, safeMessage) } ?: trace }
            return StartupFailureRecord(
                id = "${at.toEpochMilliseconds().toString(16)}-${Random.nextInt(0xFFFFFF).toString(16)}",
                phase = phase ?: (error as? StartupPhaseException)?.phase,
                errorType = cause::class.simpleName ?: "Throwable",
                message = Redactor.redact(safeMessage),
                stackTrace = Redactor.redact(stack),
                timestamp = at.toString(),
                appVersion = appVersion,
                platform = platform,
                dataFault = DataFault.of(error),
            )
        }

        /**
         * [error]'s text without the input some exceptions quote: a JSON decoding error prints the document it read,
         * and at the start that is the preferences, with tokens in them. Its message and offset stay.
         */
        fun describeErrorSafely(error: Throwable): String {
            val cause = StartupPhaseException.unwrap(error)
            val text = cause.message ?: cause::class.simpleName ?: "Throwable"
            return if (cause is SerializationException) text.substringBefore("\nJSON input:").trimEnd() else text
        }

        /** The record in [text], or null when it isn't one (a field missing or of the wrong kind). */
        fun fromJson(text: String): StartupFailureRecord? {
            val json = try {
                Json.parseToJsonElement(text).jsonObject
            } catch (_: IllegalArgumentException) {
                return null
            }
            fun string(key: String) = (json[key] as? JsonPrimitive)?.takeIf { it.isString }?.content
            fun bool(key: String) = (json[key] as? JsonPrimitive)?.booleanOrNull ?: false
            val message = string("message") ?: return null
            val errorType = string("errorType") ?: return null
            val timestamp = string("timestamp")?.takeIf { runCatching { Instant.parse(it) }.isSuccess } ?: return null
            return StartupFailureRecord(
                id = string("id") ?: "legacy-$timestamp",
                phase = StartupPhase.fromId(string("phase")),
                errorType = errorType,
                message = message,
                stackTrace = string("stackTrace"),
                timestamp = timestamp,
                appVersion = string("appVersion") ?: "unknown",
                platform = string("platform") ?: "unknown",
                reported = bool("reported"),
                dataFault = DataFault.fromId(string("dataFault")),
            )
        }
    }
}

/** A start's failure tagged with the [phase] it came from; [cause] is the real error, which classification reads. */
class StartupPhaseException(val phase: StartupPhase, override val cause: Throwable) :
    Exception("StartupPhaseException(${phase.id}): ${StartupFailureRecord.describeErrorSafely(cause)}", cause) {
    companion object {
        fun unwrap(error: Throwable): Throwable {
            var current = error
            while (current is StartupPhaseException) current = current.cause
            return current
        }
    }
}

/** Runs [block] as the start's [phase]: an exception it throws comes out as a [StartupPhaseException] naming it, or an inner phase's. */
inline fun <T> startupPhase(phase: StartupPhase, block: () -> T): T = try {
    block()
} catch (e: StartupPhaseException) {
    throw e
} catch (e: Exception) {
    throw StartupPhaseException(phase, e)
}

/**
 * The app's start failed: [record] (already kept for the next start) is what the startup failure screen shows, copies
 * and offers to retry.
 */
class StartupFailedException(val record: StartupFailureRecord, cause: Throwable) : Exception(record.headline, cause)

/**
 * The last failed start, kept beside the database (`startup_failure.json` in [directory]) so it outlives the process
 * that failed: a failed start has no other way out (its log is in memory, a GUI launch has no console, and the Logs
 * screen is behind the start that failed). The next start sends it to the crash reporter ([flush]) once that runs, and
 * shows it on the Logs screen ([consumePrevious], [pending]) where the user can copy or upload it.
 *
 * Best effort: a failure here is logged and never thrown. Every change of the file runs under one lock, so the disk
 * holds the last call's record and [markReported] can't overwrite a newer failure.
 */
class StartupFailures(directory: String) {
    private val file = Path(directory, FILE_NAME)
    private val lock = Mutex()

    /** The record of this process: one recorded now, or an earlier start's [consumePrevious] read. */
    @Volatile
    var pending: StartupFailureRecord? = null
        private set

    /**
     * Keeps [failure] from the start that is failing now, on its thread: nothing else touches the record yet, and the
     * process may end right after.
     */
    fun recordFailingStart(failure: StartupFailureRecord) {
        pending = failure
        write(failure)
    }

    /** Keeps [failure] (shown at once, written to disk). */
    suspend fun record(failure: StartupFailureRecord) {
        pending = failure
        lock.withLock { write(failure) }
    }

    /** The record on disk, left there. */
    suspend fun peek(): StartupFailureRecord? = lock.withLock { read() }

    /** Rewrites [failure] as reported, unless a newer one replaced it on disk meanwhile (compare and set by id). */
    suspend fun markReported(failure: StartupFailureRecord) {
        lock.withLock {
            val current = read()
            if (current == null || current.id != failure.id) {
                Log.d(TAG) { "the startup failure record was replaced before it could be marked reported" }
                return
            }
            val updated = failure.copy(reported = true)
            if (pending?.id == failure.id) pending = updated
            write(updated)
        }
    }

    /**
     * Sends the record on disk to the crash reporter, once: [send] (null while no reporter runs: the record waits for
     * the next start) gives it to the reporter and says whether it took it; only then is it marked reported. A user who
     * turned reports off ([optedIn] false) or a build that has none ([canEverReport] false) never sends it, so it is
     * marked reported at once rather than kept forever.
     */
    suspend fun flush(optedIn: Boolean, canEverReport: Boolean, send: ((StartupFailureRecord) -> Boolean)?) {
        val record = peek()
        if (record == null || record.reported) return
        if (!optedIn || !canEverReport) {
            Log.d(TAG) { if (optedIn) "startup failure not reported: this build has no crash reports" else "startup failure not reported: crash reports are off" }
            markReported(record)
            return
        }
        if (send == null) {
            Log.d(TAG) { "startup failure kept for the next start: no crash reporter runs" }
            return
        }
        val sent = try {
            send(record)
        } catch (e: Exception) {
            Log.d(TAG, e) { "could not report the startup failure" }
            false
        }
        if (sent) markReported(record) else Log.d(TAG) { "the crash reporter didn't take the startup failure; kept for the next start" }
    }

    /**
     * An earlier start's record, now [pending]: deleted once it was reported, kept on disk while it wasn't (the
     * reporter's only retry); an unreadable file is deleted.
     */
    suspend fun consumePrevious(): StartupFailureRecord? = lock.withLock {
        try {
            if (!SystemFileSystem.exists(file)) return@withLock null
            val record = StartupFailureRecord.fromJson(SystemFileSystem.source(file).buffered().use { it.readString() })
            if (record == null || record.reported) SystemFileSystem.delete(file, mustExist = false)
            if (record != null) pending = record
            record
        } catch (e: Exception) {
            Log.d(TAG, e) { "could not read an earlier startup failure record" }
            null
        }
    }

    /** Forgets the record, in memory and on disk (the Logs screen's Clear). */
    suspend fun clear() {
        lock.withLock {
            pending = null
            try {
                SystemFileSystem.delete(file, mustExist = false)
            } catch (e: Exception) {
                Log.d(TAG, e) { "could not delete the startup failure record" }
            }
        }
    }

    private fun read(): StartupFailureRecord? = try {
        if (SystemFileSystem.exists(file)) StartupFailureRecord.fromJson(SystemFileSystem.source(file).buffered().use { it.readString() }) else null
    } catch (e: Exception) {
        Log.d(TAG, e) { "could not read the startup failure record" }
        null
    }

    private fun write(failure: StartupFailureRecord) {
        try {
            file.parent?.let { SystemFileSystem.createDirectories(it) }
            SystemFileSystem.sink(file).buffered().use { it.writeString(failure.toJson()) }
        } catch (e: Exception) {
            Log.d(TAG, e) { "could not keep the startup failure record" }
        }
    }

    companion object {
        const val FILE_NAME = "startup_failure.json"
        private const val TAG = "startup"
    }
}
