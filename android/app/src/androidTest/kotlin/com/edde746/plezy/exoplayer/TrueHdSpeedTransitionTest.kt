package com.edde746.plezy.exoplayer

import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Speed changes arrive while the carrier is already live (#1804). Nothing re-asks the sink unless
 * capabilities are invalidated, so this drives the real path: play on the carrier, change speed,
 * and require the renderer to actually move TrueHD onto a decoder and keep the clock advancing.
 *
 * Skips itself on hardware that never takes the carrier; there is no transition to observe there.
 */
class TrueHdSpeedTransitionTest {
  private companion object {
    const val TAG = "TrueHdSpeed"
    const val SETTLE_MS = 4_000L
  }

  @Test
  fun leavingUnitSpeedMovesTrueHdOffTheCarrierAndKeepsPlaying() {
    val instrumentation = InstrumentationRegistry.getInstrumentation()
    val context = instrumentation.targetContext
    val fixture = copyFixture(context)
    val thread = HandlerThread("truehd-speed-test").apply { start() }
    val handler = Handler(thread.looper)

    val playing = CountDownLatch(1)
    val audioDecoder = AtomicReference<String?>(null)
    val trackEncoding = AtomicReference<Int>(-1)
    val player = AtomicReference<ExoPlayer?>(null)

    handler.post {
      val factory = PlezyRenderersFactory(context).apply {
        setEnableDecoderFallback(true)
        setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
      }
      // Mirrors ExoPlayerCore: without this flag DefaultTrackSelector silently drops every
      // renderer-capability invalidation, so the carrier could never be re-evaluated.
      val selector = DefaultTrackSelector(context).apply {
        setParameters(
          buildUponParameters().setAllowInvalidateSelectionsOnRendererCapabilitiesChange(true)
        )
      }
      val exo = ExoPlayer.Builder(context, factory).setTrackSelector(selector).build()
      player.set(exo)
      exo.addAnalyticsListener(
        object : AnalyticsListener {
          override fun onAudioDecoderInitialized(
            eventTime: AnalyticsListener.EventTime,
            decoderName: String,
            initializedTimestampMs: Long,
            initializationDurationMs: Long
          ) {
            audioDecoder.set(decoderName)
            Log.i(TAG, "audio decoder: $decoderName")
          }

          override fun onAudioTrackInitialized(
            eventTime: AnalyticsListener.EventTime,
            config: AudioSink.AudioTrackConfig
          ) {
            trackEncoding.set(config.sampleRate)
            Log.i(TAG, "AudioTrack rate=${config.sampleRate} buffer=${config.bufferSize}")
          }

          override fun onIsPlayingChanged(eventTime: AnalyticsListener.EventTime, isPlaying: Boolean) {
            if (isPlaying) playing.countDown()
          }
        }
      )
      val source = ProgressiveMediaSource.Factory(
        DefaultDataSource.Factory(context),
        DefaultExtractorsFactory()
      ).createMediaSource(MediaItem.fromUri(Uri.fromFile(fixture)))
      exo.setMediaSource(source)
      exo.prepare()
      exo.playWhenReady = true
    }

    assertTrue("playback never started", playing.await(30, TimeUnit.SECONDS))
    Thread.sleep(SETTLE_MS)

    val carrierEncoding = trackEncoding.get()
    val decoderBefore = audioDecoder.get()
    Log.i(TAG, "==== BEFORE: rate=$carrierEncoding decoder=$decoderBefore ====")

    // AudioTrackConfig is built from OutputConfig, which stays PCM16 by design; the real
    // AudioTrack format is swapped in the builder modifier. The observable carrier signature is
    // therefore the 192kHz carrier rate with no decoder instantiated.
    if (carrierEncoding != TrueHdMatPacker.CARRIER_SAMPLE_RATE || decoderBefore != null) {
      Log.i(TAG, "==== SKIPPED: device does not take the carrier (rate=$carrierEncoding) ====")
      teardown(handler, player, thread, fixture)
      return
    }

    val positionBefore = positionOf(handler, player)
    handler.post { player.get()?.setPlaybackSpeed(1.5f) }
    Thread.sleep(SETTLE_MS)

    val encodingAfter = trackEncoding.get()
    val decoderAfter = audioDecoder.get()
    val positionAfter = positionOf(handler, player)
    Log.i(
      TAG,
      "==== AFTER: rate=$encodingAfter decoder=$decoderAfter " +
        "position=${positionBefore}ms -> ${positionAfter}ms ===="
    )

    // Returning to 1x has to re-offer the carrier, or one speed nudge costs Atmos for the session.
    trackEncoding.set(-1)
    handler.post { player.get()?.setPlaybackSpeed(1f) }
    Thread.sleep(SETTLE_MS)
    val rateRestored = trackEncoding.get()
    Log.i(TAG, "==== RESTORED: rate=$rateRestored ====")

    teardown(handler, player, thread, fixture)

    assertEquals(
      "returning to 1x must put TrueHD back on the carrier",
      TrueHdMatPacker.CARRIER_SAMPLE_RATE,
      rateRestored
    )
    assertNotEquals(
      "TrueHD must leave the IEC 61937 carrier when speed leaves 1x",
      TrueHdMatPacker.CARRIER_SAMPLE_RATE,
      encodingAfter
    )
    assertTrue("a decoder must take over the TrueHD track", decoderAfter != null)
    assertTrue("the clock must keep advancing after the switch", positionAfter > positionBefore)
    // The whole point of the switch: the speed the user asked for has to actually apply. At 1.5x
    // the media clock must outrun the 4s of wall time spent waiting.
    assertTrue(
      "playback must run faster than real time after the switch, advanced " +
        "${positionAfter - positionBefore}ms in ${SETTLE_MS}ms",
      positionAfter - positionBefore > SETTLE_MS * 6 / 5
    )
  }

  private fun positionOf(handler: Handler, player: AtomicReference<ExoPlayer?>): Long {
    val value = AtomicReference(0L)
    val done = CountDownLatch(1)
    handler.post {
      value.set(player.get()?.currentPosition ?: 0L)
      done.countDown()
    }
    done.await(5, TimeUnit.SECONDS)
    return value.get()
  }

  private fun teardown(
    handler: Handler,
    player: AtomicReference<ExoPlayer?>,
    thread: HandlerThread,
    fixture: File
  ) {
    val done = CountDownLatch(1)
    handler.post {
      player.get()?.release()
      done.countDown()
    }
    done.await(10, TimeUnit.SECONDS)
    thread.quitSafely()
    thread.join(5_000)
    fixture.delete()
  }

  private fun copyFixture(
    context: android.content.Context,
    asset: String = "ffmpeg/truehd_speed_repro.mka"
  ): File {
    val output = File.createTempFile("truehd-speed-", null, context.cacheDir)
    InstrumentationRegistry.getInstrumentation().context.assets
      .open(asset)
      .use { input -> output.outputStream().use { input.copyTo(it) } }
    return output
  }

  /**
   * The container announces 48kHz, which selection trusts, but the bitstream is genuinely 44.1kHz
   * TrueHD, which the carrier does not cover (#1804). The packer emits nothing in that state, so
   * the sink has to hand the stream to the decoder rather than play silence.
   */
  @Test
  fun aRateFamilyMismatchFallsBackToTheDecoderInsteadOfGoingSilent() {
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    if (!supportsTrueHdMatCarrier(context)) {
      Log.i(TAG, "==== MISMATCH SKIPPED: device has no carrier route ====")
      return
    }
    val fixture = copyFixture(context, "ffmpeg/truehd_mismatch_repro.mka")
    val thread = HandlerThread("truehd-mismatch-test").apply { start() }
    val handler = Handler(thread.looper)

    val playing = CountDownLatch(1)
    val audioDecoder = AtomicReference<String?>(null)
    val trackRate = AtomicReference(-1)
    val rateSequence = java.util.Collections.synchronizedList(mutableListOf<Int>())
    val diagnostics = java.util.Collections.synchronizedList(mutableListOf<String>())
    val player = AtomicReference<ExoPlayer?>(null)

    handler.post {
      val factory = PlezyRenderersFactory(context).apply {
        setEnableDecoderFallback(true)
        setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
        audioDiagnosticsLogger = { _, _, message ->
          diagnostics.add(message)
          Log.i(TAG, "mismatch sink: $message")
        }
      }
      val selector = DefaultTrackSelector(context).apply {
        setParameters(
          buildUponParameters().setAllowInvalidateSelectionsOnRendererCapabilitiesChange(true)
        )
      }
      val exo = ExoPlayer.Builder(context, factory).setTrackSelector(selector).build()
      player.set(exo)
      exo.addAnalyticsListener(
        object : AnalyticsListener {
          override fun onAudioDecoderInitialized(
            eventTime: AnalyticsListener.EventTime,
            decoderName: String,
            initializedTimestampMs: Long,
            initializationDurationMs: Long
          ) {
            audioDecoder.set(decoderName)
            Log.i(TAG, "mismatch audio decoder: $decoderName")
          }

          override fun onAudioTrackInitialized(
            eventTime: AnalyticsListener.EventTime,
            config: AudioSink.AudioTrackConfig
          ) {
            trackRate.set(config.sampleRate)
            rateSequence.add(config.sampleRate)
            Log.i(TAG, "mismatch AudioTrack rate=${config.sampleRate}")
          }

          override fun onAudioInputFormatChanged(
            eventTime: AnalyticsListener.EventTime,
            format: androidx.media3.common.Format,
            decoderReuseEvaluation: androidx.media3.exoplayer.DecoderReuseEvaluation?
          ) {
            Log.i(TAG, "mismatch INPUT format: mime=${format.sampleMimeType} rate=${format.sampleRate} ch=${format.channelCount}")
          }

          override fun onIsPlayingChanged(eventTime: AnalyticsListener.EventTime, isPlaying: Boolean) {
            if (isPlaying) playing.countDown()
          }
        }
      )
      val source = ProgressiveMediaSource.Factory(
        DefaultDataSource.Factory(context),
        DefaultExtractorsFactory()
      ).createMediaSource(MediaItem.fromUri(Uri.fromFile(fixture)))
      exo.setMediaSource(source)
      exo.prepare()
      exo.playWhenReady = true
    }

    assertTrue("playback never started", playing.await(30, TimeUnit.SECONDS))
    Thread.sleep(SETTLE_MS)
    val positionFirst = positionOf(handler, player)
    Thread.sleep(SETTLE_MS)
    val positionSecond = positionOf(handler, player)

    val decoder = audioDecoder.get()
    val rate = trackRate.get()
    Log.i(
      TAG,
      "==== MISMATCH RESULT: rates=$rateSequence decoder=$decoder rate=$rate " +
        "position=${positionFirst}ms -> ${positionSecond}ms ===="
    )
    teardown(handler, player, thread, fixture)

    // Without this the test would also pass on a build where the carrier was never selected at all:
    // the mismatch fires on the first access unit, before the carrier writes a burst, so no 192kHz
    // AudioTrack is ever opened and the rate sequence alone cannot tell the two apart.
    assertTrue(
      "the carrier must have been entered and then left at runtime, saw: $diagnostics",
      diagnostics.any { it.contains("MAT/IEC 61937 carrier") } &&
        diagnostics.any { it.contains("44.1kHz-family rate its container did not") }
    )
    assertTrue("a decoder must take the stream over instead of the carrier", decoder != null)
    assertNotEquals(
      "the stream must not still be riding the carrier",
      TrueHdMatPacker.CARRIER_SAMPLE_RATE,
      rate
    )
    assertTrue("playback must keep advancing after the fallback", positionSecond > positionFirst)
  }
}
