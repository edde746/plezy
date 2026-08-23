package com.edde746.plezy.shared

import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Pure display-mode selection policy for content-adaptive display switching.
 * Extracted from [FrameRateManager] so the policy is unit-testable on the
 * JVM, where android.view.Display.Mode cannot be instantiated.
 */
object DisplayModeSelector {
  const val RATE_TOLERANCE = 0.1f

  /** JVM-testable mirror of android.view.Display.Mode. */
  data class ModeInfo(val modeId: Int, val width: Int, val height: Int, val refreshRate: Float) {
    val area: Long get() = width.toLong() * height
  }

  data class RefreshRateMatch(val reason: String, val priority: Int, val error: Float)

  data class Selection(val mode: ModeInfo, val reason: String)

  private data class Candidate(val mode: ModeInfo, val match: RefreshRateMatch)

  /** How well [refreshRate] presents [fps] content: exact, an integer multiple, or not at all. */
  fun matchRefreshRate(refreshRate: Float, fps: Float): RefreshRateMatch? {
    if (refreshRate <= 0f || fps <= 0f) return null

    val exactError = abs(refreshRate - fps)
    if (exactError < RATE_TOLERANCE) {
      return RefreshRateMatch(reason = "exact", priority = 0, error = exactError)
    }

    val multiple = (refreshRate / fps).roundToInt()
    if (multiple > 1) {
      val multipleError = abs(refreshRate - (fps * multiple))
      if (multipleError < RATE_TOLERANCE) {
        return RefreshRateMatch(reason = "${multiple}x", priority = 1, error = multipleError)
      }
    }

    return null
  }

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
    if (videoWidth <= 0 || videoHeight <= 0) return null
    return supportedModes.asSequence()
      .filter { it.width >= videoWidth && it.height >= videoHeight }
      .mapNotNull { mode -> matchRefreshRate(mode.refreshRate, fps)?.let { Candidate(mode, it) } }
      .minWithOrNull(
        // Prefer the resolution closest to the panel's current one (least change,
        // keeps panel-native res when a high-res match exists), then refresh match.
        compareBy<Candidate> { abs(it.mode.area - currentMode.area) }
          .thenBy { it.match.priority }
          .thenBy { it.match.error }
      )
      ?.let { Selection(it.mode, "${it.match.reason}, error=${it.match.error}") }
  }
}
