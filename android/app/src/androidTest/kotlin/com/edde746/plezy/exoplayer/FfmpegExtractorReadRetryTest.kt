package com.edde746.plezy.exoplayer

import android.content.Context
import android.net.Uri
import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
import androidx.media3.common.ParserException
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.TransferListener
import androidx.media3.extractor.DefaultExtractorInput
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorInput
import androidx.media3.extractor.ExtractorOutput
import androidx.media3.extractor.PositionHolder
import androidx.media3.extractor.SeekMap
import androidx.media3.extractor.TrackOutput
import androidx.media3.extractor.text.DefaultSubtitleParserFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.libass.media.AssHandler
import java.io.File
import java.io.IOException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Regression coverage for #2113: a transient byte-source failure mid-stream
 * must reach media3 as a plain retryable IOException, and the demuxer must
 * deliver samples again once the retried read succeeds.
 *
 * 2.17.1 got both halves wrong. The AVIO callback converted the proxy's
 * stored IOException into a bare AVERROR(EIO), which the extractor classified
 * as "malformed container" — a ParserException that
 * DefaultLoadErrorHandlingPolicy never retries — so one dropped connection
 * sent an otherwise healthy ExoPlayer session to the MPV fallback. And even
 * with the classification fixed, a failed refill latches
 * AVIOContext.error/eof_reached, so the retry would re-fail on the stale
 * error without the native side clearing the latch on re-entry.
 */
@RunWith(AndroidJUnit4::class)
class FfmpegExtractorReadRetryTest {

  private companion object {
    /** 30 s at 10 fps: video samples are exact multiples of 100 ms. */
    const val FIXTURE = "ffmpeg/seek_cued.mkv"
    const val SAMPLE_INTERVAL_US = 100_000L
    const val TOTAL_SAMPLES = 300
  }

  @Test
  fun transientLoaderReadFailureIsRetryableAndDeliveryResumesGaplessly() {
    withHarness(FIXTURE) { harness ->
      assertTrue("no samples before the fault", harness.pumpUntil { harness.sampleTimestamps.size >= 10 })

      harness.failNextLoaderRead()
      val thrown = assertThrows(IOException::class.java) {
        harness.pumpUntil { harness.sampleTimestamps.size >= TOTAL_SAMPLES }
      }
      // The regression: a byte-source failure classified as malformed content
      // is terminal to media3, which retries only plain IOExceptions.
      assertFalse("byte-source failure classified as malformed: $thrown", thrown is ParserException)
      assertEquals("injected loader failure", thrown.message)

      // What ExtractingLoadable does on a load-error retry: reopen the source
      // where the input stood and call read() again.
      harness.reopenForRetry()
      assertTrue(
        "no samples after the retried read",
        harness.pumpUntil { harness.sampleTimestamps.size >= TOTAL_SAMPLES / 2 }
      )

      // Decode order is not presentation order with B-frames; what must hold
      // is that the delivered set stays gapless across the failure point.
      val sorted = harness.sampleTimestamps.sorted()
      assertEquals(
        "sample delivery must resume gaplessly after the transient failure",
        sorted.indices.map { it * SAMPLE_INTERVAL_US },
        sorted
      )
    }
  }

  private fun withHarness(fixture: String, block: (Harness) -> Unit) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    val cacheDir = context.cacheDir.also { it.mkdirs() }
    val file = File.createTempFile("ffmpeg-retry-fixture-", ".mkv", cacheDir)
    instrumentation.context.assets.open(fixture).use { input ->
      file.outputStream().use(input::copyTo)
    }
    val harness = Harness(context, Uri.fromFile(file))
    try {
      harness.prepare()
      block(harness)
    } finally {
      harness.close()
      file.delete()
    }
  }

  /**
   * Stand-in for ProgressiveMediaPeriod's loader, like FfmpegExtractorSeekTest's,
   * plus the piece under test here: the loader's DataSource can be made to fail
   * exactly one read, and [reopenForRetry] performs the load-error retry the
   * way ExtractingLoadable.load() does.
   */
  private class Harness(context: Context, private val uri: Uri) {
    private val factory = DefaultDataSource.Factory(context)
    private val io = FfmpegRandomAccessSource(factory) { DataSpec(uri) }
    private val output = CapturingOutput()
    private val positionHolder = PositionHolder()
    private val extractor = requireNotNull(
      FfmpegExtractor.create(
        { FfmpegDemuxerPolicy.Preference.FFMPEG },
        DvConversionMode.DISABLED,
        DefaultSubtitleParserFactory(),
        AssHandler(),
        io
      )
    ) { "native ffmpeg demuxer unavailable" }

    private var loaderSource: FlakySource? = null
    private var input: ExtractorInput? = null

    val sampleTimestamps: List<Long>
      get() = output.sampleTimestamps

    fun prepare() {
      openAt(0)
      assertTrue("fixture should be sniffed by the ffmpeg demuxer", extractor.sniff(input!!))
      input!!.resetPeekPosition()
      extractor.init(output)
    }

    /** Arms the current loader handle; only its next read throws. */
    fun failNextLoaderRead() {
      loaderSource!!.failNextRead = true
    }

    fun reopenForRetry() {
      openAt(input!!.position)
    }

    fun pumpUntil(condition: () -> Boolean): Boolean {
      repeat(200_000) {
        if (condition()) return true
        when (extractor.read(input!!, positionHolder)) {
          Extractor.RESULT_SEEK -> openAt(positionHolder.position)
          Extractor.RESULT_END_OF_INPUT -> return condition()
          else -> Unit
        }
      }
      return condition()
    }

    private fun openAt(position: Long) {
      loaderSource?.close()
      val source = FlakySource(factory.createDataSource())
      val remaining = source.open(DataSpec.Builder().setUri(uri).setPosition(position).build())
      loaderSource = source
      input = DefaultExtractorInput(
        source,
        position,
        if (remaining == C.LENGTH_UNSET.toLong()) C.LENGTH_UNSET.toLong() else position + remaining
      )
    }

    fun close() {
      extractor.release()
      loaderSource?.close()
    }
  }

  /** Wraps only the loader's source, so the fault never lands on an index read. */
  private class FlakySource(private val inner: DataSource) : DataSource {
    var failNextRead = false

    override fun open(dataSpec: DataSpec): Long = inner.open(dataSpec)

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
      if (failNextRead) {
        failNextRead = false
        throw IOException("injected loader failure")
      }
      return inner.read(buffer, offset, length)
    }

    override fun addTransferListener(transferListener: TransferListener) = inner.addTransferListener(transferListener)

    override fun getUri(): Uri? = inner.uri

    override fun getResponseHeaders(): Map<String, List<String>> = inner.responseHeaders

    override fun close() = inner.close()
  }

  private class CapturingOutput : ExtractorOutput {
    val sampleTimestamps = mutableListOf<Long>()

    override fun track(id: Int, type: Int): TrackOutput = CapturingTrack(type, sampleTimestamps)

    override fun endTracks() = Unit

    override fun seekMap(seekMap: SeekMap) = Unit
  }

  private class CapturingTrack(private val type: Int, private val timestamps: MutableList<Long>) : TrackOutput {
    private val scratch = ByteArray(64 * 1024)

    override fun format(format: Format) = Unit

    override fun sampleData(input: DataReader, length: Int, allowEndOfInput: Boolean): Int =
      sampleData(input, length, allowEndOfInput, TrackOutput.SAMPLE_DATA_PART_MAIN)

    override fun sampleData(input: DataReader, length: Int, allowEndOfInput: Boolean, sampleDataPart: Int): Int {
      val read = input.read(scratch, 0, minOf(length, scratch.size))
      return if (read == C.RESULT_END_OF_INPUT) 0 else read
    }

    override fun sampleData(data: ParsableByteArray, length: Int) {
      sampleData(data, length, TrackOutput.SAMPLE_DATA_PART_MAIN)
    }

    override fun sampleData(data: ParsableByteArray, length: Int, sampleDataPart: Int) {
      data.skipBytes(length)
    }

    override fun sampleMetadata(timeUs: Long, flags: Int, size: Int, offset: Int, cryptoData: TrackOutput.CryptoData?) {
      if (type == C.TRACK_TYPE_VIDEO) timestamps.add(timeUs)
    }
  }
}
