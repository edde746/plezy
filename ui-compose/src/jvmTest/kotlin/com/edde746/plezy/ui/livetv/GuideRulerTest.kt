package com.edde746.plezy.ui.livetv

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** The guide's time ruler: a time is drawn whole or not at all, never cut by the start of the ruler. */
class GuideRulerTest {
    @Test
    fun aTimeAtOrPastTheStartIsDrawnAtItsMark() {
        assertEquals(0f, rulerLabelX(mark = 0f, next = 300f, width = 60, gap = 8))
        assertEquals(120f, rulerLabelX(mark = 120f, next = 420f, width = 60, gap = 8))
    }

    @Test
    fun aTimeWhoseMarkScrolledPastTheStartStaysWholeAtTheStart() {
        assertEquals(0f, rulerLabelX(mark = -40f, next = 260f, width = 60, gap = 8))
        // The last time has no next one to push it.
        assertEquals(0f, rulerLabelX(mark = -400f, next = Float.MAX_VALUE, width = 60, gap = 8))
    }

    @Test
    fun aTimeTheNextOneReachesLeavesTheStartWholeRatherThanCut() {
        assertEquals(0f, rulerLabelX(mark = -250f, next = 68f, width = 60, gap = 8))
        assertNull(rulerLabelX(mark = -250f, next = 50f, width = 60, gap = 8))
    }
}
