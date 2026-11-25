package com.edde746.plezy.cast

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.presentation.cast.CastLinkStatus
import com.edde746.plezy.presentation.cast.CastMediaKind
import com.edde746.plezy.presentation.cast.CastNoticeKind
import com.edde746.plezy.presentation.cast.CastSenderUiState
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.secrets.SecretStore
import io.ktor.websocket.Frame
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.yield
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class CastTest {
    @Test
    fun `an unknown sender pairs once the receivers user allows it with the code both show`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()

        phone.pickAndChoose()
        val shown = phone.sender.state.first { it.picker?.pairing != null }.picker!!.pairing!!
        val asked = tv.receiver.state.first { it.prompt != null }.prompt!!
        assertEquals(shown.code, asked.code)
        assertEquals(PHONE.name, asked.senderName)
        assertTrue(shown.code.length == 4 && shown.code.all { it.isDigit() })
        assertEquals(CastLinkStatus.PAIRING, phone.sender.state.value.status)

        tv.receiver.approve()
        val linked = phone.sender.state.first { it.status == CastLinkStatus.CONNECTED }
        assertEquals(TV.id, linked.target?.id)
        assertNull(linked.picker)
        assertTrue(phone.sender.casting)
        assertEquals(listOf(PHONE.id), tv.senders.load().map { it.device.id })
    }

    @Test
    fun `a refused pairing tells the sender and leaves it on this device`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()

        phone.pickAndChoose()
        tv.receiver.state.first { it.prompt != null }
        tv.receiver.refuse()

        val refused = phone.sender.state.first { it.notice != null }
        assertEquals(CastNoticeKind.PAIRING_REFUSED, refused.notice?.kind)
        assertNull(refused.target)
        assertEquals(CastLinkStatus.IDLE, refused.status)
        assertTrue(tv.senders.load().isEmpty())
    }

    @Test
    fun `a remembered sender links without a prompt until the receiver forgets it`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pair(tv)
        phone.sender.disconnect()

        val prompts = mutableListOf<String>()
        backgroundScope.launch { tv.receiver.state.collect { state -> state.prompt?.let { prompts += it.code } } }
        phone.pickAndChoose()
        phone.sender.state.first { it.status == CastLinkStatus.CONNECTED }
        assertEquals(emptyList(), prompts)

        phone.sender.disconnect()
        tv.senders.forget(PHONE.id)
        phone.pickAndChoose()
        tv.receiver.state.first { it.prompt != null }
        assertEquals(CastLinkStatus.PAIRING, phone.sender.state.first { it.status == CastLinkStatus.PAIRING }.status)
    }

    @Test
    fun `the handed over access lives in memory for the cast and goes when it ends`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pair(tv)

        assertTrue(phone.sender.cast(SERVER, CastItem.Video("movie-1")))
        phone.sender.state.first { it.nowPlaying != null }
        val server = assertNotNull(tv.receiver.handedOver)
        assertEquals(listOf(TOKEN), tv.connected.map { it.token })
        assertEquals(CastItem.Video("movie-1"), tv.playback.loaded.single())
        assertFalse(tv.secrets.entries.values.any { TOKEN in it.decodeToString() }, "the token reached the secret store")
        assertFalse(phone.secrets.entries.values.any { TOKEN in it.decodeToString() }, "the token reached the secret store")

        tv.playback.end()
        val ended = phone.sender.state.first { it.notice != null }
        assertEquals(CastNoticeKind.ENDED, ended.notice?.kind)
        assertEquals(TV.id, ended.target?.id)
        assertNull(ended.nowPlaying)
        assertNull(tv.receiver.handedOver)
        assertSame(server, tv.backends.single())
    }

    @Test
    fun `a new cast replaces the access the one before was handed over with`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pair(tv)

        phone.sender.cast(SERVER, CastItem.Video("movie-1"))
        phone.sender.state.first { it.nowPlaying != null }
        val first = tv.receiver.handedOver
        phone.sender.cast(SERVER, CastItem.Video("movie-2"))
        tv.playback.state.first { it?.title == "movie-2" }
        runCurrent()

        assertEquals(2, tv.backends.size)
        assertSame(tv.backends.last(), tv.receiver.handedOver)
        assertTrue(first !== tv.receiver.handedOver)
    }

    @Test
    fun `the sender shows what the receiver plays and its controls reach the player`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pair(tv)
        phone.sender.cast(SERVER, CastItem.Video("movie-1"))
        val playing = phone.sender.state.first { it.nowPlaying != null }.nowPlaying!!
        assertEquals("movie-1", playing.title)
        assertEquals(TV.name, playing.receiverName)
        assertFalse(playing.paused)
        assertEquals(PHONE.name, tv.playback.state.value?.from)

        phone.sender.togglePause()
        assertTrue(phone.sender.state.first { it.nowPlaying?.paused == true }.nowPlaying!!.paused)
        phone.sender.seekTo(30.0)
        assertEquals(30.0, phone.sender.state.first { it.nowPlaying?.positionSeconds == 30.0 }.nowPlaying!!.positionSeconds)
        phone.sender.setVolume(40)
        phone.sender.state.first { it.nowPlaying?.volume == 40 }
        assertEquals(
            listOf(CastCommand.TogglePause, CastCommand.SeekTo(30_000), CastCommand.Volume(40)),
            tv.playback.commands,
        )
    }

    @Test
    fun `a second sender picks up what plays without restarting it`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        val laptop = net.sender(LAPTOP)
        laptop.pair(tv)
        laptop.sender.disconnect()
        phone.pair(tv)
        phone.sender.cast(SERVER, CastItem.Video("movie-1"))
        phone.sender.state.first { it.nowPlaying != null }

        laptop.sender.openPicker()
        val row = laptop.sender.state.first { state -> state.picker?.devices.orEmpty().any { it.nowPlaying != null } }
            .picker!!.devices.single()
        assertEquals(TV.id, row.device.id)
        laptop.sender.choose(TV.id)
        val picked = laptop.sender.state.first { it.nowPlaying != null }.nowPlaying!!
        assertEquals("movie-1", picked.title)
        assertEquals(1, tv.playback.loaded.size)

        laptop.sender.togglePause()
        phone.sender.state.first { it.nowPlaying?.paused == true }
    }

    @Test
    fun `the receiver keeps playing when the sender leaves`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pair(tv)
        phone.sender.cast(SERVER, CastItem.Video("movie-1"))
        phone.sender.state.first { it.nowPlaying != null }

        phone.sender.disconnect()
        runCurrent()

        assertEquals("movie-1", tv.playback.state.value?.title)
        assertEquals(emptyList(), tv.playback.commands)
        assertNotNull(tv.receiver.handedOver)
        assertEquals(PHONE.name, tv.playback.state.value?.from)
        assertNull(phone.sender.state.value.target)
    }

    @Test
    fun `a sender that gives up while pairing withdraws the receivers question at once`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pickAndChoose()
        tv.receiver.state.first { it.prompt != null }

        phone.sender.closePicker()
        runCurrent()

        assertNull(tv.receiver.state.value.prompt)
        assertEquals(CastLinkStatus.IDLE, phone.sender.state.value.status)
    }

    @Test
    fun `a remembered receiver the picker couldnt reach at first shows what it plays once it answers`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        val laptop = net.sender(LAPTOP)
        laptop.pair(tv)
        laptop.sender.disconnect()
        phone.pair(tv)
        phone.sender.cast(SERVER, CastItem.Video("movie-1"))
        phone.sender.state.first { it.nowPlaying != null }

        net.reachable = false
        laptop.sender.openPicker()
        laptop.sender.state.first { state -> state.picker?.devices.orEmpty().any { it.device.id == TV.id } }
        runCurrent()
        net.reachable = true
        net.receiver(BEDROOM)
        runCurrent()

        val row = laptop.sender.state.value.picker!!.devices.single { it.device.id == TV.id }
        assertNotNull(row.nowPlaying, "${laptop.sender.state.value.picker}")
    }

    @Test
    fun `a receiver turns away a connection past its links while the handshakes before it wait`() = runTest {
        val net = Net(this)
        net.receiver()
        val port = net.discovery.browse().first { it.isNotEmpty() }.single().port

        val waiting = List(ReceiverLimits().maxLinks) { net.connect("10.0.1.$it", port) }
        val extra = net.connect("10.0.2.1", port)
        runCurrent()

        assertTrue(waiting.all { it.incoming.tryReceive().getOrNull() is Frame.Text }, "each waiting one was greeted")
        assertTrue(extra.incoming.receiveCatching().isClosed)
    }

    @Test
    fun `an unreachable receiver tells the sender and leaves it on this device`() = runTest {
        val net = Net(this)
        net.receiver()
        val phone = net.sender()
        net.reachable = false

        phone.pickAndChoose()
        val failed = phone.sender.state.first { it.notice != null }
        assertEquals(CastNoticeKind.RECEIVER_UNREACHABLE, failed.notice?.kind)
        assertNull(failed.target)
    }

    @Test
    fun `a receiver that goes away while linked tells the sender`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pair(tv)

        tv.receiver.close()
        val lost = phone.sender.state.first { it.notice != null }
        assertEquals(CastNoticeKind.RECEIVER_UNREACHABLE, lost.notice?.kind)
        assertNull(lost.target)
        assertFalse(phone.sender.casting)
    }

    @Test
    fun `a server the receiver cant reach tells the sender and leaves it on this device`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pair(tv)
        tv.serverReachable = false

        phone.sender.cast(SERVER, CastItem.Video("movie-1"))
        val failed = phone.sender.state.first { it.notice != null }
        assertEquals(CastNoticeKind.SERVER_UNREACHABLE, failed.notice?.kind)
        assertNull(failed.target)
        assertNull(tv.receiver.handedOver)
    }

    @Test
    fun `an item that fails to play tells the sender and leaves it on this device`() = runTest {
        val net = Net(this)
        val tv = net.receiver()
        val phone = net.sender()
        phone.pair(tv)
        tv.playback.fails = true

        phone.sender.cast(SERVER, CastItem.Video("movie-1"))
        val failed = phone.sender.state.first { it.notice != null }
        assertEquals(CastNoticeKind.PLAYBACK_FAILED, failed.notice?.kind)
        assertNull(failed.target)
        assertNull(tv.receiver.handedOver)

        phone.sender.dismissNotice()
        assertNull(phone.sender.state.value.notice)
    }

    @Test
    fun `a device never lists its own receiver and keeps another device of the same name`() = runTest {
        val net = Net(this)
        net.receiver(LAPTOP)
        val namesake = LAPTOP.copy(id = "laptop-2")
        net.receiver(namesake)
        val known = CompletableDeferred<Unit>()
        val laptop = net.sender(LAPTOP) { known.await() }

        laptop.sender.openPicker()
        runCurrent()
        known.complete(Unit)
        runCurrent()

        assertEquals(listOf(namesake.id), laptop.sender.state.value.picker?.devices?.map { it.device.id })
    }

    @Test
    fun `calls for the install id at once make one id`() = runTest {
        val store = MemorySecretStore()
        val slow = object : SecretStore by store {
            override suspend fun get(key: String): ByteArray? = store.get(key).also { yield() }
        }

        val ids = List(2) { async { CastPeers.installId(slow) } }.awaitAll()

        assertEquals(1, ids.toSet().size)
        assertEquals(ids.first(), CastPeers.installId(store))
    }

    @Test
    fun `a receiver on this machines own address is hidden while one of the same name elsewhere is kept`() = runTest {
        val net = Net(this)
        net.receiver(LAPTOP.copy(id = "laptop-other-install"))
        // Listening first, it takes the first address: the one the sender's machine has.
        runCurrent()
        val elsewhere = LAPTOP.copy(id = "laptop-2")
        net.receiver(elsewhere)
        net.local = setOf("127.0.0.1", "10.0.0.1")
        val laptop = net.sender(LAPTOP)

        laptop.sender.openPicker()
        runCurrent()

        assertEquals(listOf(elsewhere.id), laptop.sender.state.value.picker?.devices?.map { it.device.id })
    }

    /** Receivers and senders on one pretend network: a receiver's port is its address. */
    private class Net(val test: TestScope) {
        private val adverts = MutableStateFlow<List<CastService>>(emptyList())
        private val endpoints = HashMap<Int, (FrameTransport) -> Unit>()
        var reachable = true

        /** The addresses of the machine the senders run on. */
        var local = emptySet<String>()

        val discovery = object : CastDiscovery {
            override fun advertise(instance: String, port: Int, txt: Map<String, String>): AutoCloseable {
                val service = CastService(instance, listOf("10.0.0.$port"), port, txt)
                adverts.update { it + service }
                return AutoCloseable { adverts.update { it - service } }
            }

            override fun browse(): Flow<List<CastService>> = adverts

            override fun localAddresses(): Set<String> = local
        }

        fun receiver(device: CastPeerInfo = TV): Tv = Tv(this, device)

        fun sender(device: CastPeerInfo = PHONE, known: suspend () -> Unit = {}): Phone = Phone(this, device, known)

        fun endpoint(): CastEndpoint = object : CastEndpoint {
            private val port = endpoints.size + 1

            override suspend fun open(accept: (FrameTransport) -> Unit): Int {
                endpoints[port] = accept
                return port
            }

            override fun close() {
                endpoints.remove(port)
            }
        }

        fun connect(from: String, port: Int): FrameTransport {
            val accept = endpoints[port]?.takeIf { reachable } ?: throw IllegalStateException("nothing listens on $port")
            val (receiverEnd, senderEnd) = memoryConnection(from, "10.0.0.$port")
            accept(receiverEnd)
            return senderEnd
        }
    }

    private class Tv(net: Net, device: CastPeerInfo) {
        val secrets = MemorySecretStore()
        val senders = CastPeers(secrets, CastPeers.SENDERS)
        val playback = FakePlayback()
        val connected = mutableListOf<ServerAccess>()
        val backends = mutableListOf<MediaBackend>()
        var serverReachable = true
        val receiver = CastReceiver(
            parentScope = net.test.backgroundScope,
            me = { device },
            senders = senders,
            allowed = flowOf(true),
            playback = playback,
            access = { access ->
                if (!serverReachable) throw CastLoadException(CastFailure.SERVER_UNREACHABLE, "unreachable")
                connected += access
                FakeMediaBackend(access.serverId).also { backends += it }
            },
            endpoint = net.endpoint(),
            discovery = net.discovery,
            timeSource = net.test.testScheduler.timeSource,
        )
    }

    private class Phone(net: Net, device: CastPeerInfo, known: suspend () -> Unit) {
        val secrets = MemorySecretStore()
        val sender = CastSender(
            parentScope = net.test.backgroundScope,
            me = {
                known()
                device
            },
            receivers = CastPeers(secrets, CastPeers.RECEIVERS),
            discovery = net.discovery,
            connect = { _, port -> net.connect(device.id, port) },
            source = object : CastSource {
                override fun access(serverId: String) = ServerAccess(BackendKind.PLEX, serverId, "Server", listOf("http://server.test"), TOKEN)

                override fun current(): Pair<String, CastItem>? = null

                override fun stopLocal() = Unit

                override fun artworkUrl(serverId: String, thumb: String): String? = null
            },
            timeSource = net.test.testScheduler.timeSource,
        )

        /** Opens the picker and chooses the TV once it's listed. */
        suspend fun pickAndChoose(id: String = TV.id) {
            sender.openPicker()
            sender.state.first { state -> state.picker?.devices.orEmpty().any { it.device.id == id } }
            sender.choose(id)
        }

        /** Pairs with [tv] (its user allowing) and links. */
        suspend fun pair(tv: Tv): CastSenderUiState {
            pickAndChoose()
            tv.receiver.state.first { it.prompt != null }
            tv.receiver.approve()
            return sender.state.first { it.status == CastLinkStatus.CONNECTED }
        }
    }

    /** A player that plays any video at once, its title the item's id, and follows the controls. */
    private class FakePlayback : CastPlayback {
        private val mutableState = MutableStateFlow<CastState?>(null)
        override val state: StateFlow<CastState?> = mutableState.asStateFlow()
        val loaded = mutableListOf<CastItem>()
        val commands = mutableListOf<CastCommand>()
        var fails = false

        override suspend fun load(item: CastItem, server: MediaBackend, senderName: String) {
            if (fails) throw CastLoadException(CastFailure.PLAYBACK_FAILED, "no")
            loaded += item
            val id = (item as CastItem.Video).itemId
            mutableState.value = CastState(CastMediaKind.VIDEO, id, paused = false, positionMs = 0, durationMs = 600_000, canSeek = true, volume = 100, from = senderName)
        }

        override fun control(command: CastCommand) {
            commands += command
            mutableState.update { state ->
                when (command) {
                    CastCommand.TogglePause -> state?.copy(paused = !state.paused)
                    is CastCommand.SeekTo -> state?.copy(positionMs = command.ms)
                    is CastCommand.Volume -> state?.copy(volume = command.percent)
                    CastCommand.Stop -> null
                    else -> state
                }
            }
        }

        fun end() {
            mutableState.value = null
        }
    }

    private companion object {
        const val SERVER = "server-1"
        const val TOKEN = "per-server-token"
        val TV = CastPeerInfo("tv-1", "Living Room", "tvOS", CastDeviceKind.TV)
        val PHONE = CastPeerInfo("phone-1", "Phone", "iOS", CastDeviceKind.HANDHELD)
        val LAPTOP = CastPeerInfo("laptop-1", "Laptop", "macOS", CastDeviceKind.DESKTOP)
        val BEDROOM = CastPeerInfo("tv-2", "Bedroom", "Android TV", CastDeviceKind.TV)
    }
}
