package com.edde746.plezy.exoplayer

import android.graphics.Bitmap
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.text.Cue
import androidx.media3.common.util.Consumer
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.extractor.text.CuesWithTiming
import androidx.media3.extractor.text.SubtitleParser
import java.util.zip.Inflater
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Delegates to [delegate] for every subtitle format except PGS, which is handled by
 * [PgsCompositionParser] because media3's PgsParser drops all but one composition object (#1953).
 */
@UnstableApi
class PgsSubtitleParserFactory(private val delegate: SubtitleParser.Factory) : SubtitleParser.Factory {
  override fun supportsFormat(format: Format): Boolean = delegate.supportsFormat(format)

  override fun getCueReplacementBehavior(format: Format): Int = delegate.getCueReplacementBehavior(format)

  override fun create(format: Format): SubtitleParser = if (format.sampleMimeType == MimeTypes.APPLICATION_PGS) PgsCompositionParser() else delegate.create(format)
}

/**
 * PGS subtitle parser that renders every composition object in a display set.
 *
 * media3's PgsParser keeps one bitmap buffer and only the first composition object's
 * coordinates, so a display set with two simultaneous images (dialogue plus a sign or
 * song caption) draws the last object at the first object's position and loses the rest.
 * It is also stateless across display sets, so Normal-state sets that only update the
 * palette (fades) or reuse cached objects blank the screen.
 *
 * This parser follows FFmpeg's pgssubdec model, which Kodi/mpv/VLC share: objects and
 * palettes are cached per epoch keyed by id, any non-Normal composition state releases
 * the caches, palette sections update entries in place, and the display-end section
 * composes one cue per object reference in the presentation. Colors use limited-range
 * BT.709 for HD planes and BT.601 otherwise, matching FFmpeg output.
 */
@UnstableApi
class PgsCompositionParser : SubtitleParser {

  companion object {
    private const val SECTION_TYPE_PALETTE = 0x14
    private const val SECTION_TYPE_OBJECT = 0x15
    private const val SECTION_TYPE_PRESENTATION = 0x16
    private const val SECTION_TYPE_END = 0x80

    // Blu-ray spec limits, as enforced by FFmpeg's pgssubdec.
    private const val MAX_OBJECT_REFS = 2
    private const val MAX_EPOCH_OBJECTS = 64
    private const val MAX_EPOCH_PALETTES = 8

    // Bounds object dimensions when a damaged stream declares them before any
    // presentation section has established the composition plane.
    private const val MAX_PLANE_DIMENSION = 4096
  }

  private class PgsObject {
    var width = 0
    var height = 0
    var rle = ByteArray(0)
    var received = 0

    val complete: Boolean
      get() = rle.isNotEmpty() && received == rle.size
  }

  private class ObjectRef(val objectId: Int, val x: Int, val y: Int)

  private val buffer = ParsableByteArray()
  private val inflatedBuffer = ParsableByteArray()
  private var inflater: Inflater? = null

  // Epoch state: objects and palettes persist across display sets until a
  // non-Normal composition state starts a new epoch or [reset] follows a seek.
  private val objects = HashMap<Int, PgsObject>()
  private val palettes = HashMap<Int, IntArray>()

  // Latest presentation composition.
  private var planeWidth = 0
  private var planeHeight = 0
  private var paletteId = 0
  private var objectRefs = emptyList<ObjectRef>()

  override fun getCueReplacementBehavior(): Int = Format.CUE_REPLACEMENT_BEHAVIOR_REPLACE

  override fun reset() {
    objects.clear()
    palettes.clear()
    objectRefs = emptyList()
    planeWidth = 0
    planeHeight = 0
    paletteId = 0
  }

  override fun parse(
    data: ByteArray,
    offset: Int,
    length: Int,
    outputOptions: SubtitleParser.OutputOptions,
    output: Consumer<CuesWithTiming>
  ) {
    buffer.reset(data, offset + length)
    buffer.setPosition(offset)
    val inflater = this.inflater ?: Inflater().also { this.inflater = it }
    if (Util.maybeInflate(buffer, inflatedBuffer, inflater)) {
      buffer.reset(inflatedBuffer.data, inflatedBuffer.limit())
    }
    val cues = ArrayList<Cue>()
    while (buffer.bytesLeft() >= 3) {
      readNextSection(cues)
    }
    output.accept(
      CuesWithTiming(
        cues,
        C.TIME_UNSET, // startTimeUs
        C.TIME_UNSET // durationUs
      )
    )
  }

  private fun readNextSection(cues: MutableList<Cue>) {
    val sectionType = buffer.readUnsignedByte()
    val sectionLength = buffer.readUnsignedShort()
    val nextSectionPosition = buffer.position + sectionLength
    if (nextSectionPosition > buffer.limit()) {
      buffer.setPosition(buffer.limit())
      return
    }
    when (sectionType) {
      SECTION_TYPE_PALETTE -> parsePalette(sectionLength)
      SECTION_TYPE_OBJECT -> parseObject(sectionLength)
      SECTION_TYPE_PRESENTATION -> parsePresentation(sectionLength)
      SECTION_TYPE_END -> composeCues(cues)
      // Window sections (0x17) carry no information the composition needs.
    }
    buffer.setPosition(nextSectionPosition)
  }

  private fun parsePresentation(sectionLength: Int) {
    if (sectionLength < 11) return
    planeWidth = buffer.readUnsignedShort()
    planeHeight = buffer.readUnsignedShort()
    buffer.skipBytes(3) // Frame rate (1), composition number (2).
    val compositionState = buffer.readUnsignedByte()
    if (compositionState and 0xC0 != 0) {
      // Epoch start/acquisition point display sets carry complete data; previous
      // epoch objects and palettes are released.
      objects.clear()
      palettes.clear()
    }
    buffer.skipBytes(1) // Palette update flag.
    paletteId = buffer.readUnsignedByte()
    val objectCount = buffer.readUnsignedByte()
    var remaining = sectionLength - 11
    val refs = ArrayList<ObjectRef>(min(objectCount, MAX_OBJECT_REFS))
    for (i in 0 until min(objectCount, MAX_OBJECT_REFS)) {
      if (remaining < 8) break
      val objectId = buffer.readUnsignedShort()
      buffer.skipBytes(1) // Window id.
      val flags = buffer.readUnsignedByte()
      val x = buffer.readUnsignedShort()
      val y = buffer.readUnsignedShort()
      remaining -= 8
      if (flags and 0x80 != 0) {
        // Cropped object: skip the crop rectangle. Like FFmpeg, the crop itself
        // is not applied, but the following reference must parse correctly.
        if (remaining < 8) break
        buffer.skipBytes(8)
        remaining -= 8
      }
      refs.add(ObjectRef(objectId, x, y))
    }
    objectRefs = refs
  }

  private fun parsePalette(sectionLength: Int) {
    if (sectionLength % 5 != 2) return
    val id = buffer.readUnsignedByte()
    buffer.skipBytes(1) // Palette version.
    if (palettes.size >= MAX_EPOCH_PALETTES && id !in palettes) return
    // Entries update in place: fade ramps resend only the entries that changed.
    val palette = palettes.getOrPut(id) { IntArray(256) }
    val bt709 = planeHeight <= 0 || planeHeight > 576
    repeat(sectionLength / 5) {
      val index = buffer.readUnsignedByte()
      val y = buffer.readUnsignedByte()
      val cr = buffer.readUnsignedByte()
      val cb = buffer.readUnsignedByte()
      val alpha = buffer.readUnsignedByte()
      palette[index] = argbColor(y, cb, cr, alpha, bt709)
    }
  }

  private fun parseObject(sectionLength: Int) {
    if (sectionLength < 4) return
    val id = buffer.readUnsignedShort()
    if (objects.size >= MAX_EPOCH_OBJECTS && id !in objects) return
    buffer.skipBytes(1) // Object version.
    val isFirstFragment = buffer.readUnsignedByte() and 0x80 != 0
    var remaining = sectionLength - 4
    val obj = objects.getOrPut(id) { PgsObject() }
    if (isFirstFragment) {
      if (remaining < 7) return
      val rleLength = buffer.readUnsignedInt24() - 4 // Length includes the width/height fields.
      val width = buffer.readUnsignedShort()
      val height = buffer.readUnsignedShort()
      remaining -= 7
      val maxWidth = if (planeWidth > 0) planeWidth else MAX_PLANE_DIMENSION
      val maxHeight = if (planeHeight > 0) planeHeight else MAX_PLANE_DIMENSION
      if (rleLength <= 0 || width !in 1..maxWidth || height !in 1..maxHeight) {
        obj.rle = ByteArray(0)
        obj.received = 0
        return
      }
      obj.width = width
      obj.height = height
      obj.rle = ByteArray(rleLength)
      obj.received = 0
    }
    val bytesToRead = min(remaining, obj.rle.size - obj.received)
    if (bytesToRead > 0) {
      buffer.readBytes(obj.rle, obj.received, bytesToRead)
      obj.received += bytesToRead
    }
  }

  private fun composeCues(cues: MutableList<Cue>) {
    if (planeWidth <= 0 || planeHeight <= 0) return
    val palette = palettes[paletteId] ?: return
    for (ref in objectRefs) {
      // Skip references to missing or incomplete objects (damaged stream, or a
      // post-seek Normal set whose epoch data was never observed).
      val obj = objects[ref.objectId] ?: continue
      if (!obj.complete) continue
      cues.add(
        Cue.Builder()
          .setBitmap(decodeBitmap(obj, palette))
          .setPosition(ref.x.toFloat() / planeWidth)
          .setPositionAnchor(Cue.ANCHOR_TYPE_START)
          .setLine(ref.y.toFloat() / planeHeight, Cue.LINE_TYPE_FRACTION)
          .setLineAnchor(Cue.ANCHOR_TYPE_START)
          .setSize(obj.width.toFloat() / planeWidth)
          .setBitmapHeight(obj.height.toFloat() / planeHeight)
          .build()
      )
    }
  }

  private fun decodeBitmap(obj: PgsObject, palette: IntArray): Bitmap {
    val pixels = IntArray(obj.width * obj.height)
    val rle = obj.rle
    var input = 0
    var output = 0
    while (input < rle.size && output < pixels.size) {
      val first = rle[input++].toInt() and 0xFF
      if (first != 0) {
        pixels[output++] = palette[first]
        continue
      }
      if (input >= rle.size) break
      val flags = rle[input++].toInt() and 0xFF
      if (flags == 0) continue // End-of-line marker.
      var run = flags and 0x3F
      if (flags and 0x40 != 0) {
        if (input >= rle.size) break
        run = run shl 8 or (rle[input++].toInt() and 0xFF)
      }
      val color = if (flags and 0x80 != 0) {
        if (input >= rle.size) break
        palette[rle[input++].toInt() and 0xFF]
      } else {
        palette[0]
      }
      val end = min(output + run, pixels.size)
      pixels.fill(color, output, end)
      output = end
    }
    return Bitmap.createBitmap(pixels, obj.width, obj.height, Bitmap.Config.ARGB_8888)
  }

  private fun argbColor(y: Int, cb: Int, cr: Int, alpha: Int, bt709: Boolean): Int {
    val yc = (y - 16) * (255f / 219f)
    val cbc = (cb - 128) * (255f / 224f)
    val crc = (cr - 128) * (255f / 224f)
    val r: Float
    val g: Float
    val b: Float
    if (bt709) {
      r = yc + 1.5747f * crc
      g = yc - 0.1873f * cbc - 0.4682f * crc
      b = yc + 1.8556f * cbc
    } else {
      r = yc + 1.402f * crc
      g = yc - 0.34414f * cbc - 0.71414f * crc
      b = yc + 1.772f * cbc
    }
    return (alpha shl 24) or
      (r.roundToInt().coerceIn(0, 255) shl 16) or
      (g.roundToInt().coerceIn(0, 255) shl 8) or
      b.roundToInt().coerceIn(0, 255)
  }
}
