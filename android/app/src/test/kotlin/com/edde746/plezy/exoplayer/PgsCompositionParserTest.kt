package com.edde746.plezy.exoplayer

import androidx.media3.common.text.Cue
import androidx.media3.extractor.text.CuesWithTiming
import androidx.media3.extractor.text.SubtitleParser
import java.io.ByteArrayOutputStream
import java.util.zip.Deflater
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Regression coverage for #1953: display sets with several composition objects must
 * produce one cue per object, and Normal-state display sets (palette-only fades,
 * cached-object reuse) must keep the composition instead of blanking it.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class PgsCompositionParserTest {

  private companion object {
    const val WHITE = 0xFFFFFFFF.toInt()
    const val FADED_WHITE = 0x80FFFFFF.toInt()
    const val YELLOW = 0xFFFFF000.toInt()
    const val GREEN_BT709 = 0xFF00D800.toInt()
    const val GREEN_BT601 = 0xFF00FF01.toInt()

    val WHITE_ENTRY = intArrayOf(1, 235, 128, 128, 255)
    val YELLOW_ENTRY = intArrayOf(2, 210, 146, 16, 255)

    const val STATE_NORMAL = 0x00
    const val STATE_EPOCH_START = 0x80
  }

  private class Buf {
    private val out = ByteArrayOutputStream()

    fun u8(value: Int) = apply { out.write(value) }

    fun u16(value: Int) = apply {
      out.write(value ushr 8)
      out.write(value)
    }

    fun u24(value: Int) = apply {
      out.write(value ushr 16)
      out.write(value ushr 8)
      out.write(value)
    }

    fun raw(bytes: ByteArray) = apply { out.write(bytes) }

    fun build(): ByteArray = out.toByteArray()
  }

  private fun segment(type: Int, payload: ByteArray): ByteArray = Buf().u8(type).u16(payload.size).raw(payload).build()

  private fun objectRef(id: Int, x: Int, y: Int, cropped: Boolean = false): ByteArray = Buf()
    .u16(id)
    .u8(0) // Window id.
    .u8(if (cropped) 0x80 else 0)
    .u16(x)
    .u16(y)
    .raw(if (cropped) ByteArray(8) else ByteArray(0)) // Crop rectangle.
    .build()

  private fun pcs(planeWidth: Int, planeHeight: Int, state: Int, vararg refs: ByteArray): ByteArray {
    val payload = Buf()
      .u16(planeWidth)
      .u16(planeHeight)
      .u8(0x10) // Frame rate.
      .u16(0) // Composition number.
      .u8(state)
      .u8(0) // Palette update flag.
      .u8(0) // Palette id.
      .u8(refs.size)
    refs.forEach { payload.raw(it) }
    return segment(0x16, payload.build())
  }

  private fun pds(vararg entries: IntArray): ByteArray {
    val payload = Buf().u8(0).u8(0) // Palette id, version.
    entries.forEach { e -> payload.u8(e[0]).u8(e[1]).u8(e[2]).u8(e[3]).u8(e[4]) }
    return segment(0x14, payload.build())
  }

  private fun ods(id: Int, width: Int, height: Int, rle: ByteArray): ByteArray = segment(
    0x15,
    Buf().u16(id).u8(0).u8(0xC0).u24(rle.size + 4).u16(width).u16(height).raw(rle).build()
  )

  /** RLE for a solid bitmap: one literal palette-index byte per pixel. */
  private fun solidRle(width: Int, height: Int, colorIndex: Int): ByteArray = ByteArray(width * height) { colorIndex.toByte() }

  private fun end(): ByteArray = segment(0x80, ByteArray(0))

  private fun displaySet(vararg segments: ByteArray): ByteArray {
    val out = ByteArrayOutputStream()
    segments.forEach { out.write(it) }
    return out.toByteArray()
  }

  private fun parseCues(parser: PgsCompositionParser, sample: ByteArray): List<Cue> {
    val outputs = mutableListOf<CuesWithTiming>()
    parser.parse(sample, SubtitleParser.OutputOptions.allCues()) { outputs.add(it) }
    assertEquals(1, outputs.size)
    return outputs[0].cues
  }

  /** Epoch-start display set: white 4x2 object at (100, 900) and yellow 6x3 object at (200, 100). */
  private fun twoObjectEpochStart(): ByteArray = displaySet(
    pcs(1920, 1080, STATE_EPOCH_START, objectRef(1, 100, 900), objectRef(2, 200, 100)),
    pds(WHITE_ENTRY, YELLOW_ENTRY),
    ods(1, 4, 2, solidRle(4, 2, 1)),
    ods(2, 6, 3, solidRle(6, 3, 2)),
    end()
  )

  @Test
  fun twoCompositionObjectsProduceIndependentlyPositionedCues() {
    val cues = parseCues(PgsCompositionParser(), twoObjectEpochStart())

    assertEquals(2, cues.size)
    val (dialogue, sign) = cues
    assertEquals(100f / 1920f, dialogue.position, 1e-6f)
    assertEquals(900f / 1080f, dialogue.line, 1e-6f)
    assertEquals(4f / 1920f, dialogue.size, 1e-6f)
    assertEquals(2f / 1080f, dialogue.bitmapHeight, 1e-6f)
    assertEquals(WHITE, dialogue.bitmap!!.getPixel(0, 0))
    assertEquals(200f / 1920f, sign.position, 1e-6f)
    assertEquals(100f / 1080f, sign.line, 1e-6f)
    assertEquals(6, sign.bitmap!!.width)
    assertEquals(3, sign.bitmap!!.height)
    assertEquals(YELLOW, sign.bitmap!!.getPixel(5, 2))
  }

  @Test
  fun paletteOnlyFadeUpdateKeepsBothObjectsAndPreservesUnsentEntries() {
    val parser = PgsCompositionParser()
    parseCues(parser, twoObjectEpochStart())

    // Normal-state fade step: same references, only the white entry's alpha changes.
    val cues = parseCues(
      parser,
      displaySet(
        pcs(1920, 1080, STATE_NORMAL, objectRef(1, 100, 900), objectRef(2, 200, 100)),
        pds(intArrayOf(1, 235, 128, 128, 128)),
        end()
      )
    )

    assertEquals(2, cues.size)
    assertEquals(FADED_WHITE, cues[0].bitmap!!.getPixel(0, 0))
    // The yellow entry was not resent; an in-place palette update must preserve it.
    assertEquals(YELLOW, cues[1].bitmap!!.getPixel(0, 0))
  }

  @Test
  fun zeroObjectDisplaySetClearsTheComposition() {
    val parser = PgsCompositionParser()
    parseCues(parser, twoObjectEpochStart())

    val cues = parseCues(parser, displaySet(pcs(1920, 1080, STATE_NORMAL), end()))

    assertTrue(cues.isEmpty())
  }

  @Test
  fun epochStartReleasesCachedObjects() {
    val parser = PgsCompositionParser()
    parseCues(parser, twoObjectEpochStart())

    // New epoch referencing an object it never defines: nothing may leak across.
    val cues = parseCues(
      parser,
      displaySet(pcs(1920, 1080, STATE_EPOCH_START, objectRef(1, 100, 900)), end())
    )

    assertTrue(cues.isEmpty())
  }

  @Test
  fun resetDropsEpochState() {
    val parser = PgsCompositionParser()
    parseCues(parser, twoObjectEpochStart())

    parser.reset()
    val cues = parseCues(
      parser,
      displaySet(pcs(1920, 1080, STATE_NORMAL, objectRef(1, 100, 900)), end())
    )

    assertTrue(cues.isEmpty())
  }

  @Test
  fun fragmentedObjectReassembles() {
    val rle = solidRle(4, 2, 1)
    val first = segment(
      0x15,
      Buf().u16(1).u8(0).u8(0x80).u24(rle.size + 4).u16(4).u16(2).raw(rle.copyOfRange(0, 3)).build()
    )
    val continuation = segment(
      0x15,
      Buf().u16(1).u8(0).u8(0x40).raw(rle.copyOfRange(3, rle.size)).build()
    )

    val cues = parseCues(
      PgsCompositionParser(),
      displaySet(pcs(1920, 1080, STATE_EPOCH_START, objectRef(1, 0, 0)), pds(WHITE_ENTRY), first, continuation, end())
    )

    assertEquals(1, cues.size)
    assertEquals(WHITE, cues[0].bitmap!!.getPixel(3, 1))
  }

  @Test
  fun croppedFirstReferenceDoesNotCorruptTheSecond() {
    val cues = parseCues(
      PgsCompositionParser(),
      displaySet(
        pcs(1920, 1080, STATE_EPOCH_START, objectRef(1, 100, 900, cropped = true), objectRef(2, 200, 100)),
        pds(WHITE_ENTRY, YELLOW_ENTRY),
        ods(1, 4, 2, solidRle(4, 2, 1)),
        ods(2, 6, 3, solidRle(6, 3, 2)),
        end()
      )
    )

    assertEquals(2, cues.size)
    assertEquals(200f / 1920f, cues[1].position, 1e-6f)
    assertEquals(100f / 1080f, cues[1].line, 1e-6f)
  }

  @Test
  fun runLengthEncodedBitmapsDecode() {
    // Short-form color run (16 white pixels), then a long-form run (100 pixels).
    val shortRun = byteArrayOf(0x00, 0x90.toByte(), 0x01)
    val longRun = byteArrayOf(0x00, 0xC0.toByte(), 0x64, 0x01)

    val cues = parseCues(
      PgsCompositionParser(),
      displaySet(
        pcs(1920, 1080, STATE_EPOCH_START, objectRef(1, 0, 0), objectRef(2, 0, 200)),
        pds(WHITE_ENTRY),
        ods(1, 16, 1, shortRun),
        ods(2, 100, 1, longRun),
        end()
      )
    )

    assertEquals(2, cues.size)
    assertEquals(WHITE, cues[0].bitmap!!.getPixel(15, 0))
    assertEquals(WHITE, cues[1].bitmap!!.getPixel(99, 0))
  }

  @Test
  fun zlibCompressedSampleParses() {
    val deflater = Deflater()
    deflater.setInput(twoObjectEpochStart())
    deflater.finish()
    val compressed = ByteArray(4096)
    val length = deflater.deflate(compressed)
    deflater.end()

    val cues = parseCues(PgsCompositionParser(), compressed.copyOf(length))

    assertEquals(2, cues.size)
  }

  @Test
  fun paletteMatrixFollowsPlaneHeight() {
    val greenEntry = intArrayOf(1, 145, 34, 54, 255)

    val hdCues = parseCues(
      PgsCompositionParser(),
      displaySet(
        pcs(1920, 1080, STATE_EPOCH_START, objectRef(1, 0, 0)),
        pds(greenEntry),
        ods(1, 1, 1, solidRle(1, 1, 1)),
        end()
      )
    )
    val sdCues = parseCues(
      PgsCompositionParser(),
      displaySet(
        pcs(720, 576, STATE_EPOCH_START, objectRef(1, 0, 0)),
        pds(greenEntry),
        ods(1, 1, 1, solidRle(1, 1, 1)),
        end()
      )
    )

    assertEquals(GREEN_BT709, hdCues[0].bitmap!!.getPixel(0, 0))
    assertEquals(GREEN_BT601, sdCues[0].bitmap!!.getPixel(0, 0))
  }
}
