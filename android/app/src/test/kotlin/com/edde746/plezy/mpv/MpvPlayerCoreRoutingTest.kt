package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The routing this app keeps where mpv-android's GpuVoPolicy decides
 * differently; the library's own rules are its GpuVoPolicyTest's.
 */
class MpvPlayerCoreRoutingTest {
  @Test
  fun `any HDR display keeps HDR video on the plane in every conversion mode`() {
    for (gamma in listOf("pq", "hlg")) {
      for (mode in listOf("auto", "player", "device")) {
        assertFalse(
          "$gamma in $mode",
          MpvPlayerCore.needsToneMapping(gamma, displayHdrSupported = true, conversionMode = mode, sdkInt = 34)
        )
      }
    }
    // The same file on a display without HDR follows the user's mode.
    assertTrue(MpvPlayerCore.needsToneMapping("hlg", displayHdrSupported = false, conversionMode = "player", sdkInt = 34))
  }

  @Test
  fun `HEVC Main 10 without a hardware profile stays with the hardware decoder`() {
    assertFalse(MpvPlayerCore.needsSoftwareDecode("hevc", "Main 10", hardwareHigh10 = false, hardwareAv1 = false))
    // H.264 High 10 without one still goes to software decode up front.
    assertTrue(MpvPlayerCore.needsSoftwareDecode("h264", "High 10", hardwareHigh10 = false, hardwareAv1 = false))
  }

  @Test
  fun `the cheap render tier leaves tone-mapping at mpv's curve`() {
    val mpvDefaults = mapOf("scale" to "lanczos", "cscale" to "", "dscale" to "hermite", "dither" to "fruit", "tone-mapping" to "auto")

    val replaced = MpvPlayerCore.cheapRenderReplacements { mpvDefaults[it] }

    assertEquals(mapOf("scale" to "lanczos", "cscale" to "", "dscale" to "hermite", "dither" to "fruit"), replaced)
  }

  @Test
  fun `the cheap render tier keeps a render option the user set`() {
    val replaced = MpvPlayerCore.cheapRenderReplacements { if (it == "scale") "ewa_lanczossharp" else null }

    assertFalse("scale" in replaced)
  }
}
