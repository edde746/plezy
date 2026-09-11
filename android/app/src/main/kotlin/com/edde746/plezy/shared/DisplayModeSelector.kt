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
   * Longest repeating pulldown [cadencePeriod] will accept, in video frames.
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

  /** JVM-testable mirror of android.view.Display.Mode. */
  data class ModeInfo(val modeId: Int, val width: Int, val height: Int, val refreshRate: Float) {
    val area: Long get() = width.toLong() * height
  }

  data class RefreshRateMatch(val reason: String, val priority: Int, val error: Float)

  data class Selection(val mode: ModeInfo, val reason: String)

  private data class Candidate(val mode: ModeInfo, val match: RefreshRateMatch)

  private data class CadenceCandidate(val mode: ModeInfo, val period: Int)

  /** How well [refreshRate] presents [fps] content: exact, an integer multiple, or not at all. */
  fun matchRefreshRate(refreshRate: Float, fps: Float): RefreshRateMatch? {
    if (refreshRate <= 0f || fps <= 0f) return null

    val exactError = abs(refreshRate - fps)
    if (exactError < RATE_TOLERANCE) {
      return RefreshRateMatch(reason = "exact", priority = 0, error = exactError)
    }

    // The error is measured after multiplication, so the tolerance has to
    // scale with the multiple. A flat 0.1 Hz rejects |120 - 5 * 23.976| =
    // 0.12, which would make every 120 Hz panel fail to rate-match
    // NTSC-fractional content — exactly where 120/24p is the ideal 5:5.
    val multiple = (refreshRate / fps).roundToInt()
    if (multiple > 1) {
      val multipleError = abs(refreshRate - (fps * multiple))
      if (multipleError < RATE_TOLERANCE * multiple) {
        return RefreshRateMatch(reason = "${multiple}x", priority = 1, error = multipleError)
      }
    }

    return null
  }

  /**
   * Length, in video frames, of the shortest vsync pattern that repeats when
   * [fps] content is presented on a [refreshRate] display, or null when
   * nothing up to [MAX_CADENCE_PERIOD] frames repeats.
   *
   * Deliberately separate from [matchRefreshRate], which answers the stricter
   * "does this rate present the content cleanly" question that
   * FrameRateManager uses to recognise a landed switch. 60 Hz does not match
   * 23.976, but it presents it as the textbook 3:2 pulldown (period 2), where
   * 90 Hz needs the 4,4,4,3 pattern (period 4) and 50 Hz never repeats at
   * all. Shorter is better: the irregularity returns sooner, so no single
   * frame is held far from its share of the cadence.
   *
   * Only meaningful when the display refreshes at least as fast as the
   * content; below that, frames are dropped rather than repeated.
   */
  fun cadencePeriod(refreshRate: Float, fps: Float): Int? {
    if (refreshRate <= 0f || fps <= 0f) return null
    val ratio = refreshRate / fps
    if (ratio < 1f) return null
    for (period in 2..MAX_CADENCE_PERIOD) {
      val vsyncs = ratio * period
      if (abs(vsyncs - vsyncs.roundToInt()) < CADENCE_TOLERANCE) return period
    }
    return null
  }

  /**
   * The mode among [modes] that presents [fps] with the shortest repeating
   * cadence. Ties go to the higher refresh rate: at equal pattern length,
   * finer vsync quantisation keeps each frame closer to its ideal moment.
   */
  private fun shortestCadence(fps: Float, modes: Sequence<ModeInfo>): CadenceCandidate? = modes
    .mapNotNull { mode -> cadencePeriod(mode.refreshRate, fps)?.let { CadenceCandidate(mode, it) } }
    .minWithOrNull(compareBy<CadenceCandidate> { it.period }.thenByDescending { it.mode.refreshRate })

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
        .minWithOrNull(
          compareBy<Candidate> { it.match.priority }
            .thenBy { it.match.error }
            .thenBy { abs(it.mode.refreshRate - currentMode.refreshRate) }
        )
        ?.let { return Selection(it.mode, "resolution + ${it.match.reason} rate, error=${it.match.error}") }

      // No mode at this resolution divides the content rate: take the shortest
      // repeating pulldown before falling back to the nearest rate, so the
      // resolution path applies the same cadence policy as cadenceMatch.
      shortestCadence(fps, bucket.asSequence())
        ?.let { return Selection(it.mode, "resolution + ${it.period}-frame cadence") }
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
      .minWithOrNull(
        compareBy<Candidate> { it.match.priority }
          .thenBy { it.match.error }
          .thenBy { abs(it.mode.refreshRate - currentMode.refreshRate) }
      )
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
          // keeps panel-native res when a high-res match exists), then refresh match.
          compareBy<Candidate> { abs(it.mode.area - currentMode.area) }
            .thenBy { it.match.priority }
            .thenBy { it.match.error }
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
    val currentPeriod = cadencePeriod(currentMode.refreshRate, fps) ?: Int.MAX_VALUE
    return shortestCadence(fps, sameResolution)
      ?.takeIf { it.period < currentPeriod }
      ?.let { Selection(it.mode, "${it.period}-frame cadence") }
  }
}
