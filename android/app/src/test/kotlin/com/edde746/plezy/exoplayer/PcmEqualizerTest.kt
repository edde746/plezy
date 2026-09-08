package com.edde746.plezy.exoplayer

import kotlin.math.PI
import kotlin.math.log10
import kotlin.math.sin
import kotlin.math.sqrt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PcmEqualizerTest {
  @Test
  fun flatIsIdentityForEveryChannel() {
    val dsp = PcmEqualizer(48000, 8)
    repeat(512) { frame ->
      repeat(8) { channel ->
        val sample = sin(frame * 0.2 + channel) * 0.8
        assertEquals(sample, dsp.process(sample, channel), 0.0)
      }
    }
  }

  @Test
  fun preampHasIndependentBroadbandGain() {
    assertEquals(-6.0, response(EqualizerParameters.create(List(10) { 0.0 }, -6.0, 0.0), 1000.0), 0.01)
  }

  @Test
  fun selectedBandAndBassReachTheirCenterGain() {
    assertEquals(6.0, response(EqualizerParameters.create(List(10) { if (it == 5) 6.0 else 0.0 }, 0.0, 0.0), 1000.0), 0.03)
    assertEquals(4.0, response(EqualizerParameters.create(List(10) { 0.0 }, 0.0, 4.0), 80.0), 0.05)
  }

  @Test
  fun channelsDoNotLeakAndDisableSettlesToIdentity() {
    val dsp = PcmEqualizer(48000, 2)
    dsp.update(EqualizerParameters.create(List(10) { 12.0 }, -12.0, 12.0))
    repeat(4096) { frame ->
      assertTrue(dsp.process(if (frame == 256) 0.2 else 0.0, 0).isFinite())
      assertEquals(0.0, dsp.process(0.0, 1), 0.0)
    }
    dsp.update(EqualizerParameters.FLAT)
    repeat(512) { frame ->
      val sample = sin(frame * 0.1) * 0.1
      val output = dsp.process(sample, 0)
      dsp.process(0.0, 1)
      if (frame >= 128) assertEquals(sample, output, 0.0)
    }
  }

  @Test
  fun lowSampleRateSkipsUnrepresentableBands() {
    val dsp = PcmEqualizer(8000, 1)
    dsp.update(EqualizerParameters.create(List(10) { 12.0 }, -12.0, -12.0))
    repeat(8000) { assertTrue(dsp.process(sin(it * 0.1), 0).isFinite()) }
  }

  @Test
  fun changesCrossfadeFromPreviousOutput() {
    val dsp = PcmEqualizer(48000, 1)
    dsp.update(EqualizerParameters.create(List(10) { 0.0 }, 12.0, 0.0))
    assertEquals(0.1, dsp.process(0.1, 0), 0.000001)
  }

  @Test(expected = IllegalArgumentException::class)
  fun rejectsNonFiniteGains() {
    EqualizerParameters.create(List(10) { Double.NaN }, 0.0, 0.0)
  }

  private fun response(parameters: EqualizerParameters, frequency: Double): Double {
    val dsp = PcmEqualizer(48000, 1)
    dsp.update(parameters)
    var inputEnergy = 0.0
    var outputEnergy = 0.0
    repeat(48000) { frame ->
      val sample = sin(2 * PI * frequency * frame / 48000) * 0.1
      val output = dsp.process(sample, 0)
      if (frame >= 24000) {
        inputEnergy += sample * sample
        outputEnergy += output * output
      }
    }
    return 20 * log10(sqrt(outputEnergy / inputEnergy))
  }
}
