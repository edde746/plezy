package com.edde746.plezy.net

import com.sun.net.httpserver.HttpServer
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.net.InetAddress
import java.net.InetSocketAddress
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

/** A media server gets at most twelve of the app's requests at once; the next waits for one of them to finish. */
class ConnectionLimitTest {
    private val arrived = AtomicInteger()
    private val release = CountDownLatch(1)
    private val server = HttpServer.create(InetSocketAddress(InetAddress.getLoopbackAddress(), 0), 50).apply {
        executor = Executors.newCachedThreadPool()
        createContext("/") { exchange ->
            arrived.incrementAndGet()
            release.await(30, TimeUnit.SECONDS)
            val body = "ok".toByteArray()
            exchange.sendResponseHeaders(200, body.size.toLong())
            exchange.responseBody.use { it.write(body) }
        }
        start()
    }
    private val client = PlezyHttpClient.create("test")

    @AfterTest
    fun tearDown() {
        release.countDown()
        client.close()
        server.stop(0)
    }

    @Test
    fun aHostGetsTwelveRequestsAtOnce() = runBlocking {
        val url = "http://127.0.0.1:${server.address.port}/"
        val requests = (1..13).map { async(Dispatchers.IO) { client.get(url).bodyAsText() } }

        withTimeout(10_000) { while (arrived.get() < 12) delay(10) }
        // The thirteenth stays queued while the twelve are held.
        delay(500)
        assertEquals(12, arrived.get())

        release.countDown()
        assertEquals(List(13) { "ok" }, requests.awaitAll())
        assertEquals(13, arrived.get())
    }
}
