package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class EndOfStreamPolicyTest {

  private fun isFinishedFile(
    hasPlaybackOutput: Boolean = true,
    hasVideoOutput: Boolean = true,
    isLive: Boolean = false,
    durationMs: Long = 60_000L,
    positionMs: Long = 60_000L,
    frameStallMs: Long = EndOfStreamPolicy.FRAME_STALL_MS
  ): Boolean = EndOfStreamPolicy.isFinishedFile(
    hasPlaybackOutput = hasPlaybackOutput,
    hasVideoOutput = hasVideoOutput,
    isLive = isLive,
    durationMs = durationMs,
    positionMs = positionMs,
    frameStallMs = frameStallMs
  )


  @Test
  fun stuckPastDurationWithNoPictureIsTheEndOfTheFile() {
    // The reported failure: the clock ran a minute past the last frame.
    assertTrue(isFinishedFile(positionMs = 119_816L, frameStallMs = 59_816L))
    // And the moment the overrun begins, once the picture is already gone.
    assertTrue(isFinishedFile(positionMs = 60_000L, frameStallMs = 5_000L))
  }

  @Test
  fun stillPaintingFramesMeansTheDurationIsUnderDeclaredNotFinished() {
    assertFalse(isFinishedFile(positionMs = 90_000L, frameStallMs = 4_999L))
    assertFalse(isFinishedFile(positionMs = 90_000L, frameStallMs = 0L))
  }

  @Test
  fun audioOnlyMediaHasNoFrameCounterAndRidesTheTimeoutAlone() {
    assertTrue(isFinishedFile(hasVideoOutput = false, frameStallMs = 0L))
  }

  @Test
  fun playbackShortOfTheDurationIsNeverFinished() {
    assertFalse(isFinishedFile(positionMs = 59_999L))
  }

  @Test
  fun unknownOrAbsentDurationIsNeverFinished() {
    assertFalse(isFinishedFile(durationMs = C.TIME_UNSET, positionMs = 120_000L))
    assertFalse(isFinishedFile(durationMs = 0L, positionMs = 120_000L))
    assertFalse(isFinishedFile(durationMs = -5L, positionMs = 120_000L))
  }

  @Test
  fun liveAndOutputlessSessionsKeepTheNormalRecovery() {
    // Live has no meaningful end; a session that never produced output is a
    // start-up failure, which the fallback ladder already owns.
    assertFalse(isFinishedFile(isLive = true))
    assertFalse(isFinishedFile(hasPlaybackOutput = false))
  }


  @Test
  fun fallbackResumesStrictlyInsideTheMedia() {
    // The observed hand-off asked MPV to start 59_816ms past the end.
    assertEquals(
      2_622_668L,
      EndOfStreamPolicy.fallbackStartPositionMs(positionMs = 2_683_484L, durationMs = 2_623_668L, isLive = false)
    )
    assertEquals(
      59_000L,
      EndOfStreamPolicy.fallbackStartPositionMs(positionMs = 60_000L, durationMs = 60_000L, isLive = false)
    )
  }

  @Test
  fun fallbackKeepsAMidFilePositionUntouched() {
    assertEquals(
      30_000L,
      EndOfStreamPolicy.fallbackStartPositionMs(positionMs = 30_000L, durationMs = 60_000L, isLive = false)
    )
  }

  @Test
  fun fallbackNeverGoesNegativeOnShortOrUnknownMedia() {
    assertEquals(
      0L,
      EndOfStreamPolicy.fallbackStartPositionMs(positionMs = 400L, durationMs = 500L, isLive = false)
    )
    assertEquals(
      0L,
      EndOfStreamPolicy.fallbackStartPositionMs(positionMs = -1L, durationMs = C.TIME_UNSET, isLive = false)
    )
  }

  @Test
  fun liveFallbackKeepsItsPositionBecauseTheEndKeepsMoving() {
    assertEquals(
      2_683_484L,
      EndOfStreamPolicy.fallbackStartPositionMs(positionMs = 2_683_484L, durationMs = 2_623_668L, isLive = true)
    )
  }
}
