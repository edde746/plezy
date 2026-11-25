package com.edde746.plezy.app

import com.edde746.plezy.cast.CastFailure
import com.edde746.plezy.cast.CastItem
import com.edde746.plezy.cast.CastLink
import com.edde746.plezy.cast.CastMessage
import com.edde746.plezy.cast.CastPeerInfo
import com.edde746.plezy.cast.CastReceiver
import com.edde746.plezy.cast.ServerAccess
import com.edde746.plezy.cast.memoryConnection
import com.edde746.plezy.cast.senderHandshake
import com.edde746.plezy.jellyfin.FakeResponse
import com.edde746.plezy.jellyfin.JellyfinTestServer
import com.edde746.plezy.jellyfin.RecordedRequest
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.playback.session.PlaybackSession
import com.edde746.plezy.presentation.cast.CastDeviceKind
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Casts to this app's receiver from a sender linked in memory, on the Jellyfin servers the senders hand over. */
class AppCastReceiverTest {
    /** Answers held until the test lets them go, by host and path. */
    private val held = HashMap<String, CompletableDeferred<Unit>>()

    private val server = JellyfinTestServer(
        handler = { request ->
            held["${request.url.host}${request.path}"]?.await()
            answer(request)
        },
    )

    private val platform = FakeAppPlatform()

    @Test
    fun `a cast of the second version of a title opens that version`() = runTest {
        val app = AppSession(testGraph(http = server.http), platform)
        val sender = link(app.castReceiver)

        sender.send(CastMessage.Load(access("a"), CastItem.Video("movie-1", mediaIndex = 1, mediaSourceId = "src-2", strict = true)))
        runCurrent()

        val opened = (app.playbacks.active.value?.session as? PlaybackSession)?.opened?.value
        assertEquals(1, opened?.mediaIndex, "$opened")
        assertEquals("src-2", opened?.mediaSourceId)
    }

    @Test
    fun `a cast whose player opens only after the sender was told it failed opens nothing`() = runTest {
        val graph = testGraph(http = server.http)
        val app = AppSession(graph, platform)
        // The music session's teardown holds the player back, past the receiver's wait for it.
        val teardown = CompletableDeferred<Unit>()
        graph.playbackCoordinator.registerMusicSession { teardown.await() }
        val sender = link(app.castReceiver)

        sender.send(CastMessage.Load(access("a"), CastItem.Video("movie-1")))
        val failed = sender.incoming.first { it is CastMessage.Failed }
        teardown.complete(Unit)
        runCurrent()

        assertEquals(CastMessage.Failed(CastFailure.PLAYBACK_FAILED), failed)
        assertNull(app.playbacks.active.value)
        assertEquals(0, platform.playbacks.size)
    }

    @Test
    fun `a late answer to a cast another cast took over is never stored`() = runTest {
        val graph = testGraph(http = server.http)
        val app = AppSession(graph, platform)
        val sender = link(app.castReceiver)
        val itemA = CompletableDeferred<Unit>().also { held["a.test/Users/user-a/Items/movie-1"] = it }
        val healthB = CompletableDeferred<Unit>().also { held["b.test/Users/Me"] = it }

        sender.send(CastMessage.Load(access("a"), CastItem.Video("movie-1")))
        runCurrent()
        assertTrue(server.requests.any { it.url.host == "a.test" && it.path == "/Users/user-a/Items/movie-1" }, "A's play asks for its item")
        // B takes over while its server still answers the health check, so A's play still opens meanwhile.
        sender.send(CastMessage.Load(access("b"), CastItem.Video("movie-1")))
        runCurrent()
        itemA.complete(Unit)
        runCurrent()

        assertEquals(emptyList(), graph.data.apiCache.rowsMatching("machine-a", "").map { it.key })
        healthB.complete(Unit)
    }

    /** Links a sender to [receiver] in memory, the receiver's user allowing the pairing; the sender's end of the link. */
    private suspend fun TestScope.link(receiver: CastReceiver): CastLink {
        val (receiverEnd, senderEnd) = memoryConnection("10.0.0.2", "10.0.0.1")
        receiver.accept(receiverEnd)
        backgroundScope.launch {
            receiver.state.first { it.prompt != null }
            receiver.approve()
        }
        return senderHandshake(senderEnd, PHONE, null, { null }, pair = true, onCode = { _, _ -> }, remember = {}, forget = {}, scope = backgroundScope)
    }

    /** Jellyfin server [name] at `http://[name].test`, its machine `machine-[name]`, as its user `user-[name]`. */
    private fun access(name: String) = ServerAccess(
        BackendKind.JELLYFIN, "machine-$name", "Server $name", listOf("http://$name.test"), "token-$name", "user-$name", name, "device-$name",
    )

    private fun answer(request: RecordedRequest): FakeResponse {
        val name = request.url.host.removeSuffix(".test")
        return when (request.path) {
            "/Users/Me", "/Users/user-$name" -> FakeResponse(200, """{"Id":"user-$name","Name":"$name","Policy":{"IsAdministrator":false}}""")
            "/Users/user-$name/Items/movie-1" -> FakeResponse(200, MOVIE)
            "/Items/movie-1/PlaybackInfo" -> FakeResponse(200, """{"PlaySessionId":"play-1","MediaSources":$SOURCES}""")
            else -> FakeResponse(404)
        }
    }

    private companion object {
        val PHONE = CastPeerInfo("phone-1", "Phone", "iOS", CastDeviceKind.HANDHELD)
        const val SOURCES = """[{"Id":"src-1","Name":"720p","Container":"mkv","SupportsDirectPlay":true,"MediaStreams":[{"Index":0,"Type":"Video","Height":720}]},""" +
            """{"Id":"src-2","Name":"360p","Container":"mkv","SupportsDirectPlay":true,"MediaStreams":[{"Index":0,"Type":"Video","Height":360}]}]"""
        const val MOVIE = """{"Id":"movie-1","Type":"Movie","Name":"Two Versions","ProductionYear":2026,"MediaSources":$SOURCES}"""
    }
}
