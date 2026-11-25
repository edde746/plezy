package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.testData
import com.edde746.plezy.downloads.ControllerHarness
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.downloads.DownloadProgress
import com.edde746.plezy.downloads.FakeBackgroundWorkProbe
import com.edde746.plezy.downloads.diagnostics
import com.edde746.plezy.downloads.testMediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The detail download button through a download's life: queueing, queued, downloading, done, and the stops on the way. */
class DownloadButtonSpecTest {
    private var harness: ControllerHarness? = null
    private val movie = testMediaItem("m", MediaKind.MOVIE, "srv")
    private val key = movie.globalKey

    @AfterTest
    fun close() {
        harness?.close()
    }

    /** The button for [movie] with its download at [status] (none: not downloaded), [queueing] while it expands. */
    private suspend fun TestScope.spec(status: DownloadedMediaStatus?, percent: Int = 0, currentFile: String? = null, queueing: Boolean = false): DownloadButtonSpec {
        val h = ControllerHarness.create().also { harness = it }
        if (status != null) {
            h.seed(downloads = mapOf(key to DownloadProgress(key, status, progress = percent)))
            // The files still to come arrive with the manager's progress reports.
            if (currentFile != null) h.controller.onProgressUpdate(DownloadProgress(key, status, progress = percent, currentFile = currentFile))
        }
        if (queueing) {
            // Held at the notification permission prompt, the title is still expanding.
            h.permission.gate = CompletableDeferred()
            backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { h.controller.queueDownload(movie, FakeMediaBackend("srv")) }
        }
        return downloadButtonSpec(h.controller, movie)
    }

    @Test
    fun `a title not downloaded offers the download`() = runTest {
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.DOWNLOAD, T.downloads.downloadNow), spec(null))
    }

    @Test
    fun `queueing shows a spinner that takes no press whatever the download says`() = runTest {
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.SPINNER, null, interactive = false), spec(null, queueing = true))
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.SPINNER, null, interactive = false), spec(DownloadedMediaStatus.FAILED, queueing = true))
    }

    @Test
    fun `queued shows the queued icon and names the files still to come`() = runTest {
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.QUEUED, T.downloads.queuedTooltip, interactive = false), spec(DownloadedMediaStatus.QUEUED))
        assertEquals(
            DownloadButtonSpec(DownloadButtonIcon.QUEUED, T.downloads.queuedFilesTooltip(files = "0 of 3 episodes"), interactive = false),
            spec(DownloadedMediaStatus.QUEUED, currentFile = "0 of 3 episodes"),
        )
    }

    @Test
    fun `downloading shows its progress and takes no press`() = runTest {
        assertEquals(
            DownloadButtonSpec(DownloadButtonIcon.PROGRESS, T.downloads.downloadingTooltip, interactive = false, progress = 0.42f),
            spec(DownloadedMediaStatus.DOWNLOADING, percent = 42),
        )
        assertEquals(
            T.downloads.downloadingFilesTooltip(files = "1 of 3 episodes"),
            spec(DownloadedMediaStatus.DOWNLOADING, currentFile = "1 of 3 episodes").tooltip,
        )
    }

    @Test
    fun `a finished download shows done and offers to delete it`() = runTest {
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.DOWNLOADED, T.downloads.deleteDownload, DownloadButtonTint.ORANGE), spec(DownloadedMediaStatus.COMPLETED))
    }

    @Test
    fun `a failed download shows the error and offers a retry`() = runTest {
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.FAILED, T.downloads.retryDownload, DownloadButtonTint.RED), spec(DownloadedMediaStatus.FAILED))
    }

    @Test
    fun `a paused download offers to resume it`() = runTest {
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.PAUSED, T.downloads.resumeDownload, DownloadButtonTint.AMBER), spec(DownloadedMediaStatus.PAUSED))
    }

    @Test
    fun `a cancelled download says so`() = runTest {
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.CANCELLED, T.downloads.cancelledDownload, DownloadButtonTint.GREY), spec(DownloadedMediaStatus.CANCELLED))
    }

    @Test
    fun `a partly downloaded title offers to complete it`() = runTest {
        assertEquals(
            DownloadButtonSpec(DownloadButtonIcon.PARTIAL, T.downloads.partialDownloadClickToComplete, DownloadButtonTint.ORANGE),
            spec(DownloadedMediaStatus.PARTIAL),
        )
    }

    @Test
    fun `a downloaded album asks before deleting and then says the download is deleted`() = runTest {
        val h = ControllerHarness.create().also { harness = it }
        val album = testMediaItem("al", MediaKind.ALBUM, "srv", title = "Sine Album")
        val track = testMediaItem("t1", MediaKind.TRACK, "srv", parentId = album.id)
        h.seed(
            downloads = mapOf(track.globalKey to DownloadProgress(track.globalKey, DownloadedMediaStatus.COMPLETED)),
            metadata = mapOf(track.globalKey to track, album.globalKey to album),
        )
        val dialogs = DownloadDialogs()
        val settings = testData().deviceSettings
        val warning = BackgroundDownloadWarning(diagnostics(FakeBackgroundWorkProbe()), settings, {}, { true }, backgroundScope)
        val detail = DetailDownload(h.controller, DownloadActions(h.controller, dialogs, warning, settings), dialogs, warning, SmartDeletion(h.controller))

        val press = async { detail.press(album, FakeMediaBackend("srv")) }
        val confirm = dialogs.dialog.filterIsInstance<DownloadDialog.Confirm>().first()
        assertEquals(T.downloads.deleteConfirm(title = "Sine Album"), confirm.message)
        assertTrue(confirm.destructive)
        dialogs.confirm()

        assertEquals(DownloadFeedback(T.downloads.downloadDeleted, isError = false), press.await())
    }
}
