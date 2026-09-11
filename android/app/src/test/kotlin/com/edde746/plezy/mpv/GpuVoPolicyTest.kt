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
  fun `auto drives the DV decoder whenever the device can convert for the sink`() {
    // A DV display takes full DV, P7 included.
    assertEquals(
      GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "auto"),
      GpuVoPolicy.dvDecoderOptions("auto", displaySupportsDv = true, hasDvDecoder = true)
    )
    // No DV display but a decoder that converts: keep the DV path for
    // single-layer profiles, keep stripping dual-layer P7 to its base layer.
    assertEquals(
      GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "strip"),
      GpuVoPolicy.dvDecoderOptions("auto", displaySupportsDv = false, hasDvDecoder = true)
    )
    // Nothing on the device can convert, so software reshaping has to.
    assertEquals(
      GpuVoPolicy.DvDecoderOptions(dolbyVision = false, p7Mode = "strip"),
      GpuVoPolicy.dvDecoderOptions("auto", displaySupportsDv = false, hasDvDecoder = false)
    )
  }

  @Test
  fun `explicit conversion modes ignore the device and an unknown mode is rejected`() {
    for (display in listOf(false, true)) {
      for (decoder in listOf(false, true)) {
        assertEquals(
          "disabled/$display/$decoder",
          GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "native"),
          GpuVoPolicy.dvDecoderOptions("disabled", display, decoder)
        )
        assertEquals(
          "dv81/$display/$decoder",
          GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "convert"),
          GpuVoPolicy.dvDecoderOptions("dv81", display, decoder)
        )
        assertEquals(
          "hevc_strip/$display/$decoder",
          GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "strip"),
          GpuVoPolicy.dvDecoderOptions("hevc_strip", display, decoder)
        )
        assertNull(GpuVoPolicy.dvDecoderOptions("sideways", display, decoder))
      }
    }
  }

  /**
   * The defect that motivated pairing these two: P5 reached the plane with the
   * DV decoder switched off, which renders it as inverted plain HEVC. Whenever
   * P5 is allowed to stay on the plane, the decoder must be driving it.
   */
  @Test
  fun `P5 is never left on the plane with the DV decoder disabled`() {
    // The two predicates are not the same question: a device can ship a DV
    // decoder that does not advertise DvheStn, so it converts nothing for P5.
    for (display in listOf(false, true)) {
      for (anyDvDecoder in listOf(false, true)) {
        for (p5Decoder in listOf(false, true)) {
          // DvheStn is read off the DV decoder list, so advertising P5 without
          // owning a DV decoder cannot happen. Every other pairing can.
          if (p5Decoder && !anyDvDecoder) continue
          val reshaping = GpuVoPolicy.needsDvReshaping(5L, "auto", canPlayP5Natively = p5Decoder)
          val options = GpuVoPolicy.dvDecoderOptions("auto", display, anyDvDecoder)!!
          assertTrue("display=$display any=$anyDvDecoder p5=$p5Decoder", reshaping || options.dolbyVision)
        }
      }
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
  fun `only an AV1 session asking for hardware decode on BigOcean parks the decoder across a rebuild`() {
    assertTrue(GpuVoPolicy.needsParkedRebuild("av1", "mediacodec,mediacodec-copy", bigOceanAv1 = true))
    assertTrue(GpuVoPolicy.needsParkedRebuild("av1", "mediacodec", bigOceanAv1 = true))
    // Other decoders survive being re-created inside the rebuild.
    assertFalse(GpuVoPolicy.needsParkedRebuild("av1", "mediacodec", bigOceanAv1 = false))
    assertFalse(GpuVoPolicy.needsParkedRebuild("hevc", "mediacodec", bigOceanAv1 = true))
    // A software session (user setting or a per-file hold) never touches the hardware instance.
    assertFalse(GpuVoPolicy.needsParkedRebuild("av1", "no", bigOceanAv1 = true))
    assertFalse(GpuVoPolicy.needsParkedRebuild("av1", "", bigOceanAv1 = true))
    assertFalse(GpuVoPolicy.needsParkedRebuild("av1", null, bigOceanAv1 = true))
    assertFalse(GpuVoPolicy.needsParkedRebuild(null, "mediacodec", bigOceanAv1 = true))
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
  fun `High 10 without a hardware profile is software-decoded up front`() {
    assertTrue(GpuVoPolicy.needsSoftwareDecode("h264", "High 10", hardwareHigh10 = false, hardwareAv1 = true))
    assertTrue(GpuVoPolicy.needsSoftwareDecode("h264", "High 10 Intra", hardwareHigh10 = false, hardwareAv1 = true))
    assertEquals("gpu", GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_CODEC_SW_DECODE)))
  }

  @Test
  fun `hardware supported and unrelated streams retain the configured decoder`() {
    // A decoder that advertises the profile gets to try.
    assertFalse(GpuVoPolicy.needsSoftwareDecode("h264", "High 10", hardwareHigh10 = true, hardwareAv1 = false))
    // 8-bit profiles, other codecs, and streams whose container carries no
    // profile (Annex B transport streams) are not routed.
    assertFalse(GpuVoPolicy.needsSoftwareDecode("h264", "High", hardwareHigh10 = false, hardwareAv1 = false))
    assertFalse(GpuVoPolicy.needsSoftwareDecode("h264", "Constrained Baseline", hardwareHigh10 = false, hardwareAv1 = false))
    assertFalse(GpuVoPolicy.needsSoftwareDecode("hevc", "Main 10", hardwareHigh10 = false, hardwareAv1 = false))
    assertFalse(GpuVoPolicy.needsSoftwareDecode("h264", null, hardwareHigh10 = false, hardwareAv1 = false))
    assertFalse(GpuVoPolicy.needsSoftwareDecode("h264", "", hardwareHigh10 = false, hardwareAv1 = false))
    assertFalse(GpuVoPolicy.needsSoftwareDecode(null, "High 10", hardwareHigh10 = false, hardwareAv1 = false))
  }

  @Test
  fun `AV1 bypasses software MediaCodec even without a reported profile`() {
    assertTrue(GpuVoPolicy.needsSoftwareDecode("av1", "Main", hardwareHigh10 = true, hardwareAv1 = false))
    assertTrue(GpuVoPolicy.needsSoftwareDecode("av1", null, hardwareHigh10 = true, hardwareAv1 = false))
    assertTrue(GpuVoPolicy.needsSoftwareDecode("av1", "", hardwareHigh10 = true, hardwareAv1 = false))
    assertFalse(GpuVoPolicy.needsSoftwareDecode("av1", "Main", hardwareHigh10 = false, hardwareAv1 = true))
  }

  // The per-file policies run inside on_preloaded, before mpv selects a
  // track, so the track they decide for comes from the pending selection.

  @Test
  fun `auto selection follows mpv's pending choice, not track-list order`() {
    // Cover art first, the default-flagged feature second: mpv picks 2.
    assertEquals(2L, GpuVoPolicy.pendingVideoTrackId("auto", "2", listOf(1L, 2L)))
    assertEquals(1L, GpuVoPolicy.pendingVideoTrackId("auto", "1", listOf(1L, 2L)))
  }

  @Test
  fun `explicit vid answers on its own`() {
    assertEquals(2L, GpuVoPolicy.pendingVideoTrackId("2", pendingVid = null, videoTrackIds = listOf(1L, 2L)))
    // A user's explicit choice is never re-selected, even when mpv would
    // pick differently.
    assertEquals(1L, GpuVoPolicy.pendingVideoTrackId("1", "2", listOf(1L, 2L)))
    // No such track: mpv selects nothing, so nothing is routed.
    assertNull(GpuVoPolicy.pendingVideoTrackId("7", "2", listOf(1L, 2L)))
  }

  @Test
  fun `no video selection yields no track`() {
    assertNull(GpuVoPolicy.pendingVideoTrackId("no", "1", listOf(1L, 2L)))
    assertNull(GpuVoPolicy.pendingVideoTrackId("auto", "no", listOf(1L, 2L)))
    assertNull(GpuVoPolicy.pendingVideoTrackId("auto", "1", emptyList()))
  }

  @Test
  fun `without the pending-vid property the first track is the fallback`() {
    assertEquals(1L, GpuVoPolicy.pendingVideoTrackId("auto", null, listOf(1L, 2L)))
    assertEquals(1L, GpuVoPolicy.pendingVideoTrackId(null, null, listOf(1L, 2L)))
    assertNull(GpuVoPolicy.pendingVideoTrackId("auto", null, emptyList()))
  }

  @Test
  fun `cheap render tier needs a GL vo on a driver without norm16`() {
    assertTrue(GpuVoPolicy.needsCheapRenderTier(glVoActive = true, textureNorm16 = false))
    // The plane never scales in GL; a capable GPU keeps mpv's defaults.
    assertFalse(GpuVoPolicy.needsCheapRenderTier(glVoActive = false, textureNorm16 = false))
    assertFalse(GpuVoPolicy.needsCheapRenderTier(glVoActive = true, textureNorm16 = true))
  }

  @Test
  fun `cheap tier replaces only options still at their mpv default`() {
    for ((option, defaults) in GpuVoPolicy.MPV_DEFAULT_RENDER_OPTIONS) {
      for (default in defaults) assertTrue(option, GpuVoPolicy.isDefaultRenderOption(option, default))
      // A user's mpv.conf value, or an unreadable option, is left alone.
      assertFalse(option, GpuVoPolicy.isDefaultRenderOption(option, "ewa_lanczos"))
      assertFalse(option, GpuVoPolicy.isDefaultRenderOption(option, null))
    }
    // cscale's default is "inherit", which mpv 0.41 reads back as empty.
    assertTrue(GpuVoPolicy.isDefaultRenderOption("cscale", ""))
    assertFalse(GpuVoPolicy.isDefaultRenderOption("scale", ""))
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
