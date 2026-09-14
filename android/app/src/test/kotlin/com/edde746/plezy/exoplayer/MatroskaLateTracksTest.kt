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
    val timesUs = mutableListOf<Long>()
    var format: Format? = null

    val sampleCount: Int
      get() = timesUs.size

    override fun format(format: Format) {
      this.format = format
    }

    override fun sampleData(input: DataReader, length: Int, allowEndOfInput: Boolean, sampleDataPart: Int): Int = input.read(ByteArray(length), 0, length)

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
      data.skipBytes(length)
    }

    override fun sampleMetadata(timeUs: Long, flags: Int, size: Int, offset: Int, cryptoData: TrackOutput.CryptoData?) {
      timesUs.add(timeUs)
    }
  }

  private class CapturingExtractorOutput : ExtractorOutput {
    val tracks = mutableMapOf<Int, CapturedTrack>()
    val seekMaps = mutableListOf<SeekMap>()

    override fun track(id: Int, type: Int): TrackOutput = tracks.getOrPut(id) { CapturedTrack(type) }
    override fun endTracks() = Unit
    override fun seekMap(seekMap: SeekMap) {
      seekMaps.add(seekMap)
    }
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

  private fun readToEnd(extractor: Extractor, reader: ByteArrayDataReader, length: Long) {
    var input: ExtractorInput = DefaultExtractorInput(reader, reader.position, length)
    val seekPosition = PositionHolder()
    repeat(100_000) {
      when (extractor.read(input, seekPosition)) {
        Extractor.RESULT_END_OF_INPUT -> return
        Extractor.RESULT_SEEK -> {
          reader.position = seekPosition.position
          input = DefaultExtractorInput(reader, seekPosition.position, length)
        }
      }
    }
    error("extractor did not reach end of input")
  }

  @Test
  fun extractsSamplesWhenSeekHeadReferencesTracksAfterClusters() {
    val assHandler = AssHandler()
    val extractor = ZlibMatroskaExtractor(AssSubtitleParserFactory(assHandler), assHandler)
    val output = CapturingExtractorOutput()
    extractor.init(output)

    val data = fixtureData()
    readToEnd(extractor, ByteArrayDataReader(data), data.size.toLong())

    assertEquals(2, output.tracks.size)
    assertEquals(setOf(C.TRACK_TYPE_VIDEO, C.TRACK_TYPE_AUDIO), output.tracks.values.map { it.type }.toSet())
    output.tracks.values.forEach { track ->
      assertNotNull(track.format)
      assertTrue("expected extracted samples for track type ${track.type}", track.sampleCount > 0)
    }
  }

  /**
   * media3 1.11.0 builds the Matroska seek map at the end of the Cues element, which for
   * tracks-after-clusters files is before the Tracks element parsed — the map then permanently
   * reports unseekable and resolves every seek to byte 0, snapping playback to the start
   * (#1969; upstream androidx/media #3377).
   * The production stack must repair it through the per-track cue lookups.
   */
  @Test
  fun seeksViaCuesWhenSeekMapIsBuiltBeforeTracks() {
    val assHandler = AssHandler()
    val extractor = CuelessSeekExtractorWrapper(ZlibMatroskaExtractor(AssSubtitleParserFactory(assHandler), assHandler))
    val output = CapturingExtractorOutput()
    extractor.init(output)

    val data = fixtureData()
    val reader = ByteArrayDataReader(data)
    readToEnd(extractor, reader, data.size.toLong())

    assertEquals(1, output.seekMaps.size)
    val seekMap = output.seekMaps.single()
    assertTrue("tracks-after-clusters file with Cues must be seekable", seekMap.isSeekable)

    val points = seekMap.getSeekPoints(500_000L)
    // Cue-based resolution snaps to the fixture's only cue point (t=0); a byte-proportional
    // estimate would return the requested time instead.
    assertEquals(0L, points.first.timeUs)
    val position = points.first.position
    val clusterId = byteArrayOf(0x1F, 0x43, 0xB6.toByte(), 0x75)
    assertTrue(
      "seek position $position must point at a Cluster element",
      data.copyOfRange(position.toInt(), position.toInt() + 4).contentEquals(clusterId)
    )

    output.tracks.values.forEach { it.timesUs.clear() }
    extractor.seek(position, points.first.timeUs)
    reader.position = position
    readToEnd(extractor, reader, data.size.toLong())

    output.tracks.values.forEach { track ->
      assertTrue("expected extracted samples after seek for track type ${track.type}", track.sampleCount > 0)
      assertEquals(points.first.timeUs, track.timesUs.first())
    }
  }
}
