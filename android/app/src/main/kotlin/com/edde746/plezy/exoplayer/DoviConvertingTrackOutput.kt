package com.edde746.plezy.exoplayer

import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.extractor.TrackOutput

/**
 * TrackOutput wrapper that processes DV Profile 7 HEVC samples based on conversion mode:
 *
 * - DV81: Convert RPU NALs via libdovi mode 2 to Profile 8.1, present as
 *   video/dolby-vision with dvhe.08.XX codec string. Conversion failures drop
 *   that RPU instead of forwarding Profile 7 metadata into a Profile 8.1 stream.
 * - HEVC_STRIP: Strip DV RPU/EL NALs, present as plain video/hevc.
 *
 * Two modes of NAL framing (auto-detected):
 * - Annex B (MKV path): MatroskaExtractor outputs 00 00 00 01 start codes
 * - Length-prefixed (MP4 path): Mp4Extractor outputs 4-byte big-endian lengths
 *
 * NAL processing:
 * - Type 62 (UNSPEC62): DV RPU → convert (DV81) or strip (HEVC_STRIP)
 * - Type 63 (UNSPEC63): DV Enhancement Layer → strip
 * - All other NALs: pass through unchanged, matching Kodi's compatibility path
 *
 * All buffers are reused across samples to minimize GC pressure on the hot path.
 */
class DoviConvertingTrackOutput(
  delegate: TrackOutput,
  private val dvMode: DvConversionMode = DvConversionMode.HEVC_STRIP,
  private val emitLog: ((String, String, String) -> Unit)? = null
) : BufferedTransformingTrackOutput(delegate, INITIAL_BUFFER_SIZE) {

  companion object {
    private const val TAG = "DoviConvertTrack"
    private const val NAL_TYPE_UNSPEC62 = 62
    private const val NAL_TYPE_UNSPEC63 = 63
    private const val LIBDOVI_MODE_TO_81 = 2
    private const val INITIAL_BUFFER_SIZE = 256 * 1024
    private const val MAX_CONVERTED_RPU_SIZE = 16 * 1024
    private val ANNEX_B_START_CODE = byteArrayOf(0, 0, 0, 1)
  }

  var conversionActive = false
    private set
  var strippedNalCount = 0L
    private set
  var strippedRpuNalCount = 0L
    private set
  var strippedElNalCount = 0L
    private set
  var strippedInitNalCount = 0L
    private set
  var convertedRpuCount = 0L
    private set
  var rpuConversionFailureCount = 0L
    private set
  var rpuOutputTooSmallCount = 0L
    private set
  val averageRpuConversionTimeUs: Long
    get() = if (rpuConversionCallCount > 0) totalRpuConversionTimeUs / rpuConversionCallCount else 0L
  val averageSampleProcessingTimeUs: Long
    get() = if (sampleCount > 0) totalSampleProcessingTimeUs / sampleCount else 0L

  // Reusable buffers — grown as needed, never shrunk
  private var outputBuf = ByteArray(INITIAL_BUFFER_SIZE)
  private var outputLen = 0

  // Sample counter for periodic logging
  private var sampleCount = 0L
  private var rpuConversionCallCount = 0L
  private var totalRpuConversionTimeUs = 0L
  private var totalSampleProcessingTimeUs = 0L
  private var loggedSupplementalWrapper = false
  private var loggedEncryptedSupplementalPassthrough = false
  private var outputIsProcessed = false

  override fun format(format: Format) {
    if (!conversionActive) {
      val codecs = format.codecs
      if (isDvProfile7Codec(codecs)) {
        val codecString = codecs ?: ""
        conversionActive = true
        logInfo("DV Profile 7 detected ($codecString), mode=$dvMode")
        when (dvMode) {
          DvConversionMode.DV81 -> logInfo("DV81: Kodi-style libdovi conversion (convert RPU type 62, drop EL type 63)")
          DvConversionMode.HEVC_STRIP -> logInfo("HEVC_STRIP: Kodi-compatible strip (drop RPU type 62 and EL type 63 only)")
          else -> Unit
        }
        logInfo(
          "Original format: mime=${format.sampleMimeType}, codecs=$codecString, " +
            "initData=${format.initializationData.size} entries " +
            "(${format.initializationData.mapIndexed { i, d -> "$i:${d.size}B" }.joinToString()})"
        )
        val strippedInitializationData = stripInitializationData(format.initializationData)

        val newFormat = when (dvMode) {
          DvConversionMode.DV81 -> {
            // Parse DV level from codec string: "dvhe.07.06" → 6
            val level = codecString.split('.').getOrNull(2)?.toIntOrNull() ?: 6
            val newCodecs = "dvhe.08.%02d".format(level)
            val dvConfigRecord = buildDv81ConfigRecord(level)
            logInfo("DV81: rewriting to $newCodecs, config=${dvConfigRecord.size}B")

            format.buildUpon()
              .setSampleMimeType(MimeTypes.VIDEO_DOLBY_VISION)
              .setCodecs(newCodecs)
              .setInitializationData(strippedInitializationData + dvConfigRecord)
              .build()
          }
          else -> {
            // HEVC_STRIP: present as plain HEVC
            logInfo("HEVC_STRIP: rewriting to video/hevc")
            format.buildUpon()
              .setSampleMimeType(MimeTypes.VIDEO_H265)
              .setCodecs(null)
              .setInitializationData(strippedInitializationData)
              .build()
          }
        }

        logInfo(
          "Rewritten format: mime=${newFormat.sampleMimeType}, " +
            "codecs=${newFormat.codecs}, initData=${newFormat.initializationData.size} entries"
        )
        delegate.format(newFormat)
        return
      }
    }
    delegate.format(format)
  }

  override val transformEnabled: Boolean
    get() = conversionActive

  override val transformedBuffer: ByteArray
    get() = if (outputIsProcessed) outputBuf else inputBuffer

  override fun transformSample(inputLength: Int, flags: Int): Int {
    val processStartNs = System.nanoTime()
    outputIsProcessed = if ((flags and C.BUFFER_FLAG_ENCRYPTED) != 0) {
      if (!loggedEncryptedSupplementalPassthrough && (flags and C.BUFFER_FLAG_HAS_SUPPLEMENTAL_DATA) != 0) {
        loggedEncryptedSupplementalPassthrough = true
        logWarn("Encrypted supplemental sample encountered, passing raw sample")
      }
      false
    } else {
      try {
        processSampleData(flags, inputLength)
        true
      } catch (e: Exception) {
        logError("NAL processing failed, passing raw sample", e)
        false
      }
    }
    val transformedLength = if (outputIsProcessed) outputLen else inputLength
    if (outputIsProcessed) {
      recordSampleProcessing((System.nanoTime() - processStartNs) / 1_000L)
    }

    // Skip empty samples (all NALs were DV layers) — don't confuse the decoder.
    return if (transformedLength == 0) -1 else transformedLength
  }

  /**
   * Process a sample, unwrapping Media3 supplemental-data framing when present.
   *
   * Samples with C.BUFFER_FLAG_HAS_SUPPLEMENTAL_DATA are stored as:
   * [4-byte big-endian main sample size][main sample][supplemental data].
   * Only the main sample contains video NALs and should be rewritten.
   */
  private fun processSampleData(flags: Int, dataLen: Int) {
    if ((flags and C.BUFFER_FLAG_HAS_SUPPLEMENTAL_DATA) == 0) {
      processNalUnits(0, dataLen)
      return
    }

    if (dataLen < 4) {
      logWarn("Bad supplemental sample: ${dataLen}B is too small")
      copyRawSample(dataLen)
      return
    }

    val mainSampleLen = readInt32BE(inputBuffer, 0)
    if (mainSampleLen < 0 || mainSampleLen > dataLen - 4) {
      logWarn("Bad supplemental sample: mainLen=$mainSampleLen total=$dataLen")
      copyRawSample(dataLen)
      return
    }

    val supplementalLen = dataLen - 4 - mainSampleLen
    if (!loggedSupplementalWrapper) {
      loggedSupplementalWrapper = true
      logDebug(
        "Supplemental wrapper detected: total=${dataLen}B, main=${mainSampleLen}B, " +
          "supplemental=${supplementalLen}B, innerFirstBytes=${formatBytes(inputBuffer, 4, 8)}"
      )
    }

    processNalUnits(4, mainSampleLen)

    val processedMainLen = outputLen
    if (processedMainLen == 0) {
      outputLen = 0
      return
    }

    ensureOutputCapacity(4 + processedMainLen + supplementalLen)
    System.arraycopy(outputBuf, 0, outputBuf, 4, processedMainLen)
    writeInt32BE(outputBuf, 0, processedMainLen)
    if (supplementalLen > 0) {
      System.arraycopy(inputBuffer, 4 + mainSampleLen, outputBuf, 4 + processedMainLen, supplementalLen)
    }
    outputLen = 4 + processedMainLen + supplementalLen

    if (sampleCount <= 3 || (sampleCount % 500 == 0L)) {
      logDebug(
        "Sample #$sampleCount (Supplemental): main=${mainSampleLen}B -> ${processedMainLen}B, " +
          "supplemental=${supplementalLen}B, total=${dataLen}B -> ${outputLen}B"
      )
    }
  }

  /**
   * Process NAL units in sampleBuf[dataOffset..dataOffset+dataLen). Auto-detects format:
   * - Annex B (00 00 00 01 / 00 00 01 start codes) — used by MatroskaExtractor
   * - Length-prefixed (4-byte big-endian length) — used by Mp4Extractor
   *
   * Result is written to outputBuf[0..outputLen).
   */
  private fun processNalUnits(dataOffset: Int, dataLen: Int) {
    outputLen = 0
    if (dataLen < 4) {
      ensureOutputCapacity(dataLen)
      System.arraycopy(inputBuffer, dataOffset, outputBuf, 0, dataLen)
      outputLen = dataLen
      return
    }

    // Auto-detect: Annex B starts with 00 00 00 01 or 00 00 01
    val isAnnexB = (
      dataLen >= 4 &&
        inputBuffer[dataOffset] == 0.toByte() &&
        inputBuffer[dataOffset + 1] == 0.toByte() &&
        inputBuffer[dataOffset + 2] == 0.toByte() &&
        inputBuffer[dataOffset + 3] == 1.toByte()
      ) ||
      (
        dataLen >= 3 &&
          inputBuffer[dataOffset] == 0.toByte() &&
          inputBuffer[dataOffset + 1] == 0.toByte() &&
          inputBuffer[dataOffset + 2] == 1.toByte()
        )

    if (sampleCount == 0L) {
      logDebug(
        "NAL format detected: ${if (isAnnexB) "Annex B" else "length-prefixed"}, " +
          "first bytes: ${formatBytes(inputBuffer, dataOffset, 8)}"
      )
    }

    if (isAnnexB) processAnnexBNals(dataOffset, dataLen) else processLengthPrefixedNals(dataOffset, dataLen)
  }

  /** Process Annex B formatted NAL units (MKV path). Scans inline, no list allocation. */
  private fun processAnnexBNals(dataOffset: Int, dataLen: Int) {
    ensureOutputCapacity(dataLen)
    val dataEnd = dataOffset + dataLen
    var kept = 0
    var stripped = 0

    // Find first start code
    var scEnd = -1
    var i = dataOffset
    while (i < dataEnd - 2) {
      if (inputBuffer[i] == 0.toByte() && inputBuffer[i + 1] == 0.toByte()) {
        if (i + 3 < dataEnd && inputBuffer[i + 2] == 0.toByte() && inputBuffer[i + 3] == 1.toByte()) {
          scEnd = i + 4
          break
        } else if (inputBuffer[i + 2] == 1.toByte()) {
          scEnd = i + 3
          break
        }
      }
      i++
    }

    if (scEnd < 0) {
      // No start codes found — pass through
      System.arraycopy(inputBuffer, dataOffset, outputBuf, 0, dataLen)
      outputLen = dataLen
      sampleCount++
      return
    }

    var nalStart = scEnd

    while (nalStart < dataEnd) {
      // Find next start code to determine end of current NAL
      var nalEnd = dataEnd
      i = nalStart
      while (i < dataEnd - 2) {
        if (inputBuffer[i] == 0.toByte() && inputBuffer[i + 1] == 0.toByte()) {
          if (i + 3 < dataEnd && inputBuffer[i + 2] == 0.toByte() && inputBuffer[i + 3] == 1.toByte()) {
            nalEnd = i
            break
          } else if (inputBuffer[i + 2] == 1.toByte()) {
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
          System.arraycopy(inputBuffer, nalStart, outputBuf, outputLen, nalLen)
          outputLen += nalLen
          kept++
        } else if (action == NalAction.CONVERT) {
          val convertedLen = convertRpuIntoOutput(nalStart, nalLen, outputLen + 4)
          if (convertedLen >= 0) {
            System.arraycopy(ANNEX_B_START_CODE, 0, outputBuf, outputLen, 4)
            outputLen += 4
            outputLen += convertedLen
            convertedRpuCount++
            kept++
          } else {
            recordStrippedNal(action)
            stripped++
          }
        } else {
          recordStrippedNal(action)
          stripped++
        }
      }

      // Advance past the next start code
      if (nalEnd >= dataEnd) break
      nalStart = if (nalEnd + 3 < dataEnd && inputBuffer[nalEnd + 2] == 0.toByte() && inputBuffer[nalEnd + 3] == 1.toByte()) {
        nalEnd + 4
      } else {
        nalEnd + 3
      }
    }

    sampleCount++
    if (sampleCount <= 3 || (sampleCount % 500 == 0L)) {
      logDebug(
        "Sample #$sampleCount (AnnexB): ${dataLen}B -> ${outputLen}B, " +
          "kept=$kept stripped=$stripped NALs"
      )
    }
  }

  /** Process length-prefixed NAL units (MP4 path). */
  private fun processLengthPrefixedNals(dataOffset: Int, dataLen: Int) {
    ensureOutputCapacity(dataLen)
    val dataEnd = dataOffset + dataLen
    var pos = dataOffset
    var kept = 0
    var stripped = 0

    while (pos + 4 <= dataEnd) {
      val nalLen = ((inputBuffer[pos].toInt() and 0xFF) shl 24) or
        ((inputBuffer[pos + 1].toInt() and 0xFF) shl 16) or
        ((inputBuffer[pos + 2].toInt() and 0xFF) shl 8) or
        (inputBuffer[pos + 3].toInt() and 0xFF)

      if (nalLen <= 0 || pos + 4 + nalLen > dataEnd) {
        if (sampleCount < 5) {
          logWarn("Bad NAL length $nalLen at pos ${pos - dataOffset} (data.size=$dataLen)")
        }
        break
      }

      val nalStart = pos + 4
      val action = processNalInline(nalStart, nalLen)
      if (action == NalAction.KEEP) {
        ensureOutputCapacity(outputLen + 4 + nalLen)
        writeInt32BE(outputBuf, outputLen, nalLen)
        outputLen += 4
        System.arraycopy(inputBuffer, nalStart, outputBuf, outputLen, nalLen)
        outputLen += nalLen
        kept++
      } else if (action == NalAction.CONVERT) {
        val convertedLen = convertRpuIntoOutput(nalStart, nalLen, outputLen + 4)
        if (convertedLen >= 0) {
          writeInt32BE(outputBuf, outputLen, convertedLen)
          outputLen += 4
          outputLen += convertedLen
          convertedRpuCount++
          kept++
        } else {
          recordStrippedNal(action)
          stripped++
        }
      } else {
        recordStrippedNal(action)
        stripped++
      }

      pos += 4 + nalLen
    }

    sampleCount++
    if (sampleCount <= 3 || (sampleCount % 500 == 0L)) {
      logDebug(
        "Sample #$sampleCount (LenPrefix): ${dataLen}B -> ${outputLen}B, " +
          "kept=$kept stripped=$stripped NALs"
      )
    }
  }

  private enum class NalAction { KEEP, STRIP_RPU, STRIP_EL, CONVERT }

  private fun recordStrippedNal(action: NalAction) {
    strippedNalCount++
    // CONVERT reaches here only after conversion fails; raw P7 RPUs are not safe in P8.1 output.
    when (action) {
      NalAction.STRIP_RPU, NalAction.CONVERT -> strippedRpuNalCount++
      NalAction.STRIP_EL -> strippedElNalCount++
      NalAction.KEEP -> Unit
    }
  }

  private fun convertRpuIntoOutput(nalStart: Int, nalLen: Int, outputOffset: Int): Int {
    ensureOutputCapacity(outputOffset + MAX_CONVERTED_RPU_SIZE)

    var retriedAfterResize = false
    while (true) {
      val startNs = System.nanoTime()
      val written = DoviBridge.convertRpuNalu(
        payload = inputBuffer,
        payloadOffset = nalStart,
        payloadLength = nalLen,
        output = outputBuf,
        outputOffset = outputOffset,
        outputCapacity = outputBuf.size,
        mode = LIBDOVI_MODE_TO_81
      )
      totalRpuConversionTimeUs += (System.nanoTime() - startNs) / 1_000L
      rpuConversionCallCount++

      if (written >= 0) return written

      if (written == DoviBridge.DESTINATION_TOO_SMALL) {
        rpuOutputTooSmallCount++
        if (!retriedAfterResize) {
          val doubled = if (outputBuf.size <= Int.MAX_VALUE / 2) outputBuf.size * 2 else Int.MAX_VALUE
          ensureOutputCapacity(maxOf(doubled, outputOffset + MAX_CONVERTED_RPU_SIZE))
          retriedAfterResize = true
          continue
        }
      }

      rpuConversionFailureCount++
      return written
    }
  }

  private fun recordSampleProcessing(elapsedUs: Long) {
    totalSampleProcessingTimeUs += elapsedUs
    if (sampleCount <= 3 || (sampleCount > 0 && sampleCount % 500 == 0L)) {
      logDebug(
        "Perf: avgSample=${averageSampleProcessingTimeUs}us, " +
          "avgRpu=${averageRpuConversionTimeUs}us, converted=$convertedRpuCount, " +
          "rpuFailures=$rpuConversionFailureCount, rpuTooSmall=$rpuOutputTooSmallCount"
      )
    }
  }

  private fun stripInitializationData(initializationData: List<ByteArray>): List<ByteArray> {
    if (initializationData.isEmpty()) return emptyList()

    val stripped = ArrayList<ByteArray>(initializationData.size)
    var beforeBytes = 0
    var afterBytes = 0
    var droppedBuffers = 0

    for (data in initializationData) {
      beforeBytes += data.size
      val processed = stripInitializationAnnexB(data)
      if (processed == null) {
        // Media3's HEVC init data is normally Annex B. Non-AnnexB entries in
        // Dolby Vision formats are typically dvcC/dvvC records, which must not
        // be forwarded when advertising plain HEVC.
        droppedBuffers++
        continue
      }
      if (processed.isEmpty()) {
        droppedBuffers++
        continue
      }
      afterBytes += processed.size
      stripped.add(processed)
    }

    logInfo(
      "Init data stripped: ${initializationData.size} entries/${beforeBytes}B -> " +
        "${stripped.size} entries/${afterBytes}B, strippedNals=$strippedInitNalCount, " +
        "droppedBuffers=$droppedBuffers"
    )

    return stripped
  }

  private fun stripInitializationAnnexB(data: ByteArray): ByteArray? {
    if (data.isEmpty()) return data

    val firstStartCodeEnd = findStartCodeEnd(data, 0) ?: return null
    ensureOutputCapacity(data.size)
    outputLen = 0

    var kept = 0
    var stripped = 0
    var nalStart = firstStartCodeEnd

    while (nalStart < data.size) {
      val nalEnd = findNextStartCodeOffset(data, nalStart) ?: data.size
      val nalLen = nalEnd - nalStart
      if (nalLen > 0) {
        when (classifyNal(data, nalStart, nalLen, convertRpu = false)) {
          NalAction.KEEP -> {
            ensureOutputCapacity(outputLen + 4 + nalLen)
            System.arraycopy(ANNEX_B_START_CODE, 0, outputBuf, outputLen, 4)
            outputLen += 4
            System.arraycopy(data, nalStart, outputBuf, outputLen, nalLen)
            outputLen += nalLen
            kept++
          }
          else -> {
            strippedInitNalCount++
            stripped++
          }
        }
      }

      if (nalEnd >= data.size) break
      nalStart = findStartCodeEnd(data, nalEnd) ?: break
    }

    logDebug("Init data sample: ${data.size}B -> ${outputLen}B, kept=$kept stripped=$stripped NALs")
    return outputBuf.copyOf(outputLen)
  }

  private fun findStartCodeEnd(data: ByteArray, from: Int): Int? {
    var i = from
    while (i < data.size - 2) {
      if (data[i] == 0.toByte() && data[i + 1] == 0.toByte()) {
        if (i + 3 < data.size && data[i + 2] == 0.toByte() && data[i + 3] == 1.toByte()) {
          return i + 4
        } else if (data[i + 2] == 1.toByte()) {
          return i + 3
        }
      }
      i++
    }
    return null
  }

  private fun findNextStartCodeOffset(data: ByteArray, from: Int): Int? {
    var i = from
    while (i < data.size - 2) {
      if (data[i] == 0.toByte() && data[i + 1] == 0.toByte()) {
        if (i + 3 < data.size && data[i + 2] == 0.toByte() && data[i + 3] == 1.toByte()) {
          return i
        } else if (data[i + 2] == 1.toByte()) {
          return i
        }
      }
      i++
    }
    return null
  }

  /** Classify a NAL at sampleBuf[offset..offset+len) without copying. */
  private fun processNalInline(offset: Int, len: Int): NalAction = classifyNal(inputBuffer, offset, len, convertRpu = dvMode == DvConversionMode.DV81)

  private fun isDvProfile7Codec(codecs: String?): Boolean {
    val normalized = codecs?.lowercase() ?: return false
    return normalized.startsWith("dvhe.07") || normalized.startsWith("dvh1.07")
  }

  private fun classifyNal(data: ByteArray, offset: Int, len: Int, convertRpu: Boolean): NalAction {
    if (len < 2) return NalAction.KEEP
    val nalType = (data[offset].toInt() ushr 1) and 0x3F
    return when {
      nalType == NAL_TYPE_UNSPEC62 && convertRpu -> NalAction.CONVERT
      nalType == NAL_TYPE_UNSPEC62 -> NalAction.STRIP_RPU
      nalType == NAL_TYPE_UNSPEC63 -> NalAction.STRIP_EL
      else -> NalAction.KEEP
    }
  }

  private fun writeInt32BE(buf: ByteArray, offset: Int, value: Int) {
    buf[offset] = ((value ushr 24) and 0xFF).toByte()
    buf[offset + 1] = ((value ushr 16) and 0xFF).toByte()
    buf[offset + 2] = ((value ushr 8) and 0xFF).toByte()
    buf[offset + 3] = (value and 0xFF).toByte()
  }

  private fun readInt32BE(buf: ByteArray, offset: Int): Int = ((buf[offset].toInt() and 0xFF) shl 24) or
    ((buf[offset + 1].toInt() and 0xFF) shl 16) or
    ((buf[offset + 2].toInt() and 0xFF) shl 8) or
    (buf[offset + 3].toInt() and 0xFF)

  private fun copyRawSample(dataLen: Int) {
    ensureOutputCapacity(dataLen)
    System.arraycopy(inputBuffer, 0, outputBuf, 0, dataLen)
    outputLen = dataLen
  }

  private fun formatBytes(data: ByteArray, offset: Int, length: Int): String {
    val end = minOf(data.size, offset + length)
    if (offset >= end) return ""
    return (offset until end).joinToString(" ") { "%02X".format(data[it]) }
  }

  private fun ensureOutputCapacity(needed: Int) {
    if (outputBuf.size < needed) {
      outputBuf = outputBuf.copyOf(maxOf(needed, outputBuf.size * 2))
    }
  }

  private fun logDebug(message: String) {
    Log.d(TAG, message)
    emitLog?.invoke("debug", "dv-convert", message)
  }

  private fun logInfo(message: String) {
    Log.i(TAG, message)
    emitLog?.invoke("info", "dv-convert", message)
  }

  private fun logWarn(message: String) {
    Log.w(TAG, message)
    emitLog?.invoke("warn", "dv-convert", message)
  }

  private fun logError(message: String, throwable: Throwable) {
    Log.e(TAG, message, throwable)
    emitLog?.invoke("error", "dv-convert", "$message: ${throwable.message}")
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
    record[0] = 0x01 // dv_version_major = 1
    record[1] = 0x00 // dv_version_minor = 0
    record[2] = ((8 shl 1) or ((level ushr 5) and 0x01)).toByte() // profile=8 | level MSB
    record[3] = (((level and 0x1F) shl 3) or 0x05).toByte() // level low 5 | rpu=1 el=0 bl=1
    record[4] = (1 shl 4).toByte() // bl_compatibility_id=1 (HDR10)
    // bytes 5-23 remain 0 (reserved)
    return record
  }
}
