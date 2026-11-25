package com.edde746.plezy

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log as AndroidLog
import androidx.compose.ui.geometry.Rect
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.RootScreen
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.log.Log
import com.edde746.plezy.output.DeviceOutput
import com.edde746.plezy.report.Report
import com.edde746.plezy.report.toJson
import com.edde746.plezy.ui.probe.LayoutProbe
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.Executors
import java.util.concurrent.FutureTask
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

/**
 * Test-only report (`report` extra): what the test harness asserts on instead of a human watching. JSON lines under
 * the [TAG] logcat tag; one longer than logcat's 4 KB entry limit, which would cut it (two or three bytes a letter in
 * some languages), goes in `chunk` lines instead ([log]), which the harness joins. The screens' names are the shared
 * [Report]'s (the desktop harness writes the same):
 * - `event`: the launch's `start` (device, form factor, display), activity events, and app warnings and errors
 *   (redacted by [Log]);
 * - `ui`: whenever it changes, its `t` the moment the main thread read it, where `focus` lines are logged (so a `ui`
 *   line newer than the last `focus` line has the focus since then): the screen on top and the back stack (or the
 *   root's screen), the focused control and the splash's status line;
 * - `probes`: whenever they change, where the named controls are ([LayoutProbe], screen pixels: what
 *   `adb shell input tap` takes, menus included), in parts of one `seq`;
 * - `focus`: the moment the focused control changes;
 * - `chunk`: a part (`part` of `parts`, in order, under one `seq`) of the `text` of a line of any of these that is over
 *   [LINE_BYTES].
 */
internal class TestReport(private val context: Context) {
    /** A dev session's app; the product's running app comes from [root]. */
    @Volatile var app: AppSession? = null

    @Volatile var root: RootSession? = null

    private val t0 = SystemClock.elapsedRealtime()
    private val main = Handler(Looper.getMainLooper())
    private val executor: ScheduledExecutorService =
        Executors.newSingleThreadScheduledExecutor { Thread(it, "test-report").apply { isDaemon = true } }
    private val rects = ConcurrentHashMap<String, Rect>()
    @Volatile private var focused: String? = null
    private var lastUi: JsonObject? = null
    private var lastProbes: String? = null
    private var probeSeq = 0
    /** The last `chunk` lines' `seq`: lines are logged from the main thread and the report's own. */
    private val chunkSeq = AtomicInteger()
    private var previousSink: Log.Sink? = null

    /** Where the named controls are and which one has focus. Called on the main thread. */
    val probe: LayoutProbe = object : LayoutProbe {
        override fun place(name: String, bounds: Rect?) {
            if (bounds == null || bounds.isEmpty) rects.remove(name) else rects[name] = bounds
        }

        override val onScreen: Boolean get() = true

        override fun focus(name: String, focused: Boolean) {
            when {
                focused && this@TestReport.focused != name -> this@TestReport.focused = name
                !focused && this@TestReport.focused == name -> this@TestReport.focused = null
                else -> return
            }
            log("focus", "focus" to this@TestReport.focused)
        }
    }

    fun start(extras: LaunchExtras) {
        val display = context.resources.displayMetrics
        val features = (context.applicationContext as PlezyApplication).platform.deviceFeatures()
        val dev = extras.dev
        event(
            "start",
            mapOf(
                "dev" to (dev?.dev == true),
                "devKeep" to (dev?.data != null),
                "devOpen" to dev?.open?.let { Report.name(it.screen ?: it.destination.route) },
                "mpvOptions" to extras.mpvOptions,
                "settings" to dev?.settings.orEmpty().associate { it.key to it.value },
                "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
                "sdk" to Build.VERSION.SDK_INT,
                "soc" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) "${Build.SOC_MANUFACTURER} ${Build.SOC_MODEL}" else null,
                "television" to isTelevision(context),
                "deviceFeatures" to mapOf("hdr" to features.hdr, "matchFrameRate" to features.matchFrameRate, "audioPassthrough" to features.audioPassthrough),
                "passthroughCodecs" to DeviceOutput.passthroughCodecs(context),
                "display" to mapOf("w" to display.widthPixels, "h" to display.heightPixels, "density" to display.density),
            ),
        )
        val sink = Log.sink
        previousSink = sink
        Log.sink = Log.Sink { level, tag, message, error ->
            sink.write(level, tag, message, error)
            if (level >= Log.Level.WARN) event("log", mapOf("level" to level.name, "tag" to tag, "message" to message))
        }
        executor.scheduleWithFixedDelay({ runCatching(::sample).onFailure { AndroidLog.w(TAG, "sample failed", it) } }, 0, SAMPLE_MS, TimeUnit.MILLISECONDS)
    }

    /** An app or lifecycle event, logged at once with the playback position at that moment. */
    fun event(name: String, detail: Map<String, Any?> = emptyMap()) {
        log("event", "event" to name, *detail.toList().toTypedArray())
    }

    fun stop() {
        executor.shutdownNow()
        previousSink?.let { Log.sink = it }
        event("stop")
    }

    private fun ms(): Long = SystemClock.elapsedRealtime() - t0

    /** What the app shows, read on the main thread at [at] ([ms]). */
    private class Ui(val at: Long, val fields: Map<String, JsonElement>)

    private fun readUi(): Ui? {
        val task = FutureTask { ui() }
        main.post(task)
        return runCatching { task.get(2, TimeUnit.SECONDS) }.getOrNull()
    }

    private fun ui(): Ui {
        val plezy = context.applicationContext as PlezyApplication
        val root = root
        val rootScreen = root?.screen?.value
        val app = if (rootScreen == null || rootScreen is RootScreen.Main) root?.app ?: app else null
        val navigator = app?.navigator
        val route = navigator?.current
        val fields = linkedMapOf(
            "screen" to toJson(route?.let(Report::name) ?: rootScreen?.let(Report::name) ?: "starting"),
            "backStack" to toJson(navigator?.backStack?.value.orEmpty().map(Report::name)),
            "focus" to toJson(focused),
            // The splash's status line while the product starts (null before half a second and once it is done).
            "startup" to toJson(root?.startup?.state?.value?.status),
            "pictureInPicture" to toJson(plezy.platform.inPictureInPicture),
            "servers" to (app?.let(Report::servers) ?: toJson(null)),
        )
        return Ui(ms(), fields)
    }

    private fun sample() {
        val ui = readUi() ?: return
        val line = JsonObject(ui.fields)
        if (line != lastUi) {
            lastUi = line
            log("ui", *line.toList().toTypedArray(), t = ui.at)
        }
        logProbes()
    }

    /** The probes as `name: [left, top, width, height]`, in parts of [PROBES_PER_LINE] under one `seq`, when changed. */
    private fun logProbes() {
        val entries = rects.entries.sortedBy { it.key }.map { (name, r) ->
            name to listOf(r.left.roundToInt(), r.top.roundToInt(), r.width.roundToInt(), r.height.roundToInt())
        }
        val text = entries.joinToString { "${it.first}=${it.second}" }
        if (text == lastProbes) return
        lastProbes = text
        probeSeq++
        val parts = entries.chunked(PROBES_PER_LINE).ifEmpty { listOf(emptyList()) }
        parts.forEachIndexed { index, part ->
            log("probes", "seq" to probeSeq, "part" to index, "parts" to parts.size, "probes" to part.toMap())
        }
    }

    /**
     * One line of [type] at [t] (now by default) with [fields]; over [LINE_BYTES] (in UTF-8), its text in `chunk` lines
     * of one `seq` instead, each piece at most [PIECE_BYTES] once escaped ([pieces]).
     */
    private fun log(type: String, vararg fields: Pair<String, Any?>, t: Long = ms()) {
        val line = toJson(linkedMapOf("type" to type, "t" to t, *fields)).toString()
        if (line.encodeToByteArray().size <= LINE_BYTES) {
            AndroidLog.i(TAG, line)
            return
        }
        val seq = chunkSeq.incrementAndGet()
        val pieces = pieces(line)
        pieces.forEachIndexed { index, piece ->
            AndroidLog.i(TAG, toJson(linkedMapOf("type" to "chunk", "seq" to seq, "part" to index, "parts" to pieces.size, "text" to piece)).toString())
        }
    }

    /** [line] in pieces of at most [PIECE_BYTES] in UTF-8 once escaped as a JSON string, no surrogate pair split. */
    private fun pieces(line: String): List<String> {
        val pieces = mutableListOf<String>()
        var start = 0
        var size = 0
        var i = 0
        while (i < line.length) {
            val c = line[i]
            val pair = c.isHighSurrogate() && i + 1 < line.length
            val bytes = when {
                pair -> 4
                c == '"' || c == '\\' -> 2
                c.code < 0x80 -> 1
                c.code < 0x800 -> 2
                else -> 3
            }
            if (size + bytes > PIECE_BYTES) {
                pieces += line.substring(start, i)
                start = i
                size = 0
            }
            size += bytes
            i += if (pair) 2 else 1
        }
        pieces += line.substring(start)
        return pieces
    }

    private companion object {
        const val TAG = "PlezyReport"
        const val SAMPLE_MS = 500L
        const val PROBES_PER_LINE = 40

        /** The longest line logged whole: logcat cuts an entry's message at about 4,050 bytes. */
        const val LINE_BYTES = 3900

        /** The longest `chunk` text, escaped, leaving room for the line's other fields. */
        const val PIECE_BYTES = 3700
    }
}
