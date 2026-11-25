package com.edde746.plezy.cast

import com.edde746.plezy.log.Log
import io.ktor.network.selector.SelectorManager
import io.ktor.network.sockets.ServerSocket
import io.ktor.network.sockets.Socket
import io.ktor.network.sockets.aSocket
import io.ktor.network.sockets.openReadChannel
import io.ktor.network.sockets.openWriteChannel
import io.ktor.network.sockets.port
import io.ktor.websocket.CloseReason
import io.ktor.websocket.Frame
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withTimeoutOrNull

/** The bounds of a receiver's socket server; tests shorten them. */
internal data class ServerLimits(
    val maxConnections: Int = 32,
    val maxConnectionsPerSource: Int = 5,
    /** How long a connection may take to send its upgrade request. */
    val upgradeTimeoutMs: Long = 10_000,
    val preferredPort: Int = CastServer.PORT,
)

/**
 * A receiver's WebSocket server: it serves `/cast` only, and hands each upgraded connection to [accept]. A
 * connection takes its slot (at most [ServerLimits.maxConnections], [ServerLimits.maxConnectionsPerSource] per
 * address) before a byte is read, and keeps it until it ends. Its state lives on [scope], which runs on one thread.
 */
internal class CastServer(
    private val selector: SelectorManager,
    private val scope: CoroutineScope,
    private val limits: ServerLimits = ServerLimits(),
) : CastEndpoint {
    private var server: ServerSocket? = null
    private var acceptJob: Job? = null
    private var accept: (FrameTransport) -> Unit = { it.close() }
    private var open = 0
    private val bySource = HashMap<String, Int>()

    /** Listens on [ServerLimits.preferredPort], else a free one, handing connections to [accept]; returns the port. */
    override suspend fun open(accept: (FrameTransport) -> Unit): Int {
        close()
        this.accept = accept
        val bound = try {
            aSocket(selector).tcp().bind("0.0.0.0", limits.preferredPort) { reuseAddress = true }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Port ${limits.preferredPort} is taken; using a free one" }
            aSocket(selector).tcp().bind("0.0.0.0", 0)
        }
        server = bound
        acceptJob = scope.launch {
            while (true) {
                val socket = try {
                    bound.accept()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    if (server === bound) Log.w(TAG, e) { "Accept failed" }
                    return@launch
                }
                launch { serve(socket) }
            }
        }
        return bound.port
    }

    override fun close() {
        acceptJob?.cancel()
        acceptJob = null
        server?.close()
        server = null
    }

    private suspend fun serve(socket: Socket) {
        val source = WebSocketWire.ipOf(socket.remoteAddress)
        val fromSource = bySource[source] ?: 0
        if (open >= limits.maxConnections || fromSource >= limits.maxConnectionsPerSource) {
            socket.close()
            return
        }
        open++
        bySource[source] = fromSource + 1
        var transport: SocketTransport? = null
        try {
            val input = socket.openReadChannel()
            val output = socket.openWriteChannel(autoFlush = false)
            val head = withTimeoutOrNull(limits.upgradeTimeoutMs) { WebSocketWire.readRequest(input) } ?: return
            if (head.path != CAST_PATH) return WebSocketWire.respond(output, 404, "Not Found")
            val key = head.upgradeKey ?: return WebSocketWire.respond(output, 400, "Bad Request")
            WebSocketWire.acceptUpgrade(output, key)
            transport = SocketTransport(WebSocketWire.session(socket, input, output, masking = false, scope), source)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "A connection failed before its upgrade" }
        } finally {
            val ending = transport?.ws?.session?.coroutineContext?.get(Job)
            if (ending == null) {
                socket.close()
                release(source)
            } else {
                ending.invokeOnCompletion { scope.launch { release(source) } }
            }
        }
        transport?.let(accept)
    }

    private fun release(source: String) {
        open--
        val left = (bySource[source] ?: 1) - 1
        if (left <= 0) bySource.remove(source) else bySource[source] = left
    }

    companion object {
        const val PORT: Int = 48640
        private const val TAG = "CastServer"
    }
}

/** An upgraded socket as a [FrameTransport]. */
private class SocketTransport(val ws: WebSocketWire.WebSocket, override val remoteAddress: String) : FrameTransport {
    override val incoming: ReceiveChannel<Frame> get() = ws.session.incoming

    override fun send(frame: Frame): Boolean = ws.send(frame)

    override fun close() = ws.close(CloseReason.Codes.NORMAL.code, "")
}

/**
 * Opens a sender's WebSocket to the receiver at [host]:[port] within [timeoutMs]; throws when it doesn't open. The
 * connect blocks its thread (Android forbids that on the main one), so it runs on IO.
 */
internal suspend fun connectCast(selector: SelectorManager, scope: CoroutineScope, host: String, port: Int, timeoutMs: Long = 10_000): FrameTransport =
    withTimeout(timeoutMs) {
        val socket = withContext(Dispatchers.IO) { aSocket(selector).tcp().connect(host, port) }
        try {
            val authority = if (':' in host) "[$host]:$port" else "$host:$port"
            SocketTransport(WebSocketWire.clientHandshake(socket, authority, CAST_PATH, scope), host)
        } catch (e: Throwable) {
            socket.close()
            throw e
        }
    }
