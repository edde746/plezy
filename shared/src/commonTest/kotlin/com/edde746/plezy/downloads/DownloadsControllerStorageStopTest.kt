package com.edde746.plezy.downloads

import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.model.CollectionMembership
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** A storage failure stops downloads: sync rules wait behind the stop, a download the user asks for lifts it. */
class DownloadsControllerStorageStopTest {
    private var harness: ControllerHarness? = null
    private val downloader = FakeNativeDownloader()
    private var queueRuns = 0

    @AfterTest
    fun close() {
        harness?.close()
    }

    /** A server whose show and season hold [episodes]; [onFetchItem] runs inside each item fetch. */
    private class ShowBackend(val episodes: List<MediaItem>, val onFetchItem: suspend (String) -> Unit = {}) : FakeMediaBackend("srv") {
        init {
            playableDescendants = { episodes }
            items = { id ->
                onFetchItem(id)
                null
            }
        }

        override suspend fun stampLibrary(item: MediaItem): MediaItem = item

        override fun resolveDownloadArtwork(item: MediaItem) = emptyList<DownloadArtworkSpec>()

        override suspend fun fetchCollectionMemberships(itemIds: Set<String>) = emptyList<CollectionMembership>()
    }

    private fun episode(index: Int) = testMediaItem("ep-$index", MediaKind.EPISODE, "srv", title = "Episode $index", parentIndex = 1, index = index)

    private val movie = testMediaItem("movie-1", MediaKind.MOVIE, "srv", title = "Movie")

    /** The controller over a manager whose queue runs are counted, with [client] registered. */
    private suspend fun harness(client: ShowBackend): ControllerHarness {
        val dms = DmsHarness.create()
        client.cacheHandle = dms.plexCache
        val h = ControllerHarness(dms, downloader, managerOf = { servers ->
            dms.manager(clientResolver = { id, _ -> servers.client(id) }, downloader = downloader, queueProcessorOverride = { queueRuns++ })
        })
        harness = h
        h.controller.ensureInitialized()
        h.servers.register(client)
        return h
    }

    /** [item] downloading for the active profile, which the storage refusal will hit. */
    private suspend fun ControllerHarness.downloading(item: MediaItem) {
        seed(downloads = mapOf(item.globalKey to DownloadProgress(item.globalKey, DOWNLOADING)), metadata = mapOf(item.globalKey to item))
        dms.library.updateBgTaskId(item.globalKey, "task-${item.id}")
    }

    private suspend fun ControllerHarness.refuseForStorage(item: MediaItem) {
        val update = TaskStatusUpdate(downloadTask("task-${item.id}", item.globalKey), TaskStatus.FAILED, TaskException.FileSystem(StorageFloor.REFUSAL))
        dms.report(this@DownloadsControllerStorageStopTest.downloader, update)
        until { controller.downloads[item.globalKey]?.status == FAILED }
    }

    private suspend fun ControllerHarness.row(item: MediaItem) = dms.library.getDownloadedMedia(item.globalKey)

    @Test
    fun `sync passes neither lift a storage stop nor queue and a retry lifts it`() = runTest {
        val refused = episode(1)
        val next = episode(2)
        val client = ShowBackend(listOf(refused, next))
        val h = harness(client)
        val rule = h.controller.createSyncRule(ServerId("srv"), "show-1", SyncRuleTarget.SHOW, 0)
        h.downloading(refused)
        h.refuseForStorage(refused)
        assertTrue(h.manager.queueBlockedByStorageFailure)
        client.calls.clear()

        assertEquals(emptyList(), h.controller.executeSyncRules(force = true))
        assertNull(h.controller.executeSyncRuleFor(rule.globalKey))

        assertTrue(h.manager.queueBlockedByStorageFailure)
        assertEquals(FAILED.code, h.row(refused)?.status)
        assertEquals(T.downloads.storageFull, h.row(refused)?.error_message)
        assertEquals(FAILED, h.controller.downloads[refused.globalKey]?.status)
        assertNull(h.row(next))
        assertTrue(h.dms.library.getQueue().isEmpty())
        assertEquals(0, queueRuns)
        assertEquals(emptyList(), client.calls, "a stopped pass makes no server requests")

        h.controller.retryDownload(refused.globalKey, client)
        assertFalse(h.manager.queueBlockedByStorageFailure)
        assertEquals(QUEUED.code, h.row(refused)?.status)

        h.controller.executeSyncRules(force = true)
        assertEquals(QUEUED.code, h.row(next)?.status)
    }

    @Test
    fun `a storage stop during a sync pass holds the rest of the pass`() = runTest {
        val episodes = (1..3).map(::episode)
        lateinit var h: ControllerHarness
        val client = ShowBackend(episodes) { id -> if (id == "ep-2") h.refuseForStorage(movie) }
        h = harness(client)
        h.controller.createSyncRule(ServerId("srv"), "show-1", SyncRuleTarget.SHOW, 0)
        h.downloading(movie)

        h.controller.executeSyncRules(force = true)

        assertTrue(h.manager.queueBlockedByStorageFailure)
        assertEquals(1, queueRuns, "only the episode queued before the stop ran the queue")
        assertEquals(T.downloads.storageFull, h.row(episodes[0])?.error_message)
        assertNull(h.row(episodes[1]))
        assertNull(h.row(episodes[2]))
        assertFalse("fetchItem:ep-3" in client.calls)
    }

    @Test
    fun `a storage stop during a season download holds its other episodes until the next request`() = runTest {
        val episodes = (1..3).map(::episode)
        lateinit var h: ControllerHarness
        val client = ShowBackend(episodes) { id -> if (id == "ep-2") h.refuseForStorage(movie) }
        h = harness(client)
        h.downloading(movie)

        h.controller.queueDownload(testMediaItem("season-1", MediaKind.SEASON, "srv", title = "Season 1", index = 1), client)

        assertTrue(h.manager.queueBlockedByStorageFailure)
        assertEquals(1, queueRuns)
        for (held in episodes.drop(1)) assertEquals(QUEUED.code, h.row(held)?.status, held.id)

        h.controller.queueDownload(testMediaItem("movie-2", MediaKind.MOVIE, "srv", title = "Movie 2"), client)

        assertFalse(h.manager.queueBlockedByStorageFailure)
        h.dms.idle()
        assertEquals(2, queueRuns)
    }
}
