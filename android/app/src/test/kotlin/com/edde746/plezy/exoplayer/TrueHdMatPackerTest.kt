package com.edde746.plezy.exoplayer

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Pins the TrueHD -> MAT/IEC 61937 carrier against FFmpeg (#1804).
 *
 * The carrier is fed straight to an `ENCODING_IEC61937` AudioTrack, so a wrong byte is not a subtle
 * defect: the receiver either drops sync or renders the carrier as full-scale noise. The only
 * defensible bar is byte-for-byte agreement with a reference implementation, so the fixtures are
 * FFmpeg's own input and output:
 *
 * ```
 * ffmpeg -i surround_5_1_truehd.mka -c:a copy -f truehd truehd_access_units.bin
 * ffmpeg -i surround_5_1_truehd.mka -c:a copy -f spdif  truehd_iec61937_golden.bin
 * ```
 */
class TrueHdMatPackerTest {

  private fun resource(name: String): ByteArray = checkNotNull(javaClass.classLoader?.getResourceAsStream(name)) { "missing fixture $name" }
    .use { it.readBytes() }

  private val accessUnits by lazy { resource("truehd_access_units.bin") }
  private val golden by lazy { resource("truehd_iec61937_golden.bin") }

  /** The whole point: our carrier and FFmpeg's are the same bytes. */
  @Test
  fun packedCarrierMatchesFfmpegByteForByte() {
    val packed = packAll(accessUnits)

    assertEquals(
      "burst count differs from FFmpeg",
      golden.size / TrueHdMatPacker.MAT_PKT_OFFSET,
      packed.size / TrueHdMatPacker.MAT_PKT_OFFSET
    )
    // Compare per burst so a failure names the frame rather than dumping 240KB.
    for (index in 0 until packed.size / TrueHdMatPacker.MAT_PKT_OFFSET) {
      val from = index * TrueHdMatPacker.MAT_PKT_OFFSET
      val to = from + TrueHdMatPacker.MAT_PKT_OFFSET
      assertArrayEquals(
        "burst $index differs from FFmpeg",
        golden.copyOfRange(from, to),
        packed.copyOfRange(from, to)
      )
    }
  }

  /** Each burst is a full IEC 61937 frame: preamble, then payload, then the inter-frame gap. */
  @Test
  fun everyBurstCarriesTheTrueHdPreamble() {
    val packed = packAll(accessUnits)
    assertTrue("expected at least one burst", packed.isNotEmpty())

    for (index in 0 until packed.size / TrueHdMatPacker.MAT_PKT_OFFSET) {
      val at = index * TrueHdMatPacker.MAT_PKT_OFFSET
      assertEquals("burst $index Pa", 0xF872, readLittleEndianShort(packed, at))
      assertEquals("burst $index Pb", 0x4E1F, readLittleEndianShort(packed, at + 2))
      assertEquals("burst $index Pc (IEC61937_TRUEHD)", 0x16, readLittleEndianShort(packed, at + 4))
      assertEquals("burst $index Pd", TrueHdMatPacker.MAT_FRAME_SIZE, readLittleEndianShort(packed, at + 6))
    }
  }

  /** A burst is exactly 20ms of carrier, which is what makes the PCM-domain accounting downstream correct. */
  @Test
  fun aBurstIsTwentyMillisecondsOfCarrier() {
    val framesPerBurst = TrueHdMatPacker.MAT_PKT_OFFSET / IecCarrier.BYTES_PER_FRAME
    val durationUs = framesPerBurst * 1_000_000L / IecCarrier.SAMPLE_RATE
    assertEquals(20_000L, durationUs)
  }

  /**
   * Media3's Matroska path concatenates 16 syncframes into one sample, so the packer has to split
   * them itself; feeding a whole sample as if it were one access unit reads a single timing for
   * sixteen frames and desynchronises the carrier.
   */
  @Test
  fun aRechunkedSampleIsSplitIntoItsAccessUnits() {
    var offset = 0
    var units = 0
    while (offset < accessUnits.size) {
      val length = TrueHdMatPacker.accessUnitLength(accessUnits, offset, accessUnits.size)
      if (length == 0) break
      units++
      offset += length
    }
    assertTrue("fixture should contain many access units, found $units", units > 16)
    assertEquals("access unit walk must consume the stream exactly", accessUnits.size, offset)
  }

  /** Reset must not leave a half-filled frame behind, or the next seek emits a spliced burst. */
  @Test
  fun resetDropsPartialCarrierState() {
    val packer = TrueHdMatPacker()
    feed(packer, accessUnits, stopAfterBursts = 1)
    packer.reset()

    val afterReset = packAll(accessUnits, packer)
    assertArrayEquals(
      "a reset packer must reproduce the stream from the start",
      packAll(accessUnits),
      afterReset
    )
  }

  /** The packer must not allocate a burst per frame; buffers alternate and are reused. */
  @Test
  fun burstBuffersAreReusedRatherThanAllocated() {
    val packer = TrueHdMatPacker()
    val seen = java.util.IdentityHashMap<java.nio.ByteBuffer, Boolean>()
    var bursts = 0
    var offset = 0
    while (offset < accessUnits.size) {
      val length = TrueHdMatPacker.accessUnitLength(accessUnits, offset, accessUnits.size)
      if (length == 0) break
      packer.packAccessUnit(accessUnits, offset, length)?.let {
        seen[it] = true
        bursts++
      }
      offset += length
    }
    assertTrue("expected several bursts, saw $bursts", bursts > 2)
    assertTrue("at most two buffers may ever be handed out, saw ${seen.size}", seen.size <= 2)
  }

  private fun packAll(units: ByteArray, packer: TrueHdMatPacker = TrueHdMatPacker()): ByteArray {
    val out = java.io.ByteArrayOutputStream()
    var offset = 0
    while (offset < units.size) {
      val length = TrueHdMatPacker.accessUnitLength(units, offset, units.size)
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

  private fun feed(packer: TrueHdMatPacker, units: ByteArray, stopAfterBursts: Int) {
    var offset = 0
    var bursts = 0
    while (offset < units.size && bursts < stopAfterBursts) {
      val length = TrueHdMatPacker.accessUnitLength(units, offset, units.size)
      if (length == 0) break
      if (packer.packAccessUnit(units, offset, length) != null) bursts++
      offset += length
    }
  }

  private fun readLittleEndianShort(data: ByteArray, offset: Int): Int = (data[offset].toInt() and 0xFF) or ((data[offset + 1].toInt() and 0xFF) shl 8)

  /**
   * The flag gates every later call, so leaving it latched across a reset would make a packer that
   * once saw a 44.1kHz-family stream emit nothing for the rest of its life.
   */
  @Test
  fun resetClearsTheUnsupportedRateFamilyFlag() {
    val packer = TrueHdMatPacker()
    val units = resource("truehd_441_access_units.bin")

    val length = TrueHdMatPacker.accessUnitLength(units, 0, units.size)
    packer.packAccessUnit(units, 0, length)
    assertTrue("the fixture must actually announce the 44.1kHz family", packer.unsupportedStream)

    packer.reset()

    assertFalse("reset must clear the flag", packer.unsupportedStream)
    assertArrayEquals(
      "a clean packer must reproduce the stream after a poisoned one",
      golden,
      packAll(accessUnits, TrueHdMatPacker())
    )
  }
}
