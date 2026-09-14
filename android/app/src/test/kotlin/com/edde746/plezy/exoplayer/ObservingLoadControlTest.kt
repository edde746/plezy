package com.edde746.plezy.exoplayer

import android.app.Activity
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.LoadControl
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner

/**
 * The wrapper has to be a complete [LoadControl], not a partial one.
 *
 * media3's interface gives almost every member a default implementation that throws
 * `IllegalStateException`, so a forwarder this class forgets does not fail to compile — it takes the
 * player down at construction, or the first time ExoPlayer asks. Building a real player is the only
 * assertion that covers all of them at once, including methods a media3 upgrade adds later.
 */
@RunWith(RobolectricTestRunner::class)
class ObservingLoadControlTest {

  private fun loadControl() = DefaultLoadControl.Builder().setTargetBufferBytes(4 * 1024 * 1024).build()

  @Test
  fun aRealPlayerCanBeBuiltAndReleasedThroughTheWrapper() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val player = ExoPlayer.Builder(activity).setLoadControl(ObservingLoadControl(loadControl())).build()
    try {
      // Construction alone already routes through getBackBufferDurationUs and getAllocator.
      assertEquals(ExoPlayer.STATE_IDLE, player.playbackState)
    } finally {
      player.release()
    }
  }

  @Test
  fun theStartPlaybackVerdictIsRecordedAndResettable() {
    // A fake delegate, because a fabricated `Parameters` cannot satisfy DefaultLoadControl's own
    // timeline lookups. What matters here is that the wrapper reports what the delegate said.
    val delegate = FakeLoadControl()
    val observing = ObservingLoadControl(delegate)
    assertNull("nothing asked yet", observing.startPlaybackVerdict)

    delegate.startPlayback = true
    assertTrue(observing.shouldStartPlayback(delegate.lastParameters))
    assertEquals(true, observing.startPlaybackVerdict)

    delegate.startPlayback = false
    assertEquals(false, observing.shouldStartPlayback(delegate.lastParameters))
    assertEquals(false, observing.startPlaybackVerdict)

    observing.reset()
    assertNull("a fresh buffering window must not inherit the last verdict", observing.startPlaybackVerdict)
  }

  @Test
  fun otherCallsReachTheDelegate() {
    val delegate = loadControl()
    val observing = ObservingLoadControl(delegate)
    val playerId = androidx.media3.exoplayer.analytics.PlayerId.UNSET
    observing.onPrepared(playerId)
    try {
      assertSame(delegate.getAllocator(playerId)::class.java, observing.getAllocator(playerId)::class.java)
      assertEquals(delegate.getBackBufferDurationUs(playerId), observing.getBackBufferDurationUs(playerId))
      assertEquals(delegate.retainBackBufferFromKeyframe(playerId), observing.retainBackBufferFromKeyframe(playerId))
    } finally {
      observing.onReleased(playerId)
    }
  }
}

/** Minimal complete [LoadControl], so the wrapper's recording can be exercised on its own. */
@androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
private class FakeLoadControl : LoadControl {
  var startPlayback = false

  val lastParameters: LoadControl.Parameters = LoadControl.Parameters(
    androidx.media3.exoplayer.analytics.PlayerId.UNSET,
    androidx.media3.common.Timeline.EMPTY,
    LoadControl.EMPTY_MEDIA_PERIOD_ID,
    /* playbackPositionUs= */
    0L,
    /* bufferedDurationUs= */
    0L,
    /* playbackSpeed= */
    1f,
    /* playWhenReady= */
    true,
    /* rebuffering= */
    false,
    /* targetLiveOffsetUs= */
    androidx.media3.common.C.TIME_UNSET,
    /* lastRebufferRealtimeMs= */
    androidx.media3.common.C.TIME_UNSET
  )

  override fun shouldStartPlayback(parameters: LoadControl.Parameters): Boolean = startPlayback

  override fun shouldContinueLoading(parameters: LoadControl.Parameters): Boolean = true

  override fun onPrepared(playerId: androidx.media3.exoplayer.analytics.PlayerId) = Unit

  override fun onTracksSelected(
    parameters: LoadControl.Parameters,
    trackGroups: androidx.media3.exoplayer.source.TrackGroupArray,
    trackSelections: Array<out androidx.media3.exoplayer.trackselection.ExoTrackSelection>
  ) = Unit

  override fun onStopped(playerId: androidx.media3.exoplayer.analytics.PlayerId) = Unit

  override fun onReleased(playerId: androidx.media3.exoplayer.analytics.PlayerId) = Unit

  override fun getAllocator(
    playerId: androidx.media3.exoplayer.analytics.PlayerId
  ): androidx.media3.exoplayer.upstream.Allocator = androidx.media3.exoplayer.upstream.DefaultAllocator(true, 64 * 1024)

  override fun getBackBufferDurationUs(playerId: androidx.media3.exoplayer.analytics.PlayerId): Long = 0L

  override fun retainBackBufferFromKeyframe(playerId: androidx.media3.exoplayer.analytics.PlayerId): Boolean = false
}
