package com.edde746.plezy.playback.output

import com.edde746.plezy.crash.Breadcrumb
import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.ServerStream
import com.edde746.plezy.playback.VideoInfo
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.flow.transformLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

/**
 * The platform's side of a playback's output (display-mode and HDR switching, passthrough): the display
 * the player is on, and switching it and the audio route to what [OutputPolicy] decides. One per playback on
 * platforms that can switch something (`PlatformPlayback.output`). Called on the main thread.
 */
interface PlaybackOutputHost {
    /**
     * The display the player is on, before the playback changed anything. Read once per playback, at its start. It
     * suspends rather than blocking the main thread while the display can't be read yet (Windows: the previous
     * playback's restore of the mode and HDR still running).
     */
    suspend fun display(): DisplayInfo

    /**
     * Makes the output follow [plan], and returns once the display has settled on it: where it switches the display's
     * mode or HDR state, after the switch landed and [OutputPlan.switchDelaySeconds] more, playback held meanwhile
     * (the engine's hold); at once where nothing switches. Each plan is complete ([OutputPlan]): what it leaves at its
     * default (no [OutputPlan.mode], no [OutputPlan.enableHdr]) goes back to how it was before the playback, if an
     * earlier plan changed it. The engine's HDR output follows [OutputPlan.hdrOutput]
     * ([com.edde746.plezy.playback.PlayerEngine.setHdrOutput], [awaitHdrOutput]); the result is whether the engine took
     * it. Cancelled when a newer plan replaces it: the hold it took goes with it.
     */
    suspend fun apply(plan: OutputPlan): Boolean

    /**
     * The platform switches the display's mode before the engine opens a file ([PlaybackOutput.preOpen]): Android,
     * whose HDMI renegotiation once the audio output is open breaks passthrough on a SHIELD's and a receiver's chain.
     */
    val switchesBeforeOpen: Boolean get() = false

    /**
     * Holds the video decoder of the next file the engine opens, between its demuxer and its decoder, where a host
     * that switches before the open ([switchesBeforeOpen]) can (Android's mpv, at `on_preloaded`): asked right before
     * the open, for a file whose server didn't say its rate or size. A decoder made before an HDMI mode switch can stay
     * bound to the old mode (a Fire TV Stick 4K's Dolby Vision decoder showed the picture green and purple), so the
     * display switches in between. Null where the engine has no such hold.
     */
    fun holdDecoder(): DecoderHold? = null

    /**
     * The playback ended: the display's mode and HDR state as they were before it. A platform whose app can quit
     * during a playback also restores on its way out.
     */
    fun restore()
}

/** A hold on the next opened file's video decoder ([PlaybackOutputHost.holdDecoder]). */
interface DecoderHold {
    /**
     * The held file's video as its container declares it (rate, size; SDR) once the engine reached the hold; null when
     * nothing was held: no video track, the open failed or was superseded, the engine went away.
     */
    suspend fun video(): VideoInfo?

    /** Lets the held decoder open; before the hold was reached, cancels it, so it can't hold a later file instead. */
    fun release()
}

/** [PlayerEngine.setHdrOutput], returning once the engine answered whether it took [enabled]. */
suspend fun PlayerEngine.awaitHdrOutput(enabled: Boolean): Boolean = suspendCancellableCoroutine { done ->
    setHdrOutput(enabled) { applied -> done.resume(applied) }
}

/**
 * One playback's output on a [formFactor] device: [PlaybackOutputHost.apply]s a plan without a video once the display
 * is read (HDR output as the setting, the player's HDR switch and the display allow, the audio passthrough), then a
 * plan for each item at its first frame, and again whenever the player enters or leaves [fullscreen] (a desktop
 * switches only while fullscreen), the [settings] change or the player's HDR switch flips ([setHdr]), and restores the
 * display when [release]d. Where the host switches before the engine opens ([PlaybackOutputHost.switchesBeforeOpen]),
 * [preOpen] plans for the server's video first, or for the video the file's container declares while the engine holds
 * its decoder ([PlaybackOutputHost.holdDecoder]); its first frame's plan then finds the display in the mode it asks for
 * and switches again only where the presented video differs (a decoder that deinterlaces presents fields).
 *
 * Each item is measured once ([EngineState.loadId]): its first [VideoInfo] once the first frame is up, at the rate the
 * player presents it. A rate mpv reports after the first frame (`container-fps` is a property change of its own) gets
 * [RATE_WAIT_MS]; an item that has none by then is planned without one. Between items the last plan stays. The
 * display is read once, at the start, so every plan is decided against the display's own state.
 *
 * While the item's first plan is being applied ([negotiating]: the display switches for it) the player keeps its first
 * frame behind the loading state; a newer item or plan abandons that negotiation, never releasing the newer one's.
 *
 * Main thread.
 */
class PlaybackOutput internal constructor(
    private val engineState: StateFlow<EngineState>,
    fullscreen: Flow<Boolean>,
    private val formFactor: FormFactor,
    private val settings: Flow<DeviceSettings>,
    private val host: PlaybackOutputHost,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private var applied: OutputPlan? = null
    private var released = false
    private val mutableNegotiating = MutableStateFlow(false)

    /** The item whose first plan went out last. */
    private var negotiated: Long? = null

    /** Orders measured items and pre-open videos: the later one is what the display follows. */
    private var sequence = 0L

    /** The video [preOpen] switches for, until an item measured after it. */
    private val preOpened = MutableStateFlow<PreOpen?>(null)

    /** The player's HDR switch while it differs from the stored setting ([setHdr]): the plan's HDR input in its place. */
    private val hdrSwitch = MutableStateFlow<HdrSwitch?>(null)

    /** A development build's Dolby Vision conversion for this playback ([setDolbyVisionConversion]), in the setting's place. */
    private val dvConversion = MutableStateFlow<DolbyVisionConversion?>(null)

    /** The display couldn't be read: no plan goes out, and the HDR switch is refused. */
    private var planless = false

    /** Whether the engine took the HDR output of the plan out now ([PlaybackOutputHost.apply]). */
    private var lastTaken = true

    /** The display is switching for the current item's first frame: the player shows it once this is false. */
    val negotiating: StateFlow<Boolean> = mutableNegotiating.asStateFlow()

    init {
        scope.launch {
            val display = try {
                host.display()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "reading the display failed; the output stays as it is" }
                planless = true
                hdrSwitch.value?.taken?.complete(false)
                return@launch
            }
            Log.i(TAG) { "display: $display" }
            val inputs = combine(settings.distinctUntilChanged(), hdrSwitch, dvConversion) { loaded, switch, conversion ->
                Inputs(loaded.copy(hdr = switch?.enabled ?: loaded.hdr, dvConversionMode = conversion ?: loaded.dvConversionMode), switch)
            }
            combine(items(), preOpened, fullscreen.distinctUntilChanged(), inputs) { item, pre, inFullscreen, input ->
                val ahead = pre?.takeIf { item == null || item.sequence < it.sequence }
                Planned(item.takeIf { ahead == null }, ahead, input.hdrSwitch, OutputPolicy.plan(ahead?.video ?: item?.video, display, input.settings, formFactor, inFullscreen))
            }.collectLatest { planned ->
                val taken = apply(planned.item, planned.plan)
                planned.preOpen?.settled?.complete(Unit)
                planned.hdrSwitch?.taken?.complete(taken)
            }
        }
    }

    /** The playback ended: the display goes back to how it was, if anything changed it. */
    fun release() {
        if (released) return
        released = true
        scope.cancel()
        mutableNegotiating.value = false
        hdrSwitch.value?.taken?.complete(false)
        if (applied != null) host.restore()
    }

    /**
     * Before the engine opens [server]'s stream (a VOD file; null for a download): where the host switches first and
     * the settings ask for the video's rate or size ([OutputPolicy.preOpenVideo]), plans for the server's video and
     * returns once the display settled on it, at most [PRE_OPEN_WAIT_MS]. Where the server doesn't say ([server] null,
     * a transcode, no rate or size) and the host can hold the decoder, arms that hold and returns at once: the file's
     * declared video is planned for while its decoder waits, released once the display settled (at most
     * [PRE_OPEN_WAIT_MS]) or when nothing switches. At once otherwise.
     */
    suspend fun preOpen(server: ServerStream?) {
        if (released || !host.switchesBeforeOpen) return
        val current = settings.first()
        val video = OutputPolicy.preOpenVideo(server, current, formFactor)
        if (video == null) {
            if (!OutputPolicy.switchesBeforeDecoder(current, formFactor)) return
            val hold = host.holdDecoder() ?: return
            scope.launch(start = CoroutineStart.UNDISPATCHED) { switchBeforeDecoder(hold) }
            return
        }
        Log.i(TAG) { "before the open: $video" }
        planAhead(video)
    }

    /** Plans for the video [hold]'s file declares while its decoder waits, and lets the decoder go once settled. */
    private suspend fun switchBeforeDecoder(hold: DecoderHold) {
        try {
            val declared = hold.video() ?: return
            val video = OutputPolicy.preDecoderVideo(declared, settings.first(), formFactor) ?: return
            Log.i(TAG) { "before the decoder: $video" }
            planAhead(video)
        } finally {
            hold.release()
        }
    }

    /** Plans for [video] ahead of the item's first frame and waits for the display to settle, at most [PRE_OPEN_WAIT_MS]. */
    private suspend fun planAhead(video: VideoInfo) {
        val pre = PreOpen(++sequence, video)
        preOpened.value = pre
        if (withTimeoutOrNull(PRE_OPEN_WAIT_MS) { pre.settled.await() } == null) {
            Log.w(TAG) { "the display didn't settle ahead of the video within $PRE_OPEN_WAIT_MS ms; going on anyway" }
        }
    }

    /**
     * The player's HDR switch: [enabled] becomes the plan's HDR input in place of the Hdr setting, alongside the
     * display's support, and the plan that follows writes the engine. Returns whether the engine took that plan's HDR
     * output: refused, the input goes back to what it was (and the engine with it). Taken, the caller stores the
     * setting, and the switch stands in for it until the stored setting says the same.
     */
    suspend fun setHdr(enabled: Boolean): Boolean {
        if (released || planless) return false
        val previous = hdrSwitch.value
        val switch = HdrSwitch(enabled)
        hdrSwitch.value = switch
        val taken = switch.taken.await()
        if (!taken) {
            if (hdrSwitch.value === switch) hdrSwitch.value = previous
            return false
        }
        scope.launch {
            settings.first { it.hdr == enabled }
            if (hdrSwitch.value === switch) hdrSwitch.value = null
        }
        return true
    }

    /**
     * A development build's Dolby Vision conversion for the rest of this playback, in place of the setting (not kept):
     * the plan's input, which the engine takes from its next decoder.
     */
    fun setDolbyVisionConversion(mode: DolbyVisionConversion) {
        dvConversion.value = mode
    }

    /**
     * The video was unloaded in the background (a TV's suspend): the display goes back to how it was, and the next
     * item's first frame plans it again.
     */
    fun suspend() {
        if (released || applied == null) return
        applied = null
        negotiated = null
        host.restore()
    }

    /** null, then each item's measured video ([Item]). */
    @OptIn(ExperimentalCoroutinesApi::class)
    private fun items(): Flow<Item?> = engineState.map { it.loadId }.distinctUntilChanged().transformLatest<Long, Item?> { loadId ->
        val shown = engineState.first { it.loadId == loadId && it.loaded && it.video != null }
        val video = if (shown.video?.fps != null) {
            shown.video
        } else {
            withTimeoutOrNull(RATE_WAIT_MS) { engineState.first { it.loadId == loadId && it.video?.fps != null } }?.video ?: shown.video
        }
        emit(Item(loadId, video, ++sequence))
    }.onStart { emit(null) }

    /** Applies [plan] unless it is the one out already; whether the engine took its HDR output (an unchanged plan's was). */
    private suspend fun apply(item: Item?, plan: OutputPlan): Boolean {
        if (plan == applied) return lastTaken
        val firstOfItem = item != null && item.loadId != negotiated
        applied = plan
        if (firstOfItem) negotiated = item.loadId
        Log.i(TAG) { "plan: $plan" }
        // The display's mode and dynamic range switch: the crash report's trail says what the player asked for.
        CrashCapture.breadcrumb(Breadcrumb("player", "Display output: $plan"))
        mutableNegotiating.value = firstOfItem
        try {
            lastTaken = host.apply(plan)
            if (!lastTaken) Log.w(TAG) { "the engine refused HDR output ${plan.hdrOutput}" }
            return lastTaken
        } finally {
            mutableNegotiating.value = false
        }
    }

    /** An item ([EngineState.loadId]) as the plans see it: its video as measured, and when ([sequence]). */
    private data class Item(val loadId: Long, val video: VideoInfo?, val sequence: Long)

    /** A video planned for before the engine opens it; [settled] once the display is on its plan. */
    private class PreOpen(val sequence: Long, val video: VideoInfo) {
        val settled = CompletableDeferred<Unit>()
    }

    /** The HDR switch at [enabled]; [taken] once the plan with it went out, with whether the engine took it. */
    private class HdrSwitch(val enabled: Boolean) {
        val taken = CompletableDeferred<Boolean>()
    }

    private data class Planned(val item: Item?, val preOpen: PreOpen?, val hdrSwitch: HdrSwitch?, val plan: OutputPlan)

    /** The settings as the plan takes them, the player's HDR switch and Dolby Vision conversion in place. */
    private data class Inputs(val settings: DeviceSettings, val hdrSwitch: HdrSwitch?)

    internal companion object {
        const val TAG = "PlaybackOutput"

        /**
         * How long an item's first frame waits for its frame rate when mpv reports it after the frame: ten tries half
         * a second apart.
         */
        const val RATE_WAIT_MS = 5_000L

        /**
         * The longest an open waits for the display to settle before it ([preOpen]): a switch's own settle (2 s and the
         * display switch delay, at most 10 s) and 3 s for a display that never lands.
         */
        const val PRE_OPEN_WAIT_MS = 16_000L
    }
}
