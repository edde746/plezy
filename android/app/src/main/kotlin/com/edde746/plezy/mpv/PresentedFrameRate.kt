package com.edde746.plezy.mpv

/**
 * What mpv presents for interlaced content, as a multiple of `container-fps`.
 * One frame per field doubles it (#2322). Two things do that: mpv's own
 * deinterlacer (`deinterlace-active` — every backend `deinterlace=auto`
 * picks emits fields), and a decoder that deinterlaces by itself (MediaCodec
 * on Tegra and Amlogic), which no mpv filter reports and only the measured
 * cadence reveals. Inverse telecine (`ivtc-active`, the fork's
 * `deinterlace=ivtc`) rebuilds the film frames and drops one in five, so
 * 29.97i is presented at 23.976 (#2710). Mirrors the Dart
 * `PlayerOutputFormat.read`.
 */
internal object PresentedFrameRate {
  /**
   * [estimatedFps] is mpv's `estimated-vf-fps`: the frame duration it derives
   * from consecutive output timestamps, one sample already at the first shown
   * frame since it decodes two frames before showing one. The band absorbs
   * Matroska's millisecond timestamp rounding (a 16.68 ms field reads as 16
   * or 17 ms) and one duplicated timestamp in a ten-frame window (10/9 × 2 =
   * 2.22) while rejecting duplicate-every-frame, dropped, or telecined
   * cadences (3.0, 0.5, 1.25). Same band as Dart's `presentsFields`.
   */
  fun presentsFields(containerFps: Double, estimatedFps: Double?, deinterlaceActive: Boolean): Boolean {
    if (deinterlaceActive) return true
    if (containerFps <= 0.0 || estimatedFps == null || estimatedFps <= 0.0) return false
    val ratio = estimatedFps / containerFps
    return ratio > 1.7 && ratio < 2.3
  }

  /** The presented rate over `container-fps`: inverse telecine wins over field output. */
  fun rateFactor(containerFps: Double, estimatedFps: Double?, deinterlaceActive: Boolean, ivtcActive: Boolean): Float = when {
    ivtcActive -> IVTC_RATE_FACTOR
    presentsFields(containerFps, estimatedFps, deinterlaceActive) -> 2f
    else -> 1f
  }

  /** 3:2 pulldown carries four film frames in five video frames. */
  const val IVTC_RATE_FACTOR = 0.8f
}
