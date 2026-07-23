package com.edde746.plezy.exoplayer

import androidx.media3.common.ParserException
import androidx.media3.extractor.TrackOutput
import java.util.zip.DataFormatException
import java.util.zip.Inflater

/**
 * TrackOutput wrapper that inflates zlib-compressed sample data (MKV ContentCompAlgo 0).
 * Each MKV block is independently zlib-compressed; this wrapper decompresses per-sample
 * between sampleData() and sampleMetadata() calls.
 *
 * All buffers are reused across samples to minimize GC pressure on the hot path.
 */
class ZlibInflatingTrackOutput(
  delegate: TrackOutput
) : BufferedTransformingTrackOutput(
  delegate,
  INITIAL_BUFFER_SIZE,
  INFLATE_CHUNK,
  MAX_COMPRESSED_SAMPLE_SIZE
) {

  companion object {
    private const val INITIAL_BUFFER_SIZE = 256 * 1024
    private const val INFLATE_CHUNK = 64 * 1024
    private const val MAX_COMPRESSED_SAMPLE_SIZE = 16 * 1024 * 1024
    private const val MAX_INFLATED_SAMPLE_SIZE = 16 * 1024 * 1024
    private const val MAX_COMPRESSION_RATIO = 1024L
    private const val MIN_RATIO_ALLOWANCE = 1024L * 1024
  }

  var active = false

  private val inflater = Inflater()
  private var inflateBuf = ByteArray(INITIAL_BUFFER_SIZE)
  private val overflowProbe = ByteArray(1)

  override val transformEnabled: Boolean
    get() = active

  override val transformedBuffer: ByteArray
    get() = inflateBuf

  override fun transformSample(inputLength: Int, flags: Int): Int {
    inflater.reset()
    inflater.setInput(inputBuffer, 0, inputLength)
    var written = 0
    val ratioBound = maxOf(MIN_RATIO_ALLOWANCE, inputLength.toLong() * MAX_COMPRESSION_RATIO)

    try {
      while (true) {
        if (written == inflateBuf.size) {
          if (inflateBuf.size < MAX_INFLATED_SAMPLE_SIZE) {
            val nextSize = minOf(MAX_INFLATED_SAMPLE_SIZE, inflateBuf.size * 2)
            inflateBuf = inflateBuf.copyOf(nextSize)
          } else {
            val overflow = inflater.inflate(overflowProbe, 0, 1)
            if (overflow > 0) {
              throw malformed("Inflated sample exceeds the maximum size")
            }
            if (inflater.finished()) return written
            throw stalledInflate()
          }
        }

        val count = inflater.inflate(inflateBuf, written, inflateBuf.size - written)
        written += count
        if (written.toLong() > ratioBound) {
          throw malformed("Inflated sample exceeds the maximum compression ratio")
        }
        if (inflater.finished()) return written
        if (count == 0) throw stalledInflate()
      }
    } catch (_: DataFormatException) {
      // Preserve playback for corrupt subtitle blocks; the raw sample remains bounded
      // by MAX_COMPRESSED_SAMPLE_SIZE and matches the pre-hardening fallback.
      if (inflateBuf.size < inputLength) inflateBuf = inflateBuf.copyOf(inputLength)
      inputBuffer.copyInto(inflateBuf, endIndex = inputLength)
      return inputLength
    }
  }

  private fun stalledInflate(): ParserException = when {
    inflater.needsDictionary() -> malformed("Zlib-compressed sample requires a dictionary")
    inflater.needsInput() -> malformed("Truncated zlib-compressed sample")
    else -> malformed("Zlib decompressor made no progress")
  }

  private fun malformed(message: String, cause: Throwable? = null): ParserException = ParserException.createForMalformedContainer(message, cause)
}
