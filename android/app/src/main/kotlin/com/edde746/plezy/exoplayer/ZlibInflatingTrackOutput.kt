package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.util.ParsableByteArray
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
    private val delegate: TrackOutput,
) : TrackOutput {

    companion object {
        private const val TAG = "ZlibTrackOutput"
        private const val INITIAL_BUFFER_SIZE = 256 * 1024
        private const val INFLATE_CHUNK = 64 * 1024
    }

    var active = false

    private val inflater = Inflater()

    // Reusable buffers — grown as needed, never shrunk
    private var compressedBuf = ByteArray(INITIAL_BUFFER_SIZE)
    private var compressedLen = 0
    private var inflateBuf = ByteArray(INITIAL_BUFFER_SIZE)
    private var readBuf = ByteArray(INFLATE_CHUNK)
    private val outputParsable = ParsableByteArray()
    private var buffering = false

    override fun format(format: Format) = delegate.format(format)

    override fun sampleData(
        input: DataReader, length: Int, allowEndOfInput: Boolean, sampleDataPart: Int
    ): Int {
        if (!active) return delegate.sampleData(input, length, allowEndOfInput, sampleDataPart)

        buffering = true
        if (readBuf.size < length) readBuf = ByteArray(length)
        val bytesRead = input.read(readBuf, 0, length)
        if (bytesRead > 0) appendCompressed(readBuf, 0, bytesRead)
        return bytesRead
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
        if (!active) {
            delegate.sampleData(data, length, sampleDataPart)
            return
        }

        buffering = true
        ensureCompressedCapacity(compressedLen + length)
        data.readBytes(compressedBuf, compressedLen, length)
        compressedLen += length
    }

    override fun sampleMetadata(
        timeUs: Long, flags: Int, size: Int, offset: Int, cryptoData: TrackOutput.CryptoData?
    ) {
        if (!active || !buffering) {
            delegate.sampleMetadata(timeUs, flags, size, offset, cryptoData)
            return
        }

        buffering = false
        val srcLen = compressedLen
        compressedLen = 0

        val inflatedLen = try {
            inflater.reset()
            inflater.setInput(compressedBuf, 0, srcLen)
            var written = 0
            while (!inflater.finished()) {
                if (written == inflateBuf.size) growInflateBuf()
                val count = inflater.inflate(inflateBuf, written, inflateBuf.size - written)
                if (count == 0 && !inflater.finished()) break
                written += count
            }
            written
        } catch (e: DataFormatException) {
            Log.e(TAG, "Zlib inflate failed (${srcLen}B), passing raw", e)
            // Fall back to raw compressed data
            ensureInflateCapacity(srcLen)
            System.arraycopy(compressedBuf, 0, inflateBuf, 0, srcLen)
            srcLen
        }

        outputParsable.reset(inflateBuf, inflatedLen)
        delegate.sampleData(outputParsable, inflatedLen, TrackOutput.SAMPLE_DATA_PART_MAIN)
        delegate.sampleMetadata(timeUs, flags, inflatedLen, 0, cryptoData)
    }

    private fun appendCompressed(src: ByteArray, offset: Int, length: Int) {
        ensureCompressedCapacity(compressedLen + length)
        System.arraycopy(src, offset, compressedBuf, compressedLen, length)
        compressedLen += length
    }

    private fun ensureCompressedCapacity(needed: Int) {
        if (compressedBuf.size < needed) {
            compressedBuf = compressedBuf.copyOf(maxOf(needed, compressedBuf.size * 2))
        }
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
