package com.edde746.plezy.exoplayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FfmpegDemuxerPolicyTest {
  @Test
  fun wireValuesRoundTrip() {
    assertEquals(FfmpegDemuxerPolicy.Preference.FFMPEG, FfmpegDemuxerPolicy.fromWire("ffmpeg"))
    assertEquals(FfmpegDemuxerPolicy.Preference.MEDIA3_ONLY, FfmpegDemuxerPolicy.fromWire("media3"))
  }

  @Test
  fun unknownWireValuesResolveToFfmpeg() {
    assertEquals(FfmpegDemuxerPolicy.Preference.FFMPEG, FfmpegDemuxerPolicy.fromWire(null))
    assertEquals(FfmpegDemuxerPolicy.Preference.FFMPEG, FfmpegDemuxerPolicy.fromWire(""))
    assertEquals(FfmpegDemuxerPolicy.Preference.FFMPEG, FfmpegDemuxerPolicy.fromWire("bogus"))
    // Retired wire value from the container-list era maps to the default.
    assertEquals(FfmpegDemuxerPolicy.Preference.FFMPEG, FfmpegDemuxerPolicy.fromWire("auto"))
  }

  @Test
  fun ffmpegDemuxesByDefaultAndMedia3OnlyDisables() {
    assertTrue(FfmpegDemuxerPolicy.enabled(FfmpegDemuxerPolicy.Preference.FFMPEG))
    assertFalse(FfmpegDemuxerPolicy.enabled(FfmpegDemuxerPolicy.Preference.MEDIA3_ONLY))
  }
}
