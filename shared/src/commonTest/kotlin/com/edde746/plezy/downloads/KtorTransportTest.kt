package com.edde746.plezy.downloads

import com.edde746.plezy.playback.resolve.FakeHttp
import com.edde746.plezy.playback.resolve.headers
import com.edde746.plezy.playback.resolve.lcgBytes
import com.edde746.plezy.playback.resolve.redirect
import com.edde746.plezy.playback.resolve.respondRange
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.utils.io.ByteChannel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.testTimeSource
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.readByteArray
import kotlinx.io.write
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class KtorTransportTest {
    private val directory = Path(SystemTemporaryDirectory, "plezy-transport-" + Random.nextLong().toULong())
    private val part = Path(directory, "video.mkv.part")
    private val file = lcgBytes(300_000, seed = 7)

    @AfterTest
    fun deleteDirectory() {
        deleteTree(directory)
    }

    @Test
    fun aWholeFileArrivesInThePartFileWithItsValidator() = runTest {
        val http = FakeHttp(this) { request -> serveVideo(request, file, "\"abc\"") }
        val listener = RecordingListener()

        val result = transport(http).transfer(request(offset = 0), listener)

        assertEquals(TransferResult.Completed(file.size.toLong(), "\"abc\""), result)
        assertContentEquals(file, read())
        assertEquals(listOf<String?>("\"abc\""), listener.validators)
        assertEquals(file.size.toLong(), listener.progress.last())
        val sent = http.requests.single()
        assertNull(sent.headers[HttpHeaders.Range])
        assertEquals("no-store", sent.headers[HttpHeaders.CacheControl])
        assertEquals("identity", sent.headers[HttpHeaders.AcceptEncoding])
        assertEquals("Plezy/test", sent.headers[HttpHeaders.UserAgent])
    }

    @Test
    fun aResumeAsksForTheRestWithIfRangeAndAppends() = runTest {
        write(file.copyOf(100_000))
        val http = FakeHttp(this) { request -> serveVideo(request, file, "\"abc\"") }

        val result = transport(http).transfer(request(offset = 100_000, validator = "\"abc\""), RecordingListener())

        assertEquals(TransferResult.Completed(file.size.toLong(), "\"abc\""), result)
        assertContentEquals(file, read())
        val sent = http.requests.single()
        assertEquals("bytes=100000-", sent.headers[HttpHeaders.Range])
        assertEquals("\"abc\"", sent.headers[HttpHeaders.IfRange])
    }

    @Test
    fun aWholeFileAnsweringAResumeIsAChangedFileAndEmptiesThePart() = runTest {
        write(file.copyOf(100_000))
        val http = FakeHttp(this) { respond(file, HttpStatusCode.OK, headers(HttpHeaders.ContentLength to "${file.size}")) }

        val result = transport(http).transfer(request(offset = 100_000, validator = "\"old\""), RecordingListener())

        assertEquals(TransferResult.Changed, result)
        assertEquals(0, read().size)
    }

    @Test
    fun aPartialAnswerThatDoesNotContinueTheFileIsAChange() = runTest {
        write(file.copyOf(100_000))
        val wrongStart = FakeHttp(this) { respondRange(file, 0, 1000) }
        assertEquals(TransferResult.Changed, transport(wrongStart).transfer(request(offset = 100_000), RecordingListener()))

        write(file.copyOf(100_000))
        val otherTotal = FakeHttp(this) { respondRange(file, 100_000, file.size - 1L, total = file.size + 5L) }
        assertEquals(TransferResult.Changed, transport(otherTotal).transfer(request(offset = 100_000), RecordingListener()))
    }

    @Test
    fun aPartFileShorterThanTheOffsetIsAChange() = runTest {
        write(file.copyOf(10))
        val http = FakeHttp(this) { request -> serveVideo(request, file) }

        assertEquals(TransferResult.Changed, transport(http).transfer(request(offset = 100_000), RecordingListener()))
        assertTrue(http.requests.isEmpty())
    }

    @Test
    fun anHttpErrorIsReportedWithItsStatus() = runTest {
        val http = FakeHttp(this) { respond("gone", HttpStatusCode.Forbidden) }

        assertEquals(TransferResult.Http(403), transport(http).transfer(request(offset = 0), RecordingListener()))
    }

    @Test
    fun aBodyEndingEarlyIsANetworkFailureKeepingWhatArrived() = runTest {
        val http = FakeHttp(this) {
            respond(file.copyOf(1000), HttpStatusCode.PartialContent, headers(HttpHeaders.ContentRange to "bytes 0-${file.size - 1}/${file.size}"))
        }

        val result = transport(http).transfer(request(offset = 0), RecordingListener())

        assertEquals(TransferResult.Network("Truncated"), result)
        assertEquals(1000, read().size)
    }

    @Test
    fun startRunsTheTransferAndReportsItsResult() = runTest {
        val http = FakeHttp(this) { request -> serveVideo(request, file) }
        val listener = RecordingListener()
        val transport = transport(http)

        transport.start(request(offset = 0), listener)
        testScheduler.advanceUntilIdle()

        assertEquals(listOf<TransferResult>(TransferResult.Completed(file.size.toLong(), "\"v1\"")), listener.results)
    }

    @Test
    fun credentialHeadersGoOnlyToTheLinksOrigin() = runTest {
        val credentials = mapOf(
            "Authorization" to "Bearer KEY",
            "Cookie" to "session=KEY",
            "Proxy-Authorization" to "Basic KEY",
            "X-Plex-Token" to "KEY",
            "X-Emby-Token" to "KEY",
        )
        val http = FakeHttp(this) { request ->
            when {
                request.url.host == "mirror.example" -> serveVideo(request, file)
                request.url.encodedPath == "/video.mkv" -> redirect("/moved/video.mkv")
                else -> redirect("https://mirror.example/video.mkv")
            }
        }
        val signedIn = request(offset = 0).copy(headers = credentials + ("User-Agent" to "Plezy/test"))

        val result = transport(http).transfer(signedIn, RecordingListener())

        assertEquals(TransferResult.Completed(file.size.toLong(), "\"v1\""), result)
        val (origin, mirror) = http.requests.partition { it.url.host == "cdn.example" }
        assertEquals(2, origin.size, "the link and its move on the same host")
        for (sent in origin) {
            for ((name, value) in credentials) assertEquals(value, sent.headers[name], "$name to ${sent.url}")
        }
        val moved = mirror.single()
        for (name in credentials.keys) assertNull(moved.headers[name], "$name to ${moved.url}")
        assertEquals("Plezy/test", moved.headers[HttpHeaders.UserAgent])
    }

    @Test
    fun aRedirectFromHttpsToHttpIsRefused() = runTest {
        val http = FakeHttp(this) { request ->
            if (request.url.protocol.name == "https") redirect("http://cdn.example/video.mkv") else serveVideo(request, file)
        }

        assertEquals(TransferResult.Http(302), transport(http).transfer(request(offset = 0), RecordingListener()))
        assertEquals(1, http.requests.size)
    }

    @Test
    fun aStartWhileTheStoppedRunStillUnwindsKeepsTheNewRunsHandleAndResult() = runTest {
        val io = HeldDispatcher(StandardTestDispatcher(testScheduler))
        // Every answer's body stays open with nothing in it: each run waits for bytes until it is stopped.
        val http = FakeHttp(this) { respond(ByteChannel(), HttpStatusCode.OK, headers(HttpHeaders.ContentLength to "${file.size}")) }
        val transport = KtorTransport(http.client, io, SystemFileSystem, testTimeSource)
        val listener = RecordingListener()

        transport.start(request(offset = 0), listener)
        testScheduler.runCurrent()
        assertEquals(1, listener.validators.size, "the first run receives")

        // Stopped, the first run unwinds only after the download started again (a write held up by a slow volume).
        io.held = true
        transport.stop("1")
        transport.start(request(offset = 0), listener)
        io.held = false
        testScheduler.runCurrent()

        assertEquals(2, http.requests.size, "the new run receives")
        assertEquals(emptyList<TransferResult>(), listener.results, "the first run's late result doesn't end the new one")
        transport.stop("1")
        testScheduler.runCurrent()
        assertEquals(listOf<TransferResult>(TransferResult.Stopped), listener.results, "the new run stops, once")
    }

    @Test
    fun adoptAppendsAContinuingBodyAndReplacesAWholeOne() {
        SystemFileSystem.createDirectories(directory)
        val incoming = Path(directory, "video.mkv.part.incoming")
        write(file.copyOf(100_000))
        writeTo(incoming, file.copyOfRange(100_000, file.size))

        val range = "bytes 100000-${file.size - 1}/${file.size}"
        val appended = TransferFiles.adopt(request(offset = 100_000), null, incoming.toString(), 206, range, file.size - 100_000L, "\"e\"", null)

        assertEquals(TransferResult.Completed(file.size.toLong(), "\"e\""), appended)
        assertContentEquals(file, read())
        assertFalse(SystemFileSystem.exists(incoming))

        writeTo(incoming, file)
        val replaced = TransferFiles.adopt(request(offset = 0), null, incoming.toString(), 200, null, file.size.toLong(), null, "Mon, 01 Jan 2024 00:00:00 GMT")
        assertEquals(TransferResult.Completed(file.size.toLong(), "Mon, 01 Jan 2024 00:00:00 GMT"), replaced)
        assertContentEquals(file, read())
        assertFalse(SystemFileSystem.exists(incoming))
    }

    @Test
    fun adoptCallsAWholeBodyForAResumeAChange() {
        SystemFileSystem.createDirectories(directory)
        val incoming = Path(directory, "video.mkv.part.incoming")
        write(file.copyOf(100_000))
        writeTo(incoming, file)

        assertEquals(TransferResult.Changed, TransferFiles.adopt(request(offset = 100_000), null, incoming.toString(), 200, null, file.size.toLong(), null, null))
        assertEquals(0, read().size)
        assertFalse(SystemFileSystem.exists(incoming))

        writeTo(incoming, ByteArray(0))
        assertEquals(TransferResult.Http(410), TransferFiles.adopt(request(offset = 0), null, incoming.toString(), 410, null, null, null, null))
        assertFalse(SystemFileSystem.exists(incoming))
    }

    @Test
    fun `adopt calls a resumed body ending short of the total truncated unless it was a chunk`() {
        SystemFileSystem.createDirectories(directory)
        val incoming = Path(directory, "video.mkv.part.incoming")
        write(file.copyOf(100_000))
        writeTo(incoming, file.copyOfRange(100_000, 200_000))
        val range = "bytes 100000-199999/${file.size}"

        val resumed = TransferFiles.adopt(request(offset = 100_000), null, incoming.toString(), 206, range, 100_000L, "\"e\"", null)
        assertEquals(TransferResult.Network("Truncated"), resumed)

        write(file.copyOf(100_000))
        writeTo(incoming, file.copyOfRange(100_000, 200_000))
        val chunk = TransferFiles.adopt(request(offset = 100_000), 199_999L, incoming.toString(), 206, range, 100_000L, "\"e\"", null)
        assertEquals(TransferResult.Completed(200_000L, "\"e\""), chunk)
        assertContentEquals(file.copyOf(200_000), read())
    }

    /** As [KtorTransport] answers a 200 whose length isn't the expected size: the file changed, the manager restarts it. */
    @Test
    fun adoptCallsAWholeBodyOfAnotherLengthAChange() {
        SystemFileSystem.createDirectories(directory)
        val incoming = Path(directory, "video.mkv.part.incoming")
        val other = file.copyOf(file.size - 1_000)
        writeTo(incoming, other)

        val adopted = TransferFiles.adopt(request(offset = 0), null, incoming.toString(), 200, null, other.size.toLong(), "\"v2\"", null)

        assertEquals(TransferResult.Changed, adopted)
        assertFalse(SystemFileSystem.exists(part) && read().isNotEmpty())
        assertFalse(SystemFileSystem.exists(incoming))
    }

    @Test
    fun aFileTooLargeForTheRoomLeftEndsDiskFullBeforeAByteIsWritten() = runTest {
        val http = FakeHttp(this) { request -> serveVideo(request, file) }
        // Room for the floor (256 MiB of a 10 GiB volume) and 100 000 bytes more: not for the file.
        val room = VolumeCapacity(available = (256L shl 20) + 100_000, total = 10L shl 30)

        val result = transport(http) { room }.transfer(request(offset = 0), RecordingListener())

        assertEquals(TransferResult.DiskFull, result)
        assertFalse(SystemFileSystem.exists(part) && read().isNotEmpty())
    }

    @Test
    fun theVolumeIsSampledOncePerMebibyteWritten() = runTest {
        val large = lcgBytes((3 shl 20) + 1, seed = 3)
        val http = FakeHttp(this) { request -> serveVideo(request, large) }
        var samples = 0

        val result = transport(http) {
            samples++
            VolumeCapacity(available = 1L shl 40, total = 1L shl 41)
        }.transfer(request(offset = 0).copy(expectedSize = large.size.toLong()), RecordingListener())

        assertEquals(TransferResult.Completed(large.size.toLong(), "\"v1\""), result)
        // Once as the answer announces the size, then once before each MiB: 0, 1, 2 and 3 MiB.
        assertTrue(samples in 2..5, "$samples samples")
    }

    @Test
    fun aVolumeFillingUpMidTransferEndsItDiskFull() = runTest {
        val large = lcgBytes(4 shl 20, seed = 4)
        val http = FakeHttp(this) { request -> serveVideo(request, large) }
        var samples = 0

        val result = transport(http) {
            // Another app fills the volume once the transfer is under way.
            if (++samples <= 2) VolumeCapacity(1L shl 40, 1L shl 41) else VolumeCapacity(available = 100L shl 20, total = 1L shl 41)
        }.transfer(request(offset = 0).copy(expectedSize = large.size.toLong()), RecordingListener())

        assertEquals(TransferResult.DiskFull, result)
        assertTrue(read().size < large.size)
    }

    private fun TestScope.transport(http: FakeHttp, capacity: (String) -> VolumeCapacity? = { null }) =
        KtorTransport(http.client, StandardTestDispatcher(testScheduler), SystemFileSystem, testTimeSource, capacity)

    private fun request(offset: Long, validator: String? = null) = TransferRequest(
        id = "1",
        url = "https://cdn.example/video.mkv",
        headers = mapOf("User-Agent" to "Plezy/test"),
        partPath = part.toString(),
        offset = offset,
        expectedSize = file.size.toLong(),
        validator = validator,
        title = "Video",
        wifiOnly = false,
    )

    private fun write(bytes: ByteArray) = writeTo(part, bytes)

    private fun writeTo(path: Path, bytes: ByteArray) {
        SystemFileSystem.createDirectories(directory)
        SystemFileSystem.sink(path).buffered().use { it.write(bytes) }
    }

    private fun read(): ByteArray = SystemFileSystem.source(part).buffered().use { it.readByteArray() }

    private class RecordingListener : TransferListener {
        val progress = mutableListOf<Long>()
        val validators = mutableListOf<String?>()
        val results = mutableListOf<TransferResult>()

        override fun onProgress(id: String, bytes: Long, totalBytes: Long?) {
            progress += bytes
        }

        override fun onResponse(id: String, validator: String?) {
            validators += validator
        }

        override fun onResult(id: String, result: TransferResult) {
            results += result
        }
    }
}
