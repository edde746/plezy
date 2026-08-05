package com.edde746.plezy.exoplayer

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.exoplayer.audio.AudioCapabilities
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The hardware half of the #1790 contract, and the half a JVM fake cannot reach.
 *
 * `DefaultAudioSink` charges a static, process-wide counter on every flush and only discharges it
 * from `Listener::onReleased` — the same callback the player surfaces as
 * [AnalyticsListener.onAudioTrackReleased]. Any lasting imbalance stops media3 escalating audio
 * failures at all, which is how a failed `AudioTrack` turned into a permanent buffering hang.
 *
 * `onAudioTrackInitialized` fires once per acquisition and `onAudioTrackReleased` once per answered
 * flush, so counting both against a real sink, across the reuse and eviction cycles the wrapper's
 * cache actually creates, measures the invariant directly.
 */
@RunWith(AndroidJUnit4::class)
class AudioOutputReleaseAccountingTest {

  private companion object {
    const val SEEK_COUNT = 4
    const val STATE_TIMEOUT_SECONDS = 20L
  }

  @Test
  fun everyFlushIsAnsweredAcrossSeeksAndAConfigChange() {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    // Different channel counts give the sink two different output configurations, so the second
    // item cannot reuse the first one's parked AudioTrack and has to evict it.
    val surround = copyFixture(context, "ffmpeg/surround_5_1.flac")
    val stereo = copyFixture(context, "ffmpeg/stereo.flac")

    val playbackThread = HandlerThread("plezy-release-accounting-test").apply { start() }
    val handler = Handler(playbackThread.looper)
    val playerReference = AtomicReference<ExoPlayer>()
    val errorReference = AtomicReference<Throwable>()
    val initialized = AtomicInteger()
    val released = AtomicInteger()

    try {
      handler.runAndWait {
        val factory = PlezyRenderersFactory(context).apply {
          setEnableDecoderFallback(true)
          setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
          // Decoded PCM is the only output the cache parks, so it is the path whose reuse and
          // eviction the accounting has to survive.
          shouldBlockDirectAudioOutput = { format ->
            format.sampleMimeType != null && format.sampleMimeType != MimeTypes.AUDIO_RAW
          }
        }
        val player = ExoPlayer.Builder(context, factory).setLooper(playbackThread.looper).build()
        playerReference.set(player)
        player.addAnalyticsListener(object : AnalyticsListener {
          override fun onAudioTrackInitialized(
            eventTime: AnalyticsListener.EventTime,
            audioTrackConfig: AudioSink.AudioTrackConfig
          ) {
            initialized.incrementAndGet()
          }

          override fun onAudioTrackReleased(
            eventTime: AnalyticsListener.EventTime,
            audioTrackConfig: AudioSink.AudioTrackConfig
          ) {
            released.incrementAndGet()
          }

          override fun onPlayerErrorChanged(
            eventTime: AnalyticsListener.EventTime,
            error: androidx.media3.common.PlaybackException?
          ) {
            if (error != null) errorReference.set(error)
          }
        })
      }

      val player = playerReference.get()
      play(handler, player, surround)
      awaitReady(handler, player)

      // Each seek flushes the sink: the output is parked and handed straight back, so every one of
      // them has to settle its own flush or the counter drifts up for the rest of the process.
      repeat(SEEK_COUNT) {
        handler.runAndWait { player.seekTo(0) }
        awaitReady(handler, player)
      }

      val afterSeeks = initialized.get() - released.get()
      assertNull("playback failed before the config change", errorReference.get())
      assertTrue("expected the seeks to rebuild the audio output", initialized.get() > 1)
      assertEquals(
        "after $SEEK_COUNT seeks only the live acquisition may be outstanding " +
          "(initialized=${initialized.get()}, released=${released.get()})",
        1,
        afterSeeks
      )

      // Config change: the parked 5.1 track cannot serve stereo, so it is evicted for real.
      play(handler, player, stereo)
      awaitReady(handler, player)

      assertNull("playback failed after the config change", errorReference.get())
      assertEquals(
        "an eviction must not leave a second acquisition outstanding " +
          "(initialized=${initialized.get()}, released=${released.get()})",
        1,
        initialized.get() - released.get()
      )
    } finally {
      handler.runAndWait { playerReference.get()?.release() }
      playbackThread.quitSafely()
      playbackThread.join(TimeUnit.SECONDS.toMillis(5))
      surround.delete()
      stereo.delete()
    }
  }

  /**
   * The same invariant on a real bitstream route, which is the output the reporter's device was
   * failing to build. Needs a live HDMI sink that advertises encoded surround, so it skips on a
   * phone or a TV set to PCM rather than passing without having exercised anything.
   */
  @Test
  fun everyFlushIsAnsweredOnABitstreamRoute() {
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    val movieAttributes = AudioAttributes.Builder()
      .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
      .setUsage(C.USAGE_MEDIA)
      .build()
    val capabilities = AudioCapabilities.getCapabilities(context, movieAttributes, null)
    val fixture = when {
      capabilities.supportsEncoding(C.ENCODING_E_AC3) -> "ffmpeg/surround_5_1_eac3.mka"
      capabilities.supportsEncoding(C.ENCODING_DTS) -> "ffmpeg/surround_5_1_dts.mka"
      else -> null
    }
    assumeTrue("the current audio route does not advertise E-AC3 or DTS bitstream", fixture != null)

    val media = copyFixture(context, fixture!!)
    val playbackThread = HandlerThread("plezy-bitstream-accounting-test").apply { start() }
    val handler = Handler(playbackThread.looper)
    val playerReference = AtomicReference<ExoPlayer>()
    val errorReference = AtomicReference<Throwable>()
    val initialized = AtomicInteger()
    val released = AtomicInteger()
    val sawEncodedOutput = AtomicReference(false)

    try {
      handler.runAndWait {
        val factory = PlezyRenderersFactory(context).apply {
          setEnableDecoderFallback(true)
          setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
          shouldBlockDirectAudioOutput = { false }
        }
        val player = ExoPlayer.Builder(context, factory).setLooper(playbackThread.looper).build()
        playerReference.set(player)
        player.addAnalyticsListener(object : AnalyticsListener {
          override fun onAudioTrackInitialized(
            eventTime: AnalyticsListener.EventTime,
            audioTrackConfig: AudioSink.AudioTrackConfig
          ) {
            initialized.incrementAndGet()
            if (!isPcmEncoding(audioTrackConfig.encoding)) sawEncodedOutput.set(true)
          }

          override fun onAudioTrackReleased(
            eventTime: AnalyticsListener.EventTime,
            audioTrackConfig: AudioSink.AudioTrackConfig
          ) {
            released.incrementAndGet()
          }

          override fun onPlayerErrorChanged(
            eventTime: AnalyticsListener.EventTime,
            error: androidx.media3.common.PlaybackException?
          ) {
            if (error != null) errorReference.set(error)
          }
        })
      }

      val player = playerReference.get()
      play(handler, player, media)
      awaitReady(handler, player)
      repeat(SEEK_COUNT) {
        handler.runAndWait { player.seekTo(0) }
        awaitReady(handler, player)
      }

      assertNull("bitstream playback failed", errorReference.get())
      assumeTrue(
        "the route advertised encoded surround but the sink still decoded to PCM",
        sawEncodedOutput.get()
      )
      assertEquals(
        "a bitstream output must answer every flush too " +
          "(initialized=${initialized.get()}, released=${released.get()})",
        1,
        initialized.get() - released.get()
      )
    } finally {
      handler.runAndWait { playerReference.get()?.release() }
      playbackThread.quitSafely()
      playbackThread.join(TimeUnit.SECONDS.toMillis(5))
      media.delete()
    }
  }

  private fun play(handler: Handler, player: ExoPlayer, file: File) {
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    handler.runAndWait {
      val source = ProgressiveMediaSource.Factory(
        DefaultDataSource.Factory(context),
        DefaultExtractorsFactory()
      ).createMediaSource(MediaItem.fromUri(Uri.fromFile(file)))
      player.setMediaSource(source)
      player.prepare()
      player.play()
    }
  }

  /** Waits for the player to reach READY, which is the point an AudioTrack has been acquired. */
  private fun awaitReady(handler: Handler, player: ExoPlayer) {
    val ready = CountDownLatch(1)
    val listener = object : Player.Listener {
      override fun onPlaybackStateChanged(playbackState: Int) {
        if (playbackState == Player.STATE_READY || playbackState == Player.STATE_ENDED) ready.countDown()
      }
    }
    handler.runAndWait {
      if (player.playbackState == Player.STATE_READY || player.playbackState == Player.STATE_ENDED) {
        ready.countDown()
      } else {
        player.addListener(listener)
      }
    }
    val reached = ready.await(STATE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
    handler.runAndWait { player.removeListener(listener) }
    assertTrue("timed out waiting for the player to become ready", reached)
    // The AudioTrack is acquired on the first buffer handed to the sink, which lands just after
    // READY; give the playback thread a beat to get there before counting.
    handler.runAndWait { }
    Thread.sleep(250)
    handler.runAndWait { }
  }

  private fun Handler.runAndWait(block: () -> Unit) {
    val done = CountDownLatch(1)
    val failure = AtomicReference<Throwable>()
    post {
      try {
        block()
      } catch (error: Throwable) {
        failure.set(error)
      } finally {
        done.countDown()
      }
    }
    assertTrue("timed out running on the playback thread", done.await(STATE_TIMEOUT_SECONDS, TimeUnit.SECONDS))
    failure.get()?.let { throw it }
  }

  private fun copyFixture(targetContext: Context, fixture: String): File {
    val output = File.createTempFile("release-accounting-", null, targetContext.cacheDir)
    InstrumentationRegistry.getInstrumentation().context.assets.open(fixture).use { input ->
      output.outputStream().use(input::copyTo)
    }
    return output
  }
}
