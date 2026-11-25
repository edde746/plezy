package com.edde746.plezy.desktop.harness

import androidx.compose.runtime.Composable
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.DevCrashException
import com.edde746.plezy.app.DevLaunch
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.app.applyDevSettings
import com.edde746.plezy.app.devAppSession
import com.edde746.plezy.app.httpClient
import com.edde746.plezy.crash.CrashReports
import com.edde746.plezy.crash.ReleaseChannel
import com.edde746.plezy.crash.crashReports
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.desktop.Bootstrap
import com.edde746.plezy.desktop.Cli
import com.edde746.plezy.desktop.TestLaunch
import com.edde746.plezy.desktop.TestSession
import com.edde746.plezy.desktop.runApp
import com.edde746.plezy.mpv.DesktopWindow
import com.edde746.plezy.mpv.MpvNatives
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.mpv.WaylandSession
import com.edde746.plezy.mpv.WaylandWindow
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.ui.app.PlezyPlatform
import kotlinx.coroutines.runBlocking
import sun.misc.Unsafe
import java.awt.Frame
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemorySegment
import java.lang.foreign.ValueLayout
import java.nio.file.Path
import javax.swing.JFrame
import javax.swing.SwingUtilities
import kotlin.system.exitProcess

/** When the launcher started (TestMainKt loads with main()): the report's `main` milestone, and `--engine-set` times count from here. */
private val startedAt = System.nanoTime()

/**
 * The harness launcher (the desktop test harness starts it, with app-desktop's writeHarnessArgs argfile): the desktop
 * app with the test-only options ([TestOptions]) on top of its own ([Cli]), run through the app's [runApp] with a
 * [TestLaunch]. The release jar has neither.
 *
 *     java @harness.args com.edde746.plezy.desktop.harness.TestMainKt [test options] [app options] [<plezy:// link>]
 */
fun main(args: Array<String>) {
    // As the app's main: AWT's toolkit is chosen before anything here (the report's input listener) touches AWT.
    WaylandSession.useNativeToolkit()
    val (cli, options) = try {
        TestOptions.parse(args)
    } catch (e: Cli.Error) {
        System.err.println("plezy: ${e.message}\n\n${TestOptions.USAGE}")
        exitProcess(2)
    }
    val launch = HarnessLaunch(options)
    runApp(cli, launch)
    options.exitAfterSeconds?.let(launch::exitAfter)
    options.crashAfterSeconds?.let(::crashAfter)
    options.crashNativeAfterSeconds?.let(::crashNativeAfter)
    options.abortNativeAfterSeconds?.let(::abortNativeAfter)
    options.crashVmAfterSeconds?.let(::crashVmAfter)
}

/** `--crash-after`: throws a [DevCrashException] on a thread of its own [seconds] from now, which nothing catches. */
private fun crashAfter(seconds: Double) {
    Thread({
        Thread.sleep((seconds * 1000).toLong())
        throw DevCrashException()
    }, "crash-after").apply { isDaemon = true; start() }
}

/**
 * `--crash-native-after`: [seconds] from now, calls libmpv's `mpv_client_id` with a handle at address 8, which reads
 * through it inside libmpv: an access violation (SIGSEGV on Linux) in libmpv's code that ends the process, as a libmpv
 * crash does.
 */
private fun crashNativeAfter(seconds: Double) {
    Thread({
        Thread.sleep((seconds * 1000).toLong())
        val clientId = Linker.nativeLinker().downcallHandle(
            MpvNatives.lookup().find("mpv_client_id").orElseThrow(),
            FunctionDescriptor.of(ValueLayout.JAVA_LONG, ValueLayout.ADDRESS),
        )
        clientId.invokeWithArguments(MemorySegment.ofAddress(8))
    }, "crash-native-after").apply { isDaemon = true; start() }
}

/**
 * `--crash-vm-after`: [seconds] from now, reads address 8 through `Unsafe`: a fault in the JVM's own code, which HotSpot
 * reports and then ends the process through its fatal-error path (an abort() on Linux, to dump core).
 */
private fun crashVmAfter(seconds: Double) {
    Thread({
        Thread.sleep((seconds * 1000).toLong())
        val unsafe = Unsafe::class.java.getDeclaredField("theUnsafe").apply { isAccessible = true }.get(null) as Unsafe
        @Suppress("DEPRECATION")
        unsafe.getLong(8L)
    }, "crash-vm-after").apply { isDaemon = true; start() }
}

/**
 * `--abort-native-after`: [seconds] from now, creates an mpv with a render context and destroys the mpv without freeing
 * the context, a broken API use libmpv ends the process for: its core thread calls abort() ("mpv_render_context_free()
 * not called").
 */
private fun abortNativeAfter(seconds: Double) {
    Thread({
        Thread.sleep((seconds * 1000).toLong())
        val linker = Linker.nativeLinker()
        val mpv = MpvNatives.lookup()
        fun call(name: String, descriptor: FunctionDescriptor, vararg args: Any): Any? =
            linker.downcallHandle(mpv.find(name).orElseThrow(), descriptor).invokeWithArguments(*args)
        val address = ValueLayout.ADDRESS
        val arena = Arena.global()
        // mpv_create insists on the C numeric locale, which the JVM replaced with the user's on Linux (glibc's LC_NUMERIC: 1).
        if (!System.getProperty("os.name").startsWith("Windows")) {
            linker.downcallHandle(linker.defaultLookup().find("setlocale").orElseThrow(), FunctionDescriptor.of(address, ValueLayout.JAVA_INT, address))
                .invokeWithArguments(1, arena.allocateFrom("C"))
        }
        val handle = call("mpv_create", FunctionDescriptor.of(address)) as MemorySegment
        check(handle != MemorySegment.NULL) { "mpv_create failed" }
        check(call("mpv_initialize", FunctionDescriptor.of(ValueLayout.JAVA_INT, address), handle) == 0) { "mpv_initialize failed" }
        // mpv_render_param[]: { MPV_RENDER_PARAM_API_TYPE (1), "sw" }, then the terminating { 0, NULL }.
        val params = arena.allocate(32, 8)
        params.set(ValueLayout.JAVA_INT, 0, 1)
        params.set(address, 8, arena.allocateFrom("sw"))
        val context = arena.allocate(address)
        val created = call("mpv_render_context_create", FunctionDescriptor.of(ValueLayout.JAVA_INT, address, address, address), context, handle, params)
        check(created == 0) { "mpv_render_context_create failed: $created" }
        call("mpv_terminate_destroy", FunctionDescriptor.ofVoid(address), handle)
    }, "abort-native-after").apply { isDaemon = true; start() }
}

/** [options] as the app's [TestLaunch]: a dev session, a device of its own, the test report, the engine calls. */
private class HarnessLaunch(private val options: TestOptions) : TestLaunch {
    private val report = options.report?.let(::TestReport)

    /** The latest playback's engine, which a later `--engine-set` call goes to. */
    @Volatile private var engine: PlayerEngine? = null

    /** Closes the app as its window's close button does; null until the window shows the app. */
    @Volatile private var close: (() -> Unit)? = null

    override val dataDir: Path? = options.dataDir
    override val session: TestSession? = if (options.dev.dev) DevSession(options.dev, options.dataDir) else null
    override val windowSize: Pair<Int, Int>? = options.windowSize
    override val windowPlacement: Boolean = options.windowPlacement
    override val slowStartMillis: Long = options.dev.slowStartMillis
    override val layoutProbe = report?.probe
    override val externalPlayers = report
    override val gamepadStates = options.gamepadFeed?.let(::GamepadFeed)

    override fun start() {
        report?.start()
        report?.mark("main", startedAt)
    }

    override fun mark(name: String) {
        report?.mark(name)
    }

    override fun event(name: String, detail: Map<String, Any?>) {
        report?.event(name, detail)
        // `--play`'s playback is the harness's own, which no app session releases: the app's close waits for it.
        if (name == "close" && options.play != null) engine?.release()
    }

    override fun onEngine(engine: MpvPlayerEngine, number: Int) {
        this.engine = engine
        report?.onEngine(engine)
        // The calls at 0 s, on the first playback's engine as it is created (the engine holds them until mpv starts).
        if (number == 1) options.engineSets.filter { it.atSeconds == 0.0 }.forEach { call(engine, it) }
    }

    override fun onShow(window: JFrame, desktop: DesktopWindow, root: RootSession?, app: AppSession?, close: () -> Unit) {
        report?.root = root
        report?.app = app
        report?.window = desktop
        report?.isFocused = { window.isFocused }
        report?.isActive = { window.isActive }
        report?.isMinimized = { window.extendedState and Frame.ICONIFIED != 0 }
        report?.isMaximized = { window.extendedState and Frame.MAXIMIZED_BOTH == Frame.MAXIMIZED_BOTH }
        report?.paintStats = { (window as? WaylandWindow)?.takePaintStats() }
        if (options.frameTimes) {
            val log = FrameLog()
            check(log.attach(window)) { "--frame-times: the window has no Skia layer to time" }
            report?.frameLog = log
            report?.event("frameLog", mapOf("renderer" to log.renderer))
        }
        options.windowResize?.let { (w, h) -> window.setSize(w, h) }
        this.close = close
        scheduleEngineSets()
    }

    /** `--play`'s playback instead of the app ([HarnessPlayback]). */
    override fun content(platform: PlezyPlatform, app: @Composable () -> Unit): @Composable () -> Unit {
        val url = options.play ?: return app
        return { HarnessPlayback(platform, url, matchDisplay = options.playMatch, onFrame = { report?.composeFrame(it) }) }
    }

    override suspend fun watchStartup() {
        report?.watchStartup()
    }

    override fun finish(status: String) {
        report?.finish(status)
    }

    /** `--exit-after`: closes the app [seconds] from now, and halts it 30 s later should its shutdown hang. */
    fun exitAfter(seconds: Double) {
        Thread({
            Thread.sleep((seconds * 1000).toLong())
            SwingUtilities.invokeLater { close?.invoke() }
        }, "exit-after").apply { isDaemon = true; start() }
        // Last resort if shutdown hangs (e.g. a stuck mpv teardown): the harness must always get a process exit.
        Thread({
            Thread.sleep(((seconds + 30) * 1000).toLong())
            report?.finish("timeout")
            Runtime.getRuntime().halt(3)
        }, "watchdog").apply { isDaemon = true; start() }
    }

    /** The `--engine-set` calls after 0 s, each on the engine playing at its time (skipped, and logged, when none is). */
    private fun scheduleEngineSets() {
        val later = options.engineSets.filter { it.atSeconds > 0.0 }.sortedBy { it.atSeconds }
        if (later.isEmpty()) return
        Thread({
            for (set in later) {
                val waitMs = (set.atSeconds * 1000).toLong() - (System.nanoTime() - startedAt) / 1_000_000
                if (waitMs > 0) Thread.sleep(waitMs)
                val current = engine
                if (current != null) call(current, set) else report?.event("engineSetSkipped", mapOf("name" to set.name))
            }
        }, "engine-set").apply { isDaemon = true; start() }
    }

    /** One `--engine-set` call through the [PlayerEngine] API, logged as a report event. */
    private fun call(engine: PlayerEngine, set: TestOptions.EngineSet) {
        report?.event("engineSet", mapOf("name" to set.name, "value" to set.value))
        when (set.name) {
            "speed" -> engine.setSpeed(set.value.toDouble())
            "sub-delay" -> engine.setSubtitleDelay(set.value.toDouble())
            "audio-delay" -> engine.setAudioDelay(set.value.toDouble())
            "volume" -> engine.setVolume(set.value.toDouble())
            "mute" -> engine.setMuted(set.value == "yes")
            "hdr" -> (engine as MpvPlayerEngine).setHdrOutput(set.value == "yes")
            "hdr-tone-mapping" -> (engine as MpvPlayerEngine).setHdrToneMapping(player = set.value == "player")
        }
    }
}

/**
 * `--dev`: a development session instead of the product, as [launch] asks for it, on an in-memory database or one kept
 * in [dataDir] (`--data-dir`, `--dev-data`), its settings stored first.
 */
internal class DevSession(private val launch: DevLaunch, private val dataDir: Path?) : TestSession {
    override fun boot(version: String): AppBootstrap {
        val database = dataDir?.let { DatabaseFactory(it.toAbsolutePath().resolve("plezy.db")) } ?: DatabaseFactory.inMemory()
        val boot = AppBootstrap.local(database, Bootstrap.flavor, version, launch.httpClient(version))
        runBlocking { boot.graph.applyDevSettings(launch.settings) }
        return boot
    }

    override fun app(boot: AppBootstrap, platform: PlezyPlatform, failed: (String) -> Unit): AppSession =
        boot.graph.devAppSession(launch, platform, failed)

    /** `--dev-discord`'s; none without it, whatever the build's, so no test run shows on a real Discord unasked. */
    override val discordApplicationId: String? = launch.discord

    /** `--dev-crash-reports`' fake Sentry, or none. */
    override fun crashReports(boot: AppBootstrap): CrashReports =
        boot.crashReports(ReleaseChannel.DEVELOPMENT, launch.crashReports.orEmpty())

    /** `--dev-no-audio`'s: playback on no audio output, for a host without an audio device. */
    override val noAudio: Boolean = launch.noAudio
}
