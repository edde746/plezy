package com.edde746.plezy.exoplayer

import androidx.media3.common.MimeTypes
import androidx.media3.common.ParserException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Test

/**
 * Spec for the per-codec initializationData shapes the ffmpeg demuxer must
 * publish so MediaCodec csd-0/1/2 and FfmpegAudioDecoder's extradata
 * reconstruction both see what media3's own extractors emit. Regression
 * coverage for #2088: Opus with a bare OpusHead csd made Android's decoders
 * eat the first two real packets as configuration and discard all output.
 */
class FfmpegAudioCsdTest {

  private fun opusHead(preSkip: Int): ByteArray {
    val header = ByteArray(19)
    "OpusHead".toByteArray(Charsets.US_ASCII).copyInto(header)
    header[8] = 1 // version
    header[9] = 2 // channel count
    header[10] = (preSkip and 0xFF).toByte()
    header[11] = (preSkip ushr 8).toByte()
    return header
  }

  private fun nativeOrderLong(bytes: ByteArray): Long = ByteBuffer.wrap(bytes).order(ByteOrder.nativeOrder()).long

  @Test
  fun opusBuildsThreeCsdBuffers() {
    val header = opusHead(preSkip = 312)
    val csd = FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_OPUS, header)
    assertEquals(3, csd.size)
    assertArrayEquals(header, csd[0])
    // Pre-skip converted to nanoseconds at the Opus 48 kHz clock.
    assertEquals(312L * 1_000_000_000L / 48_000L, nativeOrderLong(csd[1]))
    // media3's default seek pre-roll: 3840 samples = 80 ms.
    assertEquals(80_000_000L, nativeOrderLong(csd[2]))
  }

  @Test
  fun opusRejectsTruncatedHeader() {
    assertThrows(ParserException::class.java) {
      FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_OPUS, ByteArray(11))
    }
  }

  private fun xiphLace(length: Int): ByteArray {
    val bytes = ArrayList<Byte>()
    var remaining = length
    while (remaining >= 0xFF) {
      bytes.add(0xFF.toByte())
      remaining -= 0xFF
    }
    bytes.add(remaining.toByte())
    return bytes.toByteArray()
  }

  private fun vorbisHeader(type: Int, payloadLength: Int): ByteArray =
    byteArrayOf(type.toByte()) + "vorbis".toByteArray(Charsets.US_ASCII) + ByteArray(payloadLength)

  @Test
  fun vorbisSplitsLacedHeadersIntoIdentificationAndSetup() {
    val id = vorbisHeader(0x01, payloadLength = 23) // 30 bytes, the real identification header size
    val comment = vorbisHeader(0x03, payloadLength = 300) // > 255 exercises the 0xFF lacing
    val setup = vorbisHeader(0x05, payloadLength = 40)
    val extradata = byteArrayOf(0x02) + xiphLace(id.size) + xiphLace(comment.size) + id + comment + setup

    val csd = FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_VORBIS, extradata)

    assertEquals(2, csd.size)
    assertArrayEquals(id, csd[0])
    assertArrayEquals(setup, csd[1])
  }

  @Test
  fun vorbisRejectsNonLacedExtradata() {
    assertThrows(ParserException::class.java) {
      FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_VORBIS, byteArrayOf(0x01, 0x02, 0x03))
    }
  }

  @Test
  fun vorbisRejectsTruncatedExtradata() {
    val id = vorbisHeader(0x01, payloadLength = 23)
    val truncated = byteArrayOf(0x02) + xiphLace(id.size) + xiphLace(64) + id // headers end early
    assertThrows(ParserException::class.java) {
      FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_VORBIS, truncated)
    }
  }

  @Test
  fun flacWrapsBareStreamInfoInMarkedStream() {
    val streamInfo = ByteArray(34) { it.toByte() }
    val csd = FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_FLAC, streamInfo)
    assertEquals(1, csd.size)
    assertArrayEquals(
      "fLaC".toByteArray(Charsets.US_ASCII) + byteArrayOf(0x80.toByte(), 0x00, 0x00, 34) + streamInfo,
      csd[0]
    )
  }

  @Test
  fun flacPrependsMarkerToBlockHeadedStreamInfo() {
    val block = byteArrayOf(0x00, 0x00, 0x00, 34) + ByteArray(34) { it.toByte() }
    val csd = FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_FLAC, block)
    assertEquals(1, csd.size)
    assertArrayEquals("fLaC".toByteArray(Charsets.US_ASCII) + block, csd[0])
  }

  @Test
  fun flacKeepsMarkedStreamVerbatim() {
    val marked = "fLaC".toByteArray(Charsets.US_ASCII) + byteArrayOf(0x80.toByte(), 0x00, 0x00, 34) + ByteArray(34)
    val csd = FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_FLAC, marked)
    assertEquals(1, csd.size)
    assertSame(marked, csd[0])
  }

  @Test
  fun flacRejectsUnrecognizedExtradata() {
    assertThrows(ParserException::class.java) {
      FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_FLAC, ByteArray(10))
    }
  }

  @Test
  fun otherCodecsPassExtradataThroughAsSingleEntry() {
    val asc = byteArrayOf(0x12, 0x10) // AAC-LC 44.1 kHz stereo AudioSpecificConfig
    val csd = FfmpegAudioCsd.initializationData(MimeTypes.AUDIO_AAC, asc)
    assertEquals(1, csd.size)
    assertSame(asc, csd[0])
  }
}
