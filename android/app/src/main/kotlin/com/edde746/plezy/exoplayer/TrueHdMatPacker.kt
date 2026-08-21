package com.edde746.plezy.exoplayer

import java.nio.ByteBuffer
/**
 * Packs Dolby TrueHD access units into MAT frames carried in IEC 61937 bursts (#1804).
 *
 * Android will not bitstream raw TrueHD on the TV routes we have measured — the platform reports
 * `ENCODING_DOLBY_TRUEHD` as offload-only while reporting `ENCODING_IEC61937` at 192kHz/7.1 as
 * bitstream-capable. That is also the split Kodi models: it offers an "AudioTrack (IEC)" sink where
 * it packs the carrier itself, and treats handing raw TrueHD to Android as the fallback. Media3 only
 * ever does the latter, and at the stream rate rather than the carrier rate, which is why playback
 * wedges where other players work.
 *
 * The algorithm is a port of FFmpeg's `spdif_header_truehd` (libavformat/spdifenc.c, n8.0). Kodi's
 * `CAEBitstreamPacker` is *not* an equivalent reference: it wraps an already-assembled buffer,
 * whereas the timing-driven padding and MAT code placement live in FFmpeg's stateful packer.
 *
 * Output is a complete IEC 61937 burst per MAT frame:
 *
 *  - 8 byte preamble, little endian: `Pa=0xF872 Pb=0x4E1F Pc=0x0016 Pd=61424`
 *  - 61424 bytes of MAT frame, 16-bit byte-swapped
 *  - 8 bytes of zero padding
 *  - 61440 bytes total, which is 20ms at 192kHz/8ch/16-bit
 *
 * Not thread safe; the sink drives it from the playback thread only.
 */
internal class TrueHdMatPacker : IecCarrierPacker {

  internal companion object {
    /** Payload bytes in one MAT frame. */
    const val MAT_FRAME_SIZE = 61424

    /** Bytes from the start of one burst to the next, including preamble and trailing gap. */
    const val MAT_PKT_OFFSET = 61440

    private const val BURST_HEADER_SIZE = 8
    private const val SYNCWORD1 = 0xF872
    private const val SYNCWORD2 = 0x4E1F
    private const val IEC61937_TRUEHD = 0x16

    /** Minimum bytes needed to read an access unit header plus its major-sync probe. */
    private const val MIN_ACCESS_UNIT_LENGTH = 10

    private val MAT_START_CODE = byteArrayOf(
      0x07, 0x9E.toByte(), 0x00, 0x03, 0x84.toByte(), 0x01, 0x01, 0x01, 0x80.toByte(), 0x00,
      0x56, 0xA5.toByte(), 0x3B, 0xF4.toByte(), 0x81.toByte(), 0x83.toByte(), 0x49, 0x80.toByte(),
      0x77, 0xE0.toByte()
    )
    private val MAT_MIDDLE_CODE = byteArrayOf(
      0xC3.toByte(), 0xC1.toByte(), 0x42, 0x49, 0x3B, 0xFA.toByte(), 0x82.toByte(), 0x83.toByte(),
      0x49, 0x80.toByte(), 0x77, 0xE0.toByte()
    )
    private val MAT_END_CODE = byteArrayOf(
      0xC3.toByte(), 0xC2.toByte(), 0xC0.toByte(), 0xC4.toByte(), 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x97.toByte(), 0x11
    )

    private val MAT_CODES = arrayOf(MAT_START_CODE, MAT_MIDDLE_CODE, MAT_END_CODE)
    private val MAT_CODE_POSITIONS = intArrayOf(0, 30708, MAT_FRAME_SIZE - MAT_END_CODE.size)

    /**
     * Length of the access unit starting at [offset], in bytes.
     *
     * The first 16-bit big-endian word carries the length in units of 16-bit words in its low 12
     * bits. Returns 0 when the buffer is too short or the length is nonsensical, which the caller
     * treats as "stop walking".
     */
    fun accessUnitLength(data: ByteArray, offset: Int, limit: Int): Int {
      if (offset + 2 > limit) return 0
      val words = ((data[offset].toInt() and 0x0F) shl 8) or (data[offset + 1].toInt() and 0xFF)
      val length = words * 2
      return if (length < 4 || offset + length > limit) 0 else length
    }

    /** True when the access unit at [offset] carries a major sync, which announces the rate. */
    private fun hasMajorSync(data: ByteArray, offset: Int, limit: Int): Boolean {
      if (offset + 8 > limit) return false
      return (data[offset + 4].toInt() and 0xFF) == 0xF8 &&
        (data[offset + 5].toInt() and 0xFF) == 0x72 &&
        (data[offset + 6].toInt() and 0xFF) == 0x6F
    }
  }

  private val matBuffers = Array(2) { ByteArray(MAT_FRAME_SIZE) }
  private val burstBacking = Array(2) { ByteArray(MAT_PKT_OFFSET) }
  private val burstBuffers = Array(2) {
    ByteBuffer.wrap(burstBacking[it]).order(java.nio.ByteOrder.LITTLE_ENDIAN)
  }
  private var burstIndex = 0
  private var matBufferIndex = 0
  private var matBufferFilled = 0
  private var previousTiming = 0
  private var previousSize = 0
  private var samplesPerFrame = 0

  /** Drops all carrier state. Call on flush/seek: MAT frames must not straddle a discontinuity. */
  override fun reset() {
    matBufferIndex = 0
    matBufferFilled = 0
    previousTiming = 0
    previousSize = 0
    samplesPerFrame = 0
    // The family is re-learned from the next major sync. Leaving it latched here would make every
    // later stream on this packer emit nothing.
    unsupportedStream = false
    java.util.Arrays.fill(matBuffers[0], 0)
    java.util.Arrays.fill(matBuffers[1], 0)
  }

  /**
   * True when the stream announced a 44.1kHz-family rate.
   *
   * That family rides a 176.4kHz carrier rather than 192kHz, which changes the AudioTrack tuple the
   * whole path is built around. Rather than carry a second carrier configuration for a combination
   * that is essentially absent from real media, the sink reads this and falls back to decoding.
   */
  override var unsupportedStream: Boolean = false
    private set

  override fun accessUnitLength(data: ByteArray, offset: Int, limit: Int): Int = Companion.accessUnitLength(data, offset, limit)

  /**
   * Packs one access unit, returning a completed burst when this unit finished a MAT frame.
   *
   * The returned buffer is owned by the packer and reused, alternating between two so a burst
   * handed downstream stays valid while the next frame fills. Callers must submit or copy it before
   * the second following call. This is the audio path on low-power TV hardware — a fresh 61,440
   * byte array every 20ms would be roughly 3MB/s of garbage.
   *
   * Faithful to `spdif_header_truehd`: padding between units is derived from the delta of their
   * `input_timing` fields against the previous unit's on-carrier size, so the carrier keeps a fixed
   * rate even though the source frames vary in length.
   *
   * At most one burst can complete per access unit: padding is bounded below half a MAT frame and
   * an access unit is far smaller, so a single unit cannot span two frame boundaries.
   */
  override fun packAccessUnit(data: ByteArray, offset: Int, length: Int): ByteBuffer? {
    if (length < MIN_ACCESS_UNIT_LENGTH) return null

    if (hasMajorSync(data, offset, offset + length)) {
      // Rate is announced in the major sync; 40 samples per frame at 48kHz, doubling with the rate.
      val rateBits = when (data[offset + 7].toInt() and 0xFF) {
        0xBA -> (data[offset + 8].toInt() and 0xFF) shr 4
        0xBB -> (data[offset + 9].toInt() and 0xFF) shr 4
        else -> return null
      }
      // Bit 3 selects the 44.1kHz family, which rides a 176.4kHz carrier we do not build.
      unsupportedStream = (rateBits and 8) != 0
      if (unsupportedStream) return null
      samplesPerFrame = 40 shl (rateBits and 3)
    }
    if (unsupportedStream || samplesPerFrame == 0) return null

    val inputTiming = ((data[offset + 2].toInt() and 0xFF) shl 8) or (data[offset + 3].toInt() and 0xFF)
    var paddingRemaining = 0
    if (previousSize != 0) {
      val deltaSamples = (inputTiming - previousTiming) and 0xFFFF
      // One 48kHz-family frame is 1/1200s; the carrier runs at 768000*4 bytes/s, so the nominal
      // space per frame is 2560 bytes, which divides evenly by samplesPerFrame.
      val deltaBytes = deltaSamples * 2560 / samplesPerFrame
      paddingRemaining = deltaBytes - previousSize
      if (paddingRemaining < 0 || paddingRemaining >= MAT_FRAME_SIZE / 2) {
        // Timing we do not model; better a momentary rate wobble than a corrupt frame.
        paddingRemaining = 0
      }
    }

    var totalFrameSize = length
    var dataCursor = offset
    var dataRemaining = length
    var completed: ByteBuffer? = null

    var nextCodeIndex = MAT_CODE_POSITIONS.indexOfFirst { matBufferFilled <= it }
    if (nextCodeIndex < 0) return null

    while (paddingRemaining > 0 || dataRemaining > 0 || MAT_CODE_POSITIONS[nextCodeIndex] == matBufferFilled) {
      if (MAT_CODE_POSITIONS[nextCodeIndex] == matBufferFilled) {
        val code = MAT_CODES[nextCodeIndex]
        var codeLengthRemaining = code.size
        code.copyInto(matBuffers[matBufferIndex], matBufferFilled)
        matBufferFilled += code.size
        nextCodeIndex++

        if (nextCodeIndex == MAT_CODES.size) {
          nextCodeIndex = 0
          // Last code of the frame: this buffer is complete, continue filling the other one.
          completed = toIec61937Burst(matBuffers[matBufferIndex])
          matBufferIndex = matBufferIndex xor 1
          matBufferFilled = 0
          // The inter-frame gap occupies carrier space too.
          codeLengthRemaining += MAT_PKT_OFFSET - MAT_FRAME_SIZE
        }

        if (paddingRemaining > 0) {
          val countedAsPadding = minOf(paddingRemaining, codeLengthRemaining)
          paddingRemaining -= countedAsPadding
          codeLengthRemaining -= countedAsPadding
        }
        if (codeLengthRemaining > 0) totalFrameSize += codeLengthRemaining
      }

      if (paddingRemaining > 0) {
        val padding = minOf(MAT_CODE_POSITIONS[nextCodeIndex] - matBufferFilled, paddingRemaining)
        java.util.Arrays.fill(matBuffers[matBufferIndex], matBufferFilled, matBufferFilled + padding, 0)
        matBufferFilled += padding
        paddingRemaining -= padding
        if (paddingRemaining > 0) continue
      }

      if (dataRemaining > 0) {
        val toCopy = minOf(MAT_CODE_POSITIONS[nextCodeIndex] - matBufferFilled, dataRemaining)
        data.copyInto(matBuffers[matBufferIndex], matBufferFilled, dataCursor, dataCursor + toCopy)
        matBufferFilled += toCopy
        dataCursor += toCopy
        dataRemaining -= toCopy
      }
    }

    previousSize = totalFrameSize
    previousTiming = inputTiming
    return completed
  }

  /**
   * Wraps a finished MAT frame in its IEC 61937 burst, into the next reusable buffer.
   *
   * Alternating between two keeps a burst already handed downstream intact while the following
   * frame is assembled.
   */
  private fun toIec61937Burst(matFrame: ByteArray): ByteBuffer {
    burstIndex = burstIndex xor 1
    val burst = burstBuffers[burstIndex]
    val backing = burstBacking[burstIndex]
    putLittleEndianShort(backing, 0, SYNCWORD1)
    putLittleEndianShort(backing, 2, SYNCWORD2)
    putLittleEndianShort(backing, 4, IEC61937_TRUEHD)
    putLittleEndianShort(backing, 6, MAT_FRAME_SIZE)
    // The carrier is a 16-bit sample stream, so the payload goes out byte-swapped per word.
    var source = 0
    var destination = BURST_HEADER_SIZE
    while (source < MAT_FRAME_SIZE) {
      backing[destination] = matFrame[source + 1]
      backing[destination + 1] = matFrame[source]
      source += 2
      destination += 2
    }
    // Trailing bytes stay zero for the inter-frame gap; the backing array is never re-dirtied
    // beyond MAT_FRAME_SIZE, so they remain zero for the life of the packer.
    burst.limit(MAT_PKT_OFFSET)
    burst.position(0)
    return burst
  }

  private fun putLittleEndianShort(target: ByteArray, offset: Int, value: Int) {
    target[offset] = (value and 0xFF).toByte()
    target[offset + 1] = ((value shr 8) and 0xFF).toByte()
  }
}
