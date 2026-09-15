package com.edde746.plezy.exoplayer

import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.extractor.Extractor
import androidx.media3.extractor.ExtractorsFactory
import androidx.media3.extractor.mkv.MatroskaExtractor
import androidx.media3.extractor.text.DefaultSubtitleParserFactory
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.libass.media.parser.AssSubtitleParserFactory
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * On-device coverage for MKV files whose SeekHead references Tracks after the Clusters (#1969).
 *
 * media3 1.11.0 builds the Matroska seek map at the end of the Cues element, which for these files
 * is before the Tracks element parsed, so the map permanently reports unseekable and ExoPlayer
 * coerces every seek to t=0 (ProgressiveMediaPeriod; tracking issue androidx/media #3377). The
 * first test is a canary asserting the upstream defect against a stock MatroskaExtractor — when it
 * fails after a media3 upgrade, the TrackAwareSeekMap repair in [CuelessSeekExtractorWrapper] can
 * be retired. The second test drives the production wrapper stack and requires the seek to
 * actually land.
 */
class MatroskaLateTracksSeekDeviceTest {
  private companion object {
    const val TAG = "MkvLateTracksSeek"
    const val SEEK_TARGET_MS = 500L
    const val SETTLE_MS = 2_000L
  }

  private class Session(
    val handler: Handler,
    val thread: HandlerThread,
    val player: AtomicReference<ExoPlayer?>,
    val fixture: File
  )

  @Test
  fun stockMatroskaExtractorSnapsSeeksToStart() {
    val result = runSeekScenario("stock") { MatroskaExtractor(DefaultSubtitleParserFactory()) }
    assertFalse(
      "upstream media3 now reports tracks-after-clusters MKVs seekable — " +
        "the TrackAwareSeekMap repair in CuelessSeekExtractorWrapper can be retired",
      result.seekable
    )
    assertTrue(
      "unseekable media must snap the seek to the start, position=${result.positionAfterSeekMs}ms",
      result.positionAfterSeekMs < SEEK_TARGET_MS / 2
    )
  }

  @Test
  fun wrappedExtractorKeepsSeekPosition() {
    val result = runSeekScenario("wrapped") {
      val assHandler = AssHandler()
      CuelessSeekExtractorWrapper(ZlibMatroskaExtractor(AssSubtitleParserFactory(assHandler), assHandler))
    }
    assertTrue("wrapped extractor must report the item seekable", result.seekable)
    assertTrue(
      "seek to ${SEEK_TARGET_MS}ms must hold, position=${result.positionAfterSeekMs}ms",
      result.positionAfterSeekMs >= SEEK_TARGET_MS / 2
    )
  }

  private class ScenarioResult(val seekable: Boolean, val positionAfterSeekMs: Long)

  private fun runSeekScenario(label: String, extractorFactory: () -> Extractor): ScenarioResult {
    val session = openPaused(label, extractorFactory)
    try {
      val seekable = onPlayerThread(session) { it.isCurrentMediaItemSeekable }
      session.handler.post { session.player.get()?.seekTo(SEEK_TARGET_MS) }
      // The masked position is the seek target; the snap surfaces once the period resolves the
      // seek, so give the load a moment before sampling the settled position.
      Thread.sleep(SETTLE_MS)
      val positionAfterSeekMs = onPlayerThread(session) { it.currentPosition }
      Log.i(TAG, "==== $label: seekable=$seekable position=${positionAfterSeekMs}ms ====")
      return ScenarioResult(seekable, positionAfterSeekMs)
    } finally {
      teardown(session)
    }
  }

  private fun openPaused(label: String, extractorFactory: () -> Extractor): Session {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    val fixture = copyFixture(context)
    val thread = HandlerThread("mkv-late-tracks-$label").apply { start() }
    val handler = Handler(thread.looper)
    val player = AtomicReference<ExoPlayer?>(null)
    val ready = CountDownLatch(1)
    val failed = AtomicBoolean(false)

    handler.post {
      val exo = ExoPlayer.Builder(context).build()
      player.set(exo)
      exo.addListener(
        object : Player.Listener {
          override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_READY) ready.countDown()
          }

          override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
            Log.e(TAG, "$label player error", error)
            failed.set(true)
            ready.countDown()
          }
        }
      )
      val source = ProgressiveMediaSource.Factory(
        DefaultDataSource.Factory(context),
        ExtractorsFactory { arrayOf(extractorFactory()) }
      ).createMediaSource(MediaItem.fromUri(Uri.fromFile(fixture)))
      exo.setMediaSource(source)
      exo.playWhenReady = false
      exo.prepare()
    }

    val session = Session(handler, thread, player, fixture)
    if (!ready.await(30, TimeUnit.SECONDS) || failed.get()) {
      teardown(session)
      error("$label playback never became ready")
    }
    return session
  }

  private fun <T> onPlayerThread(session: Session, read: (ExoPlayer) -> T): T {
    val value = AtomicReference<T>()
    val done = CountDownLatch(1)
    session.handler.post {
      session.player.get()?.let { value.set(read(it)) }
      done.countDown()
    }
    assertTrue("player thread stalled", done.await(5, TimeUnit.SECONDS))
    return checkNotNull(value.get())
  }

  private fun teardown(session: Session) {
    val done = CountDownLatch(1)
    session.handler.post {
      session.player.get()?.release()
      done.countDown()
    }
    done.await(10, TimeUnit.SECONDS)
    session.thread.quitSafely()
    session.thread.join(5_000)
    session.fixture.delete()
  }

  private fun copyFixture(context: android.content.Context): File {
    val output = File.createTempFile("mkv-late-tracks-", ".mkv", context.cacheDir)
    InstrumentationRegistry.getInstrumentation().context.assets
      .open("ffmpeg/matroska_tracks_at_end.mkv")
      .use { input -> output.outputStream().use { input.copyTo(it) } }
    return output
  }
}
