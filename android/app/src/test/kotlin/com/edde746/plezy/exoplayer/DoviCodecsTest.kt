package com.edde746.plezy.exoplayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DoviCodecsTest {
  @Test
  fun hevcProfilesUseDvhePrefix() {
    // Profile 8 level 6 is the stream from #2096: the record's dv_profile and
    // dv_level bytes must surface verbatim, matching media3's
    // DolbyVisionConfig output for the same file (dvhe.08.06).
    assertEquals("dvhe.08.06", DoviCodecs.rfc6381(8, 6))
    assertEquals("dvhe.04.09", DoviCodecs.rfc6381(4, 9))
    assertEquals("dvhe.05.06", DoviCodecs.rfc6381(5, 6))
    // Profile 7 keys DoviConvertingTrackOutput's P7 conversion.
    assertEquals("dvhe.07.06", DoviCodecs.rfc6381(7, 6))
  }

  @Test
  fun avcAndAv1ProfilesUseTheirOwnPrefixes() {
    assertEquals("dvav.09.05", DoviCodecs.rfc6381(9, 5))
    assertEquals("dav1.10.04", DoviCodecs.rfc6381(10, 4))
  }

  @Test
  fun twoDigitLevelsAreNotZeroPadded() {
    assertEquals("dvhe.08.10", DoviCodecs.rfc6381(8, 10))
  }

  @Test
  fun unrecognizedProfilesReturnNullSoTheBaseCodecFormatSurvives() {
    // Media3's DolbyVisionConfig table: anything it rejects must keep the
    // track's plain HEVC/AVC format instead of publishing an unplayable
    // video/dolby-vision variant.
    assertNull(DoviCodecs.rfc6381(0, 6))
    assertNull(DoviCodecs.rfc6381(2, 6))
    assertNull(DoviCodecs.rfc6381(6, 6))
    assertNull(DoviCodecs.rfc6381(20, 6))
  }
}
