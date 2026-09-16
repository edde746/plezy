package com.edde746.plezy.mpv

import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * The frame rate a MediaCodec decoder is told to be ready for (MediaFormat
 * `operating-rate`, mpv `--hwdec-mediacodec-operating-rate`).
 *
 * Vendors pick the codec's clock from this number, not from the stream: on
 * Tensor the AV1 block sizes its DVFS point from `width x height x rate`, and
 * with nothing declared it ran a 30 Mbps 1080p24 grain section at 40 ms a
 * frame — 21 fps — while the same frames took 18 ms once 60 was declared
 * (#2361). The content rate alone (24) changed nothing: the vendor's model
 * provisions for a typical bitrate at that rate, and a heavy one needs
 * headroom over it. Only some stacks read the number at all (Tensor,
 * Qualcomm); on the rest it is inert, never harmful within the codec's own
 * advertised range.
 *
 * One instance per session, mutated under the session's write queue: the
 * file's inputs arrive from the preloaded hook, the speed from mpv's `speed`,
 * and a user config line pins the rate for the rest of the session.
 */
internal class DecoderOperatingRate {
  private var containerFps = 0.0
  private var codecMaxFps: Int? = null
  private var playbackSpeed = 1.0
  private var pinned = false

  /** A `hwdec-mediacodec-operating-rate` line in the user's config: the rate is theirs from here on. */
  fun pin() {
    pinned = true
  }

  /** A new file's rate and its decoder's advertised maximum; the rate to declare before the decoder is created. */
  fun onFile(containerFps: Double, codecMaxFps: Int?): Int? {
    this.containerFps = containerFps
    this.codecMaxFps = codecMaxFps
    return current()
  }

  /** mpv's `speed`; the rate to re-declare when the speed actually changed. */
  fun onSpeed(speed: Double): Int? {
    if (!speed.isFinite() || speed <= 0.0 || speed == playbackSpeed) return null
    playbackSpeed = speed
    return current()
  }

  private fun current(): Int? = if (pinned) null else rate(containerFps, playbackSpeed, codecMaxFps)

  companion object {
    /** The least any file is declared at: 24 alone changed nothing on Tensor, 60 did. */
    const val FLOOR_FPS = 60.0

    /** Headroom over the content rate for bitrate the vendor's model does not see. */
    const val HEADROOM = 2.0

    /** A saturating rate buys nothing (the clock tables top out) and is the one class with documented breakage. */
    const val CEILING_FPS = 240

    /**
     * The content rate with headroom, floored, scaled by speed and capped by
     * the codec's advertised maximum and the ceiling. An unknown content rate
     * declares the floor; a codec with no advertised maximum gets the ceiling.
     */
    fun rate(containerFps: Double, playbackSpeed: Double, codecMaxFps: Int?): Int {
      val fps = if (containerFps > 0.0) containerFps else 0.0
      val upper = min(codecMaxFps?.takeIf { it > 0 } ?: CEILING_FPS, CEILING_FPS)
      return min(ceil(max(HEADROOM * fps, FLOOR_FPS) * playbackSpeed).toInt(), upper)
    }
  }
}
