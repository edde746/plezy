package com.edde746.plezy.presentation.player

import com.edde746.plezy.playback.STATS_INTERVAL_MS
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * The playback info's readings ([sections]): every [POLL_INTERVAL_MS] while its card is visible, never otherwise.
 * With auto-hide the card fades out with the controls and keeps its last reading, and the reading stops: nothing reads
 * the engine's stats behind a card no one sees. Each reading ([read]) takes the engine's state (the engine reads its
 * stats while the store asks it to, [polling]), the app's memory and the interface's frame rate, which the view counts
 * by calling [onFrame] for each frame it draws while the card shows.
 *
 * The frame rate is measured anew at each reading, over the frames drawn since the last one ([MIN_FPS_WINDOW_NANOS]
 * at least), and the last rate measured stays until then: a card that comes back with the controls shows the rate it
 * had, not "—". Only a card that has never counted a frame has none.
 *
 * Called on the main thread; the store drives it ([update]).
 */
class PlaybackInfoReader internal constructor(
    private val scope: CoroutineScope,
    private val read: (memoryBytes: Long?, uiFps: Double?) -> List<InfoSection>,
    private val memory: () -> Long? = ::residentMemoryBytes,
) {
    private val mutableSections = MutableStateFlow(emptyList<InfoSection>())

    /** The latest reading; the last one stays while the card fades out. */
    val sections: StateFlow<List<InfoSection>> = mutableSections.asStateFlow()

    private var job: Job? = null

    /** The card reads the engine: on, visible and the player on screen. */
    val polling: Boolean get() = job != null

    // The interface's frame rate: frames counted from [fpsFrom] to [lastFrame], measured at each reading ([measure]).
    private var frames = 0
    private var fpsFrom: Long? = null
    private var lastFrame: Long? = null
    private var uiFps: Double? = null

    /**
     * The info is [shown] (the setting), visible ([visible]: shown, and with [autoHide] only while [controlsVisible]),
     * and [onScreen] (not in picture in picture, not in the background): it reads while all hold.
     */
    internal fun update(shown: Boolean, autoHide: Boolean, controlsVisible: Boolean, onScreen: Boolean) {
        val reading = shown && visible(autoHide, controlsVisible) && onScreen
        if (reading == polling) return
        if (reading) {
            frames = 0
            fpsFrom = null
            lastFrame = null
            job = scope.launch {
                while (true) {
                    measure()
                    mutableSections.value = read(memory(), uiFps)
                    delay(POLL_INTERVAL_MS)
                }
            }
        } else {
            job?.cancel()
            job = null
        }
    }

    /** A frame the view drew at [frameTimeNanos] (its frame clock's time) while the card shows. */
    fun onFrame(frameTimeNanos: Long) {
        if (!polling) return
        if (fpsFrom == null) {
            fpsFrom = frameTimeNanos
            frames = 0
            return
        }
        frames++
        lastFrame = frameTimeNanos
    }

    /** The frame rate over the frames counted since the last measure, once they span [MIN_FPS_WINDOW_NANOS]. */
    private fun measure() {
        val from = fpsFrom ?: return
        val last = lastFrame ?: return
        val elapsed = last - from
        if (elapsed < MIN_FPS_WINDOW_NANOS) return
        uiFps = frames * NANOS_PER_SECOND.toDouble() / elapsed
        frames = 0
        fpsFrom = last
    }

    companion object {
        /** How often the card reads: as often as the engine reads its stats. */
        const val POLL_INTERVAL_MS = STATS_INTERVAL_MS

        /** The card shows: always, or with [autoHide] while the controls show. */
        fun visible(autoHide: Boolean, controlsVisible: Boolean): Boolean = !autoHide || controlsVisible

        private const val NANOS_PER_SECOND = 1_000_000_000L

        /** The least span of frames a rate is measured over: a reading right after the card shows measures none. */
        private const val MIN_FPS_WINDOW_NANOS = 250_000_000L
    }
}

/**
 * The playback info as the player shows it ([PlayerUiState.playbackInfo]): [visible] is false while auto-hide has
 * faded it out with the controls.
 */
data class PlaybackInfoState(val visible: Boolean)

/** The app's resident memory in bytes; null where the platform doesn't say. */
internal expect fun residentMemoryBytes(): Long?
