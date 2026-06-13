package com.amaze.vibestream.exoplayer

import java.nio.ByteBuffer

/**
 * In-place sanitizer for HEVC Annex B buffers carrying both Dolby Vision and HDR10+
 * dynamic metadata. Buggy chipsets (Fire TV 4K Max, MediaTek-based Google TV, ...)
 * crash or black-screen when a native DV codec also receives in-band HDR10+ SEI, so
 * only the metadata the active decode path consumes may be kept:
 *
 * - Native DV codec: strip HDR10+ SEI NALs (types 39/40 with ST 2094-40 payload),
 *   the decoder follows the DV RPU. Port of androidx/media#3085 / Kodi xbmc#24584.
 * - HEVC fallback for a DV format: strip DV RPU/EL NALs (types 62/63) instead,
 *   leaving HDR10+ for the display.
 *
 * Runs on the playback thread against MediaCodec's direct input buffers, where
 * per-byte ByteBuffer accessor calls are far too slow for high-bitrate UHD remuxes
 * (#1313). Each sample is therefore staged through a reusable heap array with a
 * single bulk get, scanned and compacted with array ops, and only the modified tail
 * is written back. Instances are not thread-safe: use one per renderer.
 *
 * Pure JVM (no android/media3 imports) so it stays unit-testable on the host.
 */
class DvBitstreamSanitizer {

  private companion object {
    const val NAL_TYPE_PREFIX_SEI = 39
    const val NAL_TYPE_SUFFIX_SEI = 40
    const val NAL_TYPE_UNSPEC62 = 62 // DV RPU
    const val NAL_TYPE_UNSPEC63 = 63 // DV Enhancement Layer

    const val SEI_PAYLOAD_TYPE_ITU_T_T35 = 4

    const val INITIAL_SCRATCH_SIZE = 256 * 1024
  }

  /** Reusable staging buffer — grown as needed, never shrunk. */
  private var scratch = ByteArray(INITIAL_SCRATCH_SIZE)

  /**
   * Scans `[position, limit)` of [data] for Annex B NAL units and removes the selected
   * metadata NALs by compacting the buffer in place and reducing its limit. The position
   * is left unchanged. Returns the number of NAL units stripped.
   *
   * A sample with no start codes at all is left untouched: it cannot contain the
   * targeted NALs, and emptying it would only confuse the decoder.
   */
  fun sanitize(data: ByteBuffer, stripHdr10PlusSei: Boolean, stripDvRpu: Boolean): Int {
    val startPos = data.position()
    val len = data.limit() - startPos
    if (len == 0) return 0
    if (scratch.size < len) scratch = ByteArray(maxOf(len, scratch.size * 2))
    val buf = scratch
    data.get(buf, 0, len)
    data.position(startPos)

    var writeLen = 0
    var firstModified = -1
    var strippedCount = 0
    var nalStartIndex = -1
    var startCodeLen = 0

    var i = 0
    while (i <= len) {
      // Find next start code or end of buffer.
      val atEnd = i == len
      var foundStartCode = false
      var nextStartCodeLen = 0
      if (!atEnd && i + 2 < len && buf[i].toInt() == 0 && buf[i + 1].toInt() == 0) {
        if (buf[i + 2].toInt() == 1) {
          foundStartCode = true
          nextStartCodeLen = 3
        } else if (buf[i + 2].toInt() == 0 && i + 3 < len && buf[i + 3].toInt() == 1) {
          foundStartCode = true
          nextStartCodeLen = 4
        }
      }

      if (foundStartCode || atEnd) {
        if (nalStartIndex >= 0) {
          // Complete NAL unit (including its start code) from nalStartIndex to i.
          val nalDataStart = nalStartIndex + startCodeLen
          val nalEnd = i
          var strip = false

          if (nalEnd - nalDataStart >= 2) {
            // HEVC NAL header: forbidden_zero_bit(1) + nal_unit_type(6) + nuh_layer_id MSB(1).
            val nalUnitType = (buf[nalDataStart].toInt() and 0x7E) shr 1
            strip = when (nalUnitType) {
              NAL_TYPE_UNSPEC62, NAL_TYPE_UNSPEC63 -> stripDvRpu
              NAL_TYPE_PREFIX_SEI, NAL_TYPE_SUFFIX_SEI ->
                stripHdr10PlusSei && isHdr10PlusSeiNalUnit(buf, nalDataStart + 2, nalEnd)
              else -> false
            }
          }

          if (strip) {
            strippedCount++
            if (firstModified < 0) firstModified = writeLen
          } else {
            if (writeLen != nalStartIndex) {
              // Also reached with zero strips when bytes precede the first start code.
              if (firstModified < 0) firstModified = writeLen
              System.arraycopy(buf, nalStartIndex, buf, writeLen, nalEnd - nalStartIndex)
            }
            writeLen += nalEnd - nalStartIndex
          }
        }
        nalStartIndex = i
        startCodeLen = nextStartCodeLen
        i += if (nextStartCodeLen > 0) nextStartCodeLen else 1
      } else {
        i++
      }
    }

    if (writeLen == len || firstModified < 0) return 0

    // Bytes before firstModified are byte-identical to the buffer; write back only the tail.
    data.position(startPos + firstModified)
    data.put(buf, firstModified, writeLen - firstModified)
    data.limit(startPos + writeLen)
    data.position(startPos)
    return strippedCount
  }

  /**
   * Returns whether the SEI RBSP (starting after the 2-byte HEVC NAL header) begins with an
   * HDR10+ message: user_data_registered_itu_t_t35 with country code 0xB5 (United States),
   * provider code 0x003C (Samsung), provider oriented code 0x0001, application identifier 4
   * (ST 2094-40), application version 0 or 1. Malformed/truncated data returns false so the
   * NAL is kept.
   */
  private fun isHdr10PlusSeiNalUnit(buf: ByteArray, rbspStart: Int, nalEnd: Int): Boolean {
    var pos = rbspStart
    if (pos >= nalEnd) return false

    // SEI payload type: accumulated 0xFF bytes plus the final byte.
    var payloadType = 0
    while (pos < nalEnd) {
      val b = buf[pos++].toInt() and 0xFF
      payloadType += b
      if (b != 0xFF) break
    }

    // SEI payload size, same encoding.
    var payloadSize = 0
    while (pos < nalEnd) {
      val b = buf[pos++].toInt() and 0xFF
      payloadSize += b
      if (b != 0xFF) break
    }

    if (payloadType != SEI_PAYLOAD_TYPE_ITU_T_T35 || payloadSize < 7 || pos + 7 > nalEnd) {
      return false
    }

    // The identifier bytes (B5 00 3C 00 01 04 00/01) cannot contain the 0x000003 emulation
    // prevention pattern, so they can be read without RBSP unescaping.
    val countryCode = buf[pos].toInt() and 0xFF
    val providerCode = ((buf[pos + 1].toInt() and 0xFF) shl 8) or (buf[pos + 2].toInt() and 0xFF)
    val orientedCode = ((buf[pos + 3].toInt() and 0xFF) shl 8) or (buf[pos + 4].toInt() and 0xFF)
    val appIdentifier = buf[pos + 5].toInt() and 0xFF
    val appVersion = buf[pos + 6].toInt() and 0xFF

    return countryCode == 0xB5 &&
      providerCode == 0x003C &&
      orientedCode == 0x0001 &&
      appIdentifier == 4 &&
      (appVersion == 0 || appVersion == 1)
  }
}
