package com.edde746.plezy.shared

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DeviceQuirksTest {

  private fun unreliable(
    manufacturer: String = "Amazon",
    model: String = "AFTMM",
    fps: Float = 23.976f
  ) = DeviceQuirks.hasUnreliableTunneledPlayback(manufacturer, model, fps)

  @Test
  fun fireTvStick4kJuddersOnFilmRateSoTunnelingIsWithdrawn() {
    assertTrue(unreliable(fps = 23.976f))
    assertTrue(unreliable(fps = 24f))
    assertTrue(unreliable(fps = 25f))
    assertTrue(unreliable(fps = 29.97f))
    assertTrue(unreliable(fps = DeviceQuirks.MAX_UNRELIABLE_TUNNELED_FPS))
  }

  @Test
  fun highFrameRateKeepsTunnelingOnTheSameDevice() {
    // Tunneling exists for this workload and Amazon recommends it here, so the
    // quirk must not reach 4K50/60 content.
    assertFalse(unreliable(fps = 50f))
    assertFalse(unreliable(fps = 59.94f))
    assertFalse(unreliable(fps = 60f))
  }

  @Test
  fun unknownFrameRateLeavesBehaviourUnchanged() {
    assertFalse(unreliable(fps = -1f))
    assertFalse(unreliable(fps = 0f))
  }

  @Test
  fun otherAmazonHardwareIsUnaffected() {
    // Only AFTMM was reported and A/B-tested; siblings keep stock behaviour.
    assertFalse(unreliable(model = "AFTKA"))
    assertFalse(unreliable(model = "AFTMM2"))
    assertFalse(unreliable(model = "AFTSSS"))
    assertFalse(unreliable(model = "KFMAWI"))
  }

  @Test
  fun otherManufacturersAreUnaffected() {
    assertFalse(unreliable(manufacturer = "NVIDIA", model = "SHIELD Android TV"))
    assertFalse(unreliable(manufacturer = "Sony", model = "BRAVIA 4K GB"))
  }

  @Test
  fun buildStringCasingDoesNotDefeatTheMatch() {
    assertTrue(unreliable(manufacturer = "amazon", model = "aftmm"))
  }
}
