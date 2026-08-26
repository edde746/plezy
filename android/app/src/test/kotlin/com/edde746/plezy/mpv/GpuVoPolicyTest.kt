package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * P5 has no compatible base layer: on a device without native DV it must
 * leave the video plane for gpu-next software reshaping, and nothing else
 * may be routed (wrong-colors class verified on a Pixel 7). The vo target
 * matrix keeps gpu-next away from hardware sessions (#2010) while giving
 * the reshaping path the only vo that composites RPU metadata (#1902).
 */
class GpuVoPolicyTest {
  @Test
  fun `P5 without native support is routed`() {
    assertTrue(GpuVoPolicy.needsDvReshaping(5L, "auto", canPlayP5Natively = false))
  }

  @Test
  fun `P5 with native support stays on the plane`() {
    assertFalse(GpuVoPolicy.needsDvReshaping(5L, "auto", canPlayP5Natively = true))
  }

  @Test
  fun `base-layer-compatible profiles are never routed`() {
    // P7/P8 strip to an HDR10/HLG base layer; non-DV content has no profile.
    assertFalse(GpuVoPolicy.needsDvReshaping(7L, "auto", canPlayP5Natively = false))
    assertFalse(GpuVoPolicy.needsDvReshaping(8L, "auto", canPlayP5Natively = false))
    assertFalse(GpuVoPolicy.needsDvReshaping(null, "auto", canPlayP5Natively = false))
  }

  @Test
  fun `explicit conversion modes are user overrides and stay native`() {
    for (mode in listOf("disabled", "native", "dv81", "hevc", "hevc_strip")) {
      assertFalse(mode, GpuVoPolicy.needsDvReshaping(5L, mode, canPlayP5Natively = false))
    }
  }

  @Test
  fun `hdr tone-mapping is needed only for a PQ or HLG signal on a non-HDR display`() {
    assertTrue(GpuVoPolicy.needsHdrToneMapping("pq", displaySupportsHdr = false))
    assertTrue(GpuVoPolicy.needsHdrToneMapping("hlg", displaySupportsHdr = false))
    // An HDR display scans the signal out itself.
    assertFalse(GpuVoPolicy.needsHdrToneMapping("pq", displaySupportsHdr = true))
    assertFalse(GpuVoPolicy.needsHdrToneMapping("hlg", displaySupportsHdr = true))
    // SDR transfers need no mapping, and mpv reports none before the first
    // frame of a file.
    assertFalse(GpuVoPolicy.needsHdrToneMapping("bt.1886", displaySupportsHdr = false))
    assertFalse(GpuVoPolicy.needsHdrToneMapping("srgb", displaySupportsHdr = false))
    assertFalse(GpuVoPolicy.needsHdrToneMapping(null, displaySupportsHdr = false))
    assertFalse(GpuVoPolicy.needsHdrToneMapping("", displaySupportsHdr = false))
  }

  @Test
  fun `only direct mediacodec output can stay on the plane`() {
    // -copy also reads frames back into system memory, so it leaves too.
    assertTrue(GpuVoPolicy.needsSoftwareRender("no"))
    assertTrue(GpuVoPolicy.needsSoftwareRender("mediacodec-copy"))
    assertFalse(GpuVoPolicy.needsSoftwareRender("mediacodec"))
    // Unreported until the decoder initializes: stay on the plane.
    assertFalse(GpuVoPolicy.needsSoftwareRender(null))
    assertFalse(GpuVoPolicy.needsSoftwareRender(""))
  }

  @Test
  fun `a software-decoding session targets gpu, not gpu-next`() {
    assertEquals("gpu", GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_SW_DECODE)))
    assertEquals("gpu", GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_SHADERS)))
    assertEquals(
      "gpu",
      GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_SHADERS, GpuVoPolicy.REASON_SW_DECODE))
    )
  }

  @Test
  fun `no reasons keeps the video plane`() {
    assertNull(GpuVoPolicy.targetFor(emptySet()))
  }

  @Test
  fun `dv reshaping targets gpu-next even alongside other reasons`() {
    assertEquals("gpu-next", GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_DV_RESHAPE)))
    assertEquals(
      "gpu-next",
      GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_SHADERS, GpuVoPolicy.REASON_DV_RESHAPE))
    )
  }

  @Test
  fun `shaders and chain failure target the hardware-safe gpu vo`() {
    assertEquals("gpu", GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_SHADERS)))
    assertEquals("gpu", GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_CHAIN_FAILURE)))
    assertEquals(
      "gpu",
      GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_SHADERS, GpuVoPolicy.REASON_CHAIN_FAILURE))
    )
  }

  @Test
  fun `hdr tone-mapping targets gpu but yields to dv reshaping`() {
    assertEquals("gpu", GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_HDR_SDR)))
    assertEquals(
      "gpu",
      GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_HDR_SDR, GpuVoPolicy.REASON_SHADERS))
    )
    assertEquals(
      "gpu-next",
      GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_HDR_SDR, GpuVoPolicy.REASON_DV_RESHAPE))
    )
  }
}
