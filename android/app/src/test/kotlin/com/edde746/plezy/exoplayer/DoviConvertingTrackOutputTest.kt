package com.edde746.plezy.exoplayer

import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import java.io.ByteArrayOutputStream
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DoviConvertingTrackOutputTest {

  @Test
  fun malformedSupplementalSampleIsDroppedAndNextSampleRecovers() {
    val delegate = RecordingTrackOutput()
    val messages = mutableListOf<String>()
    val output = DoviConvertingTrackOutput(delegate, emitLog = { _, _, message -> messages.add(message) })
    activateProfile7(output)

    feed(output, ByteArray(3), C.BUFFER_FLAG_HAS_SUPPLEMENTAL_DATA)

    val malformed = ByteArray(5_882)
    writeInt32Be(malformed, 0, 279_101)
    feed(output, malformed, C.BUFFER_FLAG_HAS_SUPPLEMENTAL_DATA)

    assertEquals(0, delegate.samples.size)
    assertTrue(messages.any { it.contains("mainLen=279101 total=5882; dropping sample") })
    assertTrue(messages.any { it.contains("3B is too small; dropping sample") })

    val valid = supplementalSample(
      main = byteArrayOf(0, 0, 0, 1, 0x40, 0x01),
      supplemental = byteArrayOf(0x55)
    )
    feed(output, valid, C.BUFFER_FLAG_HAS_SUPPLEMENTAL_DATA)

    assertEquals(1, delegate.samples.size)
    assertArrayEquals(valid, delegate.samples.single())
  }

  @Test
  fun repeatedExtractorSeeksDoNotLeakInterruptedSamplesIntoPlayback() {
    val extractor = RecordingExtractor()
    val delegateTrack = RecordingTrackOutput()
    val output = RecordingExtractorOutput(delegateTrack)
    val messages = mutableListOf<String>()
    val wrapper = DoviExtractorWrapper(extractor, emitLog = { _, _, message -> messages.add(message) })
    wrapper.init(output)
    val wrappedTrack = extractor.output.track(1, C.TRACK_TYPE_VIDEO)
    activateProfile7(wrappedTrack)

    repeat(2) { index ->
      val interrupted = ByteArray(5_882)
      writeInt32Be(interrupted, 0, 279_101)
      wrappedTrack.sampleData(
        ParsableByteArray(interrupted),
        interrupted.size,
        TrackOutput.SAMPLE_DATA_PART_MAIN
      )
      wrapper.seek(1234L + index, 5_000L + index)
    }

    val valid = supplementalSample(
      main = byteArrayOf(0, 0, 0, 1, 0x40, 0x01),
      supplemental = byteArrayOf(0x55)
    )
    feed(wrappedTrack, valid, C.BUFFER_FLAG_HAS_SUPPLEMENTAL_DATA)

    assertEquals(2, extractor.seekCount)
    assertEquals(1235L, extractor.seekPosition)
    assertEquals(5_001L, extractor.seekTimeUs)
    assertEquals(1, delegateTrack.samples.size)
    assertArrayEquals(valid, delegateTrack.samples.single())
    assertTrue(messages.none { it.startsWith("Bad supplemental sample") })
  }

  private fun activateProfile7(output: TrackOutput) {
    output.format(
      Format.Builder()
        .setSampleMimeType(MimeTypes.VIDEO_DOLBY_VISION)
        .setCodecs("dvhe.07.06")
        .build()
    )
  }

  private fun feed(output: TrackOutput, sample: ByteArray, flags: Int) {
    output.sampleData(ParsableByteArray(sample), sample.size, TrackOutput.SAMPLE_DATA_PART_MAIN)
    output.sampleMetadata(1, flags, sample.size, 0, null)
  }

  private fun supplementalSample(main: ByteArray, supplemental: ByteArray): ByteArray {
    val sample = ByteArray(4 + main.size + supplemental.size)
    writeInt32Be(sample, 0, main.size)
    main.copyInto(sample, destinationOffset = 4)
    supplemental.copyInto(sample, destinationOffset = 4 + main.size)
    return sample
  }

  private fun writeInt32Be(target: ByteArray, offset: Int, value: Int) {
    target[offset] = ((value ushr 24) and 0xFF).toByte()
    target[offset + 1] = ((value ushr 16) and 0xFF).toByte()
    target[offset + 2] = ((value ushr 8) and 0xFF).toByte()
    target[offset + 3] = (value and 0xFF).toByte()
  }

  private class RecordingTrackOutput : TrackOutput {
    val samples = mutableListOf<ByteArray>()
    private val pending = ByteArrayOutputStream()

    override fun format(format: Format) = Unit

    override fun sampleData(
      input: DataReader,
      length: Int,
      allowEndOfInput: Boolean,
      sampleDataPart: Int
    ): Int {
      val buffer = ByteArray(length)
      val read = input.read(buffer, 0, length)
      if (read > 0) pending.write(buffer, 0, read)
      return read
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
      val buffer = ByteArray(length)
      data.readBytes(buffer, 0, length)
      pending.write(buffer)
    }

    override fun sampleMetadata(
      timeUs: Long,
      flags: Int,
      size: Int,
      offset: Int,
      cryptoData: TrackOutput.CryptoData?
    ) {
      samples.add(pending.toByteArray())
      pending.reset()
    }
  }

  private class RecordingExtractor : Extractor {
    lateinit var output: ExtractorOutput
    var seekPosition = C.INDEX_UNSET.toLong()
    var seekTimeUs = C.TIME_UNSET
    var seekCount = 0

    override fun sniff(input: ExtractorInput): Boolean = true

    override fun init(output: ExtractorOutput) {
      this.output = output
    }

    override fun read(input: ExtractorInput, seekPosition: PositionHolder): Int = Extractor.RESULT_END_OF_INPUT

    override fun seek(position: Long, timeUs: Long) {
      seekCount++
      this.seekPosition = position
      seekTimeUs = timeUs
    }

    override fun release() = Unit
  }

  private class RecordingExtractorOutput(
    private val trackOutput: TrackOutput
  ) : ExtractorOutput {
    override fun track(id: Int, type: Int): TrackOutput = trackOutput
    override fun endTracks() = Unit
    override fun seekMap(seekMap: SeekMap) = Unit
  }
}
