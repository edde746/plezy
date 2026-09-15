package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.DefaultExtractorInput
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.parser.AssSubtitleParserFactory
import java.io.EOFException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Extracts the committed fixture (1s 440Hz sine, AAC-LC 48kHz stereo, LATM/LOAS
 * muxed into MKV as A_MS/ACM tag 0x1602) and verifies direct Matroska playback
 * unwraps LOAS frames to raw AAC with a synthesized AudioSpecificConfig.
 *
 * Robolectric provides real android.util.* implementations — MatroskaExtractor
 * stores tracks in a SparseArray, which is a no-op stub on plain JVM.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MatroskaLatmSupportTest {

  private class CapturedSample(val timeUs: Long, val flags: Int, val data: ByteArray)

  private class FakeTrackOutput : TrackOutput {
    val formats = mutableListOf<Format>()
    val samples = mutableListOf<CapturedSample>()
    private var buf = ByteArray(64 * 1024)
    private var bufLen = 0

    override fun format(format: Format) {
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
      samples.add(CapturedSample(timeUs, flags, buf.copyOfRange(start, start + size)))
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

  private fun fixtureData(): ByteArray = checkNotNull(javaClass.getResourceAsStream("/latm_loas.mkv")) {
    "fixture latm_loas.mkv missing from test resources"
  }.use { it.readBytes() }

  private fun loasFrames(count: Int): List<ByteArray> {
    val data = fixtureData()
    val frames = mutableListOf<ByteArray>()
    var position = 0
    while (position <= data.size - 3 && frames.size < count) {
      val isSyncWord = (data[position].toInt() and 0xFF) == 0x56 &&
        (data[position + 1].toInt() and 0xE0) == 0xE0
      if (isSyncWord) {
        val payloadSize = ((data[position + 1].toInt() and 0x1F) shl 8) or
          (data[position + 2].toInt() and 0xFF)
        val end = position + 3 + payloadSize
        if (payloadSize > 0 && end <= data.size) {
          frames.add(data.copyOfRange(position, end))
          position = end
          continue
        }
      }
      position++
    }
    check(frames.size == count) { "expected $count LOAS frames, found ${frames.size}" }
    return frames
  }

  private fun extractFixture(): FakeExtractorOutput {
    val data = fixtureData()

    val assHandler = AssHandler()
    val extractor = ZlibMatroskaExtractor(AssSubtitleParserFactory(assHandler), assHandler)
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

  @Test
  fun unwrapsLoasAcmTrackToRawAac() {
    val output = extractFixture()

    assertEquals(1, output.tracks.size)
    val track = output.tracks.values.first()

    // No audio/x-unknown format may reach the queue; the LATM-derived AAC
    // format must carry the AudioSpecificConfig for MediaCodec.
    assertFalse(track.formats.any { it.sampleMimeType == MimeTypes.AUDIO_UNKNOWN })
    val format = track.formats.last()
    assertEquals(MimeTypes.AUDIO_AAC, format.sampleMimeType)
    assertEquals(48000, format.sampleRate)
    assertEquals(2, format.channelCount)
    assertTrue(format.initializationData.isNotEmpty())
    assertTrue(format.initializationData[0].isNotEmpty())

    // 1s at 48kHz / 1024 samples per AAC frame ≈ 47 frames
    assertTrue("expected ~47 samples, got ${track.samples.size}", track.samples.size in 40..55)

    // Raw AAC payloads: smaller than the LOAS wrapping, no LOAS syncword,
    // keyframe-flagged, monotonic timestamps spanning ~1s.
    var prevTimeUs = Long.MIN_VALUE
    for (sample in track.samples) {
      assertTrue(sample.data.isNotEmpty())
      val isLoasSync = sample.data.size >= 2 &&
        (sample.data[0].toInt() and 0xFF) == 0x56 &&
        (sample.data[1].toInt() and 0xE0) == 0xE0
      assertFalse("sample still LOAS-framed", isLoasSync)
      assertEquals(C.BUFFER_FLAG_KEY_FRAME, sample.flags and C.BUFFER_FLAG_KEY_FRAME)
      assertTrue(sample.timeUs >= prevTimeUs)
      prevTimeUs = sample.timeUs
    }
    val spanUs = track.samples.last().timeUs - track.samples.first().timeUs
    assertTrue("expected ~1s span, got ${spanUs}us", spanUs in 800_000..1_200_000)
  }

  @Test
  fun detectsLoasAcmCodecPrivate() {
    val loas = byteArrayOf(0x02, 0x16, 0, 0, 0, 0)
    assertTrue(isLoasAcmTrack("A_MS/ACM", loas))
    // Wrong tag (PCM), wrong codec, or missing private data must not match
    assertFalse(isLoasAcmTrack("A_MS/ACM", byteArrayOf(0x01, 0x00, 0, 0)))
    assertFalse(isLoasAcmTrack("A_AAC", loas))
    assertFalse(isLoasAcmTrack("A_MS/ACM", null))
    assertFalse(isLoasAcmTrack("A_MS/ACM", byteArrayOf(0x02)))
    assertFalse(isLoasAcmTrack(null, loas))
  }

  @Test
  fun rejectsUnexpectedEndOfInput() {
    val output = LatmTrackOutput(FakeTrackOutput(), 1)
    val reader = ByteArrayDataReader(ByteArray(0))

    assertThrows(EOFException::class.java) {
      output.sampleData(reader, 1, false, TrackOutput.SAMPLE_DATA_PART_MAIN)
    }
    assertEquals(
      C.RESULT_END_OF_INPUT,
      output.sampleData(reader, 1, true, TrackOutput.SAMPLE_DATA_PART_MAIN)
    )
  }

  @Test
  fun preservesStreamMuxConfigAcrossExtractorSeek() {
    val frames = loasFrames(2)
    assertEquals(0, frames[0][3].toInt() and 0x80)
    assertEquals(0x80, frames[1][3].toInt() and 0x80)

    val delegate = FakeTrackOutput()
    val output = LatmTrackOutput(delegate, 1)
    output.format(
      Format.Builder()
        .setId("1")
        .setSampleMimeType(MimeTypes.AUDIO_UNKNOWN)
        .build()
    )

    output.sampleData(ParsableByteArray(frames[0]), frames[0].size, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(0, C.BUFFER_FLAG_KEY_FRAME, frames[0].size, 0, null)
    assertEquals(1, delegate.samples.size)

    output.reset()
    output.sampleData(ParsableByteArray(frames[1]), frames[1].size, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(21_000, C.BUFFER_FLAG_KEY_FRAME, frames[1].size, 0, null)
    assertEquals(2, delegate.samples.size)
  }
}
