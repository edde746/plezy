package com.edde746.plezy.exoplayer

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.extractor.ExtractorsFactory
import androidx.media3.extractor.text.DefaultSubtitleParserFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.libass.media.AssHandler
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end regression coverage for #2088: audio demuxed by FfmpegExtractor
 * must reach MediaCodec with the per-codec csd shapes media3's own extractors
 * emit. With raw ffmpeg extradata as the only csd buffer, Android's Opus
 * decoders consume the first two real packets as codec delay / seek pre-roll
 * and then silently discard every decoded sample — the player never leaves
 * STATE_BUFFERING, which this test observes as a playback timeout.
 *
 * The extractors factory contains only FfmpegExtractor, so a fixture that
 * falls back to media3's extractors fails instead of passing vacuously.
 */
@RunWith(AndroidJUnit4::class)
class FfmpegExtractorAudioCsdPlaybackTest {

  @Test
  fun opusPlaysToEnd() {
    playToEnd("ffmpeg/stereo_opus.mka")
  }

  @Test
  fun vorbisPlaysToEnd() {
    playToEnd("ffmpeg/stereo_vorbis.mka")
  }

  @Test
  fun flacPlaysToEnd() {
    playToEnd("ffmpeg/stereo.flac")
  }

  private fun playToEnd(fixture: String) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    val fixtureFile = copyFixture(instrumentation.context, context, fixture)
    val playbackThread = HandlerThread("ffmpeg-csd-test").apply { start() }
    val handler = Handler(playbackThread.looper)
    val completed = CountDownLatch(1)
    val playerReference = AtomicReference<ExoPlayer>()
    val errorReference = AtomicReference<Throwable>()

    handler.post {
      try {
        val fixtureUri = Uri.fromFile(fixtureFile)
        val ffmpegOnlyExtractors = ExtractorsFactory {
          val extractor = FfmpegExtractor.create(
            { FfmpegDemuxerPolicy.Preference.FFMPEG },
            DvConversionMode.DISABLED,
            DefaultSubtitleParserFactory(),
            AssHandler(),
            FfmpegRandomAccessSource(DefaultDataSource.Factory(context)) { DataSpec(fixtureUri) }
          )
          assertNotNull("FFmpeg demuxer JNI library is unavailable", extractor)
          arrayOf(extractor!!)
        }
        val player = ExoPlayer.Builder(context, PlezyRenderersFactory(context))
          .setLooper(playbackThread.looper)
          .build()
        playerReference.set(player)
        player.addListener(object : Player.Listener {
          override fun onPlayerError(error: PlaybackException) {
            errorReference.set(error)
            completed.countDown()
          }

          override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_ENDED) {
              completed.countDown()
            }
          }
        })
        val source = ProgressiveMediaSource.Factory(
          DefaultDataSource.Factory(context),
          ffmpegOnlyExtractors
        ).createMediaSource(MediaItem.fromUri(fixtureUri))
        player.setMediaSource(source)
        player.prepare()
        player.play()
      } catch (error: Throwable) {
        errorReference.set(error)
        completed.countDown()
      }
    }

    val finished = completed.await(20, TimeUnit.SECONDS)
    val released = CountDownLatch(1)
    handler.post {
      playerReference.get()?.release()
      playbackThread.quitSafely()
      released.countDown()
    }
    val teardownFinished = released.await(5, TimeUnit.SECONDS)
    playbackThread.join(5_000)
    val fixtureDeleted = fixtureFile.delete()

    assertTrue("Player teardown timed out for $fixture", teardownFinished)
    assertTrue("Playback timed out for $fixture", finished)
    assertNull("Playback failed for $fixture", errorReference.get())
    assertTrue("Fixture cleanup failed for $fixture", fixtureDeleted)
  }

  private fun copyFixture(instrumentationContext: Context, targetContext: Context, fixture: String): File {
    val output = File.createTempFile("ffmpeg-csd-fixture-", null, targetContext.cacheDir)
    instrumentationContext.assets.open(fixture).use { input ->
      output.outputStream().use(input::copyTo)
    }
    return output
  }
}
