package com.edde746.plezy.app

import com.edde746.plezy.crash.FailureBoundary
import com.edde746.plezy.crash.StartupFailedException
import com.edde746.plezy.crash.StartupFailureRecord
import com.edde746.plezy.crash.StartupFailures
import com.edde746.plezy.crash.StartupMark
import com.edde746.plezy.crash.StartupMarks
import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.crash.StartupPhaseException
import com.edde746.plezy.crash.osDescription
import com.edde746.plezy.crash.startupPhase
import com.edde746.plezy.data.DataReset
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.downloads.DownloadStoragePlatform
import com.edde746.plezy.downloads.discardDownloaderTempFiles
import com.edde746.plezy.downloads.openLocalDataWithDownloadRecovery
import com.edde746.plezy.importer.EarlierReleaseLocations
import com.edde746.plezy.log.Log
import com.edde746.plezy.net.NetworkState
import com.edde746.plezy.net.PlezyHttpClient
import com.edde746.plezy.net.closeIdleConnections
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.secrets.SecretStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.plus
import kotlinx.coroutines.runBlocking
import kotlin.time.Clock

/**
 * The shared core of one app process ([graph]). Every app builds one at launch, off the main thread (the graph opens
 * the database), and [close]s it when the process ends. Its coroutines run on the main dispatcher, inside one failure
 * boundary ([FailureBoundary]): in the product a coroutine that throws is logged and reported and the app runs on; in
 * a development build and in [local] it ends the process. The platform reports the system's settings
 * ([SystemInputs.report]) first: [product] and [local] throw an [IllegalStateException] before then.
 *
 * - [product]: the device's database and its secret store.
 * - [local]: a process of its own: an in-memory database (or one of its own) and secrets in memory. The dev module's
 *   development session is one; nothing it does reaches the device's database or its secret store.
 *
 * The platform calls [onForeground] whenever the app comes to the foreground, [onBackground] whenever it leaves it
 * (hidden, minimized, or running on for audio, picture in picture or a download), and [onNetworkChanged] whenever the
 * network changes. The Mac, where another app being frontmost counts as the background, also calls
 * [onWindowVisibleChanged], which there alone decides whether the app can be seen ([AppGraph.visible]).
 */
class AppBootstrap private constructor(
    val graph: AppGraph,
    /** The boundary of [graph]'s scope, whose failures [com.edde746.plezy.crash.crashReports] sends. */
    internal val failures: FailureBoundary,
) : AutoCloseable {
    init {
        // Log's level follows the Debug logging setting from the start, in a development session as in the product.
        graph.scope.launch { Log.followDebugLogging(graph.data.deviceSettings.observe(AppSettings.enableDebugLogging)) }
    }

    /** The app came to the foreground: its idle connections close (one may have died while it slept). */
    fun onForeground() {
        graph.http.closeIdleConnections()
        graph.setForeground(true)
    }

    /** The app went to the background. */
    fun onBackground() {
        graph.setForeground(false)
    }

    /**
     * The Mac's window can be seen, or no longer can (minimized, hidden, covered whole), whichever app is frontmost and
     * whether or not the app is active ([AppGraph.visible]).
     */
    fun onWindowVisibleChanged(visible: Boolean) {
        graph.setWindowVisible(visible)
    }

    /**
     * The device's network changed ([AppGraph.network]): [online] when some network is up, [metered] when it costs per
     * byte. The idle connections close, since they went out on the old network.
     */
    fun onNetworkChanged(online: Boolean, metered: Boolean) {
        graph.http.closeIdleConnections()
        graph.setNetwork(NetworkState(online, metered))
    }

    /** Closes the graph (its HTTP client and database). */
    override fun close() {
        graph.close()
    }

    companion object {
        /**
         * @param database the device's database (`DatabaseFactory()` on Apple platforms, the file in
         *   `DatabaseFactory.defaultDirectory()` on desktop).
         * @param startup the start the splash shows, which the platform began first: opening the database reports a
         *   migration to it, and the platform hands it to [RootSession].
         * @param development a development build (Android's debug build, Apple's Debug configuration): a coroutine that
         *   throws ends the process instead of being reported ([FailureBoundary]), and the player offers its debug entries
         *   ([com.edde746.plezy.presentation.player.PlayerConfig.development]).
         * @param earlierRelease where Plezy's earlier releases kept their data on this device (`EarlierReleaseLocations.android`,
         *   `.desktop`, `.apple`): the first start imports it ([RootSession]). Null for a launch with a device of its own.
         * @param downloadTempDirectory the background downloader's partial files (`DownloadPlatform.tempDirectory`): a
         *   database that can't open because the device is full opens after they are discarded, and the downloads that
         *   were running fail as stopped for storage ([openLocalDataWithDownloadRecovery]); null without downloads
         *   (Apple TV).
         * @param buildLabel the build as a failed start's record names it ([StartupFailureRecord.appVersion]):
         *   `version+build`, as [appVersion] where the platform has no build number.
         * @throws StartupFailedException when the core can't be built: its record is kept for the next start, and the
         *   platform shows the startup failure screen, whose Retry calls this again.
         */
        @Throws(StartupFailedException::class)
        fun product(
            database: DatabaseFactory,
            secrets: SecretStore,
            flavor: BuildFlavor,
            appVersion: String,
            startup: Startup,
            development: Boolean = false,
            earlierRelease: EarlierReleaseLocations? = null,
            downloadTempDirectory: String? = null,
            buildLabel: String = appVersion,
        ): AppBootstrap = product(
            database.filesDirectory(), secrets, flavor, appVersion, development, earlierRelease, downloadTempDirectory, buildLabel,
        ) {
            val data = LocalData(database) { startup.begin(StartupStep.MIGRATION) }
            // Its schema is checked here too, before anything reads it; Android's opens in RootSession, off the main
            // thread.
            if (!database.opensOnFirstStatement) {
                try {
                    data.open()
                } catch (e: Exception) {
                    data.close()
                    throw e
                }
            }
            data
        }

        /**
         * Resets the app's saved data after the start failed for it ([StartupFailureRecord.dataFault]) and the user
         * confirmed: [DataReset] over the start's [database] and [secrets], the app's own download folders under
         * [downloads]' base directory and [downloadTempDirectory]. Nothing may have the database open; the platform
         * starts again afterwards, as a first run.
         */
        @Throws(Exception::class)
        suspend fun resetData(database: DatabaseFactory, secrets: SecretStore, downloads: DownloadStoragePlatform?, downloadTempDirectory: String?) {
            DataReset(database, secrets, downloads, downloadTempDirectory).reset()
        }

        /**
         * [product] over the database [openDatabase] opens and checks (closing what it created when that fails), its
         * files in [filesDirectory]. Desktop and Apple platforms open it here; Android's driver opens it at its first
         * statement, in [RootSession], which recovers from a full disk the same way.
         */
        @Throws(StartupFailedException::class)
        internal fun product(
            filesDirectory: String,
            secrets: SecretStore,
            flavor: BuildFlavor,
            appVersion: String,
            development: Boolean,
            earlierRelease: EarlierReleaseLocations?,
            downloadTempDirectory: String?,
            buildLabel: String = appVersion,
            openDatabase: suspend () -> LocalData,
        ): AppBootstrap {
            SystemInputs.requireReported()
            val failures = FailureBoundary(crash = development)
            try {
                StartupMarks.mark(StartupMark.DATABASE_OPEN_STARTED)
                val data = startupPhase(StartupPhase.DATABASE) {
                    runBlocking {
                        openLocalDataWithDownloadRecovery(
                            openDatabase = { openDatabase() },
                            recoverNativeDownloads = { downloadTempDirectory?.let { discardDownloaderTempFiles(it) } },
                            storageFullMessage = T.downloads.storageFull,
                        )
                    }
                }
                // The platform's HTTP engine, with the system's (and the user's) trusted certificates.
                val http = startupPhase(StartupPhase.CERTIFICATE_TRUST) { PlezyHttpClient.create(appVersion) }
                // The core over the app's files directory: downloads, image cache and earlier releases' data under it.
                val graph = startupPhase(StartupPhase.STORAGE) {
                    AppGraph(
                        data, secrets, flavor, appVersion, http, MainScope() + failures, Clock.System, filesDirectory,
                        earlierRelease = earlierRelease, downloadTempDirectory = downloadTempDirectory, development = development,
                        buildLabel = buildLabel,
                    )
                }
                return AppBootstrap(graph, failures)
            } catch (e: Exception) {
                // The next start sends it to the crash reporter and shows it on the Logs screen; its phase is the step's.
                val record = StartupFailureRecord.of(e, buildLabel, osDescription())
                StartupFailures(filesDirectory).recordFailingStart(record)
                throw StartupFailedException(record, StartupPhaseException.unwrap(e))
            }
        }

        /**
         * A process of its own (a development session, a UI test), whose coroutine that throws ends the process
         * ([FailureBoundary]).
         *
         * @param database an in-memory database (`DatabaseFactory.inMemory()`), or a directory of its own.
         */
        fun local(database: DatabaseFactory, flavor: BuildFlavor, appVersion: String): AppBootstrap =
            local(database, flavor, appVersion, PlezyHttpClient.create(appVersion))

        /** [local] whose requests go through [http] (a development session's recorded plex.tv). */
        fun local(database: DatabaseFactory, flavor: BuildFlavor, appVersion: String, http: HttpClient): AppBootstrap {
            SystemInputs.requireReported()
            val failures = FailureBoundary(crash = true)
            val graph = AppGraph(database, MemorySecretStore(), flavor, appVersion, http, scope = MainScope() + failures)
            return AppBootstrap(graph, failures)
        }
    }
}
