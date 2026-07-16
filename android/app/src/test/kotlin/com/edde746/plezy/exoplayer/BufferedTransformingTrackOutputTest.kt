package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput
import java.io.ByteArrayOutputStream
import java.io.EOFException
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class BufferedTransformingTrackOutputTest {

  @Test
  fun activeTransformBuffersChunksAndEmitsOneNormalizedSample() {
    val delegate = RecordingTrackOutput()
    val output = IncrementingTrackOutput(delegate)

    output.sampleData(ParsableByteArray(byteArrayOf(1, 2)), 2, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleData(ParsableByteArray(byteArrayOf(3)), 1, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(42, C.BUFFER_FLAG_KEY_FRAME, 3, 7, null)

    assertArrayEquals(byteArrayOf(2, 3, 4), delegate.bytes.toByteArray())
    assertEquals(42, delegate.timeUs)
    assertEquals(3, delegate.sampleSize)
    assertEquals(0, delegate.sampleOffset)
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

  private class IncrementingTrackOutput(delegate: TrackOutput) : BufferedTransformingTrackOutput(delegate, initialBufferSize = 2) {
    private var transformed = ByteArray(2)

    override val transformEnabled = true
    override val transformedBuffer: ByteArray
      get() = transformed

    override fun transformSample(inputLength: Int, flags: Int): Int {
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
      this.timeUs = timeUs
      sampleSize = size
      sampleOffset = offset
    }
  }
}
