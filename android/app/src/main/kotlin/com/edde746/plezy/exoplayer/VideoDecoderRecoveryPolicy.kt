package com.edde746.plezy.exoplayer

import androidx.media3.common.PlaybackException

/**
 * Keeps runtime decoder recovery separate from genuine format incompatibility.
 *
 * A video format that has already rendered a frame is known to be supported. A
 * later decoder failure can therefore be retried in ExoPlayer before the
 * session falls back to mpv. Cold-start failures still use the normal fallback,
 * while consecutive and per-media caps prevent reload loops.
 */
internal object VideoDecoderRecoveryPolicy {
  const val MAX_CONSECUTIVE_ATTEMPTS = 1
  const val MAX_ATTEMPTS_PER_MEDIA = 3
  const val HEALTHY_PLAYBACK_PROGRESS_MS = 3000L

  fun isTransientVideoDecoderError(errorCode: Int, isVideoRenderer: Boolean): Boolean = isVideoRenderer &&
    (
      errorCode == PlaybackException.ERROR_CODE_DECODER_INIT_FAILED ||
        errorCode == PlaybackException.ERROR_CODE_DECODING_FAILED
      )

  fun canRetryRuntimeFailure(
    hasRenderedVideoFrame: Boolean,
    consecutiveAttempts: Int,
    totalAttempts: Int
  ): Boolean = hasRenderedVideoFrame &&
    consecutiveAttempts < MAX_CONSECUTIVE_ATTEMPTS &&
    totalAttempts < MAX_ATTEMPTS_PER_MEDIA

  fun hasSustainedPlayback(
    hasRenderedFrame: Boolean,
    isPlaying: Boolean,
    recoveryPositionMs: Long,
    currentPositionMs: Long
  ): Boolean = hasRenderedFrame &&
    isPlaying &&
    currentPositionMs - recoveryPositionMs >= HEALTHY_PLAYBACK_PROGRESS_MS
}
