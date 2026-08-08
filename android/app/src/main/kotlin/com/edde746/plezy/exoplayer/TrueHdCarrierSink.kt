package com.edde746.plezy.exoplayer

import android.media.AudioDeviceInfo
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.AuxEffectInfo
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.util.Clock
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.analytics.PlayerId
import androidx.media3.exoplayer.audio.AudioSink
import java.nio.ByteBuffer

/**
 * Routes Dolby TrueHD through a MAT/IEC 61937 carrier, and everything else through the normal sink
 * (#1804).
 *
 * Android will not bitstream raw TrueHD on the TV routes measured for this issue: the platform
 * reports `ENCODING_DOLBY_TRUEHD` as offload-only while reporting `ENCODING_IEC61937` at 192kHz/7.1
 * as bitstream-capable. Kodi models the same split and packs the carrier itself; media3 only ever
 * hands Android raw TrueHD, at the stream rate. This sink adds the missing path.
 *
 * **Why two delegates rather than one sink with the processors held inactive.** The carrier is a
 * bit-exact byte stream that happens to be shaped like PCM. Any sample mutation — downmix, Sonic,
 * silence skipping, float conversion — turns it into full-scale noise at the receiver. Keeping the
 * carrier on a delegate built with an empty [AudioProcessorChain] makes that impossible by
 * construction. The alternative, asserting the normal chain stays inactive, puts the guarantee in a
 * different class from the thing it protects, so adding a processor later would silently break
 * playback in the loudest possible way.
 *
 * [carrierSink] must therefore be built with no audio processors and with an output provider whose
 * `AudioTrack` is forced to `ENCODING_IEC61937`; see [PlezyRenderersFactory].
 *
 * Selection happens only in [configure]. Persistent controls and the listener are mirrored to both
 * delegates so either can be activated later; per-stream calls go to the active one alone.
 */
@OptIn(UnstableApi::class)
internal class TrueHdCarrierSink(
  private val defaultSink: AudioSink,
  private val carrierSink: AudioSink,
  /** Whether the current route can bitstream the carrier tuple. Evaluated per format. */
  private val carrierRouteAvailable: () -> Boolean,
  /** Whether policy currently forbids bitstreaming at all (downmix, normalization, user setting). */
  private val directOutputBlocked: (Format) -> Boolean,
  private val log: ((String, String, String) -> Unit)? = null
) : AudioSink {

  private companion object {
    /** One MAT frame is exactly one carrier period: 3840 frames at 192kHz. */
    const val CARRIER_BURST_DURATION_US =
      TrueHdMatPacker.MAT_PKT_OFFSET.toLong() / TrueHdMatPacker.CARRIER_BYTES_PER_FRAME *
        1_000_000L / TrueHdMatPacker.CARRIER_SAMPLE_RATE
  }

  private val packer = TrueHdMatPacker()

  private var active: AudioSink = defaultSink
  private var carrierActive = false

  /** A burst the delegate refused; it must be placed before any further input is consumed. */
  private var pendingBurst: ByteBuffer? = null
  private var pendingBurstTimeUs: Long = 0

  /**
   * Anchor for carrier timestamps, and how many bursts have been emitted since it.
   *
   * Each MAT frame is exactly one carrier period of audio, so timestamps are derived from the
   * cadence rather than from whichever access unit happened to close the frame. Handing the sink
   * the closing unit's own presentation time drifts against the time it derives from written
   * frames, which it reports as a discontinuity on nearly every frame.
   */
  private var carrierAnchorUs: Long = C.TIME_UNSET
  private var burstsSinceAnchor: Long = 0

  private var playbackParameters: PlaybackParameters = PlaybackParameters.DEFAULT

  // --- Selection ---

  /**
   * True when this format should ride the carrier.
   *
   * Speed changes are excluded deliberately: a bitstream cannot be resampled, so anything other
   * than 1.0x has to decode. The same is true of the existing downmix/normalization blocks, which
   * [directOutputBlocked] already reports.
   */
  private fun shouldUseCarrier(format: Format): Boolean {
    if (format.sampleMimeType != MimeTypes.AUDIO_TRUEHD) return false
    if (packer.unsupportedRateFamily) return false
    if (playbackParameters.speed != 1f) return false
    if (directOutputBlocked(format)) return false
    return carrierRouteAvailable()
  }

  /** The PCM-shaped format the carrier delegate is configured with. */
  private fun carrierFormat(): Format = Format.Builder()
    .setSampleMimeType(MimeTypes.AUDIO_RAW)
    .setPcmEncoding(C.ENCODING_PCM_16BIT)
    .setChannelCount(TrueHdMatPacker.CARRIER_CHANNEL_COUNT)
    .setSampleRate(TrueHdMatPacker.CARRIER_SAMPLE_RATE)
    .build()

  override fun supportsFormat(format: Format): Boolean =
    if (shouldUseCarrier(format)) true else defaultSink.supportsFormat(format)

  override fun getFormatSupport(format: Format): Int =
    if (shouldUseCarrier(format)) AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY else defaultSink.getFormatSupport(format)

  override fun configure(inputFormat: Format, specifiedBufferSize: Int, outputChannels: IntArray?) {
    val useCarrier = shouldUseCarrier(inputFormat)
    if (useCarrier != carrierActive) {
      log?.invoke(
        "info",
        "audio",
        if (useCarrier) {
          "TrueHD via MAT/IEC 61937 carrier at ${TrueHdMatPacker.CARRIER_SAMPLE_RATE}Hz/" +
            "${TrueHdMatPacker.CARRIER_CHANNEL_COUNT}ch"
        } else {
          "Leaving the MAT carrier; audio returns to the normal sink"
        }
      )
    }
    carrierActive = useCarrier
    active = if (useCarrier) carrierSink else defaultSink
    discardCarrierState()

    if (useCarrier) {
      carrierSink.configure(carrierFormat(), specifiedBufferSize, null)
    } else {
      defaultSink.configure(inputFormat, specifiedBufferSize, outputChannels)
    }
  }

  // --- Stream path: active delegate only ---

  override fun handleBuffer(buffer: ByteBuffer, presentationTimeUs: Long, encodedAccessUnitCount: Int): Boolean {
    if (!carrierActive) return defaultSink.handleBuffer(buffer, presentationTimeUs, encodedAccessUnitCount)

    // A refused burst blocks everything: placing it must come before consuming more input, or the
    // carrier would lose a frame.
    pendingBurst?.let { burst ->
      if (!carrierSink.handleBuffer(burst, pendingBurstTimeUs, 1)) return false
      pendingBurst = null
    }
    if (!buffer.hasRemaining()) return true

    val sample = ByteArray(buffer.remaining())
    buffer.duplicate().get(sample)
    if (carrierAnchorUs == C.TIME_UNSET) carrierAnchorUs = presentationTimeUs

    var offset = 0
    while (offset < sample.size) {
      val length = TrueHdMatPacker.accessUnitLength(sample, offset, sample.size)
      if (length == 0) break
      val burst = packer.packAccessUnit(sample, offset, length)
      offset += length
      if (burst == null) continue

      val burstTimeUs = carrierAnchorUs + burstsSinceAnchor * CARRIER_BURST_DURATION_US
      burstsSinceAnchor++
      if (!carrierSink.handleBuffer(burst, burstTimeUs, 1)) {
        pendingBurst = burst
        pendingBurstTimeUs = burstTimeUs
        break
      }
    }
    if (packer.unsupportedRateFamily) {
      log?.invoke("info", "audio", "TrueHD is 44.1kHz-family; the MAT carrier does not cover it, decoding instead")
    }

    // The sample is consumed either way: a stashed burst is placed on the next call.
    buffer.position(buffer.limit())
    return true
  }

  override fun getCurrentPositionUs(sourceEnded: Boolean): Long = active.getCurrentPositionUs(sourceEnded)

  override fun playToEndOfStream() {
    // A partially filled MAT frame cannot be emitted; up to 20ms is dropped at the end of a stream.
    active.playToEndOfStream()
  }

  override fun isEnded(): Boolean = active.isEnded()

  override fun hasPendingData(): Boolean = pendingBurst != null || active.hasPendingData()

  override fun handleDiscontinuity() {
    discardCarrierState()
    active.handleDiscontinuity()
  }

  override fun play() = active.play()

  override fun pause() = active.pause()

  override fun flush() {
    discardCarrierState()
    active.flush()
  }

  override fun getAudioTrackBufferSizeUs(): Long = active.getAudioTrackBufferSizeUs()

  private fun discardCarrierState() {
    packer.reset()
    pendingBurst = null
    // Re-anchor on the next burst: after a seek the carrier restarts from a new media time.
    carrierAnchorUs = C.TIME_UNSET
    burstsSinceAnchor = 0
  }

  // --- Persistent state: mirrored, so either delegate can be activated later ---

  override fun setListener(listener: AudioSink.Listener) {
    defaultSink.setListener(listener)
    carrierSink.setListener(listener)
  }

  override fun setPlayerId(playerId: PlayerId?) {
    defaultSink.setPlayerId(playerId)
    carrierSink.setPlayerId(playerId)
  }

  override fun setClock(clock: Clock) {
    defaultSink.setClock(clock)
    carrierSink.setClock(clock)
  }

  override fun setPlaybackParameters(playbackParameters: PlaybackParameters) {
    this.playbackParameters = playbackParameters
    defaultSink.setPlaybackParameters(playbackParameters)
    carrierSink.setPlaybackParameters(playbackParameters)
  }

  override fun getPlaybackParameters(): PlaybackParameters = active.getPlaybackParameters()

  override fun setSkipSilenceEnabled(skipSilenceEnabled: Boolean) {
    // Only reaches the normal sink: the carrier delegate has no processors to skip silence with,
    // and dropping "silent" carrier bytes would break the frame cadence.
    defaultSink.setSkipSilenceEnabled(skipSilenceEnabled)
  }

  override fun getSkipSilenceEnabled(): Boolean = defaultSink.getSkipSilenceEnabled()

  override fun setAudioAttributes(audioAttributes: AudioAttributes) {
    defaultSink.setAudioAttributes(audioAttributes)
    carrierSink.setAudioAttributes(audioAttributes)
  }

  override fun getAudioAttributes(): AudioAttributes? = active.audioAttributes

  override fun setAudioSessionId(audioSessionId: Int) {
    defaultSink.setAudioSessionId(audioSessionId)
    carrierSink.setAudioSessionId(audioSessionId)
  }

  override fun setAuxEffectInfo(auxEffectInfo: AuxEffectInfo) {
    defaultSink.setAuxEffectInfo(auxEffectInfo)
    carrierSink.setAuxEffectInfo(auxEffectInfo)
  }

  override fun setPreferredDevice(audioDeviceInfo: AudioDeviceInfo?) {
    defaultSink.setPreferredDevice(audioDeviceInfo)
    carrierSink.setPreferredDevice(audioDeviceInfo)
  }

  override fun setOutputStreamOffsetUs(outputStreamOffsetUs: Long) {
    defaultSink.setOutputStreamOffsetUs(outputStreamOffsetUs)
    carrierSink.setOutputStreamOffsetUs(outputStreamOffsetUs)
  }

  override fun setVolume(volume: Float) {
    defaultSink.setVolume(volume)
    carrierSink.setVolume(volume)
  }

  override fun enableTunnelingV21() {
    // Tunneling is a decoded-PCM/video-sync arrangement; the carrier never uses it.
    defaultSink.enableTunnelingV21()
  }

  override fun disableTunneling() {
    defaultSink.disableTunneling()
  }

  override fun reset() {
    discardCarrierState()
    defaultSink.reset()
    carrierSink.reset()
  }

  override fun release() {
    discardCarrierState()
    defaultSink.release()
    carrierSink.release()
  }
}
