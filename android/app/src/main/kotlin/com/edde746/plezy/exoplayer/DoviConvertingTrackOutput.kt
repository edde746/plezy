package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput
import java.io.ByteArrayOutputStream

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
        private val ANNEX_B_START_CODE = byteArrayOf(0, 0, 0, 1)
    }

    var conversionActive = false
        private set
    var strippedNalCount = 0L
        private set
    var convertedRpuCount = 0L
        private set

    // Sample buffering between sampleData() and sampleMetadata()
    private val sampleBuffer = ByteArrayOutputStream(256 * 1024)
    private var buffering = false

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

        // Buffer sample data for processing at sampleMetadata() time
        buffering = true
        val buf = ByteArray(length)
        val bytesRead = input.read(buf, 0, length)
        if (bytesRead > 0) {
            sampleBuffer.write(buf, 0, bytesRead)
        }
        return bytesRead
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
        if (!conversionActive) {
            delegate.sampleData(data, length, sampleDataPart)
            return
        }

        // Buffer sample data for processing at sampleMetadata() time
        buffering = true
        val bytes = ByteArray(length)
        data.readBytes(bytes, 0, length)
        sampleBuffer.write(bytes, 0, length)
    }

    override fun sampleMetadata(
        timeUs: Long, flags: Int, size: Int, offset: Int, cryptoData: TrackOutput.CryptoData?
    ) {
        if (!conversionActive || !buffering) {
            delegate.sampleMetadata(timeUs, flags, size, offset, cryptoData)
            return
        }

        buffering = false
        val rawSample = sampleBuffer.toByteArray()
        sampleBuffer.reset()

        val processed = try {
            processNalUnits(rawSample)
        } catch (e: Exception) {
            Log.e(TAG, "NAL processing failed, passing raw sample", e)
            rawSample
        }

        // Skip empty samples (all NALs were DV layers) — don't confuse the decoder
        if (processed.isEmpty()) return

        // Write processed data to delegate. Offset must be 0 since we write exactly
        // the processed amount (no trailing data from next sample in the buffer).
        val parsable = ParsableByteArray(processed, processed.size)
        delegate.sampleData(parsable, processed.size, TrackOutput.SAMPLE_DATA_PART_MAIN)
        delegate.sampleMetadata(timeUs, flags, processed.size, 0, cryptoData)
    }

    // Sample counter for periodic logging
    private var sampleCount = 0L

    /**
     * Process a single NAL: convert RPU (DV81), strip DV layers, or keep.
     * Returns processed NAL data to write, or null if stripped.
     */
    private fun processNal(nalData: ByteArray): ByteArray? {
        if (nalData.size < 2) return nalData
        val nalType = (nalData[0].toInt() ushr 1) and 0x3F
        val nuhLayerId = ((nalData[0].toInt() and 1) shl 5) or
            ((nalData[1].toInt() ushr 3) and 0x1F)
        return when {
            nalType == NAL_TYPE_UNSPEC62 && dvMode == DvConversionMode.DV81 -> {
                val converted = DoviBridge.convertRpuNalu(nalData, LIBDOVI_MODE_TO_81)
                if (converted != null) {
                    normalizeLayerId(converted)
                    convertedRpuCount++
                    converted
                } else {
                    strippedNalCount++
                    null
                }
            }
            nalType == NAL_TYPE_UNSPEC62 || nalType == NAL_TYPE_UNSPEC63 || nuhLayerId > 0 -> {
                strippedNalCount++
                null
            }
            else -> {
                normalizeLayerId(nalData)
                nalData
            }
        }
    }

    /**
     * Process NAL units in the sample data. Auto-detects format:
     * - Annex B (00 00 00 01 / 00 00 01 start codes) — used by MatroskaExtractor
     * - Length-prefixed (4-byte big-endian length) — used by Mp4Extractor
     */
    private fun processNalUnits(data: ByteArray): ByteArray {
        if (data.size < 4) return data

        // Auto-detect: Annex B starts with 00 00 00 01 or 00 00 01
        val isAnnexB = (data.size >= 4 && data[0] == 0.toByte() && data[1] == 0.toByte() &&
            data[2] == 0.toByte() && data[3] == 1.toByte()) ||
            (data.size >= 3 && data[0] == 0.toByte() && data[1] == 0.toByte() &&
                data[2] == 1.toByte())

        if (sampleCount == 0L) {
            Log.d(TAG, "NAL format detected: ${if (isAnnexB) "Annex B" else "length-prefixed"}, " +
                "first bytes: ${data.take(8).joinToString(" ") { "%02X".format(it) }}")
        }

        return if (isAnnexB) processAnnexBNals(data) else processLengthPrefixedNals(data)
    }

    /**
     * Find all Annex B start code positions (00 00 01 or 00 00 00 01) in the data.
     * Returns list of pairs: (startCodeEnd, startCodeLen) where startCodeEnd is the
     * byte index right after the start code, and startCodeLen is 3 or 4.
     */
    private fun findAnnexBStartCodes(data: ByteArray): List<Pair<Int, Int>> {
        val positions = mutableListOf<Pair<Int, Int>>()
        var i = 0
        while (i < data.size - 2) {
            if (data[i] == 0.toByte() && data[i + 1] == 0.toByte()) {
                if (i + 3 < data.size && data[i + 2] == 0.toByte() && data[i + 3] == 1.toByte()) {
                    positions.add(Pair(i + 4, 4))
                    i += 4
                    continue
                } else if (data[i + 2] == 1.toByte()) {
                    positions.add(Pair(i + 3, 3))
                    i += 3
                    continue
                }
            }
            i++
        }
        return positions
    }

    /** Process Annex B formatted NAL units (MKV path). */
    private fun processAnnexBNals(data: ByteArray): ByteArray {
        val output = ByteArrayOutputStream(data.size)
        var kept = 0
        var stripped = 0

        val startCodes = findAnnexBStartCodes(data)
        if (startCodes.isEmpty()) {
            sampleCount++
            return data
        }

        for (idx in startCodes.indices) {
            val nalStart = startCodes[idx].first
            val nalEnd = if (idx + 1 < startCodes.size) {
                startCodes[idx + 1].first - startCodes[idx + 1].second
            } else {
                data.size
            }
            if (nalEnd <= nalStart) continue

            val result = processNal(data.copyOfRange(nalStart, nalEnd))
            if (result != null) {
                output.write(ANNEX_B_START_CODE)
                output.write(result)
                kept++
            } else {
                stripped++
            }
        }

        sampleCount++
        if (sampleCount <= 3 || (sampleCount % 500 == 0L)) {
            Log.d(TAG, "Sample #$sampleCount (AnnexB): ${data.size}B -> ${output.size()}B, " +
                "kept=$kept stripped=$stripped NALs")
        }
        return output.toByteArray()
    }

    /** Process length-prefixed NAL units (MP4 path). */
    private fun processLengthPrefixedNals(data: ByteArray): ByteArray {
        val output = ByteArrayOutputStream(data.size)
        var pos = 0
        var kept = 0
        var stripped = 0

        while (pos + 4 <= data.size) {
            val nalLen = ((data[pos].toInt() and 0xFF) shl 24) or
                ((data[pos + 1].toInt() and 0xFF) shl 16) or
                ((data[pos + 2].toInt() and 0xFF) shl 8) or
                (data[pos + 3].toInt() and 0xFF)

            if (nalLen <= 0 || pos + 4 + nalLen > data.size) {
                if (sampleCount < 5) {
                    Log.w(TAG, "Bad NAL length $nalLen at pos $pos (data.size=${data.size})")
                }
                break
            }

            val result = processNal(data.copyOfRange(pos + 4, pos + 4 + nalLen))
            if (result != null) {
                writeLengthPrefixedNal(output, result)
                kept++
            } else {
                stripped++
            }

            pos += 4 + nalLen
        }

        sampleCount++
        if (sampleCount <= 3 || (sampleCount % 500 == 0L)) {
            Log.d(TAG, "Sample #$sampleCount (LenPrefix): ${data.size}B -> ${output.size()}B, " +
                "kept=$kept stripped=$stripped NALs")
        }
        return output.toByteArray()
    }

    private fun normalizeLayerId(nalData: ByteArray) {
        if (nalData.size >= 2) {
            nalData[0] = (nalData[0].toInt() and 0xFE).toByte() // Clear bit 0 of byte 0
            nalData[1] = (nalData[1].toInt() and 0x07).toByte() // Clear bits 7-3 of byte 1
        }
    }

    private fun writeLengthPrefixedNal(output: ByteArrayOutputStream, nalData: ByteArray) {
        val len = nalData.size
        output.write((len ushr 24) and 0xFF)
        output.write((len ushr 16) and 0xFF)
        output.write((len ushr 8) and 0xFF)
        output.write(len and 0xFF)
        output.write(nalData)
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
