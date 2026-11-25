package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.testData
import com.edde746.plezy.downloads.BackgroundWorkStatus
import com.edde746.plezy.downloads.ControllerHarness
import com.edde746.plezy.downloads.DownloadProgress
import com.edde746.plezy.downloads.FakeBackgroundWorkProbe
import com.edde746.plezy.downloads.diagnostics
import com.edde746.plezy.downloads.testMediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.servers.FakeOfflineWatchDownloads
import com.edde746.plezy.servers.FakeWatchClients
import com.edde746.plezy.servers.InMemoryOfflineWatchQueue
import com.edde746.plezy.servers.OfflineWatchProvider
import com.edde746.plezy.servers.OfflineWatchSyncService
import com.edde746.plezy.servers.RecordingTrackers
import com.edde746.plezy.servers.ToggleOfflineMode
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchedThresholdSource
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration

class DownloadsStoreTest {
    private var harness: ControllerHarness? = null

    @AfterTest
    fun close() {
        harness?.close()
    }

    private fun TestScope.store(h: ControllerHarness): DownloadsStore {
        val data = testData()
        val notifier = WatchStateNotifier()
        val clients = FakeWatchClients()
        val offlineMode = ToggleOfflineMode()
        val sync = OfflineWatchSyncService(
            InMemoryOfflineWatchQueue(), FakeOfflineWatchDownloads(), clients, notifier, RecordingTrackers(),
            thresholds = object : WatchedThresholdSource {
                override fun reportsServerThreshold(client: MediaBackend) = false
                override fun cachedPercent(serverId: ServerId): Int? = null
            },
            offlineMode = offlineMode,
            scope = backgroundScope,
            minSyncInterval = Duration.ZERO,
            forceSyncOnResume = false,
            timeSource = testScheduler.timeSource,
        )
        val offlineWatch = OfflineWatchProvider(sync, FakeOfflineWatchDownloads(), notifier, backgroundScope, { SpecialsOrdering.SPECIALS_LAST }, { false })
        return DownloadsStore(
            controller = h.controller,
            prefs = data.libraryPrefs,
            warning = BackgroundDownloadWarning(diagnostics(FakeBackgroundWorkProbe()), data.deviceSettings, {}, { true }, backgroundScope),
            diagnostics = MutableStateFlow(BackgroundWorkStatus()),
            watchActions = WatchActions(clients, offlineMode, offlineWatch, notifier, RecordingTrackers(), backgroundScope),
            offline = MutableStateFlow(false),
            clientFor = { null },
            serverNameOf = { null },
            dialogs = DownloadDialogs(),
            deletion = SmartDeletion(h.controller),
            parentScope = backgroundScope,
        )
    }

    @Test
    fun aScreenOpenedAfterDownloadsCompletedListsThemInItsFirstState() = runTest {
        val h = ControllerHarness.create().also { harness = it }
        val movie = testMediaItem("m1", MediaKind.MOVIE, "srv", title = "Maestro Movie")
        h.seed(downloads = mapOf(movie.globalKey to DownloadProgress(movie.globalKey, COMPLETED)), metadata = mapOf(movie.globalKey to movie))

        // Nothing has run on the store's scope yet: this is the state a screen made now draws first.
        val store = store(h)
        val state = store.state.value

        assertEquals(listOf("Maestro Movie"), state.tree.map { it.node.title })
        store.select(DownloadsTab.MOVIES)
        val movies = store.state.value.tab?.content as? DownloadsContent.Grid
        assertEquals(listOf("Maestro Movie"), movies?.items?.map { it.title })
    }

    @Test
    fun `switching to Music right after a download completes shows it`() = runTest {
        val h = ControllerHarness.create().also { harness = it }
        val kept = testMediaItem("t1", MediaKind.TRACK, "srv", title = "Kept", parentId = "album-1", parentTitle = "First")
        val arriving = testMediaItem("t2", MediaKind.TRACK, "srv", title = "Arriving", parentId = "album-2", parentTitle = "Second")
        h.seed(
            downloads = mapOf(kept.globalKey to DownloadProgress(kept.globalKey, COMPLETED), arriving.globalKey to DownloadProgress(arriving.globalKey, DOWNLOADING, progress = 50)),
            metadata = mapOf(kept.globalKey to kept, arriving.globalKey to arriving),
        )
        val store = store(h)
        store.select(DownloadsTab.MUSIC)
        store.select(DownloadsTab.MANAGE)

        h.controller.onProgressUpdate(DownloadProgress(arriving.globalKey, COMPLETED, progress = 100))
        store.select(DownloadsTab.MUSIC)

        val albums = store.state.value.tab?.content as? DownloadsContent.Albums
        assertEquals(setOf("Kept", "Arriving"), albums?.rows?.filterIsInstance<MusicRow.Track>()?.map { it.item.title }?.toSet())
    }
}
