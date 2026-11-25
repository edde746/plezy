package com.edde746.plezy.net

import io.ktor.client.engine.okhttp.OkHttpConfig
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicInteger
import javax.net.SocketFactory
import kotlin.concurrent.thread
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The app closes its idle connections from the main thread (coming to the foreground, the network changing), and closing
 * a connection is network I/O (a TLS connection writes its close_notify), which Android's main thread refuses: the
 * connections close off the caller's thread, and still before the next request takes one.
 */
class IdleConnectionsTest {
    private val server = ServerSocket(0, 50, InetAddress.getLoopbackAddress())
    private val connections = AtomicInteger()
    private val held = CopyOnWriteArrayList<Socket>()
    private val closedOn = CopyOnWriteArrayList<Thread>()

    /** Every socket the client opens records the thread that closes it. */
    private val sockets = object : SocketFactory() {
        override fun createSocket(): Socket = object : Socket() {
            override fun close() {
                closedOn += Thread.currentThread()
                super.close()
            }
        }

        override fun createSocket(host: String, port: Int): Socket = throw UnsupportedOperationException()
        override fun createSocket(host: String, port: Int, localHost: InetAddress, localPort: Int): Socket = throw UnsupportedOperationException()
        override fun createSocket(host: InetAddress, port: Int): Socket = throw UnsupportedOperationException()
        override fun createSocket(address: InetAddress, port: Int, localAddress: InetAddress, localPort: Int): Socket =
            throw UnsupportedOperationException()
    }

    private val client = PlezyHttpClient.create("test") {
        engine { (this as OkHttpConfig).config { socketFactory(sockets) } }
    }

    init {
        thread(isDaemon = true) {
            while (!server.isClosed) {
                val socket = runCatching { server.accept() }.getOrNull() ?: break
                connections.incrementAndGet()
                held += socket
                thread(isDaemon = true) { serve(socket) }
            }
        }
    }

    @AfterTest
    fun stop() {
        client.close()
        server.close()
        held.forEach { it.close() }
    }

    /** Answers each request on the connection with `ok`, keeping it alive. */
    private fun serve(socket: Socket) {
        val input = socket.getInputStream().bufferedReader(Charsets.ISO_8859_1)
        val output = socket.getOutputStream()
        while (true) {
            while (true) {
                val line = runCatching { input.readLine() }.getOrNull() ?: return
                if (line.isEmpty()) break
            }
            output.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: keep-alive\r\n\r\nok".toByteArray())
            output.flush()
        }
    }

    private fun fetch(): String = runBlocking {
        withTimeout(5_000) { client.get("http://127.0.0.1:${server.localPort}/").bodyAsText() }
    }

    @Test
    fun idleConnectionsCloseOffTheCallersThreadBeforeTheNextRequest() {
        assertEquals("ok", fetch())
        assertEquals(1, (client.engine.config as OkHttpConfig).preconfigured!!.connectionPool.idleConnectionCount())

        client.closeIdleConnections()
        assertTrue(Thread.currentThread() !in closedOn, "a connection was closed on the caller's thread")

        assertEquals("ok", fetch())
        assertEquals(2, connections.get(), "the request after closing went out on the old connection")
        assertTrue(closedOn.isNotEmpty(), "the old connection wasn't closed")
        assertTrue(Thread.currentThread() !in closedOn, "a connection was closed on the caller's thread")
    }
}
