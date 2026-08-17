package com.edde746.plezy.exoplayer

import java.nio.ByteBuffer

/**
 * Packs DTS-HD (Master Audio) access units into IEC 61937 "DTS type IV" bursts (#1988).
 *
 * Some HDMI routes advertise `ENCODING_DTS_HD` but cannot actually carry Master Audio: Amazon
 * specifies the Fire TV Stick 4K Max as "DTS-HD passthrough, basic profile", and Android has one
 * ambiguous encoding constant for both profiles until API 34. Handing media3's raw path full MA
 * frames there initialises an AudioTrack that drains normally and renders silence. The same
 * devices do bitstream the 192kHz/7.1 `ENCODING_IEC61937` carrier — the split Kodi models with
 * its "AudioTrack (IEC)" sink, and the one TrueHD already rides here (#1804, #1863) — so DTS-HD
 * is packed onto that carrier instead.
 *
 * The algorithm is a port of FFmpeg's `spdif_header_dts`/`spdif_header_dts4`
 * (libavformat/spdifenc.c, n8.1) at `dtshd_rate=768000`, the rate that fills the 8-channel/192kHz
 * carrier; Kodi's `CAEBitstreamPacker::PackDTSHD` produces the same bytes.
 *
 * Output is one complete IEC 61937 burst per access unit:
 *
 *  - 8-byte preamble, little endian: `Pa=0xF872 Pb=0x4E1F Pc=0x11|subtype<<8 Pd=aligned bytes`
 *  - 10-byte DTS-HD start code, 16-bit big-endian payload size, then the access unit, all 16-bit
 *    byte-swapped
 *  - zero padding to the burst repetition period the core frame duration maps to
 *    (512 samples at 48kHz — the shape of essentially all Master Audio — is 32768 bytes)
 *
 * Unlike MAT's fixed frames, a Master Audio peak can genuinely exceed the carrier. FFmpeg answers
 * by stripping such units to the always-fitting core substream and holding that for
 * `dtshd_fallback_time` (60s) so receivers do not flap between core and MA decoding; that
 * behavior is ported as-is and pinned by the golden fixture.
 *
 * Not thread safe; the sink drives it from the playback thread only.
 */
internal class DtsHdIecPacker : IecCarrierPacker {

  internal companion object {
    private const val BURST_HEADER_SIZE = 8
    private const val SYNCWORD1 = 0xF872
    private const val SYNCWORD2 = 0x4E1F
    private const val IEC61937_DTSHD = 0x11

    /** Core and extension-substream sync words, big-endian raw framing. */
    private const val SYNC_CORE = 0x7FFE8001
    private const val SYNC_EXSS = 0x64582025

    /**
     * Little-endian and 14-bit core framings, from S/PDIF and DTS-in-WAV captures. They have no
     * period mapping here (FFmpeg's HD path refuses them too), so they latch the stream
     * unsupported and it decodes.
     */
    private const val SYNC_CORE_LE = 0xFE7F0180.toInt()
    private const val SYNC_CORE_14B_BE = 0x1FFFE800
    private const val SYNC_CORE_14B_LE = 0xFF1F00E8.toInt()

    /**
     * The carrier's IEC 60958 frame rate as FFmpeg's two-channel model counts it: the burst
     * repetition period is `period = 768000 * coreSamples / coreRate` IEC 60958 frames of 4 bytes,
     * which is the same byte rate as [IecCarrier]'s 8 channels at 192kHz.
     */
    private const val CARRIER_IEC958_RATE = 768_000

    /** Core SFREQ index to Hz (`ff_dca_sample_rates`); zero marks invalid indices. */
    private val CORE_SAMPLE_RATES = intArrayOf(
      0, 8000, 16000, 32000, 0, 0, 11025, 22050, 44100, 0, 0, 12000, 24000, 48000, 96000, 192000
    )

    /** Precedes every burst payload; `spdifenc.c`'s `dtshd_start_code`. */
    private val START_CODE = byteArrayOf(0x01, 0, 0, 0, 0, 0, 0, 0, 0xFE.toByte(), 0xFE.toByte())

    /** Seconds of core-only output after an overflow; FFmpeg's `dtshd_fallback_time` default. */
    private const val HD_STRIP_SECONDS = 60

    /** Minimum bytes needed to read a core header through its SFREQ field. */
    private const val MIN_CORE_HEADER_LENGTH = 9

    /** IEC 61937-11 subtype for a burst repetition period in IEC 60958 frames, or -1. */
    private fun subtypeForPeriod(period: Long): Int = when (period) {
      512L -> 0
      1024L -> 1
      2048L -> 2
      4096L -> 3
      8192L -> 4
      16384L -> 5
      else -> -1
    }

    private fun readSyncWord(data: ByteArray, offset: Int): Int = ((data[offset].toInt() and 0xFF) shl 24) or
      ((data[offset + 1].toInt() and 0xFF) shl 16) or
      ((data[offset + 2].toInt() and 0xFF) shl 8) or
      (data[offset + 3].toInt() and 0xFF)

    /** Reads [count] (≤ 24) bits big-endian starting at absolute bit [bitPosition]. */
    private fun readBits(data: ByteArray, bitPosition: Int, count: Int): Int {
      var result = 0
      var position = bitPosition
      var remaining = count
      while (remaining > 0) {
        val byte = data[position ushr 3].toInt() and 0xFF
        val bitsLeftInByte = 8 - (position and 7)
        val take = minOf(bitsLeftInByte, remaining)
        result = (result shl take) or ((byte shr (bitsLeftInByte - take)) and ((1 shl take) - 1))
        position += take
        remaining -= take
      }
      return result
    }

    /** `NBLKS + 1`: PCM blocks of 32 samples in the core frame at [offset]. */
    private fun coreBlocks(data: ByteArray, offset: Int): Int {
      val word = ((data[offset + 4].toInt() and 0xFF) shl 8) or (data[offset + 5].toInt() and 0xFF)
      return ((word shr 2) and 0x7F) + 1
    }

    /** `FSIZE + 1`: the core frame's byte length. */
    private fun coreFrameSize(data: ByteArray, offset: Int): Int {
      val bits = ((data[offset + 5].toInt() and 0xFF) shl 16) or
        ((data[offset + 6].toInt() and 0xFF) shl 8) or
        (data[offset + 7].toInt() and 0xFF)
      return ((bits shr 4) and 0x3FFF) + 1
    }

    /** The core `SFREQ` field mapped to Hz; 0 for reserved indices. */
    private fun coreSampleRate(data: ByteArray, offset: Int): Int = CORE_SAMPLE_RATES[((data[offset + 8].toInt() and 0xFF) shr 2) and 0x0F]

    /**
     * Total byte length of the extension substream at [offset] (`nuBits4ExSSFsize + 1`), or 0
     * when the header does not fit in [limit].
     *
     * Header layout after the 32-bit sync: UserDefinedBits(8), nExtSSIndex(2),
     * bHeaderSizeType(1), then a header-size field of 8 or 12 bits and this size field of 16 or
     * 20 bits — at most 75 bits, so 10 bytes cover every shape.
     */
    private fun extensionSubstreamSize(data: ByteArray, offset: Int, limit: Int): Int {
      if (offset + 10 > limit) return 0
      val base = offset shl 3
      val wide = readBits(data, base + 42, 1) == 1
      val sizeFieldPosition = base + 43 + if (wide) 12 else 8
      return readBits(data, sizeFieldPosition, if (wide) 20 else 16) + 1
    }
  }

  /** Burst geometry learned from the stream's core framing; zero until the first unit packs. */
  private var burstBytes = 0

  private var burstBacking = Array(2) { ByteArray(0) }
  private var burstBuffers = Array(2) { ByteBuffer.wrap(burstBacking[it]) }
  private var burstIndex = 0

  /** Bytes each reusable buffer was dirtied to, so padding only clears what a prior burst wrote. */
  private val dirtyEnd = intArrayOf(0, 0)

  /** Assembles start code + size + access unit before the byte swap; sized with the bursts. */
  private var payloadScratch = ByteArray(0)

  /** Access units still to strip to their core after an overflow. */
  private var hdStripRemaining = 0

  /**
   * Latched when a burst had to be stripped to the core substream, so the sink can log the
   * downgrade once. Cleared by [reset].
   */
  var strippedToCore = false
    private set

  override var unsupportedStream = false
    private set

  override fun reset() {
    // Buffers and the learned burst geometry survive; only per-stream state drops. The flag is
    // re-learned from the next unit; leaving it latched would silence every later stream.
    hdStripRemaining = 0
    strippedToCore = false
    unsupportedStream = false
  }

  override fun accessUnitLength(data: ByteArray, offset: Int, limit: Int): Int {
    if (offset + 4 > limit) return 0
    when (readSyncWord(data, offset)) {
      SYNC_CORE -> Unit
      SYNC_EXSS -> {
        // A stray HD frame without its core, seen at stream starts. Its size is walkable, so it
        // is consumed as a unit and dropped by packAccessUnit; FFmpeg discards these too.
        val size = extensionSubstreamSize(data, offset, limit)
        return if (size < 4 || offset + size > limit) 0 else size
      }
      SYNC_CORE_LE, SYNC_CORE_14B_BE, SYNC_CORE_14B_LE -> {
        unsupportedStream = true
        return 0
      }
      else -> return 0
    }

    if (offset + MIN_CORE_HEADER_LENGTH > limit) return 0
    val coreSize = coreFrameSize(data, offset)
    var end = offset + coreSize
    if (coreSize < MIN_CORE_HEADER_LENGTH || end > limit) return 0
    // Master Audio glues one or more extension substreams to the core; they belong to this unit.
    while (end + 4 <= limit && readSyncWord(data, end) == SYNC_EXSS) {
      val size = extensionSubstreamSize(data, end, limit)
      if (size < 4 || end + size > limit) return 0
      end += size
    }
    return end - offset
  }

  override fun packAccessUnit(data: ByteArray, offset: Int, length: Int): ByteBuffer? {
    if (length < MIN_CORE_HEADER_LENGTH) return null
    when (readSyncWord(data, offset)) {
      SYNC_CORE -> Unit
      // The stray leading HD frame accessUnitLength admitted; there is no core to derive a
      // period from, so it is dropped rather than carried.
      SYNC_EXSS -> return null
      else -> return null
    }

    val blocks = coreBlocks(data, offset)
    val coreSize = coreFrameSize(data, offset)
    val sampleRate = coreSampleRate(data, offset)
    if (sampleRate == 0) {
      unsupportedStream = true
      return null
    }

    val coreSamples = blocks shl 5
    val periodProduct = CARRIER_IEC958_RATE.toLong() * coreSamples
    val period = periodProduct / sampleRate
    val newSubtype = if (periodProduct % sampleRate != 0L) -1 else subtypeForPeriod(period)
    if (newSubtype < 0) {
      // 44.1kHz-family cores and exotic frame lengths map to no IEC 61937-11 repetition period at
      // this carrier rate; FFmpeg refuses them the same way, so the stream decodes instead.
      unsupportedStream = true
      return null
    }
    setBurstGeometry((period * 4).toInt())

    // FFmpeg's overflow answer: a Master Audio peak the carrier cannot hold strips this and the
    // next ~60 seconds of units to the always-fitting core substream, so the receiver does not
    // flap between core and MA decoding.
    if (START_CODE.size + 2 + length > burstBytes - BURST_HEADER_SIZE) {
      hdStripRemaining = sampleRate * HD_STRIP_SECONDS / coreSamples
    }
    var payloadSize = length
    if (hdStripRemaining > 0 && coreSize <= length) {
      payloadSize = coreSize
      hdStripRemaining--
      strippedToCore = true
    }
    val payloadBytes = START_CODE.size + 2 + payloadSize
    if (payloadBytes > burstBytes - BURST_HEADER_SIZE) {
      // Even the bare core overflows this period (only possible for very short core frames);
      // nothing can be carried.
      unsupportedStream = true
      return null
    }

    START_CODE.copyInto(payloadScratch, 0)
    payloadScratch[START_CODE.size] = (payloadSize ushr 8).toByte()
    payloadScratch[START_CODE.size + 1] = (payloadSize and 0xFF).toByte()
    data.copyInto(payloadScratch, START_CODE.size + 2, offset, offset + payloadSize)
    // A final lone byte goes out MSB-aligned; its swap partner must be zero, not stale scratch.
    if (payloadBytes and 1 == 1) payloadScratch[payloadBytes] = 0

    burstIndex = burstIndex xor 1
    val backing = burstBacking[burstIndex]
    putLittleEndianShort(backing, 0, SYNCWORD1)
    putLittleEndianShort(backing, 2, SYNCWORD2)
    putLittleEndianShort(backing, 4, IEC61937_DTSHD or (newSubtype shl 8))
    // Aligned so (Pd & 0xF) == 0x8, which some receivers reportedly require; FFmpeg and Kodi
    // both apply the same quirk.
    putLittleEndianShort(backing, 6, ((payloadBytes + 0x17) and 0x0F.inv()) - BURST_HEADER_SIZE)

    // The carrier is a 16-bit sample stream, so the payload goes out byte-swapped per word.
    var source = 0
    var destination = BURST_HEADER_SIZE
    val swappedPayload = payloadBytes + (payloadBytes and 1)
    while (source < swappedPayload) {
      backing[destination] = payloadScratch[source + 1]
      backing[destination + 1] = payloadScratch[source]
      source += 2
      destination += 2
    }
    if (destination < dirtyEnd[burstIndex]) {
      java.util.Arrays.fill(backing, destination, dirtyEnd[burstIndex], 0)
    }
    dirtyEnd[burstIndex] = destination

    val burst = burstBuffers[burstIndex]
    burst.limit(burstBytes)
    burst.position(0)
    return burst
  }

  private fun setBurstGeometry(newBurstBytes: Int) {
    if (newBurstBytes == burstBytes) return
    burstBytes = newBurstBytes
    burstBacking = Array(2) { ByteArray(newBurstBytes) }
    burstBuffers = Array(2) { ByteBuffer.wrap(burstBacking[it]).order(java.nio.ByteOrder.LITTLE_ENDIAN) }
    dirtyEnd[0] = 0
    dirtyEnd[1] = 0
    payloadScratch = ByteArray(newBurstBytes)
  }

  private fun putLittleEndianShort(target: ByteArray, offset: Int, value: Int) {
    target[offset] = (value and 0xFF).toByte()
    target[offset + 1] = ((value shr 8) and 0xFF).toByte()
  }
}
