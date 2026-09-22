package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
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
  fun `a DV display takes every profile on the DV decoder`() {
    for (profile in listOf(null, 5L, 7L, 8L)) {
      for (p5Decoder in listOf(false, true)) {
        assertEquals(
          "profile=$profile p5=$p5Decoder",
          GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "auto"),
          GpuVoPolicy.dvDecoderOptions("auto", displaySupportsDv = true, dvProfile = profile, canPlayP5Natively = p5Decoder)
        )
      }
    }
  }

  @Test
  fun `without a DV display only P5 with a converting decoder stays on the DV path`() {
    // P5 has no compatible base layer: the decoder that advertises it is the
    // only hardware path (#2290).
    assertEquals(
      GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "strip"),
      GpuVoPolicy.dvDecoderOptions("auto", displaySupportsDv = false, dvProfile = 5L, canPlayP5Natively = true)
    )
    // Nothing on the device converts P5, so software reshaping has to.
    assertEquals(
      GpuVoPolicy.DvDecoderOptions(dolbyVision = false, p7Mode = "strip"),
      GpuVoPolicy.dvDecoderOptions("auto", displaySupportsDv = false, dvProfile = 5L, canPlayP5Natively = false)
    )
    // P8 decodes its compatible base layer as plain HEVC whatever the device
    // ships: a DV decoder without a DV sink may convert to SDR (#2416).
    for (p5Decoder in listOf(false, true)) {
      assertEquals(
        "P8 p5=$p5Decoder",
        GpuVoPolicy.DvDecoderOptions(dolbyVision = false, p7Mode = "strip"),
        GpuVoPolicy.dvDecoderOptions("auto", displaySupportsDv = false, dvProfile = 8L, canPlayP5Natively = p5Decoder)
      )
      // P7 and non-DV content: the DV decoder has nothing to take.
      for (profile in listOf(null, 7L)) {
        assertEquals(
          "profile=$profile p5=$p5Decoder",
          GpuVoPolicy.DvDecoderOptions(dolbyVision = false, p7Mode = "strip"),
          GpuVoPolicy.dvDecoderOptions("auto", displaySupportsDv = false, dvProfile = profile, canPlayP5Natively = p5Decoder)
        )
      }
    }
  }

  @Test
  fun `explicit conversion modes ignore the device and file, and an unknown mode is rejected`() {
    for (display in listOf(false, true)) {
      for (profile in listOf(null, 5L, 8L)) {
        assertEquals(
          "disabled/$display/$profile",
          GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "native"),
          GpuVoPolicy.dvDecoderOptions("disabled", display, profile, canPlayP5Natively = false)
        )
        assertEquals(
          "dv81/$display/$profile",
          GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "convert"),
          GpuVoPolicy.dvDecoderOptions("dv81", display, profile, canPlayP5Natively = false)
        )
        assertEquals(
          "hevc_strip/$display/$profile",
          GpuVoPolicy.DvDecoderOptions(dolbyVision = true, p7Mode = "strip"),
          GpuVoPolicy.dvDecoderOptions("hevc_strip", display, profile, canPlayP5Natively = false)
        )
      }
    }
    assertThrows(IllegalArgumentException::class.java) {
      GpuVoPolicy.dvDecoderOptions("sideways", displaySupportsDv = false, dvProfile = null, canPlayP5Natively = false)
    }
    for (mode in GpuVoPolicy.DV_CONVERSION_MODES) {
      GpuVoPolicy.dvDecoderOptions(mode, displaySupportsDv = false, dvProfile = null, canPlayP5Natively = false)
    }
  }

  /**
   * The defect that motivated pairing these two: P5 reached the plane with the
   * DV decoder switched off, which renders it as inverted plain HEVC. Whenever
   * P5 is allowed to stay on the plane, the decoder must be driving it.
   */
  @Test
  fun `P5 is never left on the plane with the DV decoder disabled`() {
    for (display in listOf(false, true)) {
      for (p5Decoder in listOf(false, true)) {
        val reshaping = GpuVoPolicy.needsDvReshaping(5L, "auto", canPlayP5Natively = p5Decoder)
        val options = GpuVoPolicy.dvDecoderOptions("auto", display, dvProfile = 5L, canPlayP5Natively = p5Decoder)
        assertTrue("display=$display p5=$p5Decoder", reshaping || options.dolbyVision)
      }
    }
  }

  // Native support is whether the bundled FFmpeg will open a decoder, which
  // is narrower than what the device advertises: the app once counted
  // decoders FFmpeg never asks for and sent P5 to the plane as plain HEVC.

  private fun candidate(
    name: String,
    mime: String = GpuVoPolicy.DV_MIME,
    profiles: List<Int> = listOf(GpuVoPolicy.DV_PROFILE_DVHE_STN),
    isSoftwareOnly: Boolean = false
  ) = GpuVoPolicy.DvDecoderCandidate(name, mime, profiles, isSoftwareOnly)

  private fun nativeP5Decoder(candidates: List<GpuVoPolicy.DvDecoderCandidate>) = GpuVoPolicy.nativeDvDecoder(candidates, 5L)

  @Test
  fun `a hardware DvheStn decoder under the FFmpeg MIME type is the native P5 path`() {
    assertEquals("c2.amlogic.dolby-vision.dvhe.decoder", nativeP5Decoder(listOf(candidate("c2.amlogic.dolby-vision.dvhe.decoder"))))
    // Case-insensitive MIME match, as FFmpeg compares it.
    assertEquals("OMX.MTK.VIDEO.DECODER.DV", nativeP5Decoder(listOf(candidate("OMX.MTK.VIDEO.DECODER.DV", mime = "video/Dolby-Vision"))))
    // First match in list order, as FFmpeg takes it.
    assertEquals("first", nativeP5Decoder(listOf(candidate("first"), candidate("second"))))
  }

  @Test
  fun `a decoder registered only under a vendor DV MIME type is never opened`() {
    // FFmpeg probes video/dolby-vision alone; a device whose DV decoder only
    // answers to video/hevcdv "has DV" to MediaCodecList and none to FFmpeg.
    assertNull(nativeP5Decoder(listOf(candidate("c2.vendor.dv.decoder", mime = "video/hevcdv"))))
    assertNull(nativeP5Decoder(listOf(candidate("c2.vendor.dv.decoder", mime = "video/dv_hevc"))))
  }

  @Test
  fun `only the exact profile bit FFmpeg probes counts`() {
    // P7 (DvheDtb) and P8 (DvheSt) decoders convert nothing for single-layer P5.
    assertNull(nativeP5Decoder(listOf(candidate("c2.vendor.dv.decoder", profiles = listOf(0x40, 0x100)))))
    assertNull(nativeP5Decoder(listOf(candidate("c2.vendor.dv.decoder", profiles = emptyList()))))
    assertNull(nativeP5Decoder(emptyList()))
    // And a P5-only decoder is not what FFmpeg opens for a P8 stream.
    val p8Only = listOf(candidate("OMX.Nvidia.DOVI.decode", profiles = listOf(GpuVoPolicy.DV_PROFILE_DVHE_ST)))
    assertEquals("OMX.Nvidia.DOVI.decode", GpuVoPolicy.nativeDvDecoder(p8Only, 8L))
    assertNull(GpuVoPolicy.nativeDvDecoder(p8Only, 5L))
    // FFmpeg re-routes single-layer P5 and P8 only; P7 and non-DV never probe.
    val both = listOf(candidate("c2.vendor.dv.decoder", profiles = listOf(0x20, 0x40, 0x100)))
    assertNull(GpuVoPolicy.nativeDvDecoder(both, 7L))
    assertNull(GpuVoPolicy.nativeDvDecoder(both, null))
  }

  @Test
  fun `software-only decoders are skipped as FFmpeg skips them`() {
    // The API 29+ platform flag.
    assertNull(nativeP5Decoder(listOf(candidate("c2.android.dolby-vision.decoder", isSoftwareOnly = true))))
    // FFmpeg's own name blacklist on releases without the flag.
    for (name in listOf(
      "OMX.google.dolby-vision.decoder",
      "OMX.ffmpeg.dv.decoder",
      "OMX.SEC.hevc.sw.dec",
      "OMX.qcom.video.decoder.hevcswvdec"
    )) {
      assertNull(name, nativeP5Decoder(listOf(candidate(name))))
    }
    // The blacklist is exact where FFmpeg's is: Samsung hardware and the
    // Qualcomm hardware HEVC decoder are not software.
    assertEquals("OMX.SEC.hevc.dec", nativeP5Decoder(listOf(candidate("OMX.SEC.hevc.dec"))))
    assertEquals("OMX.qcom.video.decoder.hevc", nativeP5Decoder(listOf(candidate("OMX.qcom.video.decoder.hevc"))))
    // A hardware decoder later in the list still wins over an earlier software one.
    assertEquals("c2.vendor.dv.decoder", nativeP5Decoder(listOf(candidate("OMX.google.dv", isSoftwareOnly = true), candidate("c2.vendor.dv.decoder"))))
  }

  @Test
  fun `a P5 file that lands in software decode needs reshaping whatever was predicted`() {
    // hwdec-current is the outcome; a predicted native decoder that failed to
    // open leaves the base layer unreshaped unless gpu-next takes it.
    assertTrue(GpuVoPolicy.softwareDecodeNeedsDvReshaping(5L, "auto", hwdecCurrent = "no"))
    assertTrue(GpuVoPolicy.softwareDecodeNeedsDvReshaping(5L, "auto", hwdecCurrent = "mediacodec-copy"))
    // Still on the hardware decoder: nothing to react to.
    assertFalse(GpuVoPolicy.softwareDecodeNeedsDvReshaping(5L, "auto", hwdecCurrent = "mediacodec"))
    assertFalse(GpuVoPolicy.softwareDecodeNeedsDvReshaping(5L, "auto", hwdecCurrent = null))
    // Base-layer-compatible profiles and explicit modes follow needsDvReshaping.
    assertFalse(GpuVoPolicy.softwareDecodeNeedsDvReshaping(8L, "auto", hwdecCurrent = "no"))
    assertFalse(GpuVoPolicy.softwareDecodeNeedsDvReshaping(null, "auto", hwdecCurrent = "no"))
    assertFalse(GpuVoPolicy.softwareDecodeNeedsDvReshaping(5L, "native", hwdecCurrent = "no"))
  }

  @Test
  fun `software decode with dv reshaping targets gpu-next, not gpu`() {
    assertEquals(
      "gpu-next",
      GpuVoPolicy.targetFor(setOf(GpuVoPolicy.REASON_SW_DECODE, GpuVoPolicy.REASON_DV_RESHAPE))
    )
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
