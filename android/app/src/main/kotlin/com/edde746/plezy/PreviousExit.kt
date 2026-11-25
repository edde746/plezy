package com.edde746.plezy

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.crash.CrashReport
import com.edde746.plezy.crash.RuntimeUiState
import com.edde746.plezy.crash.StartupMark
import com.edde746.plezy.crash.StartupMarks
import com.edde746.plezy.log.Log
import com.edde746.plezy.mpv.PlaybackDiagnostics
import java.security.MessageDigest
import java.util.concurrent.Executors
import kotlin.time.Duration.Companion.seconds

/**
 * How the app's previous process ended (Android 11+, `ApplicationExitInfo`), once per exit: logged as a warning, and
 * sent to the crash reporter when it was a failure wherever the process was, or any exit the viewer could see or hear
 * ([messageFor]). Only allowlisted values leave ([map]): the reason, status, importance, time, device model, API level,
 * ABI, low-RAM flag, the system's description masked, the process's memory, and the last [StartupMark],
 * [RuntimeUiState] ([keepStartupMarks]) and [PlaybackDiagnostics] ([keepPreviousPlayback]) it kept. An exit is reported once: its key
 * ([dedupeKey]) is committed before it is.
 */
internal object PreviousExit {
    private const val TAG = "exit"
    private const val PREFERENCES = "plezy_exit_diagnostics"
    private const val LAST_REPORTED = "last_reported_exit"
    private const val STARTUP_PHASE = "last_startup_phase"
    private const val UI_STATE = "ui_state"

    /** What the previous process kept ([keepStartupMarks]): read on the main thread as the process starts, before the report reads it on another. */
    @Volatile var previous = Launch()
        private set

    /** Android's `IMPORTANCE_PERCEPTIBLE` (picture in picture, background playback); foreground is 100. */
    private const val IMPORTANCE_PERCEPTIBLE = 230
    private val FAILURES = setOf("crash", "native_crash", "anr", "initialization_failure", "excessive_resource_usage")
    private val ABIS = setOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
    private const val MAX_MEMORY_KB = 64L * 1024 * 1024
    private const val MAX_DEVICE_MODEL = 80
    private const val MAX_DESCRIPTION = 120
    private val DOTTED_NAME = Regex("""[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z0-9_]+)+""")
    private val NUMBER = Regex("[0-9]+")
    private val OUTSIDE_DESCRIPTION = Regex("""[^A-Za-z0-9 _.:,()\[\]#<>/=-]+""")
    private val WHITESPACE = Regex("""\s+""")

    /** An exit as the system recorded it. */
    data class Exit(
        val reason: Int,
        val status: Int,
        val importance: Int,
        val timestamp: Long,
        val description: String? = null,
        val pssKb: Long = 0,
        val rssKb: Long = 0,
    )

    /** What the previous process kept of where it was: its last startup mark, UI state and playback. */
    data class Launch(val startupPhase: String? = null, val uiState: String? = null, val playback: Map<String, Any> = emptyMap())

    /** The device the exit happened on. */
    data class Device(val model: String, val apiLevel: Int, val abi: String, val lowRam: Boolean)

    /** An exit's report: its allowlisted [details], and the key that tells it from any other exit (not reported). */
    data class Report(val details: Map<String, Any>, val dedupeKey: String)

    /**
     * The crash report's message for an exit worth one, or null for a routine one: Android ends cached processes all
     * the time (memory, idling, recents cleared), so a background exit is news only when it is a failure. The reason is
     * in the message so each reason groups as its own issue.
     */
    fun messageFor(reason: String, importance: Int): String? =
        if (reason in FAILURES || importance <= IMPORTANCE_PERCEPTIBLE) "Previous Android application exit: $reason" else null

    /** Logs and reports the last exit not reported yet; best effort, never throws. */
    suspend fun report(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        try {
            val manager = context.getSystemService(ActivityManager::class.java) ?: return
            val info = manager.getHistoricalProcessExitReasons(context.packageName, 0, 1).firstOrNull() ?: return
            val exit = Exit(info.reason, info.status, info.importance, info.timestamp, info.description, info.pss, info.rss)
            val device = Device("${Build.MANUFACTURER} ${Build.MODEL}", Build.VERSION.SDK_INT, Build.SUPPORTED_ABIS.firstOrNull().orEmpty(), manager.isLowRamDevice)
            val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            val details = takeIfNew(
                map(exit, device, previous),
                // An earlier version kept the exit's time here (a Long): read as no key.
                readKey = { runCatching { preferences.getString(LAST_REPORTED, null) }.getOrNull() },
                commitKey = { preferences.edit().putString(LAST_REPORTED, it).commit() },
            ) ?: return
            Log.w(TAG) { "Previous Android application exit: " + details.entries.joinToString(" ") { (k, v) -> "$k=$v" } }
            val message = messageFor(details.getValue("reason") as String, exit.importance) ?: return
            val sink = CrashCapture.awaitSink(10.seconds) ?: return
            sink.capture(CrashReport(message = message, level = CrashReport.Level.WARNING, contexts = mapOf("android_previous_exit" to details)))
        } catch (e: Exception) {
            Log.d(TAG, e) { "could not read the previous exit" }
        }
    }

    /**
     * The details of [report] when it is an exit not reported yet and its key committed ([readKey], [commitKey]); null
     * otherwise, so a key that can't be kept never lets the same exit be reported again.
     */
    @Synchronized
    fun takeIfNew(report: Report, readKey: () -> String?, commitKey: (String) -> Boolean): Map<String, Any>? {
        if (readKey() == report.dedupeKey) return null
        if (!commitKey(report.dedupeKey)) return null
        return report.details
    }

    /** The exit's report: only allowlisted values, each in its fixed vocabulary or range. */
    fun map(exit: Exit, device: Device, launch: Launch = Launch()): Report = Report(
        details = buildMap {
            put("reason", reasonName(exit.reason))
            put("status", exit.status)
            put("importance", exit.importance)
            put("timestamp", exit.timestamp)
            put("deviceModel", deviceModel(device.model))
            put("apiLevel", device.apiLevel)
            put("abi", device.abi.takeIf { it in ABIS } ?: "unknown")
            put("lowRam", device.lowRam)
            StartupMark.fromId(launch.startupPhase)?.let { put("startupPhase", it.id) }
            description(exit.description)?.let { put("description", it) }
            exit.pssKb.takeIf { it in 1..MAX_MEMORY_KB }?.let { put("pssKb", it) }
            exit.rssKb.takeIf { it in 1..MAX_MEMORY_KB }?.let { put("rssKb", it) }
            putAll(launch.playback)
            RuntimeUiState.fromId(launch.uiState)?.let { put("uiState", it.id) }
        },
        dedupeKey = dedupeKey(exit),
    )

    /** SHA-256 over the exit's time, reason, status and importance, each length-prefixed: the same exit, the same key. */
    fun dedupeKey(exit: Exit): String {
        val digest = MessageDigest.getInstance("SHA-256")
        for (field in listOf(exit.timestamp, exit.reason, exit.status, exit.importance).map(Any::toString)) {
            digest.update("${field.length}:$field;".toByteArray(Charsets.UTF_8))
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    /**
     * The system's free-text description (`[FORCE STOP] stop <pkg> due to from pid #`, `excessive cpu # during #`)
     * names the kill path the reason codes collapse. Dotted names (other apps' packages, a server's host) and every
     * number are masked and only a fixed ASCII set survives, so it identifies neither the device nor its owner.
     */
    fun description(raw: String?): String? = raw
        ?.replace(DOTTED_NAME, "<pkg>")
        ?.replace(NUMBER, "#")
        ?.replace(OUTSIDE_DESCRIPTION, " ")
        ?.replace(WHITESPACE, " ")
        ?.trim()
        ?.take(MAX_DESCRIPTION)
        ?.trim()
        ?.ifEmpty { null }

    /** The model with whitespace and control characters collapsed to single spaces, at most 80 characters; `unknown` for none. */
    fun deviceModel(raw: String): String = raw
        .map { if (Character.isISOControl(it)) ' ' else it }
        .joinToString("")
        .replace(WHITESPACE, " ")
        .trim()
        .take(MAX_DEVICE_MODEL)
        .trim()
        .ifEmpty { "unknown" }

    /**
     * Reads what the previous process kept of where it was, then keeps this process's from here on ([StartupMarks.persist],
     * committed in order on one daemon thread) and marks its start. First thing in the process.
     */
    fun keepStartupMarks(context: Context) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        previous = readLaunch(preferences)
        val writes = Executors.newSingleThreadExecutor { Thread(it, "plezy-exit-diagnostics").apply { isDaemon = true } }
        fun write(edit: SharedPreferences.Editor.() -> Unit) = writes.execute {
            try {
                preferences.edit().apply(edit).commit()
            } catch (e: Exception) {
                Log.d(TAG, e) { "could not keep the exit diagnostics" }
            }
        }
        StartupMarks.persist = object : StartupMarks.Persist {
            override fun mark(mark: StartupMark) = write { putString(STARTUP_PHASE, mark.id) }

            override fun uiState(state: RuntimeUiState) = write { putString(UI_STATE, state.id) }

        }
        StartupMarks.mark(StartupMark.NATIVE_ON_CREATE)
    }

    /** Adds the previous process's playback ([PlaybackDiagnostics.read]) to [previous]; after [keepStartupMarks]. */
    fun keepPreviousPlayback(context: Context) {
        previous = previous.copy(playback = PlaybackDiagnostics.read(context))
    }

    private fun readLaunch(preferences: SharedPreferences): Launch = try {
        Launch(
            startupPhase = preferences.getString(STARTUP_PHASE, null),
            uiState = preferences.getString(UI_STATE, null),
        )
    } catch (e: ClassCastException) {
        // A value of another type under one of the keys: none of it is trusted.
        Launch()
    }

    fun reasonName(reason: Int): String = when (reason) {
        ApplicationExitInfo.REASON_EXIT_SELF -> "exit_self"
        ApplicationExitInfo.REASON_SIGNALED -> "signaled"
        ApplicationExitInfo.REASON_LOW_MEMORY -> "low_memory"
        ApplicationExitInfo.REASON_CRASH -> "crash"
        ApplicationExitInfo.REASON_CRASH_NATIVE -> "native_crash"
        ApplicationExitInfo.REASON_ANR -> "anr"
        ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "initialization_failure"
        ApplicationExitInfo.REASON_PERMISSION_CHANGE -> "permission_change"
        ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE -> "excessive_resource_usage"
        ApplicationExitInfo.REASON_USER_REQUESTED, ApplicationExitInfo.REASON_USER_STOPPED -> "user_requested"
        ApplicationExitInfo.REASON_DEPENDENCY_DIED -> "dependency_died"
        ApplicationExitInfo.REASON_FREEZER -> "freezer"
        ApplicationExitInfo.REASON_PACKAGE_STATE_CHANGE -> "package_state_change"
        ApplicationExitInfo.REASON_PACKAGE_UPDATED -> "package_updated"
        else -> "other"
    }
}
