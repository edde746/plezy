package com.edde746.plezy.mpv

import android.graphics.SurfaceTexture
import android.view.Surface
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The Surface vote must reproduce Media3's `VideoFrameReleaseHelper`
 * contract: SurfaceFlinger sees the playback cadence only while frames are
 * being presented, and never keeps a vote from a Surface the player left.
 */
@RunWith(RobolectricTestRunner::class)
class SurfaceFrameRateVoteTest {
  private val calls = mutableListOf<Pair<Surface, Float>>()
  private val vote = SurfaceFrameRateVote { surface, rate -> calls += surface to rate }

  @Test
  fun votesTheMediaRateTimesSpeedOnlyWhileStarted() {
    val surface = Surface(SurfaceTexture(0))
    vote.onSurfaceChanged(surface)
    // A Surface may carry an earlier vote, so attaching resets it (Media3's
    // forced update); until playback starts that is all it hears.
    assertEquals(listOf(surface to 0f), calls)
    vote.onMediaFrameRate(23.976f)
    // A paused session presents nothing; a vote here would hold the display
    // at the content rate through menus and the pause screen.
    assertEquals(1, calls.size)

    vote.onStarted()
    assertEquals(surface to 23.976f, calls.last())

    vote.onPlaybackSpeed(1.5f)
    assertEquals(surface to 23.976f * 1.5f, calls.last())

    vote.onStopped()
    assertEquals(surface to 0f, calls.last())
    assertEquals(4, calls.size)

    // Nothing to re-vote: stopped stays cleared even when inputs change.
    vote.onMediaFrameRate(25f)
    assertEquals(4, calls.size)
  }

  @Test
  fun aNewSurfaceClearsTheOldOneAndIsVotedEvenAtAnUnchangedRate() {
    val first = Surface(SurfaceTexture(0))
    val second = Surface(SurfaceTexture(0))
    vote.onMediaFrameRate(24f)
    vote.onStarted()
    vote.onSurfaceChanged(first)
    assertEquals(listOf(first to 24f), calls)

    // Same rate, different Surface: the compositor tracks votes per Surface,
    // so the new one must hear it and the old one must be released.
    vote.onSurfaceChanged(second)
    assertEquals(listOf(first to 24f, first to 0f, second to 24f), calls)

    // Leaving for the placeholder releases the real Surface; the placeholder
    // never gets a vote.
    vote.onSurfaceChanged(null)
    assertEquals(second to 0f, calls.last())
    assertEquals(4, calls.size)
    vote.onMediaFrameRate(30f)
    assertEquals(4, calls.size)
  }

  @Test
  fun losingTheMediaRateClearsAnActiveVote() {
    val surface = Surface(SurfaceTexture(0))
    vote.onMediaFrameRate(50f)
    vote.onStarted()
    vote.onSurfaceChanged(surface)
    assertEquals(listOf(surface to 50f), calls)

    // A new file starts with an unknown rate (Media3: Format.NO_VALUE).
    vote.onMediaFrameRate(0f)
    assertEquals(surface to 0f, calls.last())
    assertEquals(2, calls.size)

    // Garbage never becomes a vote.
    vote.onMediaFrameRate(Float.NaN)
    vote.onMediaFrameRate(-24f)
    assertEquals(2, calls.size)
  }
}
