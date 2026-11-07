package com.edde746.plezy.watchnext

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Pure set-union coverage for the Fire OS stale-poster grant fix. Uses strings so
 * the test does not depend on android.net.Uri (stubbed in local JVM unit tests).
 */
class PreviewChannelGrantMergeTest {
  @Test
  fun mergeGrantSetsKeepsLivePostersThatIntendedSetDropped() {
    val intended = setOf("content://…/new.art")
    val live = setOf("content://…/stale.art", "content://…/new.art")

    val merged = PreviewChannelPublisher.mergeGrantSets(intended, live)

    assertEquals(2, merged.size)
    assertTrue(merged.containsAll(intended))
    assertTrue(merged.containsAll(live))
  }

  @Test
  fun mergeGrantSetsWithEmptyLiveMatchesIntended() {
    val intended = setOf("content://…/only.art")
    assertEquals(intended, PreviewChannelPublisher.mergeGrantSets(intended, emptySet()))
  }
}
