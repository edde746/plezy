package plezy.buildlogic

import com.sun.net.httpserver.HttpServer
import org.gradle.api.logging.Logging
import org.junit.jupiter.api.Assertions.assertTimeoutPreemptively
import java.io.File
import java.net.InetSocketAddress
import java.nio.file.Files
import java.security.MessageDigest
import java.time.Duration
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.random.Random
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFails

class FetchVerifiedTest {
    private val body = Random(7).nextBytes(8 shl 20)
    private val sha256 = MessageDigest.getInstance("SHA-256").digest(body).joinToString("") { "%02x".format(it) }
    private val cache = Files.createTempDirectory("plezy-mpv-test").toFile()
    private val target = File(cache, "libmpv-test.tar.gz")
    private val logger = Logging.getLogger(FetchVerifiedTest::class.java)
    private val requests = AtomicInteger()

    /** Set: the first two requests get their headers and first bytes together, then the second its rest 1.5 s later. */
    @Volatile private var overlap = false
    private val arrived = CountDownLatch(2)
    private val released = CountDownLatch(1)

    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0).apply {
        executor = Executors.newCachedThreadPool()
        createContext("/asset") { exchange ->
            val n = requests.incrementAndGet()
            exchange.sendResponseHeaders(200, body.size.toLong())
            exchange.responseBody.use { out ->
                var sent = 0
                if (overlap) {
                    sent = 1 shl 16
                    out.write(body, 0, sent)
                    out.flush()
                    arrived.countDown()
                    arrived.await(30, TimeUnit.SECONDS)
                    Thread.sleep(if (n == 1) 300 else 1500)
                }
                out.write(body, sent, body.size - sent)
            }
        }
        // Headers and the first bytes, then nothing until the test ends.
        createContext("/stall") { exchange ->
            exchange.sendResponseHeaders(200, body.size.toLong())
            exchange.responseBody.use { out ->
                out.write(body, 0, 1 shl 16)
                out.flush()
                released.await(60, TimeUnit.SECONDS)
            }
        }
        start()
    }
    private val url = "http://127.0.0.1:${server.address.port}/asset"

    @AfterTest
    fun stop() {
        released.countDown()
        server.stop(0)
        cache.deleteRecursively()
    }

    private fun cached(): List<String> = cache.list()!!.sorted()

    @Test
    fun twoConcurrentDownloadsOfOneAssetBothSucceedAndLeaveOneFile() {
        overlap = true
        val pool = Executors.newFixedThreadPool(2)
        val fetches = List(2) { pool.submit<File> { fetchVerified(url, sha256, target, logger) } }
        val results = fetches.map { it.get(60, TimeUnit.SECONDS) }
        pool.shutdown()
        assertEquals(listOf(target, target), results)
        assertEquals(2, requests.get())
        assertEquals(listOf(target.name), cached())
        assertContentEquals(body, target.readBytes())
    }

    @Test
    fun aCorruptCachedAssetIsReplacedAndAValidOneReused() {
        target.writeText("truncated")
        fetchVerified(url, sha256, target, logger)
        assertContentEquals(body, target.readBytes())
        fetchVerified(url, sha256, target, logger)
        assertEquals(1, requests.get())
        assertEquals(listOf(target.name), cached())
    }

    @Test
    fun aDownloadWithTheWrongChecksumFailsAndLeavesNothing() {
        assertFails { fetchVerified(url, "0".repeat(64), target, logger) }
        assertEquals(emptyList(), cached())
    }

    @Test
    fun aDownloadThatStallsFailsAndLeavesNothing() {
        val stalled = url.replace("/asset", "/stall")
        assertTimeoutPreemptively(Duration.ofSeconds(20)) {
            assertFails { fetchVerified(stalled, sha256, target, logger, idleTimeout = Duration.ofSeconds(1)) }
        }
        assertEquals(emptyList(), cached())
    }

    @Test
    fun aKilledBuildsTempFileGoesADayOnAndALiveOneStays() {
        val killed = File(cache, "libmpv-other.tar.gz.123.part").apply { writeText("x") }
        killed.setLastModified(System.currentTimeMillis() - TimeUnit.HOURS.toMillis(25))
        val live = File(cache, "libmpv-other.tar.gz.456.part").apply { writeText("x") }
        fetchVerified(url, sha256, target, logger)
        assertEquals(listOf(live.name, target.name), cached())
    }
}
