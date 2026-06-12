package com.edde746.plezy.libass.media.widget

import com.edde746.plezy.libass.AssAtlasFrame
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Tests for the speculative render-ahead state machine. The render function is
 * scripted: each call records (timeMs, slot) and returns the next queued frame.
 */
class SpecRenderEngineTest {

  private class RenderCall(val timeMs: Long, val slot: Int)

  private class Harness(
    slotCount: Int = 3,
    speculationEnabled: Boolean = true
  ) {
    val calls = mutableListOf<RenderCall>()
    val script = ArrayDeque<AssAtlasFrame?>()
    var generation = 0L
    var glTaken = -1

    val engine = SpecRenderEngine(
      slotCount = slotCount,
      speculationEnabled = speculationEnabled,
      renderAt = { timeMs, slot ->
        calls.add(RenderCall(timeMs, slot))
        if (script.isEmpty()) changed() else script.removeFirst()
      },
      stateGeneration = { generation },
      glTakenSlot = { glTaken }
    )

    /** Primes the cadence estimator with [n] steady requests; returns last pts. */
    fun prime(n: Int = 5, startUs: Long = 0L, deltaUs: Long = 42_000L): Long {
      var pts = startUs
      repeat(n) {
        engine.service(pts, pinned = true)
        engine.speculateAfter(pts, pinned = true, hasPending = false)
        pts += deltaUs
      }
      return pts - deltaUs
    }
  }

  private companion object {
    const val DELTA = 42_000L

    fun changed(quads: Int = 5) = AssAtlasFrame(2048, 100, quads, 2, 0)

    fun unchanged() = AssAtlasFrame(0, 0, 0, 0, 0)
  }

  @Test
  fun `steady state hits serve without rendering`() {
    val h = Harness()
    val last = h.prime()

    // Cadence is confident by now: the last speculateAfter pre-rendered last+Δ.
    val before = h.calls.size
    val outcome = h.engine.service(last + DELTA, pinned = true)

    assertTrue(outcome is SpecRenderEngine.Outcome.Post)
    outcome as SpecRenderEngine.Outcome.Post
    assertTrue(outcome.specHit)
    assertFalse(outcome.newContent) // content was written (and seq-bumped) at spec time
    assertEquals("service must not render on a hit", before, h.calls.size)
    assertEquals(1L, h.engine.specHits)
  }

  @Test
  fun `hit tolerates jitter within epsilon`() {
    val h = Harness()
    val last = h.prime()

    val outcome = h.engine.service(last + DELTA + 3_000, pinned = true)

    assertTrue((outcome as SpecRenderEngine.Outcome.Post).specHit)
  }

  @Test
  fun `seek misses and renders on demand into the spec slot`() {
    val h = Harness()
    val last = h.prime()
    val specSlot = h.calls.last().slot // where the speculative content went

    val before = h.calls.size
    h.script.add(changed())
    val outcome = h.engine.service(last + 1_000_000, pinned = true)

    assertTrue(outcome is SpecRenderEngine.Outcome.Post)
    outcome as SpecRenderEngine.Outcome.Post
    assertFalse(outcome.specHit)
    assertTrue(outcome.newContent)
    assertEquals(before + 1, h.calls.size)
    assertEquals("miss must render into the slot holding libass's last content", specSlot, h.calls.last().slot)
    assertEquals(1L, h.engine.specMisses)
  }

  @Test
  fun `miss with changed 0 posts the spec slot not stale screen content`() {
    // The trap: spec rendered NEW content (never posted); a mismatched request
    // then returns changed == 0 (identical to libass's LAST render = the spec
    // content). Posting "last posted" content would be stale — the engine must
    // post the slot libass last wrote.
    val h = Harness()
    val last = h.prime()
    val specSlot = h.calls.last().slot

    h.script.add(unchanged())
    val outcome = h.engine.service(last + 200_000, pinned = true) // > ε, miss; estimator resets too

    assertTrue(outcome is SpecRenderEngine.Outcome.Post)
    outcome as SpecRenderEngine.Outcome.Post
    assertFalse(outcome.specHit)
    assertFalse(outcome.newContent)
    assertEquals("changed==0 must repost libass's last-rendered slot", specSlot, outcome.slot)
  }

  @Test
  fun `state generation change invalidates speculation`() {
    val h = Harness()
    val last = h.prime()

    h.generation++ // margins/zoom/track switch between spec render and the request
    h.script.add(changed())
    val before = h.calls.size
    val outcome = h.engine.service(last + DELTA, pinned = true)

    assertTrue(outcome is SpecRenderEngine.Outcome.Post)
    assertFalse((outcome as SpecRenderEngine.Outcome.Post).specHit)
    assertEquals("stale spec must be re-rendered", before + 1, h.calls.size)
    assertEquals(1L, h.engine.specMisses)
  }

  @Test
  fun `unpinned requests never feed the estimator or speculate`() {
    val h = Harness()
    val last = h.prime()

    // Paused invalidate-repaint at an arbitrary position.
    h.script.add(changed())
    h.engine.service(last, pinned = false)
    val specBefore = h.calls.size
    assertNull(h.engine.speculateAfter(last, pinned = false, hasPending = false))
    assertEquals("unpinned must not speculate", specBefore, h.calls.size)

    // Cadence survives the unpinned request: the next pinned pair still hits.
    h.engine.service(last + DELTA, pinned = true)
    h.engine.speculateAfter(last + DELTA, pinned = true, hasPending = false)
    val outcome = h.engine.service(last + 2 * DELTA, pinned = true)
    assertTrue((outcome as SpecRenderEngine.Outcome.Post).specHit)
  }

  @Test
  fun `speculation skipped while a request is pending`() {
    val h = Harness()
    val last = h.prime()
    val before = h.calls.size

    assertNull(h.engine.speculateAfter(last, pinned = true, hasPending = true))
    assertEquals(before, h.calls.size)
    assertTrue(h.engine.specSkips > 0)
  }

  @Test
  fun `no speculation until cadence is confident`() {
    val h = Harness()
    h.engine.service(0, pinned = true)
    // Only one delta sample so far (needs 4).
    h.engine.service(DELTA, pinned = true)
    val before = h.calls.size
    assertNull(h.engine.speculateAfter(DELTA, pinned = true, hasPending = false))
    assertEquals(before, h.calls.size)
  }

  @Test
  fun `render target avoids posted and gl taken slots`() {
    val h = Harness()
    h.script.add(changed())
    val first = h.engine.service(0, pinned = true) as SpecRenderEngine.Outcome.Post
    val posted = first.slot

    h.glTaken = (posted + 1) % 3
    h.script.add(changed())
    val second = h.engine.service(1_000_000, pinned = true) as SpecRenderEngine.Outcome.Post

    val expected = (0 until 3).first { it != posted && it != h.glTaken }
    assertEquals(expected, second.slot)
  }

  @Test
  fun `changed 0 before any content skips`() {
    val h = Harness()
    h.script.add(unchanged())
    assertEquals(SpecRenderEngine.Outcome.Skip, h.engine.service(0, pinned = true))
  }

  @Test
  fun `renderer gone skips`() {
    val h = Harness()
    h.script.add(null)
    assertEquals(SpecRenderEngine.Outcome.Skip, h.engine.service(0, pinned = true))
  }

  @Test
  fun `two slot mode alternates and never speculates`() {
    val h = Harness(slotCount = 2, speculationEnabled = false)
    h.script.add(changed())
    val a = h.engine.service(0, pinned = true) as SpecRenderEngine.Outcome.Post
    assertNull(h.engine.speculateAfter(0, pinned = true, hasPending = false))

    h.script.add(changed())
    val b = h.engine.service(DELTA, pinned = true) as SpecRenderEngine.Outcome.Post
    assertTrue(a.slot != b.slot)
    assertTrue(a.slot in 0..1 && b.slot in 0..1)
    assertEquals(0, h.calls.count { it.slot >= 2 })
  }

  @Test
  fun `static dialogue hit reposts the same slot without new content`() {
    // Spec render returns changed == 0 (nothing moves): a hit must repost the
    // last-rendered slot so GL skips the upload entirely.
    val h = Harness()
    h.script.add(changed())
    val first = h.engine.service(0, pinned = true) as SpecRenderEngine.Outcome.Post
    var pts = 0L
    repeat(4) { // build cadence; renders return changed for simplicity
      pts += DELTA
      h.engine.service(pts, pinned = true)
    }
    h.script.add(unchanged()) // speculative render: nothing changes at pts+Δ
    assertNull(h.engine.speculateAfter(pts, pinned = true, hasPending = false))

    val before = h.calls.size
    val outcome = h.engine.service(pts + DELTA, pinned = true) as SpecRenderEngine.Outcome.Post
    assertTrue(outcome.specHit)
    assertFalse(outcome.newContent)
    assertEquals(before, h.calls.size)
    assertNotNull(first) // first slot existed; hit reposts whichever slot was last rendered
  }

  @Test
  fun `speculative write reports slot for seq bump`() {
    val h = Harness()
    val last = h.prime()
    h.script.add(changed())
    val write = h.engine.speculateAfter(last, pinned = true, hasPending = false)
    assertNotNull(write)
    assertEquals(h.calls.last().slot, write!!.slot)
  }

  @Test
  fun `spec predicts pts plus median delta`() {
    val h = Harness()
    val last = h.prime()
    h.script.add(changed())
    h.engine.speculateAfter(last, pinned = true, hasPending = false)
    assertEquals((last + DELTA) / 1000, h.calls.last().timeMs)
  }

  @Test
  fun `prefetch renders the requested future pts and reports its slot`() {
    val h = Harness()
    h.script.add(changed())
    h.engine.service(0, pinned = true) // some content on screen

    h.script.add(changed())
    val write = h.engine.prefetch(5_000_000)

    assertNotNull(write)
    assertEquals(5_000L, h.calls.last().timeMs)
    assertEquals(h.calls.last().slot, write!!.slot)
    assertEquals(1L, h.engine.prefetchCount)
  }

  @Test
  fun `prefetch invalidates pending speculation`() {
    // Prefetch rewrites libass's last-rendered content (and possibly the spec
    // slot itself); a stale spec hit would post future-event content.
    val h = Harness()
    val last = h.prime() // leaves a valid spec for last+Δ

    h.script.add(changed())
    h.engine.prefetch(last + 5_000_000)

    val before = h.calls.size
    h.script.add(changed())
    val outcome = h.engine.service(last + DELTA, pinned = true)

    assertTrue(outcome is SpecRenderEngine.Outcome.Post)
    assertFalse((outcome as SpecRenderEngine.Outcome.Post).specHit)
    assertEquals("post-prefetch request must render on demand", before + 1, h.calls.size)
  }

  @Test
  fun `render after prefetch with changed 0 posts the prefetched slot`() {
    // changed==0 after a prefetch means "identical to libass's last render" =
    // the prefetched content — correct exactly when playback reached the
    // prefetched event. The engine must post that slot, not older content.
    val h = Harness()
    h.script.add(changed())
    h.engine.service(0, pinned = true)

    h.script.add(changed())
    val write = h.engine.prefetch(5_000_000)!!

    h.script.add(unchanged())
    val outcome = h.engine.service(5_000_000, pinned = true) as SpecRenderEngine.Outcome.Post
    assertEquals(write.slot, outcome.slot)
    assertFalse(outcome.newContent)
  }

  @Test
  fun `prefetch avoids posted and gl taken slots`() {
    val h = Harness()
    h.script.add(changed())
    val posted = (h.engine.service(0, pinned = true) as SpecRenderEngine.Outcome.Post).slot
    h.glTaken = (posted + 1) % 3

    h.script.add(changed())
    val write = h.engine.prefetch(5_000_000)

    val expected = (0 until 3).first { it != posted && it != h.glTaken }
    assertEquals(expected, write!!.slot)
  }
}
