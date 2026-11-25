package com.edde746.plezy.watch

import android.os.Build
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.net.PlezyHttpClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Assume.assumeTrue
import party.openwatch.Candidate
import party.openwatch.Connection
import party.openwatch.Media
import party.openwatch.MediaKind
import party.openwatch.Phase
import party.openwatch.PlayerAdapter
import party.openwatch.Relays
import party.openwatch.Resolver
import party.openwatch.WatchParty
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.fail
import kotlin.time.TimeSource

/**
 * Open Watch Party on the device's own runtime (its library declares a higher minimum API level than the app's): two
 * parties on a real relay through the app's HttpClient, the host shares a movie, and the guest's player follows its
 * play, pause and seek. The relay's base URL is the `watchRelay` instrumentation argument; without it the test is
 * skipped.
 */
class WatchPartyDeviceTest {
    private val relayUrl: String? = InstrumentationRegistry.getArguments().getString("watchRelay")
    private val executor = Executors.newSingleThreadExecutor()
    private val dispatcher = executor.asCoroutineDispatcher()
    private val scope = CoroutineScope(SupervisorJob() + dispatcher)
    private val http = PlezyHttpClient.create("device-test")
    private val movie = Media(MediaKind.MOVIE, "Heat", durationMs = 600_000, year = 1995, ids = mapOf("imdb" to "tt0113277"))

    @AfterTest
    fun stopEverything() {
        scope.cancel()
        http.close()
        executor.shutdown()
    }

    @Test
    fun theGuestFollowsTheHostsPlayPauseAndSeek() {
        assumeTrue("no watchRelay instrumentation argument", relayUrl != null)
        val relays = Relays.at(http, relayUrl!!)
        val api = "API ${Build.VERSION.SDK_INT}"
        runBlocking(dispatcher) {
            withTimeout(90_000) {
                val host = WatchParty(relays, CLIENT, "Host", Resolver<String> { emptyList() }, scope)
                val guest = WatchParty(
                    relays,
                    CLIENT,
                    "Guest",
                    Resolver { media -> if (media.title == movie.title) listOf(Candidate("heat", "heat.mkv", durationMs = media.durationMs)) else emptyList() },
                    scope,
                )
                try {
                    val code = host.create()
                    guest.join(code)
                    assertEquals(Connection.CONNECTED, guest.state.value.connection, api)
                    assertEquals(code, guest.state.value.room?.code, api)
                    eventually("the host sees the guest on $api") { host.state.value.room?.participants?.size == 2 }

                    val hostPlayer = FakePlayer(movie.durationMs)
                    val guestPlayer = FakePlayer(movie.durationMs)
                    host.setMedia(movie, "heat.mkv", positionMs = 60_000)
                    host.attachPlayer(hostPlayer, "heat.mkv")
                    eventually("the guest's match on $api") { guest.state.value.choice != null }
                    guest.attachPlayer(guestPlayer, "heat.mkv")
                    eventually("both players running on $api") {
                        guest.state.value.room?.phase == Phase.PLAYING && !hostPlayer.paused && !guestPlayer.paused
                    }
                    assertTrue(guestPlayer.positionMs >= 60_000, "the guest plays from 60 s on $api: ${guestPlayer.positionMs}")

                    host.pause()
                    eventually("the guest paused on $api") { guestPlayer.paused && guest.state.value.room?.phase == Phase.PAUSED }
                    assertTrue(
                        abs(hostPlayer.positionMs - guestPlayer.positionMs) <= 1_000,
                        "host ${hostPlayer.positionMs}, guest ${guestPlayer.positionMs} on $api",
                    )

                    host.seek(120_000)
                    eventually("the guest at 120 s on $api") {
                        guest.state.value.room?.positionMs == 120_000L && guestPlayer.positionMs == 120_000L
                    }

                    host.play()
                    eventually("the guest playing again on $api") {
                        guest.state.value.room?.phase == Phase.PLAYING && !guestPlayer.paused
                    }
                    delay(1_000)
                    assertTrue(guestPlayer.positionMs > 120_500, "the guest moved on from 120 s on $api: ${guestPlayer.positionMs}")
                    assertTrue(
                        abs(hostPlayer.positionMs - guestPlayer.positionMs) <= 1_000,
                        "host ${hostPlayer.positionMs}, guest ${guestPlayer.positionMs} on $api",
                    )

                    host.end()
                    eventually("the room ended for the guest on $api") { guest.state.value.connection == Connection.ENDED }
                } finally {
                    guest.close()
                    host.close()
                }
            }
        }
    }

    /** Waits until [condition] holds, checking every 20 ms; fails after [timeoutMs] with [what]. */
    private suspend fun eventually(what: String, timeoutMs: Long = 15_000, condition: () -> Boolean) {
        val start = TimeSource.Monotonic.markNow()
        while (!condition()) {
            if (start.elapsedNow().inWholeMilliseconds > timeoutMs) fail("timed out waiting for $what")
            delay(20)
        }
    }

    /** A player in real time whose commands take effect at once. */
    private class FakePlayer(override val durationMs: Long) : PlayerAdapter {
        @Volatile private var base = 0L

        @Volatile private var baseAt = TimeSource.Monotonic.markNow()

        @Volatile override var paused = true
            private set

        override val positionMs: Long
            get() = if (paused) base else minOf(base + baseAt.elapsedNow().inWholeMilliseconds, durationMs)
        override val buffering: Boolean get() = false
        override val firstFrameShown: Boolean get() = true

        override suspend fun play() {
            rebase()
            paused = false
        }

        override suspend fun pause() {
            rebase()
            paused = true
        }

        override suspend fun seek(positionMs: Long) {
            base = positionMs
            baseAt = TimeSource.Monotonic.markNow()
        }

        private fun rebase() {
            base = positionMs
            baseAt = TimeSource.Monotonic.markNow()
        }
    }

    private companion object {
        const val CLIENT = "PlezyDeviceTest/1.0"
    }
}
