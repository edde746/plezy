package com.edde746.plezy.ui.updates

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.BundledText
import com.edde746.plezy.app.DeviceIdentity
import com.edde746.plezy.app.PlatformPlayback
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.ui.TestMain
import com.edde746.plezy.ui.app.PlezyFrame
import com.edde746.plezy.ui.app.PlezyPlatform
import com.edde746.plezy.ui.app.SaveResult
import com.edde746.plezy.updates.Installation
import com.edde746.plezy.updates.ReleaseUpdate
import com.edde746.plezy.updates.Updater
import java.io.IOException
import java.io.File
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/**
 * The update dialog over the app: a GitHub release's (Later, Skip This Version, View Release) and an installer update's
 * (Install Update, its download, its failure), and the installer updater's launch check leaving a skipped version out.
 *
 * The graph's scope (skips, installs) runs on the tests' main thread ([TestMain]), as the product's does on its own,
 * beside the test's UI thread. Nothing waits on a clock: the fake installer and the settings say what happened through
 * deferreds and flows, and [settled] lets the main thread finish what it was handed before the UI is read.
 */
@OptIn(ExperimentalTestApi::class)
class UpdateDialogTest {
    /** The app graph's scope (skips, installs) runs on Main. */
    private val main = TestMain.dispatcher

    @BeforeTest
    fun setUp() {
        TestMain.install()
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    private val platform = TestPlatform()
    private val installer = FakeInstaller()
    private val updates = PlatformUpdates(Installation.Windows("C:\\Plezy\\Plezy.exe", hasUninstaller = true, hasWingetMarker = false), installer)

    private val release = ReleaseUpdate(
        currentVersion = "2.25.9",
        latestVersion = "2.26.0",
        releaseUrl = "https://github.com/edde746/plezy/releases/tag/2.26.0",
        releaseName = "2.26.0",
        releaseNotes = "Fixes the queue.",
        publishedAt = "2026-11-01T10:00:00Z",
    )

    @Test
    fun aReleaseShowsItsVersionsAndNotesAndViewReleaseOpensItsPage() = dialog { _ ->
        runOnIdle { updates.show(release) }

        onNodeWithText("Update Available").assertExists()
        onNodeWithText("Version 2.26.0 is available").assertExists()
        onNodeWithText("Current: 2.25.9").assertExists()
        onNodeWithText("Fixes the queue.").assertExists()
        onNodeWithText("View Release").performClick()

        onNodeWithText("Update Available").assertDoesNotExist()
        assertEquals(listOf(release.releaseUrl), platform.opened.toList())
    }

    @Test
    fun laterClosesTheDialogAndSkipStoresTheVersion() = dialog { graph ->
        runOnIdle { updates.show(release) }
        onNodeWithText("Later").performClick()
        onNodeWithText("Update Available").assertDoesNotExist()
        assertEquals(null, skipped(graph))

        runOnIdle { updates.show(release) }
        onNodeWithText("Skip This Version").performClick()
        onNodeWithText("Update Available").assertDoesNotExist()
        runBlocking { graph.data.deviceSettings.observe(AppSettings.updateSkippedVersion).first { it == "2.26.0" } }
        assertEquals(emptyList(), platform.opened.toList())
    }

    @Test
    fun anInstallerUpdateDownloadsAndSaysWhenItFails() = dialog { _ ->
        assertEquals(Updater.NATIVE, updates.updates.updater)
        runOnIdle { runBlocking { updates.checkInstallerNow() } }

        onNodeWithText("Version 2.26.0 is available").assertExists()
        onNodeWithText("Current: 2.25.9").assertExists()
        onNode(hasText("Install Update") and hasClickAction()).assertIsFocused()
        onNodeWithText("Install Update").performClick()
        onNodeWithText("Downloading the update…").assertExists()
        assertEquals("2.26.0", runBlocking { installer.started.await() })

        installer.result.completeExceptionally(IOException("the download broke off"))
        settled()
        onNodeWithText("The update could not be installed").assertExists()
        onNodeWithText("Close").performClick()
        onNodeWithText("Update Available").assertDoesNotExist()
    }

    @Test
    fun cancelStopsTheDownload() = dialog { _ ->
        runOnIdle { runBlocking { updates.checkInstallerNow() } }
        onNodeWithText("Install Update").performClick()
        runBlocking { installer.started.await() }
        onNodeWithText("Cancel").performClick()

        onNodeWithText("Update Available").assertDoesNotExist()
        runBlocking { installer.cancelled.await() }
        settled()
        onNodeWithText("Update Available").assertDoesNotExist()
    }

    @Test
    fun aProgressReportAfterCancelLeavesTheDialogAlone() = dialog { _ ->
        runOnIdle { runBlocking { updates.checkInstallerNow() } }
        onNodeWithText("Install Update").performClick()
        runBlocking { installer.started.await() }
        onNodeWithText("Cancel").performClick()
        runBlocking { installer.cancelled.await() }

        // The download's thread reports once more after Cancel: the dialog stays closed.
        installer.progress(0.9f)
        settled()
        onNodeWithText("Update Available").assertDoesNotExist()

        // Offered again, a report from the cancelled download doesn't turn it into a download.
        runOnIdle { runBlocking { updates.checkInstallerNow() } }
        installer.progress(0.95f)
        settled()
        onNodeWithText("Install Update").assertExists()
        onNodeWithText("Downloading the update…").assertDoesNotExist()
    }

    @Test
    fun theLaunchCheckLeavesOutASkippedInstallerUpdate() = dialog { graph ->
        runBlocking { graph.data.deviceSettings.set(AppSettings.updateSkippedVersion, "2.26.0") }
        runOnIdle { runBlocking { updates.offerInstallerUpdate() } }
        onNodeWithText("Update Available").assertDoesNotExist()

        installer.found = FakeUpdate("2.26.1")
        runOnIdle { runBlocking { updates.offerInstallerUpdate() } }
        onNodeWithText("Version 2.26.1 is available").assertExists()
    }

    @Test
    fun aFeedThatCantBeReadOffersNothingAtLaunch() = dialog { _ ->
        installer.failCheck = true
        runOnIdle { runBlocking { updates.offerInstallerUpdate() } }
        onNodeWithText("Update Available").assertDoesNotExist()
    }

    private fun skipped(graph: AppGraph): String? = runBlocking { graph.data.deviceSettings.value(AppSettings.updateSkippedVersion) }

    /**
     * Runs what the main thread was handed so far (a resumed install, its failure), then lets the UI catch up: the
     * main thread is one thread, so an empty task it runs comes after them.
     */
    private fun ComposeUiTest.settled() {
        runBlocking(main) {}
        waitForIdle()
    }

    /** The dialog of [updates] in the app's frame on a graph of its own (version 2.25.9), given to [test]. */
    private fun dialog(test: ComposeUiTest.(AppGraph) -> Unit) = runComposeUiTest {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "2.25.9").use { boot ->
            updates.attach(boot.graph)
            setContent {
                PlezyFrame(boot.graph, platform, appearance = null, Modifier.size(960.dp, 540.dp)) { UpdateDialog(updates) }
            }
            waitForIdle()
            test(boot.graph)
        }
    }

    private data class FakeUpdate(override val version: String, override val notesUrl: String? = "https://example.com/notes") : InstallerUpdate

    /**
     * The feed offers [found]; an install says which version it [started], reports half done, then waits for [result]
     * and says when it was [cancelled]; [progress] is its report, kept for a late one. The install runs on the main
     * thread, the test reads it from its own: only deferreds and volatile fields cross.
     */
    private class FakeInstaller : InstallerUpdater {
        @Volatile var found: InstallerUpdate? = FakeUpdate("2.26.0")
        @Volatile var failCheck = false
        val started = CompletableDeferred<String>()
        val result = CompletableDeferred<Unit>()
        val cancelled = CompletableDeferred<Unit>()
        @Volatile var progress: (Float) -> Unit = {}

        override suspend fun check(): InstallerUpdate? = if (failCheck) throw IOException("the feed is down") else found

        override suspend fun install(update: InstallerUpdate, progress: (Float) -> Unit) {
            this.progress = progress
            started.complete(update.version)
            progress(0.5f)
            try {
                result.await()
            } catch (e: CancellationException) {
                cancelled.complete(Unit)
                throw e
            }
        }
    }

    /** The platform as far as the dialog reaches it: the links it opens. */
    private class TestPlatform : PlezyPlatform {
        /** Written on the UI thread, read on the test's. */
        val opened = CopyOnWriteArrayList<String>()

        override val formFactor = FormFactor.DESKTOP

        override val appleTv = false

        override val device: DeviceIdentity get() = error("the test names no device")

        override val artworkCacheDirectory = File(System.getProperty("java.io.tmpdir"), "plezy-test-artwork")

        override val playerConfig: PlayerConfig get() = error("the test plays nothing")

        override fun createPlayback(settings: DeviceSettings): PlatformPlayback = error("the test plays nothing")

        override fun createMusicAudioPlayer(): AudioPlayer = error("the test plays nothing")

        override fun setFullscreen(fullscreen: Boolean) = Unit

        override fun openUrl(url: String): Boolean {
            opened += url
            return true
        }

        override fun setClipboardText(text: String, sensitive: Boolean) = Unit

        override fun deviceFeatures(): DeviceFeatures = error("the test reads no device")

        override fun bundledTexts(folder: String): List<BundledText> = error("the test reads no device")

        override fun exit() = Unit

        @Composable
        override fun VideoSurface(engine: PlayerEngine, modifier: Modifier) = Unit

        override fun saveFile(fileName: String, text: String, done: (SaveResult) -> Unit) = Unit

        override fun openFile(opened: (name: String, text: String) -> Unit, failed: () -> Unit) = Unit
    }
}
