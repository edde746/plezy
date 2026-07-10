package com.edde746.plezy.exoplayer

import kotlin.math.pow

/**
 * Stereo downmix coefficient builder (Kodi-style center boost).
 *
 * Channel-order assumptions per input count follow the Android channel-mask
 * bit order that MediaCodec / the FFmpeg extension emit:
 * 3 = FL FR FC, 4 = FL FR BL BR, 5 = FL FR FC BL BR, 6 = FL FR FC LFE BL BR,
 * 7 = 6.1 (5.1 + BC), 8 = 7.1 (5.1 + SL SR). LFE is dropped, matching
 * ffmpeg's default lfe_mix_level=0 (and what the mpv backends produce).
 *
 * All coefficients must stay >= 0: ChannelMixingMatrix throws on negatives.
 */
object DownmixMatrices {
  const val MIN_DOWNMIX_INPUT_CHANNELS = 3
  const val MAX_DOWNMIX_INPUT_CHANNELS = 8
  const val MAX_CENTER_BOOST_DB = 12

  const val SURROUND_GAIN = 0.70710678f // -3 dB
  private const val BACK_CENTER_GAIN = 0.5f // SURROUND_GAIN split across both outputs

  /** Kodi's mechanism: center coefficient = 10^((-3 + boostDb) / 20); boost 0 is the standard -3 dB. */
  fun centerGain(centerBoostDb: Int): Float = 10f.pow((-3f + centerBoostDb.coerceIn(0, MAX_CENTER_BOOST_DB)) / 20f)

  /**
   * Row-major stereo coefficients ([inputChannel * 2 + outputChannel]), or null
   * when [inputChannels] is not downmixed (mono/stereo pass through; >8ch
   * unsupported, the caller keeps an identity matrix).
   *
   * [normalize] scales the matrix so the loudest output sum is <= 1 (cannot
   * clip); disabled keeps the original level like Kodi's "maintain original
   * volume" (the 16-bit mix saturates on clip).
   */
  fun stereoCoefficients(inputChannels: Int, centerBoostDb: Int, normalize: Boolean): FloatArray? {
    val c = centerGain(centerBoostDb)
    val s = SURROUND_GAIN
    val rows: List<FloatArray> = when (inputChannels) {
      3 -> listOf(fl(), fr(), both(c))
      4 -> listOf(fl(), fr(), left(s), right(s))
      5 -> listOf(fl(), fr(), both(c), left(s), right(s))
      6 -> listOf(fl(), fr(), both(c), lfe(), left(s), right(s))
      7 -> listOf(fl(), fr(), both(c), lfe(), left(s), right(s), both(BACK_CENTER_GAIN))
      8 -> listOf(fl(), fr(), both(c), lfe(), left(s), right(s), left(s), right(s))
      else -> return null
    }
    val flat = FloatArray(rows.size * 2)
    rows.forEachIndexed { i, row ->
      flat[i * 2] = row[0]
      flat[i * 2 + 1] = row[1]
    }
    if (normalize) {
      var sumL = 0f
      var sumR = 0f
      for (i in rows.indices) {
        sumL += flat[i * 2]
        sumR += flat[i * 2 + 1]
      }
      val peak = maxOf(sumL, sumR, 1f)
      if (peak > 1f) {
        for (i in flat.indices) flat[i] /= peak
      }
    }
    return flat
  }

  private fun fl() = floatArrayOf(1f, 0f)
  private fun fr() = floatArrayOf(0f, 1f)
  private fun left(gain: Float) = floatArrayOf(gain, 0f)
  private fun right(gain: Float) = floatArrayOf(0f, gain)
  private fun both(gain: Float) = floatArrayOf(gain, gain)
  private fun lfe() = floatArrayOf(0f, 0f)
}
