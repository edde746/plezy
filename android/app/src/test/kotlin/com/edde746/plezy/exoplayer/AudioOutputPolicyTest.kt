package com.edde746.plezy.exoplayer

import androidx.media3.common.MimeTypes
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AudioOutputPolicyTest {

  @Test
  fun passthroughDisabledBlocksBitstreamFormats() {
    val bitstreamFormats = listOf(
      "audio/ac3",
      "audio/eac3",
      "audio/eac3-joc",
      "audio/ac4",
      "audio/vnd.dts",
      "audio/vnd.dts.hd",
      "audio/vnd.dts.uhd",
      MimeTypes.AUDIO_TRUEHD
    )

    for (mimeType in bitstreamFormats) {
      assertTrue(mimeType, shouldBlockDirectOutputForPassthrough(mimeType, audioPassthroughEnabled = false))
    }
  }

  @Test
  fun passthroughEnabledAllowsBitstreamFormats() {
    assertFalse(shouldBlockDirectOutputForPassthrough("audio/ac3", audioPassthroughEnabled = true))
    assertFalse(shouldBlockDirectOutputForPassthrough(MimeTypes.AUDIO_TRUEHD, audioPassthroughEnabled = true))
  }

  @Test
  fun passthroughDisabledLeavesDecodedFormatsAvailable() {
    val decodedFormats = listOf(
      MimeTypes.AUDIO_AAC,
      MimeTypes.AUDIO_OPUS,
      MimeTypes.AUDIO_RAW,
      MimeTypes.AUDIO_FLAC
    )

    for (mimeType in decodedFormats) {
      assertFalse(mimeType, shouldBlockDirectOutputForPassthrough(mimeType, audioPassthroughEnabled = false))
    }
  }
}
