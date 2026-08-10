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
    bufferedAheadMs: Long = 30_000L,
    playbackSpeed: Float = 1f,
    loadControlReady: Boolean? = null,
    loading: Boolean = true
  ) = BufferingStallPolicy.evaluate(
    elapsedMs = elapsedMs,
    baselinePositionMs = baselinePositionMs,
    currentPositionMs = currentPositionMs,
    bufferedPositionMs = currentPositionMs + bufferedAheadMs,
    playbackSpeed = playbackSpeed,
    loadControlReady = loadControlReady,
    loading = loading
  )


  @Test
  fun aLoaderThatStoppedAskingForDataCountsAsEnoughBuffer() {
    // The #1790 shape on a high bitrate stream: the byte cap is full at a couple of seconds, the
    // renderers never become ready so media3 never asks its load control, and nothing moves.
    val belowTheDurationBar = 2_000L
    assertEquals(Verdict.STARVED, evaluate(bufferedAheadMs = belowTheDurationBar, loading = true))
    assertEquals(Verdict.STALLED, evaluate(bufferedAheadMs = belowTheDurationBar, loading = false))
  }

  @Test
  fun aLoaderStillFetchingWithATinyBufferIsAnOrdinaryRebuffer() {
    assertEquals(Verdict.STARVED, evaluate(bufferedAheadMs = 500L, loading = true))
  }

  @Test
  fun aStaleNotYetFromTheLoadControlCannotVetoAStoppedLoader() {
    // media3 stops asking the moment a renderer goes unready — the failure this watchdog exists for
    // — so a `false` recorded before that must not outrank a loader that has since stopped.
    assertEquals(Verdict.STALLED, evaluate(bufferedAheadMs = 2_000L, loading = false, loadControlReady = false))
  }


  @Test
  fun aByteCappedBufferBelowTheDurationBarIsStillIndicted() {
    // The real failure this watchdog exists for, on a high bitrate stream: media3 released playback
    // off its byte target with only a couple of seconds buffered, and the player still will not move.
    val belowTheDurationBar = 2_000L
    assertEquals(Verdict.STARVED, evaluate(bufferedAheadMs = belowTheDurationBar))
    assertEquals(Verdict.STALLED, evaluate(bufferedAheadMs = belowTheDurationBar, loadControlReady = true))
  }

  @Test
  fun aLoadControlHoldingPlaybackBackIsNotIndictedWhileTheLoaderStillWants() {
    // Plenty buffered by duration, so the duration signal alone would indict; media3 saying "not
    // yet" while its loader keeps fetching is an ordinary rebuffer.
    assertEquals(Verdict.STALLED, evaluate(bufferedAheadMs = 30_000L))
    assertEquals(Verdict.STALLED, evaluate(bufferedAheadMs = 30_000L, loadControlReady = false))
    assertEquals(
      "nothing says this player could start",
      Verdict.STARVED,
      evaluate(bufferedAheadMs = 1_000L, loading = true, loadControlReady = false)
    )
  }

  @Test
  fun progressOutranksTheLoadControlVerdict() {
    assertEquals(
      Verdict.HEALTHY,
      evaluate(currentPositionMs = position + 5_000, loadControlReady = true)
    )
  }


  @Test
  fun aFastForwardNeedsProportionallyMoreMediaBeforeItIsIndicted() {
    // Enough media to start at 1x, but the load control measures its bar in playout time, so at 2x
    // this player is still legitimately rebuffering rather than stalled.
    val justEnoughAtNormalSpeed = BufferingStallPolicy.MIN_BUFFER_AHEAD_MS + 1_000L
    assertEquals(Verdict.STALLED, evaluate(bufferedAheadMs = justEnoughAtNormalSpeed))
    assertEquals(Verdict.STARVED, evaluate(bufferedAheadMs = justEnoughAtNormalSpeed, playbackSpeed = 2f))
  }

  @Test
  fun aSlowMotionPlayerNeedsLessMediaBeforeItIsIndicted() {
    val shortOfTheBar = BufferingStallPolicy.MIN_BUFFER_AHEAD_MS - 1_000L
    assertEquals(Verdict.STARVED, evaluate(bufferedAheadMs = shortOfTheBar))
    assertEquals(Verdict.STALLED, evaluate(bufferedAheadMs = shortOfTheBar, playbackSpeed = 0.5f))
  }

  @Test
  fun anImpossibleSpeedIsTreatedAsNormal() {
    assertEquals(Verdict.STALLED, evaluate(playbackSpeed = 0f))
    assertEquals(Verdict.STALLED, evaluate(playbackSpeed = -1f))
  }


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


  @Test
  fun frozenPositionWaitsOutTheTimeout() {
    assertEquals(Verdict.WAITING, evaluate(elapsedMs = BufferingStallPolicy.STALL_TIMEOUT_MS - 1))
  }

  /** The #1790 shape: data available, nothing playing, no error raised. */
  @Test
  fun bufferedButFrozenIsStalled() {
    assertEquals(Verdict.STALLED, evaluate())
  }


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
