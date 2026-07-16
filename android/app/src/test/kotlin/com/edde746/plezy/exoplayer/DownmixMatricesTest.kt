package com.edde746.plezy.exoplayer

import kotlin.math.pow
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DownmixMatricesTest {

  private fun coeff(matrix: FloatArray, input: Int, output: Int) = matrix[input * 2 + output]

  private fun columnSum(matrix: FloatArray, output: Int): Float {
    var sum = 0f
    for (input in 0 until matrix.size / 2) sum += coeff(matrix, input, output)
    return sum
  }

  @Test
  fun centerGainMatchesKodiFormula() {
    // Kodi: center_mix_level = 10^((-3 + boost) / 20)
    assertEquals(0.70795f, DownmixMatrices.centerGain(0), 1e-3f)
    assertEquals(1.0f, DownmixMatrices.centerGain(3), 1e-3f)
    assertEquals(2.81838f, DownmixMatrices.centerGain(12), 1e-3f)
  }

  @Test
  fun centerGainClampsBoost() {
    assertEquals(DownmixMatrices.centerGain(12), DownmixMatrices.centerGain(20), 0f)
    assertEquals(DownmixMatrices.centerGain(0), DownmixMatrices.centerGain(-5), 0f)
  }

  @Test
  fun fivePointOneLayoutUnnormalized() {
    val m = DownmixMatrices.stereoCoefficients(6, centerBoostDb = 0, normalize = false)!!
    val c = DownmixMatrices.centerGain(0)
    val s = DownmixMatrices.SURROUND_GAIN
    // FL FR FC LFE BL BR
    assertEquals(1f, coeff(m, 0, 0), 0f)
    assertEquals(0f, coeff(m, 0, 1), 0f)
    assertEquals(0f, coeff(m, 1, 0), 0f)
    assertEquals(1f, coeff(m, 1, 1), 0f)
    assertEquals(c, coeff(m, 2, 0), 0f)
    assertEquals(c, coeff(m, 2, 1), 0f)
    assertEquals(0f, coeff(m, 3, 0), 0f) // LFE dropped
    assertEquals(0f, coeff(m, 3, 1), 0f)
    assertEquals(s, coeff(m, 4, 0), 0f)
    assertEquals(0f, coeff(m, 4, 1), 0f)
    assertEquals(0f, coeff(m, 5, 0), 0f)
    assertEquals(s, coeff(m, 5, 1), 0f)
  }

  @Test
  fun sixPointOneBackCenterMixesHalfToEachSide() {
    val m = DownmixMatrices.stereoCoefficients(7, centerBoostDb = 0, normalize = false)!!
    assertEquals(0.5f, coeff(m, 6, 0), 0f)
    assertEquals(0.5f, coeff(m, 6, 1), 0f)
  }

  @Test
  fun normalizeScalesMaxColumnSumToOne() {
    for (channels in intArrayOf(6, 8)) {
      val m = DownmixMatrices.stereoCoefficients(channels, centerBoostDb = 6, normalize = true)!!
      assertEquals("channels=$channels L", 1f, columnSum(m, 0), 1e-4f)
      assertEquals("channels=$channels R", 1f, columnSum(m, 1), 1e-4f)
      // Relative balance is preserved: FC/FL ratio equals the raw center gain.
      assertEquals(DownmixMatrices.centerGain(6), coeff(m, 2, 0) / coeff(m, 0, 0), 1e-4f)
    }
  }

  @Test
  fun normalizeNeverAmplifies() {
    for (channels in DownmixMatrices.MIN_DOWNMIX_INPUT_CHANNELS..DownmixMatrices.MAX_DOWNMIX_INPUT_CHANNELS) {
      val raw = DownmixMatrices.stereoCoefficients(channels, centerBoostDb = 6, normalize = false)!!
      val normalized = DownmixMatrices.stereoCoefficients(channels, centerBoostDb = 6, normalize = true)!!
      for (i in raw.indices) {
        assertTrue("channels=$channels i=$i", normalized[i] <= raw[i] + 1e-6f)
      }
    }
  }

  @Test
  fun boostRaisesOnlyTheCenterChannel() {
    val base = DownmixMatrices.stereoCoefficients(6, centerBoostDb = 0, normalize = false)!!
    val boosted = DownmixMatrices.stereoCoefficients(6, centerBoostDb = 6, normalize = false)!!
    val expectedRatio = 10f.pow(6f / 20f)
    assertEquals(expectedRatio, coeff(boosted, 2, 0) / coeff(base, 2, 0), 1e-4f)
    for (input in intArrayOf(0, 1, 3, 4, 5)) {
      assertEquals("input=$input L", coeff(base, input, 0), coeff(boosted, input, 0), 0f)
      assertEquals("input=$input R", coeff(base, input, 1), coeff(boosted, input, 1), 0f)
    }
  }

  @Test
  fun passThroughCountsReturnNull() {
    for (channels in intArrayOf(1, 2, 9, 12)) {
      assertNull("channels=$channels", DownmixMatrices.stereoCoefficients(channels, 0, true))
    }
  }

  @Test
  fun allCoefficientsNonNegative() {
    // ChannelMixingMatrix throws on negative coefficients; guard every combination.
    for (channels in DownmixMatrices.MIN_DOWNMIX_INPUT_CHANNELS..DownmixMatrices.MAX_DOWNMIX_INPUT_CHANNELS) {
      for (boost in intArrayOf(0, 6, 12)) {
        for (normalize in booleanArrayOf(true, false)) {
          val m = DownmixMatrices.stereoCoefficients(channels, boost, normalize)
          assertNotNull(m)
          for (value in m!!) {
            assertTrue("channels=$channels boost=$boost normalize=$normalize", value >= 0f)
          }
        }
      }
    }
  }
}
