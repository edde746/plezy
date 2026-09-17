package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * The rate a MediaCodec decoder is declared with is what picks its clock on
 * Tensor (#2361): 24p content declared at 24 stayed at the 1080p30 point
 * and decoded 40 ms frames; 60 halved that.
 */
class DecoderOperatingRateTest {
  @Test
  fun theContentRateGetsHeadroomAboveTheFloor() {
    // 2 x 23.976 = 48 is under the 60 floor; the floor wins.
    assertEquals(60, DecoderOperatingRate.rate(23.976, 1.0, codecMaxFps = 180))
    assertEquals(60, DecoderOperatingRate.rate(29.97, 1.0, codecMaxFps = 180))
    // 60p content gets twice its rate.
    assertEquals(120, DecoderOperatingRate.rate(59.94, 1.0, codecMaxFps = 180))
    // An unknown content rate still declares the floor.
    assertEquals(60, DecoderOperatingRate.rate(0.0, 1.0, codecMaxFps = 180))
    assertEquals(60, DecoderOperatingRate.rate(Double.NaN, 1.0, codecMaxFps = 180))
  }

  @Test
  fun speedScalesTheDeclaration() {
    assertEquals(120, DecoderOperatingRate.rate(23.976, 2.0, codecMaxFps = 240))
    // Half speed halves the need.
    assertEquals(30, DecoderOperatingRate.rate(23.976, 0.5, codecMaxFps = 180))
  }

  @Test
  fun theCodecsAdvertisedMaximumAndTheCeilingCap() {
    assertEquals(30, DecoderOperatingRate.rate(23.976, 1.0, codecMaxFps = 30))
    // At 8x the content alone is 192 fps; the codec's own maximum caps it.
    assertEquals(180, DecoderOperatingRate.rate(23.976, 8.0, codecMaxFps = 180))
    assertEquals(240, DecoderOperatingRate.rate(120.0, 4.0, codecMaxFps = 960))
    // No advertised maximum: the ceiling, never a saturating value.
    assertEquals(240, DecoderOperatingRate.rate(23.976, 8.0, codecMaxFps = null))
    // A bogus maximum is ignored.
    assertEquals(60, DecoderOperatingRate.rate(23.976, 1.0, codecMaxFps = 0))
  }

  @Test
  fun aSpeedChangeRedeclaresWithTheFilesInputs() {
    val policy = DecoderOperatingRate()
    assertEquals(60, policy.onFile(23.976, codecMaxFps = 180))
    // The same speed again is not a change; a nonsense speed is not one either.
    assertNull(policy.onSpeed(1.0))
    assertNull(policy.onSpeed(Double.NaN))
    assertNull(policy.onSpeed(0.0))
    assertEquals(120, policy.onSpeed(2.0))
    // The next file is declared at the speed still in force.
    assertEquals(180, policy.onFile(59.94, codecMaxFps = 180))
  }

  @Test
  fun aUserPinSwitchesThePolicyOff() {
    val policy = DecoderOperatingRate()
    policy.pin()
    assertNull(policy.onFile(23.976, codecMaxFps = 180))
    assertNull(policy.onSpeed(2.0))
  }
}
