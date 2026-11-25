package com.edde746.plezy.cast

import com.edde746.plezy.crypto.cryptoProvider
import dev.whyoleg.cryptography.DelicateCryptographyApi
import dev.whyoleg.cryptography.algorithms.SHA1
import dev.whyoleg.cryptography.random.CryptographyRandom
import io.ktor.network.sockets.InetSocketAddress
import io.ktor.network.sockets.Socket
import io.ktor.network.sockets.openReadChannel
import io.ktor.network.sockets.openWriteChannel
import io.ktor.utils.io.ByteReadChannel
import io.ktor.utils.io.ByteWriteChannel
import io.ktor.utils.io.InternalAPI
import io.ktor.utils.io.LineEnding
import io.ktor.utils.io.readLineStrict
import io.ktor.utils.io.writeStringUtf8
import io.ktor.websocket.DefaultWebSocketSession
import io.ktor.websocket.PINGER_DISABLED
import io.ktor.websocket.RawWebSocket
import kotlin.io.encoding.Base64
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.SendChannel
import kotlinx.coroutines.launch
import io.ktor.websocket.CloseReason
import io.ktor.websocket.Frame

/**
 * Plain RFC 6455 over a TCP socket: a cast sender opens `ws://ip:port/cast`, the receiver upgrades that path only, and
 * neither negotiates an extension. Ktor's framing does the rest (masking, fragments, pings, the closing handshake).
 */
internal object WebSocketWire {
    /** RFC 6455's GUID, which every standard peer hashes the key with. */
    private const val GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    private const val MAX_HEAD_LINE = 8192
    private const val MAX_HEAD_LINES = 100
    const val CLOSE_TIMEOUT_MS: Long = 5_000

    /** An HTTP request's head: its target's path and its headers (names lower-cased). */
    class RequestHead(val method: String, val path: String, val headers: Map<String, String>) {
        /** The client's key when this is a valid WebSocket upgrade; null otherwise. */
        val upgradeKey: String?
            get() {
                if (method != "GET") return null
                val connection = headers["connection"]?.split(',')?.map { it.trim().lowercase() }.orEmpty()
                if ("upgrade" !in connection) return null
                if (headers["upgrade"]?.lowercase() != "websocket") return null
                if (headers["sec-websocket-version"] != "13") return null
                return headers["sec-websocket-key"]
            }
    }

    /** Reads a request head; null when the connection ends first or the head is malformed or too large. */
    suspend fun readRequest(input: ByteReadChannel): RequestHead? {
        val requestLine = input.readHeadLine() ?: return null
        val parts = requestLine.split(' ')
        if (parts.size != 3 || !parts[2].startsWith("HTTP/1.")) return null
        val headers = readHeaders(input) ?: return null
        val path = parts[1].substringBefore('?').substringBefore('#')
        return RequestHead(parts[0], path, headers)
    }

    private suspend fun readHeaders(input: ByteReadChannel): Map<String, String>? {
        val headers = LinkedHashMap<String, String>()
        repeat(MAX_HEAD_LINES) {
            val line = input.readHeadLine() ?: return null
            if (line.isEmpty()) return headers
            val colon = line.indexOf(':')
            if (colon <= 0) return null
            val name = line.substring(0, colon).trim().lowercase()
            val value = line.substring(colon + 1).trim()
            headers[name] = headers[name]?.let { "$it, $value" } ?: value
        }
        return null
    }

    /** One line of an HTTP head; throws when it runs past [MAX_HEAD_LINE] bytes. */
    private suspend fun ByteReadChannel.readHeadLine(): String? = readLineStrict(MAX_HEAD_LINE.toLong(), LineEnding.Lenient)

    suspend fun respond(output: ByteWriteChannel, status: Int, reason: String) {
        output.writeStringUtf8("HTTP/1.1 $status $reason\r\ncontent-length: 0\r\nconnection: close\r\n\r\n")
        output.flush()
    }

    suspend fun acceptUpgrade(output: ByteWriteChannel, key: String) {
        output.writeStringUtf8(
            "HTTP/1.1 101 Switching Protocols\r\nconnection: Upgrade\r\nupgrade: websocket\r\nsec-websocket-accept: ${acceptValue(key)}\r\n\r\n",
        )
        output.flush()
    }

    /** RFC 6455's accept value: SHA-1 is what the protocol fixes, not a choice of ours. */
    @OptIn(DelicateCryptographyApi::class)
    fun acceptValue(key: String): String = Base64.encode(cryptoProvider.get(SHA1).hasher().hashBlocking((key + GUID).encodeToByteArray()))

    /** Opens [path] on [socket] as a client; throws [UpgradeRefused] or an I/O error when the host doesn't upgrade. */
    suspend fun clientHandshake(socket: Socket, host: String, path: String, scope: CoroutineScope): WebSocket {
        val input = socket.openReadChannel()
        val output = socket.openWriteChannel(autoFlush = false)
        val key = Base64.encode(CryptographyRandom.nextBytes(16))
        output.writeStringUtf8(
            "GET $path HTTP/1.1\r\nhost: $host\r\nconnection: Upgrade\r\nupgrade: websocket\r\nsec-websocket-version: 13\r\nsec-websocket-key: $key\r\n\r\n",
        )
        output.flush()
        val status = input.readHeadLine() ?: throw UpgradeRefused("the connection closed during the handshake")
        val code = status.split(' ').getOrNull(1)?.toIntOrNull()
        val headers = readHeaders(input) ?: throw UpgradeRefused("malformed handshake response")
        if (code != 101) throw UpgradeRefused("Connection to 'ws://$host$path' was not upgraded to websocket, HTTP status code: $code")
        if (headers["sec-websocket-accept"] != acceptValue(key)) throw UpgradeRefused("bad Sec-WebSocket-Accept")
        return session(socket, input, output, masking = true, scope)
    }

    /** The WebSocket over an upgraded [socket]; the socket closes when the session ends. */
    @OptIn(InternalAPI::class)
    fun session(socket: Socket, input: ByteReadChannel, output: ByteWriteChannel, masking: Boolean, scope: CoroutineScope): WebSocket {
        val job = Job(scope.coroutineContext[Job])
        job.invokeOnCompletion { socket.close() }
        val raw = RawWebSocket(input, output, masking = masking, coroutineContext = scope.coroutineContext + job)
        val session = DefaultWebSocketSession(raw, PINGER_DISABLED, CLOSE_TIMEOUT_MS)
        session.start()
        session.coroutineContext[Job]?.invokeOnCompletion { job.cancel() }
        val outbox = Channel<Frame>(Channel.UNLIMITED)
        CoroutineScope(scope.coroutineContext + job).launch {
            for (frame in outbox) session.outgoing.send(frame)
        }
        return WebSocket(session, outbox)
    }

    /**
     * An open WebSocket and the queue its frames go out through, in the order they were queued however many wait
     * (the session's own channel holds only a few).
     */
    class WebSocket(val session: DefaultWebSocketSession, private val outbox: SendChannel<Frame>) {
        fun send(frame: Frame): Boolean = outbox.trySend(frame).isSuccess

        /** Queues the closing handshake behind every frame already queued. */
        fun close(code: Short, reason: String) {
            outbox.trySend(Frame.Close(CloseReason(code, reason)))
            outbox.close()
        }
    }

    /** The IPv4 (or IPv6) text of a peer's address, without a name lookup. */
    fun ipOf(address: io.ktor.network.sockets.SocketAddress): String {
        val inet = address as? InetSocketAddress ?: return "unknown"
        val bytes = inet.resolveAddress() ?: return inet.hostname
        val v4 = when {
            bytes.size == 4 -> bytes
            bytes.size == 16 && (0..9).all { bytes[it] == 0.toByte() } && bytes[10] == (-1).toByte() && bytes[11] == (-1).toByte() -> bytes.copyOfRange(12, 16)
            else -> null
        }
        return v4?.joinToString(".") { (it.toInt() and 0xFF).toString() } ?: inet.hostname
    }

    class UpgradeRefused(message: String) : Exception(message)
}
