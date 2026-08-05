package com.edde746.plezy.exoplayer

import com.edde746.plezy.exoplayer.BufferingStallPolicy.Verdict
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BufferingStallPolicyTest {

  private val position = 85_206L

  private fun evaluate(
    elapsedMs: Long = BufferingStallPolicy.STALL_TIMEOUT_MS,
    baselinePositionMs: Long = position,
    currentPositionMs: Long = position,
    bufferedAheadMs: Long = 30_000L
  ) = BufferingStallPolicy.evaluate(
    elapsedMs = elapsedMs,
    baselinePositionMs = baselinePositionMs,
    currentPositionMs = currentPositionMs,
    bufferedPositionMs = currentPositionMs + bufferedAheadMs
  )

  // Progress

  @Test
  fun advancingPositionIsHealthy() {
    assertEquals(
      Verdict.HEALTHY,
      evaluate(currentPositionMs = position + BufferingStallPolicy.PROGRESS_EPSILON_MS)
    )
  }

  @Test
  fun advancingPositionOutranksAnExpiredTimeout() {
    assertEquals(
      Verdict.HEALTHY,
      evaluate(elapsedMs = 10 * BufferingStallPolicy.STALL_TIMEOUT_MS, currentPositionMs = position + 5_000)
    )
  }

  @Test
  fun clockJitterBelowTheEpsilonIsNotProgress() {
    assertEquals(
      Verdict.STALLED,
      evaluate(currentPositionMs = position + BufferingStallPolicy.PROGRESS_EPSILON_MS - 1)
    )
  }

  @Test
  fun positionMovingBackwardsIsNotProgress() {
    assertEquals(Verdict.STALLED, evaluate(currentPositionMs = position - 5_000))
  }

  // Timeout

  @Test
  fun frozenPositionWaitsOutTheTimeout() {
    assertEquals(Verdict.WAITING, evaluate(elapsedMs = BufferingStallPolicy.STALL_TIMEOUT_MS - 1))
  }

  /** The #1790 shape: data available, nothing playing, no error raised. */
  @Test
  fun bufferedButFrozenIsStalled() {
    assertEquals(Verdict.STALLED, evaluate())
  }

  // Starvation — the loader's problem, not the renderer's

  @Test
  fun emptyBufferIsStarved() {
    assertEquals(Verdict.STARVED, evaluate(bufferedAheadMs = 0))
  }

  @Test
  fun starvationOutranksAnExpiredTimeout() {
    assertEquals(
      Verdict.STARVED,
      evaluate(elapsedMs = 10 * BufferingStallPolicy.STALL_TIMEOUT_MS, bufferedAheadMs = 0)
    )
  }

  /**
   * `DefaultLoadControl` deliberately holds playback in `STATE_BUFFERING` until it has
   * [LoadControlPolicy.BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS] buffered. A watchdog that indicts
   * the player inside that window is indicting it for obeying its own load control.
   */
  @Test
  fun aBufferBelowTheLoadControlPlayStartThresholdIsStarved() {
    assertEquals(
      Verdict.STARVED,
      evaluate(
        elapsedMs = 10 * BufferingStallPolicy.STALL_TIMEOUT_MS,
        bufferedAheadMs = LoadControlPolicy.BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS.toLong()
      )
    )
  }

  @Test
  fun theStallThresholdClearsTheLoadControlPlayStartThreshold() {
    assertTrue(
      "MIN_BUFFER_AHEAD_MS (${BufferingStallPolicy.MIN_BUFFER_AHEAD_MS}) must exceed the load " +
        "control's post-rebuffer play-start threshold " +
        "(${LoadControlPolicy.BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS})",
      BufferingStallPolicy.MIN_BUFFER_AHEAD_MS > LoadControlPolicy.BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS
    )
  }

  @Test
  fun starvedIsStickyWhileTheBufferStaysThin() {
    assertEquals(
      Verdict.STARVED,
      evaluate(
        elapsedMs = 10 * BufferingStallPolicy.STALL_TIMEOUT_MS,
        bufferedAheadMs = BufferingStallPolicy.MIN_BUFFER_AHEAD_MS - 1
      )
    )
  }

  // Stall clock ownership

  @Test
  fun starvationAndProgressBothRestartTheStallClock() {
    assertTrue(BufferingStallPolicy.resetsStallClock(Verdict.STARVED))
    assertTrue(BufferingStallPolicy.resetsStallClock(Verdict.HEALTHY))
  }

  @Test
  fun waitingKeepsTheStallClockRunning() {
    assertFalse(BufferingStallPolicy.resetsStallClock(Verdict.WAITING))
  }

  /**
   * Regression: a long network stall used to accrue the whole timeout while starved, so the very
   * first poll after the buffer refilled reported a stall that never happened and force-reloaded
   * a perfectly healthy rebuffer. Starvation restarts the clock, so the refilled buffer gets the
   * full timeout to start playing.
   */
  @Test
  fun aRecoveringBufferIsNotStalledByTimeSpentStarved() {
    val starvedFor = 60_000L
    val starved = evaluate(elapsedMs = starvedFor, bufferedAheadMs = 0)
    assertEquals(Verdict.STARVED, starved)
    assertTrue(BufferingStallPolicy.resetsStallClock(starved))

    // The watchdog re-baselines on that verdict, so the next poll starts from zero elapsed.
    assertEquals(
      Verdict.WAITING,
      evaluate(
        elapsedMs = BufferingStallPolicy.CHECK_INTERVAL_MS,
        bufferedAheadMs = BufferingStallPolicy.MIN_BUFFER_AHEAD_MS + 1
      )
    )
  }
}
