package com.edde746.plezy.ui.ratings

import kotlin.test.Test
import kotlin.test.assertEquals

class StarValueTest {
    @Test
    fun aPositionIsItsShareOfTheWidthInHalfStars() {
        assertEquals(0, starValueAt(0f, 142f))
        assertEquals(5, starValueAt(71f, 142f))
        assertEquals(10, starValueAt(142f, 142f))
        // 7.5 half stars rounds up, 7.4 down.
        assertEquals(8, starValueAt(75f, 100f))
        assertEquals(7, starValueAt(74f, 100f))
    }

    @Test
    fun aDragPastEitherEndStopsAtItsScore() {
        assertEquals(0, starValueAt(-30f, 142f))
        assertEquals(10, starValueAt(500f, 142f))
    }

    @Test
    fun aControlWithoutWidthGivesNoScoreAboveTen() {
        assertEquals(0, starValueAt(0f, 0f))
        assertEquals(10, starValueAt(4f, 0f))
    }
}
