package com.edde746.plezy.desktop.harness

import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.geometry.Rect
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.RootScreen
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.desktop.players.ExternalPlayersObserver
import com.edde746.plezy.log.Log
import com.edde746.plezy.mpv.DesktopWindow
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.playback.players.ExternalLaunchStatus
import com.edde746.plezy.playback.players.ExternalPlayerAttempt
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.report.Report
import com.edde746.plezy.report.toJson
import com.edde746.plezy.ui.probe.LayoutProbe
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import java.awt.AWTEvent
import java.awt.Component
import java.awt.Container
import java.awt.Dialog
import java.awt.Toolkit
import java.awt.Window
import java.awt.event.KeyEvent
import java.awt.event.MouseEvent
import java.lang.management.ManagementFactory
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.FutureTask
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import javax.swing.JFileChooser
import javax.swing.JTextField
import javax.swing.SwingUtilities
import kotlin.math.roundToInt
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Test-only report (the harness launcher's `--report`): what the remote harness asserts on instead of a human watching.
 *
 * Every [SAMPLE_MS] it records the screen on top and the back stack (or the root's screen), the splash's status line,
 * the device's network and stored settings, the window geometry, the app's own dialogs on screen (Swing's file
 * choosers: their kind, the text in their name field, their filters and look) and where the named controls are
 * ([probe], window pixels), so the harness can click them. App actions are logged as [event]s (on Windows also the
 * display switches and the media controls' commands; the external players' launches), and so are the app's warnings
 * and errors (redacted by [Log]). Each sample, event,
 * startup milestone and the final status is a record of the journal ([ReportJournal]), appended and flushed as it
 * happens, so a crash still leaves every record behind; the latest sample alone also goes to `report.last.json` beside
 * it (replaced atomically), for a harness that polls the screen during a long run. A sample the UI thread can't answer
 * within [UI_WAIT_MS] is a `sampleTimedOut` event instead.
 */
internal class TestReport(private val path: Path) : ExternalPlayersObserver {
    @Volatile var app: AppSession? = null

    /** The product's root; its running app, when there is one, is sampled like [app]. */
    @Volatile var root: RootSession? = null

    @Volatile var window: DesktopWindow? = null
    @Volatile var isFocused: () -> Boolean = { false }

    /** The window is the active one (its own popups can hold the keyboard focus meanwhile). */
    @Volatile var isActive: () -> Boolean = { false }

    /** The window is minimized: it presents nothing, and mpv's output reads as SDR meanwhile. */
    @Volatile var isMinimized: () -> Boolean = { false }

    /** The window is maximized, as AWT's extended state has it. */
    @Volatile var isMaximized: () -> Boolean = { false }

    /** The Wayland window's Compose frames since the last sample (their render times and renderer); null elsewhere. */
    @Volatile var paintStats: () -> Map<String, Any?>? = { null }

    /** `--frame-times`' frames and stalls, taken with each sample; null without it. */
    @Volatile var frameLog: FrameLog? = null

    /** The engine of the latest playback. */
    @Volatile private var engine: MpvPlayerEngine? = null
    private var engines = 0
    private val probes = ConcurrentHashMap<String, Rect>()

    /** Compose frames since the last sample (`--play`'s overlay): count, the last frame's time and the longest gap. */
    private val frames = LongArray(3)

    /** `--play`'s overlay drew the Compose frame of [nanos] (withFrameNanos' time). */
    fun composeFrame(nanos: Long) = synchronized(frames) {
        if (frames[1] != 0L) frames[2] = maxOf(frames[2], nanos - frames[1])
        frames[0]++
        frames[1] = nanos
    }

    private fun takeFrames(): Map<String, Any?>? = synchronized(frames) {
        if (frames[0] == 0L) return null
        val taken = mapOf("frames" to frames[0], "longestGapMs" to frames[2] / 1e6)
        frames[0] = 0
        frames[2] = 0
        taken
    }

    // The app image's runtime has no jdk.management (the harness started by the image's launcher): no CPU time there.
    private val os = if (ModuleLayer.boot().findModule("jdk.management").isEmpty) null else ManagementFactory.getOperatingSystemMXBean() as? com.sun.management.OperatingSystemMXBean
    private var lastCpuNanos = 0L
    private var lastCpuWall = 0L

    /** The process's CPU time since the last sample, in cores (1.0: one core busy all the time). */
    private fun cpuCores(): Double? {
        val cpu = os?.processCpuTime ?: return null
        val wall = System.nanoTime()
        val cores = if (lastCpuWall == 0L) null else (cpu - lastCpuNanos).toDouble() / (wall - lastCpuWall)
        lastCpuNanos = cpu
        lastCpuWall = wall
        return cores
    }

    /** The playing engine's video output: the plane's state, mpv's decoder, output range and frame drops. */
    private fun video(engine: MpvPlayerEngine): Map<String, Any?> {
        val s = engine.currentState
        return linkedMapOf(
            "output" to engine.videoOutputStats(), "hwdec" to s.hwdec, "loaded" to s.loaded, "error" to s.error?.message,
            "video" to s.video?.let { mapOf("width" to it.width, "height" to it.height, "codec" to it.codec, "range" to it.dynamicRange.name) },
            "outputRange" to s.outputDynamicRange?.name,
            "stats" to s.stats?.let {
                mapOf(
                    "pixelFormat" to it.pixelFormat, "hwPixelFormat" to it.hwPixelFormat, "transfer" to it.transfer, "primaries" to it.primaries,
                    "dropped" to it.droppedFrames, "decoderDropped" to it.decoderDroppedFrames, "delayed" to it.delayedFrames,
                    "displayRefreshRate" to it.displayRefreshRate,
                )
            },
        )
    }

    /** The named control that has keyboard focus, as [probe] last heard; null while none has. */
    @Volatile private var focused: String? = null

    /**
     * Collects the positions of the controls the UI names ([com.edde746.plezy.ui.probe.layoutProbe]) and which of them
     * has focus. An empty rect is a control that isn't placed (a lazy list keeps items it scrolled away composed, at zero
     * size): not on screen.
     */
    val probe = object : LayoutProbe {
        override fun place(name: String, bounds: Rect?) {
            if (bounds == null || bounds.isEmpty) probes.remove(name) else probes[name] = bounds
        }

        override fun focus(name: String, focused: Boolean) {
            if (focused) this@TestReport.focused = name else if (this@TestReport.focused == name) this@TestReport.focused = null
        }
    }

    private val t0 = System.nanoTime()
    private val marks = linkedMapOf<String, Long>()
    private val executor = Executors.newSingleThreadScheduledExecutor { Thread(it, "test-report").apply { isDaemon = true } }

    /** The journal from [start] to [finish]; records outside them are dropped. */
    private var journal: ReportJournal? = null
    private val latest: Path = path.resolveSibling(path.fileName.toString().removeSuffix(".jsonl") + ".last.json")

    /** When the OS started the process (the launcher), in epoch ms: the startup milestones count from it. */
    private val processStart = ProcessHandle.current().info().startInstant().map { it.toEpochMilli() }
        .orElse(ManagementFactory.getRuntimeMXBean().startTime)

    /**
     * Starts the journal at [path] (replacing an earlier run's), with the JVM's start and the milestones marked so far,
     * and the sampling. Called once this process is the app ([com.edde746.plezy.desktop.SingleInstance]): a later
     * start that hands its link over must not touch the running app's journal.
     */
    @Synchronized fun start() {
        journal = ReportJournal(path)
        append("mark", markRecord("jvm", ManagementFactory.getRuntimeMXBean().startTime - processStart))
        marks.forEach { (name, nanos) -> append("mark", markRecord(name, sinceProcessStart(nanos))) }
        val sink = Log.sink
        Log.sink = Log.Sink { level, tag, message, error ->
            sink.write(level, tag, message, error)
            if (level >= Log.Level.WARN) event("log", mapOf("level" to level.name, "tag" to tag, "message" to message))
        }
        // On the report's thread, as each sample: reading the mpv library's path loads it.
        executor.execute { append("env", env()) }
        executor.scheduleAtFixedRate({ runCatching { sample() }.onFailure { it.printStackTrace() } }, 0, SAMPLE_MS, TimeUnit.MILLISECONDS)
        // Where each press arrives as AWT sees it (the component, its point, the screen point; a key's code and its
        // focus owner): a harness's input can be checked against what it aimed at.
        Toolkit.getDefaultToolkit().addAWTEventListener({ e ->
            if (e is MouseEvent && e.id == MouseEvent.MOUSE_PRESSED) {
                val detail = mapOf(
                    "button" to e.button,
                    "component" to e.component?.javaClass?.simpleName,
                    "at" to listOf(e.x, e.y),
                    "screen" to listOf(e.xOnScreen, e.yOnScreen),
                )
                event("mousePressed", detail)
            } else if (e is KeyEvent && e.id == KeyEvent.KEY_PRESSED) {
                event("keyPressed", mapOf("key" to KeyEvent.getKeyText(e.keyCode), "code" to e.keyCode, "component" to e.component?.javaClass?.simpleName))
            }
        }, AWTEvent.MOUSE_EVENT_MASK or AWTEvent.KEY_EVENT_MASK)
    }

    /** Milliseconds since the report started. */
    fun ms(): Long = (System.nanoTime() - t0) / 1_000_000

    /** First occurrence of a startup milestone, at [nanos] ([System.nanoTime]; now by default). */
    @Synchronized fun mark(name: String, nanos: Long = System.nanoTime()) {
        if (marks.putIfAbsent(name, nanos) == null && journal != null) append("mark", markRecord(name, sinceProcessStart(nanos)))
    }

    /** [nanos] ([System.nanoTime]) in ms since the OS started the process. */
    private fun sinceProcessStart(nanos: Long): Long = System.currentTimeMillis() - (System.nanoTime() - nanos) / 1_000_000 - processStart

    private fun markRecord(name: String, ms: Long) = linkedMapOf("name" to name, "ms" to ms)

    /**
     * The startup milestones a drawn frame shows, each marked at the next frame's start (within a frame interval of its
     * presentation): `firstFrame` (the window's first; the splash marks it when it draws before the app replaces it),
     * `firstScreen` (past the splash) and `home` (the app on Home).
     * Runs in the window's composition, on the UI thread, until Home shows or [STARTUP_WATCH] passes. It looks every
     * [STARTUP_POLL] without asking for a frame, and asks for one only when a milestone it hasn't marked shows: a run
     * that starts elsewhere (`--dev-open`) draws nothing for it while it waits.
     */
    suspend fun watchStartup() {
        val marked = HashSet<String>()
        withTimeoutOrNull(STARTUP_WATCH) {
            while ("home" !in marked) {
                val shown = shownMilestones().filter { it !in marked }
                if (shown.isNotEmpty()) {
                    withFrameNanos { }
                    shown.forEach { mark(it) }
                    marked += shown
                }
                delay(STARTUP_POLL)
            }
        }
    }

    private fun shownMilestones(): List<String> {
        val root = root
        val rootScreen = root?.screen?.value
        val app = if (rootScreen == null) app else (rootScreen as? RootScreen.Main)?.app
        val shown = mutableListOf("firstFrame")
        if ((rootScreen != null && rootScreen != RootScreen.Starting) || app != null) shown += "firstScreen"
        if (app?.navigator?.current == Route.Home) shown += "home"
        return shown
    }

    /** A playback started on [engine]. */
    fun onEngine(engine: MpvPlayerEngine) {
        this.engine = engine
        event("playback", mapOf("engine" to ++engines))
    }

    /** An app action, with the playback state at that moment and any extra detail. */
    @Synchronized fun event(name: String, detail: Map<String, Any?> = emptyMap()) {
        val s = engine?.currentState
        append(
            "event",
            linkedMapOf<String, Any?>(
                "t" to ms(), "wall" to System.currentTimeMillis(), "event" to name,
                "positionSeconds" to (s?.positionSeconds ?: 0.0), "paused" to (s?.paused ?: false),
            ) + detail,
        )
    }

    /**
     * An external player's launch (`externalPlayerLaunch`): its status and the program started (`command`) or the
     * scheme of the URL opened (`opened`), never the URL itself.
     */
    override fun externalPlayerLaunched(started: ExternalPlayerAttempt?, status: ExternalLaunchStatus) {
        val detail = when (started) {
            is ExternalPlayerAttempt.Command -> mapOf("command" to started.command.first())
            is ExternalPlayerAttempt.OpenUrl -> mapOf("opened" to started.url.substringBefore(':'))
            null -> emptyMap()
        }
        event("externalPlayerLaunch", mapOf("status" to status.name) + detail)
    }

    /** Stops sampling and ends the journal with the run's [status]; the first status stands. */
    fun finish(status: String) {
        executor.shutdown()
        executor.awaitTermination(3, TimeUnit.SECONDS)
        synchronized(this) {
            append("status", status)
            journal?.close()
            journal = null
        }
    }

    /** One journal record: `{"<kind>": <value>}`. */
    @Synchronized private fun append(kind: String, value: Any?) {
        journal?.append(JsonObject(mapOf(kind to toJson(value))))
    }

    /** What the UI shows, read on the UI thread. */
    private class UiState(
        val screen: String,
        val backStack: List<String>,
        /** The app's own dialogs on screen ([dialogFields]). */
        val dialogs: List<Map<String, Any?>>,
    )

    private fun ui(): UiState? {
        val root = root
        val app = root?.app ?: app
        if (root == null && app == null) return null
        val task = FutureTask {
            val rootScreen = root?.screen?.value
            val main = rootScreen == null || rootScreen is RootScreen.Main
            val navigator = (if (main) app else null)?.navigator
            val route = navigator?.current
            UiState(
                screen = route?.let(Report::name) ?: rootScreen?.let(Report::name).orEmpty(),
                backStack = navigator?.backStack?.value?.map(Report::name).orEmpty(),
                dialogs = Window.getWindows().filterIsInstance<Dialog>().filter { it.isShowing }.map(::dialogFields),
            )
        }
        SwingUtilities.invokeLater(task)
        return try {
            task.get(UI_WAIT_MS, TimeUnit.MILLISECONDS)
        } catch (e: TimeoutException) {
            // No sample reads it any more: the UI thread skips it unless it has started.
            task.cancel(false)
            throw e
        }
    }

    private fun sample() {
        val ui = try {
            ui()
        } catch (e: TimeoutException) {
            event("sampleTimedOut", mapOf("waitedMs" to UI_WAIT_MS))
            return
        }
        val w = window
        val graph = (root?.app ?: app)?.graph
        val sample = linkedMapOf<String, Any?>(
            "t" to ms(),
            "wall" to System.currentTimeMillis(),
            "screen" to ui?.screen,
            // The splash's status line while the product starts (null before half a second and once it is done).
            "startup" to root?.startup?.state?.value?.status,
            "backStack" to ui?.backStack,
            // The device's network as the app sees it (a dev session's `offline` switch included).
            "servers" to (root?.app ?: app)?.let { a -> runCatching { Report.servers(a) }.getOrNull() },
            "network" to graph?.network?.value?.let { linkedMapOf("online" to it.online, "metered" to it.metered) },
            "stored" to graph?.let { g -> runCatching { runBlocking { Report.stored(g.data.deviceSettings.settings()) } }.getOrNull() },
            "probes" to probes.entries.sortedBy { it.key }.associate { (name, r) ->
                name to listOf(r.left.roundToInt(), r.top.roundToInt(), r.width.roundToInt(), r.height.roundToInt())
            },
            "focus" to focused,
            "window" to w?.let {
                linkedMapOf(
                    "frame" to it.frameRect(), "content" to runCatching { it.contentRect() }.getOrNull(), "monitor" to it.monitorRect(),
                    "fullscreen" to it.isFullscreen, "focused" to isFocused(), "active" to isActive(), "minimized" to isMinimized(),
                    "maximized" to isMaximized(),
                    "darkChrome" to it.hasDarkChrome(),
                )
            },
            "dialogs" to ui?.dialogs,
            "handles" to DesktopWindow.processHandleCounts().ifEmpty { null },
            "video" to engine?.let(::video),
            "paint" to paintStats(),
            "compose" to takeFrames(),
            "frameLog" to frameLog?.take(),
            "cpuCores" to cpuCores(),
        )
        val element = toJson(sample)
        append("sample", element)
        // The latest sample alone beside the journal: a harness polling it needn't parse every sample so far.
        replace(latest, Json.encodeToString(JsonElement.serializer(), element))
    }

    /** What the run ran on: the OS, the JVM, the interop and scale settings and the mpv library. */
    private fun env(): Map<String, Any?> = linkedMapOf(
        "os" to System.getProperty("os.name"),
        "java" to System.getProperty("java.runtime.version"),
        "vendor" to System.getProperty("java.vm.vendor"),
        "interopBlending" to System.getProperty("compose.interop.blending"),
        "uiScale" to DesktopWindow.uiScale,
        "mpvLibrary" to runCatching { com.edde746.plezy.mpv.MpvNatives.library.toString() }.getOrNull(),
        // Under Wayland the app is a native Wayland client (sun.awt.wl.WLToolkit), elsewhere an X11 or Windows one.
        "awtToolkit" to Toolkit.getDefaultToolkit().javaClass.name,
        "waylandSession" to com.edde746.plezy.mpv.WaylandSession.active,
        "java2dUiScale" to System.getProperty("sun.java2d.uiScale"),
        "awtToolkitName" to System.getProperty("awt.toolkit.name"),
        "waylandDisplay" to System.getenv("WAYLAND_DISPLAY"),
    )

    /** Writes [text] to [target] through a temporary file moved over it, so a reader never sees half a file. */
    private fun replace(target: Path, text: String) {
        val tmp = target.resolveSibling(target.fileName.toString() + ".tmp")
        Files.createDirectories(target.toAbsolutePath().parent)
        Files.writeString(tmp, text)
        // A reader holding the file open without delete sharing makes the replace fail on Windows; retry briefly.
        repeat(20) { attempt ->
            try {
                Files.move(tmp, target, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
                return
            } catch (e: java.io.IOException) {
                if (attempt == 19) throw e
                Thread.sleep(25)
            }
        }
    }

    private companion object {
        const val SAMPLE_MS = 500L

        /** How long a sample waits for the UI thread to read the screens' state. */
        const val UI_WAIT_MS = 2000L

        /** How long [watchStartup] waits for Home. */
        val STARTUP_WATCH = 30.seconds

        /** How often [watchStartup] looks for a milestone it hasn't marked. */
        val STARTUP_POLL = 4.milliseconds

        /**
         * A dialog of the app's own on screen: its title, its frame (AWT's pixels: physical on Linux, scaled on
         * Windows), whether it is the active window and its system chrome dark, and, for a Swing file chooser, its kind
         * (OPEN or SAVE), its look's UI class, the text in its name field (a save's proposed name), its filters (the one
         * in effect first) and the name field's rect, where the harness types a path. Call on the event thread.
         */
        fun dialogFields(d: Dialog): Map<String, Any?> {
            val chooser = descendants(d).filterIsInstance<JFileChooser>().firstOrNull()
            val field = chooser?.let { c -> descendants(c).filterIsInstance<JTextField>().firstOrNull { it.isShowing && it.isEditable } }
            return linkedMapOf(
                "title" to d.title,
                "frame" to listOf(d.x, d.y, d.width, d.height),
                "active" to d.isActive,
                "darkChrome" to DesktopWindow.hasDarkChrome(d),
                "chooser" to chooser?.let { c ->
                    linkedMapOf(
                        "type" to when (c.dialogType) {
                            JFileChooser.OPEN_DIALOG -> "OPEN"
                            JFileChooser.SAVE_DIALOG -> "SAVE"
                            else -> "CUSTOM"
                        },
                        "ui" to c.ui.javaClass.simpleName,
                        "fileName" to field?.text,
                        "filter" to c.fileFilter?.description,
                        "filters" to c.choosableFileFilters.map { it.description },
                        "nameField" to field?.let { f -> f.locationOnScreen.let { listOf(it.x, it.y, f.width, f.height) } },
                    )
                },
            )
        }

        private fun descendants(c: Container): Sequence<Component> =
            c.components.asSequence().flatMap { sequenceOf(it) + if (it is Container) descendants(it) else emptySequence() }
    }
}
