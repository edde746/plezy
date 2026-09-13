package com.edde746.plezy.mpv

/**
 * Whether mpv presents one frame per field for interlaced content, so the
 * presented rate is twice `container-fps` (#2322). Two things do that: mpv's
 * own deinterlacer (`deinterlace-active` — every backend `deinterlace=auto`
 * picks emits fields), and a decoder that deinterlaces by itself (MediaCodec
 * on Tegra and Amlogic), which no mpv filter reports and only the measured
 * cadence reveals. Mirrors the Dart `PlayerOutputFormat.presentsFields`.
 */
internal object PresentedFrameRate {
  /**
   * [estimatedFps] is mpv's `estimated-vf-fps`: the frame duration it derives
   * from consecutive output timestamps, one sample already at the first shown
   * frame since it decodes two frames before showing one. The band absorbs
   * Matroska's millisecond timestamp rounding (a 16.68 ms field reads as 16
   * or 17 ms) while rejecting duplicate, dropped, or telecined cadences.
   */
  fun presentsFields(containerFps: Double, estimatedFps: Double?, deinterlaceActive: Boolean): Boolean {
    if (deinterlaceActive) return true
    if (containerFps <= 0.0 || estimatedFps == null || estimatedFps <= 0.0) return false
    val ratio = estimatedFps / containerFps
    return ratio > 1.8 && ratio < 2.2
  }
}
