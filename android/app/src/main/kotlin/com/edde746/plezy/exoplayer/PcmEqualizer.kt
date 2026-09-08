package com.edde746.plezy.exoplayer

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin

/**
 * Ten peaking biquads, an independent preamp, and the same broad 80 Hz Bass bell
 * used by mpv. State is per channel; no platform audiofx engine is claimed.
 * Parameter changes crossfade over 128 frames to avoid step discontinuities.
 * Used only on decoded PCM, never on the IEC carrier path.
 */
class PcmEqualizer(private val sampleRate: Int, private val channels: Int) {
  private var parameters = EqualizerParameters.FLAT
  private var current = Kernel(parameters, sampleRate, channels)
  private var previous: Kernel? = null
  private var remainingFrames = 0

  init {
    require(sampleRate > 0 && channels > 0)
  }

  fun update(next: EqualizerParameters) {
    if (next == parameters) return
    parameters = next
    previous = current
    current = Kernel(next, sampleRate, channels)
    remainingFrames = TRANSITION_FRAMES
  }

  fun process(sample: Double, channel: Int): Double {
    val output = current.process(sample, channel)
    val old = previous ?: return output
    val weight = remainingFrames.toDouble() / TRANSITION_FRAMES
    val mixed = old.process(sample, channel) * weight + output * (1.0 - weight)
    if (channel == channels - 1 && --remainingFrames == 0) previous = null
    return mixed
  }

  private class Kernel(parameters: EqualizerParameters, sampleRate: Int, channels: Int) {
    private val preamp = 10.0.pow(parameters.preampDb / 20.0)
    private val filters = buildList {
      if (parameters.bassDb != 0.0 && 80 < sampleRate / 2.0) add(Biquad(80.0, 0.5, parameters.bassDb, sampleRate, channels))
      for ((i, frequency) in EqualizerParameters.FREQUENCIES.withIndex()) {
        // Bands above Nyquist cannot be represented by this source.
        if (parameters.gains[i] != 0.0 && frequency < sampleRate / 2.0) {
          add(Biquad(frequency, 1.414, parameters.gains[i], sampleRate, channels))
        }
      }
    }

    fun process(sample: Double, channel: Int): Double {
      var value = sample * preamp
      for (filter in filters) value = filter.process(value, channel)
      return value
    }
  }

  private class Biquad(frequency: Double, q: Double, gainDb: Double, sampleRate: Int, channels: Int) {
    private val b0: Double
    private val b1: Double
    private val b2: Double
    private val a1: Double
    private val a2: Double
    private val z1 = DoubleArray(channels)
    private val z2 = DoubleArray(channels)

    init {
      val amplitude = 10.0.pow(gainDb / 40.0)
      val omega = 2 * PI * frequency / sampleRate
      val alpha = sin(omega) / (2 * q)
      val denominator = 1 + alpha / amplitude
      b0 = (1 + alpha * amplitude) / denominator
      b1 = -2 * cos(omega) / denominator
      b2 = (1 - alpha * amplitude) / denominator
      a1 = b1
      a2 = (1 - alpha / amplitude) / denominator
    }

    fun process(input: Double, channel: Int): Double {
      val output = b0 * input + z1[channel]
      z1[channel] = b1 * input - a1 * output + z2[channel]
      z2[channel] = b2 * input - a2 * output
      return output
    }
  }

  private companion object {
    const val TRANSITION_FRAMES = 128
  }
}
