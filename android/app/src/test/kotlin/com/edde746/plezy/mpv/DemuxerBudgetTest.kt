package com.edde746.plezy.mpv

import android.content.ComponentCallbacks2
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Boundaries are the contract; rationale on [DemuxerBudget]. */
class DemuxerBudgetTest {
  private val mib = 1024L * 1024L

  @Test
  fun `unknown heap class keeps mpv defaults`() {
    assertNull(DemuxerBudget.forHeapClassMB(0))
    assertNull(DemuxerBudget.forHeapClassMB(-1))
  }

  @Test
  fun `small heap class gets the tight tier`() {
    val budget = DemuxerBudget.forHeapClassMB(256)!!
    assertEquals(32 * mib, budget.aheadBytes)
    assertEquals(16 * mib, budget.backBytes)
  }

  @Test
  fun `mid heap class gets the middle tier`() {
    assertEquals(64 * mib, DemuxerBudget.forHeapClassMB(257)!!.aheadBytes)
    val budget = DemuxerBudget.forHeapClassMB(512)!!
    assertEquals(64 * mib, budget.aheadBytes)
    assertEquals(32 * mib, budget.backBytes)
  }

  @Test
  fun `large heap class gets the full tier`() {
    val budget = DemuxerBudget.forHeapClassMB(513)!!
    assertEquals(100 * mib, budget.aheadBytes)
    assertEquals(48 * mib, budget.backBytes)
  }

  @Test
  fun `running low frees the back cache and leaves read-ahead alone`() {
    // Shrinking read-ahead is what forces a rebuffer on a slow link, so the
    // first pressure level must not touch it.
    for (heapClass in listOf(256, 512, 1024)) {
      val steady = DemuxerBudget.forHeapClassMB(heapClass)!!
      val low = DemuxerBudget.forTrimLevel(heapClass, ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)!!

      assertEquals("heap class $heapClass", steady.aheadBytes, low.aheadBytes)
      assertEquals("heap class $heapClass", 0L, low.backBytes)
    }
  }

  @Test
  fun `running critical shrinks the total but never below the tightest tier`() {
    val tightest = DemuxerBudget.forHeapClassMB(256)!!
    for (heapClass in listOf(256, 512, 1024)) {
      val steady = DemuxerBudget.forHeapClassMB(heapClass)!!
      val critical = DemuxerBudget.forTrimLevel(heapClass, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL)!!

      assertTrue(
        "heap class $heapClass",
        critical.aheadBytes + critical.backBytes < steady.aheadBytes + steady.backBytes
      )
      assertTrue("heap class $heapClass", critical.aheadBytes >= tightest.aheadBytes)
    }
  }

  @Test
  fun `critical pressure keeps six seconds of the stream byte rate`() {
    // A byte count decides nothing on its own: 32 MiB is 3.4 s of #2314's
    // 80 Mbps stretch and 13 s of a 20 Mbps episode.
    val remux = DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL, 10_000_000L)!!
    assertEquals(60_000_000L, remux.aheadBytes)
    assertEquals(0L, remux.backBytes)

    // Six seconds of a 16 Mbps episode is under the byte floor, which stands.
    val episode = DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL, 2_000_000L)!!
    assertEquals(32 * mib, episode.aheadBytes)
  }

  @Test
  fun `critical pressure never holds more read-ahead than the tier granted`() {
    // The answer is what to hold, not what to ask for - there is nothing to
    // reclaim above the tier - and the back cache goes either way.
    val steady = DemuxerBudget.forHeapClassMB(512)!!
    val critical = DemuxerBudget.forTrimLevel(512, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL, 100_000_000L)!!

    assertEquals(steady.aheadBytes, critical.aheadBytes)
    assertEquals(0L, critical.backBytes)
  }

  @Test
  fun `the byte rate is the faster of the cached span and the file average`() {
    // The #2314 file averages 57.7 Mbps and plays 81 Mbps stretches; read-ahead
    // has to survive the stretch, so the cached span wins where it is usable.
    assertEquals(
      10_000_000L,
      DemuxerBudget.streamByteRate(
        cachedBytes = 33_500_000L,
        cachedSeconds = 3.35,
        fileBytes = 45_000_000_000L,
        fileSeconds = 6250.0
      )
    )
    // A cache still filling after a seek measures nothing; the average carries.
    assertEquals(
      7_200_000L,
      DemuxerBudget.streamByteRate(
        cachedBytes = 2_000_000L,
        cachedSeconds = 0.2,
        fileBytes = 7_200_000_000L,
        fileSeconds = 1000.0
      )
    )
  }

  @Test
  fun `a stream with nothing to measure has no byte rate`() {
    // A core with nothing loaded, or a stream mpv reports no size for: the
    // caller falls back to the byte floor instead of dividing by zero.
    assertEquals(0L, DemuxerBudget.streamByteRate(0L, 0.0, 0L, 0.0))
    assertEquals(
      0L,
      DemuxerBudget.streamByteRate(cachedBytes = 5_000_000L, cachedSeconds = 0.0, fileBytes = 5_000_000L, fileSeconds = 0.0)
    )
  }

  @Test
  fun `a level that is not memory pressure asks for nothing back`() {
    // The constants are not ordered by severity - RUNNING_CRITICAL is 15 and
    // UI_HIDDEN is 20 - so a numeric comparison would read "your UI is
    // hidden" as harsher than "the device is critical".
    assertNull(DemuxerBudget.forTrimLevel(512, ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN))
    assertNull(DemuxerBudget.forTrimLevel(512, ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE))
  }

  @Test
  fun `an unknown heap class has nothing to shrink under pressure`() {
    assertNull(DemuxerBudget.forTrimLevel(0, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL))
    assertNull(DemuxerBudget.forTrimLevel(0, ComponentCallbacks2.TRIM_MEMORY_COMPLETE))
  }

  @Test
  fun `a milder level after a harsher one cannot re-grow the budget`() {
    // Re-growing while the device is still thrashing is how the app got
    // killed; a trim sequence is not ordered, so the narrowing has to be the
    // rule rather than a property of the order levels arrive in.
    val steady = DemuxerBudget.forHeapClassMB(1024)!!
    val critical = DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL)!!
    val low = DemuxerBudget.forTrimLevel(1024, ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)!!

    // The milder level genuinely asks for more read-ahead than the harsher
    // one applied, so this sequence is what a plain assignment would widen.
    assertTrue(low.aheadBytes > critical.aheadBytes)
    assertEquals(critical, steady.narrowedTo(critical).narrowedTo(low))
  }
}
