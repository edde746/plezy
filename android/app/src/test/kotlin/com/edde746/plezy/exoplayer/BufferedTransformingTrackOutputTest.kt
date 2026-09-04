package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.ParserException
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput
import java.io.ByteArrayOutputStream
import java.io.EOFException
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Before
import org.junit.Test

class BufferedTransformingTrackOutputTest {
  @Before
  fun enableMedia3TestBoundsChecks() {
    ParsableByteArray.setShouldEnforceLimitOnLegacyMethods(true)
  }

  @After
  fun resetMedia3TestBoundsChecks() {
    ParsableByteArray.setShouldEnforceLimitOnLegacyMethods(null)
  }

  @Test
  fun activeTransformBuffersChunksAndEmitsOneNormalizedSample() {
    val delegate = RecordingTrackOutput()
    val output = IncrementingTrackOutput(delegate)

    output.sampleData(ParsableByteArray(byteArrayOf(1, 2)), 2, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleData(ParsableByteArray(byteArrayOf(3)), 1, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(42, C.BUFFER_FLAG_KEY_FRAME, 3, 0, null)

    assertArrayEquals(byteArrayOf(2, 3, 4), delegate.bytes.toByteArray())
    assertEquals(42, delegate.timeUs)
    assertEquals(3, delegate.sampleSize)
    assertEquals(0, delegate.sampleOffset)
  }

  @Test
  fun metadataBoundsDiscardAbandonedBytesAndPreserveTrailingSample() {
    val delegate = RecordingTrackOutput()
    val output = IncrementingTrackOutput(delegate)

    output.sampleData(ParsableByteArray(byteArrayOf(9, 9)), 2, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleData(ParsableByteArray(byteArrayOf(1, 2)), 2, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleData(ParsableByteArray(byteArrayOf(3, 4, 5)), 3, TrackOutput.SAMPLE_DATA_PART_MAIN)

    output.sampleMetadata(1, C.BUFFER_FLAG_KEY_FRAME, 2, 3, null)
    output.sampleMetadata(2, 0, 3, 0, null)

    assertArrayEquals(byteArrayOf(2, 3, 4, 5, 6), delegate.bytes.toByteArray())
    assertEquals(2, delegate.metadataCount)
    assertEquals(2, delegate.timeUs)
  }

  @Test
  fun droppedSamplePreservesTrailingSample() {
    val delegate = RecordingTrackOutput()
    val output = IncrementingTrackOutput(delegate)
    output.sampleData(ParsableByteArray(byteArrayOf(1, 2, 3)), 3, TrackOutput.SAMPLE_DATA_PART_MAIN)

    output.dropNext = true
    output.sampleMetadata(1, 0, 1, 2, null)
    output.sampleMetadata(2, 0, 2, 0, null)

    assertArrayEquals(byteArrayOf(3, 4), delegate.bytes.toByteArray())
    assertEquals(1, delegate.metadataCount)
  }

  @Test
  fun resetDiscardsPendingBytesWithoutReleasingCapacity() {
    val delegate = RecordingTrackOutput()
    val output = IncrementingTrackOutput(delegate, maxBufferedSampleBytes = 4)
    output.sampleData(ParsableByteArray(byteArrayOf(9, 9, 9, 9)), 4, TrackOutput.SAMPLE_DATA_PART_MAIN)

    output.resetBufferedData()
    output.sampleData(ParsableByteArray(byteArrayOf(1, 2, 3, 4)), 4, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(1, 0, 4, 0, null)

    assertArrayEquals(byteArrayOf(2, 3, 4, 5), delegate.bytes.toByteArray())
    assertEquals(1, delegate.metadataCount)
  }

  @Test
  fun invalidMetadataDropsBufferedBytesAndRecovers() {
    val delegate = RecordingTrackOutput()
    val output = IncrementingTrackOutput(delegate)
    output.sampleData(ParsableByteArray(byteArrayOf(1, 2)), 2, TrackOutput.SAMPLE_DATA_PART_MAIN)

    output.sampleMetadata(1, 0, 3, 0, null)
    output.sampleData(ParsableByteArray(byteArrayOf(4)), 1, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(2, 0, 1, 0, null)

    assertArrayEquals(byteArrayOf(5), delegate.bytes.toByteArray())
    assertEquals(1, delegate.metadataCount)
  }

  @Test
  fun activeTransformHonorsDataReaderEndOfInputContract() {
    val output = IncrementingTrackOutput(RecordingTrackOutput())
    val exhausted = DataReader { _, _, _ -> C.RESULT_END_OF_INPUT }

    assertThrows(EOFException::class.java) {
      output.sampleData(exhausted, 1, false, TrackOutput.SAMPLE_DATA_PART_MAIN)
    }
    assertEquals(
      C.RESULT_END_OF_INPUT,
      output.sampleData(exhausted, 1, true, TrackOutput.SAMPLE_DATA_PART_MAIN)
    )
  }

  @Test
  fun activeTransformRejectsParsableDataBeyondConfiguredBound() {
    val output = IncrementingTrackOutput(RecordingTrackOutput(), maxBufferedSampleBytes = 4)

    output.sampleData(ParsableByteArray(byteArrayOf(1, 2, 3)), 3, TrackOutput.SAMPLE_DATA_PART_MAIN)

    assertThrows(ParserException::class.java) {
      output.sampleData(ParsableByteArray(byteArrayOf(4, 5)), 2, TrackOutput.SAMPLE_DATA_PART_MAIN)
    }
  }

  @Test
  fun dataReaderRequestIsChunkedWithoutAllocatingTheDeclaredLength() {
    val requestedLengths = mutableListOf<Int>()
    val reader = DataReader { buffer, offset, length ->
      requestedLengths += length
      repeat(length) { buffer[offset + it] = it.toByte() }
      length
    }
    val output = IncrementingTrackOutput(RecordingTrackOutput(), maxBufferedSampleBytes = 4)

    assertEquals(2, output.sampleData(reader, Int.MAX_VALUE, false, TrackOutput.SAMPLE_DATA_PART_MAIN))
    assertEquals(listOf(2), requestedLengths)
  }

  private class IncrementingTrackOutput(
    delegate: TrackOutput,
    maxBufferedSampleBytes: Int = Int.MAX_VALUE
  ) : BufferedTransformingTrackOutput(
    delegate,
    initialBufferSize = 2,
    maxBufferedSampleBytes = maxBufferedSampleBytes
  ) {
    var dropNext = false
    private var transformed = ByteArray(2)

    override val transformEnabled = true
    override val transformedBuffer: ByteArray
      get() = transformed

    override fun transformSample(inputLength: Int, flags: Int): Int {
      if (dropNext) {
        dropNext = false
        return -1
      }
      if (transformed.size < inputLength) transformed = ByteArray(inputLength)
      for (index in 0 until inputLength) {
        transformed[index] = (inputBuffer[index] + 1).toByte()
      }
      return inputLength
    }
  }

  private class RecordingTrackOutput : TrackOutput {
    val bytes = ByteArrayOutputStream()
    var timeUs = C.TIME_UNSET
    var sampleSize = -1
    var sampleOffset = -1
    var metadataCount = 0

    override fun format(format: Format) = Unit

    override fun sampleData(
      input: DataReader,
      length: Int,
      allowEndOfInput: Boolean,
      sampleDataPart: Int
    ): Int {
      val buffer = ByteArray(length)
      val read = input.read(buffer, 0, length)
      if (read > 0) bytes.write(buffer, 0, read)
      return read
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
      val buffer = ByteArray(length)
      data.readBytes(buffer, 0, length)
      bytes.write(buffer)
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
      sampleSize = size
      sampleOffset = offset
    }
  }
}
