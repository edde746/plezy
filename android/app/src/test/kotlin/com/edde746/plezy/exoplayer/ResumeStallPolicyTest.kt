package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import com.edde746.plezy.exoplayer.ResumeStallPolicy.Verdict
import org.junit.Assert.assertEquals
import org.junit.Test

class ResumeStallPolicyTest {

  // checkWindowMs

  @Test
  fun windowFloorsAtDefaultForNormalFrameRates() {
    // 24fps → 4 × 42ms = 168ms, floored to 1000ms
    assertEquals(1000L, ResumeStallPolicy.checkWindowMs(formatFps = 24f, detectedFps = -1f, speed = 1f))
    assertEquals(1000L, ResumeStallPolicy.checkWindowMs(formatFps = 60f, detectedFps = -1f, speed = 1f))
  }

  @Test
  fun windowScalesUpForLowFrameRates() {
    // 2fps → 4 × 500ms = 2000ms
    assertEquals(2000L, ResumeStallPolicy.checkWindowMs(formatFps = 2f, detectedFps = -1f, speed = 1f))
  }

  @Test
  fun windowScalesUpForSlowedPlayback() {
    // 8fps at 0.25× speed → effective 2fps → 2000ms
    assertEquals(2000L, ResumeStallPolicy.checkWindowMs(formatFps = 8f, detectedFps = -1f, speed = 0.25f))
    // fast playback shrinks the interval; still floored
    assertEquals(1000L, ResumeStallPolicy.checkWindowMs(formatFps = 24f, detectedFps = -1f, speed = 2f))
  }

  @Test
  fun windowFallsBackThroughDetectedFpsToDefault() {
    // Format fps unknown (NO_VALUE = -1) → detected fps wins
    assertEquals(2000L, ResumeStallPolicy.checkWindowMs(formatFps = -1f, detectedFps = 2f, speed = 1f))
    // Neither known → 24fps assumption → floor
    assertEquals(1000L, ResumeStallPolicy.checkWindowMs(formatFps = -1f, detectedFps = -1f, speed = 1f))
    assertEquals(1000L, ResumeStallPolicy.checkWindowMs(formatFps = null, detectedFps = null, speed = 1f))
  }

  // evaluate

  @Test
  fun advancingFramesAreHealthy() {
    assertEquals(
      Verdict.HEALTHY,
      ResumeStallPolicy.evaluate(
        baselineFrames = 100,
        currentFrames = 124,
        baselinePositionMs = 60_000,
        currentPositionMs = 61_000,
        durationMs = 3_600_000,
        windowMs = 1000
      )
    )
  }

  @Test
  fun counterResetCountsAsHealthy() {
    // Renderer re-enable resets DecoderCounters below the baseline — not a stall.
    assertEquals(
      Verdict.HEALTHY,
      ResumeStallPolicy.evaluate(
        baselineFrames = 100,
        currentFrames = 3,
        baselinePositionMs = 60_000,
        currentPositionMs = 61_000,
        durationMs = 3_600_000,
        windowMs = 1000
      )
    )
  }

  @Test
  fun stalledClockRequestsRecheck() {
    // Frames frozen but the position isn't advancing either: generic buffering
    // stall, not the decoder freeze this watchdog targets.
    assertEquals(
      Verdict.RECHECK,
      ResumeStallPolicy.evaluate(
        baselineFrames = 100,
        currentFrames = 100,
        baselinePositionMs = 60_000,
        currentPositionMs = 60_200,
        durationMs = 3_600_000,
        windowMs = 1000
      )
    )
  }

  @Test
  fun nearEndOfStreamIsSkipped() {
    // Video track ending before audio is legitimate near EOF.
    assertEquals(
      Verdict.SKIP_NEAR_EOF,
      ResumeStallPolicy.evaluate(
        baselineFrames = 100,
        currentFrames = 100,
        baselinePositionMs = 3_598_000,
        currentPositionMs = 3_599_000,
        durationMs = 3_600_000,
        windowMs = 1000
      )
    )
  }

  @Test
  fun frozenFramesWithAdvancingClockMidFileIsStalled() {
    assertEquals(
      Verdict.STALLED,
      ResumeStallPolicy.evaluate(
        baselineFrames = 100,
        currentFrames = 100,
        baselinePositionMs = 60_000,
        currentPositionMs = 61_000,
        durationMs = 3_600_000,
        windowMs = 1000
      )
    )
  }

  @Test
  fun unknownDurationSkipsEofGuardAndStalls() {
    // Live/unknown duration (C.TIME_UNSET) must not suppress detection.
    assertEquals(
      Verdict.STALLED,
      ResumeStallPolicy.evaluate(
        baselineFrames = 100,
        currentFrames = 100,
        baselinePositionMs = 60_000,
        currentPositionMs = 61_000,
        durationMs = C.TIME_UNSET,
        windowMs = 1000
      )
    )
  }
}
