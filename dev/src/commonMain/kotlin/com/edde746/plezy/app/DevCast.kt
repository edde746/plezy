package com.edde746.plezy.app

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.cast.CastCommand
import com.edde746.plezy.cast.CastDiscovery
import com.edde746.plezy.cast.CastItem
import com.edde746.plezy.cast.CastPeerInfo
import com.edde746.plezy.cast.CastPlayback
import com.edde746.plezy.cast.CastService
import com.edde746.plezy.cast.CastState
import com.edde746.plezy.log.Log
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.presentation.cast.CastLinkStatus
import com.edde746.plezy.presentation.cast.CastMediaKind
import com.edde746.plezy.presentation.cast.CastOption
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.seconds

/**
 * `cast.demo` ([DevSetting.CastDemo]): stand-ins for a second device on the network, running the real cast stack in this
 * process over loopback. The receiver "Demo TV" is listed in this app's picker, pairs with a code (approving after 5 s)
 * and plays a pretend video, "Demo Movie", that answers every control. The sender "Demo Phone" links to this app's own
 * receiver (its pairing prompt shows here, over the player `--dev-play` opened) and, once allowed, casts that item here,
 * replacing the local play; without `--dev-play` it links 3 s after the start and casts nothing.
 */
internal class DevCastDemo(platform: CastDiscovery?) {
    private val adverts = MutableStateFlow<List<CastService>>(emptyList())

    /** This app's discovery: the network's, plus the stand-ins and this app's own receiver on loopback. */
    val app: CastDiscovery = Discovery(platform)

    /** The stand-ins': loopback only, so no other device on the network finds them. */
    private val local: CastDiscovery = Discovery(null)

    private inner class Discovery(private val network: CastDiscovery?) : CastDiscovery {
        override fun advertise(instance: String, port: Int, txt: Map<String, String>): AutoCloseable {
            val service = CastService(instance, listOf(LOOPBACK), port, txt)
            adverts.update { it + service }
            val announced = network?.advertise(instance, port, txt)
            return AutoCloseable {
                adverts.update { it - service }
                announced?.close()
            }
        }

        // The stand-ins answer on loopback in place of other devices: loopback isn't this machine for them.
        override fun localAddresses(): Set<String> = network?.localAddresses().orEmpty() - LOOPBACK

        override fun browse(): Flow<List<CastService>> =
            if (network == null) adverts else combine(adverts, network.browse()) { here, found -> here + found }
    }

    /** Starts "Demo TV" in [app], on [scope]. */
    fun startReceiver(app: AppSession, scope: CoroutineScope) {
        val receiver = app.castPeerReceiver(DEMO_TV, DemoPlayback(scope), local)
        scope.launch {
            receiver.state.map { it.prompt }.collect { prompt ->
                if (prompt != null) {
                    delay(APPROVE_AFTER)
                    receiver.approve()
                }
            }
        }
    }

    /**
     * Runs "Demo Phone" in [app]: it links to this app's receiver once it's announced, then casts [play] when given.
     * Returns once it cast, was refused or gave up.
     */
    suspend fun runSender(app: AppSession, play: PlayRequest.Item?) {
        val sender = app.castPeerSender(DEMO_PHONE, local)
        Log.i(TAG) { "Demo Phone looks for this app's receiver" }
        sender.openPicker()
        val receiver = withTimeoutOrNull(FIND_TIMEOUT) {
            sender.state.first { state -> state.picker?.devices.orEmpty().any { it.device.id != DEMO_TV.id } }
        }?.picker?.devices?.first { it.device.id != DEMO_TV.id }?.device
        if (receiver == null) {
            sender.closePicker()
            return Log.w(TAG) { "This app's receiver never showed: is casting allowed here?" }
        }
        Log.i(TAG) { "Demo Phone links to ${receiver.name}" }
        sender.choose(receiver.id)
        val linked = sender.state.first { it.status == CastLinkStatus.CONNECTED || (it.status == CastLinkStatus.IDLE && it.notice != null) }
        if (linked.status != CastLinkStatus.CONNECTED) return Log.i(TAG) { "Demo Phone didn't link: ${linked.notice?.message}" }
        val request = play ?: return Log.i(TAG) { "Demo Phone linked; nothing to cast" }
        val cast = sender.cast(request.serverId.value, CastItem.Video(request.itemId))
        Log.i(TAG) { if (cast) "Demo Phone cast ${request.itemId}" else "Demo Phone couldn't cast ${request.itemId}" }
    }

    /** "Demo Movie": a pretend video whose position runs while it plays, whatever was cast (logged). */
    private class DemoPlayback(private val scope: CoroutineScope) : CastPlayback {
        private val mutableState = MutableStateFlow<CastState?>(null)
        override val state: StateFlow<CastState?> = mutableState.asStateFlow()
        private var clock: Job? = null

        override suspend fun load(item: CastItem, server: MediaBackend, senderName: String) {
            Log.i(TAG) { "Demo TV plays $item from $senderName" }
            mutableState.value = CastState(
                kind = CastMediaKind.VIDEO,
                title = DEMO_TITLE,
                paused = false,
                positionMs = 0,
                durationMs = DURATION_MS,
                canSeek = true,
                audio = options(AUDIO, 0),
                subtitles = options(SUBTITLES, 0),
                qualities = options(QUALITIES, 0),
                hasNext = true,
                volume = 100,
                from = senderName,
            )
            clock?.cancel()
            clock = scope.launch {
                while (true) {
                    delay(TICK_MS)
                    update { if (it.paused) it else it.copy(positionMs = (it.positionMs + TICK_MS).coerceAtMost(DURATION_MS)) }
                }
            }
        }

        override fun control(command: CastCommand) {
            when (command) {
                CastCommand.TogglePause -> update { it.copy(paused = !it.paused) }
                is CastCommand.SeekTo -> update { it.copy(positionMs = command.ms.coerceIn(0, DURATION_MS)) }
                is CastCommand.SeekBy -> update { it.copy(positionMs = (it.positionMs + command.ms).coerceIn(0, DURATION_MS)) }
                is CastCommand.Audio -> update { it.copy(audio = it.audio.map { o -> o.copy(selected = o.key == command.key) }) }
                is CastCommand.Subtitle -> update { it.copy(subtitles = it.subtitles.map { o -> o.copy(selected = o.key == command.key) }) }
                is CastCommand.Quality -> update { it.copy(qualities = it.qualities.map { o -> o.copy(selected = o.key == command.key) }) }
                CastCommand.Next -> update { it.copy(positionMs = 0, hasPrevious = true, hasNext = false) }
                CastCommand.Previous -> update { it.copy(positionMs = 0, hasPrevious = false, hasNext = true) }
                CastCommand.Stop -> {
                    clock?.cancel()
                    mutableState.value = null
                }
                is CastCommand.Volume -> update { it.copy(volume = command.percent) }
            }
        }

        private fun update(change: (CastState) -> CastState) {
            mutableState.update { it?.let(change) }
        }

        private fun options(labels: List<String>, selected: Int): List<CastOption> =
            labels.mapIndexed { index, label -> CastOption("$index", label, null, index == selected) }
    }

    private companion object {
        const val TAG = "DevCastDemo"
        const val LOOPBACK = "127.0.0.1"
        const val DEMO_TITLE = "Demo Movie"
        const val DURATION_MS = 2L * 60 * 60 * 1000
        const val TICK_MS = 1_000L
        val APPROVE_AFTER = 5.seconds
        val FIND_TIMEOUT = 60.seconds
        val DEMO_TV = CastPeerInfo("demo-tv", "Demo TV", "tvOS", CastDeviceKind.TV)
        val DEMO_PHONE = CastPeerInfo("demo-phone", "Demo Phone", "iOS", CastDeviceKind.HANDHELD)
        val AUDIO = listOf("English", "Commentary")
        val SUBTITLES = listOf("Off", "English")
        val QUALITIES = listOf("Original", "1080p", "720p")
    }
}
