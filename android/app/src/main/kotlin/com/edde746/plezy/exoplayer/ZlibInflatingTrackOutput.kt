package com.edde746.plezy.exoplayer

import android.util.Log
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
) : BufferedTransformingTrackOutput(delegate, INITIAL_BUFFER_SIZE, INFLATE_CHUNK) {

  companion object {
    private const val TAG = "ZlibTrackOutput"
    private const val INITIAL_BUFFER_SIZE = 256 * 1024
    private const val INFLATE_CHUNK = 64 * 1024
  }

  var active = false

  private val inflater = Inflater()
  private var inflateBuf = ByteArray(INITIAL_BUFFER_SIZE)

  override val transformEnabled: Boolean
    get() = active

  override val transformedBuffer: ByteArray
    get() = inflateBuf

  override fun transformSample(inputLength: Int, flags: Int): Int = try {
    inflater.reset()
    inflater.setInput(inputBuffer, 0, inputLength)
    var written = 0
    while (!inflater.finished()) {
      if (written == inflateBuf.size) growInflateBuf()
      val count = inflater.inflate(inflateBuf, written, inflateBuf.size - written)
      if (count == 0 && !inflater.finished()) break
      written += count
    }
    written
  } catch (e: DataFormatException) {
    Log.e(TAG, "Zlib inflate failed (${inputLength}B), passing raw", e)
    ensureInflateCapacity(inputLength)
    System.arraycopy(inputBuffer, 0, inflateBuf, 0, inputLength)
    inputLength
  }

  private fun ensureInflateCapacity(needed: Int) {
    if (inflateBuf.size < needed) {
      inflateBuf = ByteArray(maxOf(needed, inflateBuf.size * 2))
    }
  }

  private fun growInflateBuf() {
    inflateBuf = inflateBuf.copyOf(inflateBuf.size * 2)
  }
}
