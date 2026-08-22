package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput
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
 * Drives LatmTrackOutput with LOAS frames from the committed fixture (1s 440Hz
 * sine, AAC-LC 48kHz stereo, LATM/LOAS) and verifies it unwraps them to raw
 * AAC with a synthesized AudioSpecificConfig. Both demuxer paths deliver LOAS
 * this way: the FFmpeg extractor wraps aac_latm tracks directly.
 *
 * Robolectric provides real android.util.* implementations for media3's
 * internals.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LatmTrackOutputTest {

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

  private fun placeholderFormat(): Format = Format.Builder()
    .setId("1")
    .setSampleMimeType(MimeTypes.AUDIO_AAC)
    .setLabel("LATM track")
    .setLanguage("eng")
    .build()

  @Test
  fun unwrapsLoasFramesToRawAac() {
    val delegate = FakeTrackOutput()
    val output = LatmTrackOutput(delegate, 1)
    output.format(placeholderFormat())

    val frames = loasFrames(40)
    var timeUs = 0L
    for (frame in frames) {
      output.sampleData(ParsableByteArray(frame), frame.size, TrackOutput.SAMPLE_DATA_PART_MAIN)
      output.sampleMetadata(timeUs, C.BUFFER_FLAG_KEY_FRAME, frame.size, 0, null)
      timeUs += 21_333
    }

    // The placeholder format must be swallowed; the LATM-derived AAC format
    // carries the AudioSpecificConfig and the original track metadata.
    val format = delegate.formats.last()
    assertEquals(MimeTypes.AUDIO_AAC, format.sampleMimeType)
    assertEquals(48000, format.sampleRate)
    assertEquals(2, format.channelCount)
    assertEquals("1", format.id)
    assertEquals("LATM track", format.label)
    assertTrue(format.initializationData.isNotEmpty())
    assertTrue(format.initializationData[0].isNotEmpty())

    assertTrue("expected ~40 samples, got ${delegate.samples.size}", delegate.samples.size in 35..40)
    for (sample in delegate.samples) {
      assertTrue(sample.data.isNotEmpty())
      val isLoasSync = sample.data.size >= 2 &&
        (sample.data[0].toInt() and 0xFF) == 0x56 &&
        (sample.data[1].toInt() and 0xE0) == 0xE0
      assertFalse("sample still LOAS-framed", isLoasSync)
    }
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
  fun preservesStreamMuxConfigAcrossReset() {
    val frames = loasFrames(2)
    assertEquals(0, frames[0][3].toInt() and 0x80)
    assertEquals(0x80, frames[1][3].toInt() and 0x80)

    val delegate = FakeTrackOutput()
    val output = LatmTrackOutput(delegate, 1)
    output.format(placeholderFormat())

    output.sampleData(ParsableByteArray(frames[0]), frames[0].size, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(0, C.BUFFER_FLAG_KEY_FRAME, frames[0].size, 0, null)
    assertEquals(1, delegate.samples.size)

    output.reset()
    output.sampleData(ParsableByteArray(frames[1]), frames[1].size, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(21_000, C.BUFFER_FLAG_KEY_FRAME, frames[1].size, 0, null)
    assertEquals(2, delegate.samples.size)
  }
}
