package com.edde746.plezy.exoplayer

import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.parser.AssSubtitleParserFactory
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Packed stereo metadata must use the same extractor as ASS, zlib and LATM playback. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MatroskaStereoModeTest {
  @Test
  fun observesStereoModeWithoutReplacingTheSubtitleExtractor() {
    val handler = AssHandler()
    val observed = mutableListOf<Long>()
    val extractor = ZlibMatroskaExtractor(AssSubtitleParserFactory(handler), handler) { observed.add(it) }
    extractor.startMasterElement(0xAE, 0L, 0L)
    extractor.integerElement(0xD7, 1L)
    assertEquals(emptyList<Long>(), observed)
    for (mode in listOf(1L, 11L, 2L, 3L)) extractor.integerElement(0x53B8, mode)
    assertEquals(listOf(1L, 11L, 2L, 3L), observed)
  }
}
