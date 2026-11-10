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

  @Test
  fun amlogicGoogleTvBoxesRaiseGraphicsBlackInDolbyVision() {
    // #2926: Xiaomi TV Box S 3rd Gen; the onn boxes report the same vendor string.
    assertTrue(DeviceQuirks.raisesGraphicsBlackInDolbyVision("Amlogic", "Xiaomi"))
    assertTrue(DeviceQuirks.raisesGraphicsBlackInDolbyVision("amlogic", "onn."))
  }

  @Test
  fun amlogicFireTvKeepsTheOpaqueLetterbox() {
    // The Fire TV Cube 3 is Amlogic but needs opaque black like the MediaTek Fire TVs.
    assertFalse(DeviceQuirks.raisesGraphicsBlackInDolbyVision("Amlogic", "Amazon"))
  }

  @Test
  fun otherSocsAndUnreportedVendorsKeepTheOpaqueLetterbox() {
    // MediaTek is where the opaque fill fixed gray bars (#2163); pre-S devices report no vendor.
    assertFalse(DeviceQuirks.raisesGraphicsBlackInDolbyVision("Mediatek", "Google"))
    assertFalse(DeviceQuirks.raisesGraphicsBlackInDolbyVision("NVIDIA", "NVIDIA"))
    assertFalse(DeviceQuirks.raisesGraphicsBlackInDolbyVision("unknown", "Xiaomi"))
    assertFalse(DeviceQuirks.raisesGraphicsBlackInDolbyVision(null, "Xiaomi"))
  }

  @Test
  fun amlogicAndMediatekTvBoxesDelayTheSubtitlePlane() {
    // #2894: SEI Box R 4K Plus (S905X4) and Google TV Streamer (MT8696) report these strings.
    assertTrue(DeviceQuirks.videoPlaneLagsGraphics("Amlogic", isTv = true))
    assertTrue(DeviceQuirks.videoPlaneLagsGraphics("Mediatek", isTv = true))
    assertTrue(DeviceQuirks.videoPlaneLagsGraphics("MediaTek", isTv = true))
  }

  @Test
  fun otherSocsPhonesAndUnreportedVendorsKeepTheSubtitlePlaneOnTheVideoTimestamp() {
    // The Shield (Tegra, API 28) reports no vendor and shows both planes on one refresh.
    assertFalse(DeviceQuirks.videoPlaneLagsGraphics(null, isTv = true))
    assertFalse(DeviceQuirks.videoPlaneLagsGraphics("NVIDIA", isTv = true))
    assertFalse(DeviceQuirks.videoPlaneLagsGraphics("Realtek", isTv = true))
    assertFalse(DeviceQuirks.videoPlaneLagsGraphics("Mediatek", isTv = false))
    assertFalse(DeviceQuirks.videoPlaneLagsGraphics("Amlogic", isTv = false))
  }

  private fun asynchronous(
    manufacturer: String = "NVIDIA",
    model: String = "SHIELD Android TV",
    device: String = "mdarcy",
    sdkInt: Int = 28
  ) = DeviceQuirks.runsMediaCodecAsynchronouslyBelowS(manufacturer, model, device, sdkInt)

  @Test
  fun theDevicesRunWithAsynchronousMediaCodecBelowApi31UseIt() {
    // SHIELD TV Pro (2019) on Android 9 and Fire TV Stick 4K Max (2nd gen) on Fire OS 8.
    assertTrue(asynchronous())
    assertTrue(asynchronous(manufacturer = "Amazon", model = "AFTKRT", device = "karat", sdkInt = 30))
    assertTrue(asynchronous(manufacturer = "nvidia", device = "MDARCY"))
    assertTrue(asynchronous(manufacturer = "amazon", model = "aftkrt", device = "karat", sdkInt = 30))
  }

  @Test
  fun theSameDevicesOnAnApiLevelThatWasNotRunStaySynchronous() {
    assertFalse(asynchronous(sdkInt = 30))
    assertFalse(asynchronous(sdkInt = 26))
    assertFalse(asynchronous(manufacturer = "Amazon", model = "AFTKRT", device = "karat", sdkInt = 28))
  }

  @Test
  fun siblingModelsThatWereNotRunStaySynchronous() {
    // Every SHIELD reports the same model, so only the board tells the 2019 Pro apart.
    assertFalse(asynchronous(device = "darcy"))
    assertFalse(asynchronous(device = "foster"))
    assertFalse(asynchronous(device = "sif"))
    assertFalse(asynchronous(manufacturer = "Amazon", model = "AFTKM", device = "kara", sdkInt = 30))
    assertFalse(asynchronous(manufacturer = "Amazon", model = "AFTMM", device = "mantis", sdkInt = 28))
    assertFalse(asynchronous(manufacturer = "Google", model = "Chromecast", device = "sabrina", sdkInt = 30))
    // A board name alone is not the device.
    assertFalse(asynchronous(manufacturer = "Amazon", model = "AFTKM", device = "mdarcy"))
  }
}
