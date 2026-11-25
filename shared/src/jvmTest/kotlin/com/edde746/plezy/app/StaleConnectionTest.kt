@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.app

import com.edde746.plezy.data.inMemoryDatabase
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import kotlinx.coroutines.withTimeout
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A kept-alive connection can die silently while the app sleeps or its network changes (a NAT entry dropped, a server
 * gone): the socket stays open and nothing answers on it. The first request after coming back must not wait out the
 * socket timeout on it.
 */
class StaleConnectionTest {
    private val server = ServerSocket(0, 50, InetAddress.getLoopbackAddress())
    private val connections = AtomicInteger()
    private val held = mutableListOf<Socket>()

    @BeforeTest
    fun start() {
        Dispatchers.setMain(StandardTestDispatcher())
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
        // The first connection answers one request, then goes silent; every later one answers each request.
        thread(isDaemon = true) {
            while (!server.isClosed) {
                val socket = runCatching { server.accept() }.getOrNull() ?: break
                val dying = connections.incrementAndGet() == 1
                synchronized(held) { held += socket }
                thread(isDaemon = true) { serve(socket, answers = if (dying) 1 else Int.MAX_VALUE) }
            }
        }
    }

    @AfterTest
    fun stop() {
        server.close()
        synchronized(held) { held.forEach { it.close() } }
        Dispatchers.resetMain()
    }

    private fun serve(socket: Socket, answers: Int) {
        val input = socket.getInputStream().bufferedReader(Charsets.ISO_8859_1)
        val output = socket.getOutputStream()
        repeat(answers) {
            while (true) {
                val line = runCatching { input.readLine() }.getOrNull() ?: return
                if (line.isEmpty()) break
            }
            output.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: keep-alive\r\n\r\nok".toByteArray())
            output.flush()
        }
        // Silent: the connection stays open and its next request is read by nobody.
    }

    private fun boot() = AppBootstrap.local(inMemoryDatabase(), BuildFlavor.SIDELOADED, "test")

    private fun AppBootstrap.fetch(): String = runBlocking {
        withTimeout(5_000) { graph.http.get("http://127.0.0.1:${server.localPort}/").bodyAsText() }
    }

    @Test
    fun theFirstRequestAfterComingBackToTheForegroundOpensAFreshConnection() {
        boot().use { boot ->
            boot.onForeground()
            assertEquals("ok", boot.fetch())
            boot.onBackground()
            boot.onForeground()
            assertEquals("ok", boot.fetch())
            assertEquals(2, connections.get())
        }
    }

    @Test
    fun theFirstRequestAfterTheNetworkChangesOpensAFreshConnection() {
        boot().use { boot ->
            boot.onNetworkChanged(online = true, metered = false)
            assertEquals("ok", boot.fetch())
            boot.onNetworkChanged(online = true, metered = true)
            assertEquals("ok", boot.fetch())
            assertEquals(2, connections.get())
        }
    }
}
