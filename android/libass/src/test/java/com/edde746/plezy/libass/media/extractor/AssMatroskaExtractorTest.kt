package com.edde746.plezy.libass.media.extractor

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.ParserException
import androidx.media3.extractor.DefaultExtractorInput
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.text.DefaultSubtitleParserFactory
import com.edde746.plezy.libass.media.AssHandler
import java.io.EOFException
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class AssMatroskaExtractorTest {

  @Test
  fun smallFontIsDeliveredAndNonFontDoesNotConsumeBudget() {
    val handler = AssHandler()
    val extractor = extractor(handler)

    attachment(extractor, "font/ttf")
    extractor.fileData(4, input(4, seed = 11))
    attachment(extractor, "application/octet-stream")
    extractor.fileData(9, input(9, seed = 22))

    val pending = handler.fontStore.pendingSnapshot()
    assertEquals(1, pending.size)
    assertEquals("fixture-font", pending.single().first)
    assertArrayEquals(byteArrayOf(11, 12, 13, 14), pending.single().second)
    assertEquals(4L, extractor.acceptedFontBytes)
  }

  @Test
  fun perFontLimitAcceptsExactBoundaryAndSkipsOneByteOver() {
    val handler = AssHandler()
    val extractor = extractor(handler)
    val limit = AssMatroskaExtractor.MAX_FONT_BYTES.toInt()

    attachment(extractor, "font/otf")
    extractor.fileData(limit, input(limit))
    attachment(extractor, "font/otf")
    extractor.fileData(limit + 1, input(limit + 1))

    assertEquals(limit.toLong(), extractor.acceptedFontBytes)
    assertEquals(1, handler.fontStore.pendingSnapshot().size)
  }

  @Test
  fun aggregateLimitIsDeterministicAcrossAttachmentEntries() {
    val handler = AssHandler()
    val extractor = extractor(handler)
    val perFont = AssMatroskaExtractor.MAX_FONT_BYTES.toInt()

    repeat(2) {
      attachment(extractor, "font/ttf")
      extractor.fileData(perFont, input(perFont, seed = it))
      extractor.endAttachment()
    }
    attachment(extractor, "font/ttf")
    extractor.fileData(1, input(1))

    assertEquals(AssMatroskaExtractor.MAX_TOTAL_FONT_BYTES, extractor.acceptedFontBytes)
    assertEquals(2, handler.fontStore.pendingSnapshot().size)
  }

  @Test
  fun negativeAndZeroSizesAllocateAndDeliverNothing() {
    val handler = AssHandler()
    val extractor = extractor(handler)
    attachment(extractor, "font/woff2")

    assertThrows(ParserException::class.java) {
      extractor.fileData(-1, input(0))
    }
    attachment(extractor, "font/woff2")
    extractor.fileData(0, input(0))

    assertEquals(0L, extractor.acceptedFontBytes)
    assertEquals(0, handler.fontStore.pendingSnapshot().size)
  }

  @Test
  fun failedReadDoesNotChargeAggregateBudgetOrDeliverPartialFont() {
    val handler = AssHandler()
    val extractor = extractor(handler)
    attachment(extractor, "font/ttf")

    assertThrows(EOFException::class.java) {
      extractor.fileData(1024, input(1024, available = 4))
    }
    assertEquals(0L, extractor.acceptedFontBytes)
    assertEquals(0, handler.fontStore.pendingSnapshot().size)

    attachment(extractor, "font/ttf")
    extractor.fileData(1024, input(1024))
    assertEquals(1024L, extractor.acceptedFontBytes)
    assertEquals(1, handler.fontStore.pendingSnapshot().size)
  }

  private fun extractor(handler: AssHandler) = TestExtractor(handler)

  private fun attachment(extractor: TestExtractor, mime: String) {
    extractor.setAttachment(mime)
  }

  private class TestExtractor(handler: AssHandler) :
    AssMatroskaExtractor(
      DefaultSubtitleParserFactory(),
      handler
    ) {
    fun setAttachment(mime: String) {
      startMasterElement(ID_ATTACHED_FILE, 0, 0)
      stringElement(ID_FILE_NAME, "fixture-font")
      stringElement(ID_FILE_MIME_TYPE, mime)
    }

    fun fileData(contentSize: Int, input: ExtractorInput) {
      binaryElement(ID_FILE_DATA, contentSize, input)
    }

    fun endAttachment() {
      endMasterElement(ID_ATTACHED_FILE)
    }

    override fun onFontRejected(contentSize: Int, acceptedBytes: Long, reason: String) = Unit
  }

  private fun input(
    declared: Int,
    available: Int = declared,
    seed: Int = 0
  ): ExtractorInput = DefaultExtractorInput(
    PatternDataReader(available, seed),
    0,
    declared.toLong()
  )

  private class PatternDataReader(
    private val size: Int,
    private val seed: Int
  ) : DataReader {
    private var position = 0

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
      if (position >= size) return C.RESULT_END_OF_INPUT
      val count = minOf(length, size - position)
      for (index in 0 until count) {
        buffer[offset + index] = ((seed + position + index) and 0xFF).toByte()
      }
      position += count
      return count
    }
  }
}
