package com.edde746.plezy.cast

import com.edde746.plezy.format.formatTimecode
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.cast.CastDevice
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.presentation.cast.CastDeviceRow
import com.edde746.plezy.presentation.cast.CastLinkStatus
import com.edde746.plezy.presentation.cast.CastNotice
import com.edde746.plezy.presentation.cast.CastNoticeKind
import com.edde746.plezy.presentation.cast.CastNowPlaying
import com.edde746.plezy.presentation.cast.CastPairingCode
import com.edde746.plezy.presentation.cast.CastPickerUiState
import com.edde746.plezy.presentation.cast.CastSenderUiState
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.TimeSource

/** What a sender casts from: its own server access, what plays here and the artwork of its servers. Main thread. */
internal interface CastSource {
    /** This device's access to [serverId] (its per-server token, never the plex.tv account's); null when it has none. */
    fun access(serverId: String): ServerAccess?

    /** What plays on this device now, where it is: the server and the item to hand over; null when nothing does. */
    fun current(): Pair<String, CastItem>?

    /** Closes this device's player (the video's, or stops the music) once what it played went to a receiver. */
    fun stopLocal()

    /** The poster [thumb] of [serverId] through this device's own access; null without it. */
    fun artworkUrl(serverId: String, thumb: String): String?
}

/** The bounds a sender keeps; tests shorten them. */
internal data class SenderLimits(
    /** A link that hears nothing for this long (the receiver's state comes every second) is lost. */
    val silenceMs: Long = 6_000,
    /** How long the picker says it is searching while it lists nothing. */
    val searchingMs: Long = 5_000,
    val handshake: HandshakeLimits = HandshakeLimits(),
)

/**
 * This device as a cast sender: the picker over the receivers [discovery] finds, the target Play plays on, the target's
 * state and its controls. A receiver this device paired with ([receivers]) links without asking; another pairs first,
 * both devices showing the code. While the picker is open, the remembered receivers are linked to read what they play,
 * so choosing one picks up control without restarting it. Every failure shows a notice and leaves the target: Play plays
 * on this device again. One per app session ([com.edde746.plezy.app.AppSession.castSender]). Main thread.
 */
class CastSender internal constructor(
    parentScope: CoroutineScope,
    private val me: suspend () -> CastPeerInfo,
    private val receivers: CastPeers,
    private val discovery: CastDiscovery?,
    private val connect: suspend (host: String, port: Int) -> FrameTransport,
    private val source: CastSource,
    private val limits: SenderLimits = SenderLimits(),
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(CastSenderUiState())

    val state: StateFlow<CastSenderUiState> = mutableState.asStateFlow()

    // The picker: open since [pickerOpened], what discovery found, the remembered receivers' links and what they play.
    private var pickerOpen = false
    private var fromPlayer = false
    private var pickerOpened = timeSource.markNow()
    private var pickerJob: Job? = null
    private var services: List<CastService> = emptyList()
    private val peeks = HashMap<String, CastLink>()
    private val peekJobs = HashMap<String, Job>()
    private val playing = HashMap<String, CastState?>()
    private var pairing: CastPairingCode? = null

    /** This device's own cast id, read as the picker first opens: its own receiver is never listed. */
    private var selfId: String? = null

    // The target.
    private var target: CastDevice? = null
    private var status = CastLinkStatus.IDLE
    private var link: CastLink? = null
    private var connectJob: Job? = null
    private var linkJob: Job? = null
    private var remote: CastState? = null
    private var controlsOpen = false
    private var notice: CastNotice? = null

    /** Opens the picker and looks for receivers while it is open; [fromPlayer] hands over what plays here on a choice. */
    fun openPicker(fromPlayer: Boolean = false) {
        this.fromPlayer = fromPlayer
        if (pickerOpen) return publish()
        pickerOpen = true
        pickerOpened = timeSource.markNow()
        pickerJob = scope.launch {
            if (selfId == null) {
                launch {
                    selfId = me().id
                    publish()
                }
            }
            launch {
                delay(limits.searchingMs)
                publish()
            }
            discovery?.browse()?.collect { found ->
                val local = discovery.localAddresses().mapTo(HashSet(), ::hostKey)
                // A receiver only this machine's addresses reach runs here (another app or install): never a target.
                services = found.filterNot { service -> service.hosts.all { hostKey(it) in local } }
                peekRemembered()
                publish()
            }
        }
        publish()
    }

    /** Closes the picker; a pairing in progress is cancelled. */
    fun closePicker() {
        if (!pickerOpen) return
        pickerOpen = false
        pickerJob?.cancel()
        pickerJob = null
        services = emptyList()
        peekJobs.values.forEach { it.cancel() }
        peekJobs.clear()
        peeks.values.forEach { it.close() }
        peeks.clear()
        playing.clear()
        if (status == CastLinkStatus.CONNECTING || status == CastLinkStatus.PAIRING) drop(null)
        publish()
    }

    /** Makes receiver [deviceId] the target (pairing first when it doesn't know this device). */
    fun choose(deviceId: String) {
        if (target?.id == deviceId && status != CastLinkStatus.IDLE) return
        val service = services.firstOrNull { it.txt["id"] == deviceId } ?: return
        val device = service.device() ?: return
        drop(null)
        target = device
        status = CastLinkStatus.CONNECTING
        publish()
        connectJob = scope.launch {
            val opened = peeks.remove(deviceId)?.also { peekJobs.remove(deviceId)?.cancel() } ?: try {
                open(service, pair = true)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Couldn't link to ${device.name}" }
                val refused = e is CastHandshakeException && e.reason == CastHandshakeException.Reason.REFUSED
                pairing = null
                drop(if (refused) notice(CastNoticeKind.PAIRING_REFUSED, device.name) else notice(CastNoticeKind.RECEIVER_UNREACHABLE, device.name))
                return@launch
            }
            pairing = null
            remote = playing.remove(deviceId)
            link = opened
            status = CastLinkStatus.CONNECTED
            val handOver = fromPlayer
            closePicker()
            linkJob = scope.launch { follow(opened, device) }
            if (handOver) source.current()?.let { (serverId, item) -> if (cast(serverId, item)) source.stopLocal() }
            publish()
        }
    }

    /** "This device": drops the target, as [disconnect], and closes the picker. */
    fun chooseThisDevice() {
        drop(null)
        closePicker()
    }

    /** Leaves the target: it keeps playing; Play plays here again. */
    fun disconnect() = drop(null)

    fun openControls() {
        if (status != CastLinkStatus.CONNECTED) return
        controlsOpen = true
        publish()
    }

    fun closeControls() {
        controlsOpen = false
        publish()
    }

    fun togglePause() = control(CastCommand.TogglePause)

    fun seekTo(seconds: Double) = control(CastCommand.SeekTo((seconds * 1000).toLong()))

    /** ±10 s from the controls. */
    fun seekBy(seconds: Double) = control(CastCommand.SeekBy((seconds * 1000).toLong()))

    fun selectAudio(key: String) = control(CastCommand.Audio(key))

    fun selectSubtitle(key: String) = control(CastCommand.Subtitle(key))

    fun selectQuality(key: String) = control(CastCommand.Quality(key))

    fun next() = control(CastCommand.Next)

    fun previous() = control(CastCommand.Previous)

    /** Stops playback on the target; the target stays chosen. */
    fun stop() = control(CastCommand.Stop)

    fun setVolume(percent: Int) = control(CastCommand.Volume(percent.coerceIn(0, 100)))

    fun dismissNotice() {
        notice = null
        publish()
    }

    /**
     * Plays [item] of [serverId] on the target with this device's access to that server; false when no target is
     * connected or this device has no access to hand over (the play then happens here).
     */
    fun cast(serverId: String, item: CastItem): Boolean {
        val open = link?.takeIf { status == CastLinkStatus.CONNECTED } ?: return false
        val access = source.access(serverId) ?: return false
        return open.send(CastMessage.Load(access, item))
    }

    /** Whether Play plays on a receiver now. */
    internal val casting: Boolean get() = status == CastLinkStatus.CONNECTED

    private fun control(command: CastCommand) {
        link?.takeIf { status == CastLinkStatus.CONNECTED }?.send(CastMessage.Control(command))
    }

    /** Opens a link to [service]'s receiver over its addresses in turn; throws the last failure. */
    private suspend fun open(service: CastService, pair: Boolean): CastLink {
        val id = service.txt["id"]
        val me = me()
        var failure: Exception = IllegalStateException("${service.instance} has no address")
        for (host in service.hosts) {
            val transport = try {
                connect(host, service.port)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                failure = e
                continue
            }
            return senderHandshake(
                transport, me, id, receivers::get, pair,
                onCode = { receiver, code ->
                    pairing = CastPairingCode(receiver.name, code, T.cast.pairing.senderTitle(receiver.name), T.cast.pairing.senderMessage(receiver.name))
                    if (target?.id == receiver.id) status = CastLinkStatus.PAIRING
                    publish()
                },
                remember = receivers::remember, forget = receivers::forget, scope = scope, limits = limits.handshake,
            )
        }
        throw failure
    }

    /**
     * Links the remembered receivers the picker lists (not the target) to read what they play; one that failed is tried
     * again as the list changes.
     */
    private suspend fun peekRemembered() {
        val remembered = receivers.load().map { it.device.id }.toSet()
        for (service in services) {
            val id = service.txt["id"] ?: continue
            if (id !in remembered || id == target?.id || id in peekJobs) continue
            peekJobs[id] = scope.launch {
                try {
                    val opened = try {
                        open(service, pair = false)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.d(TAG, e) { "Couldn't read what ${service.instance} plays" }
                        return@launch
                    }
                    peeks[id] = opened
                    opened.incoming.collect { message ->
                        if (message is CastMessage.State && peeks[id] === opened) {
                            playing[id] = message.state
                            publish()
                        }
                    }
                    if (peeks[id] === opened) {
                        peeks.remove(id)
                        playing.remove(id)
                        publish()
                    }
                } finally {
                    if (peekJobs[id] === coroutineContext[Job]) peekJobs.remove(id)
                }
            }
        }
    }

    /** Follows the target's link until it ends; an end that isn't this device's own drops the target. */
    private suspend fun follow(open: CastLink, device: CastDevice) {
        var heard = timeSource.markNow()
        val watchdog = scope.launch {
            while (true) {
                delay(limits.silenceMs / 3)
                if (heard.elapsedNow().inWholeMilliseconds > limits.silenceMs) {
                    Log.w(TAG) { "${device.name} went silent" }
                    open.close()
                    return@launch
                }
            }
        }
        try {
            open.incoming.collect { message ->
                heard = timeSource.markNow()
                when (message) {
                    is CastMessage.State -> remote = message.state
                    CastMessage.Ended -> {
                        remote = null
                        controlsOpen = false
                        notice = notice(CastNoticeKind.ENDED, device.name)
                    }
                    is CastMessage.Failed -> {
                        val kind = when (message.failure) {
                            CastFailure.SERVER_UNREACHABLE -> CastNoticeKind.SERVER_UNREACHABLE
                            CastFailure.PLAYBACK_FAILED -> CastNoticeKind.PLAYBACK_FAILED
                        }
                        return@collect drop(notice(kind, device.name))
                    }
                    else -> Unit
                }
                publish()
            }
        } finally {
            watchdog.cancel()
        }
        if (link === open) drop(notice(CastNoticeKind.RECEIVER_UNREACHABLE, device.name))
    }

    /** Leaves the target (with [why] to show): its link closes, Play plays here again. */
    private fun drop(why: CastNotice?) {
        connectJob?.cancel()
        connectJob = null
        val open = link
        link = null
        linkJob?.cancel()
        linkJob = null
        open?.close()
        target = null
        status = CastLinkStatus.IDLE
        remote = null
        controlsOpen = false
        pairing = null
        if (why != null) notice = why
        publish()
    }

    private fun notice(kind: CastNoticeKind, name: String): CastNotice = CastNotice(
        kind,
        when (kind) {
            CastNoticeKind.RECEIVER_UNREACHABLE -> T.cast.errors.receiverUnreachable(name)
            CastNoticeKind.PAIRING_REFUSED -> T.cast.errors.pairingRefused(name)
            CastNoticeKind.SERVER_UNREACHABLE -> T.cast.errors.serverUnreachable(name)
            CastNoticeKind.PLAYBACK_FAILED -> T.cast.errors.playbackFailed(name)
            CastNoticeKind.ENDED -> T.cast.errors.ended(name)
        },
    )

    private fun publish() {
        val target = target
        mutableState.value = CastSenderUiState(
            target = target,
            status = status,
            picker = if (pickerOpen) picker() else null,
            nowPlaying = remote?.takeIf { status == CastLinkStatus.CONNECTED }?.let { nowPlaying(it, target?.name.orEmpty()) },
            controlsOpen = controlsOpen && status == CastLinkStatus.CONNECTED,
            notice = notice,
        )
    }

    private fun picker(): CastPickerUiState {
        // No receiver is listed until this device's own id is known: its own receiver may be among them.
        val selfId = selfId
        val devices = services.takeIf { selfId != null }.orEmpty().mapNotNull { service ->
            val device = service.device()?.takeIf { it.id != selfId } ?: return@mapNotNull null
            val selected = target?.id == device.id
            val plays = if (selected && status == CastLinkStatus.CONNECTED) remote else playing[device.id]
            CastDeviceRow(
                device = device,
                selected = selected && status == CastLinkStatus.CONNECTED,
                connecting = selected && status != CastLinkStatus.CONNECTED,
                nowPlaying = plays?.title?.let(T.cast.picker::playing),
            )
        }.distinctBy { it.device.id }
        return CastPickerUiState(
            fromPlayer = fromPlayer,
            devices = devices,
            thisDeviceSelected = target == null,
            searching = devices.isEmpty() && pickerOpened.elapsedNow().inWholeMilliseconds < limits.searchingMs,
            pairing = pairing,
        )
    }

    private fun nowPlaying(state: CastState, receiverName: String): CastNowPlaying {
        val position = state.positionMs / 1000.0
        val duration = state.durationMs / 1000.0
        return CastNowPlaying(
            receiverName = receiverName,
            kind = state.kind,
            title = state.title,
            subtitle = state.subtitle,
            artworkUrl = state.serverId?.let { serverId -> state.thumb?.let { source.artworkUrl(serverId, it) } },
            paused = state.paused,
            buffering = state.buffering,
            positionSeconds = position,
            durationSeconds = duration,
            position = formatTimecode(position),
            duration = formatTimecode(duration),
            progress = if (state.durationMs > 0) (state.positionMs.toFloat() / state.durationMs).coerceIn(0f, 1f) else 0f,
            canSeek = state.canSeek,
            audioTracks = state.audio,
            subtitleTracks = state.subtitles,
            qualities = state.qualities,
            hasPrevious = state.hasPrevious,
            hasNext = state.hasNext,
            volume = state.volume,
        )
    }

    internal fun close() = scope.cancel()

    private companion object {
        const val TAG = "CastSender"

        /** An IP literal as compared: without an IPv6 scope (`%en0`), lower case. */
        fun hostKey(host: String): String = host.substringBefore('%').lowercase()

        fun CastService.device(): CastDevice? {
            val id = txt["id"]?.takeIf { it.isNotEmpty() } ?: return null
            val kind = CastDeviceKind.entries.firstOrNull { it.name == txt["kind"] } ?: CastDeviceKind.TV
            return CastDevice(id, txt["name"]?.takeIf { it.isNotEmpty() } ?: instance, txt["platform"].orEmpty(), kind)
        }
    }
}
