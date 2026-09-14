package com.edde746.plezy.exoplayer

import androidx.media3.exoplayer.DefaultLoadControl
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * [LoadControlPolicyTest] checks that the policy's arithmetic satisfies the ordering we believe
 * media3 requires. This file checks the belief, by handing every value the settings screen can
 * produce to a real `DefaultLoadControl.Builder`.
 *
 * The distinction matters because media3 validates with Guava `Preconditions.checkArgument`, not
 * `androidx.media3.common.util.Assertions` and not a JVM `assert`. It is an unconditional throw
 * that survives R8 — nothing in `proguard-rules.pro` elides it — so a rejected pair is an
 * `IllegalArgumentException` out of player construction on a user's device, not a degraded buffer.
 * A media3 upgrade that tightens the ordering should fail here rather than there.
 */
@RunWith(RobolectricTestRunner::class)
class LoadControlPolicyBuildTest {

  /** Both Auto memory tiers, their boundary, and the unknown-memory case. */
  private val memoryTiers = intArrayOf(0, 512, 1024, 2048, 2049, 4096, 8192)

  private fun build(tier: LoadControlPolicy.BufferTier, availableMB: Int): DefaultLoadControl {
    val durations = LoadControlPolicy.bufferDurations(tier, availableMB)
    return DefaultLoadControl.Builder()
      .setTargetBufferBytes(LoadControlPolicy.MIN_TARGET_BYTES)
      .setPrioritizeTimeOverSizeThresholds(false)
      .setBufferDurationsMs(
        durations.minBufferMs,
        durations.maxBufferMs,
        LoadControlPolicy.BUFFER_FOR_PLAYBACK_MS,
        LoadControlPolicy.BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS
      )
      .build()
  }

  @Test
  fun everyTierBuildsOnEveryMemoryTier() {
    for (tier in LoadControlPolicy.BufferTier.entries) {
      for (availableMB in memoryTiers) {
        // build() throws IllegalArgumentException on a rejected ordering; reaching the next
        // iteration is the assertion.
        build(tier, availableMB)
      }
    }
  }

  @Test
  fun aTierNameThisVersionDoesNotKnowStillBuilds() {
    // The tier crosses a MethodChannel as a string, so the enum is not the only possible input:
    // a Dart build newer than this native build can send a name that is not in `entries`.
    for (wire in arrayOf(null, "", "gigantic", "EXTRA_LARGE", "0")) {
      build(LoadControlPolicy.BufferTier.fromWire(wire), availableMB = 1024)
    }
  }

  @Test
  fun theShippedAutoTiersAreUnchanged() {
    // #1816 adds a setting; it must not quietly retune the default everyone already has.
    assertEquals(
      LoadControlPolicy.BufferDurations(15_000, 50_000),
      LoadControlPolicy.bufferDurations(LoadControlPolicy.BufferTier.AUTO, availableMB = 2048)
    )
    assertEquals(
      LoadControlPolicy.BufferDurations(30_000, 60_000),
      LoadControlPolicy.bufferDurations(LoadControlPolicy.BufferTier.AUTO, availableMB = 2049)
    )
  }
}
