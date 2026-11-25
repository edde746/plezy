package com.edde746.plezy.presentation.settings

import com.edde746.plezy.crash.StartupFailureRecord
import com.edde746.plezy.image.ArtworkDiagnosticsLog
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogBuffer
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.TextContent
import io.ktor.http.headersOf
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * View Logs over this run's log buffer: what the buffer keeps (its size, the level it keeps,
 * clearing), the page's records newest first under the device block, the copied and uploaded text and its limits.
 */
class LogsPageTest {
    private var level = Log.minLevel

    @BeforeTest
    fun emptyBuffer() {
        level = Log.minLevel
        LogBuffer.clear()
    }

    @AfterTest
    fun restoreLevel() {
        Log.minLevel = level
        LogBuffer.clear()
    }

    private fun messages() = LogBuffer.snapshot().map { it.message }

    @Test
    fun theBufferDropsTheOldestRecordsPastItsSize() {
        // Five of these fit the buffer, six don't: each counts 12 bytes plus two a character.
        val record = "x".repeat(LogBuffer.MAX_BYTES / 10 - 10)
        repeat(6) { LogBuffer.append(Log.Level.WARN, "t", "$it$record", null) }
        val kept = LogBuffer.snapshot()
        assertEquals(listOf('1', '2', '3', '4', '5'), kept.map { it.message.first() }, "the oldest went, the rest stay in order")

        // A single record larger than the buffer is still kept.
        LogBuffer.append(Log.Level.WARN, "t", "y".repeat(LogBuffer.MAX_BYTES + 1), null)
        assertEquals(1, LogBuffer.snapshot().size)
    }

    @Test
    fun debugRecordsAreKeptOnlyWithDebugLogging() {
        Log.minLevel = Log.Level.INFO
        Log.d("t") { "hidden" }
        Log.i("t") { "shown" }
        assertEquals(listOf("shown"), messages())

        Log.minLevel = Log.Level.DEBUG
        Log.d("t") { "now shown" }
        assertEquals(listOf("shown", "now shown"), messages())
    }

    private class Logs(val fixture: SettingsFixture, val store: LogsStore) {
        val events = fixture.collect(store.events)
        val state get() = store.state.value
    }

    /** The page over the records [seed] logs (and none from before). */
    private fun TestScope.logs(seed: () -> Unit = {}): Logs {
        val fixture = settingsFixture()
        LogBuffer.clear()
        seed()
        return Logs(fixture, fixture.stores.logs()).also { runCurrent() }
    }

    @Test
    fun recordsShowNewestFirstAndCopyOldestFirstUnderTheDeviceBlock() = runTest {
        val logs = logs {
            Log.i("net") { "first" }
            Log.e("player", IllegalStateException("boom")) { "second" }
        }
        assertEquals(listOf("second", "first"), logs.state.entries.map { it.message })
        assertEquals(listOf("ERROR", "INFO"), logs.state.entries.map { it.level })
        assertTrue(logs.state.entries.first().error!!.contains("boom"))
        assertTrue(logs.state.hasLogs)
        assertTrue(logs.state.header.startsWith("${T.app.title} v"))
        assertTrue("\nVideo decoders: " in logs.state.header)

        val text = logs.store.text()
        assertTrue(text.startsWith(logs.state.header + "\n---\n"))
        val body = text.substringAfter("---\n")
        assertTrue(body.indexOf("net: first") < body.indexOf("player: second"))
        assertTrue("\nError: " in body)

        logs.store.copy()
        assertEquals(listOf(text), logs.fixture.platform.clipboard)
        assertEquals(listOf<SettingsEvent>(SettingsEvent.Message(T.messages.logsCopied)), logs.events)
    }

    @Test
    fun theHeaderNamesTheEffectsTierAndTheDisplayTheAppLogged() = runTest {
        val display = "2560x1440 physical, 1280x720 logical @ 2.00x (budget 2.0x)"
        val logs = logs { ArtworkDiagnosticsLog.log(effects = "full (forced)", display = display) }
        assertTrue("\nEffects: full (forced)\nDisplay: $display\n" in logs.state.header)
        assertEquals(listOf("Display: $display", "Effects: full (forced)"), logs.state.entries.map { it.message })
    }

    @Test
    fun refreshReadsTheBufferAgainAndClearEmptiesIt() = runTest {
        val logs = logs()
        assertFalse(logs.state.hasLogs)
        Log.i("t") { "later" }
        assertEquals(emptyList(), logs.state.entries)
        logs.store.refresh()
        assertEquals(listOf("later"), logs.state.entries.map { it.message })

        logs.store.clear()
        assertEquals(emptyList(), logs.state.entries)
        assertFalse(logs.state.hasLogs)
        assertEquals(emptyList(), LogBuffer.snapshot())
        assertEquals(SettingsEvent.Message(T.messages.logsCleared), logs.events.last())
    }

    @Test
    fun aFailedStartWithoutLogsEnablesCopyUploadAndClearAndClearForgetsIt() = runTest {
        val fixture = settingsFixture()
        LogBuffer.clear()
        val failure = StartupFailureRecord.of(IllegalStateException("database locked"), appVersion = "1.0", platform = "test")
        fixture.graph.startupFailures.record(failure)
        val logs = Logs(fixture, fixture.stores.logs()).also { runCurrent() }
        assertTrue(logs.state.hasLogs, "a failed start alone leaves Copy, Upload and Clear off")
        assertTrue(logs.state.header.endsWith(failure.describe()))
        assertTrue(failure.describe() in logs.store.text())

        logs.store.clear()
        runCurrent()
        assertEquals(null, fixture.graph.startupFailures.pending)
        assertEquals(null, fixture.graph.startupFailures.peek())
        assertFalse(logs.state.hasLogs)
        assertFalse("database locked" in logs.state.header)
    }

    @Test
    fun aFailedUploadSaysSoAndEndsUploading() = runTest {
        val logs = logs { Log.i("t") { "something" } }
        logs.store.upload()
        assertTrue(logs.state.uploading)
        logs.store.state.first { !it.uploading }
        runCurrent()
        assertEquals(SettingsEvent.Message(T.messages.logsUploadFailed, error = true), logs.events.last())
    }

    @Test
    fun anUploadPostsThePlainTextLogAndShowsTheIdTheRelayAnswers() = runTest {
        val fixture = settingsFixture()
        LogBuffer.clear()
        Log.i("net") { "uploaded line" }
        val requests = mutableListOf<HttpRequestData>()
        val http = HttpClient(
            MockEngine { request ->
                requests += request
                respond("""{"id":"k7m2q"}""", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
            },
        )
        val store = LogsPage(http, "1.0", fixture.platform, fixture.graph.startupFailures, backgroundScope)
        val logs = Logs(fixture, store).also { runCurrent() }

        store.upload()
        store.state.first { !it.uploading }
        runCurrent()
        val request = requests.single()
        assertEquals(HttpMethod.Post, request.method)
        assertEquals(LogsPage.UPLOAD_URL, request.url.toString())
        val body = request.body as TextContent
        assertEquals(ContentType.Text.Plain, body.contentType.withoutParameters())
        assertEquals(store.text(), body.text)
        assertEquals(SettingsEvent.LogsUploaded("k7m2q"), logs.events.last())
    }

    @Test
    fun anUploadKeepsTheHeaderAndTheNewestWholeLines() {
        val header = "Plezy test device\n---\n"
        val payload = constrainLogPayload(header, "oldest line that should be removed\nmiddle line that should be removed\nnewest \uD83D\uDE80 line", 52)
        assertTrue(payload.encodeToByteArray().size <= 52)
        assertTrue(payload.startsWith(header))
        assertTrue(payload.endsWith("newest \uD83D\uDE80 line"))
        assertFalse("oldest line" in payload)

        assertEquals("device\n---\none\ntwo", constrainLogPayload("device\n---\n", "one\ntwo", 128))
    }

    @Test
    fun aHeaderPastTheLimitIsCutBetweenCharacters() {
        assertEquals("ab", constrainLogPayload("ab\u00e9", "logs", 3))
        assertEquals("", constrainLogPayload("header", "logs", 0))
    }
}
