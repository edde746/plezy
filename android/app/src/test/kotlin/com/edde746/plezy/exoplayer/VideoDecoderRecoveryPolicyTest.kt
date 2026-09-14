package com.edde746.plezy.exoplayer

import androidx.media3.common.PlaybackException
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VideoDecoderRecoveryPolicyTest {

  @Test
  fun runtimeVideoDecoderFailuresAreRecoverable() {
    assertTrue(
      VideoDecoderRecoveryPolicy.isTransientVideoDecoderError(
        PlaybackException.ERROR_CODE_DECODER_INIT_FAILED,
        isVideoRenderer = true
      )
    )
    assertTrue(
      VideoDecoderRecoveryPolicy.isTransientVideoDecoderError(
        PlaybackException.ERROR_CODE_DECODING_FAILED,
        isVideoRenderer = true
      )
    )
  }

  @Test
  fun formatAndNonVideoErrorsAreNotRecoverable() {
    assertFalse(
      VideoDecoderRecoveryPolicy.isTransientVideoDecoderError(
        PlaybackException.ERROR_CODE_DECODING_FORMAT_UNSUPPORTED,
        isVideoRenderer = true
      )
    )
    assertFalse(
      VideoDecoderRecoveryPolicy.isTransientVideoDecoderError(
        PlaybackException.ERROR_CODE_DECODING_FAILED,
        isVideoRenderer = false
      )
    )
  }

  @Test
  fun runtimeFailureRequiresAWarmDecoderAndAvailableBudgets() {
    assertFalse(
      VideoDecoderRecoveryPolicy.canRetryRuntimeFailure(
        hasRenderedVideoFrame = false,
        consecutiveAttempts = 0,
        totalAttempts = 0
      )
    )
    assertTrue(
      VideoDecoderRecoveryPolicy.canRetryRuntimeFailure(
        hasRenderedVideoFrame = true,
        consecutiveAttempts = 0,
        totalAttempts = 0
      )
    )
    assertFalse(
      VideoDecoderRecoveryPolicy.canRetryRuntimeFailure(
        hasRenderedVideoFrame = true,
        consecutiveAttempts = 1,
        totalAttempts = 1
      )
    )
    assertFalse(
      VideoDecoderRecoveryPolicy.canRetryRuntimeFailure(
        hasRenderedVideoFrame = true,
        consecutiveAttempts = 0,
        totalAttempts = VideoDecoderRecoveryPolicy.MAX_ATTEMPTS_PER_MEDIA
      )
    )
  }

  @Test
  fun sustainedPlaybackRequiresAFrameAndForwardProgress() {
    assertFalse(
      VideoDecoderRecoveryPolicy.hasSustainedPlayback(
        hasRenderedFrame = false,
        isPlaying = true,
        recoveryPositionMs = 10_000,
        currentPositionMs = 13_000
      )
    )
    assertFalse(
      VideoDecoderRecoveryPolicy.hasSustainedPlayback(
        hasRenderedFrame = true,
        isPlaying = false,
        recoveryPositionMs = 10_000,
        currentPositionMs = 13_000
      )
    )
    assertFalse(
      VideoDecoderRecoveryPolicy.hasSustainedPlayback(
        hasRenderedFrame = true,
        isPlaying = true,
        recoveryPositionMs = 10_000,
        currentPositionMs = 12_999
      )
    )
    assertTrue(
      VideoDecoderRecoveryPolicy.hasSustainedPlayback(
        hasRenderedFrame = true,
        isPlaying = true,
        recoveryPositionMs = 10_000,
        currentPositionMs = 13_000
      )
    )
  }
}
