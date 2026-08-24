package com.edde746.plezy.exoplayer

import androidx.annotation.OptIn
import androidx.media3.common.MimeTypes
import androidx.media3.common.ParserException
import androidx.media3.common.util.UnstableApi
import androidx.media3.container.OpusUtil

/**
 * Shapes ffmpeg codec extradata into the per-codec initializationData layout
 * media3's audio decode paths consume. MediaCodecAudioRenderer maps the list
 * entries verbatim to MediaCodec csd-0/1/2 and the bundled FfmpegAudioDecoder
 * rebuilds avcodec extradata from the same entries, so both expect the shapes
 * media3's own extractors emit — not raw ffmpeg extradata:
 *
 * - Opus: [OpusHead, codec delay ns, seek pre-roll ns]. Android's Opus
 *   decoders consume their first three input buffers as exactly this
 *   configuration; given only OpusHead they read the first two real packets
 *   as delay/pre-roll and then silently discard every decoded sample, which
 *   stalled the audio clock at 0 until the MPV fallback fired (#2088).
 * - Vorbis: [identification header, setup header], split out of the
 *   Xiph-laced blob the way MatroskaExtractor's parseVorbisCodecPrivate does.
 * - FLAC: the "fLaC"-marked STREAMINFO stream MediaCodec documents; ffmpeg
 *   surfaces a bare or block-headed STREAMINFO depending on the container.
 *
 * Everything else (AAC ASC, ALAC cookie, passthrough codecs) already matches
 * media3's single-entry shape and passes through. MP3's WAVEFORMATEX blob is
 * dropped on the JNI side before it reaches this shaping.
 */
@OptIn(UnstableApi::class)
internal object FfmpegAudioCsd {

  // RFC 7845 section 5.1: the identification header is at least 19 bytes;
  // OpusUtil reads the pre-skip field at offsets 10-11.
  private const val OPUS_HEADER_MIN_BYTES = 19

  private val FLAC_STREAM_MARKER = byteArrayOf(0x66, 0x4C, 0x61, 0x43) // "fLaC"
  private const val FLAC_STREAM_INFO_SIZE = 34
  private const val FLAC_BLOCK_HEADER_SIZE = 4
  private const val FLAC_LAST_BLOCK_FLAG = 0x80

  fun initializationData(mime: String, extradata: ByteArray): List<ByteArray> = when (mime) {
    MimeTypes.AUDIO_OPUS -> opus(extradata)
    MimeTypes.AUDIO_VORBIS -> vorbis(extradata)
    MimeTypes.AUDIO_FLAC -> flac(extradata)
    else -> listOf(extradata)
  }

  private fun opus(extradata: ByteArray): List<ByteArray> {
    if (extradata.size < OPUS_HEADER_MIN_BYTES) {
      throw malformed("Opus extradata is not an identification header: ${extradata.size} bytes")
    }
    // [OpusHead, pre-skip ns, 80 ms default seek pre-roll ns] — the same
    // shape media3's Matroska/Ogg/MP4 extractors publish.
    return OpusUtil.buildInitializationData(extradata)
  }

  /**
   * Splits the Xiph-laced header blob (identification, comment, setup) into
   * media3's [identification header, setup header] pair, mirroring media3
   * 1.11.0 MatroskaExtractor.parseVorbisCodecPrivate.
   */
  private fun vorbis(extradata: ByteArray): List<ByteArray> {
    try {
      if (extradata[0].toInt() != 0x02) throw malformed("Vorbis extradata is not Xiph-laced headers")
      var offset = 1
      var idHeaderLength = 0
      while (extradata[offset].toInt() and 0xFF == 0xFF) {
        idHeaderLength += 0xFF
        offset++
      }
      idHeaderLength += extradata[offset++].toInt() and 0xFF
      var commentHeaderLength = 0
      while (extradata[offset].toInt() and 0xFF == 0xFF) {
        commentHeaderLength += 0xFF
        offset++
      }
      commentHeaderLength += extradata[offset++].toInt() and 0xFF

      if (extradata[offset].toInt() != 0x01) throw malformed("Vorbis identification header not found")
      val idHeader = extradata.copyOfRange(offset, offset + idHeaderLength)
      offset += idHeaderLength
      if (extradata[offset].toInt() != 0x03) throw malformed("Vorbis comment header not found")
      offset += commentHeaderLength
      if (extradata[offset].toInt() != 0x05) throw malformed("Vorbis setup header not found")
      return listOf(idHeader, extradata.copyOfRange(offset, extradata.size))
    } catch (e: IndexOutOfBoundsException) {
      throw malformed("Vorbis extradata truncated")
    }
  }

  /**
   * Normalizes to the "fLaC"-marked metadata stream. MediaCodec's decoder
   * feeds csd-0 straight into libFLAC, which requires the stream marker;
   * ffmpeg's canonical FLAC extradata is the bare 34-byte STREAMINFO, and
   * some demuxers keep the 4-byte metadata block header in front of it.
   */
  private fun flac(extradata: ByteArray): List<ByteArray> {
    if (startsWithFlacMarker(extradata)) return listOf(extradata)
    if (extradata.size == FLAC_STREAM_INFO_SIZE) {
      val blockHeader = byteArrayOf(
        (FLAC_LAST_BLOCK_FLAG or 0).toByte(), // last-metadata-block, type 0 = STREAMINFO
        0x00,
        0x00,
        FLAC_STREAM_INFO_SIZE.toByte()
      )
      return listOf(FLAC_STREAM_MARKER + blockHeader + extradata)
    }
    val declaredLength = if (extradata.size >= FLAC_BLOCK_HEADER_SIZE) {
      ((extradata[1].toInt() and 0xFF) shl 16) or
        ((extradata[2].toInt() and 0xFF) shl 8) or
        (extradata[3].toInt() and 0xFF)
    } else {
      -1
    }
    if (extradata[0].toInt() and 0x7F == 0 &&
      declaredLength == FLAC_STREAM_INFO_SIZE &&
      extradata.size >= FLAC_BLOCK_HEADER_SIZE + FLAC_STREAM_INFO_SIZE
    ) {
      return listOf(FLAC_STREAM_MARKER + extradata)
    }
    throw malformed("FLAC extradata is not a STREAMINFO block: ${extradata.size} bytes")
  }

  private fun startsWithFlacMarker(extradata: ByteArray): Boolean {
    if (extradata.size < FLAC_STREAM_MARKER.size) return false
    for (i in FLAC_STREAM_MARKER.indices) {
      if (extradata[i] != FLAC_STREAM_MARKER[i]) return false
    }
    return true
  }

  private fun malformed(message: String): ParserException = ParserException.createForMalformedContainer(message, null)
}
