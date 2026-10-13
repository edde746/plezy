package com.edde746.plezy.exoplayer

import android.app.Activity
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.LoadControl
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
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

  @Test
  fun byteCapHysteresisSuppressesMicroReadsUntilBufferDrainsToLowWaterMark() {
    val targetBytes = 10 * 64 * 1024 // 10 segments (640 KiB)
    val delegate = FakeLoadControl(targetBytes = targetBytes)
    var rebufferCalls = 0
    val observing = ObservingLoadControl(
      delegate = delegate,
      targetBufferBytes = targetBytes,
      onRebuffering = { rebufferCalls++ }
    )

    // 1. Fill allocator to targetBytes (10 segments). Delegate stops loading.
    delegate.setAllocatedSegments(10)
    assertFalse(observing.shouldContinueLoading(delegate.parametersWith(bufferedDurationUs = 6_000_000L)))
    assertTrue("byte-cap hold should latch when stopped at targetBufferBytes", observing.holdingForByteCap)
    assertEquals(targetBytes, observing.allocatedBytes())

    // 2. Renderer consumes 1 segment (90% full). Because bufferedDurationUs (5.5s) < minBufferMs (15s),
    // DefaultLoadControl flips back to true immediately, which would cause 1 MiB micro-throttling.
    // ObservingLoadControl must keep returning false until 80% (8 segments).
    delegate.setAllocatedSegments(9)
    assertFalse(
      "must suppress micro-read at 90% full",
      observing.shouldContinueLoading(delegate.parametersWith(bufferedDurationUs = 5_500_000L))
    )
    assertTrue(observing.holdingForByteCap)

    // 3. Drains to 80% (8 segments): hysteresis releases and burst loading resumes.
    delegate.setAllocatedSegments(8)
    assertTrue(
      "must resume burst loading at 80% low-water mark",
      observing.shouldContinueLoading(delegate.parametersWith(bufferedDurationUs = 4_800_000L))
    )
    assertFalse(observing.holdingForByteCap)
    assertEquals(0, rebufferCalls)
  }

  @Test
  fun rebufferingReleasesByteCapHoldAndNotifiesOncePerRebufferEdge() {
    val targetBytes = 10 * 64 * 1024
    val delegate = FakeLoadControl(targetBytes = targetBytes)
    var rebufferCalls = 0
    val observing = ObservingLoadControl(
      delegate = delegate,
      targetBufferBytes = targetBytes,
      onRebuffering = { rebufferCalls++ }
    )

    delegate.setAllocatedSegments(10)
    assertFalse(observing.shouldContinueLoading(delegate.parametersWith(bufferedDurationUs = 6_000_000L)))
    assertTrue(observing.holdingForByteCap)

    // Mid-playback rebuffer at 9 segments: releases hold immediately and notifies callback once.
    delegate.setAllocatedSegments(9)
    assertTrue(
      observing.shouldContinueLoading(
        delegate.parametersWith(bufferedDurationUs = 1_000_000L, rebuffering = true)
      )
    )
    assertFalse(observing.holdingForByteCap)
    assertEquals(1, rebufferCalls)

    // Subsequent tick in the same rebuffer window does not double-fire.
    assertTrue(
      observing.shouldContinueLoading(
        delegate.parametersWith(bufferedDurationUs = 2_000_000L, rebuffering = true)
      )
    )
    assertEquals(1, rebufferCalls)

    // Exiting rebuffer and re-entering later fires again.
    assertTrue(
      observing.shouldContinueLoading(
        delegate.parametersWith(bufferedDurationUs = 6_000_000L, rebuffering = false)
      )
    )
    assertTrue(
      observing.shouldContinueLoading(
        delegate.parametersWith(bufferedDurationUs = 500_000L, rebuffering = true)
      )
    )
    assertEquals(2, rebufferCalls)
  }
}

/** Minimal complete [LoadControl], so the wrapper's recording can be exercised on its own. */
@androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
private class FakeLoadControl(private val targetBytes: Int = 0) : LoadControl {
  var startPlayback = false
  private val defaultAllocator = androidx.media3.exoplayer.upstream.DefaultAllocator(true, 64 * 1024)
  private val heldAllocations = mutableListOf<androidx.media3.exoplayer.upstream.Allocation>()

  val lastParameters: LoadControl.Parameters = parametersWith()

  fun parametersWith(
    bufferedDurationUs: Long = 0L,
    playbackSpeed: Float = 1f,
    rebuffering: Boolean = false
  ): LoadControl.Parameters = LoadControl.Parameters(
    androidx.media3.exoplayer.analytics.PlayerId.UNSET,
    androidx.media3.common.Timeline.EMPTY,
    LoadControl.EMPTY_MEDIA_PERIOD_ID,
    /* playbackPositionUs= */
    0L,
    /* bufferedDurationUs= */
    bufferedDurationUs,
    /* playbackSpeed= */
    playbackSpeed,
    /* playWhenReady= */
    true,
    /* rebuffering= */
    rebuffering,
    /* targetLiveOffsetUs= */
    androidx.media3.common.C.TIME_UNSET,
    /* lastRebufferRealtimeMs= */
    androidx.media3.common.C.TIME_UNSET
  )

  fun setAllocatedSegments(count: Int) {
    while (heldAllocations.size < count) {
      heldAllocations.add(defaultAllocator.allocate())
    }
    while (heldAllocations.size > count) {
      defaultAllocator.release(heldAllocations.removeAt(heldAllocations.lastIndex))
    }
  }

  override fun shouldStartPlayback(parameters: LoadControl.Parameters): Boolean = startPlayback

  override fun shouldContinueLoading(parameters: LoadControl.Parameters): Boolean {
    if (targetBytes > 0 && defaultAllocator.totalBytesAllocated >= targetBytes) {
      return false
    }
    return true
  }

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
  ): androidx.media3.exoplayer.upstream.Allocator = defaultAllocator

  override fun getBackBufferDurationUs(playerId: androidx.media3.exoplayer.analytics.PlayerId): Long = 0L

  override fun retainBackBufferFromKeyframe(playerId: androidx.media3.exoplayer.analytics.PlayerId): Boolean = false
}
