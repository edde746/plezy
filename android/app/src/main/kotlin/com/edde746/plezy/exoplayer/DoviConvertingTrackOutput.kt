package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput

/**
 * TrackOutput wrapper that processes DV Profile 7 HEVC samples based on conversion mode:
 *
 * - DV81: Convert RPU NALs via libdovi to Profile 8.1, present as video/dolby-vision
 *   with dvhe.08.XX codec string. Preserves dynamic tone mapping metadata.
 * - HEVC_STRIP: Strip all DV enhancement layers, present as plain video/hevc.
 *
 * Two modes of NAL framing (auto-detected):
 * - Annex B (MKV path): MatroskaExtractor outputs 00 00 00 01 start codes
 * - Length-prefixed (MP4 path): Mp4Extractor outputs 4-byte big-endian lengths
 *
 * NAL processing:
 * - Type 62 (UNSPEC62): DV RPU → convert (DV81) or strip (HEVC_STRIP)
 * - Type 63 (UNSPEC63): DV Enhancement Layer → strip
 * - nuh_layer_id > 0: Enhancement layer NAL → strip
 * - All retained NALs: normalize nuh_layer_id to 0
 *
 * All buffers are reused across samples to minimize GC pressure on the hot path.
 */
class DoviConvertingTrackOutput(
    private val delegate: TrackOutput,
    private val dvMode: DvConversionMode = DvConversionMode.HEVC_STRIP,
) : TrackOutput {

    companion object {
        private const val TAG = "DoviConvertTrack"
        private const val NAL_TYPE_UNSPEC62 = 62
        private const val NAL_TYPE_UNSPEC63 = 63
        private const val LIBDOVI_MODE_TO_81 = 2
        private const val INITIAL_BUFFER_SIZE = 256 * 1024
        private const val READ_CHUNK = 64 * 1024
        private val ANNEX_B_START_CODE = byteArrayOf(0, 0, 0, 1)
    }

    var conversionActive = false
        private set
    var strippedNalCount = 0L
        private set
    var convertedRpuCount = 0L
        private set

    // Reusable buffers — grown as needed, never shrunk
    private var sampleBuf = ByteArray(INITIAL_BUFFER_SIZE)
    private var sampleLen = 0
    private var outputBuf = ByteArray(INITIAL_BUFFER_SIZE)
    private var outputLen = 0
    private var readBuf = ByteArray(READ_CHUNK)
    private val outputParsable = ParsableByteArray()
    private var buffering = false

    // Sample counter for periodic logging
    private var sampleCount = 0L

    override fun format(format: Format) {
        if (!conversionActive) {
            val codecs = format.codecs
            if (codecs != null && codecs.startsWith("dvhe.07")) {
                conversionActive = true
                Log.i(TAG, "DV Profile 7 detected ($codecs), mode=$dvMode")
                Log.i(TAG, "Original format: mime=${format.sampleMimeType}, codecs=$codecs, " +
                    "initData=${format.initializationData.size} entries " +
                    "(${format.initializationData.mapIndexed { i, d -> "$i:${d.size}B" }.joinToString()})")

                val newFormat = when (dvMode) {
                    DvConversionMode.DV81 -> {
                        // Parse DV level from codec string: "dvhe.07.06" → 6
                        val level = codecs.split('.').getOrNull(2)?.toIntOrNull() ?: 6
                        val newCodecs = "dvhe.08.%02d".format(level)
                        val dvConfigRecord = buildDv81ConfigRecord(level)
                        Log.i(TAG, "DV81: rewriting to $newCodecs, config=${dvConfigRecord.size}B")

                        format.buildUpon()
                            .setSampleMimeType(MimeTypes.VIDEO_DOLBY_VISION)
                            .setCodecs(newCodecs)
                            .setInitializationData(
                                if (format.initializationData.isNotEmpty())
                                    listOf(format.initializationData[0], dvConfigRecord)
                                else
                                    listOf(ByteArray(0), dvConfigRecord)
                            )
                            .build()
                    }
                    else -> {
                        // HEVC_STRIP: present as plain HEVC
                        Log.i(TAG, "HEVC_STRIP: rewriting to video/hevc")
                        format.buildUpon()
                            .setSampleMimeType(MimeTypes.VIDEO_H265)
                            .setCodecs(null)
                            .setInitializationData(
                                if (format.initializationData.isNotEmpty())
                                    listOf(format.initializationData[0])
                                else
                                    emptyList()
                            )
                            .build()
                    }
                }

                Log.i(TAG, "Rewritten format: mime=${newFormat.sampleMimeType}, " +
                    "codecs=${newFormat.codecs}, initData=${newFormat.initializationData.size} entries")
                delegate.format(newFormat)
                return
            }
        }
        delegate.format(format)
    }

    override fun sampleData(
        input: DataReader, length: Int, allowEndOfInput: Boolean, sampleDataPart: Int
    ): Int {
        if (!conversionActive) {
            return delegate.sampleData(input, length, allowEndOfInput, sampleDataPart)
        }

        buffering = true
        if (readBuf.size < length) readBuf = ByteArray(length)
        val bytesRead = input.read(readBuf, 0, length)
        if (bytesRead > 0) {
            ensureSampleCapacity(sampleLen + bytesRead)
            System.arraycopy(readBuf, 0, sampleBuf, sampleLen, bytesRead)
            sampleLen += bytesRead
        }
        return bytesRead
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
        if (!conversionActive) {
            delegate.sampleData(data, length, sampleDataPart)
            return
        }

        buffering = true
        ensureSampleCapacity(sampleLen + length)
        data.readBytes(sampleBuf, sampleLen, length)
        sampleLen += length
    }

    override fun sampleMetadata(
        timeUs: Long, flags: Int, size: Int, offset: Int, cryptoData: TrackOutput.CryptoData?
    ) {
        if (!conversionActive || !buffering) {
            delegate.sampleMetadata(timeUs, flags, size, offset, cryptoData)
            return
        }

        buffering = false
        val srcLen = sampleLen
        sampleLen = 0

        val outLen: Int
        val outBuf: ByteArray
        val success = try {
            processNalUnits(srcLen)
            true
        } catch (e: Exception) {
            Log.e(TAG, "NAL processing failed, passing raw sample", e)
            false
        }
        if (success) {
            outLen = outputLen
            outBuf = outputBuf
        } else {
            outLen = srcLen
            outBuf = sampleBuf
        }

        // Skip empty samples (all NALs were DV layers) — don't confuse the decoder
        if (outLen == 0) return

        outputParsable.reset(outBuf, outLen)
        delegate.sampleData(outputParsable, outLen, TrackOutput.SAMPLE_DATA_PART_MAIN)
        delegate.sampleMetadata(timeUs, flags, outLen, 0, cryptoData)
    }

    /**
     * Process NAL units in sampleBuf[0..dataLen). Auto-detects format:
     * - Annex B (00 00 00 01 / 00 00 01 start codes) — used by MatroskaExtractor
     * - Length-prefixed (4-byte big-endian length) — used by Mp4Extractor
     *
     * Result is written to outputBuf[0..outputLen).
     */
    private fun processNalUnits(dataLen: Int) {
        outputLen = 0
        if (dataLen < 4) {
            ensureOutputCapacity(dataLen)
            System.arraycopy(sampleBuf, 0, outputBuf, 0, dataLen)
            outputLen = dataLen
            return
        }

        // Auto-detect: Annex B starts with 00 00 00 01 or 00 00 01
        val isAnnexB = (dataLen >= 4 && sampleBuf[0] == 0.toByte() && sampleBuf[1] == 0.toByte() &&
            sampleBuf[2] == 0.toByte() && sampleBuf[3] == 1.toByte()) ||
            (dataLen >= 3 && sampleBuf[0] == 0.toByte() && sampleBuf[1] == 0.toByte() &&
                sampleBuf[2] == 1.toByte())

        if (sampleCount == 0L) {
            Log.d(TAG, "NAL format detected: ${if (isAnnexB) "Annex B" else "length-prefixed"}, " +
                "first bytes: ${sampleBuf.take(8).joinToString(" ") { "%02X".format(it) }}")
        }

        if (isAnnexB) processAnnexBNals(dataLen) else processLengthPrefixedNals(dataLen)
    }

    /** Process Annex B formatted NAL units (MKV path). Scans inline, no list allocation. */
    private fun processAnnexBNals(dataLen: Int) {
        ensureOutputCapacity(dataLen)
        var kept = 0
        var stripped = 0

        // Find first start code
        var scEnd = -1
        var i = 0
        while (i < dataLen - 2) {
            if (sampleBuf[i] == 0.toByte() && sampleBuf[i + 1] == 0.toByte()) {
                if (i + 3 < dataLen && sampleBuf[i + 2] == 0.toByte() && sampleBuf[i + 3] == 1.toByte()) {
                    scEnd = i + 4
                    break
                } else if (sampleBuf[i + 2] == 1.toByte()) {
                    scEnd = i + 3
                    break
                }
            }
            i++
        }

        if (scEnd < 0) {
            // No start codes found — pass through
            System.arraycopy(sampleBuf, 0, outputBuf, 0, dataLen)
            outputLen = dataLen
            sampleCount++
            return
        }

        var nalStart = scEnd

        while (nalStart < dataLen) {
            // Find next start code to determine end of current NAL
            var nalEnd = dataLen
            i = nalStart
            while (i < dataLen - 2) {
                if (sampleBuf[i] == 0.toByte() && sampleBuf[i + 1] == 0.toByte()) {
                    if (i + 3 < dataLen && sampleBuf[i + 2] == 0.toByte() && sampleBuf[i + 3] == 1.toByte()) {
                        nalEnd = i
                        break
                    } else if (sampleBuf[i + 2] == 1.toByte()) {
                        nalEnd = i
                        break
                    }
                }
                i++
            }

            val nalLen = nalEnd - nalStart
            if (nalLen > 0) {
                val action = processNalInline(nalStart, nalLen)
                if (action == NalAction.KEEP) {
                    ensureOutputCapacity(outputLen + 4 + nalLen)
                    System.arraycopy(ANNEX_B_START_CODE, 0, outputBuf, outputLen, 4)
                    outputLen += 4
                    System.arraycopy(sampleBuf, nalStart, outputBuf, outputLen, nalLen)
                    normalizeLayerId(outputBuf, outputLen)
                    outputLen += nalLen
                    kept++
                } else if (action == NalAction.CONVERT) {
                    val converted = DoviBridge.convertRpuNalu(
                        sampleBuf.copyOfRange(nalStart, nalStart + nalLen), LIBDOVI_MODE_TO_81
                    )
                    if (converted != null) {
                        normalizeLayerId(converted, 0)
                        ensureOutputCapacity(outputLen + 4 + converted.size)
                        System.arraycopy(ANNEX_B_START_CODE, 0, outputBuf, outputLen, 4)
                        outputLen += 4
                        System.arraycopy(converted, 0, outputBuf, outputLen, converted.size)
                        outputLen += converted.size
                        convertedRpuCount++
                        kept++
                    } else {
                        strippedNalCount++
                        stripped++
                    }
                } else {
                    strippedNalCount++
                    stripped++
                }
            }

            // Advance past the next start code
            if (nalEnd >= dataLen) break
            nalStart = if (nalEnd + 3 < dataLen && sampleBuf[nalEnd + 2] == 0.toByte() && sampleBuf[nalEnd + 3] == 1.toByte()) {
                nalEnd + 4
            } else {
                nalEnd + 3
            }
        }

        sampleCount++
        if (sampleCount <= 3 || (sampleCount % 500 == 0L)) {
            Log.d(TAG, "Sample #$sampleCount (AnnexB): ${dataLen}B -> ${outputLen}B, " +
                "kept=$kept stripped=$stripped NALs")
        }
    }

    /** Process length-prefixed NAL units (MP4 path). */
    private fun processLengthPrefixedNals(dataLen: Int) {
        ensureOutputCapacity(dataLen)
        var pos = 0
        var kept = 0
        var stripped = 0

        while (pos + 4 <= dataLen) {
            val nalLen = ((sampleBuf[pos].toInt() and 0xFF) shl 24) or
                ((sampleBuf[pos + 1].toInt() and 0xFF) shl 16) or
                ((sampleBuf[pos + 2].toInt() and 0xFF) shl 8) or
                (sampleBuf[pos + 3].toInt() and 0xFF)

            if (nalLen <= 0 || pos + 4 + nalLen > dataLen) {
                if (sampleCount < 5) {
                    Log.w(TAG, "Bad NAL length $nalLen at pos $pos (data.size=$dataLen)")
                }
                break
            }

            val nalStart = pos + 4
            val action = processNalInline(nalStart, nalLen)
            if (action == NalAction.KEEP) {
                ensureOutputCapacity(outputLen + 4 + nalLen)
                writeInt32BE(outputBuf, outputLen, nalLen)
                outputLen += 4
                System.arraycopy(sampleBuf, nalStart, outputBuf, outputLen, nalLen)
                normalizeLayerId(outputBuf, outputLen)
                outputLen += nalLen
                kept++
            } else if (action == NalAction.CONVERT) {
                val converted = DoviBridge.convertRpuNalu(
                    sampleBuf.copyOfRange(nalStart, nalStart + nalLen), LIBDOVI_MODE_TO_81
                )
                if (converted != null) {
                    normalizeLayerId(converted, 0)
                    ensureOutputCapacity(outputLen + 4 + converted.size)
                    writeInt32BE(outputBuf, outputLen, converted.size)
                    outputLen += 4
                    System.arraycopy(converted, 0, outputBuf, outputLen, converted.size)
                    outputLen += converted.size
                    convertedRpuCount++
                    kept++
                } else {
                    strippedNalCount++
                    stripped++
                }
            } else {
                strippedNalCount++
                stripped++
            }

            pos += 4 + nalLen
        }

        sampleCount++
        if (sampleCount <= 3 || (sampleCount % 500 == 0L)) {
            Log.d(TAG, "Sample #$sampleCount (LenPrefix): ${dataLen}B -> ${outputLen}B, " +
                "kept=$kept stripped=$stripped NALs")
        }
    }

    private enum class NalAction { KEEP, STRIP, CONVERT }

    /** Classify a NAL at sampleBuf[offset..offset+len) without copying. */
    private fun processNalInline(offset: Int, len: Int): NalAction {
        if (len < 2) return NalAction.KEEP
        val nalType = (sampleBuf[offset].toInt() ushr 1) and 0x3F
        val nuhLayerId = ((sampleBuf[offset].toInt() and 1) shl 5) or
            ((sampleBuf[offset + 1].toInt() ushr 3) and 0x1F)
        return when {
            nalType == NAL_TYPE_UNSPEC62 && dvMode == DvConversionMode.DV81 -> NalAction.CONVERT
            nalType == NAL_TYPE_UNSPEC62 || nalType == NAL_TYPE_UNSPEC63 || nuhLayerId > 0 -> NalAction.STRIP
            else -> NalAction.KEEP
        }
    }

    private fun normalizeLayerId(data: ByteArray, offset: Int) {
        if (data.size - offset >= 2) {
            data[offset] = (data[offset].toInt() and 0xFE).toByte()
            data[offset + 1] = (data[offset + 1].toInt() and 0x07).toByte()
        }
    }

    private fun writeInt32BE(buf: ByteArray, offset: Int, value: Int) {
        buf[offset] = ((value ushr 24) and 0xFF).toByte()
        buf[offset + 1] = ((value ushr 16) and 0xFF).toByte()
        buf[offset + 2] = ((value ushr 8) and 0xFF).toByte()
        buf[offset + 3] = (value and 0xFF).toByte()
    }

    private fun ensureSampleCapacity(needed: Int) {
        if (sampleBuf.size < needed) {
            sampleBuf = sampleBuf.copyOf(maxOf(needed, sampleBuf.size * 2))
        }
    }

    private fun ensureOutputCapacity(needed: Int) {
        if (outputBuf.size < needed) {
            outputBuf = outputBuf.copyOf(maxOf(needed, outputBuf.size * 2))
        }
    }

    /**
     * Build a 24-byte DOVIDecoderConfigurationRecord for DV Profile 8.1.
     *
     * Binary layout (from Dolby Vision spec):
     * byte[0]:    dv_version_major = 1
     * byte[1]:    dv_version_minor = 0
     * byte[2]:    dv_profile (7 bits) | dv_level MSB (1 bit)
     * byte[3]:    dv_level low 5 bits (5 bits) | rpu_present (1) | el_present (1) | bl_present (1)
     * byte[4]:    bl_compatibility_id (4 bits) | md_compression (2 bits) | reserved (2 bits)
     * byte[5-23]: reserved (zeros)
     */
    private fun buildDv81ConfigRecord(level: Int): ByteArray {
        val record = ByteArray(24)
        record[0] = 0x01                                                    // dv_version_major = 1
        record[1] = 0x00                                                    // dv_version_minor = 0
        record[2] = ((8 shl 1) or ((level ushr 5) and 0x01)).toByte()       // profile=8 | level MSB
        record[3] = (((level and 0x1F) shl 3) or 0x05).toByte()             // level low 5 | rpu=1 el=0 bl=1
        record[4] = (1 shl 4).toByte()                                      // bl_compatibility_id=1 (HDR10)
        // bytes 5-23 remain 0 (reserved)
        return record
    }
}
