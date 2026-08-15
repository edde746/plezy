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
import java.util.concurrent.atomic.AtomicInteger

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
  private var sinkListener: AudioSink.Listener? = null

  /**
   * Latched when a stream's bitstream contradicts the rate its container announced, which selection
   * was made from.
   *
   * Deliberately outlives [flush] and [reset]: media3 resets every renderer disabled by a new
   * selection before enabling the replacement (ExoPlayerImplInternal.enableRenderers), and both
   * audio renderers share this sink, so the outgoing renderer's reset lands here in the middle of
   * the very handover this latch exists to cause. Clearing it there would re-offer the carrier and
   * loop straight back into the mismatch.
   *
   * The real boundary is a new media item, which only the caller knows and which happens before
   * selection asks anything. [beginMediaItem] is that hook; without it one malformed item would
   * cost bitstreaming for every later item sharing the player.
   *
   * It is held as a generation rather than a flag because that hook is called on the app thread
   * while the mismatch is discovered on the playback thread. A late buffer from the outgoing stream
   * can land after the new item began; latching the generation the carrier was configured for makes
   * that write name the stream it belongs to instead of poisoning its successor.
   */
  private val mediaGeneration = AtomicInteger(0)

  /** Generation [mediaGeneration] held when the carrier was last configured; playback thread. */
  private var configuredGeneration = 0

  @Volatile
  private var mismatchGeneration = -1

  /**
   * True when this format should ride the carrier.
   *
   * Speed changes are excluded deliberately: a bitstream cannot be resampled, so anything other
   * than 1.0x has to decode. The same is true of the existing downmix/normalization blocks, which
   * [directOutputBlocked] already reports.
   *
   * The rate family is decided from the format rather than from the packer, which only learns it
   * from a major sync once buffers are already flowing — far too late for a selection that happens
   * before configure.
   */
  private fun shouldUseCarrier(format: Format): Boolean {
    if (format.sampleMimeType != MimeTypes.AUDIO_TRUEHD) return false
    if (mismatchGeneration == mediaGeneration.get()) return false
    if (!isCarrierRateFamily(format.sampleRate)) return false
    if (playbackParameters.speed != 1f) return false
    if (directOutputBlocked(format)) return false
    return carrierRouteAvailable()
  }

  /**
   * The 48kHz family rides the 192kHz carrier this path builds. The 44.1kHz family needs a 176.4kHz
   * carrier, which would be a different AudioTrack tuple throughout, so it decodes instead.
   */
  private fun isCarrierRateFamily(sampleRate: Int): Boolean = sampleRate == 48_000 || sampleRate == 96_000 || sampleRate == 192_000

  /** The PCM-shaped format the carrier delegate is configured with. */
  private fun carrierFormat(): Format = Format.Builder()
    .setSampleMimeType(MimeTypes.AUDIO_RAW)
    .setPcmEncoding(C.ENCODING_PCM_16BIT)
    .setChannelCount(TrueHdMatPacker.CARRIER_CHANNEL_COUNT)
    .setSampleRate(TrueHdMatPacker.CARRIER_SAMPLE_RATE)
    .build()

  /**
   * TrueHD is deliberately binary: the carrier, or decoded PCM. Never media3's own raw TrueHD path.
   *
   * That path builds an `ENCODING_DOLBY_TRUEHD` track at the *stream* rate, which is the
   * configuration this issue is about — one box takes a single write and never advances its
   * playback head, another freezes for ten seconds, and the third declines it and decodes anyway.
   * Even Kodi's raw fallback is a different thing: it only offers raw TrueHD after verifying it at
   * 192kHz, which media3 never requests. So when the carrier is unavailable — no IEC route, a speed
   * change, downmix, normalization, or a 44.1kHz-family stream — report unsupported and let the
   * bundled FFmpeg decoder take it, exactly as the existing decoded-PCM fallback does.
   */
  private fun isTrueHd(format: Format): Boolean = format.sampleMimeType == MimeTypes.AUDIO_TRUEHD

  override fun supportsFormat(format: Format): Boolean = when {
    shouldUseCarrier(format) -> true
    isTrueHd(format) -> false
    else -> defaultSink.supportsFormat(format)
  }

  override fun getFormatSupport(format: Format): Int = when {
    shouldUseCarrier(format) -> AudioSink.SINK_FORMAT_SUPPORTED_DIRECTLY
    isTrueHd(format) -> AudioSink.SINK_FORMAT_UNSUPPORTED
    else -> defaultSink.getFormatSupport(format)
  }

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
    configuredGeneration = mediaGeneration.get()
    active = if (useCarrier) carrierSink else defaultSink
    discardCarrierState()

    if (useCarrier) {
      carrierSink.configure(carrierFormat(), specifiedBufferSize, null)
    } else {
      defaultSink.configure(inputFormat, specifiedBufferSize, outputChannels)
    }
  }

  override fun handleBuffer(buffer: ByteBuffer, presentationTimeUs: Long, encodedAccessUnitCount: Int): Boolean {
    if (!carrierActive) return defaultSink.handleBuffer(buffer, presentationTimeUs, encodedAccessUnitCount)

    // A refused burst blocks everything: placing it must come before consuming more input, or the
    // carrier would lose a frame.
    pendingBurst?.let { burst ->
      if (!carrierSink.handleBuffer(burst, pendingBurstTimeUs, 1)) return false
      pendingBurst = null
    }
    if (!buffer.hasRemaining()) return true
    if (carrierAnchorUs == C.TIME_UNSET) carrierAnchorUs = presentationTimeUs

    // One media3 sample holds many access units. The buffer position advances per unit, so a burst
    // the delegate refuses leaves the units behind it in the buffer for the retry rather than
    // dropping them — media3 re-delivers the same buffer whenever this returns false.
    val remaining = ByteArray(buffer.remaining())
    buffer.duplicate().get(remaining)

    var offset = 0
    while (offset < remaining.size) {
      val length = TrueHdMatPacker.accessUnitLength(remaining, offset, remaining.size)
      if (length == 0) {
        // Not a unit boundary we recognise. Consuming the tail keeps the stream moving; trying to
        // resynchronise mid-carrier would splice a frame.
        buffer.position(buffer.limit())
        return true
      }
      val burst = packer.packAccessUnit(remaining, offset, length)
      if (packer.unsupportedRateFamily) {
        // Selection is made from Format.sampleRate, so the bitstream disagrees with its container.
        // The packer emits nothing in that state; consuming here would turn the stream into
        // silence. Leave this unit in the buffer, latch the carrier off, and ask for reselection so
        // the decoder takes over and receives it.
        if (mismatchGeneration != configuredGeneration) {
          mismatchGeneration = configuredGeneration
          log?.invoke(
            "warn",
            "audio",
            "TrueHD bitstream announced a 44.1kHz-family rate its container did not; " +
              "leaving the carrier so it decodes"
          )
          sinkListener?.onAudioCapabilitiesChanged()
        }
        return false
      }
      offset += length
      buffer.position(buffer.position() + length)
      if (burst == null) continue

      val burstTimeUs = carrierAnchorUs + burstsSinceAnchor * CARRIER_BURST_DURATION_US
      burstsSinceAnchor++
      if (!carrierSink.handleBuffer(burst, burstTimeUs, 1)) {
        pendingBurst = burst
        pendingBurstTimeUs = burstTimeUs
        return false
      }
    }
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
    sinkListener = listener
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
    val wasUnitSpeed = this.playbackParameters.speed == 1f
    val isUnitSpeed = playbackParameters.speed == 1f
    this.playbackParameters = playbackParameters
    defaultSink.setPlaybackParameters(playbackParameters)
    // A bitstream cannot be resampled, and the carrier delegate has no processor chain to do it
    // with, so it is never handed a speed nothing can apply.
    carrierSink.setPlaybackParameters(
      if (isUnitSpeed) playbackParameters else PlaybackParameters.DEFAULT
    )

    // Crossing 1x changes whether TrueHD may ride the carrier, but nothing re-asks on its own:
    // the renderer only consults the sink when capabilities are invalidated. Rebuilding the track
    // selector parameters is not enough either — DefaultTrackSelector skips invalidation when the
    // rebuilt parameters compare equal. This is the path media3 itself uses for a route change,
    // and it reaches onRendererCapabilitiesChanged, so the format is re-evaluated and TrueHD moves
    // between the carrier and the decoder.
    if (wasUnitSpeed != isUnitSpeed && (carrierActive || isUnitSpeed)) {
      log?.invoke(
        "info",
        "audio",
        "Playback speed ${if (isUnitSpeed) "returned to" else "left"} 1.0x; re-evaluating the TrueHD carrier"
      )
      sinkListener?.onAudioCapabilitiesChanged()
    }
  }

  /** Whether TrueHD is currently riding the carrier. Read by the core when speed changes. */
  val isCarrierActive: Boolean
    get() = carrierActive

  /**
   * While the carrier is live the delegate is deliberately pinned to 1x, but the player polls this
   * through the media clock and adopts whatever it reads. Reporting the delegate's value would push
   * the pinned 1x back and silently undo the user's speed change, so the requested parameters are
   * reported instead; the reselection triggered above then moves TrueHD onto the decoder, which
   * really can apply them.
   */
  override fun getPlaybackParameters(): PlaybackParameters = if (carrierActive) playbackParameters else active.getPlaybackParameters()

  override fun setSkipSilenceEnabled(skipSilenceEnabled: Boolean) {
    // Only the normal sink: the carrier delegate is fed a fixed-rate bitstream,
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

  /**
   * Called by the owner immediately before a new media item is set, which is the only point where
   * "this stream lied about its rate" stops being true and the carrier can be offered again.
   */
  fun beginMediaItem() {
    mediaGeneration.incrementAndGet()
  }

  override fun release() {
    mediaGeneration.incrementAndGet()
    discardCarrierState()
    defaultSink.release()
    carrierSink.release()
  }
}
