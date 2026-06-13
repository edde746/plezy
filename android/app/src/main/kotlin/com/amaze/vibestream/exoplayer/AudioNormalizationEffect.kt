package com.amaze.vibestream.exoplayer

import android.media.audiofx.DynamicsProcessing
import android.media.audiofx.LoudnessEnhancer
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * Session-bound loudness normalization approximating mpv's
 * `loudnorm=I=-14:TP=-3:LRA=4` filter (#1289).
 *
 * API 28+: DynamicsProcessing with a single full-range compressor band as a
 * slow AGC plus a limiter for the true-peak ceiling. API 25-27, or when the
 * device lacks the DynamicsProcessing effect HAL: LoudnessEnhancer (fixed
 * makeup gain with built-in limiting).
 *
 * Effects bind to the audio session, so they survive AudioTrack re-creation
 * (seeks, format changes) while the session id is stable. They only process
 * PCM mixer streams — the caller must force decoded PCM output and disable
 * tunneling while enabled. DynamicsProcessing parameters are per-channel, so
 * the effect is re-created when the output channel count changes (dialogue
 * lives in the center channel of 5.1 PCM).
 */
class AudioNormalizationEffect(private val log: (String, String, String) -> Unit) {

  private companion object {
    const val EFFECT_PRIORITY = 0

    // DynamicsProcessing — tuned for movie mixes whose dialogue sits around
    // -27 LUFS: compress above threshold, make up toward I=-14, limit at TP=-3.
    const val FRAME_DURATION_MS = 10f
    const val MBC_CUTOFF_HZ = 20_000f
    const val MBC_ATTACK_MS = 30f
    const val MBC_RELEASE_MS = 300f
    const val MBC_RATIO = 4f
    const val MBC_THRESHOLD_DB = -34f
    const val MBC_KNEE_DB = 6f
    const val MBC_NOISE_GATE_DB = -90f // effectively disabled
    const val MBC_EXPANDER_RATIO = 1f // no downward expansion
    const val MBC_POST_GAIN_DB = 15f
    const val LIMITER_ATTACK_MS = 1f
    const val LIMITER_RELEASE_MS = 60f
    const val LIMITER_RATIO = 10f
    const val LIMITER_THRESHOLD_DB = -3f
    const val DEFAULT_CHANNEL_COUNT = 2
    const val MAX_CHANNEL_COUNT = 8

    // LoudnessEnhancer fallback: fixed boost, internally limited.
    const val LOUDNESS_ENHANCER_GAIN_MB = 900 // +9 dB
  }

  private var dynamicsProcessing: DynamicsProcessing? = null
  private var loudnessEnhancer: LoudnessEnhancer? = null
  private var attachedSessionId = 0
  private var attachedChannelCount = 0

  val isActive: Boolean get() = dynamicsProcessing != null || loudnessEnhancer != null

  /** For stats/QA: which engine is processing. */
  val describe: String
    get() = when {
      dynamicsProcessing != null -> "DynamicsProcessing"
      loudnessEnhancer != null -> "LoudnessEnhancer"
      else -> "off"
    }

  /** Attach to [sessionId]; idempotent for an unchanged (session, channels) pair. */
  fun attach(sessionId: Int, channelCount: Int?) {
    val channels = (channelCount ?: DEFAULT_CHANNEL_COUNT).coerceIn(1, MAX_CHANNEL_COUNT)
    if (sessionId == attachedSessionId && channels == attachedChannelCount && isActive) return
    release()
    if (sessionId == 0) return // AUDIO_SESSION_ID_UNSET — retry on onAudioSessionIdChanged
    attachedSessionId = sessionId
    attachedChannelCount = channels
    if (Build.VERSION.SDK_INT >= 28 && tryDynamicsProcessing(sessionId, channels)) return
    tryLoudnessEnhancer(sessionId)
  }

  fun release() {
    dynamicsProcessing?.let { effect ->
      runCatching { effect.setEnabled(false) }
      runCatching { effect.release() }
    }
    dynamicsProcessing = null
    loudnessEnhancer?.let { effect ->
      runCatching { effect.setEnabled(false) }
      runCatching { effect.release() }
    }
    loudnessEnhancer = null
    attachedSessionId = 0
    attachedChannelCount = 0
  }

  @RequiresApi(28)
  private fun tryDynamicsProcessing(sessionId: Int, channelCount: Int): Boolean = try {
    val band = DynamicsProcessing.MbcBand(
      /* inUse = */ true,
      MBC_CUTOFF_HZ,
      MBC_ATTACK_MS,
      MBC_RELEASE_MS,
      MBC_RATIO,
      MBC_THRESHOLD_DB,
      MBC_KNEE_DB,
      MBC_NOISE_GATE_DB,
      MBC_EXPANDER_RATIO,
      /* preGain = */ 0f,
      MBC_POST_GAIN_DB
    )
    val mbc = DynamicsProcessing.Mbc(/* inUse = */ true, /* enabled = */ true, /* bandCount = */ 1)
      .apply { setBand(0, band) }
    val limiter = DynamicsProcessing.Limiter(
      /* inUse = */ true,
      /* enabled = */ true,
      /* linkGroup = */ 0,
      LIMITER_ATTACK_MS,
      LIMITER_RELEASE_MS,
      LIMITER_RATIO,
      LIMITER_THRESHOLD_DB,
      /* postGain = */ 0f
    )
    val channel = DynamicsProcessing.Channel(
      /* inputGain = */ 0f,
      /* preEqInUse = */ false, /* preEqBandCount = */ 0,
      /* mbcInUse = */ true, /* mbcBandCount = */ 1,
      /* postEqInUse = */ false, /* postEqBandCount = */ 0,
      /* limiterInUse = */ true
    ).apply {
      setMbc(mbc)
      setLimiter(limiter)
    }
    val config = DynamicsProcessing.Config.Builder(
      DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
      channelCount,
      /* preEqInUse = */ false, /* preEqBandCount = */ 0,
      /* mbcInUse = */ true, /* mbcBandCount = */ 1,
      /* postEqInUse = */ false, /* postEqBandCount = */ 0,
      /* limiterInUse = */ true
    )
      .setPreferredFrameDuration(FRAME_DURATION_MS)
      .setAllChannelsTo(channel)
      .build()
    dynamicsProcessing = DynamicsProcessing(EFFECT_PRIORITY, sessionId, config).apply { setEnabled(true) }
    log("info", "audio-normalization", "DynamicsProcessing attached (session=$sessionId, channels=$channelCount)")
    true
  } catch (e: Exception) {
    log(
      "warn",
      "audio-normalization",
      "DynamicsProcessing unavailable (${e.javaClass.simpleName}: ${e.message}); trying LoudnessEnhancer"
    )
    dynamicsProcessing = null
    false
  }

  private fun tryLoudnessEnhancer(sessionId: Int) {
    try {
      loudnessEnhancer = LoudnessEnhancer(sessionId).apply {
        setTargetGain(LOUDNESS_ENHANCER_GAIN_MB)
        setEnabled(true)
      }
      log("info", "audio-normalization", "LoudnessEnhancer attached (session=$sessionId, gain=${LOUDNESS_ENHANCER_GAIN_MB}mB)")
    } catch (e: Exception) {
      loudnessEnhancer = null
      attachedSessionId = 0
      attachedChannelCount = 0
      log(
        "warn",
        "audio-normalization",
        "No loudness effect available on this device (${e.javaClass.simpleName}: ${e.message})"
      )
    }
  }
}
