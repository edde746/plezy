package com.edde746.plezy.libass.media.text

import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.TrackOutput
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Spec for the dialogue feed both demuxer paths rely on: samples arrive in
 * media3's MatroskaExtractor shape ("Dialogue: 0:00:00:00,<duration>,<rest>")
 * and the sink must receive the sample start, the parsed duration, and the
 * payload after the second comma — while every byte is still forwarded
 * unchanged to the delegate.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AssTrackOutputTest {

  private class CapturedDialogue(val trackId: String?, val startMs: Long, val durationMs: Long, val line: ByteArray)

  private class RecordingSink : AssTrackOutput.DialogueSink {
    val dialogues = mutableListOf<CapturedDialogue>()

    override fun onDialogue(trackId: String?, startMs: Long, durationMs: Long, data: ByteArray, offset: Int, length: Int) {
      dialogues.add(CapturedDialogue(trackId, startMs, durationMs, data.copyOfRange(offset, offset + length)))
    }
  }

  private class RecordingTrackOutput : TrackOutput {
    val formats = mutableListOf<Format>()
    val samples = mutableListOf<ByteArray>()
    val sampleTimes = mutableListOf<Long>()
    private var buf = ByteArray(1024)
    private var bufLen = 0

    override fun format(format: Format) {
      formats.add(format)
    }

    override fun sampleData(input: androidx.media3.common.DataReader, length: Int, allowEndOfInput: Boolean, sampleDataPart: Int): Int {
      if (buf.size < bufLen + length) buf = buf.copyOf(bufLen + length)
      val read = input.read(buf, bufLen, length)
      if (read > 0) bufLen += read
      return read
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
      if (buf.size < bufLen + length) buf = buf.copyOf(bufLen + length)
      data.readBytes(buf, bufLen, length)
      bufLen += length
    }

    override fun sampleMetadata(timeUs: Long, flags: Int, size: Int, offset: Int, cryptoData: TrackOutput.CryptoData?) {
      val start = bufLen - offset - size
      samples.add(buf.copyOfRange(start, start + size))
      sampleTimes.add(timeUs)
      if (offset == 0) bufLen = 0
    }
  }

  private fun ssaFormat(id: String = "3"): Format = Format.Builder()
    .setId(id)
    .setSampleMimeType(MimeTypes.TEXT_SSA)
    .build()

  private fun deliver(output: AssTrackOutput, sample: String, timeUs: Long) {
    val bytes = sample.toByteArray(Charsets.UTF_8)
    output.sampleData(ParsableByteArray(bytes), bytes.size, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(timeUs, C.BUFFER_FLAG_KEY_FRAME, bytes.size, 0, null)
  }

  @Test
  fun feedsDialogueAndForwardsSampleUnchanged() {
    val sink = RecordingSink()
    val delegate = RecordingTrackOutput()
    val output = AssTrackOutput(delegate, sink)
    output.format(ssaFormat())

    val sample = "Dialogue: 0:00:00:00,0:00:05:00,7,0,Default,,0,0,0,,Hello, world"
    deliver(output, sample, 90_000_000L)

    assertEquals(1, sink.dialogues.size)
    val dialogue = sink.dialogues.first()
    assertEquals("3", dialogue.trackId)
    assertEquals(90_000L, dialogue.startMs)
    assertEquals(5_000L, dialogue.durationMs)
    // Payload after the second comma: the raw MKV/FFmpeg block, commas in the
    // text field intact.
    assertEquals("7,0,Default,,0,0,0,,Hello, world", dialogue.line.toString(Charsets.UTF_8))

    // The delegate still receives the full untouched sample.
    assertEquals(1, delegate.samples.size)
    assertArrayEquals(sample.toByteArray(Charsets.UTF_8), delegate.samples.first())
    assertEquals(90_000_000L, delegate.sampleTimes.first())
  }

  @Test
  fun ignoresNonAssTracksAndMalformedSamples() {
    val sink = RecordingSink()
    val delegate = RecordingTrackOutput()
    val output = AssTrackOutput(delegate, sink)

    // SubRip track: forwarded, never fed to libass.
    output.format(Format.Builder().setId("1").setSampleMimeType(MimeTypes.APPLICATION_SUBRIP).build())
    deliver(output, "1\n00:00:00,000 --> 00:00:05,000\nplain text", 1_000_000L)
    assertTrue(sink.dialogues.isEmpty())
    assertEquals(1, delegate.samples.size)

    // ASS track with an unparseable duration: forwarded, not fed.
    val assOutput = AssTrackOutput(RecordingTrackOutput(), sink)
    assOutput.format(ssaFormat())
    deliver(assOutput, "Dialogue: bogus", 1_000_000L)
    assertTrue(sink.dialogues.isEmpty())
  }

  @Test
  fun handlesChunkedSampleDataAndDataReaderPath() {
    val sink = RecordingSink()
    val delegate = RecordingTrackOutput()
    val output = AssTrackOutput(delegate, sink)
    output.format(ssaFormat("0"))

    val sample = "Dialogue: 0:00:00:00,0:00:01:50,1,0,Style,,0,0,0,,Line"
    val bytes = sample.toByteArray(Charsets.UTF_8)
    val split = bytes.size / 2
    output.sampleData(ParsableByteArray(bytes.copyOfRange(0, split)), split, TrackOutput.SAMPLE_DATA_PART_MAIN)
    val rest = bytes.copyOfRange(split, bytes.size)
    var consumed = 0
    val reader = androidx.media3.common.DataReader { buffer, offset, length ->
      if (consumed >= rest.size) {
        C.RESULT_END_OF_INPUT
      } else {
        val toRead = minOf(length, rest.size - consumed)
        System.arraycopy(rest, consumed, buffer, offset, toRead)
        consumed += toRead
        toRead
      }
    }
    while (consumed < rest.size) {
      output.sampleData(reader, rest.size - consumed, false, TrackOutput.SAMPLE_DATA_PART_MAIN)
    }
    output.sampleMetadata(0L, C.BUFFER_FLAG_KEY_FRAME, bytes.size, 0, null)

    assertEquals(1, sink.dialogues.size)
    assertEquals(1_500L, sink.dialogues.first().durationMs)
    assertEquals("1,0,Style,,0,0,0,,Line", sink.dialogues.first().line.toString(Charsets.UTF_8))
    assertArrayEquals(bytes, delegate.samples.first())
  }
}
