package com.edde746.plezy.shared

import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Pure display-mode selection policy for content-adaptive display switching.
 * Extracted from [FrameRateManager] so the policy is unit-testable on the
 * JVM, where android.view.Display.Mode cannot be instantiated.
 */
object DisplayModeSelector {
  /**
   * Per-multiple refresh-rate tolerance, in Hz. The comparison happens after
   * multiplication, so the allowance scales with the multiple: an NTSC
   * fractional rate is off by 0.1% of the content rate, which reaches
   * 0.12 Hz at 5x 23.976 (= 119.88 against a 120 Hz panel).
   */
  const val RATE_TOLERANCE = 0.1f

  /**
   * Longest repeating pulldown [cadence] will accept, in video frames.
   * Four covers every fractional cadence worth switching for (60/23.976 is 2,
   * 90/23.976 is 4); longer patterns spread their irregularity so far apart
   * that ranking them buys nothing.
   */
  const val MAX_CADENCE_PERIOD = 4

  /**
   * How far a cadence may drift from a whole number of vsyncs across its full
   * period. 0.05 vsync accepts the NTSC fractional cadences (60/23.976 is off
   * by 0.005 vsync per 2 frames, 90/23.976 by 0.017 per 4) while rejecting
   * rates that only nearly repeat (50/23.976 is off by 0.17 at every period).
   */
  const val CADENCE_TOLERANCE = 0.05f

  /**
   * Content rates a 50/60 Hz-class mode shows at exactly twice their rate:
   * 25 and 29.97/30 fps. [halfRateRanking] ranks their own 25/30 Hz modes
   * after any equally precise multiple (#3090): 2:2 at 50/60 Hz has no
   * judder, while a 25/30 Hz mode drags the OSD and subtitle animation down
   * to that rate. Kodi's default whitelist leaves out the same 25/29.97/30 Hz
   * modes.
   *
   * Film rates are deliberately not doubled: 48 Hz is no broadcast rate, and
   * a 120 Hz panel presents it as a permanent 2:3 (#2255) where 24 Hz input
   * gets the panel's own 5:5.
   */
  private const val HALF_RATE_MIN_FPS = 24.5f
  private const val HALF_RATE_MAX_FPS = 30.5f

  /**
   * Content-rate error, `|refreshRate / multiple - fps|` in Hz, below which
   * [halfRateRanking] counts a match as precise: far above the float noise in
   * reported rates (60.000004), far below the 0.1% NTSC mismatch (0.03 Hz for
   * 29.97 fps at 60 Hz).
   */
  private const val PRECISE_RATE_ERROR = 0.005f

  /** JVM-testable mirror of android.view.Display.Mode. */
  data class ModeInfo(val modeId: Int, val width: Int, val height: Int, val refreshRate: Float) {
    val area: Long get() = width.toLong() * height
  }

  data class RefreshRateMatch(val reason: String, val priority: Int, val error: Float, val multiple: Int)

  data class Selection(val mode: ModeInfo, val reason: String)

  private data class Candidate(val mode: ModeInfo, val match: RefreshRateMatch)

  /** [period] video frames before the vsync pattern repeats; [drift] is how
   * far it misses a whole number of vsyncs, per frame, so `1 / (drift * fps)`
   * is the mean seconds between cadence breaks. Period 1 means every frame is
   * held the same number of vsyncs — no steady-state judder at all. */
  data class Cadence(val period: Int, val drift: Float)

  private data class CadenceCandidate(val mode: ModeInfo, val cadence: Cadence)

  /** How well [refreshRate] presents [fps] content: exact, an integer multiple, or not at all. */
  fun matchRefreshRate(refreshRate: Float, fps: Float): RefreshRateMatch? {
    if (refreshRate <= 0f || fps <= 0f) return null

    val exactError = abs(refreshRate - fps)
    if (exactError < RATE_TOLERANCE) {
      return RefreshRateMatch(reason = "exact", priority = 0, error = exactError, multiple = 1)
    }

    // The error is measured after multiplication, so the tolerance has to
    // scale with the multiple. A flat 0.1 Hz rejects |120 - 5 * 23.976| =
    // 0.12, which would make every 120 Hz panel fail to rate-match
    // NTSC-fractional content — exactly where 120/24p is the ideal 5:5.
    val multiple = (refreshRate / fps).roundToInt()
    if (multiple > 1) {
      val multipleError = abs(refreshRate - (fps * multiple))
      if (multipleError < RATE_TOLERANCE * multiple) {
        return RefreshRateMatch(reason = "${multiple}x", priority = 1, error = multipleError, multiple = multiple)
      }
    }

    return null
  }

  /**
   * Ranks rate matches: an exact rate first, the nearer one when two are
   * within tolerance; among integer multiples the mode already active, then
   * the largest multiple, then the smaller multiplication error.
   *
   * Within the exact tier the current mode earns nothing: [RATE_TOLERANCE]
   * admits a neighbouring rate as "exact" (60.000004 for 59.94 content), and
   * keeping it because it is active trades a true match for a permanent
   * frame drop every ~17 s. The nearer rate wins; the active mode only
   * settles an equal error.
   *
   * A clean multiple the display is already in is never traded for another
   * one, whatever its error: the switch would renegotiate the panel for the
   * same cadence. Between multiples, higher is better. A 120 Hz panel drives
   * itself at 120; a 48 Hz mode on it is 2.5 panel refreshes per input frame,
   * a permanent 2:3 (#2255), where 120 Hz is a whole 5:5, and the fractional
   * drift's occasional repeated vsync costs 1/120 s instead of 1/48 s. Smaller
   * error only separates the same multiple, 119.88 from 120.
   *
   * Deliberately not SurfaceFlinger's tie-break: its layer-vote scoring
   * ranks 48 and 120 equal for 23.976 and settles on the lower rate unless a
   * layer voted Max.
   *
   * Half-rate content ranks by [halfRateRanking] instead.
   */
  private fun rateRanking(fps: Float, currentMode: ModeInfo): Comparator<Candidate> {
    if (fps >= HALF_RATE_MIN_FPS && fps <= HALF_RATE_MAX_FPS) return halfRateRanking(currentMode)
    return compareBy<Candidate> { it.match.priority }
      .thenBy { it.match.priority != 0 && it.mode.modeId != currentMode.modeId }
      .thenByDescending { it.match.multiple }
      .thenBy { it.match.error }
      .thenBy { it.mode.modeId != currentMode.modeId }
  }

  /**
   * Ranks rate matches for content between [HALF_RATE_MIN_FPS] and
   * [HALF_RATE_MAX_FPS]: a precise match first, then a multiple over the
   * content's own rate, then the mode already active, then the lowest
   * multiple, then the smaller error.
   *
   * Precision leads for the reason [rateRanking]'s exact tier ignores the
   * active mode: 60.000004 Hz is a 2x of 29.97 fps within tolerance but
   * repeats a frame every ~17 s, where 59.94 Hz (or 29.97 Hz itself, on a
   * panel without a 59.94 mode) presents it evenly. Among equally precise
   * modes the active one stays, so a display already at 120 Hz keeps 30 fps
   * at 4:4 instead of renegotiating down to 2:2 at 60. Otherwise the lowest
   * multiple wins: 2:2 at 50/60 Hz is already judder-free, and 100/120 Hz
   * only adds HDMI bandwidth for no cadence gain.
   */
  private fun halfRateRanking(currentMode: ModeInfo): Comparator<Candidate> = compareBy<Candidate> { it.match.error / it.match.multiple >= PRECISE_RATE_ERROR }
    .thenBy { it.match.multiple == 1 }
    .thenBy { it.mode.modeId != currentMode.modeId }
    .thenBy { it.match.multiple }
    .thenBy { it.match.error }

  /**
   * The cadence [fps] content presents with on a [refreshRate] display, or
   * null when nothing up to [MAX_CADENCE_PERIOD] frames repeats.
   *
   * Deliberately separate from [matchRefreshRate], which answers the stricter
   * "does this rate present the content cleanly" question that
   * FrameRateManager uses to recognise a landed switch. 60 Hz does not match
   * 23.976, but it presents it as the textbook 3:2 pulldown (period 2), where
   * 90 Hz needs the 4,4,4,3 pattern (period 4) and 50 Hz never repeats at
   * all. A pattern whose vsync count divides evenly across its frames is a
   * 1:1, not a pulldown: 23.976 Hz presents 23.8095 fps content one vsync per
   * frame, repeating a frame only once the 0.7% rate error has accumulated a
   * whole vsync (#2302).
   *
   * Only meaningful when the display refreshes at least as fast as the
   * content; below that, frames are dropped rather than repeated.
   */
  fun cadence(refreshRate: Float, fps: Float): Cadence? {
    if (refreshRate <= 0f || fps <= 0f) return null
    val ratio = refreshRate / fps
    if (ratio < 1f) return null
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
   * The mode among [modes] that presents [fps] best: shortest repeating
   * pattern, then the mode already active, then the slowest drift, then the
   * higher refresh rate.
   *
   * A pulldown's alternating hold times are permanent where drift only costs
   * an occasional repeated frame, so period leads; [currentMode] outranks
   * drift so a pattern of the same length never costs an HDMI renegotiation
   * for a marginal gain; at equal period and drift the finer vsync grid holds
   * each frame closer to its ideal moment.
   */
  private fun shortestCadence(fps: Float, currentMode: ModeInfo, modes: Sequence<ModeInfo>): CadenceCandidate? = modes
    .mapNotNull { mode -> cadence(mode.refreshRate, fps)?.let { CadenceCandidate(mode, it) } }
    .minWithOrNull(
      compareBy<CadenceCandidate> { it.cadence.period }
        .thenBy { it.mode.modeId != currentMode.modeId }
        .thenBy { it.cadence.drift }
        .thenByDescending { it.mode.refreshRate }
    )

  /**
   * Pick the display mode for the video, or null when no switch target exists.
   * The caller compares the result against the current mode to decide whether
   * an actual switch is needed.
   *
   * With [matchResolution] and known video dimensions, resolution wins over
   * cadence: the target is the smallest mode that still contains the video
   * (never downscaling it), rate-matched within that resolution when [fps] is
   * known. Otherwise the cadence-only policy applies and requires [fps] > 0.
   */
  fun findBestMode(
    fps: Float,
    currentMode: ModeInfo,
    supportedModes: List<ModeInfo>,
    videoWidth: Int,
    videoHeight: Int,
    matchResolution: Boolean
  ): Selection? {
    if (matchResolution && videoWidth > 0 && videoHeight > 0) {
      resolutionMatch(fps, currentMode, supportedModes, videoWidth, videoHeight)?.let { return it }
      // No mode can contain the video (source larger than the panel):
      // fall back to the cadence-only policy below.
    }
    return cadenceMatch(fps, currentMode, supportedModes, videoWidth, videoHeight)
  }

  private fun resolutionMatch(
    fps: Float,
    currentMode: ModeInfo,
    supportedModes: List<ModeInfo>,
    videoWidth: Int,
    videoHeight: Int
  ): Selection? {
    val candidates = supportedModes.filter { it.width >= videoWidth && it.height >= videoHeight }
    if (candidates.isEmpty()) return null

    // Native target: the smallest resolution that still contains the video,
    // so the display (not the device) performs the upscale.
    val targetArea = candidates.minOf { it.area }
    val bucket = candidates.filter { it.area == targetArea }

    // Rate-match within the target resolution when requested. Resolution
    // wins over cadence: a missing rate match here deliberately does not
    // widen back out to other resolutions.
    if (fps > 0f) {
      bucket
        .mapNotNull { mode -> matchRefreshRate(mode.refreshRate, fps)?.let { Candidate(mode, it) } }
        .minWithOrNull(rateRanking(fps, currentMode))
        ?.let { return Selection(it.mode, "resolution + ${it.match.reason} rate, error=${it.match.error}") }

      // No mode at this resolution divides the content rate: take the shortest
      // repeating pulldown before falling back to the nearest rate, so the
      // resolution path applies the same cadence policy as cadenceMatch.
      shortestCadence(fps, currentMode, bucket.asSequence())
        ?.let { return Selection(it.mode, "resolution + ${it.cadence.period}-frame cadence") }
    }

    // Resolution-only request, or no cadence match at the target resolution:
    // stay as close to the current refresh rate as possible so the switch
    // renegotiates only what it has to.
    val fallback = bucket.minWithOrNull(
      compareBy<ModeInfo> { abs(it.refreshRate - currentMode.refreshRate) }.thenByDescending { it.refreshRate }
    )
    return fallback?.let { Selection(it, "resolution only") }
  }

  private fun cadenceMatch(
    fps: Float,
    currentMode: ModeInfo,
    supportedModes: List<ModeInfo>,
    videoWidth: Int,
    videoHeight: Int
  ): Selection? {
    // Tier 1 — a matching-refresh mode at the CURRENT resolution: a refresh-only
    // switch, the least disruptive (no resolution/HDMI renegotiation).
    supportedModes.asSequence()
      .filter { it.width == currentMode.width && it.height == currentMode.height }
      .mapNotNull { mode -> matchRefreshRate(mode.refreshRate, fps)?.let { Candidate(mode, it) } }
      .minWithOrNull(rateRanking(fps, currentMode))
      ?.let { return Selection(it.mode, "${it.match.reason}, error=${it.match.error}") }

    // Tier 2 — no same-resolution match (e.g. a 4K panel with no 4K@24 mode, but a
    // 1080p@23.976 mode for 1080p content). Allow a resolution change, but never one
    // that downscales the video below its native size (trading detail for cadence).
    // Requires known video dimensions; without them keep Tier-1-only behaviour.
    if (videoWidth > 0 && videoHeight > 0) {
      supportedModes.asSequence()
        .filter { it.width >= videoWidth && it.height >= videoHeight }
        .mapNotNull { mode -> matchRefreshRate(mode.refreshRate, fps)?.let { Candidate(mode, it) } }
        .minWithOrNull(
          // Prefer the resolution closest to the panel's current one (least change,
          // keeps panel-native res when a high-res match exists), then the rate ranking.
          compareBy<Candidate> { abs(it.mode.area - currentMode.area) }.then(rateRanking(fps, currentMode))
        )
        ?.let { return Selection(it.mode, "${it.match.reason}, error=${it.match.error}") }
    }

    // Tier 3 — no rate divides the content rate at any usable resolution (a 60/90 Hz
    // phone panel with 23.976 fps content): settle for the shortest repeating
    // pulldown at the CURRENT resolution. A fractional cadence is never worth a
    // resolution change, and it only earns a switch when it beats the cadence we
    // already have — otherwise a TV would renegotiate HDMI for nothing.
    val sameResolution = supportedModes.asSequence()
      .filter { it.width == currentMode.width && it.height == currentMode.height }
    val currentPeriod = cadence(currentMode.refreshRate, fps)?.period ?: Int.MAX_VALUE
    return shortestCadence(fps, currentMode, sameResolution)
      ?.takeIf { it.cadence.period < currentPeriod }
      ?.let { Selection(it.mode, "${it.cadence.period}-frame cadence") }
  }
}
