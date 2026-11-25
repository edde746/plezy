package com.edde746.plezy.servers

import com.edde746.plezy.cast.WebSocketWire
import com.edde746.plezy.crypto.cryptoProvider
import com.edde746.plezy.net.PlezyHttpClient
import dev.whyoleg.cryptography.DelicateCryptographyApi
import dev.whyoleg.cryptography.algorithms.SHA1
import io.ktor.client.plugins.HttpTimeout
import io.ktor.network.selector.SelectorManager
import io.ktor.network.sockets.aSocket
import io.ktor.network.sockets.openReadChannel
import io.ktor.network.sockets.openWriteChannel
import io.ktor.network.sockets.port
import io.ktor.utils.io.writeStringUtf8
import io.ktor.websocket.Frame
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.io.encoding.Base64
import kotlin.test.assertEquals

/**
 * A push connection over the platform's own HTTP engine (OkHttp on Android and the JVM, Darwin on Apple) against a
 * loopback WebSocket server: it stays open past the client's socket timeout and past the first transport ping, as a
 * server's pushes come minutes apart.
 */
class LibraryEventConnectorTest {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val selector = SelectorManager(Dispatchers.IO)
    private val http = PlezyHttpClient.create("test") {
        install(HttpTimeout) { socketTimeoutMillis = SOCKET_TIMEOUT_MS }
    }

    @AfterTest
    fun stop() {
        http.close()
        scope.cancel()
        selector.close()
    }

    @Test
    fun aPushAfterAQuietHalfMinuteArrives() = runBlocking {
        val server = aSocket(selector).tcp().bind("127.0.0.1", 0)
        scope.launch {
            val socket = server.accept()
            val input = socket.openReadChannel()
            val output = socket.openWriteChannel(autoFlush = false)
            val key = WebSocketWire.readRequest(input)?.upgradeKey ?: return@launch socket.close()
            output.writeStringUtf8(
                "HTTP/1.1 101 Switching Protocols\r\nconnection: Upgrade\r\nupgrade: websocket\r\nsec-websocket-accept: ${accept(key)}\r\n\r\n",
            )
            output.flush()
            val session = WebSocketWire.session(socket, input, output, masking = false, scope)
            // Quiet past the client's socket timeout and the engines' 30 s ping, then one push.
            delay(QUIET_MS)
            session.send(Frame.Text("pushed"))
        }
        val connection = KtorLibraryEventConnector(http).connect("ws://127.0.0.1:${server.localAddress.port()}/socket", emptyMap())
        try {
            val frame = withTimeout(QUIET_MS + 20_000) { connection.frames.first() }
            assertEquals("pushed", frame)
        } finally {
            connection.close()
            server.close()
        }
    }

    /** RFC 6455's accept value for [key]: SHA-1 is what the protocol fixes. */
    @OptIn(DelicateCryptographyApi::class)
    private fun accept(key: String): String =
        Base64.encode(cryptoProvider.get(SHA1).hasher().hashBlocking((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encodeToByteArray()))

    private companion object {
        const val SOCKET_TIMEOUT_MS = 500L
        const val QUIET_MS = 35_000L
    }
}
