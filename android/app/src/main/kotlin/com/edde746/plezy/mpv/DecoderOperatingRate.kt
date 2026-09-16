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
 * frame — 21 fps — while the same frames took 18 ms once 60 was declared and
 * 7 ms at 120 (#2361). The content rate alone (24) changed nothing: the
 * vendor's model provisions for a typical bitrate at that rate, and a
 * heavy one needs headroom over it.
 *
 * The declared rate is therefore the content rate with headroom, floored at
 * a 60 Hz cadence, scaled by playback speed and clamped to what the codec
 * advertises. A session that still measures a deficit at that rate raises
 * once to twice it ([boosted]) and returns to the declared rate after a calm
 * spell ([DecoderDeficitMonitor]). Only some stacks read the number at all
 * (Tensor, Qualcomm); on the rest it is inert, never harmful within the
 * codec's own advertised range.
 */
internal object DecoderOperatingRate {
  /** Decode has to feed the display, not only the content. */
  const val FLOOR_FPS = 60.0

  /** Headroom over the content rate for bitrate the vendor's model does not see. */
  const val HEADROOM = 2.0

  /** A saturating rate buys nothing (the clock tables top out) and is the one class with documented breakage. */
  const val CEILING_FPS = 240

  /** The rate a file is declared with when its decoder is created, and re-declared on a speed change. */
  fun declared(containerFps: Double, playbackSpeed: Double, codecMaxFps: Int?): Int =
    rate(1.0, containerFps, playbackSpeed, codecMaxFps)

  /** The single raise for a decoder measured behind at the declared rate. */
  fun boosted(containerFps: Double, playbackSpeed: Double, codecMaxFps: Int?): Int =
    rate(2.0, containerFps, playbackSpeed, codecMaxFps)

  /**
   * [multiple] times the content rate with headroom, floored at the display
   * cadence and scaled by speed; never below the content rate at that speed
   * (the decoder must at least keep up), never above the codec's advertised
   * maximum or the ceiling. An unknown content rate declares the floor; an
   * unusable speed reads as 1x; a codec with no advertised maximum gets the
   * ceiling.
   */
  internal fun rate(multiple: Double, containerFps: Double, playbackSpeed: Double, codecMaxFps: Int?): Int {
    val fps = if (containerFps.isFinite() && containerFps > 0.0) containerFps else 0.0
    val speed = if (playbackSpeed.isFinite() && playbackSpeed > 0.0) playbackSpeed else 1.0
    val upper = min(codecMaxFps?.takeIf { it > 0 } ?: CEILING_FPS, CEILING_FPS)
    val wanted = max(multiple * max(HEADROOM * fps, FLOOR_FPS) * speed, fps * speed)
    return min(ceil(wanted).toInt(), upper).coerceAtLeast(1)
  }
}

/**
 * Turns the video plane's late-frame count into the one raise and the one
 * restore of [DecoderOperatingRate].
 *
 * The signal is mpv's `frame-drop-count`, which on the plane is the fork
 * VO's own accounting: frames that reached the codec after their time plus
 * frames the display held off cadence. It is cumulative and resets on a
 * seek. Frames go late for reasons other than a slow decoder right after a
 * start, seek or unpause (the pipeline is refilling), so those are ignored
 * for [settleMs]. Sustained lateness — [lateFramesToRaise] frames within
 * [windowMs] — raises once; [calmMs] without a late frame restores. The
 * decoder's effect on the raise is only ever confirmed by the count going
 * quiet, never by a return code, because a component may ignore the
 * parameter without saying so.
 */
internal class DecoderDeficitMonitor(
  private val lateFramesToRaise: Int = 6,
  private val windowMs: Long = 3_000,
  private val settleMs: Long = 2_000,
  private val calmMs: Long = 30_000
) {
  enum class Decision { RAISE, RESTORE }

  var boosted: Boolean = false
    private set

  private var baseline: Long = -1
  private var settledAtMs: Long = 0
  private var windowStartMs: Long = 0
  private var lateInWindow: Int = 0
  private var lastLateAtMs: Long = 0

  /** Playback (re)started at [nowMs]: a start, seek or unpause. Late frames until it settles are not a deficit. */
  fun onPlaybackStarted(nowMs: Long) {
    settledAtMs = nowMs + settleMs
    baseline = -1
    windowStartMs = nowMs
    lateInWindow = 0
  }

  /** A new file: everything measured so far belonged to the previous decoder. */
  fun reset() {
    boosted = false
    baseline = -1
    settledAtMs = 0
    windowStartMs = 0
    lateInWindow = 0
    lastLateAtMs = 0
  }

  /** The current cumulative count at [nowMs]; the decision the session should act on, if any. */
  fun onDropCount(count: Long, nowMs: Long): Decision? {
    val delta = if (baseline < 0 || count < baseline) 0L else count - baseline
    baseline = count
    if (nowMs < settledAtMs) return null

    if (nowMs - windowStartMs > windowMs) {
      windowStartMs = nowMs
      lateInWindow = 0
    }
    if (delta > 0) {
      lateInWindow += delta.coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
      lastLateAtMs = nowMs
    }

    if (!boosted && lateInWindow >= lateFramesToRaise) {
      boosted = true
      lateInWindow = 0
      return Decision.RAISE
    }
    if (boosted && delta == 0L && nowMs - lastLateAtMs >= calmMs) {
      boosted = false
      return Decision.RESTORE
    }
    return null
  }
}
