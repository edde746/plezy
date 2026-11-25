package com.edde746.plezy.presentation.player

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ContentStripSwipeTest {
    @Test
    fun theStripFollowsTheFingerOverOneHundredFiftyPoints() {
        assertEquals(0.5f, ContentStripSwipe.drag(0f, -75f))
        assertEquals(1f, ContentStripSwipe.drag(0f, -400f))
        assertEquals(0.8f, ContentStripSwipe.drag(1f, 30f), 0.0001f)
        assertEquals(0f, ContentStripSwipe.drag(0.2f, 100f))
    }

    @Test
    fun aFlingUpOpensItFromAnywhereAndAFlingDownClosesIt() {
        assertTrue(ContentStripSwipe.opens(progress = 0.05f, velocity = -201f))
        assertFalse(ContentStripSwipe.opens(progress = 0.95f, velocity = 201f))
    }

    @Test
    fun withoutAFlingItSettlesOnTheSideOfHalfwayItIsOn() {
        assertTrue(ContentStripSwipe.opens(progress = 0.51f, velocity = 199f))
        assertTrue(ContentStripSwipe.opens(progress = 0.51f, velocity = -150f))
        assertFalse(ContentStripSwipe.opens(progress = 0.5f, velocity = 0f))
        assertFalse(ContentStripSwipe.opens(progress = 0.3f, velocity = -200f))
    }
}
