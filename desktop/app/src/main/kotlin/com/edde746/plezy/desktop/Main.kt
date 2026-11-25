package com.edde746.plezy.desktop

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.awt.ComposeWindow
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.window.WindowExceptionHandler
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.BundledText
import com.edde746.plezy.app.PlatformDownloads
import com.edde746.plezy.app.PlatformPlayback
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.app.Startup
import com.edde746.plezy.cast.JmdnsCastDiscovery
import com.edde746.plezy.crash.RssPolicy
import com.edde746.plezy.crash.RssWatchdog
import com.edde746.plezy.crash.StartupFailedException
import com.edde746.plezy.crash.crashReports
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.desktop.discord.DesktopDiscordPresence
import com.edde746.plezy.desktop.linux.LinuxDisplayAwake
import com.edde746.plezy.desktop.linux.LinuxJoysticks
import com.edde746.plezy.desktop.linux.LinuxMediaControls
import com.edde746.plezy.desktop.linux.LinuxPlaybackOutput
import com.edde746.plezy.desktop.players.DesktopPlayerApps
import com.edde746.plezy.desktop.players.DesktopSystem
import com.edde746.plezy.desktop.updates.desktopUpdates
import com.edde746.plezy.desktop.windows.WindowsDisplayAwake
import com.edde746.plezy.desktop.windows.WindowsDisplayChanges
import com.edde746.plezy.desktop.windows.XInputGamepads
import com.edde746.plezy.desktop.windows.WindowsDisplayMatching
import com.edde746.plezy.desktop.windows.WindowsMediaControls
import com.edde746.plezy.desktop.windows.WindowCloak
import com.edde746.plezy.desktop.windows.WindowsWindowPlacement
import com.edde746.plezy.image.ArtworkDevice
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.mpv.DesktopWindow
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.mpv.MpvVideoSurface
import com.edde746.plezy.mpv.WaylandSession
import com.edde746.plezy.mpv.WaylandWindow
import com.edde746.plezy.mpv.desktopAudioPlayer
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.BundledShaders
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.ShaderDirectories
import com.edde746.plezy.playback.ShaderRenderer
import com.edde746.plezy.playback.output.PlaybackOutputHost
import com.edde746.plezy.playback.players.ExternalPlayerLauncher
import com.edde746.plezy.presentation.player.BuildDiscordConfig
import com.edde746.plezy.presentation.player.DiscordPresenceHost
import com.edde746.plezy.presentation.player.MediaControlsHost
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.HdrToneMapping
import com.edde746.plezy.strings.T
import com.edde746.plezy.supporter.SupporterPlatform
import com.edde746.plezy.ui.app.SaveResult
import com.edde746.plezy.ui.app.StartingScreen
import com.edde746.plezy.ui.app.StartupFailureScreen
import com.edde746.plezy.ui.app.PlezyApp
import com.edde746.plezy.ui.app.PlezyPlatform
import com.edde746.plezy.ui.app.PlezyRoot
import com.edde746.plezy.ui.app.framePalette
import com.edde746.plezy.ui.app.shownAppearance
import com.edde746.plezy.ui.crash.SentryReports
import com.edde746.plezy.ui.image.ImageMemory
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import io.sentry.Sentry
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import java.awt.Color
import java.awt.Dimension
import java.awt.Frame
import java.awt.GraphicsEnvironment
import java.awt.Toolkit
import java.awt.datatransfer.StringSelection
import java.awt.event.WindowAdapter
import java.awt.event.WindowEvent
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.CompletableFuture
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.atomic.AtomicBoolean
import javax.imageio.ImageIO
import javax.swing.JFrame
import javax.swing.SwingUtilities
import javax.swing.Timer
import javax.swing.WindowConstants
import kotlin.coroutines.CoroutineContext
import kotlin.io.path.invariantSeparatorsPathString
import kotlin.io.path.isDirectory
import kotlin.io.path.isRegularFile
import kotlin.io.path.readText
import kotlin.math.roundToInt
import kotlin.system.exitProcess
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import org.jetbrains.skiko.SystemTheme
import org.jetbrains.skiko.currentSystemTheme
import sun.misc.Signal

private val isWindows = System.getProperty("os.name").startsWith("Windows")
private val isLinux = System.getProperty("os.name").startsWith("Linux")

/**
 * The smallest content area, in dp, the window takes (a test launch's window size included; less only on a smaller
 * screen's work area): every screen is laid out for it as for the default 1280x720.
 */
internal val MinimumWindowSize = 640 to 480

/**
 * The desktop app (Windows; Linux as a native Wayland client, or under X11 without video) in one window, with mpv's
 * video under the Compose layer behind the player route: the product ([PlezyRoot]). See [Cli] for its options.
 */
fun main(args: Array<String>) {
    // A Wayland session gets a native Wayland window, the only one a video plane can go under: before anything
    // touches AWT (runApp's callers do the same).
    WaylandSession.useNativeToolkit()
    val cli = try {
        Cli.parse(args)
    } catch (e: Cli.Error) {
        System.err.println("plezy: ${e.message}\n\n${Cli.USAGE}")
        exitProcess(2)
    }
    runApp(cli, test = null)
}

/**
 * Runs the app with [cli]'s options: the product, or what [test] asks for instead (the harness launcher's, in
 * desktop/app/src/harness: a session of its own such as a dev session's app ([PlezyApp]), a device of its own, the
 * test report). Returns once the window and the core are on their way; the UI thread fills the window.
 */
internal fun runApp(cli: Cli, test: TestLaunch?) {
    val session = test?.session
    // One app per data directory (SingleInstance): a later start, such as the one the OS makes for a plezy:// link
    // while Plezy runs, hands its link to the running app and exits, before it touches the database or starts the test
    // launch. A test session without a data directory has a database of its own in memory: any number run side by side.
    val instance = (test?.dataDir?.toAbsolutePath() ?: DatabaseFactory.defaultDirectory().takeUnless { session != null })?.let { directory ->
        try {
            SingleInstance.claim(directory, cli.link) ?: exitProcess(0)
        } catch (e: IOException) {
            System.err.println("plezy: ${e.message}")
            exitProcess(1)
        }
    }
    // Windows: Compose draws over mpv's child window through Skiko's DirectComposition swapchain. Must be set before
    // any Compose/Skiko class initializes.
    if (isWindows) System.setProperty("compose.interop.blending", "true")
    // Where Compose draws nothing (the frames before its first, a screen fading in or out, a screen after the player),
    // the window under its swapchain shows on Windows. AWT paints Skiko's canvas window with its background colour
    // (black: Compose asks for a transparent one) only while background erasing is on; Skiko turns it off unless told
    // otherwise, which left the look and feel's light grey or the video host's last pixels there.
    if (isWindows) System.setProperty("skiko.rendering.noerasebackground", "false")
    // The window is made on the UI thread while this thread gets the system's settings, which its title and splash are
    // in; then it shows with the splash while this thread starts the shared core (the database) and builds DesktopApp
    // over it, whose root prepares the app meanwhile. The UI thread fills the window once it shows.
    val window = CompletableFuture<JFrame>()
    SwingUtilities.invokeLater {
        test?.mark("windowStart")
        createWindow(test, window::complete)
    }
    // An abort() in native code (libmpv's failed assertions) reported as HotSpot reports a native crash (NativeCrashes).
    // SIGABRT's handler becomes the C library's strlen: called with the signal's number as its string, it faults on
    // that address on the aborting thread, and HotSpot reports faults, never SIGABRT, so no handler code of ours runs
    // inside the abort.
    if (isWindows || isLinux) NativeAborts.install(windows = isWindows)
    // The product's portable copy opens plezy:// links from now on (the packages register them themselves).
    if (session == null) Thread(LinkRegistration::register, "link-registration").apply { isDaemon = true }.start()
    if (isLinux && !System.getProperty("java.vm.vendor").orEmpty().contains("JetBrains")) {
        System.err.println("plezy: warning: not running on JetBrains Runtime; without its Wayland toolkit there is no video, and window resizes by the window manager may be missed. Start Plezy with JetBrains Runtime 25, which the Flatpak bundles.")
    }
    // The system's languages, region and caption settings, before the window's title or the core reads them.
    Bootstrap.reportSystemInputs()
    test?.start()
    // The product's start begins before the window shows, so the splash can name its steps.
    val startup = if (session != null) null else Startup(test?.slowStartMillis ?: 0)
    SwingUtilities.invokeLater { showWindow(window.get(), startup, test) }
    test?.mark("bootstrap")
    val version = DesktopApp::class.java.`package`?.implementationVersion ?: "dev"
    startCore(cli, test, instance, startup, version, window::get)
}

/**
 * Builds the shared core, then [DesktopApp], which fills the window on the UI thread. A product start that fails shows
 * the startup failure screen in the window, whose Retry runs this again.
 */
private fun startCore(cli: Cli, test: TestLaunch?, instance: SingleInstance?, startup: Startup?, version: String, window: () -> JFrame) {
    val session = test?.session
    val boot = try {
        session?.boot(version) ?: Bootstrap.product(version, checkNotNull(startup), test?.dataDir)
    } catch (e: StartupFailedException) {
        System.err.println("plezy: start failed: ${e.record.headline}")
        val again = { Thread({ startCore(cli, test, instance, startup, version, window) }, "bootstrap").start() }
        // Saved data the start couldn't use is reset once the user confirms, and the start runs again as a first run.
        val reset: (suspend () -> Unit)? = if (session != null) null else ({
            Bootstrap.resetData(test?.dataDir)
            again()
        })
        SwingUtilities.invokeLater {
            window().setContent {
                // A test launch's report places the screen's controls, as the app's.
                CompositionLocalProvider(LocalLayoutProbe provides test?.layoutProbe) {
                    PlezyTheme { StartupFailureScreen(e.record, { again() }, reset) }
                }
            }
        }
        return
    } catch (e: Exception) {
        // Without the core there is no app: the window goes, so the process ends with the error.
        SwingUtilities.invokeLater { window().dispose() }
        throw e
    }
    test?.mark("bootstrapped")
    // Crash reports through Sentry's Java SDK while this device has them on: the product's to this build's endpoint, a
    // test session's to its own. They hold uncaught exceptions on any thread, and the exceptions the shared core's
    // coroutines survived. A crash in native code (libmpv) ends the JVM before any Java code runs: HotSpot's report of
    // it is sent on the next start ([NativeCrashes]), from the data directory's crash database (none for a test session
    // kept in memory).
    SentryReports.follow(session?.crashReports(boot) ?: boot.crashReports(Bootstrap.releaseChannel), boot.graph.scope) { configure ->
        Sentry.init { options -> configure(options) }
    }
    (test?.dataDir ?: DatabaseFactory.defaultDirectory().takeUnless { session != null })?.let { data ->
        val database = data.resolve(NativeCrashes.DATABASE)
        boot.graph.scope.launch(Dispatchers.IO) {
            NativeCrashes.collect(listOf(Path.of(System.getProperty("user.dir")), Path.of(System.getProperty("java.io.tmpdir"))), database)
            NativeCrashes.report(database, wait = 30.seconds)
        }
    }
    // Online or not, for the offline states and the downloads; the shared core hears it on the UI thread.
    val network = DesktopNetwork { online -> SwingUtilities.invokeLater { boot.onNetworkChanged(online, metered = false) } }
    network.start()

    val app = DesktopApp(cli, test, boot, network, startup, instance, window())
    SwingUtilities.invokeLater {
        // Closed while the core started ([StartupClose]): the process is ending.
        if (!window().isDisplayable) return@invokeLater
        test?.mark("edt")
        app.show()
    }
}

/**
 * Makes the window, handed to [created] as soon as it exists (DesktopApp, built off the UI thread meanwhile, only keeps
 * it), not shown yet ([showWindow]): in the system's light or dark theme until the app's is known
 * ([paintTheme]: what Swing paints where the window grows before Compose catches up, Skiko's clear colour on Linux, and
 * the system chrome), a 16:9 content area (or [test]'s window size) scaled down to fit the screen's work area (the
 * screen without its taskbar or panels: Windows clamps a larger frame to the whole screen, which puts the player's
 * controls under the taskbar), on Windows at the place the last start left it in ([WindowsWindowPlacement]). The frame
 * is sized once the peer exists and its insets are known (pack() would use Compose's intrinsic size). Physical pixels
 * under X11, where Compose applies the desktop scale itself; AWT scales on Windows and under Wayland. Resizing stops at
 * [MinimumWindowSize], or at the fitted size on a work area smaller than that. Until [DesktopApp] takes it and fills
 * it, closing it ends the process at once ([StartupClose]): the splash, the startup failure screen. Under Wayland it is
 * a [WaylandWindow], elsewhere a [ComposeWindow]; under X11 its class is the app's id ([DesktopWindow.useAppId]).
 */
@OptIn(ExperimentalComposeUiApi::class)
private fun createWindow(test: TestLaunch?, created: (JFrame) -> Unit) {
    val palette = framePalette(null, FormFactor.DESKTOP, currentSystemTheme == SystemTheme.DARK)
    DesktopWindow.useAppId()
    val window = if (WaylandSession.active) WaylandWindow() else ComposeWindow()
    // An exception in Compose's frame (its layout or drawing, input) goes where an uncaught one on the UI thread goes
    // (stderr, crash reports) and the window keeps drawing: thrown on, it would end the window's frame loop, leaving a
    // window that never paints again while the app runs on.
    val reportOnly = WindowExceptionHandler { e -> Thread.currentThread().let { it.uncaughtExceptionHandler.uncaughtException(it, e) } }
    when (window) {
        is WaylandWindow -> window.compose.exceptionHandler = reportOnly
        is ComposeWindow -> window.exceptionHandler = reportOnly
    }
    created(window)
    val scale = DesktopWindow.uiScale
    window.paintTheme(palette)
    // Packaged builds get their icon from nativeDistributions; this covers the title bar and taskbar of `run`.
    DesktopApp::class.java.getResource("/icons/plezy.png")?.let { window.iconImage = ImageIO.read(it) }
    window.defaultCloseOperation = WindowConstants.DO_NOTHING_ON_CLOSE
    window.addWindowListener(StartupClose(window, test))
    if (isLinux) closeOnSignals(window)
    window.addNotify()
    val insets = window.insets
    val frameWidth = insets.left + insets.right
    val frameHeight = insets.top + insets.bottom
    val (width, height) = test?.windowSize ?: (1280 to 720)
    val workArea = GraphicsEnvironment.getLocalGraphicsEnvironment().maximumWindowBounds
    val fit = minOf(1f, (workArea.width - frameWidth) / (width * scale), (workArea.height - frameHeight) / (height * scale))
    val contentWidth = (width * scale * fit).roundToInt()
    val contentHeight = (height * scale * fit).roundToInt()
    val (minWidth, minHeight) = MinimumWindowSize
    window.minimumSize = Dimension(
        minOf((minWidth * scale).roundToInt(), contentWidth) + frameWidth,
        minOf((minHeight * scale).roundToInt(), contentHeight) + frameHeight,
    )
    window.setSize(contentWidth + frameWidth, contentHeight + frameHeight)
    window.setLocationRelativeTo(null)
    // Windows: where the last start left it, over the size and place above (a test launch only when it asks).
    val maximized = isWindows && (test == null || test.windowPlacement) && WindowsWindowPlacement.restore((window as ComposeWindow).windowHandle)
    if (maximized) window.extendedState = window.extendedState or Frame.MAXIMIZED_BOTH
}

/**
 * Shows [window] ([createWindow]) titled and in front, with the splash ([StartingScreen], naming [startup]'s step; a
 * test session's has none; its first frame is [test]'s `firstFrame`).
 */
private fun showWindow(window: JFrame, startup: Startup?, test: TestLaunch?) {
    val palette = framePalette(null, FormFactor.DESKTOP, currentSystemTheme == SystemTheme.DARK)
    val scale = DesktopWindow.uiScale
    window.title = T.app.title
    // Windows: shown cloaked ([WindowCloak]: it draws, the desktop doesn't show it) and uncloaked on its first frame, so
    // it never shows blank or anywhere but its place; uncloaked after FIRST_FRAME_WAIT_MS whatever happens. Elsewhere
    // (no saved place to apply) shown at once.
    val hwnd = (window as? ComposeWindow)?.takeIf { isWindows }?.windowHandle
    val cloaked = hwnd != null && WindowCloak.set(hwnd, cloaked = true)
    var revealed = !cloaked
    fun reveal() {
        if (revealed) return
        revealed = true
        WindowCloak.set(hwnd!!, cloaked = false)
        test?.mark("windowVisible")
    }
    window.isVisible = true
    window.toFront()
    if (cloaked) Timer(FIRST_FRAME_WAIT_MS) { reveal() }.apply { isRepeats = false }.start() else test?.mark("windowVisible")
    window.setContent {
        val base = LocalDensity.current
        CompositionLocalProvider(LocalDensity provides Density(base.density * scale, base.fontScale)) {
            PlezyTheme(palette) { StartingScreen(startup?.state?.collectAsState()?.value?.status) }
        }
        // Marked at the next frame's start, as the report's other milestones are.
        LaunchedEffect(Unit) {
            withFrameNanos { }
            test?.mark("firstFrame")
            reveal()
        }
    }
}

/** How long a cloaked window waits for its first frame before it shows anyway ([showWindow]). */
private const val FIRST_FRAME_WAIT_MS = 1000

/** Compose's content of the app's window, whichever of the two it is ([createWindow]). */
private fun JFrame.setContent(content: @Composable () -> Unit): Unit = when (this) {
    is WaylandWindow -> compose.setContent(content)
    is ComposeWindow -> setContent { content() }
    else -> error("not the app's window: ${javaClass.name}")
}

/**
 * Closing [window] before [DesktopApp] has it (which takes this listener away): while the core starts under the splash
 * or after it failed to (the startup failure screen) there is no playback to end and nothing to save, so the window
 * goes and the process ends with status 0, the start left wherever it got (the database's own journal keeps it whole).
 * The window goes first, on the UI thread (under Wayland the toolkit's shutdown would dispose it off it); the exit runs
 * off it, as [DesktopApp.close]'s does.
 */
private class StartupClose(private val window: JFrame, private val test: TestLaunch?) : WindowAdapter() {
    override fun windowClosing(e: WindowEvent) {
        test?.event("close", mapOf("starting" to true))
        test?.finish("ok")
        window.dispose()
        Thread({ exitProcess(0) }, "shutdown").start()
    }
}

/**
 * On Linux, the signals that ask the process to end (SIGTERM: a session's logout, `kill`; SIGINT: Ctrl+C in a terminal;
 * SIGHUP: the terminal gone) close [window] as its close button does, so the exit is the app's own ([StartupClose],
 * [DesktopApp.close]): the playback's last reports go out and the window goes on the UI thread first. The runtime's own
 * handling of them runs the shutdown hooks with the window still up, and WLToolkit's hook takes it down off the UI
 * thread, which Compose's Swing panel refuses with an uncaught exception. A signal the process was started ignoring
 * (`nohup`) stays ignored.
 */
private fun closeOnSignals(window: JFrame) {
    for (name in listOf("TERM", "INT", "HUP")) {
        Signal.handle(Signal(name)) {
            SwingUtilities.invokeLater { window.dispatchEvent(WindowEvent(window, WindowEvent.WINDOW_CLOSING)) }
        }
    }
}

/**
 * Where the product's root prepares the app ([RootSession]'s preparation): on the background threads, so it goes on
 * while the UI thread opens the window, each step holding the UI thread's later work until it ends. What the app
 * starts on the UI thread as it's built (the Swing dispatcher's tasks) so runs once it's whole, as when the UI thread
 * builds it. A step must never wait for the UI thread.
 */
private object HeldUiThread : CoroutineDispatcher() {
    override fun dispatch(context: CoroutineContext, block: Runnable) {
        Dispatchers.Default.dispatch(context) {
            val done = CountDownLatch(1)
            SwingUtilities.invokeLater { done.await() }
            try {
                block.run()
            } finally {
                done.countDown()
            }
        }
    }
}

/**
 * The window in [palette]: its own paint (where Compose draws nothing: before its first frame, as the window grows, a
 * screen fading in or out) and the system chrome of every window the app opens, dark or light as the palette is, as
 * the earlier releases themed their window frame. On the AWT event thread.
 */
private fun JFrame.paintTheme(palette: Palette) {
    background = Color(palette.bg.toInt(), true)
    contentPane.background = background
    repaint()
    DesktopWindow.useChrome(palette.isDark)
}

/**
 * The window and everything in it. Borderless fullscreen goes through [DesktopWindow] (Win32 on Windows),
 * never AWT's exclusive fullscreen. On Windows the playbacks show in the System Media Transport Controls
 * ([WindowsMediaControls]) and switch the display's mode and HDR state ([WindowsDisplayMatching]); on Linux they show
 * through MPRIS ([LinuxMediaControls]). On both the Passthrough setting reaches each playback's mpv
 * ([WindowsDisplayMatching], [LinuxPlaybackOutput]), and with the Discord setting on, the playbacks show on Discord
 * ([DesktopDiscordPresence]). A playing video keeps the display awake ([WindowsDisplayAwake], [LinuxDisplayAwake])
 * while the window isn't minimized. The app hands the `plezy://` link it started with and, on Windows, the ones later
 * starts hand it ([SingleInstance]) to the product's root, bringing its window forward. Closing hides the window, then
 * releases the playback (under Wayland before the window goes: the video's plane hangs on it) and puts the display
 * back, then exits ([close]).
 */
private class DesktopApp(
    private val cli: Cli,
    private val test: TestLaunch?,
    private val boot: AppBootstrap,
    private val network: DesktopNetwork,
    /** The product's start, which its root finishes; null for a test session. */
    private val startup: Startup?,
    private val instance: SingleInstance?,
    /** The window [createWindow] made. */
    private val window: JFrame,
) {
    private val desktop = DesktopWindow(window)
    private val closing = AtomicBoolean(false)
    /** The engines whose mpv hasn't terminated yet: the playing one, and earlier ones still tearing down. */
    private val engines = CopyOnWriteArrayList<MpvPlayerEngine>()
    /** How many playbacks this run has had, which numbers their mpv logs; written on the main thread. */
    @Volatile private var playbacks = 0
    private var app: AppSession? = null

    private val mediaControls: DesktopMediaControls? = when {
        isWindows -> WindowsMediaControls({ (window as ComposeWindow).windowHandle }) { command -> test?.event("mediaCommand", mapOf("command" to command.toString())) }
        isLinux -> LinuxMediaControls(raise = { window.toFront(); window.requestFocus() }) { command ->
            test?.event("mediaCommand", mapOf("command" to command.toString()))
        }
        else -> null
    }

    /**
     * The game controllers ([DesktopGamepad]): XInput's on Windows, the joystick devices on Linux, a test launch's
     * stand-ins instead where it has them. Read from [show] on, while the window has focus.
     */
    private val gamepad: DesktopGamepad? = test?.gamepadStates?.let { states -> DesktopGamepad(window) { XInputGamepads(it, states) } } ?: when {
        isWindows -> DesktopGamepad(window) { XInputGamepads(it) }
        isLinux -> DesktopGamepad(window) { LinuxJoysticks(it) }
        else -> null
    }

    /**
     * Discord's Rich Presence as this build's Discord application ([BuildDiscordConfig]), or a dev session's
     * ([TestSession.discordApplicationId]); none without one: Settings offers no Discord switch and nothing connects.
     */
    private val discord = test?.session.let { if (it != null) it.discordApplicationId else BuildDiscordConfig.config.applicationId }
        ?.let { DesktopDiscordPresence.system(isWindows, it) }

    /**
     * The device settings this desktop offers: hardware decoding everywhere; HDR where the display under the window
     * can switch it (Windows) or the compositor can show an HDR video plane (Linux under Wayland); frame-rate matching
     * on Windows; passthrough on Windows and Linux whatever the output, which says nothing there of the formats it
     * takes undecoded. Crash reporting isn't integrated. Detected when Settings first shows.
     */
    private val deviceFeatures by lazy {
        displayMatching?.features()
            ?: DeviceFeatures(hardwareDecoding = true, hdr = isLinux && WaylandSession.compositorDescribesHdr, matchFrameRate = false, audioPassthrough = isLinux)
    }

    /**
     * Where mpv keeps the GPU shaders it compiled (`gpu-shader-cache-dir`), in the data directory's cache: a user shader
     * that took seconds to compile (ArtCNN's on Direct3D 11) loads at once from the next playback on. Compiled shaders
     * hold nothing of the user's, so a test session whose database is in memory shares the device's.
     */
    private val shaderCache: Path = (test?.dataDir ?: DatabaseFactory.defaultDirectory()).resolve("cache").resolve("mpv-shaders")

    private val platform = object : PlezyPlatform {
        override val formFactor = FormFactor.DESKTOP
        override val appleTv = false

        override val device = desktopDeviceIdentity()

        /** The main screen's display mode in pixels, for the artwork budgets. */
        override val artworkDevice: ArtworkDevice
            get() {
                if (GraphicsEnvironment.isHeadless()) return ArtworkDevice()
                val mode = GraphicsEnvironment.getLocalGraphicsEnvironment().defaultScreenDevice.displayMode
                return ArtworkDevice(displayWidth = mode.width, displayHeight = mode.height)
            }

        override val artworkCacheDirectory = desktopArtworkCacheDirectory()

        override val playerConfig = PlayerConfig.defaults(InputProfile.DESKTOP, doubleClickIntervalMillis())

        /** A game controller's press or stick ([DesktopGamepad.nonPointerInput]). */
        override val nonPointerInput: Flow<Unit> = gamepad?.nonPointerInput ?: emptyFlow()

        /** False while the window is minimized (the listener in [show]). */
        override var windowVisible by mutableStateOf(true)

        override fun createPlayback(settings: DeviceSettings): PlatformPlayback {
            engines.removeIf { it.awaitReleased(Duration.ZERO) }
            playbacks++
            // Every playback gets its own engine; a later one logs next to the first (each starts its log file anew).
            val log = cli.mpvLog?.let { if (playbacks == 1) it else it.resolveSibling("${it.fileName.toString().substringBeforeLast('.')}-$playbacks.log") }
            val mpv = MpvPlayerEngine(engineOptions(cli, test?.session, log, shaderCache, settings))
            // Linux's video plane: who tone-maps HDR shown as HDR (the HDR tone mapping setting).
            if (isLinux) mpv.setHdrToneMapping(settings.hdrToneMapping == HdrToneMapping.PLAYER)
            engines += mpv
            test?.onEngine(mpv, playbacks)
            return object : PlatformPlayback {
                override val engine: PlayerEngine = mpv
                override val hardwareDecoder = mpv.hardwareDecoder
                override val runsAmbientLighting = true
                override val mediaControls: MediaControlsHost? = this@DesktopApp.mediaControls
                override val output: PlaybackOutputHost? = displayMatching?.host(mpv) ?: if (isLinux) LinuxPlaybackOutput(mpv) else null

                override fun keepDisplayAwake(awake: Boolean) {
                    displayAwake?.keepAwake(awake)
                }
            }
        }

        /** The music player; the launch's mpv options (`--mpv-opt`, a test run's `mute=yes`) apply to it too. */
        override fun createMusicAudioPlayer(): AudioPlayer =
            desktopAudioPlayer(engineOptions(cli, test?.session, null, null, DeviceSettings.DEFAULT).extraOptions)

        @Composable
        override fun VideoSurface(engine: PlayerEngine, modifier: Modifier) = MpvVideoSurface(engine as MpvPlayerEngine, window, modifier)

        override fun deviceFeatures(): DeviceFeatures = this@DesktopApp.deviceFeatures

        override val discordPresence: DiscordPresenceHost? = this@DesktopApp.discord

        /** The music session shows in the same SMTC or MPRIS player as a video: one playback at a time. */
        override val musicControls: MediaControlsHost? = this@DesktopApp.mediaControls

        /** The build's Supporter mode and donation link (Bootstrap.supporter); no store and no app icons here. */
        override val supporter: SupporterPlatform = Bootstrap.supporter

        /** DNS-SD for casting over JmDNS, one responder per network interface. */
        override val castDiscovery = JmdnsCastDiscovery()

        /**
         * External players ([DesktopPlayerApps]): VLC, mpv and this system's other known players, found and started as
         * programs or through their URL handlers. Inside the Flatpak only the system default reaches outside its sandbox.
         */
        override val externalPlayers: ExternalPlayerLauncher = DesktopPlayerApps(DesktopSystem.Real(), observer = test?.externalPlayers)

        override val isFullscreen: Boolean get() = desktop.isFullscreen

        override fun setFullscreen(fullscreen: Boolean) {
            val before = desktop.frameRect()
            val changes = fullscreen != desktop.isFullscreen
            if (changes) placement?.fullscreenChanging(entering = fullscreen)
            desktop.setFullscreen(fullscreen)
            if (changes) placement?.fullscreenChanged()
            test?.event(
                "fullscreen",
                mapOf("fullscreen" to desktop.isFullscreen, "frameBefore" to before, "frameAfter" to desktop.frameRect(), "monitor" to desktop.monitorRect()),
            )
        }

        /** Wherever AWT can keep the window above the others ([java.awt.Window.isAlwaysOnTopSupported]). */
        override val keepsOnTop: Boolean get() = window.isAlwaysOnTopSupported

        override fun setAlwaysOnTop(onTop: Boolean) {
            window.isAlwaysOnTop = onTop
        }

        /** The system browser ([browse]); false where it doesn't take [url], and the app offers it to a phone instead. */
        override fun openUrl(url: String): Boolean = browse(url)

        // AWT has no sensitive flag: a secret is copied as any other text (AppPlatform.setClipboardText).
        override fun setClipboardText(text: String, sensitive: Boolean) =
            Toolkit.getDefaultToolkit().systemClipboard.setContents(StringSelection(text), null)

        override val downloads: PlatformDownloads = DesktopPlatformDownloads(window)

        override val hasFileDialogs = true

        /**
         * The bundled shaders in the app's resources folder's shaders/ (`compose.application.resources.dir`), the
         * imported ones in custom_shaders/ beside the database (where the earlier releases kept them), ambient
         * lighting's in the data directory's cache; a test session without a data directory, whose database is in
         * memory, uses a temporary folder. Windows renders through libplacebo (`gpu-next`), Linux through mpv's OpenGL
         * renderer (the render API), whose failing compute shaders abort libmpv.
         */
        override val shaderFiles = System.getProperty("compose.application.resources.dir")?.let { resources ->
            val data = test?.dataDir ?: DatabaseFactory.defaultDirectory().takeUnless { test?.session != null }
                ?: Files.createTempDirectory("plezy-shaders")
            val renderer = if (isWindows) ShaderRenderer.LIBPLACEBO else ShaderRenderer.OPENGL
            ShaderDirectories(
                renderer,
                BundledShaders.Directory(Path.of(resources, "shaders").toString()),
                data.resolve("cache").resolve("shaders").toString(),
                data.resolve("custom_shaders").toString(),
            )
        }

        override fun saveFile(fileName: String, text: String, done: (SaveResult) -> Unit) = saveTextFile(window, fileName, text, done)

        override fun openFile(opened: (name: String, text: String) -> Unit, failed: () -> Unit) = openTextFile(window, opened, failed)

        override fun openImage(opened: (name: String, bytes: ByteArray) -> Unit, failed: () -> Unit) = openImageFile(window, opened, failed)

        /**
         * The files under [folder] in the app's resources folder (`compose.application.resources.dir`, which the
         * packaged app, Gradle's run task and the harness launcher's argfile set), at any depth.
         */
        override fun bundledTexts(folder: String): List<BundledText> {
            val root = System.getProperty("compose.application.resources.dir")?.let { Path.of(it, folder) }
            if (root == null || !root.isDirectory()) return emptyList()
            return Files.walk(root).use { paths ->
                paths.filter { it.isRegularFile() }.map { BundledText(root.relativize(it).invariantSeparatorsPathString, it.readText()) }.toList()
            }.sortedBy { it.path }
        }

        override fun exit() = close(0)

        /** The product's updates ([desktopUpdates]); a test launch has none. */
        override val updates = if (test == null) desktopUpdates(boot.graph.http, Bootstrap.build) { close(0) } else null
    }

    private val displayMatching = if (isWindows) WindowsDisplayMatching({ (window as ComposeWindow).windowHandle }) { name, detail -> test?.event(name, detail) } else null
    private val displayAwake: DesktopDisplayAwake? = when {
        isWindows -> WindowsDisplayAwake()
        isLinux -> LinuxDisplayAwake()
        else -> null
    }

    /** Windows: a wake from sleep reloads the playing engine's audio output ([MpvPlayerEngine.onSystemResume]). */
    @Suppress("unused") // Kept for its listener thread.
    private val powerEvents = if (isWindows) WindowsDisplayChanges(onResume = { engines.forEach(MpvPlayerEngine::onSystemResume) }) else null

    /** Windows: the window's place, saved as it changes (a test launch's only when it asks). */
    private val placement = if (isWindows && (test == null || test.windowPlacement)) {
        WindowsWindowPlacement(window, { (window as ComposeWindow).windowHandle }, { desktop.isFullscreen })
    } else {
        null
    }

    /** The image caches go before the process's memory grows past 1.5 GiB (1 GiB minimized). */
    private val memoryWatchdog = RssWatchdog(RssPolicy.DESKTOP, DesktopMemory::residentBytes, ImageMemory::bytes, ImageMemory::evict)

    /**
     * The product's root, whose start prepares the app from here on, while the window still opens on the UI thread
     * ([HeldUiThread]); null for a test session. Built last: the app it prepares reads the platform's fields off the UI
     * thread from then on (a server's first connect reads the display matching through [deviceFeatures]).
     */
    private val root = if (test?.session == null) RootSession(boot.graph, platform, checkNotNull(startup), HeldUiThread) else null

    fun show() {
        test?.mark("appCreated")
        val session = test?.session
        // The appearance the app paints, which the window's own paint and chrome follow.
        val appearance: @Composable () -> Appearance?
        val product: @Composable () -> Unit = if (session != null) {
            // A step of the session's launch that fails ends the launch, as a refused option does (exit 2).
            val app = session.app(boot, platform) { reason ->
                System.err.println("plezy: the development launch failed: $reason")
                close(2)
            }
            this.app = app
            appearance = { app.appearance.collectAsState().value }
            ({ PlezyApp(app, platform) })
        } else {
            val root = checkNotNull(this.root)
            appearance = { shownAppearance(root) }
            ({ PlezyRoot(root, platform) })
        }
        val content = test?.content(platform, product) ?: product
        test?.onShow(window, desktop, root, app) { close(0) }

        val scale = DesktopWindow.uiScale
        // Closing is the app's from now on, no longer the start's.
        window.windowListeners.filterIsInstance<StartupClose>().forEach(window::removeWindowListener)
        window.addWindowListener(object : WindowAdapter() {
            override fun windowClosing(e: WindowEvent) = close(0)

            // The desktop's foreground: the window came back.
            override fun windowActivated(e: WindowEvent) = boot.onForeground()

            // Minimized, the app is in the background and the player lets the display sleep
            // (PlezyPlatform.windowVisible).
            override fun windowIconified(e: WindowEvent) {
                platform.windowVisible = false
                boot.onBackground()
                memoryWatchdog.onBackground()
            }

            override fun windowDeiconified(e: WindowEvent) {
                platform.windowVisible = true
                boot.onForeground()
            }
        })
        // What the window went through before the listener: it opened while the core started.
        platform.windowVisible = window.extendedState and Frame.ICONIFIED == 0
        if (platform.windowVisible) boot.onForeground()
        placement?.track()
        boot.graph.scope.launch { memoryWatchdog.run() }
        window.setContent {
            if (test != null) LaunchedEffect(test) { test.watchStartup() }
            val palette = framePalette(appearance(), platform.formFactor, isSystemInDarkTheme())
            LaunchedEffect(palette) { window.paintTheme(palette) }
            val base = LocalDensity.current
            CompositionLocalProvider(
                LocalDensity provides Density(base.density * scale, base.fontScale),
                LocalLayoutProbe provides test?.layoutProbe,
            ) {
                content()
            }
        }
        test?.mark("contentSet")
        gamepad?.start()
        cli.link?.let(::openLink)
        instance?.receive { link ->
            SwingUtilities.invokeLater {
                raise()
                link?.let(::openLink)
            }
        }
    }

    /** Hands a link the OS opened Plezy with ([Cli.link], or a later start's) to the product's root, or a test session's app. */
    private fun openLink(url: String) {
        root?.openUrl(url) ?: app?.links?.open(url)
    }

    /** The window in front, restored if minimized: a later start (a link opened, the app started again) comes here. */
    private fun raise() {
        if (window.extendedState and Frame.ICONIFIED != 0) window.extendedState = window.extendedState and Frame.ICONIFIED.inv()
        window.toFront()
        window.requestFocus()
    }

    /**
     * Exits with [code] as the earlier releases did, the window gone first so the exit reads as instant: hidden at once
     * (its place saved before), or under Wayland, where hiding destroys the surface a playback's video plane hangs on,
     * taken down once no plane is left. Then the playback ends and its last reports go out to the server, and the
     * trackers hear the stop ([RootSession.shutdown], [AppSession.shutdownForExit]); the engine terminates on its own
     * thread (the display restore is queued), mpv and the display are waited for, and the rest closes. However far that
     * gets, the process ends [EXIT_DEADLINE] after the close: a step that hangs (the network, the database) never keeps
     * it alive.
     */
    fun close(code: Int) {
        if (!closing.compareAndSet(false, true)) return
        test?.event("close")
        Thread({
            Thread.sleep(EXIT_DEADLINE.inWholeMilliseconds)
            System.err.println("plezy: the shutdown took longer than $EXIT_DEADLINE; exiting")
            test?.finish("exit-deadline")
            Runtime.getRuntime().halt(code)
        }, "shutdown-deadline").apply { isDaemon = true; start() }
        val plane = WaylandSession.active && engines.any { !it.awaitReleased(Duration.ZERO) }
        onUiThread {
            when {
                WaylandSession.active -> if (!plane) window.dispose()
                else -> {
                    placement?.saveOnClose()
                    window.isVisible = false
                }
            }
        }
        // A start from now on waits for this process to end and is the next app.
        instance?.stop()
        gamepad?.close()
        Thread({
            runBlocking {
                withTimeoutOrNull(REPORTS_BUDGET) {
                    root?.shutdown()
                    app?.shutdownForExit()
                }
            }
            app?.close()
            val start = System.nanoTime()
            val released = engines.all { it.awaitReleased(TERMINATE_BUDGET) }
            if (!released) System.err.println("plezy: mpv did not terminate within $TERMINATE_BUDGET")
            if (plane) SwingUtilities.invokeAndWait(window::dispose)
            displayMatching?.close()
            mediaControls?.close()
            discord?.close()
            displayAwake?.close()
            test?.event("released", mapOf("terminated" to released, "engines" to playbacks, "ms" to (System.nanoTime() - start) / 1_000_000))
            test?.finish(if (released) "ok" else "terminate-timeout")
            // Gone before the exit (a plane's window already is): under Wayland the toolkit's shutdown would dispose it
            // off the UI thread, which Compose's Swing panel refuses.
            if (!plane) SwingUtilities.invokeAndWait(window::dispose)
            network.close()
            boot.close()
            instance?.close()
            exitProcess(code)
        }, "shutdown").start()
    }

    /** [block] on the UI thread: at once from there, else queued. */
    private fun onUiThread(block: () -> Unit) {
        if (SwingUtilities.isEventDispatchThread()) block() else SwingUtilities.invokeLater(block)
    }

    companion object {
        /** How long the exit's teardown may take before the process ends regardless ([close]). */
        private val EXIT_DEADLINE = 15.seconds

        /** The exit's share of [EXIT_DEADLINE] for the playback's last reports, then for mpv's termination. */
        private val REPORTS_BUDGET = 6.seconds
        private val TERMINATE_BUDGET = 6.seconds

        /** The OS double-click interval (Windows `GetDoubleClickTime`, the desktop's setting on Linux). */
        private fun doubleClickIntervalMillis(): Long =
            (Toolkit.getDefaultToolkit().getDesktopProperty("awt.multiClickInterval") as? Int)?.toLong() ?: 500L
    }
}
