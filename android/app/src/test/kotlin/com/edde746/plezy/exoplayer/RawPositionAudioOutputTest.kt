package com.edde746.plezy.exoplayer

import android.media.AudioDeviceInfo
import android.media.AudioFormat
import androidx.annotation.OptIn
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.audio.AudioOutput
import androidx.media3.exoplayer.audio.AudioOutputProvider
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicLong
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `DefaultAudioSink` increments a static, process-wide pending-release counter on every flush and
 * decrements it only when the output reports `onReleased`. A dropped report pins that counter above
 * zero for the life of the process, which silently disables media3's own AudioTrack-init retry and
 * turns any later init failure into a permanent buffering hang (#1790). These tests pin the
 * wrapper's side of that contract: exactly one report per release, from every path.
 */
@OptIn(UnstableApi::class)
class RawPositionAudioOutputTest {

  private val rawPositionUs = AtomicLong(Long.MIN_VALUE)

  private fun config(
    encoding: Int = AudioFormat.ENCODING_PCM_16BIT,
    isOffload: Boolean = false,
    isTunneling: Boolean = false
  ): AudioOutputProvider.OutputConfig = AudioOutputProvider.OutputConfig.Builder()
    .setEncoding(encoding)
    .setSampleRate(48_000)
    .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
    .setBufferSize(40_000)
    .setIsOffload(isOffload)
    .setIsTunneling(isTunneling)
    .build()

  private fun provider(delegate: FakeOutputProvider) = RawPositionOutputProvider(delegate, rawPositionUs, log = null, sdkInt = 34)

  private fun acquire(
    provider: RawPositionOutputProvider,
    config: AudioOutputProvider.OutputConfig
  ): Pair<RawPositionAudioOutput, RecordingListener> {
    val output = provider.getAudioOutput(config) as RawPositionAudioOutput
    val listener = RecordingListener()
    output.addListener(listener)
    return output to listener
  }


  /**
   * A parked track is never going to release, so its flush has to be answered at once. Deferring
   * until the eviction would hold `DefaultAudioSink`'s process-wide pending-release count above
   * zero for the whole live track after the first seek, and any nonzero value stops media3
   * escalating *both* init and write failures — the #1790 hang, re-armed by an ordinary seek.
   */
  @Test
  fun aParkedOutputAnswersItsFlushImmediately() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)
    val (output, listener) = acquire(provider, config())

    output.release()

    assertEquals("the flush must be answered while the track is parked", 1, listener.releasedCount)
    assertFalse("a parked output must keep its AudioTrack", delegate.outputs.single().released)
  }

  @Test
  fun realReleaseReportsOnlyOnceTheDelegateConfirms() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)
    val (output, listener) = acquire(provider, config(encoding = AudioFormat.ENCODING_AC3))

    output.release()

    val real = delegate.outputs.single()
    assertTrue("a bitstream output must really release", real.released)
    assertEquals("release must not be reported before the AudioTrack is gone", 0, listener.releasedCount)

    real.confirmReleased()

    assertEquals(1, listener.releasedCount)
  }

  @Test
  fun releaseIsReportedOnceWhenTheDelegateNeverConfirms() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)
    val (output, listener) = acquire(provider, config(encoding = AudioFormat.ENCODING_AC3))

    // Player teardown: the sink flushes, then media3 posts the release completion to a playback
    // looper that is already quitting, so the confirmation never arrives.
    output.release()
    provider.release()

    assertEquals(1, listener.releasedCount)
  }

  @Test
  fun aLateDelegateConfirmationDoesNotReportTwice() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)
    val (output, listener) = acquire(provider, config(encoding = AudioFormat.ENCODING_AC3))

    output.release()
    output.settleReleaseNow()
    delegate.outputs.single().confirmReleased()

    assertEquals(1, listener.releasedCount)
  }


  @Test
  fun aParkedOutputIsHandedBackForAnIdenticalConfig() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)
    val (first, _) = acquire(provider, config())

    first.release()
    val (second, _) = acquire(provider, config())

    assertSame(first, second)
    assertEquals("the delegate must not build a second AudioTrack", 1, delegate.outputs.size)
  }

  /**
   * The sink charges the pending-release counter once per flush and builds a fresh listener per
   * acquisition, so every reuse cycle has to settle its own flush. One unanswered cycle is enough
   * to pin the counter above zero for the rest of the process.
   */
  @Test
  fun everyReuseCycleAnswersItsOwnFlush() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)

    repeat(5) {
      val (output, listener) = acquire(provider, config())
      output.release()
      assertEquals("cycle $it must report exactly one release", 1, listener.releasedCount)
    }

    assertEquals("the delegate must not build a second AudioTrack", 1, delegate.outputs.size)
  }

  /** A stale listener per cycle on the real output is how the accounting drifted in the first place. */
  @Test
  fun reuseDoesNotAccumulateListenersOnTheRealOutput() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)

    repeat(5) {
      val (output, _) = acquire(provider, config())
      output.release()
    }

    assertEquals(1, delegate.outputs.single().listeners.size)
  }

  @Test
  fun forwardedEventsReachTheCurrentListenerOnly() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)
    val (first, firstListener) = acquire(provider, config())
    first.release()
    val (_, secondListener) = acquire(provider, config())

    delegate.outputs.single().emitUnderrun()

    assertEquals(0, firstListener.underrunCount)
    assertEquals(1, secondListener.underrunCount)
  }


  /**
   * The replacement is deliberately built while the evicted track is still going away. Refusing
   * until it confirms looks safer, but the refusal reaches media3 as an init failure with no
   * pending release to excuse it, so its 200ms deadline starts immediately — and on the TVs this
   * cache exists for a teardown can outlast that, turning an ordinary config change into a
   * playback error. Upstream tolerates the same overlap.
   */
  @Test
  fun anEvictedParkedOutputIsReplacedWithoutWaitingForItsRelease() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)
    val (output, _) = acquire(provider, config())

    output.release()
    provider.getAudioOutput(config(isTunneling = true))

    assertTrue("the parked output must have been released", delegate.outputs.first().released)
    assertEquals("the replacement must not wait for the release", 2, delegate.outputs.size)
  }

  /**
   * The evicted track's flush was already answered when it parked, so its late confirmation —
   * however late — must not report a second release and drive the process-wide count negative.
   */
  @Test
  fun aSlowEvictionReleaseDoesNotReportASecondTime() {
    val delegate = FakeOutputProvider()
    val provider = provider(delegate)
    val (output, listener) = acquire(provider, config())

    output.release()
    val evicted = delegate.outputs.first()
    provider.getAudioOutput(config(isTunneling = true))
    assertEquals(1, listener.releasedCount)

    evicted.confirmReleased()
    evicted.confirmReleased()

    assertEquals(1, listener.releasedCount)
  }


  private class RecordingListener : AudioOutput.Listener {
    var releasedCount = 0
    var underrunCount = 0

    override fun onPositionAdvancing(playoutStartSystemTimeMs: Long) = Unit
    override fun onOffloadDataRequest() = Unit
    override fun onOffloadPresentationEnded() = Unit
    override fun onUnderrun() {
      underrunCount++
    }
    override fun onReleased() {
      releasedCount++
    }
  }

  private class FakeOutputProvider : AudioOutputProvider {
    val outputs = mutableListOf<FakeAudioOutput>()

    override fun getFormatSupport(formatConfig: AudioOutputProvider.FormatConfig) = throw UnsupportedOperationException()

    override fun getOutputConfig(formatConfig: AudioOutputProvider.FormatConfig) = throw UnsupportedOperationException()

    override fun getAudioOutput(config: AudioOutputProvider.OutputConfig): AudioOutput = FakeAudioOutput().also { outputs.add(it) }

    override fun addListener(listener: AudioOutputProvider.Listener) = Unit
    override fun removeListener(listener: AudioOutputProvider.Listener) = Unit
    override fun release() = Unit
  }

  private class FakeAudioOutput : AudioOutput {
    val listeners = mutableListOf<AudioOutput.Listener>()
    var released = false
    var stopped = false
    var flushed = false

    fun confirmReleased() {
      for (listener in listeners.toList()) listener.onReleased()
    }

    fun emitUnderrun() {
      for (listener in listeners.toList()) listener.onUnderrun()
    }

    override fun play() = Unit
    override fun pause() = Unit
    override fun flush() {
      flushed = true
    }
    override fun stop() {
      stopped = true
    }
    override fun release() {
      released = true
    }
    override fun write(buffer: ByteBuffer, encodedAccessUnitCount: Int, presentationTimeUs: Long) = true
    override fun setVolume(volume: Float) = Unit
    override fun isOffloadedPlayback() = false
    override fun getAudioSessionId() = 1
    override fun getSampleRate() = 48_000
    override fun getBufferSizeInFrames() = 0L
    override fun getPositionUs() = 0L
    override fun getPlaybackParameters(): PlaybackParameters = PlaybackParameters.DEFAULT
    override fun isStalled() = false
    override fun addListener(listener: AudioOutput.Listener) {
      listeners.add(listener)
    }
    override fun removeListener(listener: AudioOutput.Listener) {
      listeners.remove(listener)
    }
    override fun setPlaybackParameters(playbackParams: PlaybackParameters) = Unit
    override fun setOffloadDelayPadding(delayInFrames: Int, paddingInFrames: Int) = Unit
    override fun setOffloadEndOfStream() = Unit
    override fun attachAuxEffect(effectId: Int) = Unit
    override fun setAuxEffectSendLevel(level: Float) = Unit
    override fun setPreferredDevice(preferredDevice: AudioDeviceInfo?) = Unit
  }
}
