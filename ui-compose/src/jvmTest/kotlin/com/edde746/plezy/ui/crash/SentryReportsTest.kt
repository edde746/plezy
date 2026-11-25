package com.edde746.plezy.ui.crash

import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.app.BuildFlavor
import com.edde746.plezy.app.DevicePlatform
import com.edde746.plezy.app.Startup
import com.edde746.plezy.app.SystemInputs
import com.edde746.plezy.crash.CrashReport
import com.edde746.plezy.crash.CrashReports
import com.edde746.plezy.crash.NativeCrash
import com.edde746.plezy.crash.ReleaseChannel
import com.edde746.plezy.crash.crashReports
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.secrets.SecretStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.ui.TestMain
import io.sentry.Breadcrumb
import io.sentry.Hint
import io.sentry.ISerializer
import io.sentry.Sentry
import io.sentry.SentryEnvelope
import io.sentry.protocol.User
import io.sentry.transport.ITransport
import io.sentry.transport.RateLimiter
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import java.io.ByteArrayOutputStream
import java.nio.file.Files
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** The token below is made up; it only has the shape of a media server's access token. */
@OptIn(ExperimentalCoroutinesApi::class)
class SentryReportsTest {
    private val key = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567ABCDEFGHIJKLMNOPQRST"
    private val media = "https://media.example/library/parts/4242/file.mkv?X-Plex-Token=$key"
    private val home = System.getProperty("user.home")

    /** Each envelope Sentry would have sent, as its wire text. */
    private val sent: MutableList<String> = Collections.synchronizedList(mutableListOf())

    private class RecordingTransport(private val serializer: ISerializer, private val sent: MutableList<String>) : ITransport {
        override fun send(envelope: SentryEnvelope, hint: Hint) {
            sent += ByteArrayOutputStream().also { serializer.serialize(envelope, it) }.toString(Charsets.UTF_8)
        }

        override fun flush(timeoutMillis: Long) = Unit
        override fun getRateLimiter(): RateLimiter? = null
        override fun close(isRestarting: Boolean) = Unit
        override fun close() = Unit
    }

    /** The product's secrets, in memory. */
    private class MemorySecrets : SecretStore {
        private val values = mutableMapOf<String, ByteArray>()

        override suspend fun get(key: String): ByteArray? = values[key]

        override suspend fun put(key: String, value: ByteArray) {
            values[key] = value
        }

        override suspend fun delete(key: String) {
            values.remove(key)
        }

        override suspend fun deleteAll(prefix: String) {
            values.keys.removeAll { it.startsWith(prefix) }
        }
    }

    /** The app graph's scope (its settings' flows) runs on Main: the tests' main thread ([TestMain]). */
    @BeforeTest
    fun setUp() {
        TestMain.install()
        // The system's settings, as a platform reports them before it builds a core.
        SystemInputs.report(listOf("en"), region = null, captions = false, audioDescriptions = false)
    }

    @AfterTest
    fun closeSentry() {
        Sentry.close()
    }

    /** Starts Sentry on [reports] with every envelope recorded in [sent]; the follow ends with the returned job. */
    private suspend fun CoroutineScope.follow(reports: CrashReports): Job {
        val started = CompletableDeferred<Unit>()
        val follow = SentryReports.follow(reports, this) { configure ->
            Sentry.init { options ->
                configure(options)
                options.flushTimeoutMillis = 200
                options.setTransportFactory { o, _ -> RecordingTransport(o.serializer, sent) }
            }
            started.complete(Unit)
        }
        withTimeout(10_000) { started.await() }
        return follow
    }

    @Test
    fun aCrashReportHoldsNoMediaPathUserOrHomeDirectory() = runBlocking {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "1.2.3").use { boot ->
            val follow = follow(boot.crashReports(ReleaseChannel.DEVELOPMENT, "http://public@127.0.0.1:9/1"))

            // The media URL everywhere an app could put it: what was open, a request, the user, a tag, an extra, the
            // crashing thread's name and its exception, beside a file in the user's home directory.
            Sentry.addBreadcrumb("opened $media")
            Sentry.addBreadcrumb(Breadcrumb.http(media, "GET", 200))
            Sentry.addBreadcrumb(Breadcrumb("player").apply { setData("stream", media) })
            Sentry.setUser(User().apply { id = "profile-42"; ipAddress = "203.0.113.7" })
            Sentry.setTag("media", media)
            Sentry.setExtra("stream", media)
            val crashing = Thread({ throw IllegalStateException("stream failed: $media, cache $home/plezy/cache") }, "loader $media")
            crashing.start()
            crashing.join()
            follow.cancel()

            val events = sent.filter { "\"type\":\"event\"" in it }
            assertEquals(1, events.size, "one report of the one crash: ${sent.size} envelopes")
            val report = events.single()
            assertTrue("stream failed: https://media.example/…" in report, report)
            for (secret in listOf(key, "X-Plex-Token", "parts/4242", "profile-42", "203.0.113.7", home)) {
                assertFalse(secret in report, "'$secret' reached the report: $report")
            }
        }
    }

    /**
     * A native crash goes out as the tracker symbolicates one: an unhandled exception with its frames oldest first at
     * their addresses, and the libraries they ran in as debug images by id, their paths without the home directory.
     */
    @Test
    fun aNativeCrashIsSentWithItsFramesAndDebugImages() = runBlocking {
        AppBootstrap.local(DatabaseFactory.inMemory(), BuildFlavor.SIDELOADED, "1.2.3").use { boot ->
            val follow = follow(boot.crashReports(ReleaseChannel.DEVELOPMENT, "http://public@127.0.0.1:9/1"))
            val library = "$home/Plezy/mpv/libmpv.so.2.5.0"
            val crash = NativeCrash(
                type = "SIGSEGV",
                value = "SIGSEGV (0xb) in C [libmpv.so.2.5.0+0x2067f4] mpv_client_id+0x4",
                frames = listOf(
                    NativeCrash.Frame(0x7f9ee0a067f4, library, "mpv_client_id+0x4"),
                    NativeCrash.Frame(null, null, "j  java.lang.Thread.run()V+19"),
                ),
                images = listOf(
                    NativeCrash.Image("elf", library, 0x7f9ee0800000, 0x19e9000, "92880620-5500-c3d3-1067-2e60520a4b24", "200688920055d3c3", null),
                ),
            )
            assertTrue(SentryReports.capture(CrashReport(message = "Native crash", level = CrashReport.Level.FATAL, nativeCrash = crash)))
            follow.cancel()

            val report = sent.single { "\"type\":\"event\"" in it }
            val event = report.lines().first { "\"exception\"" in it }
            assertTrue("\"platform\":\"native\"" in event, event)
            assertTrue("\"type\":\"SIGSEGV\"" in event, event)
            assertTrue("\"handled\":false" in event, event)
            val frames = Regex("\"frames\":\\[(.*?)]").find(event)?.groupValues?.get(1).orEmpty()
            assertTrue(frames.indexOf("java.lang.Thread.run") < frames.indexOf("\"instruction_addr\":\"0x7f9ee0a067f4\""), frames)
            for (image in listOf("\"debug_id\":\"92880620-5500-c3d3-1067-2e60520a4b24\"", "\"image_addr\":\"0x7f9ee0800000\"", "\"code_file\":\"~/Plezy/mpv/libmpv.so.2.5.0\"")) {
                assertTrue(image in event, "$image not in $event")
            }
            assertFalse(home in event, event)
        }
    }

    @Test
    fun aCoroutineTheAppSurvivedIsSentAsAnErrorScrubbedAsACrash(): Unit = runBlocking {
        val cache = Files.createTempDirectory("plezy-test-cache")
        try {
            AppBootstrap.product(DatabaseFactory.inMemory(), MemorySecrets(), BuildFlavor.SIDELOADED, "1.2.3", Startup()).use { boot ->
                val channel = ReleaseChannel.of(BuildFlavor.SIDELOADED, DevicePlatform.WINDOWS, "amd64")
                val follow = follow(boot.crashReports(channel, "http://public@127.0.0.1:9/1"))

                // A store's coroutine that throws: the app runs on, and the exception goes out as an error, not as a crash.
                boot.graph.scope.launch { throw IllegalStateException("stream failed: $media, cache $home/plezy/cache") }.join()
                yield()
                follow.cancel()

                val events = sent.filter { "\"type\":\"event\"" in it }
                assertEquals(1, events.size, "one report of the one failure: ${sent.size} envelopes")
                val report = events.single()
                assertFalse("\"level\":\"fatal\"" in report, report)
                assertTrue("stream failed: https://media.example/…" in report, report)
                assertTrue("\"environment\":\"github\"" in report, report)
                assertTrue("\"dist\":\"github-windows-x64\"" in report, report)
                for (secret in listOf(key, "X-Plex-Token", "parts/4242", home)) {
                    assertFalse(secret in report, "'$secret' reached the report: $report")
                }
            }
        } finally {
            cache.toFile().deleteRecursively()
        }
    }

    /**
     * A failure that comes as reports turn on, heard before Sentry has started (which drops what comes before), is sent
     * once it has.
     */
    @Test
    fun aFailureAsReportsTurnOnIsSentOnceSentryHasStarted(): Unit = runBlocking {
        val cache = Files.createTempDirectory("plezy-test-cache")
        val follower = Executors.newSingleThreadExecutor()
        val following = follower.asCoroutineDispatcher()
        try {
            AppBootstrap.product(DatabaseFactory.inMemory(), MemorySecrets(), BuildFlavor.SIDELOADED, "1.2.3", Startup()).use { boot ->
                val settings = boot.graph.data.deviceSettings
                settings.set(AppSettings.crashReporting, false)
                val reports = boot.crashReports(ReleaseChannel.DEVELOPMENT, "http://public@127.0.0.1:9/1")
                val started = CompletableDeferred<Unit>()
                val follow = SentryReports.follow(reports, CoroutineScope(following)) { configure ->
                    Sentry.init { options ->
                        configure(options)
                        options.flushTimeoutMillis = 200
                        options.setTransportFactory { o, _ -> RecordingTransport(o.serializer, sent) }
                    }
                    started.complete(Unit)
                }
                // The follow's first pass, then its failures' collector: both wait, reports off.
                repeat(2) { withContext(following) {} }

                // While the follow's thread is busy, a store's coroutine fails and then reports turn on: the follow hears
                // of the failure first.
                val busy = CountDownLatch(1)
                follower.execute { busy.await() }
                boot.graph.scope.launch { throw IllegalStateException("stream failed") }.join()
                settings.set(AppSettings.crashReporting, true)
                withTimeout(10_000) { reports.active.first { it != null } }
                busy.countDown()

                withTimeout(10_000) { started.await() }
                withTimeout(5_000) { while (sent.none { "\"type\":\"event\"" in it }) delay(10) }
                follow.cancel()
                assertTrue(sent.single { "\"type\":\"event\"" in it }.contains("stream failed"))
            }
        } finally {
            follower.shutdown()
            cache.toFile().deleteRecursively()
        }
    }
}
