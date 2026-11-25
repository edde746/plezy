package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.testData
import com.edde746.plezy.downloads.ControllerHarness
import com.edde746.plezy.downloads.DmsHarness
import com.edde746.plezy.downloads.DownloadProgress
import com.edde746.plezy.downloads.FakeBackgroundWorkProbe
import com.edde746.plezy.downloads.FakeNativeDownloader
import com.edde746.plezy.downloads.SupplementaryBackend
import com.edde746.plezy.downloads.diagnostics
import com.edde746.plezy.downloads.testMediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class DetailDownloadTest {
    private var harness: ControllerHarness? = null

    @AfterTest
    fun close() {
        harness?.close()
    }

    @Test
    fun aPartlyDownloadedAlbumQueuesItsMissingTracksAgain() = runTest {
        // The manager's queue drain is held: it runs on another thread and would move t2 on to downloading (through the
        // unscripted offline client seed registers for the server) while the assertions read what the press queued.
        val dms = DmsHarness.create()
        val downloader = FakeNativeDownloader()
        val h = ControllerHarness(dms, downloader, managerOf = { servers ->
            dms.manager(clientResolver = { id, _ -> servers.client(id) }, downloader = downloader, queueProcessorOverride = {})
        }).also { harness = it; it.controller.ensureInitialized() }
        val c = h.controller
        val tracks = listOf("t1", "t2").map { testMediaItem(it, MediaKind.TRACK, "srv", parentId = "album", grandparentId = "artist") }
        h.seed(
            downloads = mapOf(
                "srv:t1" to DownloadProgress("srv:t1", DownloadedMediaStatus.COMPLETED, progress = 100),
                "srv:t2" to DownloadProgress("srv:t2", DownloadedMediaStatus.FAILED),
            ),
            metadata = tracks.associateBy { it.globalKey },
        )
        val album = testMediaItem("album", MediaKind.ALBUM, "srv")
        assertEquals(DownloadedMediaStatus.PARTIAL, c.getProgress(album.globalKey)?.status)
        // The album's tracks are fetched again; the one the profile has completed is skipped, the failed one queues.
        val client = SupplementaryBackend(tracks[1], { DownloadResolution("https://example.test/t2.flac") }).apply {
            playableDescendants = { tracks }
            items = { id -> tracks.firstOrNull { it.id == id } }
        }
        val settings = testData().deviceSettings
        val warning = BackgroundDownloadWarning(diagnostics(FakeBackgroundWorkProbe()), settings, {}, { true }, backgroundScope)
        val dialogs = DownloadDialogs()
        val detail = DetailDownload(c, DownloadActions(c, dialogs, warning, settings), dialogs, warning, SmartDeletion(c))

        val feedback = assertNotNull(detail.press(album, client))

        assertEquals(T.downloads.downloadQueued, feedback.message, "one track queued")
        assertEquals(DownloadedMediaStatus.COMPLETED, c.getProgress("srv:t1")?.status)
        assertEquals(DownloadedMediaStatus.QUEUED, c.getProgress("srv:t2")?.status)
    }
}
