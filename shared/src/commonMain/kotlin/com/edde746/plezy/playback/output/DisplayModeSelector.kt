package com.edde746.plezy.playback.output

import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * The display mode an Android device switches to for a video ([OutputPlan.mode]): its presented frame rate and, on a
 * TV with resolution matching on, its size.
 */
object DisplayModeSelector {
    /**
     * Per-multiple refresh-rate tolerance, in Hz. The comparison happens after multiplication, so the allowance scales
     * with the multiple: an NTSC fractional rate is off by 0.1 % of the content rate, which reaches 0.12 Hz at 5×
     * 23.976 (119.88 against a 120 Hz panel).
     */
    const val RATE_TOLERANCE = 0.1

    /**
     * Longest repeating pulldown [cadence] accepts, in video frames. Four covers every fractional cadence worth
     * switching for (60/23.976 is 2, 90/23.976 is 4); longer patterns spread their irregularity so far apart that
     * ranking them buys nothing.
     */
    const val MAX_CADENCE_PERIOD = 4

    /**
     * How far a cadence may drift from a whole number of vsyncs across its full period. 0.05 vsync accepts the NTSC
     * fractional cadences (60/23.976 is off by 0.005 vsync per 2 frames, 90/23.976 by 0.017 per 4) while rejecting
     * rates that only nearly repeat (50/23.976 is off by 0.17 at every period).
     */
    const val CADENCE_TOLERANCE = 0.05

    /**
     * Content rates a 50/60 Hz-class mode shows at exactly twice their rate: 25 and 29.97/30 fps. Their own 25/30 Hz
     * modes rank after any equally precise multiple: 2:2 at 50/60 Hz has no judder, while a 25/30 Hz mode drags the
     * on-screen controls and subtitle animation down to that rate. Film rates are not doubled: 48 Hz is no broadcast
     * rate, and a 120 Hz panel presents it as a permanent 2:3 where 24 Hz input gets the panel's own 5:5.
     */
    internal val HALF_RATE_FPS = 24.5..30.5

    /**
     * Content-rate error (`error / multiple`, in Hz) below which a half-rate match counts as precise: far above the
     * float noise in reported rates (60.000004), far below the 0.1 % NTSC mismatch (0.03 Hz for 29.97 fps at 60 Hz).
     */
    private const val PRECISE_RATE_ERROR = 0.005

    /** How [refreshRate] presents a rate: exactly ([priority] 0) or as an integer [multiple] of it ([priority] 1). */
    data class RefreshRateMatch(val reason: String, val priority: Int, val error: Double, val multiple: Int)

    /** The mode picked and why, for the log. */
    data class Selection(val mode: DisplayMode, val reason: String)

    /**
     * [period] video frames before the vsync pattern repeats; [drift] is how far it misses a whole number of vsyncs,
     * per frame. Period 1 means every frame is held the same number of vsyncs: no steady-state judder at all.
     */
    data class Cadence(val period: Int, val drift: Double)

    private data class Candidate(val mode: DisplayMode, val match: RefreshRateMatch)

    private data class CadenceCandidate(val mode: DisplayMode, val cadence: Cadence)

    /** How well [refreshRate] presents [fps] content: exactly, as an integer multiple, or not at all (null). */
    fun matchRefreshRate(refreshRate: Double, fps: Double): RefreshRateMatch? {
        if (refreshRate <= 0.0 || fps <= 0.0) return null
        val exactError = abs(refreshRate - fps)
        if (exactError < RATE_TOLERANCE) return RefreshRateMatch("exact", priority = 0, error = exactError, multiple = 1)
        val multiple = (refreshRate / fps).roundToInt()
        if (multiple > 1) {
            val multipleError = abs(refreshRate - fps * multiple)
            if (multipleError < RATE_TOLERANCE * multiple) {
                return RefreshRateMatch("${multiple}x", priority = 1, error = multipleError, multiple = multiple)
            }
        }
        return null
    }

    /**
     * Ranks rate matches for [fps] content: an exact rate first, the nearer one when two are within tolerance; among
     * integer multiples the mode already active, then the largest multiple, then the smaller multiplication error.
     * Content in [HALF_RATE_FPS] ranks by [halfRateRanking] instead.
     *
     * Within the exact tier the current mode earns nothing: [RATE_TOLERANCE] admits a neighbouring rate as exact
     * (60.000004 for 59.94 content), and keeping it because it is active trades a true match for a dropped frame every
     * ~17 s. A clean multiple the display is already in is never traded for another one: the switch would renegotiate
     * the panel for the same cadence. Between multiples, higher is better: a 48 Hz mode on a 120 Hz panel is 2.5
     * panel refreshes per frame, a permanent 2:3, where 120 Hz is a whole 5:5.
     */
    private fun rateRanking(fps: Double, current: DisplayMode): Comparator<Candidate> {
        if (fps in HALF_RATE_FPS) return halfRateRanking(current)
        return compareBy<Candidate> { it.match.priority }
            .thenBy { it.match.priority != 0 && it.mode.id != current.id }
            .thenByDescending { it.match.multiple }
            .thenBy { it.match.error }
            .thenBy { it.mode.id != current.id }
    }

    /**
     * Ranks rate matches for [HALF_RATE_FPS] content: a precise match first, then a multiple over the content's own
     * rate, then the mode already active, then the lowest multiple, then the smaller error.
     *
     * Precision leads for the reason the exact tier ignores the active mode: 60.000004 Hz is a 2× of 29.97 fps within
     * tolerance but repeats a frame every ~17 s, where 59.94 Hz (or 29.97 Hz itself, on a panel without a 59.94 mode)
     * presents it evenly. Among equally precise modes the active one stays, so a display already at 120 Hz keeps 30 fps
     * at 4:4 instead of renegotiating down to 2:2 at 60. Otherwise the lowest multiple wins: 2:2 at 50/60 Hz is
     * already judder-free, and 100/120 Hz only add HDMI bandwidth.
     */
    private fun halfRateRanking(current: DisplayMode): Comparator<Candidate> =
        compareBy<Candidate> { it.match.error / it.match.multiple >= PRECISE_RATE_ERROR }
            .thenBy { it.match.multiple == 1 }
            .thenBy { it.mode.id != current.id }
            .thenBy { it.match.multiple }
            .thenBy { it.match.error }

    /**
     * The cadence [fps] content presents with on a [refreshRate] display, or null when nothing up to
     * [MAX_CADENCE_PERIOD] frames repeats. 60 Hz presents 23.976 as the 3:2 pulldown (period 2), 90 Hz as 4,4,4,3
     * (period 4), 50 Hz never repeats. A pattern whose vsync count divides evenly across its frames is a 1:1, not a
     * pulldown: 23.976 Hz presents 23.8095 fps one vsync per frame. Only meaningful when the display refreshes at least
     * as fast as the content.
     */
    fun cadence(refreshRate: Double, fps: Double): Cadence? {
        if (refreshRate <= 0.0 || fps <= 0.0) return null
        val ratio = refreshRate / fps
        if (ratio < 1.0) return null
        for (period in 2..MAX_CADENCE_PERIOD) {
            val vsyncs = ratio * period
            val rounded = vsyncs.roundToInt()
            val error = abs(vsyncs - rounded)
            if (error >= CADENCE_TOLERANCE) continue
            return Cadence(period = if (rounded % period == 0) 1 else period, drift = error / period)
        }
        return null
    }

    /**
     * The mode among [modes] that presents [fps] best: shortest repeating pattern, then the mode already active, then
     * the slowest drift, then the higher refresh rate.
     */
    private fun shortestCadence(fps: Double, current: DisplayMode, modes: Sequence<DisplayMode>): CadenceCandidate? = modes
        .mapNotNull { mode -> cadence(mode.refreshRate, fps)?.let { CadenceCandidate(mode, it) } }
        .minWithOrNull(
            compareBy<CadenceCandidate> { it.cadence.period }
                .thenBy { it.mode.id != current.id }
                .thenBy { it.cadence.drift }
                .thenByDescending { it.mode.refreshRate },
        )

    /**
     * The mode for a video at [fps] (0 or less for none) of [videoWidth] × [videoHeight] (0 for unknown), or null when
     * nothing is a target. The result may be [current]: the caller pins it rather than switching.
     *
     * With [matchResolution] and known dimensions, resolution wins over cadence: the smallest mode that still contains
     * the video (never downscaling it), rate-matched within that resolution when [fps] is known; a video larger than
     * every mode falls back to the cadence policy. Without it the cadence policy needs [fps] > 0:
     * 1. a rate match at the current resolution;
     * 2. with known dimensions, a rate match at any resolution that contains the video, the one closest in area to the
     *    current first;
     * 3. the shortest pulldown cadence at the current resolution, only when it beats the current mode's.
     */
    fun findBestMode(
        fps: Double,
        current: DisplayMode,
        modes: List<DisplayMode>,
        videoWidth: Int,
        videoHeight: Int,
        matchResolution: Boolean,
    ): Selection? {
        if (matchResolution && videoWidth > 0 && videoHeight > 0) {
            resolutionMatch(fps, current, modes, videoWidth, videoHeight)?.let { return it }
        }
        return cadenceMatch(fps, current, modes, videoWidth, videoHeight)
    }

    private fun resolutionMatch(fps: Double, current: DisplayMode, modes: List<DisplayMode>, videoWidth: Int, videoHeight: Int): Selection? {
        val candidates = modes.filter { it.width >= videoWidth && it.height >= videoHeight }
        if (candidates.isEmpty()) return null
        val targetArea = candidates.minOf { it.area }
        val bucket = candidates.filter { it.area == targetArea }
        if (fps > 0.0) {
            bucket.mapNotNull { mode -> matchRefreshRate(mode.refreshRate, fps)?.let { Candidate(mode, it) } }
                .minWithOrNull(rateRanking(fps, current))
                ?.let { return Selection(it.mode, "resolution + ${it.match.reason} rate, error=${it.match.error}") }
            shortestCadence(fps, current, bucket.asSequence())
                ?.let { return Selection(it.mode, "resolution + ${it.cadence.period}-frame cadence") }
        }
        // Resolution only, or no cadence at the target resolution: the refresh rate closest to the current one.
        return bucket.minWithOrNull(compareBy<DisplayMode> { abs(it.refreshRate - current.refreshRate) }.thenByDescending { it.refreshRate })
            ?.let { Selection(it, "resolution only") }
    }

    private fun cadenceMatch(fps: Double, current: DisplayMode, modes: List<DisplayMode>, videoWidth: Int, videoHeight: Int): Selection? {
        val sameResolution = modes.asSequence().filter { it.width == current.width && it.height == current.height }
        sameResolution.mapNotNull { mode -> matchRefreshRate(mode.refreshRate, fps)?.let { Candidate(mode, it) } }
            .minWithOrNull(rateRanking(fps, current))
            ?.let { return Selection(it.mode, "${it.match.reason}, error=${it.match.error}") }
        if (videoWidth > 0 && videoHeight > 0) {
            modes.asSequence()
                .filter { it.width >= videoWidth && it.height >= videoHeight }
                .mapNotNull { mode -> matchRefreshRate(mode.refreshRate, fps)?.let { Candidate(mode, it) } }
                .minWithOrNull(compareBy<Candidate> { abs(it.mode.area - current.area) }.then(rateRanking(fps, current)))
                ?.let { return Selection(it.mode, "${it.match.reason}, error=${it.match.error}") }
        }
        val currentPeriod = cadence(current.refreshRate, fps)?.period ?: Int.MAX_VALUE
        return shortestCadence(fps, current, sameResolution)
            ?.takeIf { it.cadence.period < currentPeriod }
            ?.let { Selection(it.mode, "${it.cadence.period}-frame cadence") }
    }

    private val DisplayMode.area: Long get() = width.toLong() * height
}
