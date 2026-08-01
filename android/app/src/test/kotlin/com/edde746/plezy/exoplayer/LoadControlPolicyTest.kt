package com.edde746.plezy.exoplayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

private const val MIB = 1024 * 1024

class LoadControlPolicyTest {

  // autoTargetBufferBytes

  @Test
  fun neverExceedsMedia3sOwnTargetEvenWithHugeMemory() {
    assertEquals(
      LoadControlPolicy.MEDIA3_DEFAULT_TARGET_BYTES,
      LoadControlPolicy.autoTargetBufferBytes(largeHeapMB = 4096, availableMB = 8192)
    )
  }

  @Test
  fun heapBoundsTheTargetOnAShieldClassDevice() {
    // The actual #1618 defect: the shipped tiers handed this device a flat 64MB, under half
    // of media3's own choice. largeMemoryClass 512MB, ~1GB free, so the heap binds at
    // 512/4 = 128MB — exactly what the reporter had to select by hand.
    assertEquals(
      128 * MIB,
      LoadControlPolicy.autoTargetBufferBytes(largeHeapMB = 512, availableMB = 990)
    )
  }

  @Test
  fun freeMemoryBoundsTheTargetWhenItIsTighterThanTheHeap() {
    assertEquals(
      64 * MIB,
      LoadControlPolicy.autoTargetBufferBytes(largeHeapMB = 512, availableMB = 256)
    )
  }

  @Test
  fun floorWinsOverBothBudgetsSoReadAheadCannotCollapse() {
    // Going under the floor is what starves the sink on high-bitrate content; the
    // allocator only grows into the target when the content is dense enough to need it.
    assertEquals(
      LoadControlPolicy.MIN_TARGET_BYTES,
      LoadControlPolicy.autoTargetBufferBytes(largeHeapMB = 64, availableMB = 48)
    )
  }

  @Test
  fun unknownMemoryFallsBackToMedia3sTarget() {
    assertEquals(
      LoadControlPolicy.MEDIA3_DEFAULT_TARGET_BYTES,
      LoadControlPolicy.autoTargetBufferBytes(largeHeapMB = 0, availableMB = 0)
    )
  }

  @Test
  fun unknownHeapStillRespectsFreeMemory() {
    assertEquals(
      64 * MIB,
      LoadControlPolicy.autoTargetBufferBytes(largeHeapMB = -1, availableMB = 256)
    )
  }

  // readAheadSeconds

  @Test
  fun readAheadReportsSecondsAtAKnownBitrate() {
    // 64MiB of the #1618 stream (103_341 kbps) is ~5.2s — under the 15s minBufferMs, so the
    // byte cap, not the time threshold, is what stops the loader.
    val seconds = LoadControlPolicy.readAheadSeconds(64 * MIB, 103_341_000L)!!
    assertEquals(5.19, seconds, 0.01)
  }

  @Test
  fun readAheadDoublesWithTheTarget() {
    val seconds = LoadControlPolicy.readAheadSeconds(128 * MIB, 103_341_000L)!!
    assertEquals(10.39, seconds, 0.01)
  }

  @Test
  fun readAheadIsUnknownWithoutABitrate() {
    assertNull(LoadControlPolicy.readAheadSeconds(64 * MIB, 0L))
    assertNull(LoadControlPolicy.readAheadSeconds(64 * MIB, -1L))
  }
}
