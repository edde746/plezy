package com.edde746.plezy.exoplayer

import android.content.Context
import android.media.AudioDeviceInfo
import androidx.annotation.OptIn
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.util.Clock
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.analytics.PlayerId
import androidx.media3.exoplayer.audio.AudioOutput
import androidx.media3.exoplayer.audio.AudioOutputProvider
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.AudioTrackAudioOutputProvider
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.audio.DefaultAudioTrackBufferSizeProvider
import androidx.media3.exoplayer.audio.ForwardingAudioSink
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicLong

@OptIn(UnstableApi::class)
class PlezyRenderersFactory(context: Context) : DefaultRenderersFactory(context) {

    override fun buildAudioSink(
        context: Context,
        enableFloatOutput: Boolean,
        enableAudioOutputPlaybackParams: Boolean
    ): AudioSink {
        AudioTrackAudioOutputProvider.failOnSpuriousAudioTimestamp = false

        val bufferSizeProvider = DefaultAudioTrackBufferSizeProvider.Builder()
            .setMinPcmBufferDurationUs(500_000)
            .setMaxPcmBufferDurationUs(1_500_000)
            .setPcmBufferMultiplicationFactor(8)
            .build()

        val realProvider = AudioTrackAudioOutputProvider.Builder(context)
            .setAudioTrackBufferSizeProvider(bufferSizeProvider)
            .build()

        // Shared position: RawPositionAudioOutput writes the raw AudioTrack position,
        // PositionFixAudioSink reads it to bypass DefaultAudioSink's writtenDuration clamp.
        val rawPositionUs = AtomicLong(Long.MIN_VALUE)

        val defaultSink = DefaultAudioSink.Builder(context)
            .setEnableFloatOutput(enableFloatOutput)
            .setEnableAudioOutputPlaybackParameters(enableAudioOutputPlaybackParams)
            .setAudioOutputProvider(RawPositionOutputProvider(realProvider, rawPositionUs))
            .build()

        return PositionFixAudioSink(defaultSink, rawPositionUs)
    }
}

/**
 * Fixes video stutter with large audio frames (e.g. 120ms Opus).
 *
 * DefaultAudioSink.getCurrentPositionUs() clamps the playback position to
 * writtenDuration via Math.min(positionUs, framesToDurationUs(writtenFrames)).
 * With large audio frames, data arrives in bursts and writtenDuration lags behind
 * the real AudioTrack playback position between bursts, creating a sawtooth
 * position pattern (plateau → jump) that makes the video renderer drop frames.
 *
 * Fix: when DefaultAudioSink's position falls behind the raw AudioTrack position,
 * return startMediaTimeUs + rawPosition instead, giving the video renderer a
 * smooth clock to sync against.
 *
 * Also suppresses Amlogic AudioTrack timestamp discontinuity errors.
 *
 * The raw AudioTrack position advances at real-time rate regardless of speed
 * (AudioTrackPositionTracker reports post-time-stretch output frames). The
 * bypass multiplies by speed to convert to media time, matching what
 * DefaultAudioSink.applyMediaPositionParameters() does internally. Reference
 * points are captured on speed changes for correct mid-playback transitions.
 */
@OptIn(UnstableApi::class)
private class PositionFixAudioSink(
    sink: AudioSink,
    private val rawPositionUs: AtomicLong
) : ForwardingAudioSink(sink) {

    private var startMediaTimeUs = Long.MIN_VALUE
    private var suppressedErrorCount = 0

    // Speed tracking for position bypass
    private var currentSpeed = 1.0f
    private var refMediaTimeUs = Long.MIN_VALUE
    private var refRawPositionUs = 0L

    override fun handleBuffer(
        buffer: ByteBuffer,
        presentationTimeUs: Long,
        encodedAccessUnitCount: Int
    ): Boolean {
        if (startMediaTimeUs == Long.MIN_VALUE) {
            startMediaTimeUs = presentationTimeUs
            refMediaTimeUs = presentationTimeUs
            refRawPositionUs = 0
        }
        return super.handleBuffer(buffer, presentationTimeUs, encodedAccessUnitCount)
    }

    override fun setPlaybackParameters(playbackParameters: PlaybackParameters) {
        // Capture reference point before speed changes
        val rawPos = rawPositionUs.get()
        if (rawPos > 0 && refMediaTimeUs != Long.MIN_VALUE) {
            refMediaTimeUs = refMediaTimeUs + ((rawPos - refRawPositionUs) * currentSpeed).toLong()
            refRawPositionUs = rawPos
        }
        currentSpeed = playbackParameters.speed
        super.setPlaybackParameters(playbackParameters)
    }

    override fun getCurrentPositionUs(sourceEnded: Boolean): Long {
        val delegatePos = super.getCurrentPositionUs(sourceEnded)
        if (delegatePos == Long.MIN_VALUE || refMediaTimeUs == Long.MIN_VALUE) {
            return delegatePos
        }

        val rawPos = rawPositionUs.get()
        if (rawPos <= 0) return delegatePos

        val expectedPos = refMediaTimeUs + ((rawPos - refRawPositionUs) * currentSpeed).toLong()
        return if (expectedPos > delegatePos + 30_000) expectedPos else delegatePos
    }

    // --- Suppress timestamp discontinuity errors ---

    override fun setListener(listener: AudioSink.Listener) {
        super.setListener(@OptIn(UnstableApi::class) object : AudioSink.Listener {
            override fun onPositionDiscontinuity() = listener.onPositionDiscontinuity()
            override fun onPositionAdvancing(playoutStartSystemTimeUs: Long) = listener.onPositionAdvancing(playoutStartSystemTimeUs)
            override fun onUnderrun(bufferSize: Int, bufferSizeMs: Long, elapsedSinceLastFeedMs: Long) = listener.onUnderrun(bufferSize, bufferSizeMs, elapsedSinceLastFeedMs)
            override fun onSkipSilenceEnabledChanged(skipSilenceEnabled: Boolean) = listener.onSkipSilenceEnabledChanged(skipSilenceEnabled)
            override fun onOffloadBufferEmptying() = listener.onOffloadBufferEmptying()
            override fun onOffloadBufferFull() = listener.onOffloadBufferFull()
            override fun onAudioCapabilitiesChanged() = listener.onAudioCapabilitiesChanged()
            override fun onAudioTrackInitialized(audioTrackConfig: AudioSink.AudioTrackConfig) = listener.onAudioTrackInitialized(audioTrackConfig)
            override fun onAudioTrackReleased(audioTrackConfig: AudioSink.AudioTrackConfig) = listener.onAudioTrackReleased(audioTrackConfig)
            override fun onSilenceSkipped() = listener.onSilenceSkipped()
            override fun onAudioSessionIdChanged(audioSessionId: Int) = listener.onAudioSessionIdChanged(audioSessionId)

            override fun onAudioSinkError(audioSinkError: Exception) {
                if (isTimestampDiscontinuity(audioSinkError)) {
                    suppressedErrorCount++
                    return
                }
                listener.onAudioSinkError(audioSinkError)
            }
        })
    }

    override fun flush() {
        startMediaTimeUs = Long.MIN_VALUE
        refMediaTimeUs = Long.MIN_VALUE
        refRawPositionUs = 0
        rawPositionUs.set(Long.MIN_VALUE)
        super.flush()
    }

    override fun reset() {
        startMediaTimeUs = Long.MIN_VALUE
        refMediaTimeUs = Long.MIN_VALUE
        refRawPositionUs = 0
        currentSpeed = 1.0f
        rawPositionUs.set(Long.MIN_VALUE)
        suppressedErrorCount = 0
        super.reset()
    }

    private fun isTimestampDiscontinuity(e: Exception): Boolean {
        val name = e.javaClass.simpleName
        val msg = e.message ?: ""
        return name == "InvalidAudioTrackTimestampException" ||
                name == "UnexpectedDiscontinuityException" ||
                msg.contains("timestamp discontinuity", ignoreCase = true)
    }
}

// --- AudioOutput wrapping: shares raw position with PositionFixAudioSink ---

@OptIn(UnstableApi::class)
private class RawPositionOutputProvider(
    private val delegate: AudioOutputProvider,
    private val rawPositionUs: AtomicLong
) : AudioOutputProvider {

    override fun getFormatSupport(config: AudioOutputProvider.FormatConfig) =
        delegate.getFormatSupport(config)

    override fun getOutputConfig(config: AudioOutputProvider.FormatConfig) =
        delegate.getOutputConfig(config)

    override fun getAudioOutput(config: AudioOutputProvider.OutputConfig): AudioOutput {
        val realOutput = delegate.getAudioOutput(config)
        return RawPositionAudioOutput(realOutput, rawPositionUs)
    }

    override fun addListener(listener: AudioOutputProvider.Listener) =
        delegate.addListener(listener)

    override fun removeListener(listener: AudioOutputProvider.Listener) =
        delegate.removeListener(listener)

    override fun setClock(clock: Clock) = delegate.setClock(clock)

    override fun release() = delegate.release()
}

@OptIn(UnstableApi::class)
private class RawPositionAudioOutput(
    private val delegate: AudioOutput,
    private val rawPositionUs: AtomicLong
) : AudioOutput {

    override fun getPositionUs(): Long {
        val pos = delegate.getPositionUs()
        rawPositionUs.set(pos)
        return pos
    }

    override fun play() = delegate.play()
    override fun pause() = delegate.pause()

    @Throws(AudioOutput.WriteException::class)
    override fun write(buffer: ByteBuffer, size: Int, presentationTimeUs: Long) =
        delegate.write(buffer, size, presentationTimeUs)

    override fun flush() {
        rawPositionUs.set(Long.MIN_VALUE)
        delegate.flush()
    }

    override fun stop() = delegate.stop()

    override fun release() {
        rawPositionUs.set(Long.MIN_VALUE)
        delegate.release()
    }

    override fun setVolume(volume: Float) = delegate.setVolume(volume)
    override fun isOffloadedPlayback() = delegate.isOffloadedPlayback()
    override fun getAudioSessionId() = delegate.getAudioSessionId()
    override fun getSampleRate() = delegate.getSampleRate()
    override fun getBufferSizeInFrames() = delegate.getBufferSizeInFrames()
    override fun getPlaybackParameters() = delegate.getPlaybackParameters()
    override fun isStalled() = delegate.isStalled()
    override fun addListener(listener: AudioOutput.Listener) = delegate.addListener(listener)
    override fun removeListener(listener: AudioOutput.Listener) = delegate.removeListener(listener)
    override fun setPlaybackParameters(playbackParameters: PlaybackParameters) =
        delegate.setPlaybackParameters(playbackParameters)
    override fun setOffloadDelayPadding(delayInFrames: Int, paddingInFrames: Int) =
        delegate.setOffloadDelayPadding(delayInFrames, paddingInFrames)
    override fun setOffloadEndOfStream() = delegate.setOffloadEndOfStream()
    override fun setPlayerId(playerId: PlayerId) = delegate.setPlayerId(playerId)
    override fun attachAuxEffect(effectId: Int) = delegate.attachAuxEffect(effectId)
    override fun setAuxEffectSendLevel(level: Float) = delegate.setAuxEffectSendLevel(level)
    override fun setPreferredDevice(preferredDevice: AudioDeviceInfo?) =
        delegate.setPreferredDevice(preferredDevice)
}
