package com.edde746.plezy.exoplayer

import androidx.media3.common.C

/**
 * Decision logic for the post-resume video stall watchdog (#1454).
 *
 * Some TV SoCs (the Amlogic Mi Box class) stall the MediaCodec output path after a
 * pause -> resume: the playback clock and audio keep advancing but no new video
 * frame reaches the screen until the codec is flushed by a seek. The watchdog
 * snapshots the rendered-frame counter when playback resumes and evaluates it one
 * check window later; a confirmed stall is recovered with a small backward seek
 * (ExoPlayer short-circuits a same-position seek without resetting renderers, so
 * the recovery must move by a nonzero delta to force the codec flush).
 */
internal object ResumeStallPolicy {
  /** Floor for the check window; frame-interval scaling only ever raises it. */
  const val DEFAULT_CHECK_WINDOW_MS = 1000L

  /** Frames that must have been due within the window before calling it a stall. */
  const val MIN_FRAME_INTERVALS = 4

  /** Assumed fps when neither the format nor timestamp detection knows it. */
  const val FALLBACK_FPS = 24f

  /** Recovery seek delta. Must stay under the 350ms watch-together drift deadband. */
  const val SEEK_BACK_MS = 250L

  /** Re-checks allowed while the clock itself is not advancing (generic stall, not this bug). */
  const val MAX_RECHECKS = 2

  /** Recovery cap per media session; a pathological stream stops arming after this. */
  const val MAX_RECOVERIES_PER_SESSION = 5

  enum class Verdict { HEALTHY, RECHECK, SKIP_NEAR_EOF, STALLED }

  /** Window sized so even low-fps or slowed-down content has had several frames due. */
  fun checkWindowMs(formatFps: Float?, detectedFps: Float?, speed: Float): Long {
    val fps = formatFps?.takeIf { it > 1f } ?: detectedFps?.takeIf { it > 1f } ?: FALLBACK_FPS
    val frameIntervalMs = (1000f / fps / speed.coerceAtLeast(0.25f)).toLong()
    return maxOf(DEFAULT_CHECK_WINDOW_MS, MIN_FRAME_INTERVALS * frameIntervalMs)
  }

  fun evaluate(
    baselineFrames: Int,
    currentFrames: Int,
    baselinePositionMs: Long,
    currentPositionMs: Long,
    durationMs: Long,
    windowMs: Long
  ): Verdict = when {
    // Any counter movement counts as healthy, including a renderer re-enable
    // resetting DecoderCounters below the baseline.
    currentFrames != baselineFrames -> Verdict.HEALTHY
    currentPositionMs - baselinePositionMs < windowMs / 2 -> Verdict.RECHECK
    durationMs != C.TIME_UNSET && durationMs - currentPositionMs < 2 * windowMs -> Verdict.SKIP_NEAR_EOF
    else -> Verdict.STALLED
  }
}
