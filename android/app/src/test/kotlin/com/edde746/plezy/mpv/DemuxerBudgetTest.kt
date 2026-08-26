package com.edde746.plezy.mpv

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
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
}
