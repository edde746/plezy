package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput
import java.io.EOFException

/** Shared whole-sample buffering protocol for TrackOutput transforms. */
abstract class BufferedTransformingTrackOutput(
  protected val delegate: TrackOutput,
  initialBufferSize: Int,
  initialReadBufferSize: Int = initialBufferSize
) : TrackOutput {
  protected var inputBuffer = ByteArray(initialBufferSize)
    private set

  private var inputLength = 0
  private var buffering = false
  private var readBuffer = ByteArray(initialReadBufferSize)
  private val outputParsable = ParsableByteArray()

  protected abstract val transformEnabled: Boolean
  protected abstract val transformedBuffer: ByteArray

  /** Returns transformed length, or a negative value to drop the sample. */
  protected abstract fun transformSample(inputLength: Int, flags: Int): Int
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
    if (readBuffer.size < length) readBuffer = ByteArray(length)
    val bytesRead = input.read(readBuffer, 0, length)
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
    ensureInputCapacity(inputLength + length)
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

    buffering = false
    val sourceLength = inputLength
    inputLength = 0
    val transformedLength = transformSample(sourceLength, flags)
    if (transformedLength < 0) return

    outputParsable.reset(transformedBuffer, transformedLength)
    delegate.sampleData(outputParsable, transformedLength, TrackOutput.SAMPLE_DATA_PART_MAIN)
    delegate.sampleMetadata(timeUs, flags, transformedLength, 0, cryptoData)
  }

  private fun appendInput(source: ByteArray, length: Int) {
    ensureInputCapacity(inputLength + length)
    System.arraycopy(source, 0, inputBuffer, inputLength, length)
    inputLength += length
  }

  private fun ensureInputCapacity(needed: Int) {
    if (inputBuffer.size < needed) {
      inputBuffer = inputBuffer.copyOf(maxOf(needed, inputBuffer.size * 2))
    }
  }
}
