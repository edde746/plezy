package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * FFmpeg applies duplicate AVOptions in order, so what matters is the
 * effective key set mpv's decoder ends up with, not the serialization.
 */
class DecoderOptionsTest {
  private fun effective(options: String): Map<String, String> = options.split(',').filter { it.isNotEmpty() }.associate { it.substringBefore('=') to it.substringAfter('=') }

  @Test
  fun aUserLineWinsPerKeyAndTheSessionsOtherKeysSurvive() {
    val options = DecoderOptions()
    options.putAll(MpvPlayerCore.initialDecoderEntries(36))
    options.put("dolby_vision" to "0", "dv_p7_mode" to "strip")
    // A custom mpv config line naming one session key must not discard the
    // DV routing or the wrapper choice along with it.
    options.setUser("threads=2,async=0")
    assertEquals(
      mapOf(
        "ndk_codec" to "0",
        "async" to "0",
        "priority" to "0",
        "dolby_vision" to "0",
        "dv_p7_mode" to "strip",
        "threads" to "2"
      ),
      effective(options.compose())
    )
  }

  @Test
  fun aLaterSessionWriteKeepsTheUsersLine() {
    val options = DecoderOptions()
    options.putAll(MpvPlayerCore.initialDecoderEntries(31))
    options.setUser("threads=2")
    options.put("dolby_vision" to "1", "dv_p7_mode" to "convert")
    options.put("frame_rate" to "23.976")
    assertEquals(
      mapOf(
        "ndk_codec" to "0",
        "async" to "1",
        "priority" to "0",
        "dolby_vision" to "1",
        "dv_p7_mode" to "convert",
        "frame_rate" to "23.976",
        "threads" to "2"
      ),
      effective(options.compose())
    )
    // A DV change replaces only the DV choices.
    options.put("dolby_vision" to "0", "dv_p7_mode" to "native")
    val composed = effective(options.compose())
    assertEquals("0", composed["dolby_vision"])
    assertEquals("native", composed["dv_p7_mode"])
    assertEquals("2", composed["threads"])
  }

  @Test
  fun clearingTheUserLineAndRemovingKeys() {
    val options = DecoderOptions()
    options.put("ndk_codec" to "1", "frame_rate" to "25.000")
    options.setUser("x=1")
    options.setUser("   ")
    options.put("frame_rate" to null)
    assertEquals("ndk_codec=1", options.compose())
    assertEquals("", DecoderOptions().compose())
    val userOnly = DecoderOptions()
    userOnly.setUser("x=1")
    assertEquals("x=1", userOnly.compose())
  }
}
