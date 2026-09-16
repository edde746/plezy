package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * FFmpeg applies duplicate AVOptions in order, so what matters is the
 * effective key set mpv's decoder ends up with, not the serialization.
 */
class DecoderOptionsTest {
  private fun effective(options: String): Map<String, String> =
    options.split(',').filter { it.isNotEmpty() }.associate { it.substringBefore('=') to it.substringAfter('=') }

  @Test
  fun aUserLineWinsPerKeyAndTheSessionsOtherKeysSurvive() {
    val options = DecoderOptions()
      .putAll(MpvPlayerCore.initialDecoderEntries(36))
      .put("dolby_vision" to "0", "dv_p7_mode" to "strip")
    // The custom mpv config line a reporter used: it must not discard the
    // asynchronous backend or the DV routing along with the key it names.
    options.setUser("operating_rate=120,ndk_async=0")
    assertEquals(
      mapOf(
        "ndk_codec" to "1",
        "ndk_async" to "0",
        "dolby_vision" to "0",
        "dv_p7_mode" to "strip",
        "operating_rate" to "120"
      ),
      effective(options.compose())
    )
  }

  @Test
  fun aLaterSessionWriteKeepsTheUsersLine() {
    val options = DecoderOptions().putAll(MpvPlayerCore.initialDecoderEntries(31)).setUser("threads=2")
    options.put("dolby_vision" to "1", "dv_p7_mode" to "convert")
    options.put("frame_rate" to "23.976", "priority" to "0")
    assertEquals(
      mapOf(
        "ndk_codec" to "1",
        "ndk_async" to "1",
        "dolby_vision" to "1",
        "dv_p7_mode" to "convert",
        "frame_rate" to "23.976",
        "priority" to "0",
        "threads" to "2"
      ),
      effective(options.compose())
    )
    // A DV change replaces only the DV choices.
    options.put("dolby_vision" to "0", "dv_p7_mode" to "native")
    assertEquals("0", effective(options.compose())["dolby_vision"])
    assertEquals("native", effective(options.compose())["dv_p7_mode"])
    assertEquals("2", effective(options.compose())["threads"])
  }

  @Test
  fun clearingTheUserLineAndRemovingKeys() {
    val options = DecoderOptions().put("ndk_codec" to "1", "frame_rate" to "25.000").setUser("x=1")
    options.setUser("   ")
    options.put("frame_rate" to null)
    assertEquals("ndk_codec=1", options.compose())
    assertEquals("", DecoderOptions().compose())
    assertEquals("x=1", DecoderOptions().setUser("x=1").compose())
  }
}
