package com.edde746.plezy.exoplayer

import androidx.media3.common.C

/**
 * Decision logic for media the player refuses to end (#1673).
 *
 * media3 reports `StuckPlayerException.STUCK_PLAYING_NOT_ENDING` when the player
 * sits in STATE_READY past the declared duration while no renderer ever reports
 * itself ended. Observed on a tunneled MTK decoder (Fire TV 4K Max): the clock
 * ran a full minute past the last frame behind a black screen, so nothing ever
 * completed the item — no Play Next, no auto-play, and a "playing" timeline the
 * server kept extrapolating past the item duration. The leading hypothesis is
 * that the tunneled end-of-stream buffer never arrives; what the evidence
 * establishes is only that the renderers never end.
 *
 * The stuck report alone cannot mean "finished": the same condition holds for a
 * container that under-declares its duration and is legitimately still playing.
 * The rendered-frame counter separates the two — a finished file has stopped
 * painting, an under-declared one has not.
 *
 * Inputs are deliberately the core's own bookkeeping rather than live player
 * state: media3 has already stopped the player by the time the report arrives,
 * so its timeline and track selection may be gone.
 */
internal object EndOfStreamPolicy {
  /**
   * Window media3 waits before reporting a player that is past its duration and
   * still not ending. media3's own not-ending default is a full minute; this
   * matches its stuck-*playing* default instead, which [isFinishedFile] can
   * afford because it also requires the picture to be gone.
   */
  const val STALL_TIMEOUT_MS = 10_000

  /**
   * How long the rendered-frame counter must sit still before a player stuck
   * past its duration counts as a finished file rather than a long tail.
   */
  const val FRAME_STALL_MS = 5_000L

  /**
   * Distance from the end a fallback backend may resume at. MPV opened at or
   * past the last frame seeks straight into EOF and parks there without ever
   * reporting it, which is how a failed hand-off turned into a second stall.
   */
  const val FALLBACK_END_GUARD_MS = 1_000L

  /**
   * Whether a player stuck past its duration has actually reached the end of the
   * file.
   *
   * [hasPlaybackOutput] keeps start-up failures — which the fallback ladder owns
   * — out of this path. [hasVideoOutput] says whether the rendered-frame counter
   * means anything for this media: audio-only playback never moves it, so there
   * the stuck timeout stands alone. [frameStallMs] is the age of the last
   * counter change.
   */
  fun isFinishedFile(
    hasPlaybackOutput: Boolean,
    hasVideoOutput: Boolean,
    isLive: Boolean,
    durationMs: Long,
    positionMs: Long,
    frameStallMs: Long
  ): Boolean = hasPlaybackOutput &&
    !isLive &&
    durationMs != C.TIME_UNSET &&
    durationMs > 0L &&
    positionMs >= durationMs &&
    (!hasVideoOutput || frameStallMs >= FRAME_STALL_MS)

  /** Keep a backend hand-off strictly inside the media, mirroring the seek clamp. */
  fun fallbackStartPositionMs(positionMs: Long, durationMs: Long, isLive: Boolean): Long {
    if (isLive || durationMs == C.TIME_UNSET || durationMs <= 0L) return positionMs.coerceAtLeast(0L)
    return positionMs.coerceIn(0L, (durationMs - FALLBACK_END_GUARD_MS).coerceAtLeast(0L))
  }
}
