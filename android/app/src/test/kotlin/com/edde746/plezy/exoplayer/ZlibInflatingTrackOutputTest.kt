package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.ParserException
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput
import java.io.ByteArrayOutputStream
import java.util.zip.Deflater
import java.util.zip.DeflaterOutputStream
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class ZlibInflatingTrackOutputTest {

  @Test
  fun activeTransformInflatesChunkedSampleAndPreservesMetadata() {
    val original = ByteArray(512 * 1024) { (it % 251).toByte() }
    val compressed = deflate(original)
    val delegate = RecordingTrackOutput(retainBytes = true)
    val output = ZlibInflatingTrackOutput(delegate).apply { active = true }
    val split = compressed.size / 2

    output.sampleData(
      ParsableByteArray(compressed.copyOfRange(0, split)),
      split,
      TrackOutput.SAMPLE_DATA_PART_MAIN
    )
    output.sampleData(
      ParsableByteArray(compressed.copyOfRange(split, compressed.size)),
      compressed.size - split,
      TrackOutput.SAMPLE_DATA_PART_MAIN
    )
    output.sampleMetadata(42L, C.BUFFER_FLAG_KEY_FRAME, compressed.size, 7, null)

    assertArrayEquals(original, delegate.retained.toByteArray())
    assertEquals(42L, delegate.timeUs)
    assertEquals(C.BUFFER_FLAG_KEY_FRAME, delegate.flags)
    assertEquals(original.size, delegate.sampleSize)
    assertEquals(0, delegate.offset)
    assertEquals(1, delegate.metadataCount)
  }

  @Test
  fun exactlySixteenMiBInflatedSampleIsAccepted() {
    val size = 16 * 1024 * 1024
    val compressed = deflateRepeated(size)
    val delegate = RecordingTrackOutput()
    val output = ZlibInflatingTrackOutput(delegate).apply { active = true }

    feed(output, compressed)

    assertEquals(size, delegate.byteCount)
    assertEquals(size, delegate.sampleSize)
    assertEquals(1, delegate.metadataCount)
    assertTrue(compressed.size < 64 * 1024)
  }

  @Test
  fun oneByteOverInflatedLimitFailsBeforeDelegation() {
    val compressed = deflateRepeated(16 * 1024 * 1024 + 1)
    val delegate = RecordingTrackOutput()
    val output = ZlibInflatingTrackOutput(delegate).apply { active = true }

    assertThrows(ParserException::class.java) { feed(output, compressed) }

    assertEquals(0, delegate.byteCount)
    assertEquals(0, delegate.metadataCount)
    assertTrue(compressed.size < 64 * 1024)
  }

  @Test
  fun excessiveCompressionRatioFailsBeforeInflatedSizeLimit() {
    val compressed = deflate(ByteArray(8 * 1024 * 1024))
    val delegate = RecordingTrackOutput()
    val output = ZlibInflatingTrackOutput(delegate).apply { active = true }

    assertThrows(ParserException::class.java) { feed(output, compressed) }

    assertEquals(0, delegate.byteCount)
    assertEquals(0, delegate.metadataCount)
  }

  @Test
  fun corruptStreamPassesTheBoundedSampleThroughUnchanged() {
    val corrupt = byteArrayOf(0, 1, 2, 3)
    val delegate = RecordingTrackOutput(retainBytes = true)
    val output = ZlibInflatingTrackOutput(delegate).apply { active = true }

    feed(output, corrupt)

    assertArrayEquals(corrupt, delegate.retained.toByteArray())
    assertEquals(corrupt.size, delegate.sampleSize)
    assertEquals(1, delegate.metadataCount)
  }

  @Test
  fun truncatedAndDictionaryStreamsFailClosed() {
    val valid = deflate(ByteArray(4096) { 7 })
    val dictionary = "shared-zlib-dictionary".toByteArray()
    val cases = listOf(
      valid.copyOf(valid.size - 2),
      deflate(ByteArray(4096) { 3 }, dictionary)
    )

    for (compressed in cases) {
      val delegate = RecordingTrackOutput()
      val output = ZlibInflatingTrackOutput(delegate).apply { active = true }

      assertThrows(ParserException::class.java) { feed(output, compressed) }
      assertEquals(0, delegate.byteCount)
      assertEquals(0, delegate.metadataCount)
    }
  }

  @Test
  fun inactiveWrapperDelegatesBytesAndMetadataUnchanged() {
    val bytes = byteArrayOf(9, 8, 7, 6)
    val delegate = RecordingTrackOutput(retainBytes = true)
    val output = ZlibInflatingTrackOutput(delegate)

    output.sampleData(ParsableByteArray(bytes), bytes.size, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(99L, 3, bytes.size, 2, null)

    assertArrayEquals(bytes, delegate.retained.toByteArray())
    assertEquals(bytes.size, delegate.sampleSize)
    assertEquals(2, delegate.offset)
    assertEquals(99L, delegate.timeUs)
  }

  private fun feed(output: ZlibInflatingTrackOutput, compressed: ByteArray) {
    output.sampleData(
      ParsableByteArray(compressed),
      compressed.size,
      TrackOutput.SAMPLE_DATA_PART_MAIN
    )
    output.sampleMetadata(1L, C.BUFFER_FLAG_KEY_FRAME, compressed.size, 0, null)
  }

  private fun deflate(bytes: ByteArray, dictionary: ByteArray? = null): ByteArray {
    val target = ByteArrayOutputStream()
    val deflater = Deflater().apply {
      if (dictionary != null) setDictionary(dictionary)
    }
    DeflaterOutputStream(target, deflater).use { it.write(bytes) }
    return target.toByteArray()
  }

  private fun deflateRepeated(size: Int): ByteArray {
    val target = ByteArrayOutputStream()
    val chunk = ByteArray(8192) { (it % 7).toByte() }
    DeflaterOutputStream(target).use { stream ->
      var remaining = size
      while (remaining > 0) {
        val count = minOf(remaining, chunk.size)
        stream.write(chunk, 0, count)
        remaining -= count
      }
    }
    return target.toByteArray()
  }

  private class RecordingTrackOutput(
    private val retainBytes: Boolean = false
  ) : TrackOutput {
    val retained = ByteArrayOutputStream()
    var byteCount = 0
    var metadataCount = 0
    var timeUs = C.TIME_UNSET
    var flags = 0
    var sampleSize = -1
    var offset = -1

    override fun format(format: Format) = Unit

    override fun sampleData(
      input: DataReader,
      length: Int,
      allowEndOfInput: Boolean,
      sampleDataPart: Int
    ): Int {
      val buffer = ByteArray(length)
      val read = input.read(buffer, 0, length)
      if (read > 0) record(buffer, read)
      return read
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
      val buffer = ByteArray(length)
      data.readBytes(buffer, 0, length)
      record(buffer, length)
    }

    private fun record(buffer: ByteArray, length: Int) {
      byteCount += length
      if (retainBytes) retained.write(buffer, 0, length)
    }

    override fun sampleMetadata(
      timeUs: Long,
      flags: Int,
      size: Int,
      offset: Int,
      cryptoData: TrackOutput.CryptoData?
    ) {
      metadataCount++
      this.timeUs = timeUs
      this.flags = flags
      sampleSize = size
      this.offset = offset
    }
  }
}
