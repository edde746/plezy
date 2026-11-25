package com.edde746.plezy.app

import com.edde746.plezy.crash.StartupFailureRecord
import com.edde746.plezy.crash.StartupMark
import com.edde746.plezy.crash.StartupMarks
import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.crash.osDescription
import com.edde746.plezy.data.recovery.DatabaseRecovery
import com.edde746.plezy.downloads.discardDownloaderTempFiles
import com.edde746.plezy.downloads.openLocalDataWithDownloadRecovery
import com.edde746.plezy.importer.EarlierReleaseImport
import com.edde746.plezy.importer.EarlierReleaseOutcome
import com.edde746.plezy.log.Log
import com.edde746.plezy.music.MusicSessionStore
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.profiles.BootRoute
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.SettingsMigrations
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.ContinuationInterceptor
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** What the app shows at its top level ([RootSession.screen]). */
sealed interface RootScreen {
    /** The splash: the database is opening ([RootSession.startup] says how far). */
    data object Starting : RootScreen

    /**
     * The start failed: the database couldn't open or migrate, the data Plezy's earlier releases left on this device
     * couldn't be imported, or the stored settings couldn't be read or the app built over them. The startup failure
     * screen shows [record] (already kept for the crash reporter and the Logs screen) and its Retry
     * ([RootSession.retry]) starts again. After a failed import the app doesn't start until an import succeeds: nothing
     * it would store can collide with the data still to come.
     */
    data class Failed(val record: StartupFailureRecord) : RootScreen

    /**
     * The running app, entered at [entry]: the sign-in when no account is stored, the profile picker when no profile
     * is active or the user asked to pick one on every start, else the main screen. [recoveryRequired]: this device's
     * accounts were lost (Apple TV purged the database and no recovery copy survived) though the app had been used;
     * the sign-in says so instead of greeting a first run.
     */
    data class Main(val app: AppSession, val entry: BootRoute = BootRoute.MAIN, val recoveryRequired: Boolean = false) : RootScreen
}

/**
 * The product's top level ([screen]): the splash while the database opens, then the app.
 *
 * Built once per process from the product bootstrap's graph ([AppBootstrap.product]). [close] when the process's window
 * or activity goes for good.
 *
 * Android's database opens here, at its first statement: when the device is full it opens after the background
 * downloader's partial files are discarded ([openLocalDataWithDownloadRecovery]; the other platforms' opens in
 * [AppBootstrap.product]). On an install's first start, the data of Plezy's earlier releases ([AppGraph.earlierRelease])
 * is imported before the app shows, the splash naming the migration ([EarlierReleaseImport]); then, at every start, the
 * stored settings are upgraded ([SettingsMigrations.applyStartupMigrations]). A database that can't open shows
 * [RootScreen.Failed]; so does a failed import, until a [retry] or a later start imports, as the earlier releases' own
 * start stopped at their failure screen when their database couldn't be read: there is no way into the app without
 * that data. A failed upgrade goes to the graph's failure boundary; the app starts without it and the next start tries
 * again. Any other failure until the app is built (a stored setting that can't be read) shows [RootScreen.Failed] too.
 *
 * @param startup the start the platform began before the bootstrap: the splash draws its status line, and it is done
 *   once the database is open.
 * @param preparation where the start runs until the app ([AppSession]) is built, the build included; the rest, and
 *   [openUrl], run on the main thread. A context off the main thread holds the main thread's later work while each of
 *   its steps runs, so what the app starts there runs once the app is whole, as when it's built there. A coroutine the
 *   app starts undispatched takes its first step there (Watch Together's profile collector: no profile is active yet).
 */
class RootSession(
    val graph: AppGraph,
    private val platform: AppPlatform,
    val startup: Startup,
    private val preparation: CoroutineContext,
) {
    /** A root whose whole start runs on the main thread. */
    constructor(graph: AppGraph, platform: AppPlatform, startup: Startup) : this(graph, platform, startup, EmptyCoroutineContext)

    private val scope = graph.scope.childScope()
    /** The main thread, where the start goes on once the app is built. */
    private val main = graph.scope.coroutineContext[ContinuationInterceptor] ?: EmptyCoroutineContext
    private val mutableScreen = MutableStateFlow<RootScreen>(RootScreen.Starting)
    private var closed = false

    /** The links handed over before [app] exists ([openUrl]). */
    private val launchLinks = mutableListOf<String>()

    /** What the app shows. */
    val screen: StateFlow<RootScreen> = mutableScreen.asStateFlow()

    /** The running app; null before the database is open, while [RootScreen.Failed] shows, and after [close]. */
    var app: AppSession? = null
        private set

    /**
     * The theme and form factor the app will start in, read from the stored settings (theme, Force TV mode, the cached
     * Supporter entitlement) once the database is open, for the splash and the startup failure screen; null before then
     * and when the settings can't be read (those frames then paint the device's default).
     */
    val startupAppearance: StateFlow<Appearance?> get() = mutableStartupAppearance

    private val mutableStartupAppearance = MutableStateFlow<Appearance?>(null)

    init {
        start()
    }

    /**
     * The startup failure screen's Retry: the start runs again from opening the database, so a failed import imports
     * again and the app starts only once it succeeds.
     */
    fun retry() {
        if (closed || mutableScreen.value !is RootScreen.Failed) return
        mutableScreen.value = RootScreen.Starting
        start()
    }

    private fun start() {
        scope.launch(preparation) {
            val (session, lost) = prepare(EarlierReleaseImport(graph.data, graph.secrets, graph.filesDirectory)) ?: return@launch
            withContext(main) {
                // The links handed over while the app was built, oldest first, ahead of its profiles' start looking
                // for a profile one names.
                launchLinks.forEach(session.links::open)
                launchLinks.clear()
                app = session
                var recoveryRequired = false
                val entry = try {
                    session.profiles.bootRoute().also { entry ->
                        // Until an account is signed in again: after that the loss is behind the user.
                        recoveryRequired = lost && entry == BootRoute.SIGN_IN && session.servers.connections.list().isEmpty()
                    }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    // Never left on the splash: a failure loading the connections or profiles goes to the sign-in.
                    Log.e(TAG, e) { "loading the connections or profiles failed; going to the sign-in" }
                    BootRoute.SIGN_IN
                }
                if (entry == BootRoute.MAIN) {
                    // The active profile's bind (its connects and health probes) goes on under the app, whose screens
                    // show their places until the servers answer, and a PIN it asks for shows over the app. The offline
                    // start is decided once the bind settles. Without a network the splash waits for the bind, at most
                    // [NO_NETWORK_STARTUP_BIND], so a device that can't reach a server goes straight to the offline
                    // shell.
                    val hasNetwork = session.servers.connectivity.check().hasNetwork
                    val settle = async { awaitStartupBindSettle(hasNetwork) { session.profiles.awaitBindingSettle() } }
                    if (!hasNetwork) settle.join()
                    val decideOffline = suspend {
                        if (shouldStartOffline(settle.await(), session.servers.store.state.value.hasConnectedServers)) {
                            Log.w(TAG) { "no server online after the startup bind; starting offline" }
                            session.startOffline()
                        }
                    }
                    if (settle.isCompleted) decideOffline() else scope.launch { decideOffline() }
                }
                session.onboarding.enter(entry, recoveryRequired)
                session.primed = true
                mutableScreen.value = RootScreen.Main(session, entry, recoveryRequired)
                StartupMarks.mark(StartupMark.MAIN_SCREEN)
            }
        }
    }

    /** The app [prepare] built, and whether this device's data was lost (accounts gone though the app had been used). */
    private data class Prepared(val app: AppSession, val lost: Boolean)

    /**
     * The start until the app exists: the database opened, the earlier releases' data imported, the settings upgraded,
     * the stored language applied, then the app built. Null when the start failed ([RootScreen.Failed] shows).
     */
    private suspend fun prepare(earlierRelease: EarlierReleaseImport): Prepared? {
        try {
            openLocalDataWithDownloadRecovery(
                openDatabase = { graph.data.also { it.open() } },
                recoverNativeDownloads = {
                    graph.downloadTempDirectory?.let { withContext(Dispatchers.IO) { discardDownloaderTempFiles(it) } }
                },
                storageFullMessage = T.downloads.storageFull,
            )
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // The open creates or migrates the database (Android opens it here): the start can't go on.
            val record = StartupFailureRecord.of(e, graph.buildLabel, osDescription(), StartupPhase.DATABASE)
            Log.e(TAG, e) { "the database failed to open" }
            graph.startupFailures.recordFailingStart(record)
            startup.finish()
            mutableScreen.value = RootScreen.Failed(record)
            return null
        }
        StartupMarks.mark(StartupMark.DATABASE_READY)
        readStartupAppearance()
        graph.earlierRelease?.let { locations ->
            try {
                // Online, plex.tv names a legacy Plex account; offline it's named at a later start online.
                val plexUser = if (graph.network.value.online) graph.plexUserLookup(platform.device) else null
                earlierRelease.run(locations, plexUser) { startup.begin(StartupStep.MIGRATION) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // Shown, not thrown, in a development build too: the data it reads isn't the app's own.
                Log.e(TAG, e) { "the import of the earlier release's data failed" }
                fail(StartupFailureRecord.of(e, graph.buildLabel, osDescription(), StartupPhase.EARLIER_RELEASE_IMPORT))
                return null
            }
        }
        // Each in a coroutine of its own: a failure goes to the failure boundary, and the start goes on. Saved music
        // queues lose their image tokens before any profile restores one.
        scope.launch(preparation) { SettingsMigrations.applyStartupMigrations(graph.data) }.join()
        scope.launch(preparation) { MusicSessionStore.dropImageTokens(graph.data.musicSessions) }.join()
        delay(startup.slowStart)
        startup.finish()
        // Anything else that fails from here until the app is built shows the failure screen too, whose Retry starts
        // again: nothing else would leave the splash.
        var phase = StartupPhase.PREFERENCES
        try {
            val settings = graph.data.deviceSettings
            val locale = settings.value(AppSettings.appLocale)
            val initialSettings = AppearanceSettings.read(settings)
            val supporterCached = settings.value(AppSettings.supporterEntitlementCached)
            val lost = graph.data.recovery == DatabaseRecovery.RECOVERY_REQUIRED ||
                earlierRelease.outcome() == EarlierReleaseOutcome.RECOVERY_REQUIRED
            // The first frame is in the stored language, and the first servers ask Plex in it.
            // On the main thread, which the interface language belongs to.
            phase = StartupPhase.LOCALE
            withContext(main) { applyInterfaceLanguage(locale) }
            phase = StartupPhase.APP
            val app = AppSession(graph, platform, initialSettings = initialSettings, supporterCached = supporterCached)
            app.primed = false
            return Prepared(app, lost)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "the start failed (${phase.id})" }
            fail(StartupFailureRecord.of(e, graph.buildLabel, osDescription(), phase))
            return null
        }
    }

    /** Keeps [failure] and shows it ([RootScreen.Failed]), whose Retry starts again. */
    private suspend fun fail(failure: StartupFailureRecord) {
        graph.startupFailures.record(failure)
        startup.finish()
        mutableScreen.value = RootScreen.Failed(failure)
    }

    /** [startupAppearance] from the stored settings; one that can't be read leaves the device's default. */
    private suspend fun readStartupAppearance() {
        mutableStartupAppearance.value = try {
            val settings = graph.data.deviceSettings
            Appearance.of(AppearanceSettings.read(settings), platform.formFactor, settings.value(AppSettings.supporterEntitlementCached))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "the stored theme couldn't be read" }
            null
        }
    }

    /**
     * A link the OS handed the app (`plezy://`), from any platform: the running app's one link queue takes it
     * ([AppSession.links]); one that arrives while the app starts waits for it, and is read before the profiles start.
     */
    fun openUrl(url: String) {
        val app = app
        if (app != null) app.links.open(url) else if (!closed) launchLinks += url
    }

    /**
     * Ends the running app for a quit: what a quit owes the servers first (the playback's last reports, the trackers'
     * stop: [AppSession.shutdownForExit]), at most [EXIT_DEADLINE], then [close]. Later calls do nothing.
     */
    suspend fun shutdown(): Unit = withContext(Dispatchers.Main.immediate) {
        if (closed) return@withContext
        val app = app
        if (app != null && withTimeoutOrNull(EXIT_DEADLINE) { app.shutdownForExit() } == null) {
            Log.w(TAG) { "the quit's teardown didn't finish within $EXIT_DEADLINE" }
        }
        close()
    }

    /** Ends the running app. Later calls do nothing. */
    fun close() {
        if (closed) return
        closed = true
        scope.cancel()
        startup.finish()
        app?.close()
        app = null
    }
}

private const val TAG = "RootSession"

/** The longest a quit waits for its teardown ([RootSession.shutdown]). */
private val EXIT_DEADLINE = 15.seconds
/** How long the splash waits for the startup bind when the device reports no network. */
internal val NO_NETWORK_STARTUP_BIND: Duration = 2.seconds

/**
 * The outcome of the startup bind ([settle]): with a network, however long it takes (the app shows meanwhile); without
 * one, at most [NO_NETWORK_STARTUP_BIND], a timeout counting as a failure, so a device with no network reaches the
 * offline shell fast. No network never skips the connect: a server on loopback or a LAN without internet answers.
 */
internal suspend fun awaitStartupBindSettle(hasNetwork: Boolean, settle: suspend () -> Boolean): Boolean =
    if (hasNetwork) settle() else withTimeoutOrNull(NO_NETWORK_STARTUP_BIND) { settle() } ?: false

/** The app starts offline only when the startup bind failed and no server is online. */
internal fun shouldStartOffline(bindingSucceeded: Boolean, hasOnlineServers: Boolean): Boolean = !bindingSucceeded && !hasOnlineServers
