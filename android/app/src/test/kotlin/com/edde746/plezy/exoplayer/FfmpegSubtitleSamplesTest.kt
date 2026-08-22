package com.edde746.plezy.exoplayer

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Byte-exact spec for the media3-shaped subtitle sample prefixes. The shapes
 * mirror media3 1.11.0 MatroskaExtractor's SSA_PREFIX/SUBRIP_PREFIX/VTT_PREFIX
 * with the duration patched into the second timecode; SsaParser,
 * SubripParser, WebvttParser, and AssTrackOutput all parse these exact bytes.
 */
class FfmpegSubtitleSamplesTest {

  private fun string(bytes: ByteArray): String = bytes.toString(Charsets.UTF_8)

  @Test
  fun ssaPrefixMatchesMatroskaExtractorShape() {
    // 1h 2m 3s 450ms -> centiseconds, ':' separator, single-digit hour.
    assertEquals(
      "Dialogue: 0:00:00:00,1:02:03:45,",
      string(FfmpegSubtitleSamples.ssaPrefix(3_723_450_000L))
    )
    assertEquals("Dialogue: 0:00:00:00,0:00:05:00,", string(FfmpegSubtitleSamples.ssaPrefix(5_000_000L)))
    // Sub-centisecond remainders truncate, matching integer division.
    assertEquals("Dialogue: 0:00:00:00,0:00:00:99,", string(FfmpegSubtitleSamples.ssaPrefix(999_999L)))
  }

  @Test
  fun subripPrefixIsACompleteCueHeader() {
    assertEquals(
      "1\n00:00:00,000 --> 01:02:03,450\n",
      string(FfmpegSubtitleSamples.subripPrefix(3_723_450_000L))
    )
    assertEquals("1\n00:00:00,000 --> 00:00:05,000\n", string(FfmpegSubtitleSamples.subripPrefix(5_000_000L)))
  }

  @Test
  fun vttPrefixIsAOneCueDocumentHeader() {
    assertEquals(
      "WEBVTT\n\n00:00:00.000 --> 01:02:03.450\n",
      string(FfmpegSubtitleSamples.vttPrefix(3_723_450_000L))
    )
    assertEquals("WEBVTT\n\n00:00:00.000 --> 00:00:05.000\n", string(FfmpegSubtitleSamples.vttPrefix(5_000_000L)))
  }

  @Test
  fun ssaDialogueFormatMatchesMedia3Constant() {
    assertEquals(
      "Format: Start, End, ReadOrder, Layer, Style, Name, MarginL, MarginR, MarginV, Effect, Text",
      string(FfmpegSubtitleSamples.SSA_DIALOGUE_FORMAT)
    )
  }
}
