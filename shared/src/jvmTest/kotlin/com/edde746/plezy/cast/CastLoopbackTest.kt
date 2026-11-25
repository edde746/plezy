package com.edde746.plezy.cast

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.presentation.cast.CastLinkStatus
import com.edde746.plezy.presentation.cast.CastMediaKind
import com.edde746.plezy.secrets.MemorySecretStore
import com.sun.net.httpserver.HttpServer
import io.ktor.network.selector.SelectorManager
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.URI
import java.util.Collections
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** Two devices casting over real sockets on this machine, the receiver reaching a fake media server with the access handed over. */
class CastLoopbackTest {
    /** The tokens the fake server was called with. */
    private val tokens: MutableList<String> = Collections.synchronizedList(mutableListOf())
    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0).apply {
        createContext("/identity") { exchange ->
            val token = exchange.requestHeaders.getFirst("X-Plex-Token").orEmpty()
            tokens += token
            exchange.sendResponseHeaders(if (token == TOKEN) 200 else 401, -1)
            exchange.close()
        }
        start()
    }
    private val serverUrl = "http://127.0.0.1:${server.address.port}"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default.limitedParallelism(1))
    private val selector = SelectorManager(Dispatchers.IO)

    @AfterTest
    fun stop() {
        scope.cancel()
        selector.close()
        server.stop(0)
    }

    @Test
    fun `a sender pairs with a receiver over the network and casts with its access to the server`() = runBlocking(scope.coroutineContext) {
        withTimeout(30.seconds) {
            val adverts = MutableStateFlow<List<CastService>>(emptyList())
            val discovery = object : CastDiscovery {
                override fun advertise(instance: String, port: Int, txt: Map<String, String>): AutoCloseable {
                    val service = CastService(instance, listOf("127.0.0.1"), port, txt)
                    adverts.update { it + service }
                    return AutoCloseable { adverts.update { it - service } }
                }

                override fun browse(): Flow<List<CastService>> = adverts

                override fun localAddresses(): Set<String> = emptySet()
            }
            val playback = Playback()
            val receiver = CastReceiver(
                parentScope = scope,
                me = { TV },
                senders = CastPeers(MemorySecretStore(), CastPeers.SENDERS),
                allowed = flowOf(true),
                playback = playback,
                access = { access -> reach(access) },
                endpoint = CastServer(selector, scope, ServerLimits(preferredPort = 0)),
                discovery = discovery,
            )
            val sender = CastSender(
                parentScope = scope,
                me = { PHONE },
                receivers = CastPeers(MemorySecretStore(), CastPeers.RECEIVERS),
                discovery = discovery,
                connect = { host, port -> connectCast(selector, scope, host, port) },
                source = object : CastSource {
                    override fun access(serverId: String) = ServerAccess(BackendKind.PLEX, serverId, "Fake", listOf(serverUrl), TOKEN)

                    override fun current(): Pair<String, CastItem>? = null

                    override fun stopLocal() = Unit

                    override fun artworkUrl(serverId: String, thumb: String): String? = null
                },
            )

            sender.openPicker()
            sender.state.first { state -> state.picker?.devices.orEmpty().any { it.device.id == TV.id } }
            sender.choose(TV.id)
            val code = sender.state.first { it.picker?.pairing != null }.picker!!.pairing!!.code
            assertEquals(code, receiver.state.first { it.prompt != null }.prompt!!.code)
            receiver.approve()
            sender.state.first { it.status == CastLinkStatus.CONNECTED }

            assertTrue(sender.cast("server-1", CastItem.Video("movie-1")))
            assertEquals("movie-1", sender.state.first { it.nowPlaying != null }.nowPlaying!!.title)
            assertEquals(listOf(TOKEN), tokens.toList())
            assertEquals("Casting from Phone", receiver.state.value.castingFrom)

            sender.togglePause()
            sender.state.first { it.nowPlaying?.paused == true }

            sender.disconnect()
            assertEquals("movie-1", playback.state.value?.title)
            receiver.close()
            sender.close()
        }
    }

    /** The fake server answering for [access]'s token, as a receiver's client checks it. */
    private suspend fun reach(access: ServerAccess): MediaBackend = withContext(Dispatchers.IO) {
        val connection = URI("${access.baseUrls.first()}/identity").toURL().openConnection() as HttpURLConnection
        connection.setRequestProperty("X-Plex-Token", access.token)
        val status = connection.responseCode
        connection.disconnect()
        if (status != 200) throw CastLoadException(CastFailure.SERVER_UNREACHABLE, "status $status")
        FakeMediaBackend(access.serverId)
    }

    private class Playback : CastPlayback {
        private val mutableState = MutableStateFlow<CastState?>(null)
        override val state: StateFlow<CastState?> = mutableState.asStateFlow()

        override suspend fun load(item: CastItem, server: MediaBackend, senderName: String) {
            mutableState.value = CastState(CastMediaKind.VIDEO, (item as CastItem.Video).itemId, paused = false, positionMs = 0, durationMs = 60_000, canSeek = true, from = senderName)
        }

        override fun control(command: CastCommand) {
            if (command == CastCommand.TogglePause) mutableState.update { it?.copy(paused = !it.paused) }
        }
    }

    private companion object {
        const val TOKEN = "per-server-token"
        val TV = CastPeerInfo("tv-1", "Living Room", "tvOS", CastDeviceKind.TV)
        val PHONE = CastPeerInfo("phone-1", "Phone", "iOS", CastDeviceKind.HANDHELD)
    }
}
