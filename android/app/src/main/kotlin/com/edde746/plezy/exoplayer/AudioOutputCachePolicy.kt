package com.edde746.plezy.exoplayer

/**
 * Decides which audio outputs `RawPositionOutputProvider` may park in its reuse cache instead of
 * releasing on a sink flush.
 *
 * The cache exists so a seek does not tear down and rebuild the hardware audio pipeline, which
 * costs 7-10s of silence on Android TV boxes that reinitialize tunneled output slowly (Sony
 * Bravia class). That win is real for decoded PCM, but parking a *bitstream* output is a
 * different trade: a direct/passthrough `AudioTrack` occupies the platform's direct output for as
 * long as it is held, and several HDMI HALs expose only one. A parked AC3 track therefore blocks
 * the next AC3 track from being created at all, and the failure surfaces as
 * `UnsupportedOperationException: Cannot create AudioTrack` rather than as a slow seek (#1790).
 *
 * Parking also has to stay honest about media3's process-wide pending-release accounting: a
 * cached output is *not* releasing, so `RawPositionAudioOutput` signals `onReleased` immediately
 * for it. That is only true because nothing scarce is being held, which is exactly what this
 * policy guarantees.
 *
 * Offload outputs are excluded for the same reason plus their separate gapless/end-of-stream
 * state machine, which the cache does not model.
 */
internal object AudioOutputCachePolicy {

  /**
   * `AudioTrack.flush()` only reliably resets a stopped track from N MR1 onwards; below that the
   * cache would hand back a track carrying the previous playback's state.
   */
  const val MIN_SDK_INT = 25

  fun mayCache(encoding: Int, isOffload: Boolean, sdkInt: Int): Boolean {
    if (sdkInt < MIN_SDK_INT) return false
    if (isOffload) return false
    return isPcmEncoding(encoding)
  }
}
