package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.engine.mock.respondRedirect
import io.ktor.client.engine.mock.toByteArray
import io.ktor.client.plugins.HttpTimeout
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.Url
import io.ktor.http.headersOf
import io.ktor.utils.io.ByteChannel
import io.ktor.utils.io.writeFully
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Runnable
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.readByteArray
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.coroutines.CoroutineContext
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class MediaServerHttpClientTest {
    private val connect = 10.seconds
    private val response = 30.seconds
    private val receive = 120.seconds

    private fun MockServer.client(
        baseUrl: String = "https://example.test/",
        defaultHeaders: Map<String, String> = emptyMap(),
        dispatcher: CoroutineDispatcher = http.engine.dispatcher,
    ) = MediaServerHttpClient(http, baseUrl, defaultHeaders, connect, response, receive, dispatcher)

    private fun MediaServerHttpException.assertType(type: MediaServerHttpErrorType) = assertEquals(type, this.type, toString())

    private fun Result<*>.failure(): MediaServerHttpException = exceptionOrNull() as? MediaServerHttpException
        ?: throw AssertionError("expected a MediaServerHttpException, got $this")

    // URL building (Plex hub keys carry the library in their query; pagination must join it with `&`).

    private val offline = MediaServerHttpClient(HttpClient(MockEngine { error("buildUri sends nothing") }), "https://plex.example.com")

    @Test
    fun buildUriMergesParametersIntoAPathThatAlreadyHasAQuery() {
        val uri = offline.buildUri(
            "/hubs/home/recentlyAdded?type=2&sectionID=2",
            mapOf("X-Plex-Container-Start" to 0, "X-Plex-Container-Size" to 200),
        )

        assertEquals("2", uri.parameters["type"])
        assertEquals("2", uri.parameters["sectionID"])
        assertEquals("0", uri.parameters["X-Plex-Container-Start"])
        assertEquals("200", uri.parameters["X-Plex-Container-Size"])
        assertEquals("https://plex.example.com/hubs/home/recentlyAdded", "${uri.protocol.name}://${uri.host}${uri.encodedPath}")
    }

    @Test
    fun buildUriKeepsASingleQuestionMarkForAPlainPath() {
        val uri = offline.buildUri("/library/sections/2/all", mapOf("sort" to "addedAt:desc"))

        assertEquals("/library/sections/2/all", uri.encodedPath)
        assertEquals("addedAt:desc", uri.parameters["sort"])
        assertEquals(1, uri.toString().count { it == '?' })
    }

    @Test
    fun buildUriLeavesAQueryBearingPathUntouchedWithoutExtraParameters() {
        val uri = offline.buildUri("/library/sections/2/all?genre=5")

        assertEquals("/library/sections/2/all", uri.encodedPath)
        assertEquals("5", uri.parameters["genre"])
    }

    @Test
    fun buildUriUsesAnAbsoluteUrlAsItIs() {
        assertEquals(Url("https://other.example/x?y=1&z=2"), offline.buildUri("https://other.example/x?y=1", mapOf("z" to 2)))
    }

    // Request shape.

    @Test
    fun perRequestHeadersWinOverDefaultHeaders() = runTest {
        val server = MockServer(this) { respond("", HttpStatusCode.NoContent) }
        val client = server.client(defaultHeaders = mapOf("X-Plex-Token" to "default", "X-Client" to "plezy"))

        client.get("/identity", headers = mapOf("x-plex-token" to "request"))

        val sent = server.requests.single().headers
        assertEquals(listOf("request"), sent.getAll("X-Plex-Token"))
        assertEquals("plezy", sent["X-Client"])
    }

    @Test
    fun aJsonBodyIsSentAsJsonUnlessTheCallerChoseAContentType() = runTest {
        val server = MockServer(this) { respond("", HttpStatusCode.NoContent) }
        val client = server.client()
        val body = buildJsonObject { put("a", 1) }

        client.post("/Sessions/Playing", body = body)
        client.post("/Sessions/Playing", body = body, headers = mapOf("Content-Type" to "application/vnd.api+json"))

        val (plain, chosen) = server.requests
        assertEquals(ContentType.Application.Json, plain.body.contentType?.withoutParameters())
        assertEquals("""{"a":1}""", plain.body.toByteArray().decodeToString())
        assertEquals(ContentType.parse("application/vnd.api+json"), chosen.body.contentType?.withoutParameters())
    }

    // Response decoding.

    @Test
    fun aMalformedJsonBodyKeepsItsStatusRawTextAndPath() = runTest {
        val server = MockServer(this) { respondJson("{bad json", HttpStatusCode.Unauthorized) }

        val error = assertFailsWith<MediaServerHttpException> { server.client("https://example.test").get("/Users/Me") }

        assertEquals(401, error.statusCode)
        assertEquals(JsonPrimitive("{bad json"), error.responseData)
        assertEquals("/Users/Me", error.requestUri?.encodedPath)
    }

    @Test
    fun aMalformedSuccessfulJsonBodyKeepsTheSuccessStatus() = runTest {
        val server = MockServer(this) { respondJson("{bad json") }

        val error = assertFailsWith<MediaServerHttpException> { server.client().get("/Items") }

        assertEquals(200, error.statusCode)
        error.assertType(MediaServerHttpErrorType.UNKNOWN)
    }

    @Test
    fun aLowercaseContentTypeHeaderNameStillMarksJson() = runTest {
        val server = MockServer(this) { respond("{bad json", HttpStatusCode.Unauthorized, headersOf("content-type", "application/json")) }

        val error = assertFailsWith<MediaServerHttpException> { server.client().get("/Users/Me") }

        assertEquals(401, error.statusCode)
        assertEquals(JsonPrimitive("{bad json"), error.responseData)
    }

    @Test
    fun profiledAndMixedCaseJsonContentTypesAreDecoded() = runTest {
        for (contentType in listOf("application/json; profile=\"PascalCase\"", "Application/JSON")) {
            val server = MockServer(this) { respond("""{"ok":true}""", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, contentType)) }

            val answer = server.client().get("/Items")

            assertEquals(buildJsonObject { put("ok", true) }, answer.data, contentType)
        }
    }

    @Test
    fun aNonJsonBodyIsTextAndAnEmptyBodyIsNothing() = runTest {
        val server = MockServer(this) { request ->
            if (request.url.encodedPath == "/text") {
                respond("hello", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "text/plain"))
            } else {
                respond("", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
            }
        }
        val client = server.client()

        val text = client.get("/text")
        val empty = client.get("/empty")

        assertNull(text.data)
        assertEquals("hello", text.text)
        assertNull(empty.data)
        assertNull(empty.text)
    }

    // A request runs on the client's dispatcher, its caller resumed once with the answer: a caller busy drawing a frame
    // never holds up its steps.

    /** Holds every dispatched block until [runParked], so a test sees whether work was handed to it. */
    private class ParkingDispatcher : CoroutineDispatcher() {
        val parked = ArrayDeque<Runnable>()

        override fun dispatch(context: CoroutineContext, block: Runnable) {
            parked += block
        }

        fun runParked() {
            while (parked.isNotEmpty()) parked.removeFirst().run()
        }
    }

    @Test
    fun aRequestRunsOnTheClientDispatcherNotItsCallers() = runTest {
        val server = MockServer(this) { respondJson("""{"ok":true}""") }
        val parking = ParkingDispatcher()

        val answer = async { server.client(dispatcher = parking).get("/Items") }
        runCurrent()

        assertTrue(server.requests.isEmpty(), "nothing is sent before the client's dispatcher runs the request")
        assertTrue(parking.parked.isNotEmpty())
        repeat(10) {
            parking.runParked()
            runCurrent()
        }
        assertEquals(buildJsonObject { put("ok", true) }, answer.await().data)
    }

    @Test
    fun throwIfHttpErrorKeepsTheStatusBodyAndRequestUri() = runTest {
        val server = MockServer(this) { respondJson("""{"error":"nope"}""", HttpStatusCode.InternalServerError) }
        val answer = server.client().get("/System/Info")

        val error = assertFailsWith<MediaServerHttpException> { throwIfHttpError(answer) }

        assertEquals(500, error.statusCode)
        assertEquals("/System/Info", error.requestUri?.encodedPath)
        assertEquals(buildJsonObject { put("error", "nope") }, error.responseData)
    }

    @Test
    fun theEffectiveUriIsWhereRedirectsEnded() = runTest {
        val server = MockServer(this) { request ->
            if (request.url.encodedPath == "/start") respondRedirect("https://example.test/final") else respondJson("{}")
        }

        val answer = server.client().get("/start")

        assertEquals("/start", answer.requestUri.encodedPath)
        assertEquals("/final", answer.effectiveUri.encodedPath)
    }

    // Timing: the wait for headers is bounded by connect + response, the body by receive.

    @Test
    fun aServerThatAnswersAfterTheConnectBudgetIsStillWaitedFor() = runTest {
        val server = MockServer(this) {
            delay(15.seconds)
            respondJson("""{"Items":[]}""")
        }
        val answer = async { runCatching { server.client().get("/Items") } }

        advanceTimeBy(15.seconds)
        runCurrent()

        assertEquals(200, answer.await().getOrThrow().statusCode)
    }

    @Test
    fun aServerThatNeverAnswersTimesOutOnceConnectAndResponseBudgetsAreSpent() = runTest {
        val server = MockServer(this) { awaitCancellation() }
        val answer = async { runCatching { server.client().get("/Items") } }

        advanceTimeBy(connect + response - 1.seconds)
        runCurrent()
        assertFalse(answer.isCompleted)

        advanceTimeBy(1.seconds)
        runCurrent()
        answer.await().failure().assertType(MediaServerHttpErrorType.CONNECTION_TIMEOUT)
    }

    @Test
    fun aBodyStillGetsTheReceiveBudgetOnceTheHeadersArrived() = runTest {
        val body = ByteChannel(autoFlush = true)
        val server = MockServer(this) { respond(body, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json")) }
        launch {
            delay(connect + response + 30.seconds)
            body.writeFully("[]".encodeToByteArray())
            body.flushAndClose()
        }
        val answer = async { runCatching { server.client().get("/Items") } }

        advanceTimeBy(connect + response + 30.seconds)
        runCurrent()

        val result = answer.await().getOrThrow()
        assertEquals(200, result.statusCode)
        assertEquals(JsonArray(emptyList()), result.data)
    }

    @Test
    fun aBodyThatNeverEndsTimesOutAtTheReceiveBudget() = runTest {
        val body = ByteChannel(autoFlush = true)
        val server = MockServer(this) { respond(body, HttpStatusCode.OK) }
        val answer = async { runCatching { server.client().get("/Items") } }

        advanceTimeBy(receive - 1.seconds)
        runCurrent()
        assertFalse(answer.isCompleted)

        advanceTimeBy(1.seconds)
        runCurrent()
        answer.await().failure().assertType(MediaServerHttpErrorType.CONNECTION_TIMEOUT)
    }

    @Test
    fun aPerRequestTimeoutStillBoundsTheWholeWaitForHeaders() = runTest {
        val server = MockServer(this) {
            delay(3.seconds)
            respondJson("{}")
        }
        val answer = async { runCatching { server.client().get("/identity", timeout = 2.seconds) } }

        advanceTimeBy(2.seconds)
        runCurrent()

        answer.await().failure().assertType(MediaServerHttpErrorType.CONNECTION_TIMEOUT)
    }

    @Test
    fun aTimeoutAbortsTheUnderlyingRequest() = runTest {
        var aborted = false
        val server = MockServer(this) {
            try {
                awaitCancellation()
            } finally {
                aborted = true
            }
        }
        val answer = async { runCatching { server.client().get("/slow", timeout = 1.milliseconds) } }

        advanceTimeBy(1.milliseconds)
        runCurrent()

        answer.await().failure().assertType(MediaServerHttpErrorType.CONNECTION_TIMEOUT)
        assertTrue(aborted)
    }

    // getBytes: the body arrives intact whatever Content-Length claims; maxBytes bounds what is read (a BIF scrub
    // preview is tens of MB, and buffering it whole ran 32-bit Android TV boxes out of memory).

    private val chunks = listOf(byteArrayOf(1, 2, 3), byteArrayOf(4, 5), byteArrayOf(6, 7, 8, 9))
    private val body = ByteArray(9) { (it + 1).toByte() }

    private fun TestScope.chunkedServer(contentLength: Long?, parts: List<ByteArray> = chunks) = MockServer(this) {
        val channel = ByteChannel()
        launch {
            for (part in parts) {
                channel.writeFully(part)
                channel.flush()
            }
            channel.flushAndClose()
        }
        val headers = if (contentLength == null) headersOf() else headersOf(HttpHeaders.ContentLength, "$contentLength")
        respond(channel, HttpStatusCode.OK, headers)
    }

    private suspend fun TestScope.fetch(contentLength: Long? = null, parts: List<ByteArray> = chunks, maxBytes: Long? = null): ByteArray =
        chunkedServer(contentLength, parts).client().getBytes("/index.bif", maxBytes = maxBytes)

    private fun assertTooLarge(error: MediaServerHttpException) {
        assertFalse(error.isTransient)
        assertFalse(error.isCancellation)
    }

    @Test
    fun aBodyMatchingItsContentLengthArrivesIntactAcrossChunks() = runTest {
        assertContentEquals(body, fetch(contentLength = 9))
    }

    @Test
    fun aBodyWithoutContentLengthArrivesIntact() = runTest {
        assertContentEquals(body, fetch())
    }

    @Test
    fun aBodyLongerThanItsContentLengthKeepsEveryByteInOrder() = runTest {
        assertContentEquals(body, fetch(contentLength = 4))
    }

    @Test
    fun aBodyShorterThanItsContentLengthReturnsOnlyTheReceivedBytes() = runTest {
        assertContentEquals(body, fetch(contentLength = 20))
    }

    @Test
    fun anEmptyBodyWithContentLengthZeroIsEmpty() = runTest {
        assertContentEquals(ByteArray(0), fetch(contentLength = 0, parts = emptyList()))
    }

    @Test
    fun aBodyExactlyAtTheLimitArrivesIntact() = runTest {
        assertContentEquals(body, fetch(contentLength = 9, maxBytes = 9))
        assertContentEquals(body, fetch(maxBytes = 9))
    }

    @Test
    fun aDeclaredContentLengthOverTheLimitFailsWithoutWaitingForTheBody() = runTest {
        // The body never arrives, so a client that tried to read it would hang.
        val unread = ByteChannel()
        val server = MockServer(this) { respond(unread, HttpStatusCode.OK, headersOf(HttpHeaders.ContentLength, "${1L shl 30}")) }

        assertTooLarge(assertFailsWith<MediaServerHttpException> { server.client().getBytes("/index.bif", maxBytes = 1024) })
        // Cancelled rather than left unread, which would park the connection.
        assertTrue(unread.isClosedForWrite)
    }

    @Test
    fun aBodyThatOutgrowsItsContentLengthFailsOncePastTheLimit() = runTest {
        assertTooLarge(assertFailsWith<MediaServerHttpException> { fetch(contentLength = 4, maxBytes = 8) })
    }

    @Test
    fun anUndeclaredBodyStopsBeingReadOnceItPassesTheLimit() = runTest {
        val chunkCount = 1000
        var produced = 0
        val server = MockServer(this) {
            val channel = ByteChannel()
            launch {
                runCatching {
                    repeat(chunkCount) {
                        produced++
                        channel.writeFully(ByteArray(64 * 1024))
                        channel.flush()
                    }
                    channel.flushAndClose()
                }
            }
            respond(channel, HttpStatusCode.OK)
        }

        assertTooLarge(assertFailsWith<MediaServerHttpException> { server.client().getBytes("/index.bif", maxBytes = 10) })
        runCurrent()
        assertTrue(produced < chunkCount, "produced $produced chunks")
    }

    @Test
    fun aBinaryFetchAnsweredWithAnErrorStatusThrowsWithThatStatus() = runTest {
        val server = MockServer(this) { respond("Not Found", HttpStatusCode.NotFound) }

        val error = assertFailsWith<MediaServerHttpException> { server.client().getBytes("/index.bif") }

        assertEquals(404, error.statusCode)
    }

    @Test
    fun aJsonAnswerPastTheBodyLimitFailsAndStopsBeingRead() = runTest {
        val chunk = ByteArray(1024 * 1024) { ' '.code.toByte() }
        val chunkCount = 100
        var produced = 0
        val server = MockServer(this) {
            val channel = ByteChannel()
            launch {
                runCatching {
                    channel.writeFully("[".encodeToByteArray())
                    repeat(chunkCount) {
                        produced++
                        channel.writeFully(chunk)
                        channel.flush()
                    }
                    channel.writeFully("]".encodeToByteArray())
                    channel.flushAndClose()
                }
            }
            respond(channel, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
        }

        val error = assertFailsWith<MediaServerHttpException> { server.client().get("library/sections/1/all") }
        runCurrent()

        assertFalse(error.isTransient)
        assertFalse(error.isCancellation)
        assertTrue(produced < chunkCount, "produced $produced MiB")
    }

    // Shutdown: what close() cuts off is a cancellation, never a transient failure or an empty success.

    @Test
    fun aClosedClientRejectsNewRequestsAsACancellation() = runTest {
        val server = MockServer(this) { respondJson("{}") }
        val client = server.client()
        client.close()

        val error = assertFailsWith<MediaServerHttpException> { client.get("library/sections") }

        error.assertType(MediaServerHttpErrorType.CANCELLED)
        assertFalse(error.isTransient)
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun closeAbortsRequestsAlreadyInFlightAtTheTransport() = runTest {
        var aborted = false
        val server = MockServer(this) {
            try {
                awaitCancellation()
            } finally {
                aborted = true
            }
        }
        val client = server.client()
        val pending = async { runCatching { client.get("library/sections") } }
        runCurrent()

        client.close()
        runCurrent()

        assertTrue(aborted)
        pending.await().failure().assertType(MediaServerHttpErrorType.CANCELLED)
    }

    @Test
    fun aRequestStartingWhileTheClientClosesIsCancelledToo() = runTest {
        repeat(200) {
            val http = HttpClient(MockEngine { awaitCancellation() }) { install(HttpTimeout) }
            val client = MediaServerHttpClient(http, "https://example.test/")
            val outcome = withContext(Dispatchers.Default) {
                val request = async { runCatching { client.get("library/sections") } }
                client.close()
                // A request close() missed would wait out its 40 s response budget.
                withTimeout(5.seconds) { request.await() }
            }
            outcome.failure().assertType(MediaServerHttpErrorType.CANCELLED)
            http.close()
        }
    }

    @Test
    fun shutdownDuringAStreamingBodySurfacesAsCancelledNotAnEmptySuccess() = runTest {
        val body = ByteChannel(autoFlush = true)
        val client = MockServer(this) { respond(body, HttpStatusCode.OK) }.client()
        val pending = async { runCatching { client.get("library/sections") } }
        runCurrent()
        body.writeFully(byteArrayOf(1, 2, 3))
        runCurrent()

        val closing = async { client.closeGracefully(drainTimeout = 100.milliseconds) }
        runCurrent()

        pending.await().failure().assertType(MediaServerHttpErrorType.CANCELLED)
        closing.await()
    }

    @Test
    fun aCancelledDownloadCommitsNoFileAndLeavesNoTempFile() = runTest {
        withTempDir { dir ->
            val target = Path(dir, "subtitle.srt")
            val body = ByteChannel(autoFlush = true)
            val client = MockServer(this) { respond(body, HttpStatusCode.OK) }.client()
            val pending = async { runCatching { client.downloadFile("media/subtitle.srt", target.toString()) } }
            runCurrent()
            body.writeFully(byteArrayOf(1, 2, 3))
            // Let the partial chunk reach the file before the abort lands.
            runCurrent()

            val closing = async { client.closeGracefully(drainTimeout = 100.milliseconds) }
            runCurrent()

            pending.await().failure().assertType(MediaServerHttpErrorType.CANCELLED)
            closing.await()
            assertFalse(SystemFileSystem.exists(target), "a cancelled download must not commit the final file")
            assertFalse(SystemFileSystem.exists(Path("$target.download")), "the partial temp file must be cleaned up")
        }
    }

    @Test
    fun aFinishedDownloadReplacesTheFileAtItsPath() = runTest {
        withTempDir { dir ->
            val target = Path(dir, "subtitle.srt")
            SystemFileSystem.sink(target).buffered().use { it.write(byteArrayOf(9, 9, 9, 9, 9)) }
            val client = MockServer(this) { respond(body, HttpStatusCode.OK) }.client()

            client.downloadFile("media/subtitle.srt", target.toString())

            assertContentEquals(body, SystemFileSystem.source(target).buffered().use { it.readByteArray() })
            assertFalse(SystemFileSystem.exists(Path("$target.download")))
        }
    }

    @Test
    fun aDownloadAnsweredWithAnErrorStatusThrowsAndWritesNothing() = runTest {
        withTempDir { dir ->
            val target = Path(dir, "subtitle.srt")
            val client = MockServer(this) { respond("missing", HttpStatusCode.NotFound) }.client()

            val error = assertFailsWith<MediaServerHttpException> { client.downloadFile("media/subtitle.srt", target.toString()) }

            assertEquals(404, error.statusCode)
            assertFalse(SystemFileSystem.exists(target))
            assertFalse(SystemFileSystem.exists(Path("$target.download")))
        }
    }

    private suspend fun withTempDir(block: suspend (Path) -> Unit) {
        val dir = Path(SystemTemporaryDirectory, "plezy-http-test-${Random.nextLong().toULong()}")
        SystemFileSystem.createDirectories(dir)
        try {
            block(dir)
        } finally {
            SystemFileSystem.list(dir).forEach { SystemFileSystem.delete(it) }
            SystemFileSystem.delete(dir)
        }
    }
}
