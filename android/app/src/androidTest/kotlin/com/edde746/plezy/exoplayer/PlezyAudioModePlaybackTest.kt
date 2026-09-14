package com.edde746.plezy.exoplayer

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.audio.ChannelMixingMatrix
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PlezyAudioModePlaybackTest {
  private enum class AudioMode {
    PASSTHROUGH_ALLOWED,
    FORCE_DECODED,
    DOWNMIX_NORMALIZED,
    DOWNMIX_UNNORMALIZED,
    NORMALIZATION
  }

  @Test
  fun appAudioPipelinePlaysAcrossOutputModes() {
    playToEnd("ffmpeg/surround_5_1_dts.mka", AudioMode.PASSTHROUGH_ALLOWED)
    playToEnd("ffmpeg/surround_5_1_truehd.mka", AudioMode.FORCE_DECODED)
    playToEnd("ffmpeg/surround_5_1.flac", AudioMode.DOWNMIX_NORMALIZED)
    playToEnd("ffmpeg/surround_7_1.flac", AudioMode.DOWNMIX_UNNORMALIZED)
    playToEnd("ffmpeg/surround_5_1_eac3.mka", AudioMode.NORMALIZATION)
  }

  private fun playToEnd(fixture: String, mode: AudioMode) {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    val fixtureFile = copyFixture(instrumentation.context, context, fixture)
    val playbackThread = HandlerThread("plezy-audio-mode-test").apply { start() }
    val handler = Handler(playbackThread.looper)
    val completed = CountDownLatch(1)
    val playerReference = AtomicReference<ExoPlayer>()
    val errorReference = AtomicReference<Throwable>()
    val outputPolicyConsulted = AtomicBoolean(false)
    val normalizationAttachAttempted = AtomicBoolean(false)
    val normalization = AudioNormalizationEffect { _, _, _ -> }
    val downmixActive = AtomicBoolean(false)

    handler.post {
      try {
        val factory = PlezyRenderersFactory(context).apply {
          setEnableDecoderFallback(true)
          setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
          shouldBlockDirectAudioOutput = { format ->
            val encoded = format.sampleMimeType != null && format.sampleMimeType != MimeTypes.AUDIO_RAW
            if (encoded) outputPolicyConsulted.set(true)
            encoded && mode != AudioMode.PASSTHROUGH_ALLOWED
          }
          if (mode == AudioMode.DOWNMIX_NORMALIZED || mode == AudioMode.DOWNMIX_UNNORMALIZED) {
            val normalize = mode == AudioMode.DOWNMIX_NORMALIZED
            for (channelCount in DownmixMatrices.MIN_DOWNMIX_INPUT_CHANNELS..DownmixMatrices.MAX_DOWNMIX_INPUT_CHANNELS) {
              val coefficients = DownmixMatrices.stereoCoefficients(channelCount, centerBoostDb = 6, normalize = normalize)!!
              channelMixProcessor.putChannelMixingMatrix(ChannelMixingMatrix(channelCount, 2, coefficients))
            }
          }
        }
        val player = ExoPlayer.Builder(context, factory)
          .setLooper(playbackThread.looper)
          .build()
        playerReference.set(player)
        player.addListener(object : Player.Listener {
          override fun onAudioSessionIdChanged(audioSessionId: Int) {
            if (mode == AudioMode.NORMALIZATION) {
              normalizationAttachAttempted.set(true)
              normalization.attach(audioSessionId, channelCount = 6)
            }
          }

          override fun onPlayerError(error: PlaybackException) {
            errorReference.set(error)
            completed.countDown()
          }

          override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_ENDED) {
              downmixActive.set(factory.channelMixProcessor.isActive)
              completed.countDown()
            }
          }
        })
        val source = ProgressiveMediaSource.Factory(
          DefaultDataSource.Factory(context),
          DefaultExtractorsFactory()
        ).createMediaSource(MediaItem.fromUri(Uri.fromFile(fixtureFile)))
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
      normalization.release()
      playbackThread.quitSafely()
      released.countDown()
    }
    val teardownFinished = released.await(5, TimeUnit.SECONDS)
    playbackThread.join(5_000)
    val fixtureDeleted = fixtureFile.delete()

    assertTrue("Player teardown timed out for $mode / $fixture", teardownFinished)
    assertTrue("Playback timed out for $mode / $fixture", finished)
    assertNull("Playback failed for $mode / $fixture", errorReference.get())
    assertTrue("Audio output policy was not consulted for $mode / $fixture", outputPolicyConsulted.get())
    if (mode == AudioMode.DOWNMIX_NORMALIZED || mode == AudioMode.DOWNMIX_UNNORMALIZED) {
      assertTrue("Downmix processor was inactive for $mode / $fixture", downmixActive.get())
    }
    if (mode == AudioMode.NORMALIZATION) {
      assertTrue("Normalization did not receive an audio session", normalizationAttachAttempted.get())
    }
    assertTrue("Fixture cleanup failed for $mode / $fixture", fixtureDeleted)
  }

  private fun copyFixture(instrumentationContext: Context, targetContext: Context, fixture: String): File {
    val output = File.createTempFile("audio-mode-fixture-", null, targetContext.cacheDir)
    instrumentationContext.assets.open(fixture).use { input ->
      output.outputStream().use(input::copyTo)
    }
    return output
  }
}
