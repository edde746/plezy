package com.edde746.plezy.exoplayer

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
 * Pure JVM (no android/media3 imports) so it stays unit-testable on the host.
 */
object DvBitstreamSanitizer {

  private const val NAL_TYPE_PREFIX_SEI = 39
  private const val NAL_TYPE_SUFFIX_SEI = 40
  private const val NAL_TYPE_UNSPEC62 = 62 // DV RPU
  private const val NAL_TYPE_UNSPEC63 = 63 // DV Enhancement Layer

  private const val SEI_PAYLOAD_TYPE_ITU_T_T35 = 4

  /**
   * Scans `[position, limit)` of [data] for Annex B NAL units and removes the selected
   * metadata NALs by compacting the buffer in place and reducing its limit. The position
   * is left unchanged.
   */
  fun sanitize(data: ByteBuffer, stripHdr10PlusSei: Boolean, stripDvRpu: Boolean) {
    val startPos = data.position()
    val limit = data.limit()
    var writePos = startPos
    var nalStartIndex = -1
    var startCodeLen = 0

    var i = startPos
    while (i <= limit) {
      // Find next start code or end of buffer.
      val atEnd = i == limit
      var foundStartCode = false
      var nextStartCodeLen = 0
      if (!atEnd && i + 2 < limit && data.get(i).toInt() == 0 && data.get(i + 1).toInt() == 0) {
        if (data.get(i + 2).toInt() == 1) {
          foundStartCode = true
          nextStartCodeLen = 3
        } else if (data.get(i + 2).toInt() == 0 && i + 3 < limit && data.get(i + 3).toInt() == 1) {
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
            val nalUnitType = (data.get(nalDataStart).toInt() and 0x7E) shr 1
            strip = when (nalUnitType) {
              NAL_TYPE_UNSPEC62, NAL_TYPE_UNSPEC63 -> stripDvRpu
              NAL_TYPE_PREFIX_SEI, NAL_TYPE_SUFFIX_SEI ->
                stripHdr10PlusSei && isHdr10PlusSeiNalUnit(data, nalDataStart + 2, nalEnd)
              else -> false
            }
          }

          if (!strip) {
            if (writePos != nalStartIndex) {
              for (j in nalStartIndex until nalEnd) {
                data.put(writePos++, data.get(j))
              }
            } else {
              writePos = nalEnd
            }
          }
        }
        nalStartIndex = i
        startCodeLen = nextStartCodeLen
        i += if (nextStartCodeLen > 0) nextStartCodeLen else 1
      } else {
        i++
      }
    }

    data.limit(writePos)
    data.position(startPos)
  }

  /**
   * Returns whether the SEI RBSP (starting after the 2-byte HEVC NAL header) begins with an
   * HDR10+ message: user_data_registered_itu_t_t35 with country code 0xB5 (United States),
   * provider code 0x003C (Samsung), provider oriented code 0x0001, application identifier 4
   * (ST 2094-40), application version 0 or 1. Malformed/truncated data returns false so the
   * NAL is kept.
   */
  private fun isHdr10PlusSeiNalUnit(data: ByteBuffer, rbspStart: Int, nalEnd: Int): Boolean {
    var pos = rbspStart
    if (pos >= nalEnd) return false

    // SEI payload type: accumulated 0xFF bytes plus the final byte.
    var payloadType = 0
    while (pos < nalEnd) {
      val b = data.get(pos++).toInt() and 0xFF
      payloadType += b
      if (b != 0xFF) break
    }

    // SEI payload size, same encoding.
    var payloadSize = 0
    while (pos < nalEnd) {
      val b = data.get(pos++).toInt() and 0xFF
      payloadSize += b
      if (b != 0xFF) break
    }

    if (payloadType != SEI_PAYLOAD_TYPE_ITU_T_T35 || payloadSize < 7 || pos + 7 > nalEnd) {
      return false
    }

    // The identifier bytes (B5 00 3C 00 01 04 00/01) cannot contain the 0x000003 emulation
    // prevention pattern, so they can be read without RBSP unescaping.
    val countryCode = data.get(pos).toInt() and 0xFF
    val providerCode = ((data.get(pos + 1).toInt() and 0xFF) shl 8) or (data.get(pos + 2).toInt() and 0xFF)
    val orientedCode = ((data.get(pos + 3).toInt() and 0xFF) shl 8) or (data.get(pos + 4).toInt() and 0xFF)
    val appIdentifier = data.get(pos + 5).toInt() and 0xFF
    val appVersion = data.get(pos + 6).toInt() and 0xFF

    return countryCode == 0xB5 &&
      providerCode == 0x003C &&
      orientedCode == 0x0001 &&
      appIdentifier == 4 &&
      (appVersion == 0 || appVersion == 1)
  }
}
