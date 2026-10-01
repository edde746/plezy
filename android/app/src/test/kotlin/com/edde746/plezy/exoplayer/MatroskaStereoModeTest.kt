package com.edde746.plezy.exoplayer

import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
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
    extractor.init(object : ExtractorOutput {
      override fun track(id: Int, type: Int): TrackOutput = error("metadata observation does not emit a track")
      override fun endTracks() = Unit
      override fun seekMap(seekMap: SeekMap) = Unit
    })
    val startMaster = ZlibMatroskaExtractor::class.java.getDeclaredMethod("startMasterElement", Int::class.javaPrimitiveType, Long::class.javaPrimitiveType, Long::class.javaPrimitiveType).apply { isAccessible = true }
    val integer = ZlibMatroskaExtractor::class.java.getDeclaredMethod("integerElement", Int::class.javaPrimitiveType, Long::class.javaPrimitiveType).apply { isAccessible = true }
    startMaster.invoke(extractor, 0xAE, 0L, 0L)
    integer.invoke(extractor, 0xD7, 1L)
    assertEquals(emptyList<Long>(), observed)
    for (mode in listOf(1L, 11L, 2L, 3L)) integer.invoke(extractor, 0x53B8, mode)
    assertEquals(listOf(1L, 11L, 2L, 3L), observed)
  }
}
