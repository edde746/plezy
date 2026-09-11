package com.edde746.plezy.exoplayer

import java.util.Collections

/** Validated immutable EQ intent, shared by the PCM processor and its controller. */
@ConsistentCopyVisibility
data class EqualizerParameters private constructor(
  val gains: List<Double>,
  val preampDb: Double,
  val bassDb: Double
) {
  val active: Boolean get() = preampDb != 0.0 || bassDb != 0.0 || gains.any { it != 0.0 }

  companion object {
    val FLAT = create(List(10) { 0.0 }, 0.0, 0.0)
    val FREQUENCIES = listOf(31.25, 62.5, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0)

    fun create(gains: List<Double>, preampDb: Double, bassDb: Double): EqualizerParameters {
      require(gains.size == 10) { "Expected ten equalizer bands" }
      require((gains + listOf(preampDb, bassDb)).all { it.isFinite() && it in -12.0..12.0 }) { "Invalid equalizer gain" }
      return EqualizerParameters(Collections.unmodifiableList(gains.toList()), preampDb, bassDb)
    }
  }
}
