package com.edde746.plezy.exoplayer

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Pins the DTS-HD -> IEC 61937 "DTS type IV" carrier against FFmpeg (#1988).
 *
 * The carrier is fed straight to an `ENCODING_IEC61937` AudioTrack, so a wrong byte is not a subtle
 * defect: the receiver either drops sync or renders the carrier as full-scale noise. The only
 * defensible bar is byte-for-byte agreement with a reference implementation, so the fixtures are
 * FFmpeg's own input and output at the 768kHz HD rate that fills the 192kHz/7.1 carrier.
 *
 * FFmpeg cannot encode Master Audio, so the access units are synthesized — real `dca` core frames,
 * each glued to a hand-built extension substream — by `dtshd_fixture_generator.py` beside the
 * fixtures; the golden is then FFmpeg's own packing:
 *
 * ```
 * ffmpeg -f dts -i dtshd_ma_access_units.bin -c:a copy -f spdif -dtshd_rate 768000 \
 *     dtshd_ma_iec61937_golden.bin
 * ```
 *
 * One mid-stream unit is oversized on purpose, so the fixtures also pin FFmpeg's overflow answer:
 * strip to the core substream and hold that for ~60s.
 */
class DtsHdIecPackerTest {

  private fun resource(name: String): ByteArray = checkNotNull(javaClass.classLoader?.getResourceAsStream(name)) { "missing fixture $name" }
    .use { it.readBytes() }

  private val accessUnits by lazy { resource("dtshd_ma_access_units.bin") }
  private val golden by lazy { resource("dtshd_ma_iec61937_golden.bin") }

  /** 512 samples at the fixture's 48kHz core rate on the 768kHz carrier model, in bytes. */
  private val burstSize = 32768

  /** The whole point: our carrier and FFmpeg's are the same bytes. */
  @Test
  fun packedCarrierMatchesFfmpegByteForByte() {
    val packed = packAll(accessUnits)

    assertEquals(
      "burst count differs from FFmpeg",
      golden.size / burstSize,
      packed.size / burstSize
    )
    // Compare per burst so a failure names the burst rather than dumping 480KB.
    for (index in 0 until packed.size / burstSize) {
      val from = index * burstSize
      val to = from + burstSize
      assertArrayEquals(
        "burst $index differs from FFmpeg",
        golden.copyOfRange(from, to),
        packed.copyOfRange(from, to)
      )
    }
  }

  /** Each burst is a full IEC 61937 frame: preamble, then payload, then zero padding. */
  @Test
  fun everyBurstCarriesTheDtsHdPreamble() {
    val packed = packAll(accessUnits)

    for (index in 0 until packed.size / burstSize) {
      val at = index * burstSize
      assertEquals("burst $index Pa", 0xF872, readLittleEndianShort(packed, at))
      assertEquals("burst $index Pb", 0x4E1F, readLittleEndianShort(packed, at + 2))
      // Data type 0x11 with subtype 4: an 8192 IEC 60958 frame repetition period.
      assertEquals("burst $index Pc (IEC61937_DTSHD)", 0x0411, readLittleEndianShort(packed, at + 4))
      val payloadSize = 10 + 2 + burstAccessUnitSize(packed, at)
      assertEquals(
        "burst $index Pd must carry FFmpeg's (length & 0xf) == 0x8 alignment",
        ((payloadSize + 0x17) and 0x0F.inv()) - 8,
        readLittleEndianShort(packed, at + 6)
      )
    }
  }

  /**
   * A Master Audio peak the carrier cannot hold is stripped to the always-fitting core substream,
   * and stays stripped for ~60s so the receiver does not flap between core and MA decoding. The
   * fixture's fifth unit is oversized on purpose; everything after it is core-only.
   */
  @Test
  fun anOversizedUnitStripsToTheCoreAndHolds() {
    val packer = DtsHdIecPacker()
    val packed = packAll(accessUnits, packer)

    val fullUnit = 3904
    val coreOnly = 1884
    for (index in 0 until packed.size / burstSize) {
      val expected = if (index < 4) fullUnit else coreOnly
      assertEquals("burst $index payload size", expected, burstAccessUnitSize(packed, index * burstSize))
    }
    assertTrue("the strip must be observable for logging", packer.strippedToCore)
    assertFalse("stripping is a downgrade, not an unsupported stream", packer.unsupportedStream)
  }

  /** Core frames and their glued extension substreams split as one access unit each. */
  @Test
  fun accessUnitsSpanTheCoreAndItsExtensionSubstreams() {
    val packer = DtsHdIecPacker()
    var units = 0
    var offset = 0
    while (offset < accessUnits.size) {
      val length = packer.accessUnitLength(accessUnits, offset, accessUnits.size)
      if (length == 0) break
      units++
      offset += length
    }
    assertEquals("every byte of the fixture belongs to a unit", accessUnits.size, offset)
    assertEquals(golden.size / burstSize, units)
  }

  /**
   * Streams with core sometimes open with a stray HD frame that has no core (FFmpeg discards
   * these). It must be consumed as a unit so the stream keeps moving, but never carried: there is
   * no core to derive the burst period from.
   */
  @Test
  fun aStrayLeadingExtensionSubstreamIsConsumedButNotCarried() {
    val packer = DtsHdIecPacker()
    val firstUnit = packer.accessUnitLength(accessUnits, 0, accessUnits.size)
    val exssSize = 2020
    val stray = accessUnits.copyOfRange(firstUnit - exssSize, firstUnit)

    val length = packer.accessUnitLength(stray, 0, stray.size)

    assertEquals("the stray frame's own size field walks it", exssSize, length)
    assertNull("a coreless frame cannot ride the carrier", packer.packAccessUnit(stray, 0, length))
    assertFalse("a stray frame is dropped, not latched", packer.unsupportedStream)
  }

  /** The wide (bHeaderSizeType=1) extension-substream header carries 20-bit size fields. */
  @Test
  fun wideHeaderExtensionSubstreamSizesAreParsed() {
    val packer = DtsHdIecPacker()
    val core = accessUnits.copyOfRange(0, 1884)
    val exssSize = 4100
    val unit = core + wideHeaderExtensionSubstream(exssSize)

    assertEquals(1884 + exssSize, packer.accessUnitLength(unit, 0, unit.size))
  }

  /**
   * Little-endian and 14-bit core framings (S/PDIF and DTS-in-WAV captures) have no period mapping
   * on this carrier; they must latch the stream unsupported so the sink hands it to the decoder,
   * not silently consume it.
   */
  @Test
  fun nonBigEndianCoreFramingLatchesTheStreamUnsupported() {
    for (sync in listOf(
      byteArrayOf(0xFE.toByte(), 0x7F, 0x01, 0x80.toByte()),
      byteArrayOf(0x1F, 0xFF.toByte(), 0xE8.toByte(), 0x00),
      byteArrayOf(0xFF.toByte(), 0x1F, 0x00, 0xE8.toByte())
    )) {
      val packer = DtsHdIecPacker()
      val buffer = sync + ByteArray(64)

      assertEquals(0, packer.accessUnitLength(buffer, 0, buffer.size))
      assertTrue("sync ${sync.joinToString { "%02x".format(it) }}", packer.unsupportedStream)
    }
  }

  /** A 44.1kHz-family core maps to no IEC 61937-11 repetition period at 192kHz; it must decode. */
  @Test
  fun aFortyFourFamilyCoreLatchesTheStreamUnsupported() {
    val packer = DtsHdIecPacker()
    val unit = accessUnits.copyOfRange(0, 1884)
    // SFREQ sits in bits [5:2] of byte 8; index 8 is 44100Hz.
    unit[8] = ((unit[8].toInt() and 0b11000011) or (8 shl 2)).toByte()

    assertNull(packer.packAccessUnit(unit, 0, unit.size))
    assertTrue(packer.unsupportedStream)
  }

  /**
   * The flags gate every later call, so leaving them latched across a reset would make a packer
   * that once saw a bad stream emit nothing (or log strips) for the rest of its life.
   */
  @Test
  fun resetClearsTheLatchesAndReproducesTheStream() {
    val packer = DtsHdIecPacker()
    val leSync = byteArrayOf(0xFE.toByte(), 0x7F, 0x01, 0x80.toByte()) + ByteArray(64)
    packer.accessUnitLength(leSync, 0, leSync.size)
    assertTrue(packer.unsupportedStream)

    packer.reset()

    assertFalse("reset must clear the unsupported latch", packer.unsupportedStream)
    assertFalse("reset must clear the strip latch", packer.strippedToCore)
    assertArrayEquals(
      "a clean packer must reproduce the stream after a poisoned one",
      golden,
      packAll(accessUnits, packer)
    )
  }

  /** The packer must not allocate a burst per unit; buffers alternate and are reused. */
  @Test
  fun burstBuffersAreReusedRatherThanAllocated() {
    val packer = DtsHdIecPacker()
    val seen = java.util.IdentityHashMap<java.nio.ByteBuffer, Boolean>()
    var bursts = 0
    var offset = 0
    while (offset < accessUnits.size) {
      val length = packer.accessUnitLength(accessUnits, offset, accessUnits.size)
      if (length == 0) break
      packer.packAccessUnit(accessUnits, offset, length)?.let {
        seen[it] = true
        bursts++
      }
      offset += length
    }
    assertTrue("expected multiple bursts", bursts > 2)
    assertEquals("buffers must alternate between exactly two", 2, seen.size)
  }

  private fun packAll(units: ByteArray, packer: DtsHdIecPacker = DtsHdIecPacker()): ByteArray {
    val out = java.io.ByteArrayOutputStream()
    var offset = 0
    while (offset < units.size) {
      val length = packer.accessUnitLength(units, offset, units.size)
      if (length == 0) break
      packer.packAccessUnit(units, offset, length)?.let { burst ->
        val copy = ByteArray(burst.remaining())
        burst.duplicate().get(copy)
        out.write(copy)
      }
      offset += length
    }
    return out.toByteArray()
  }

  /** The 16-bit big-endian size field after the start code, read from the byte-swapped burst. */
  private fun burstAccessUnitSize(packed: ByteArray, burstOffset: Int): Int {
    // Payload bytes 10 and 11 land swapped within their 16-bit word: 10 -> +19, 11 -> +18.
    val high = packed[burstOffset + 8 + 11].toInt() and 0xFF
    val low = packed[burstOffset + 8 + 10].toInt() and 0xFF
    return (high shl 8) or low
  }

  /** An extension substream whose header uses the wide 12/20-bit size fields. */
  private fun wideHeaderExtensionSubstream(size: Int): ByteArray {
    val frame = ByteArray(size)
    frame[0] = 0x64
    frame[1] = 0x58
    frame[2] = 0x20
    frame[3] = 0x25
    // After UserDefinedBits(8): nExtSSIndex(2)=0, bHeaderSizeType(1)=1, then 12 header-size bits
    // and 20 frame-size bits, all values stored minus one.
    var bits = 0L
    bits = (bits shl 2) or 0L
    bits = (bits shl 1) or 1L
    bits = (bits shl 12) or (32L - 1)
    bits = (bits shl 20) or (size.toLong() - 1)
    // 35 bits, MSB-aligned into bytes 5..9.
    val aligned = bits shl (40 - 35)
    for (i in 0 until 5) {
      frame[5 + i] = ((aligned shr (32 - 8 * i)) and 0xFF).toByte()
    }
    return frame
  }

  private fun readLittleEndianShort(data: ByteArray, offset: Int): Int = (data[offset].toInt() and 0xFF) or ((data[offset + 1].toInt() and 0xFF) shl 8)
}
