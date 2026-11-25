package com.edde746.plezy.downloads

import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.DownloadTranscoding
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.transcodeQuality
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runTest
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.write
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** An MPEG transport stream of one video PES packet per second, from 0 s to [lastSecond]. */
internal fun transportStream(lastSecond: Int): ByteArray = ByteArray(188 * (lastSecond + 1)).also { bytes ->
    for (second in 0..lastSecond) {
        val at = second * 188
        val pts = second * 90_000L
        bytes.fill(0xFF.toByte(), at, at + 188)
        val header = intArrayOf(
            0x47, 0x41, 0x00, 0x10, // sync, unit start on PID 0x100, payload only
            0x00, 0x00, 0x01, 0xE0, 0x00, 0x00, 0x80, 0x80, 0x05, // video PES, PTS only
            (0x20 or ((pts shr 29).toInt() and 0x0E) or 1), ((pts shr 22).toInt() and 0xFF),
            ((pts shr 14).toInt() and 0xFE) or 1, ((pts shr 7).toInt() and 0xFF), ((pts shl 1).toInt() and 0xFE) or 1,
        )
        header.forEachIndexed { i, b -> bytes[at + i] = b.toByte() }
    }
}

class TransportStreamSpanTest {
    private suspend fun span(bytes: ByteArray) = TransportStreamSpan.measure(bytes.size.toLong()) { offset, length -> bytes.copyOfRange(offset.toInt(), offset.toInt() + length) }

    @Test
    fun aStreamSpansFromItsFirstToItsLastTimestamp() = runTest {
        assertEquals(60.seconds, span(transportStream(60)))
        // A file bigger than both windows is read only at its ends.
        val big = transportStream(30_000)
        assertTrue(big.size > 2 * TransportStreamSpan.WINDOW)
        assertEquals(30_000.seconds, span(big))
    }

    @Test
    fun aStreamCoversItsRuntimeUnlessItEndsEarly() {
        assertTrue(TransportStreamSpan.covers(60.seconds, 60_000))
        assertTrue(TransportStreamSpan.covers(58.seconds, 60_000), "the last frame and the encoder's rounding")
        assertFalse(TransportStreamSpan.covers(30.seconds, 60_000))
        assertFalse(TransportStreamSpan.covers(3_500.seconds, 3_600_000), "100 s short of an hour")
    }

    @Test
    fun bytesThatAreNotATransportStreamHaveNoSpan() = runTest {
        assertNull(span(ByteArray(4096) { 0x47 }))
        assertNull(span(ByteArray(0)))
    }
}

class DownloadManagerServiceTranscodeTest {
    private lateinit var harness: DmsHarness
    private val globalKey = "srv:item-1"
    private val downloader = FakeNativeDownloader()
    private val streamUrl = "https://example.test/videos/item-1/stream.ts?PlaySessionId=ps-1"
    private val task = downloadTask("current-task", globalKey).copy(url = streamUrl)
    private val item = testMediaItem("item-1", MediaKind.MOVIE, "srv", title = "Movie")

    @AfterTest
    fun close() = harness.close()

    private class TranscodingBackend(item: MediaItem) : SupplementaryBackend(item, { DownloadResolution("https://example.test/video") }), DownloadTranscoding {
        val stopped = mutableListOf<String>()

        override suspend fun resolveTranscodedDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, quality: TranscodeQualityPreset) =
            DownloadResolution("https://example.test/stream.ts")

        override suspend fun stopDownloadTranscode(downloadUrl: String) {
            stopped += downloadUrl
        }
    }

    private suspend fun seed(quality: TranscodeQualityPreset = TranscodeQualityPreset.P720_2MBPS, totalBytes: Long? = null) {
        harness = DmsHarness.create()
        harness.putPlexMetadata(
            "srv",
            "item-1",
            JsonObject(mapOf("ratingKey" to JsonPrimitive("item-1"), "type" to JsonPrimitive("movie"), "title" to JsonPrimitive("Movie"), "duration" to JsonPrimitive(60_000))),
        )
        harness.data.insertDownload("srv", "item-1", status = DOWNLOADING, totalBytes = totalBytes, transcodeQuality = quality.name.takeUnless { quality.isOriginal })
        harness.library.updateBgTaskId(globalKey, task.taskId)
    }

    private suspend fun started(manager: DownloadManagerService): DownloadManagerService {
        downloader.holds(task)
        harness.start(manager, downloader)
        return manager
    }

    private suspend fun row() = harness.library.getDownloadedMedia(globalKey)!!

    @Test
    fun theQueuedDownloadKeepsItsQuality() = runTest {
        harness = DmsHarness.create()
        val manager = harness.manager(downloader = downloader, queueProcessorOverride = {})
        manager.queueDownload(item, TranscodingBackend(item), transcodeQuality = TranscodeQualityPreset.P720_2MBPS)
        assertEquals(TranscodeQualityPreset.P720_2MBPS, row().transcodeQuality)
    }

    @Test
    fun aTranscodeWithoutAKnownLengthRunsAgainstItsEstimate() = runTest {
        seed(totalBytes = 1_000_000)
        val manager = started(harness.manager(downloader = downloader))
        val log = manager.progressLog(backgroundScope)

        harness.report(downloader, TaskProgressUpdate(task, 0.0, expectedFileSize = -1, bytesPerSecond = 100, downloadedBytes = 500_000))
        val half = log.awaitFirst { it.globalKey == globalKey && it.downloadedBytes == 500_000L }
        assertEquals(50, half.progress)
        assertEquals(1_000_000L, half.totalBytes)

        // Past the estimate it stays short of done until the file is whole.
        harness.report(downloader, TaskProgressUpdate(task, 0.0, expectedFileSize = -1, bytesPerSecond = 100, downloadedBytes = 1_200_000))
        val over = log.awaitFirst { it.globalKey == globalKey && it.downloadedBytes == 1_200_000L }
        assertEquals(99, over.progress)
        assertEquals(1_200_000L, over.totalBytes)
    }

    @Test
    fun cancellingATranscodeStopsTheServersEncode() = runTest {
        seed()
        val client = TranscodingBackend(item)
        val manager = started(harness.manager(clientResolver = { _, _ -> client }, downloader = downloader, queueProcessorOverride = {}))

        manager.cancelDownload(globalKey)
        harness.idle()

        assertEquals(listOf(streamUrl), client.stopped)
    }

    @Test
    fun cancellingAnOriginalDownloadLeavesTheServerAlone() = runTest {
        seed(TranscodeQualityPreset.ORIGINAL)
        val client = TranscodingBackend(item)
        val manager = started(harness.manager(clientResolver = { _, _ -> client }, downloader = downloader, queueProcessorOverride = {}))

        manager.cancelDownload(globalKey)
        harness.idle()

        assertTrue(client.stopped.isEmpty())
    }

    private suspend fun complete(lastSecond: Int): Path {
        seed()
        val manager = harness.manager(downloader = downloader, queueProcessorOverride = {})
        val file = Path(downloader.filePath(task))
        SystemFileSystem.createDirectories(file.parent!!)
        SystemFileSystem.sink(file).buffered().use { it.write(transportStream(lastSecond)) }
        started(manager)
        real { harness.report(downloader, TaskStatusUpdate(task, TaskStatus.COMPLETE)) }
        return file
    }

    @Test
    fun aWholeTranscodeCompletesWithItsRealSize() = runTest {
        val file = complete(lastSecond = 60)
        assertEquals(COMPLETED.code, row().status)
        assertEquals(SystemFileSystem.metadataOrNull(file)!!.size, row().total_bytes)
    }

    @Test
    fun aTranscodeTheServerEndedEarlyFailsAndIsDeleted() = runTest {
        val file = complete(lastSecond = 30)
        assertEquals(FAILED.code, row().status)
        assertEquals(T.downloads.errorDownloadFailedWithReason(T.errors.reasonServerError), row().error_message)
        assertFalse(SystemFileSystem.exists(file))
    }
}
