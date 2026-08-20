package com.edde746.plezy.shared

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.MediaCodecInfoBuilder

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [25, 28])
class MediaCodecQueryTest {

  @Test
  fun preApi29CodecQueryDoesNotInvokeApi29HardwareFlag() {
    val codecInfo = MediaCodecInfoBuilder.newBuilder()
      .setName("OMX.qcom.video.decoder.avc")
      .setIsHardwareAccelerated(false)
      .build()

    assertTrue(MediaCodecQuery.isHardwareAccelerated(codecInfo))
  }

  @Test
  fun recognizesKnownPlatformAndFfmpegSoftwareCodecNames() {
    listOf(
      "OMX.google.h264.decoder",
      "OMX.FFMPEG.VIDEO.DECODER",
      "c2.android.avc.decoder",
      "c2.google.av1.decoder",
      "c2.ffmpeg.vp9.decoder",
      "vendor.video.sw.decoder"
    ).forEach { name ->
      assertTrue("expected software codec: $name", MediaCodecQuery.isSoftwareCodecName(name))
    }
  }

  @Test
  fun doesNotMisclassifyVendorHardwareCodecNames() {
    listOf(
      "OMX.qcom.video.decoder.avc",
      "OMX.MTK.VIDEO.DECODER.HEVC",
      "c2.qti.avc.decoder",
      "c2.exynos.hevc.decoder"
    ).forEach { name ->
      assertFalse("expected hardware codec: $name", MediaCodecQuery.isSoftwareCodecName(name))
    }
  }

  @Test
  fun api29RequiresPlatformHardwareFlagAndNonSoftwareComponentName() {
    assertFalse(MediaCodecQuery.isHardwareAccelerated(29, true, "c2.ffmpeg.aac.decoder"))
    assertFalse(MediaCodecQuery.isHardwareAccelerated(29, false, "c2.qti.avc.decoder"))
    assertTrue(MediaCodecQuery.isHardwareAccelerated(29, true, "c2.qti.avc.decoder"))
  }

  @Test
  fun preApi29RetainsNameBasedFallback() {
    assertFalse(MediaCodecQuery.isHardwareAccelerated(28, true, "OMX.google.h264.decoder"))
    assertTrue(MediaCodecQuery.isHardwareAccelerated(28, false, "OMX.qcom.video.decoder.avc"))
  }
}
