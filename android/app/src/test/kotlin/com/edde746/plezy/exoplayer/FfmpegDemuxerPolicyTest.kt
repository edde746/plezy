package com.edde746.plezy.exoplayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FfmpegDemuxerPolicyTest {

  @Test
  fun wireValuesRoundTrip() {
    assertEquals(FfmpegDemuxerPolicy.Preference.AUTO, FfmpegDemuxerPolicy.fromWire("auto"))
    assertEquals(
      FfmpegDemuxerPolicy.Preference.FFMPEG_FIRST,
      FfmpegDemuxerPolicy.fromWire("ffmpeg")
    )
    assertEquals(
      FfmpegDemuxerPolicy.Preference.MEDIA3_ONLY,
      FfmpegDemuxerPolicy.fromWire("media3")
    )
  }

  @Test
  fun unknownWireValuesResolveToAuto() {
    assertEquals(FfmpegDemuxerPolicy.Preference.AUTO, FfmpegDemuxerPolicy.fromWire(null))
    assertEquals(FfmpegDemuxerPolicy.Preference.AUTO, FfmpegDemuxerPolicy.fromWire(""))
    assertEquals(FfmpegDemuxerPolicy.Preference.AUTO, FfmpegDemuxerPolicy.fromWire("bogus"))
  }

  @Test
  fun autoHandsOnlyWeakContainersToFfmpeg() {
    // Containers media3 has no working extractor for — AVI (#2052), ASF/WMV,
    // MPEG-PS/VOB — plus Matroska, whose media3 extractor needed app-side
    // patches (zlib subtitles, LATM audio, cueless seeking, font attachments)
    // that libavformat covers natively.
    assertTrue(FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.AUTO, "avi"))
    assertTrue(FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.AUTO, "asf"))
    assertTrue(FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.AUTO, "mpeg"))
    assertTrue(FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.AUTO, "matroska,webm"))
    // Case-insensitive: probed names are lowercased by the extractor.
    assertTrue(FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.AUTO, "AVI"))

    // Containers media3 handles well stay on media3's extractors.
    assertFalse(FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.AUTO, "mp4"))
    assertFalse(FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.AUTO, "mpegts"))
    assertFalse(FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.AUTO, "ogg"))
  }

  @Test
  fun ffmpegFirstTakesEverythingFromMedia3() {
    for (container in listOf("avi", "asf", "mpeg", "matroska,webm", "mp4", "mpegts", "flv")) {
      assertTrue(
        "expected ffmpeg-first to accept $container",
        FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.FFMPEG_FIRST, container)
      )
    }
  }

  @Test
  fun media3OnlyNeverUsesTheFfmpegDemuxer() {
    for (container in listOf("avi", "asf", "mpeg", "matroska,webm", "mp4")) {
      assertFalse(
        FfmpegDemuxerPolicy.primaryAccepts(FfmpegDemuxerPolicy.Preference.MEDIA3_ONLY, container)
      )
    }
    assertFalse(FfmpegDemuxerPolicy.catchAllEnabled(FfmpegDemuxerPolicy.Preference.MEDIA3_ONLY))
  }

  @Test
  fun catchAllFollowsPreference() {
    assertTrue(FfmpegDemuxerPolicy.catchAllEnabled(FfmpegDemuxerPolicy.Preference.AUTO))
    assertTrue(FfmpegDemuxerPolicy.catchAllEnabled(FfmpegDemuxerPolicy.Preference.FFMPEG_FIRST))
    assertFalse(FfmpegDemuxerPolicy.catchAllEnabled(FfmpegDemuxerPolicy.Preference.MEDIA3_ONLY))
  }
}
