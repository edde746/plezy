package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The rate a MediaCodec decoder is declared with is what picks its clock on
 * Tensor (#2361): 24p content declared at 24 stayed at the 1080p30 point
 * and decoded 40 ms frames, 60 halved that, 120 quartered it.
 */
class DecoderOperatingRateTest {
  @Test
  fun a24pFileIsDeclaredWithHeadroomAtTheDisplayFloor() {
    // 2 x 23.976 = 48 is under the 60 Hz floor; the floor wins.
    assertEquals(60, DecoderOperatingRate.declared(23.976, 1.0, codecMaxFps = 180))
    // 2 x 30 = 60 either way.
    assertEquals(60, DecoderOperatingRate.declared(29.97, 1.0, codecMaxFps = 180))
    // 60p content gets twice its rate.
    assertEquals(120, DecoderOperatingRate.declared(59.94, 1.0, codecMaxFps = 180))
  }

  @Test
  fun speedScalesTheDeclarationAndTheContentRateStaysTheFloor() {
    assertEquals(120, DecoderOperatingRate.declared(23.976, 2.0, codecMaxFps = 240))
    // At 8x the content alone is 192 fps; the codec's own maximum caps it.
    assertEquals(180, DecoderOperatingRate.declared(23.976, 8.0, codecMaxFps = 180))
    assertEquals(240, DecoderOperatingRate.declared(23.976, 8.0, codecMaxFps = null))
    // Half speed halves the need; the floor scales with it.
    assertEquals(30, DecoderOperatingRate.declared(23.976, 0.5, codecMaxFps = 180))
    // A nonsense speed reads as 1x.
    assertEquals(60, DecoderOperatingRate.declared(23.976, Double.NaN, codecMaxFps = 180))
    assertEquals(60, DecoderOperatingRate.declared(23.976, 0.0, codecMaxFps = 180))
  }

  @Test
  fun theCodecsAdvertisedMaximumAndTheCeilingCap() {
    assertEquals(30, DecoderOperatingRate.declared(23.976, 1.0, codecMaxFps = 30))
    assertEquals(240, DecoderOperatingRate.declared(120.0, 4.0, codecMaxFps = 960))
    // No advertised maximum: the ceiling, never a saturating value.
    assertEquals(240, DecoderOperatingRate.boosted(120.0, 4.0, codecMaxFps = null))
    // A bogus maximum is ignored.
    assertEquals(60, DecoderOperatingRate.declared(23.976, 1.0, codecMaxFps = 0))
  }

  @Test
  fun theBoostIsTwiceTheDeclarationUnderTheSameCaps() {
    assertEquals(120, DecoderOperatingRate.boosted(23.976, 1.0, codecMaxFps = 180))
    assertEquals(180, DecoderOperatingRate.boosted(59.94, 1.0, codecMaxFps = 180))
    assertEquals(240, DecoderOperatingRate.boosted(59.94, 1.0, codecMaxFps = null))
  }

  @Test
  fun anUnknownContentRateStillDeclaresTheFloor() {
    assertEquals(60, DecoderOperatingRate.declared(0.0, 1.0, codecMaxFps = 180))
    assertEquals(120, DecoderOperatingRate.declared(Double.NaN, 2.0, codecMaxFps = 180))
  }

  @Test
  fun aDeficitRaisesOnceAfterSettlingAndRestoresAfterCalm() {
    val monitor = DecoderDeficitMonitor(lateFramesToRaise = 6, windowMs = 3_000, settleMs = 2_000, calmMs = 30_000)
    monitor.onPlaybackStarted(nowMs = 0)
    // The refill after a start: late frames inside the settle window are not a deficit.
    assertNull(monitor.onDropCount(0, 100))
    assertNull(monitor.onDropCount(20, 1_500))
    // Settled and calm: nothing.
    assertNull(monitor.onDropCount(20, 2_500))
    assertNull(monitor.onDropCount(22, 3_000))
    // Six late frames within the window: raise, once.
    assertNull(monitor.onDropCount(25, 3_500))
    assertEquals(DecoderDeficitMonitor.Decision.RAISE, monitor.onDropCount(28, 4_000))
    assertTrue(monitor.boosted)
    assertNull(monitor.onDropCount(40, 4_500))
    assertNull(monitor.onDropCount(60, 5_000))
    // Late frames keep the boost; the calm clock restarts with each one.
    assertNull(monitor.onDropCount(61, 20_000))
    assertNull(monitor.onDropCount(61, 45_000))
    assertEquals(DecoderDeficitMonitor.Decision.RESTORE, monitor.onDropCount(61, 50_001))
    assertFalse(monitor.boosted)
    // And it can raise again later.
    assertNull(monitor.onDropCount(63, 51_000))
    assertNull(monitor.onDropCount(65, 51_500))
    assertEquals(DecoderDeficitMonitor.Decision.RAISE, monitor.onDropCount(68, 52_000))
  }

  @Test
  fun scatteredLateFramesDoNotAddUpAcrossWindows() {
    val monitor = DecoderDeficitMonitor(lateFramesToRaise = 6, windowMs = 3_000, settleMs = 0, calmMs = 30_000)
    monitor.onPlaybackStarted(0)
    assertNull(monitor.onDropCount(0, 0))
    assertNull(monitor.onDropCount(3, 1_000))
    // A new window: the earlier three no longer count.
    assertNull(monitor.onDropCount(6, 4_500))
    assertNull(monitor.onDropCount(8, 5_000))
    assertFalse(monitor.boosted)
  }

  @Test
  fun aSeekResetsTheCountAndTheSettleWindowWithoutRestoring() {
    val monitor = DecoderDeficitMonitor(lateFramesToRaise = 2, windowMs = 3_000, settleMs = 2_000, calmMs = 30_000)
    monitor.onPlaybackStarted(0)
    assertNull(monitor.onDropCount(0, 2_000))
    assertEquals(DecoderDeficitMonitor.Decision.RAISE, monitor.onDropCount(2, 2_500))
    // mpv zeroes frame-drop-count on a seek: a smaller value is a new baseline, not a negative delta.
    monitor.onPlaybackStarted(10_000)
    assertNull(monitor.onDropCount(0, 10_100))
    assertNull(monitor.onDropCount(5, 11_000))
    assertTrue(monitor.boosted)
    // A new file starts over entirely.
    monitor.reset()
    assertFalse(monitor.boosted)
  }
}
