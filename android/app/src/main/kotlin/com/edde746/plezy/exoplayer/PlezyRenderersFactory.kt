package com.edde746.plezy.exoplayer

import android.content.Context
import android.media.AudioDeviceInfo
import android.os.Build
import android.os.Handler
import androidx.annotation.OptIn
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.ChannelMixingAudioProcessor
import androidx.media3.common.audio.ChannelMixingMatrix
import androidx.media3.common.util.Clock
import androidx.media3.common.util.UnstableApi
import androidx.media3.decoder.DecoderInputBuffer
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.Renderer
import androidx.media3.exoplayer.analytics.PlayerId
import androidx.media3.exoplayer.audio.AudioOutput
import androidx.media3.exoplayer.audio.AudioOutputProvider
import androidx.media3.exoplayer.audio.AudioRendererEventListener
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.AudioTrackAudioOutputProvider
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.audio.DefaultAudioTrackBufferSizeProvider
import androidx.media3.exoplayer.audio.ForwardingAudioSink
import androidx.media3.exoplayer.mediacodec.MediaCodecAdapter
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector
import androidx.media3.exoplayer.video.MediaCodecVideoRenderer
import androidx.media3.exoplayer.video.VideoRendererEventListener
import com.edde746.plezy.TvDetection
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicLong
import kotlin.math.abs

@OptIn(UnstableApi::class)
class PlezyRenderersFactory(context: Context) : DefaultRenderersFactory(context) {

  /**
   * Android TV: MediaCodec.setOutputSurface is broken on many TV SoCs (Sony Bravia
   * MediaTek etc., ExoPlayer #5119/#8329) — force full codec re-init on surface
   * changes instead (#1481). TV-only: phones keep the fast path for PiP churn.
   */
  private val forceSetOutputSurfaceWorkaround: Boolean = TvDetection.isTv(context)

  /** Audio delay in microseconds. Shared with PositionFixAudioSink for live updates. */
  val audioDelayUs = AtomicLong(0L)

  /**
   * Stereo-downmix processor; inactive while every registered matrix is identity.
   * Pre-populated for counts 1..12 so sink configure can never hit
   * "No mixing matrix for input channel count". ExoPlayerCore swaps in
   * downmix matrices via [DownmixMatrices] when the setting is enabled.
   */
  private val identityChannelMixingMatrices = Array(DownmixMatrices.MAX_MIXING_CHANNELS) { index ->
    val channelCount = index + 1
    ChannelMixingMatrix(
      channelCount,
      channelCount,
      DownmixMatrices.identityCoefficients(channelCount)
    )
  }

  val channelMixProcessor = ChannelMixingAudioProcessor().apply {
    for (matrix in identityChannelMixingMatrices) putChannelMixingMatrix(matrix)
  }

  fun identityChannelMixingMatrix(channelCount: Int): ChannelMixingMatrix = identityChannelMixingMatrices[channelCount - 1]

  /** Returns whether direct encoded output should be hidden so decoded PCM output can be selected. */
  var shouldBlockDirectAudioOutput: ((Format) -> Boolean)? = null

  /** Called before Media3 reacts to an audio route/capability change. */
  var onAudioCapabilitiesChanged: (() -> Unit)? = null

  var audioDiagnosticsLogger: ((String, String, String) -> Unit)? = null

  var videoDiagnosticsLogger: ((String, String, String) -> Unit)? = null

  override fun buildVideoRenderers(
    context: Context,
    extensionRendererMode: Int,
    mediaCodecSelector: MediaCodecSelector,
    enableDecoderFallback: Boolean,
    eventHandler: Handler,
    eventListener: VideoRendererEventListener,
    allowedVideoJoiningTimeMs: Long,
    out: ArrayList<Renderer>
  ) {
    // Let super build the full list (including optional extension renderers),
    // then swap the stock MediaCodecVideoRenderer for the DV-sanitizing variant
    // at the same index.
    super.buildVideoRenderers(
      context,
      extensionRendererMode,
      mediaCodecSelector,
      enableDecoderFallback,
      eventHandler,
      eventListener,
      allowedVideoJoiningTimeMs,
      out
    )
    val index = out.indexOfFirst { it.javaClass == MediaCodecVideoRenderer::class.java }
    if (index < 0) return
    out[index] = DvSanitizingVideoRenderer(
      MediaCodecVideoRenderer.Builder(context)
        .setCodecAdapterFactory(codecAdapterFactory)
        .setMediaCodecSelector(mediaCodecSelector)
        .setAllowedJoiningTimeMs(allowedVideoJoiningTimeMs)
        .setEnableDecoderFallback(enableDecoderFallback)
        .setEventHandler(eventHandler)
        .setEventListener(eventListener)
        .setMaxDroppedFramesToNotify(MAX_DROPPED_VIDEO_FRAME_COUNT_TO_NOTIFY),
      forceSetOutputSurfaceWorkaround,
      videoDiagnosticsLogger
    )
  }

  /**
   * Records which audio renderers the session actually got. Whether the bundled
   * FFmpeg renderer loaded decides between decoding TrueHD/DTS-HD in ExoPlayer and
   * bailing to the mpv fallback, and nothing else in an uploaded log distinguishes
   * the two (#1703).
   */
  override fun buildAudioRenderers(
    context: Context,
    extensionRendererMode: Int,
    mediaCodecSelector: MediaCodecSelector,
    enableDecoderFallback: Boolean,
    audioSink: AudioSink,
    eventHandler: Handler,
    eventListener: AudioRendererEventListener,
    out: ArrayList<Renderer>
  ) {
    val firstAudioIndex = out.size
    super.buildAudioRenderers(
      context,
      extensionRendererMode,
      mediaCodecSelector,
      enableDecoderFallback,
      audioSink,
      eventHandler,
      eventListener,
      out
    )
    audioDiagnosticsLogger?.invoke(
      "info",
      "audio",
      "Audio renderers: " + out.subList(firstAudioIndex, out.size).joinToString { it.name }
    )
  }

  override fun buildAudioSink(
    context: Context,
    enableFloatOutput: Boolean,
    enableAudioOutputPlaybackParams: Boolean
  ): AudioSink {
    AudioTrackAudioOutputProvider.failOnSpuriousAudioTimestamp = false

    val bufferSizeProvider = DefaultAudioTrackBufferSizeProvider.Builder()
      .setMinPcmBufferDurationUs(500_000)
      .setMaxPcmBufferDurationUs(1_000_000)
      .setPcmBufferMultiplicationFactor(4)
      // media3 defaults passthrough to 250ms, which the AC3 factor doubles to 500ms — 40000
      // bytes at 640 kbps. Some HDMI routes reject a buffer that short outright and the only
      // retry media3 1.10.1 has is to keep halving it (#1790). Ask for a second up front;
      // upstream adopted the same 1s floor as its last-resort retry in #3207.
      .setPassthroughBufferDurationUs(500_000)
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
      // Wraps in DefaultAudioProcessorChain, keeping stock silence-skip +
      // Sonic; the downmix runs first and only in the decoded-PCM path.
      .setAudioProcessors(arrayOf(channelMixProcessor))
      .setAudioOutputProvider(RawPositionOutputProvider(realProvider, rawPositionUs, audioDiagnosticsLogger))
      .build()

    val processedSink = PositionFixAudioSink(
      defaultSink,
      rawPositionUs,
      audioDelayUs,
      shouldBlockDirectAudioOutput,
      onAudioCapabilitiesChanged,
      audioDiagnosticsLogger
    )

    return TrueHdCarrierSink(
      defaultSink = processedSink,
      carrierSink = buildCarrierSink(context, bufferSizeProvider),
      carrierRouteAvailable = { supportsTrueHdMatCarrier(context) },
      directOutputBlocked = { format -> shouldBlockDirectAudioOutput?.invoke(format) == true },
      log = audioDiagnosticsLogger
    )
  }

  /**
   * The delegate that carries packed TrueHD (#1804).
   *
   * Deliberately separate from the processed sink, and deliberately barren: an empty
   * [DefaultAudioSink.AudioProcessorChain] means no downmix, no Sonic, no silence skipping and no
   * float conversion can ever touch the bytes. The carrier only looks like PCM; a single mutated
   * sample reaches the receiver as full-scale noise rather than as a glitch.
   *
   * The output provider keeps `OutputConfig.encoding` at PCM 16-bit so every position, pending-data
   * and release accounting in media3 stays in its mature PCM path — which is correct here, because
   * after packing the stream genuinely is a fixed-rate 192kHz 8-channel carrier. Only the
   * `AudioTrack` itself is switched to `ENCODING_IEC61937`, via the builder modifier that upstream
   * applies immediately before `AudioTrack.Builder.build()`.
   */
  private fun buildCarrierSink(
    context: Context,
    bufferSizeProvider: DefaultAudioTrackBufferSizeProvider
  ): AudioSink {
    val provider = AudioTrackAudioOutputProvider.Builder(context)
      .setAudioTrackBufferSizeProvider(bufferSizeProvider)
      .apply {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
          setAudioTrackBuilderModifier { builder, config ->
            builder.setAudioFormat(
              android.media.AudioFormat.Builder()
                .setEncoding(android.media.AudioFormat.ENCODING_IEC61937)
                .setChannelMask(android.media.AudioFormat.CHANNEL_OUT_7POINT1_SURROUND)
                .setSampleRate(config.sampleRate)
                .build()
            )
            // The AudioTrackConfig media3 reports upstream is built from OutputConfig, which stays
            // PCM so the accounting stays in the PCM domain — so it cannot show the real encoding.
            // This is the only place that can confirm what the AudioTrack was actually built as.
            audioDiagnosticsLogger?.invoke(
              "info",
              "audio",
              "Carrier AudioTrack: encoding=IEC61937 rate=${config.sampleRate} " +
                "mask=0x${android.media.AudioFormat.CHANNEL_OUT_7POINT1_SURROUND.toString(16)} " +
                "buffer=${config.bufferSize}"
            )
          }
        }
      }
      .build()

    return DefaultAudioSink.Builder(context)
      .setEnableFloatOutput(false)
      // Not DefaultAudioProcessorChain: that one appends silence-skipping and Sonic whatever it is
      // constructed with, and either would rewrite carrier bytes. This chain has nothing in it, so
      // AudioProcessingPipeline is a straight passthrough. Speed is reported as applied without
      // resampling because the carrier delegate routes playback parameters to the AudioTrack, and
      // the sink refuses the carrier outright at any speed other than 1.0x.
      .setAudioProcessorChain(EmptyAudioProcessorChain())
      .setAudioOutputProvider(provider)
      .build()
  }
}

/**
 * An [AudioProcessorChain] that owns no processors, for the MAT carrier delegate (#1804).
 *
 * `DefaultAudioProcessorChain` always contributes silence-skipping and Sonic; both rewrite samples,
 * which is fatal to a bit-exact IEC 61937 carrier. Speed is reported back unchanged because the
 * carrier delegate applies playback parameters at the AudioTrack, and the routing sink declines the
 * carrier entirely at any speed other than 1.0x.
 */
@OptIn(UnstableApi::class)
private class EmptyAudioProcessorChain : DefaultAudioSink.AudioProcessorChain {
  override fun getAudioProcessors(): Array<AudioProcessor> = emptyArray()
  override fun applyPlaybackParameters(playbackParameters: PlaybackParameters): PlaybackParameters = playbackParameters
  override fun applySkipSilenceEnabled(skipSilenceEnabled: Boolean): Boolean = false
  override fun getMediaDuration(playoutDuration: Long): Long = playoutDuration
  override fun getSkippedOutputFrameCount(): Long = 0L
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
  private val rawPositionUs: AtomicLong,
  private val audioDelayUs: AtomicLong,
  private val shouldBlockDirectAudioOutput: ((Format) -> Boolean)?,
  private val onAudioCapabilitiesChanged: (() -> Unit)?,
  private val log: ((String, String, String) -> Unit)?
) : ForwardingAudioSink(sink) {

  private var startMediaTimeUs = Long.MIN_VALUE
  private var suppressedErrorCount = 0

  // Speed tracking for position bypass
  private var currentSpeed = 1.0f
  private var refMediaTimeUs = Long.MIN_VALUE
  private var refRawPositionUs = 0L

  // Transient counter-offset: after seek/flush, ramp offset from 0 to full
  // over recoveryDurationUs to prevent video frame drops.
  private var recoveryDurationUs = 0L
  private val loggedDirectBlockMimeTypes = mutableSetOf<String>()
  private var loggedFirstBuffer = false

  override fun supportsFormat(format: Format): Boolean {
    if (blocksDirectAudioOutput(format)) return false
    return super.supportsFormat(format)
  }

  override fun getFormatSupport(format: Format): Int {
    if (blocksDirectAudioOutput(format)) return AudioSink.SINK_FORMAT_UNSUPPORTED
    return super.getFormatSupport(format)
  }

  private fun blocksDirectAudioOutput(format: Format): Boolean {
    if (shouldBlockDirectAudioOutput?.invoke(format) != true) return false
    val mimeType = format.sampleMimeType ?: "unknown"
    if (loggedDirectBlockMimeTypes.add(mimeType)) {
      log?.invoke(
        "info",
        "audio",
        "Blocking direct $mimeType output; decoded PCM output will be preferred"
      )
    }
    return true
  }

  override fun handleBuffer(
    buffer: ByteBuffer,
    presentationTimeUs: Long,
    encodedAccessUnitCount: Int
  ): Boolean {
    if (!loggedFirstBuffer && buffer.hasRemaining()) {
      loggedFirstBuffer = true
      log?.invoke(
        "debug",
        "audio-sink",
        "First buffer: size=${buffer.remaining()}B, pts=${presentationTimeUs}us, accessUnits=$encodedAccessUnitCount"
      )
    }
    if (startMediaTimeUs == Long.MIN_VALUE) {
      startMediaTimeUs = presentationTimeUs
      refMediaTimeUs = presentationTimeUs
      refRawPositionUs = 0
      val delayUs = audioDelayUs.get()
      recoveryDurationUs = if (delayUs == 0L) 0L else maxOf(200_000L, 2L * abs(delayUs))
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
    val basePos = if (rawPos <= 0) {
      delegatePos
    } else {
      val expectedPos = refMediaTimeUs + ((rawPos - refRawPositionUs) * currentSpeed).toLong()
      if (expectedPos > delegatePos + 30_000) expectedPos else delegatePos
    }

    // Audio delay with transient counter-offset to prevent frame drops after seeks.
    // After flush, offset ramps linearly from 0 to full over recoveryDurationUs.
    val delayUs = audioDelayUs.get()
    if (delayUs == 0L) return basePos

    val elapsedUs = basePos - startMediaTimeUs
    val netOffsetUs = if (recoveryDurationUs <= 0L || elapsedUs >= recoveryDurationUs) {
      delayUs
    } else {
      (delayUs * elapsedUs) / recoveryDurationUs
    }
    return basePos + netOffsetUs
  }

  // --- Suppress timestamp discontinuity errors ---

  override fun setListener(listener: AudioSink.Listener) {
    super.setListener(
      @OptIn(UnstableApi::class) object : AudioSink.Listener {
        override fun onPositionDiscontinuity() = listener.onPositionDiscontinuity()
        override fun onPositionAdvancing(playoutStartSystemTimeUs: Long) = listener.onPositionAdvancing(playoutStartSystemTimeUs)
        override fun onUnderrun(bufferSize: Int, bufferSizeMs: Long, elapsedSinceLastFeedMs: Long) = listener.onUnderrun(bufferSize, bufferSizeMs, elapsedSinceLastFeedMs)
        override fun onSkipSilenceEnabledChanged(skipSilenceEnabled: Boolean) = listener.onSkipSilenceEnabledChanged(skipSilenceEnabled)
        override fun onOffloadBufferEmptying() = listener.onOffloadBufferEmptying()
        override fun onOffloadBufferFull() = listener.onOffloadBufferFull()
        override fun onAudioCapabilitiesChanged() {
          onAudioCapabilitiesChanged?.invoke()
          listener.onAudioCapabilitiesChanged()
        }
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
      }
    )
  }

  override fun flush() {
    startMediaTimeUs = Long.MIN_VALUE
    refMediaTimeUs = Long.MIN_VALUE
    refRawPositionUs = 0
    recoveryDurationUs = 0L
    rawPositionUs.set(Long.MIN_VALUE)
    super.flush()
  }

  override fun reset() {
    startMediaTimeUs = Long.MIN_VALUE
    refMediaTimeUs = Long.MIN_VALUE
    refRawPositionUs = 0
    recoveryDurationUs = 0L
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

/**
 * Wraps a text renderer to shift subtitle timing by [delayUs] microseconds.
 * Positive delay → subtitles appear later, negative → earlier.
 * Only render() needs the offset — the text renderer uses positionUs to decide
 * which cues are active; other Renderer methods are timing-independent.
 */
@OptIn(UnstableApi::class)
internal class SubtitleDelayRenderer(
  private val delegate: Renderer,
  private val delayUs: AtomicLong
) : Renderer by delegate {
  override fun render(positionUs: Long, elapsedRealtimeUs: Long) {
    delegate.render(positionUs - delayUs.get(), elapsedRealtimeUs)
  }
}

/**
 * MediaCodecVideoRenderer that resolves the DV / HDR10+ dual-dynamic-metadata conflict
 * per decode path (#1296, generalizes androidx/media#3085):
 * - native DV codec selected (media3 only selects one when decoder AND display support DV):
 *   strip in-band HDR10+ SEI — conflicting dynamic metadata crashes Fire TV-class chipsets
 * - HEVC fallback for an HEVC-based DV format: strip DV RPU/EL NALs (profiles 7/8, where the
 *   base layer remains valid HDR10/HLG), keeping HDR10+ for the display
 *
 * Flags are reassigned on every codec init: tunneling toggles and DV retries re-init the
 * codec without recreating renderers, and decoder fallback can switch the codec MIME.
 */
@OptIn(UnstableApi::class)
internal class DvSanitizingVideoRenderer(
  builder: Builder,
  private val forceSetOutputSurfaceWorkaround: Boolean,
  private val log: ((String, String, String) -> Unit)?
) : MediaCodecVideoRenderer(builder) {

  private val sanitizer = DvBitstreamSanitizer()

  private var stripHdr10PlusSei = false
  private var stripDvRpu = false
  private var loggedSurfaceWorkaround = false

  // On TV SoCs MediaCodec.setOutputSurface() silently yields a black picture after
  // the screensaver/background destroys and recreates the surface (#1481). Returning
  // true makes media3 release + re-init the codec instead. media3's built-in device
  // list doesn't cover 2019+ Bravias; consulted once per codec init.
  override fun codecNeedsSetOutputSurfaceWorkaround(name: String): Boolean {
    if (forceSetOutputSurfaceWorkaround) {
      if (!loggedSurfaceWorkaround) {
        loggedSurfaceWorkaround = true
        log?.invoke(
          "info",
          "video",
          "TV setOutputSurface workaround active: codec will fully re-init on surface changes (codec=$name)"
        )
      }
      return true
    }
    return super.codecNeedsSetOutputSurfaceWorkaround(name)
  }

  // Sanitize diagnostics — playback-thread only, cumulative for the renderer's lifetime.
  private var sanitizedSampleCount = 0L
  private var totalSanitizeTimeUs = 0L
  private var maxSanitizeTimeUs = 0L
  private var totalStrippedNals = 0L
  private var totalStrippedBytes = 0L

  override fun onCodecInitialized(
    name: String,
    configuration: MediaCodecAdapter.Configuration,
    initializedTimestampMs: Long,
    initializationDurationMs: Long
  ) {
    super.onCodecInitialized(name, configuration, initializedTimestampMs, initializationDurationMs)
    val codecs = configuration.format.codecs?.lowercase() ?: ""
    val dvHevcFormat = configuration.format.sampleMimeType == MimeTypes.VIDEO_DOLBY_VISION &&
      (codecs.startsWith("dvhe.") || codecs.startsWith("dvh1."))
    val codecMimeType = configuration.codecInfo.codecMimeType
    val newStripHdr10PlusSei = dvHevcFormat && codecMimeType == MimeTypes.VIDEO_DOLBY_VISION
    val newStripDvRpu = dvHevcFormat &&
      codecMimeType == MimeTypes.VIDEO_H265 &&
      isBlCompatibleDvProfile(codecs)
    if (newStripHdr10PlusSei != stripHdr10PlusSei || newStripDvRpu != stripDvRpu) {
      log?.invoke(
        "info",
        "video",
        "DV bitstream sanitizing: stripHdr10PlusSei=$newStripHdr10PlusSei, " +
          "stripDvRpu=$newStripDvRpu (codec=$name, codecs=${configuration.format.codecs})"
      )
    }
    stripHdr10PlusSei = newStripHdr10PlusSei
    stripDvRpu = newStripDvRpu
  }

  override fun onQueueInputBuffer(buffer: DecoderInputBuffer) {
    if (stripHdr10PlusSei || stripDvRpu) {
      val data = buffer.data
      if (data != null && data.hasRemaining() && !buffer.isEncrypted) {
        val sizeBefore = data.remaining()
        val startNs = System.nanoTime()
        val stripped = sanitizer.sanitize(data, stripHdr10PlusSei, stripDvRpu)
        val elapsedUs = (System.nanoTime() - startNs) / 1_000
        sanitizedSampleCount++
        totalSanitizeTimeUs += elapsedUs
        if (elapsedUs > maxSanitizeTimeUs) maxSanitizeTimeUs = elapsedUs
        totalStrippedNals += stripped
        totalStrippedBytes += sizeBefore - data.remaining()
        if (sanitizedSampleCount <= 3 || sanitizedSampleCount % 500 == 0L) {
          log?.invoke(
            "debug",
            "dv-sanitize",
            "Sample #$sanitizedSampleCount: ${sizeBefore}B -> ${data.remaining()}B, " +
              "stripped=$stripped, took=${elapsedUs}us " +
              "(avg=${totalSanitizeTimeUs / sanitizedSampleCount}us, max=${maxSanitizeTimeUs}us, " +
              "totalNals=$totalStrippedNals, totalBytes=${totalStrippedBytes}B)"
          )
        }
      }
    }
    super.onQueueInputBuffer(buffer)
  }

  private fun isBlCompatibleDvProfile(codecs: String): Boolean = codecs.startsWith("dvhe.07") ||
    codecs.startsWith("dvh1.07") ||
    codecs.startsWith("dvhe.08") ||
    codecs.startsWith("dvh1.08")
}

// --- AudioOutput wrapping: shares raw position with PositionFixAudioSink ---
// Also implements AudioTrack reuse across seeks to avoid expensive teardown/recreation.
// DefaultAudioSink releases the AudioOutput on every flush (seek), which destroys the
// AudioTrack and creates a new one. On Android TV with tunneled playback, this causes
// 7-10s audio dropout while the hardware pipeline reinitializes (Sony Bravia, etc).
// By flushing instead of releasing and caching the output, we skip the teardown cycle.
//
// Two invariants keep that safe (#1790):
//
//  1. Only outputs [AudioOutputCachePolicy] admits are parked, so the cache never holds a
//     scarce direct/passthrough route hostage while the next one is being created.
//  2. Every flush is answered by exactly one onReleased, promptly.
//
// DefaultAudioSink increments a *static, process-wide* counter on every flush and decrements it
// only from `Listener::onReleased`, which media3 delivers by posting to the playback looper — a
// looper that is already dead by the time a player-release actually completes. A dropped callback
// pins the counter above zero, and any nonzero value disables media3's escalation of *both* init
// and write failures: `PendingExceptionHolder` refuses to arm its throw deadline and every retry
// short-circuits, so a sink error never becomes a PlaybackException and playback hangs in
// STATE_BUFFERING with no recovery. The wrapper therefore owns the listener set and answers the
// flush itself when it parks the track, because a parked track is never going to release.
//
// Deferring that answer until the parked track is really evicted is tempting — it would let
// media3 stay patient through the eviction, whose replacement is built while the old AudioTrack
// is still going away — but it holds the counter above zero for the whole live track after the
// first seek, which is the very hang above. So the eviction overlap is tolerated instead, as
// upstream tolerates it: if the replacement does fail to allocate, media3 escalates on its own
// 200ms deadline into the audio recovery ladder, and the buffering stall watchdog backs that up.
//
// Everything below is confined to the ExoPlayer playback thread: sink flush/release, provider
// lookups, and media3's own onReleased delivery all run there.

@OptIn(UnstableApi::class)
internal class RawPositionOutputProvider(
  private val delegate: AudioOutputProvider,
  private val rawPositionUs: AtomicLong,
  private val log: ((String, String, String) -> Unit)?,
  private val sdkInt: Int = Build.VERSION.SDK_INT
) : AudioOutputProvider {

  private var cachedOutput: RawPositionAudioOutput? = null
  private var cachedConfig: AudioOutputProvider.OutputConfig? = null

  /** Outputs whose real release was started but whose completion has not been observed yet. */
  private val unsettledReleases = LinkedHashSet<RawPositionAudioOutput>()

  override fun getFormatSupport(config: AudioOutputProvider.FormatConfig) = delegate.getFormatSupport(config)

  override fun getOutputConfig(config: AudioOutputProvider.FormatConfig) = delegate.getOutputConfig(config)

  override fun getAudioOutput(config: AudioOutputProvider.OutputConfig): AudioOutput {
    val cached = cachedOutput
    if (cached != null && cachedConfig == config) {
      cachedOutput = null
      cached.markReacquired()
      return cached
    }
    cached?.forceRelease()
    cachedOutput = null
    cachedConfig = null

    // The replacement is built while the evicted track is still going away. Upstream does the
    // same; the alternatives are worse (see the note above this class).
    val realOutput = delegate.getAudioOutput(config)
    cachedConfig = config
    return RawPositionAudioOutput(
      delegate = realOutput,
      rawPositionUs = rawPositionUs,
      provider = this,
      mayCache = AudioOutputCachePolicy.mayCache(config.encoding, config.isOffload, sdkInt),
      log = log
    )
  }

  fun returnToCache(output: RawPositionAudioOutput) {
    val existing = cachedOutput
    if (existing != null && existing !== output) {
      existing.forceRelease()
    }
    cachedOutput = output
  }

  fun onRealReleaseStarted(output: RawPositionAudioOutput) {
    unsettledReleases.add(output)
  }

  fun onReleaseSettled(output: RawPositionAudioOutput) {
    unsettledReleases.remove(output)
  }

  override fun addListener(listener: AudioOutputProvider.Listener) = delegate.addListener(listener)

  override fun removeListener(listener: AudioOutputProvider.Listener) = delegate.removeListener(listener)

  override fun setClock(clock: Clock) = delegate.setClock(clock)

  override fun release() {
    cachedOutput?.forceRelease()
    cachedOutput = null
    cachedConfig = null
    // Player teardown: media3 schedules the real AudioTrack release with a delay and posts the
    // completion back to the playback looper this call is in the middle of quitting, so nothing
    // will ever deliver it. Settle here rather than leak the accounting for the whole process.
    for (output in unsettledReleases.toList()) output.settleReleaseNow()
    unsettledReleases.clear()
    delegate.release()
  }
}

@OptIn(UnstableApi::class)
internal class RawPositionAudioOutput(
  private val delegate: AudioOutput,
  private val rawPositionUs: AtomicLong,
  private val provider: RawPositionOutputProvider,
  private val mayCache: Boolean,
  private val log: ((String, String, String) -> Unit)?
) : AudioOutput {

  private var loggedFirstWrite = false
  private var writeCount = 0L
  private var writtenBytes = 0L
  private var failed = false

  /**
   * DefaultAudioSink registers here instead of on the real output, so the wrapper can report the
   * releases media3 will not: a parked output never really releases, and a released output's
   * completion callback is posted to a playback looper that may already be gone. The set is
   * cleared on every release report and repopulated by the sink on the next acquisition, which
   * also stops one stale listener per reuse from piling up on the real output.
   */
  private val listeners = mutableListOf<AudioOutput.Listener>()
  private var releaseSignalled = false

  private val currentListener: AudioOutput.Listener?
    get() = listeners.lastOrNull()

  private val forwarder = object : AudioOutput.Listener {
    override fun onPositionAdvancing(playoutStartSystemTimeMs: Long) {
      currentListener?.onPositionAdvancing(playoutStartSystemTimeMs)
    }

    override fun onOffloadDataRequest() {
      currentListener?.onOffloadDataRequest()
    }

    override fun onOffloadPresentationEnded() {
      currentListener?.onOffloadPresentationEnded()
    }

    override fun onUnderrun() {
      currentListener?.onUnderrun()
    }

    override fun onReleased() {
      provider.onReleaseSettled(this@RawPositionAudioOutput)
      signalReleased()
    }
  }

  init {
    delegate.addListener(forwarder)
  }

  override fun getPositionUs(): Long {
    val pos = delegate.getPositionUs()
    rawPositionUs.set(pos)
    return pos
  }

  override fun play() = delegate.play()
  override fun pause() = delegate.pause()

  @Throws(AudioOutput.WriteException::class)
  override fun write(buffer: ByteBuffer, size: Int, presentationTimeUs: Long): Boolean {
    val before = buffer.position()
    val handled = try {
      delegate.write(buffer, size, presentationTimeUs)
    } catch (e: AudioOutput.WriteException) {
      failed = true
      rawPositionUs.set(Long.MIN_VALUE)
      log?.invoke("warn", "audio-output", "Write failed; AudioTrack will not be reused: ${e.message}")
      throw e
    }
    val written = buffer.position() - before
    if (written > 0) {
      writeCount++
      writtenBytes += written.toLong()
      if (!loggedFirstWrite) {
        loggedFirstWrite = true
        log?.invoke(
          "debug",
          "audio-output",
          "First write: wrote=${written}B, handled=$handled, pts=${presentationTimeUs}us, writes=$writeCount, total=${writtenBytes}B"
        )
      }
    }
    return handled
  }

  override fun flush() {
    rawPositionUs.set(Long.MIN_VALUE)
    loggedFirstWrite = false
    writeCount = 0
    writtenBytes = 0
    delegate.flush()
  }

  override fun stop() = delegate.stop()

  override fun release() {
    rawPositionUs.set(Long.MIN_VALUE)
    if (!failed && mayCache) {
      delegate.stop()
      delegate.flush()
      provider.returnToCache(this)
      // A parked track is never going to release, so answer the flush now. Holding the sink's
      // pending-release count open for it would disable media3's escalation of every later sink
      // error, for as long as the track stays parked or live — the #1790 hang, re-armed by an
      // ordinary seek.
      signalReleased()
      return
    }
    startRealRelease()
  }

  /** Releases for real even when the output would otherwise be cacheable. */
  fun forceRelease() {
    rawPositionUs.set(Long.MIN_VALUE)
    startRealRelease()
  }

  /** Reports a release whose completion callback can no longer be delivered. */
  fun settleReleaseNow() {
    provider.onReleaseSettled(this)
    signalReleased()
  }

  /** Re-arms the wrapper for a fresh acquisition out of the provider's cache. */
  fun markReacquired() {
    releaseSignalled = false
  }

  private fun startRealRelease() {
    provider.onRealReleaseStarted(this)
    delegate.release()
  }

  private fun signalReleased() {
    if (releaseSignalled) return
    releaseSignalled = true
    val notified = listeners.toList()
    listeners.clear()
    for (listener in notified) listener.onReleased()
  }

  override fun setVolume(volume: Float) = delegate.setVolume(volume)
  override fun isOffloadedPlayback() = delegate.isOffloadedPlayback()
  override fun getAudioSessionId() = delegate.getAudioSessionId()
  override fun getSampleRate() = delegate.getSampleRate()
  override fun getBufferSizeInFrames() = delegate.getBufferSizeInFrames()
  override fun getPlaybackParameters() = delegate.getPlaybackParameters()
  override fun isStalled() = delegate.isStalled()
  override fun addListener(listener: AudioOutput.Listener) {
    listeners.add(listener)
  }
  override fun removeListener(listener: AudioOutput.Listener) {
    listeners.remove(listener)
  }
  override fun setPlaybackParameters(playbackParameters: PlaybackParameters) = delegate.setPlaybackParameters(playbackParameters)
  override fun setOffloadDelayPadding(delayInFrames: Int, paddingInFrames: Int) = delegate.setOffloadDelayPadding(delayInFrames, paddingInFrames)
  override fun setOffloadEndOfStream() = delegate.setOffloadEndOfStream()
  override fun setPlayerId(playerId: PlayerId) = delegate.setPlayerId(playerId)
  override fun attachAuxEffect(effectId: Int) = delegate.attachAuxEffect(effectId)
  override fun setAuxEffectSendLevel(level: Float) = delegate.setAuxEffectSendLevel(level)
  override fun setPreferredDevice(preferredDevice: AudioDeviceInfo?) = delegate.setPreferredDevice(preferredDevice)
}
