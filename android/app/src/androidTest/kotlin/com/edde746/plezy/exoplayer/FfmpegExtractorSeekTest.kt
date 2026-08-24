package com.edde746.plezy.exoplayer

import android.content.Context
import android.net.Uri
import androidx.media3.common.C
import androidx.media3.common.DataReader
import androidx.media3.common.Format
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
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Regression coverage for #2096 and for the seam that caused it.
 *
 * libavformat resolves seeks through its own index, reading it via
 * [FfmpegRandomAccessSource]. When that read cannot be served, matroskadec
 * burns its one-shot Cues parse and every later seek degrades to libavformat's
 * linear generic scan — which is what buffered a resume for minutes. The cued
 * fixture here has the same geometry as the file from the report (front
 * SeekHead, Cues at 99.5% of the file), so a scan is trivially distinguishable
 * from an index seek: it has to read most of the file.
 */
@RunWith(AndroidJUnit4::class)
class FfmpegExtractorSeekTest {

  private companion object {
    // Regenerate with:
    //   ffmpeg -f lavfi -i "testsrc=size=160x120:rate=10:duration=30" \
    //     -c:v libx264 -g 10 -pix_fmt yuv420p -preset veryfast seek_cued.mkv
    //   mkvmerge --no-cues -o seek_cueless.mkv seek_cued.mkv
    // The cued fixture keeps ffmpeg's default layout: a SeekHead at byte 52
    // pointing at Cues written after the clusters, at 99.5% of the file.
    const val CUED = "ffmpeg/seek_cued.mkv"
    const val CUELESS = "ffmpeg/seek_cueless.mkv"

    /** The fixtures are 30 s at 10 fps with a keyframe every second. */
    const val TARGET_US = 25_000_000L
    const val KEYFRAME_TOLERANCE_US = 1_500_000L
  }

  @Test
  fun cuedSeekLandsOnTheTargetWithoutWalkingTheFile() {
    withHarness(CUED) { harness ->
      harness.pumpUntilSampleDelivered()
      assertTrue(
        "playback should start at the beginning, got ${harness.lastSampleUs}us",
        harness.lastSampleUs < 500_000L
      )

      harness.resetByteCounter()
      harness.seekTo(TARGET_US)
      val landed = harness.pumpUntilSampleAtLeast(TARGET_US - KEYFRAME_TOLERANCE_US)

      assertTrue("no sample delivered after seeking to ${TARGET_US}us", landed)
      assertTrue(
        "seek landed at ${harness.lastSampleUs}us, expected within " +
          "${KEYFRAME_TOLERANCE_US}us of ${TARGET_US}us",
        harness.lastSampleUs <= TARGET_US + KEYFRAME_TOLERANCE_US
      )
      // An index seek reads the Cues plus the target cluster. A generic scan
      // has to read everything up to 83% of the file to get here.
      val budget = harness.fixtureSize / 3
      assertTrue(
        "seek read ${harness.bytesRead} bytes of a ${harness.fixtureSize}-byte file; " +
          "expected under $budget (index seek, not a scan)",
        harness.bytesRead < budget
      )
      // Reopening per read would mean one request per 64 KB in steady state.
      assertTrue("random-access opens after seek: ${harness.randomAccessOpens}", harness.randomAccessOpens <= 4)
    }
  }

  /**
   * Without Cues libavformat falls back to its generic scan, exactly as media3's
   * own MatroskaExtractor scans clusters. That is slow but it must still land on
   * the target rather than stalling or silently delivering from the wrong place.
   */
  @Test
  fun cuelessSeekStillReachesTheTarget() {
    withHarness(CUELESS) { harness ->
      harness.pumpUntilSampleDelivered()
      harness.seekTo(TARGET_US)
      val landed = harness.pumpUntilSampleAtLeast(TARGET_US - KEYFRAME_TOLERANCE_US)

      assertTrue("cueless seek to ${TARGET_US}us delivered nothing", landed)
      assertTrue(
        "cueless seek landed at ${harness.lastSampleUs}us",
        harness.lastSampleUs <= TARGET_US + KEYFRAME_TOLERANCE_US
      )
    }
  }

  /**
   * A download stored through SAF arrives as `content://`, which media3 reads
   * with `openAssetFileDescriptor`. The demuxer's index reads therefore have to
   * open a second descriptor on the same document while the loader still holds
   * one — the case a `file://` fixture cannot prove.
   */
  @Test
  fun cuedSeekLandsOnTheTargetThroughAContentUri() {
    withHarness(CUED, contentUri = true) { harness ->
      harness.pumpUntilSampleDelivered()

      harness.resetByteCounter()
      harness.seekTo(TARGET_US)
      val landed = harness.pumpUntilSampleAtLeast(TARGET_US - KEYFRAME_TOLERANCE_US)

      assertTrue("no sample delivered after a content:// seek to ${TARGET_US}us", landed)
      assertTrue(
        "content:// seek landed at ${harness.lastSampleUs}us",
        harness.lastSampleUs <= TARGET_US + KEYFRAME_TOLERANCE_US
      )
      assertTrue(
        "content:// index read opened no descriptor of its own",
        harness.randomAccessOpens > 0
      )
      val budget = harness.fixtureSize / 3
      assertTrue(
        "content:// seek read ${harness.bytesRead} bytes of a ${harness.fixtureSize}-byte file; " +
          "expected under $budget (index seek, not a scan)",
        harness.bytesRead < budget
      )
    }
  }

  @Test
  fun playbackFromTheStartDeliversEverySampleFromTheBeginning() {
    withHarness(CUED) { harness ->
      val timestamps = harness.pumpSamples(count = 40)

      assertTrue("expected samples from the start, got ${timestamps.size}", timestamps.size >= 40)
      assertTrue("first sample at ${timestamps.first()}us", timestamps.first() < 500_000L)
      // Delivery is in decode order, which is not presentation order once the
      // encoder emits B-frames; what must hold is that the set of samples is
      // gapless from zero (this fixture is a steady 10 fps).
      val sorted = timestamps.sorted()
      assertEquals(sorted.indices.map { it * 100_000L }, sorted)
    }
  }

  private fun withHarness(fixture: String, contentUri: Boolean = false, block: (Harness) -> Unit) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    val file = copyFixture(instrumentation.context, context, fixture)
    // The content:// case reads the same asset back through the provider, which
    // keeps its own copy: this process cannot write into the test APK's dirs.
    val uri = if (contentUri) FixtureContentProvider.uriFor(fixture) else Uri.fromFile(file)
    val harness = Harness(context, file, uri)
    try {
      harness.prepare()
      block(harness)
    } finally {
      harness.close()
      file.delete()
    }
  }

  private fun copyFixture(instrumentationContext: Context, targetContext: Context, fixture: String): File {
    val cacheDir = targetContext.cacheDir.also { it.mkdirs() }
    val output = File.createTempFile("ffmpeg-seek-fixture-", ".mkv", cacheDir)
    instrumentationContext.assets.open(fixture).use { input ->
      output.outputStream().use(input::copyTo)
    }
    return output
  }

  /**
   * Minimal stand-in for ProgressiveMediaPeriod's loader: it opens the data
   * source, feeds an ExtractorInput, and honours RESULT_SEEK by re-opening —
   * the same contract media3 implements in ExtractingLoadable.load().
   */
  private class Harness(context: Context, fixture: File, private val uri: Uri) {
    val fixtureSize = fixture.length()
    private val counting = CountingDataSourceFactory(DefaultDataSource.Factory(context))
    private val io = FfmpegRandomAccessSource(counting) { DataSpec(uri) }
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

    private var dataSource: DataSource? = null
    private var input: ExtractorInput? = null
    private var opensBaseline = 0

    val lastSampleUs: Long
      get() = output.lastSampleUs

    val bytesRead: Long
      get() = counting.bytesRead

    val randomAccessOpens: Int
      get() = io.openCount - opensBaseline

    fun prepare() {
      openAt(0)
      assertTrue("fixture should be sniffed by the ffmpeg demuxer", extractor.sniff(input!!))
      input!!.resetPeekPosition()
      extractor.init(output)
    }

    fun resetByteCounter() {
      counting.reset()
      opensBaseline = io.openCount
    }

    fun seekTo(timeUs: Long) {
      // media3 restarts the load at the SeekMap's byte hint, then calls seek()
      // on the loader thread before the next read.
      val hint = output.seekMap?.getSeekPoints(timeUs)?.first?.position ?: 0L
      openAt(hint)
      extractor.seek(hint, timeUs)
    }

    fun pumpUntilSampleDelivered(): Boolean {
      val before = output.sampleCount
      return pump { output.sampleCount > before }
    }

    fun pumpUntilSampleAtLeast(timeUs: Long): Boolean = pump { output.lastSampleUs >= timeUs }

    fun pumpSamples(count: Int): List<Long> {
      pump { output.sampleTimestamps.size >= count }
      return output.sampleTimestamps.toList()
    }

    private fun pump(until: () -> Boolean): Boolean {
      repeat(200_000) {
        if (until()) return true
        when (extractor.read(input!!, positionHolder)) {
          Extractor.RESULT_SEEK -> openAt(positionHolder.position)
          Extractor.RESULT_END_OF_INPUT -> return until()
          else -> Unit
        }
      }
      return until()
    }

    private fun openAt(position: Long) {
      dataSource?.close()
      val source = counting.createDataSource()
      val remaining = source.open(DataSpec.Builder().setUri(uri).setPosition(position).build())
      dataSource = source
      input = DefaultExtractorInput(
        source,
        position,
        if (remaining == C.LENGTH_UNSET.toLong()) C.LENGTH_UNSET.toLong() else position + remaining
      )
    }

    fun close() {
      extractor.release()
      dataSource?.close()
    }
  }

  private class CapturingOutput : ExtractorOutput {
    val sampleTimestamps = mutableListOf<Long>()
    var seekMap: SeekMap? = null
      private set

    val sampleCount: Int
      get() = sampleTimestamps.size

    val lastSampleUs: Long
      get() = sampleTimestamps.lastOrNull() ?: C.TIME_UNSET

    override fun track(id: Int, type: Int): TrackOutput = CapturingTrack(type, sampleTimestamps)

    override fun endTracks() = Unit

    override fun seekMap(seekMap: SeekMap) {
      this.seekMap = seekMap
    }
  }

  private class CapturingTrack(private val type: Int, private val timestamps: MutableList<Long>) : TrackOutput {
    private val scratch = ByteArray(64 * 1024)

    override fun format(format: Format) = Unit

    override fun sampleData(input: DataReader, length: Int, allowEndOfInput: Boolean): Int = sampleData(input, length, allowEndOfInput, TrackOutput.SAMPLE_DATA_PART_MAIN)

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

  /** Counts every byte the demuxer pulls, through either read path. */
  private class CountingDataSourceFactory(private val delegate: DataSource.Factory) : DataSource.Factory {
    @Volatile private var counter = 0L

    val bytesRead: Long
      get() = counter

    fun reset() {
      counter = 0L
    }

    override fun createDataSource(): DataSource = Counting(delegate.createDataSource())

    private inner class Counting(private val inner: DataSource) : DataSource {
      override fun open(dataSpec: DataSpec): Long = inner.open(dataSpec)

      override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        val read = inner.read(buffer, offset, length)
        if (read > 0) counter += read
        return read
      }

      override fun addTransferListener(transferListener: TransferListener) = inner.addTransferListener(transferListener)

      override fun getUri(): Uri? = inner.uri

      override fun getResponseHeaders(): Map<String, List<String>> = inner.responseHeaders

      override fun close() = inner.close()
    }
  }
}
