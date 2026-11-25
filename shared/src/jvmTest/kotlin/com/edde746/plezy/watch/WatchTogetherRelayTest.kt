package com.edde746.plezy.watch

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.net.PlezyHttpClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import party.openwatch.Relays
import java.util.concurrent.Executors
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.seconds

/**
 * Two participants on a real Open Watch Party relay at `OWP_RELAY_URL` (skipped when it is unset): the host creates a
 * room, the guest joins by its code, the host shares Alien and the guest opens its own copy, then follows the host's
 * play, pause and seek.
 */
class WatchTogetherRelayTest {
    private val relayUrl: String? = System.getenv("OWP_RELAY_URL")?.takeIf { it.isNotBlank() }

    @Test
    fun `a guest on a real relay matches the hosts file and follows its play pause and seek`() {
        val url = relayUrl ?: return
        val executor = Executors.newSingleThreadExecutor()
        val dispatcher = executor.asCoroutineDispatcher()
        val scope = CoroutineScope(dispatcher + SupervisorJob())
        val http = PlezyHttpClient.create("9.9.9")
        try {
            runBlocking(dispatcher) { session(url, http, scope) }
        } finally {
            scope.cancel()
            http.close()
            dispatcher.close()
        }
    }

    private suspend fun session(url: String, http: io.ktor.client.HttpClient, scope: CoroutineScope) {
        val hostServer = FakeMediaBackend("host-nas").apply {
            externalIds = { id -> if (id == "alien") ExternalIds(imdb = "tt0078748", tmdb = 348) else ExternalIds() }
            items = { null }
        }
        fun member(name: String, clientFor: (String) -> FakeMediaBackend?, copies: List<com.edde746.plezy.model.MediaItem>) = WatchTogether(
            client = "Plezy/9.9.9",
            displayName = { name },
            profileScope = null,
            relayBaseUrl = MutableStateFlow(url),
            relaysFor = { Relays.at(http, url) },
            recentRooms = null,
            clientFor = clientFor,
            findCopies = { lookup(copies, succeeded = setOf("guest-nas")) },
            scope = scope,
        )
        val host = member("Host", { if (it == "host-nas") hostServer else null }, emptyList())
        val guest = member("Guest", { null }, listOf(guestAlien))
        val guestPlayer = FakeRoomPlayer(renderedFrame = true, durationMs = guestAlien.durationMs)
        guest.navigatorOpener = { copy ->
            val adapter = PlezyPlayerAdapter(guestPlayer, copy)
            guest.registerPlayer(this, WatchPlayerHooks({ false }) {})
            guest.playerOpened(adapter, shareable = true, roomLaunch = true)
            true
        }
        try {
            val code = host.createRoom()
            guest.joinRoom(code)
            until("both see two participants") { host.participants.size == 2 && guest.participants.size == 2 }

            val hostPlayer = FakeRoomPlayer(renderedFrame = true, durationMs = hostAlien.durationMs)
            host.playerOpened(PlezyPlayerAdapter(hostPlayer, copyOf(hostAlien)), shareable = true, roomLaunch = false)
            until("the guest follows its own copy") { guest.isFollowing }
            assertEquals(copyOf(guestAlien), guest.roomCopy?.ref)

            host.play()
            until("the guest plays") { guestPlayer.playing && hostPlayer.playing }
            host.pause()
            until("the guest pauses") { !guestPlayer.playing && !hostPlayer.playing }
            host.seek(600_000)
            until("the guest seeks") {
                guestPlayer.commandLog.any { it.startsWith("seek:") && it.removePrefix("seek:").toLong() in 595_000..605_000 }
            }
        } finally {
            guest.close()
            host.close()
        }
    }

    private suspend fun until(what: String, check: () -> Boolean) {
        try {
            withTimeout(20.seconds) { while (!check()) delay(50) }
        } catch (e: kotlinx.coroutines.TimeoutCancellationException) {
            throw AssertionError("timed out waiting until $what", e)
        }
    }
}
