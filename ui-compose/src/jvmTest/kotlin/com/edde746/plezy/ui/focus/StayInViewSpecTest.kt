package com.edde746.plezy.ui.focus

import androidx.compose.foundation.gestures.BringIntoViewSpec
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A focused element wholly in view and clear of the container's ends stays; one wholly on screen but within an end's
 * band (a sheet list's fade) moves the least that clears it; one past an edge comes in as the platform brings it.
 */
class StayInViewSpecTest {
    /** A platform that pivots: what it would scroll, marked so it can be told apart. */
    private val pivot = object : BringIntoViewSpec {
        override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float): Float = 1000f + offset
    }
    private val spec = StayInViewSpec(pivot, before = 80f, after = 80f)

    @Test
    fun anElementClearOfTheBandsStays() {
        assertEquals(0f, spec.calculateScrollDistance(offset = 80f, size = 96f, containerSize = 880f))
        assertEquals(0f, spec.calculateScrollDistance(offset = 704f, size = 96f, containerSize = 880f))
    }

    @Test
    fun anElementOnScreenWithinABandMovesTheLeastThatClearsIt() {
        assertEquals(3f, spec.calculateScrollDistance(offset = 707f, size = 96f, containerSize = 880f), "3 px into the bottom band")
        assertEquals(-48f, spec.calculateScrollDistance(offset = 32f, size = 96f, containerSize = 880f), "48 px into the top band")
    }

    @Test
    fun anElementPastAnEdgeComesInAsThePlatformBringsIt() {
        assertEquals(1000f + 900f - 80f, spec.calculateScrollDistance(offset = 900f, size = 96f, containerSize = 880f))
        assertEquals(1000f - 10f - 80f, spec.calculateScrollDistance(offset = -10f, size = 96f, containerSize = 880f))
    }
}
