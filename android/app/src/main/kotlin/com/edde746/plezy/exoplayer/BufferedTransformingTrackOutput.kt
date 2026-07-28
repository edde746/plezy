package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.ParserException
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput
import java.io.EOFException

/**
 * Buffers transformed [TrackOutput] data until metadata identifies the exact sample range.
 *
 * Media3 may append multiple samples before reporting metadata, and [TrackOutput.sampleMetadata]
 * identifies a sample relative to all appended bytes using `size` and `offset`. Before calling
 * [transformSample], this class compacts only that sample to `inputBuffer[0 until inputLength]`.
 * Bytes after the sample remain buffered for later metadata; unreferenced bytes before it are
 * discarded. Extractor decorators must call [resetBufferedData] when a seek abandons pending data.
 */
abstract class BufferedTransformingTrackOutput(
  protected val delegate: TrackOutput,
  initialBufferSize: Int,
  initialReadBufferSize: Int = initialBufferSize,
  private val maxBufferedSampleBytes: Int = Int.MAX_VALUE
) : TrackOutput {
  protected var inputBuffer = ByteArray(initialBufferSize)
    private set

  private var inputLength = 0
  private var buffering = false
  private var readBuffer = ByteArray(initialReadBufferSize)
  private val outputParsable = ParsableByteArray()

  protected abstract val transformEnabled: Boolean
  protected abstract val transformedBuffer: ByteArray

  /**
   * Transforms the exact sample in `inputBuffer[0 until inputLength]`.
   *
   * Implementations must treat [inputBuffer] as read-only. Returns the number of bytes available
   * from [transformedBuffer], or a negative value to drop the sample.
   */
  protected abstract fun transformSample(inputLength: Int, flags: Int): Int

  init {
    require(initialBufferSize > 0)
    require(initialReadBufferSize > 0)
    require(maxBufferedSampleBytes >= initialBufferSize)
  }
  open override fun format(format: Format) = delegate.format(format)

  override fun sampleData(
    input: DataReader,
    length: Int,
    allowEndOfInput: Boolean,
    sampleDataPart: Int
  ): Int {
    if (!transformEnabled) {
      return delegate.sampleData(input, length, allowEndOfInput, sampleDataPart)
    }

    buffering = true
    val remainingCapacity = maxBufferedSampleBytes - inputLength
    if (length < 0 || remainingCapacity <= 0) throw sampleTooLarge()
    val requested = minOf(length, remainingCapacity, readBuffer.size)
    val bytesRead = input.read(readBuffer, 0, requested)
    if (bytesRead == C.RESULT_END_OF_INPUT && !allowEndOfInput) throw EOFException()
    if (bytesRead > 0) appendInput(readBuffer, bytesRead)
    return bytesRead
  }

  override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
    if (!transformEnabled) {
      delegate.sampleData(data, length, sampleDataPart)
      return
    }

    buffering = true
    ensureInputCapacity(length)
    data.readBytes(inputBuffer, inputLength, length)
    inputLength += length
  }

  override fun sampleMetadata(
    timeUs: Long,
    flags: Int,
    size: Int,
    offset: Int,
    cryptoData: TrackOutput.CryptoData?
  ) {
    if (!transformEnabled || !buffering) {
      delegate.sampleMetadata(timeUs, flags, size, offset, cryptoData)
      return
    }

    // Offset can describe data for one or more later samples already appended by the extractor.
    if (size < 0 || offset < 0 || size > inputLength - offset) {
      resetBufferedData()
      return
    }

    val sampleEnd = inputLength - offset
    val sampleStart = sampleEnd - size
    if (sampleStart > 0) {
      System.arraycopy(inputBuffer, sampleStart, inputBuffer, 0, size)
    }

    try {
      val transformedLength = transformSample(size, flags)
      if (transformedLength < 0) return

      outputParsable.reset(transformedBuffer, transformedLength)
      delegate.sampleData(outputParsable, transformedLength, TrackOutput.SAMPLE_DATA_PART_MAIN)
      delegate.sampleMetadata(timeUs, flags, transformedLength, 0, cryptoData)
    } finally {
      if (offset > 0) {
        System.arraycopy(inputBuffer, sampleEnd, inputBuffer, 0, offset)
      }
      inputLength = offset
      buffering = offset > 0
    }
  }

  /** Drops sample bytes buffered before an extractor seek while retaining allocated storage. */
  internal fun resetBufferedData() {
    inputLength = 0
    buffering = false
  }

  private fun appendInput(source: ByteArray, length: Int) {
    ensureInputCapacity(length)
    System.arraycopy(source, 0, inputBuffer, inputLength, length)
    inputLength += length
  }

  private fun ensureInputCapacity(additionalBytes: Int) {
    if (additionalBytes < 0 || additionalBytes > maxBufferedSampleBytes - inputLength) {
      throw sampleTooLarge()
    }
    val needed = inputLength + additionalBytes
    if (inputBuffer.size < needed) {
      val doubledSize = minOf(maxBufferedSampleBytes.toLong(), inputBuffer.size.toLong() * 2).toInt()
      inputBuffer = inputBuffer.copyOf(maxOf(needed, doubledSize))
    }
  }

  private fun sampleTooLarge(): ParserException = ParserException.createForMalformedContainer(
    "Buffered sample exceeds the maximum size of $maxBufferedSampleBytes bytes",
    null
  )
}
