package com.edde746.plezy.crash

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.engine.mock.toByteArray
import io.ktor.http.ContentType
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.OutgoingContent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class LogUploadTest {
    @Test
    fun `the text goes to the log relay as plain text and its log id comes back`() = runTest {
        var method: HttpMethod? = null
        var url = ""
        var type: ContentType? = null
        var sent = ""
        val http = HttpClient(
            MockEngine { request ->
                method = request.method
                url = request.url.toString()
                type = (request.body as OutgoingContent).contentType
                sent = request.body.toByteArray().decodeToString()
                respond("""{"id":"ab12cd"}""", HttpStatusCode.OK)
            },
        )

        assertEquals("ab12cd", LogUpload.upload("Plezy could not start\nphase: database", http))

        assertEquals(HttpMethod.Post, method)
        assertEquals("https://ice.plezy.app/logs", url)
        assertEquals(ContentType.Text.Plain, type?.withoutParameters())
        assertEquals("Plezy could not start\nphase: database", sent)
    }

    @Test
    fun `a refused upload or an answer without an id fails`() = runTest {
        for ((status, body) in listOf(HttpStatusCode.PayloadTooLarge to "too large", HttpStatusCode.OK to """{"error":"x"}""")) {
            val http = HttpClient(MockEngine { respond(body, status) })
            assertFailsWith<IllegalStateException> { LogUpload.upload("text", http) }
        }
    }

    @Test
    fun `text past one mebibyte is cut there without splitting a character`() {
        val short = "é".repeat(10)
        assertEquals(short, LogUpload.fit(short))

        val fitted = LogUpload.fit("a" + "é".repeat(LogUpload.MAX_BYTES))
        val size = fitted.encodeToByteArray().size
        assertTrue(size <= LogUpload.MAX_BYTES && size >= LogUpload.MAX_BYTES - 1)
        assertTrue(fitted.startsWith("aé") && fitted.drop(1).all { it == 'é' })
    }
}
