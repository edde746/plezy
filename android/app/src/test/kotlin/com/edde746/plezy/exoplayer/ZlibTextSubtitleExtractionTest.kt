package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.DefaultExtractorInput
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import androidx.media3.extractor.text.CueDecoder
import androidx.media3.extractor.text.DefaultSubtitleParserFactory
import com.edde746.plezy.libass.media.AssHandler
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Extracts the committed fixtures — one ASS subtitle track muxed by mkvmerge with
 * `--compression 0:zlib` (ContentCompAlgo 0, the anime-release convention that
 * broke #2023) and an identical uncompressed mux — and verifies the zlib block
 * payloads are inflated *before* MatroskaExtractor's subtitle sample assembly.
 *
 * Regenerate with:
 *   mkvmerge -o zlib_ssa.mkv --compression 0:zlib repro.ass
 *   mkvmerge -o plain_ssa.mkv --compression 0:none repro.ass
 * where repro.ass holds 45 two-second "SUBTITLE LINE N (H:MM:SS.00)" events.
 *
 * Robolectric provides real android.util/android.os implementations —
 * MatroskaExtractor uses SparseArray and CueDecoder uses Parcel, both of which
 * are no-op stubs on plain JVM.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ZlibTextSubtitleExtractionTest {

  private class CapturedSample(val timeUs: Long, val data: ByteArray)

  private class FakeTrackOutput : TrackOutput {
    val formats = mutableListOf<androidx.media3.common.Format>()
    val samples = mutableListOf<CapturedSample>()
    private var buf = ByteArray(64 * 1024)
    private var bufLen = 0

    override fun format(format: androidx.media3.common.Format) {
      formats.add(format)
    }

    override fun sampleData(input: DataReader, length: Int, allowEndOfInput: Boolean, sampleDataPart: Int): Int {
      ensureCapacity(bufLen + length)
      val read = input.read(buf, bufLen, length)
      if (read > 0) bufLen += read
      return read
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
      ensureCapacity(bufLen + length)
      data.readBytes(buf, bufLen, length)
      bufLen += length
    }

    override fun sampleMetadata(timeUs: Long, flags: Int, size: Int, offset: Int, cryptoData: TrackOutput.CryptoData?) {
      val start = bufLen - offset - size
      samples.add(CapturedSample(timeUs, buf.copyOfRange(start, start + size)))
      if (offset == 0) bufLen = 0
    }

    private fun ensureCapacity(needed: Int) {
      if (buf.size < needed) buf = buf.copyOf(maxOf(needed, buf.size * 2))
    }
  }

  private class FakeExtractorOutput : ExtractorOutput {
    val tracks = mutableMapOf<Int, FakeTrackOutput>()

    override fun track(id: Int, type: Int): TrackOutput = tracks.getOrPut(id) { FakeTrackOutput() }
    override fun endTracks() {}
    override fun seekMap(seekMap: SeekMap) {}
  }

  private class ByteArrayDataReader(private val data: ByteArray) : DataReader {
    var position = 0L

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
      if (position >= data.size) return C.RESULT_END_OF_INPUT
      val toRead = minOf(length, data.size - position.toInt())
      System.arraycopy(data, position.toInt(), buffer, offset, toRead)
      position += toRead
      return toRead
    }
  }

  private fun extract(resource: String): FakeExtractorOutput {
    val data = checkNotNull(javaClass.getResourceAsStream(resource)) {
      "fixture $resource missing from test resources"
    }.use { it.readBytes() }

    // DefaultSubtitleParserFactory (not AssSubtitleParserFactory) so the SSA track
    // transcodes to decodable media3 cues instead of loading native libass.
    val extractor = ZlibMatroskaExtractor(DefaultSubtitleParserFactory(), AssHandler())
    val output = FakeExtractorOutput()
    extractor.init(output)

    val reader = ByteArrayDataReader(data)
    var input = DefaultExtractorInput(reader, 0, data.size.toLong())
    val seekPosition = PositionHolder()
    while (true) {
      when (extractor.read(input, seekPosition)) {
        Extractor.RESULT_END_OF_INPUT -> return output
        Extractor.RESULT_SEEK -> {
          reader.position = seekPosition.position
          input = DefaultExtractorInput(reader, seekPosition.position, data.size.toLong())
        }
        else -> {}
      }
    }
  }

  private class DecodedCue(val startTimeUs: Long, val durationUs: Long, val text: String)

  private fun decodeCues(output: FakeExtractorOutput): List<DecodedCue> {
    val track = output.tracks.values.single()
    val format = track.formats.last()
    assertEquals(MimeTypes.APPLICATION_MEDIA3_CUES, format.sampleMimeType)
    assertEquals(MimeTypes.TEXT_SSA, format.codecs)
    val decoder = CueDecoder()
    return track.samples.map { sample ->
      val cues = decoder.decode(sample.timeUs, sample.data, 0, sample.data.size)
      DecodedCue(
        cues.startTimeUs,
        cues.durationUs,
        cues.cues.joinToString("\n") { it.text.toString() }
      )
    }
  }

  @Test
  fun zlibCompressedAssDialogueIsInflatedToParseableCues() {
    val cues = decodeCues(extract("/zlib_ssa.mkv"))

    assertEquals(45, cues.size)
    assertEquals("SUBTITLE LINE 1 (0:00:00.00)", cues.first().text)
    assertEquals(0L, cues.first().startTimeUs)
    assertEquals(2_000_000L, cues.first().durationUs)
    assertEquals("SUBTITLE LINE 45 (0:01:28.00)", cues.last().text)
    assertEquals(88_000_000L, cues.last().startTimeUs)
    cues.forEachIndexed { index, cue ->
      assertEquals(index * 2_000_000L, cue.startTimeUs)
      assertTrue("cue $index text: ${cue.text}", cue.text.startsWith("SUBTITLE LINE ${index + 1} "))
    }
  }

  @Test
  fun zlibAndPlainMuxesProduceIdenticalCues() {
    val zlib = decodeCues(extract("/zlib_ssa.mkv"))
    val plain = decodeCues(extract("/plain_ssa.mkv"))

    assertEquals(plain.size, zlib.size)
    plain.zip(zlib).forEachIndexed { index, (expected, actual) ->
      assertEquals("startTimeUs of cue $index", expected.startTimeUs, actual.startTimeUs)
      assertEquals("durationUs of cue $index", expected.durationUs, actual.durationUs)
      assertEquals("text of cue $index", expected.text, actual.text)
    }
  }
}
