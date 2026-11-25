package com.edde746.plezy.desktop

import androidx.compose.runtime.Composable
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.RootSession
import com.edde746.plezy.crash.CrashReports
import com.edde746.plezy.desktop.players.ExternalPlayersObserver
import com.edde746.plezy.mpv.DesktopWindow
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.mpv.MpvEngineOptions
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.ui.app.PlezyPlatform
import com.edde746.plezy.desktop.windows.XInputReader
import com.edde746.plezy.ui.probe.LayoutProbe
import java.nio.file.Path
import javax.swing.JFrame

/**
 * What a test launch asks of the app beyond the product: the harness launcher's (desktop/app/src/harness,
 * TestMain.kt), which parses the test-only options and runs the app through [runApp] with one of
 * these. The product's main passes none, so the release jar holds no test option, test report or dev session.
 */
internal interface TestLaunch {
    /**
     * A device of its own: its database in this directory and its secrets under a name derived from it
     * ([Bootstrap.product]), apart from the device's; with a [session], that session's (kept for its next launch).
     * Null: the device itself, or a session's in-memory database.
     */
    val dataDir: Path?

    /** An app on a core of its own instead of the product (a dev session); null for the product. */
    val session: TestSession?

    /** The content area's size in dp at startup instead of 1280×720, fitted to the work area as that is. */
    val windowSize: Pair<Int, Int>?

    /**
     * The window keeps its place across launches as the product's does (Windows: [com.edde746.plezy.desktop.windows.WindowsWindowPlacement]);
     * otherwise a test launch opens where [windowSize] puts it and leaves the stored place alone.
     */
    val windowPlacement: Boolean

    /** The product's start takes this many milliseconds longer, so the splash names its step. */
    val slowStartMillis: Long

    /** Collects where the named controls are and which has focus; null without a report. */
    val layoutProbe: LayoutProbe?

    /** Hears the external players' launches; null without a report. */
    val externalPlayers: ExternalPlayersObserver?

    /**
     * Game controllers that stand in for the system's (the harness's scripted ones): read as XInput's are, on any OS;
     * null for the system's own.
     */
    val gamepadStates: XInputReader? get() = null

    /** This process is the app of its data directory ([SingleInstance]): the launch starts its own work. */
    fun start()

    /** The start reached milestone [name] (its first time counts). */
    fun mark(name: String)

    /** An app action, with its [detail]: a media controls command, a display switch, full screen, the close. */
    fun event(name: String, detail: Map<String, Any?> = emptyMap())

    /** The run's [number]th playback starts on [engine]. */
    fun onEngine(engine: MpvPlayerEngine, number: Int)

    /**
     * [window] ([desktop]) shows the product's [root] or the session's [app]; [close] closes the app as the window's
     * close button does (on the UI thread).
     */
    fun onShow(window: JFrame, desktop: DesktopWindow, root: RootSession?, app: AppSession?, close: () -> Unit)

    /**
     * What the window shows on [platform]: the app's own [app] content, or the harness's instead (a playback of its
     * own). Composed on the UI thread.
     */
    fun content(platform: PlezyPlatform, app: @Composable () -> Unit): @Composable () -> Unit = app

    /** Runs in the window's composition from its content's first frame, on the UI thread. */
    suspend fun watchStartup()

    /** The app ends as [status]: `ok`, or `terminate-timeout` when mpv didn't terminate in time. */
    fun finish(status: String)
}

/** A test launch's app on a core of its own instead of the product's (the harness launcher's dev session). */
internal interface TestSession {
    /** The core, built on the main thread while the window opens; exits the process when the session can't start. */
    fun boot(version: String): AppBootstrap

    /** The app on [boot]'s graph, made on the UI thread with the window's [platform]; [failed] ends the launch. */
    fun app(boot: AppBootstrap, platform: PlezyPlatform, failed: (String) -> Unit): AppSession

    /**
     * The Discord application the session's Rich Presence shows as, instead of the build's; null: none, so the session
     * offers no Discord switch and connects to no Discord.
     */
    val discordApplicationId: String?

    /** Where [boot]'s crash reports go instead of the build's endpoint (a fake one, or none). */
    fun crashReports(boot: AppBootstrap): CrashReports

    /** Playback has no audio output (`ao=null`) and no audio recovery: a host without an audio device. */
    val noAudio: Boolean
}

/**
 * The mpv options a playback engine starts with: `--mpv` options last, so they win, over `ao=null` and no audio
 * recovery for a [TestSession.noAudio] session.
 */
internal fun engineOptions(cli: Cli, session: TestSession?, logFile: Path?, shaderCache: Path?, settings: DeviceSettings): MpvEngineOptions {
    val noAudio = session?.noAudio == true
    val extra = if (noAudio) mapOf("ao" to "null") + cli.mpvOptions else cli.mpvOptions
    return MpvEngineOptions(logFile = logFile, shaderCache = shaderCache, extraOptions = extra, settings = settings, audioRecovery = !noAudio)
}
