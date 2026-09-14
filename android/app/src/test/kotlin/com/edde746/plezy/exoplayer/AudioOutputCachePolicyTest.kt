package com.edde746.plezy.exoplayer

import android.media.AudioFormat
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AudioOutputCachePolicyTest {

  @Test
  fun decodedPcmIsCacheable() {
    assertTrue(
      AudioOutputCachePolicy.mayCache(
        encoding = AudioFormat.ENCODING_PCM_16BIT,
        isOffload = false,
        sdkInt = 34
      )
    )
  }

  @Test
  fun everyPcmWidthIsCacheable() {
    val pcmEncodings = listOf(
      AudioFormat.ENCODING_PCM_8BIT,
      AudioFormat.ENCODING_PCM_16BIT,
      AudioFormat.ENCODING_PCM_24BIT_PACKED,
      AudioFormat.ENCODING_PCM_32BIT,
      AudioFormat.ENCODING_PCM_FLOAT
    )
    for (encoding in pcmEncodings) {
      assertTrue(
        "expected $encoding to be cacheable",
        AudioOutputCachePolicy.mayCache(encoding = encoding, isOffload = false, sdkInt = 34)
      )
    }
  }

  /** Parking a bitstream track holds the platform's direct output, which is often single-instance. */
  @Test
  fun bitstreamOutputIsNeverCacheable() {
    val passthroughEncodings = listOf(
      AudioFormat.ENCODING_AC3,
      AudioFormat.ENCODING_E_AC3,
      AudioFormat.ENCODING_E_AC3_JOC,
      AudioFormat.ENCODING_DTS,
      AudioFormat.ENCODING_DTS_HD,
      AudioFormat.ENCODING_DOLBY_TRUEHD
    )
    for (encoding in passthroughEncodings) {
      assertFalse(
        "expected $encoding to be excluded from the cache",
        AudioOutputCachePolicy.mayCache(encoding = encoding, isOffload = false, sdkInt = 34)
      )
    }
  }

  @Test
  fun offloadOutputIsNeverCacheable() {
    assertFalse(
      AudioOutputCachePolicy.mayCache(
        encoding = AudioFormat.ENCODING_PCM_16BIT,
        isOffload = true,
        sdkInt = 34
      )
    )
  }

  @Test
  fun cachingIsOffBelowTheFlushableApiLevel() {
    assertFalse(
      AudioOutputCachePolicy.mayCache(
        encoding = AudioFormat.ENCODING_PCM_16BIT,
        isOffload = false,
        sdkInt = AudioOutputCachePolicy.MIN_SDK_INT - 1
      )
    )
    assertTrue(
      AudioOutputCachePolicy.mayCache(
        encoding = AudioFormat.ENCODING_PCM_16BIT,
        isOffload = false,
        sdkInt = AudioOutputCachePolicy.MIN_SDK_INT
      )
    )
  }
}
