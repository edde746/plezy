package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.DefaultExtractorInput
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.parser.AssSubtitleParserFactory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Regression coverage for Matroska files whose SeekHead references Tracks after the Clusters. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MatroskaLateTracksTest {

  private class CapturedTrack(val type: Int) : TrackOutput {
    var format: Format? = null
    var sampleCount = 0

    override fun format(format: Format) {
      this.format = format
    }

    override fun sampleData(input: DataReader, length: Int, allowEndOfInput: Boolean, sampleDataPart: Int): Int = input.read(ByteArray(length), 0, length)

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
      data.skipBytes(length)
    }

    override fun sampleMetadata(timeUs: Long, flags: Int, size: Int, offset: Int, cryptoData: TrackOutput.CryptoData?) {
      sampleCount++
    }
  }

  private class CapturingExtractorOutput : ExtractorOutput {
    val tracks = mutableMapOf<Int, CapturedTrack>()

    override fun track(id: Int, type: Int): TrackOutput = tracks.getOrPut(id) { CapturedTrack(type) }
    override fun endTracks() = Unit
    override fun seekMap(seekMap: SeekMap) = Unit
  }

  private class ByteArrayDataReader(private val data: ByteArray) : DataReader {
    var position = 0L

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
      if (position >= data.size) return C.RESULT_END_OF_INPUT
      val bytesRead = minOf(length, data.size - position.toInt())
      data.copyInto(buffer, offset, position.toInt(), position.toInt() + bytesRead)
      position += bytesRead
      return bytesRead
    }
  }

  private fun fixtureData(): ByteArray = checkNotNull(javaClass.getResourceAsStream("/matroska_tracks_at_end.mkv")) {
    "fixture matroska_tracks_at_end.mkv missing from test resources"
  }.use { it.readBytes() }

  private fun extractFixture(): CapturingExtractorOutput {
    val data = fixtureData()
    val assHandler = AssHandler()
    val extractor = ZlibMatroskaExtractor(AssSubtitleParserFactory(assHandler), assHandler)
    val output = CapturingExtractorOutput()
    extractor.init(output)

    val reader = ByteArrayDataReader(data)
    var input: ExtractorInput = DefaultExtractorInput(reader, 0, data.size.toLong())
    val seekPosition = PositionHolder()
    repeat(100_000) {
      when (extractor.read(input, seekPosition)) {
        Extractor.RESULT_END_OF_INPUT -> return output
        Extractor.RESULT_SEEK -> {
          reader.position = seekPosition.position
          input = DefaultExtractorInput(reader, seekPosition.position, data.size.toLong())
        }
      }
    }
    error("extractor did not reach end of input")
  }

  @Test
  fun extractsSamplesWhenSeekHeadReferencesTracksAfterClusters() {
    val output = extractFixture()

    assertEquals(2, output.tracks.size)
    assertEquals(setOf(C.TRACK_TYPE_VIDEO, C.TRACK_TYPE_AUDIO), output.tracks.values.map { it.type }.toSet())
    output.tracks.values.forEach { track ->
      assertNotNull(track.format)
      assertTrue("expected extracted samples for track type ${track.type}", track.sampleCount > 0)
    }
  }
}
