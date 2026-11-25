package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.net.PlezyHttpClient
import io.ktor.network.selector.SelectorManager
import io.ktor.network.sockets.aSocket
import io.ktor.network.sockets.openReadChannel
import io.ktor.network.sockets.openWriteChannel
import io.ktor.network.sockets.port
import io.ktor.utils.io.readLine
import io.ktor.utils.io.writeStringUtf8
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.JsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** URLSession ignores a connect timeout: the client bounds the connect itself, and only the connect. */
class AppleConnectTimeoutTest {
    private val http = PlezyHttpClient.create("test")

    @Test
    fun anUnreachableServerFailsAtTheConnectTimeout() = runBlocking {
        val client = MediaServerHttpClient(http, "http://10.255.255.1:32400")
        val started = TimeSource.Monotonic.markNow()
        val error = assertFailsWith<MediaServerHttpException> { client.get("/identity") }
        val elapsed = started.elapsedNow()
        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
        assertTrue(elapsed >= 9.seconds && elapsed < 15.seconds, "failed after $elapsed")
    }

    @Test
    fun aReachableServerThatAnswersAfterTheConnectTimeoutStillAnswers() = runBlocking {
        val selector = SelectorManager(Dispatchers.IO)
        val server = aSocket(selector).tcp().bind("127.0.0.1", 0)
        val serving = launch(Dispatchers.IO) {
            while (true) {
                val socket = server.accept()
                launch {
                    socket.use {
                        val input = socket.openReadChannel()
                        if (input.readLine().isNullOrEmpty()) return@launch
                        while (!input.readLine().isNullOrEmpty()) Unit
                        delay(15.seconds)
                        val output = socket.openWriteChannel(autoFlush = true)
                        output.writeStringUtf8("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}")
                        output.flushAndClose()
                    }
                }
            }
        }
        try {
            val client = MediaServerHttpClient(http, "http://127.0.0.1:${server.port}")
            val started = TimeSource.Monotonic.markNow()
            val response = client.get("/identity")
            assertEquals(200, response.statusCode)
            assertEquals(JsonObject(emptyMap()), response.data)
            assertTrue(started.elapsedNow() >= 15.seconds)
        } finally {
            serving.cancel()
            server.close()
            selector.close()
        }
    }
}
